---
title: Building a CPRNG called Terninger - Part 13 Async Entropy
date: 2019-11-29
tags:
- Dice
- Fortuna
- RNG
- CPRNG
- Crypto
- Terninger-Series
- Random
- C#
- Async
categories: Coding
---

Reading from entropy sources asyncronously.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/), or see [the source code](https://bitbucket.org/ligos/terninger/src/default/).

So far, I've put Terninger into production in [makemeapassword.ligos.net](https://makemeapassword.ligos.net). 

## Goal

It's been a while since my last Terninger post, but it's been working well enough and my time has been spent in other places.

However, initialisation is still a sore point.
When a `PooledEntropyCprngGenerator` starts, it has to poll all its entropy sources to gather enough entropy before it can produce crypto safe randomness.
If one of those sources takes a long time (eg: `PingStatsSource` or `ExternalWebContentSource`) it can take 10 or 20 seconds to initialise.
Just because it pools each of them in turn, waiting for the result before moving to the next.

I want Terninger's `PooledEntropyCprngGenerator` to read from those sources in parallel, so that we gather entropy even when there's a slow source.

### Scatter Gather

Recall the interface for getting entropy:

```c#
public interface IEntropySource : IDisposable
{
    Task<byte[]> GetEntropyAsync(EntropyPriority priority);
}
```

The simplest thing that could possibly work is to do a scatter gather:

```c#
var sources = GetSources();
var sourceTasks = sources.Select(s => s.GetEntropyAsync(CurrentPriority)).ToArray();
await Task.WhenAll(sourceTasks);
```

But, I'm not interested in the simplest thing, I'm interested in a marginally better, significantly more complex thing!


### Sync vs Async Sources

Around half of Terninger's entropy sources are actually synchronous.
That is, `CurrentTimeSource` is simply returning `DateTime.UtcNow.Ticks` wrapped up in an already completed `Task`.
`GCMemorySource` queries the [garbage collector](https://docs.microsoft.com/en-us/dotnet/api/system.gc), and `CryptoRandomSource` delegates to a crypto strength [RandomNumberGenerator](https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.randomnumbergenerator) instance.

There are various asyncronous sources as well, like the aforementioned `PingStatsSource`.
Plus several external random number sources like `RandomOrgExternalRandomSource` which make network requests.
Even `ProcessStatsSource`, which uses the current state of all [local processes](https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process), is actually async, because it can take a few seconds to do its work (it takes non-trivial time to query every process, and other user processes will throw exceptions when we try to read more sensitive data).

So, it would be nice if I could identify the async sources and kick them off in the background, but then keep polling the syncronous sources.
That would allow entropy to accumulate via the sync sources, and we get a boost from the async ones whenever they complete.
But network requests and other long runing async sources don't block each other.


### How to Identify Async-ness

There's no way to know if any given `Task` will complete synchronously or not.
So, Terninger will need to learn by observing.
If a source is regularly synchronous, it will eventually assume it is synchronous.

However, that doesn't help during initialisation.
When we initialise, we're in high priority mode and are desperately trying to accumulate the minimum entropy required to generate our first key.
If we have to poll each source 10 or 20 times to learn if it's async or not, we haven't actually improved our initialisation speed at all.

So we allow entropy sources to be tagged with an attribute which says how likely it will be async.

```c#
[AttributeUsage(AttributeTargets.Class, Inherited = false, AllowMultiple = false)]
public sealed class AsyncHintAttribute : Attribute
{
    public readonly IsAsync IsAsync;
    public AsyncHintAttribute(IsAsync isAsync)
    {
        this.IsAsync = isAsync;
    }
}

public enum IsAsync
{
    Unknown = 0,
    Never = 1,
    AfterInit = 2,
    Rarely = 3,
    Mostly = 4,
    Always = 5,
}
```

If a source is tagged as `IsAsync.Never`, we assume it's synchronous. 
For `AfterInit` we assume the first run will be async, and then synchronous from then on.
For `Rarely` we're a bit more conservitive, but if it completes syncronously often enough we give it the benefit of the doubt.
And other options are generally assumed to be async often enough that they'll cause problems in the tight synchronous loop.

(For now, I'm only considering `Never`, `AfterInit` and `Rarely`. The other options are there for the future; one thing I've learned is that data hangs around much longer than code - if you get your data structures and tags right up front, it allows for more options down the track. But if you get the data wrong, those options may never be available).

Anyway, this lets us get the benefits of running several synchronous sources during initialisation, while other async ones run in the background.

As long as the entropy sources don't lie. 

If we have a bad actor which is tagged as `IsAsync.Never` but actually runs async and takes several seconds to run, well, we get burned.
Over time, Terninger will learn that this source isn't really synchronous, but during the initialisation phase we take a hit.
Perhaps, when Terninger saves state to disk, it can remember the bad actors for the next time it starts up, but that's not a thing today.

The final option is `Unknown`.
There's nothing that forces implementors of `IEntropySource` to tag their implementation.
And, we may be running in an environment which can't do reflection, so all attributes are invisible to us.
Currently, `Unknown` is dealt with in the same way as `Rarely`: it will take several polling loops before Terninger decides any `Unknown` source is synchronous.


### Algorithm

OK, that's the theory.
Let's look at the actual code!

Here's the new top level polling loop:

```c#
while (!_ShouldStop.IsCancellationRequested)
{
  var (syncSources, asyncSources) = GetSources();
  if (syncSources.Any() || asyncSources.Any())
  {
      // Poll all sources.
      PollSources(syncSources, asyncSources).GetAwaiter().GetResult();
 
      // Reseed the generator (if requirements for reseed are met).
      bool didReseed = MaybeReseedGenerator();

      // Update the priority based on recent data requests.
      MaybeUpdatePriority(didReseed);

      // And update any awaiters / event subscribers.
      if (didReseed)
          RaiseOnReseedEvent();
  }

  // Sleep before next polling loop
  var sleepTime = WaitTimeBetweenPolls();
  if (sleepTime > TimeSpan.Zero)
      Thread.Sleep(sleepTime);
}
```

The first change is in `GetSources()`, it now returns the sync and async sources in separate collections after categorising them.
You'll also note that it's using a score based system to decide what's sync and async, in combination with the `AsyncHint`.
And, something I haven't mentioned, it excludes sources which throw too many exception.
(See below for details of the scoring).

```c#
// Identify very likely sync sources.
var syncSources = 
      sources.Where(x => x.ExceptionScore > -10
          &&
          ((x.AsyncScore <= -10 
              && (x.AsyncHint == IsAsync.Never || x.AsyncHint == IsAsync.AfterInit))
          || (x.AsyncScore <= -20 
              && (x.AsyncHint == IsAsync.Rarely || x.AsyncHint == IsAsync.Unknown))
          ))
          .ToArray();
var asyncSources = sources
        .Where(x => x.ExceptionScore > -10 && !syncSources.Contains(x))
        .ToArray();

return (syncSources, asyncSources);
```

The next big change is in `PollSources()`.
And this is where things get complex!

Here's the simplified version:

* We kick off all the async tasks and let them run in the background, then we do a mini polling loop on the sync sources, and finally sleep for a short time.
* The default interval is 30ms, and scaleing factor is 1.1 when in high priority.
* There's also a limit to the times we'll poll, lest the sync sources come to dominate the entropy we generate and async sources don't get a chance to run.
* And finally, we `await` the async tasks, because [fire and forget tasks are a bad idea](https://docs.microsoft.com/en-us/dotnet/api/system.threading.tasks.taskscheduler.unobservedtaskexception).

```c#
var asyncTasks = asyncSources.Select(x => ReadAndAccumulate(x)).ToList();

var loopDelay = Config.MiniPollWaitTime;
int loops = 1;
do
{
    await PollSyncSources(syncSources);

    await Task.Delay(loopDelay);
    loopDelay = new TimeSpan((long)(loopDelay.Ticks * ScalingFactorBetweenSyncPolls()));
    loops = loops + 1;
} 
while (!_ShouldStop.IsCancellationRequested && loops < 30);

await Task.WhenAll(asyncTasks);
```


### Complex Algorithm

Now, I said that was the simplified version!
Let's start add that complexity in!

We don't always `await` unfinished tasks. 
If we're in high priority mode, we save any outstanding tasks and `await` them on the next loop.
After all, high priority means its more important to reseed the generator than to `await`.

```c#
if (_OutstandingEntropySourceTasks.Any())
{
    await Task.WhenAll(_OutstandingEntropySourceTasks);
    _OutstandingEntropySourceTasks.Clear();
}

// Main body goes here
// ....

var unfinishedTasks = asyncTasks.Where(x => !x.IsCompleted).ToList();
if (this.EntropyPriority != EntropyPriority.High && unfinishedTasks.Any())
{
    await Task.WhenAll(asyncTasks);
}
else if (this.EntropyPriority == EntropyPriority.High && unfinishedTasks.Any())
{
    _OutstandingEntropySourceTasks.AddRange(unfinishedTasks);
}
```

Also, there's a stack of reasons why we break out of the loop early (without sleeping):

* Cancellation is requested.
* We're in high priority mode and have accumulated enough entropy to reseed. And at least one async task has completed; again, we want to get entropy from as many sources as possible.
* All the async tasks have completed.

```c#
if (_ShouldStop.IsCancellationRequested)
    break;

if (this.EntropyPriority == EntropyPriority.High
      && this.ShouldReseed()
      && asyncTasks.Any(t => t.IsCompleted))
    break;

if (asyncTasks.All(x => x.IsCompleted)
      && loops >= 1)
    break;
```

Oh, did I mention there might not be any sync or async sources?
Perhaps they're all sync, or all async (both cases can happen in real life).
Well, that means every time we look at the `asyncTasks` list, we need to include `|| !asyncTasks.Any()`.

```c#
if (this.EntropyPriority == EntropyPriority.High
    && this.ShouldReseed()
    && (asyncTasks.Any(t => t.IsCompleted) || !asyncTasks.Any()))
      break;
```

And, if there are no async tasks to `await`, we don't want to do the polling loop at all.
Instead, we end and revert back to the top level loop.

```c#
while (!_ShouldStop.IsCancellationRequested 
    && asyncTasks.Any() 
    && loops < 30);
```

Phew!
Maybe I should have just done `Parallel.ForEach()`.
Well, it's all done now.

(Oh, and I forgot to mention there's logging sprinkled through all the above, just to pad it out).


### Polling Safely and Scoring

At the very bottom of the stack, we actually read from entropy sources (who'd have thought)!
We need to detect if the call completed syncronously or asyncronously, keeping score of that.
We also score exceptions vs success - so that a source which repeatedly throws can be removed from the loop.

```c#
private async Task<byte[]> ReadFromSourceSafely(SourceAndMetadata sm)
{
    try
    {
        // These may come from 3rd parties, use external hardware or do IO: anything could go wrong!
        var t = sm.Source.GetEntropyAsync(this.EntropyPriority);
        var wasSync = t.IsCompleted;
        byte[] maybeEntropy;
        
        if (wasSync)
        {
            maybeEntropy = t.Result;
            sm.ScoreSync();
        }
        else
        {
            maybeEntropy = await t;
            sm.ScoreAsync();
        }
        sm.ScoreSuccess();
    }
    catch (Exception ex)
    {
        Logger.ErrorException("Unhandled exception...", ex);
        sm.ScoreException();
        return null;
    }
}
```


## Future Work

* That nagging problem of Fortuna requiring **serialisation of the internal state of the generator**.

I'm aiming to complete this one for a 0.2 release.


## Next Up

Terninger's initialisation performance is greatly improved.
It used to take 10-20 seconds to gather enough entropy for the first key, even longer in the days before NBN.
Now, 2 seconds is a long initialisation time!

You can see the [actual Terninger code in BitBucket](https://bitbucket.org/ligos/terninger/src/default/). 
And the main [NuGet package](https://www.nuget.org/packages/Terninger).

Next up: serialise the internal state of the generator, and reload it during initialisation.



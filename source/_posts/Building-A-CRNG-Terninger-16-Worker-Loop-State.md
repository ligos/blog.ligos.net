---
title: Building a CPRNG called Terninger - Part 16 Worker Loop State
date: 2024-01-18
tags:
- Dice
- Fortuna
- RNG
- CPRNG
- Crypto
- Terninger-Series
- Random
- C#
- Save
- Persistent-State
categories: Coding
---

Wiring up the worker loop to load and save state.

<!-- more --> 

## Background

There's been a short (well, long) delay getting this post up. Sorry about that. 🙁

You can [read other Terninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/), or see [the source code](https://github.com/ligos/terninger). 

So far, I've put Terninger into production in [makemeapassword.ligos.net](https://makemeapassword.ligos.net). 

And we're up to the third and final part of **persistent state**:

1. [Saving and loading the state](/2022-10-28/Building-A-CRNG-Terninger-14-Persistent-State-File.html).
2. [Getting and setting the state from components which make up Terninger](/2024-01-16/Building-A-CRNG-Terninger-15-Object-State.html).
3. **Integrating points 1 and 2 with the main entropy gathering worker loop (this post).**

## Goal

We have the interfaces and implementations to load and save state from disk, and get and set that state on in-memory objects.

We now need to wire up the main `PooledEntropyCprngGenerator` loop to load state on start up, and save when required. 

### Details

Here are the requirements in detail:

* Load previous state from disk (if it exists) on start up.
* Set internal object state based on loaded data.
* Periodically read internal object state, and save to disk.
* When stopping, save final object state.

## Main Worker Loop

Terninger has a main worker loop.
It is a single thread which keeps running for the lifetime of a Terninger `PooledEntropyCprngGenerator` to gather entropy.
Basically, a giant `while()` loop.

Well, now it needs a beginning and an end.
To load and save state at the start and finish.

It will look roughly like:

```cs
LoadState();
WorkerLoop();
SaveState();
```

Let's look at the load, save and loop changes in a bit more detail.

## Load / Set

Before the worker loop starts, we load persistent state from disk, and initialise related objects.

At the top level, there isn't much exciting going on.
The only notable thing is `.GetAwaiter().GetResult()`, because we are running in a top level thread and can't do `await`.

```cs
var persistentState = TryLoadPersistentState().GetAwaiter().GetResult();
InitialiseInternalObjectsFromPersistentState(persistentState);
```

`TryLoadPersistentState()` does the actual load, wrapped in an exception handler in case of errors.
Failures can be safely ignored and the generator will act as if it was a brand new instance.

```cs
private async Task<PersistentItemCollection> TryLoadPersistentState()
{
	if (_PersistentStateReader == null)
		return null;

	try
	{
		return await _PersistentStateReader.ReadAsync();
	}
	catch (Exception ex)
	{
		Logger.WarnException("Unable to load persistent state from. Brand new terninger instance will be initialised.", ex);
		return null;
	}
}
```

Once we have loaded our collection of items, we need to set related objects.

```cs
private void InitialiseInternalObjectsFromPersistentState(PersistentItemCollection persistentState)
{
	if (persistentState == null)
		return;

	((IPersistentStateSource)this).Initialise(persistentState.Get(nameof(PooledEntropyCprngGenerator)));

	var prngAsPeristentStateSource = _Prng as IPersistentStateSource;
	if (prngAsPeristentStateSource != null)
	{
	  prngAsPeristentStateSource.Initialise(persistentState.Get(nameof(PooledEntropyCprngGenerator) + ".PRNG"));
	}

	((IPersistentStateSource)_Accumulator).Initialise(persistentState.Get(nameof(PooledEntropyCprngGenerator) + ".Accumulator"));

	// Remove each namespace from collection so entropy sources cannot observe internal state.
	persistentState.RemoveNamespace(nameof(PooledEntropyCprngGenerator));
	persistentState.RemoveNamespace(nameof(PooledEntropyCprngGenerator) + ".PRNG");
	persistentState.RemoveNamespace(nameof(PooledEntropyCprngGenerator) + ".Accumulator");

	_Accumulator.ResetPoolZero();
}
```

Setting simply involves casting each object to `IPersistentStateSource` and calling `Initialise()`.
With a little namespacing going on to keep nested objects separate.

Although I am not initialising any `IEntropySource` objects yet, I have removed any internal state relating to `PooledEntropyCprngGenerator`, so that any future `IEntropySource` objects can't peak at potentially sensitive data.
Safety first!

The call to `ResetPoolZero()` is important.
We'll return to it shortly.

## Get / Save

Moving onto the getting / saving process which runs when Terninger is stopping.
There's just one method at the top level:

```cs
GatherAndWritePeristentStateIfRequired(PersistentEventType.Stopping).GetAwaiter().GetResult();
```

Yeah, gotta look inside that method to see what it does:

```cs
private async Task GatherAndWritePeristentStateIfRequired(PersistentEventType eventType)
{
	if (_PersistentStateWriter == null)
		return;
	if (!ShouldWritePersistentState(eventType))
		return;

	var persistentState = new PersistentItemCollection();

	// Always accumulate internal objects last, so anyone trying to impersonate global namespaces gets overwritten.

	persistentState.SetNamespace(nameof(PooledEntropyCprngGenerator), ((IPersistentStateSource)this).GetCurrentState(eventType));

	var prngAsPeristentStateSource = _Prng as IPersistentStateSource;
	if (prngAsPeristentStateSource != null)
	{
		persistentState.SetNamespace(nameof(PooledEntropyCprngGenerator) + ".PRNG", prngAsPeristentStateSource.GetCurrentState(eventType));
	}

	persistentState.SetNamespace(nameof(PooledEntropyCprngGenerator) + ".Accumulator", ((IPersistentStateSource)_Accumulator).GetCurrentState(eventType));

	// Save.
	try
	{
		await _PersistentStateWriter.WriteAsync(persistentState);
		_LastPersistentStateWriteUtc = DateTime.UtcNow;
	}
	catch (Exception ex)
	{
		Logger.WarnException("Unable to write persistent state to.", ex);
	}
}
```

This combines gathering all the state, and the actual save, into a single method.

We'll come back to `ShouldWritePersistentState()` later.
But its safe to assume when we call with `PersistentEventType.Stopping`, it returns `true`.

We gather all the state by creating an empty `PersistentItemCollection` as an accumulator, then casting related objects to `IPersistentStateSource` and calling `GetCurrentState()`.
Again, there's a bit of namespacing going on to keep separate data separate.

And, there's a reminder to myself that the internal state is accumulated last, so `IEntropySource`s can't do anything naughty.

Finally, there's a similar `WriteAsync()` call wrapped in an exception handler.

## Worker Loop 

Terninger instances can last for a long time (`makemeapassword.ligos.net` runs for a month before a reboot; and it could run for much longer if needed). 
And there's no guarantee it will be stopped cleanly (maybe the server crashes, or maybe the programmer simply doesn't `Dispose()` the object).
So, every now and then, the worker loop will save state.

Here are the relevant lines of `WorkerLoop()`:

```cs
this.PollSources(syncSources, asyncSources).GetAwaiter().GetResult();
bool didReseed = MaybeReseedGenerator();

var writeEvent = didReseed ? PersistentEventType.Reseed : PersistentEventType.Periodic;
GatherAndWritePeristentStateIfRequired(writeEvent).GetAwaiter().GetResult();
```

We reuse `GatherAndWritePeristentStateIfRequired()`, but pass a different `PersistentEventType` depending on if we reseed the generator or not. 

Time to return to `ShouldWritePersistentState()`!
It returns `true` when we `Reseed`, because that's when entropy pools will be updated.
But only returns `true` for `Periodic` if a certain duration has elapsed since we last saved (5 minutes by default).

So, we save state whenever the generator reseeds (which may take a while if the generator isn't being used), or every 5 minutes.

## Security: Entropy Pool

OK, time to deal, once and for all, with the remaining security problem that external state raises:

1. An attacker can read the persistent state on disk and be able to predict future random numbers: we've already addressed that in [a previous post](/2024-01-16/Building-A-CRNG-Terninger-15-Object-State.html).
2. An attacker can write to persistent state when the generator is stopped and poison the generator such that they can predict future random numbers.

That second problem is a tricky one to solve.
While it's very desirable to retain the state of entropy pools (it's a core function of Fortuna), it also allows an attacker a way to influence the internal state of the generator.

And that could completely subvert the generator.

And there's no way for Terninger to know the persistent state is genuine or malicious.
Even if you encrypt, or sign, or hash the persistent state file, the Terninger code needs to be able to verify that crypto without human intervention.
That means an attacker could, read crypto keys out of terninger code, and write a poisoned file.
Or, if the end user could configure those keys in the config file, then the attacker would just read the keys from the config file!
Or, the attacker could use Terninger's own code to sign their own malicious file.

Cryptography does not solve this problem.

However, there are two, relatively simple approaches to mitigate this problem.

### Add Extra Entropy When Loading

We haven't looking into the implementation of `IPersistentStateSource.Initialise()` for all objects.
In particular, `EntropyPool` adds some additional entropy when loading:

```cs
void IPersistentStateSource.Initialise(IDictionary<string, NamespacedPersistentItem> state)
{
	// As we are reading external (and potentially untrusted) persisted state, we include some additional entropy.
	if (state.TryGetValue("EntropyHash", out var entropyHashValue))
	{
		AccumulateBlock(entropyHashValue.Value, entropyHashValue.Value.Length);
		var extraEntropy = PortableEntropy.Get32();
		AccumulateBlock(extraEntropy, extraEntropy.Length);
	}
}
```

We don't just accumulate the saved hash, we also add additional entropy.

Now, `PortableEntropy.Get32()` isn't a very good source of entropy.
It will only add 16-32 bits of real entropy.
That's better than nothing, but not good enough on its own.

### Saved Entropy is Just One Source of Many

After we load all external state, there's a call to `EntropyAccumulator.ResetPoolZero()`.
That puts the generator into high priority mode to gather enough entropy for a reseed.
That usually completes [within two seconds](/2019-11-29/Building-A-CRNG-Terninger-13-Async-Entropy.html).
With the default settings, that accumulates 384 bits of **new entropy** in pool zero.
And should also gather a similar amount of entropy for all other pools.
(384 bits is the best case, an attacker might reasonably predict some of those bits, but its very difficult to predict all of them).

So, we initialise each pool based on prior state.
But then add more entropy on top of that prior state.

Essentially, the external state becomes just one source of entropy out of many.

Now an attacker also needs to deal with at least 128 bits of entropy (probably much more) on top of whatever is loaded from disk.

And, within a few minutes, it's likely there will be another reseed.
So the window of opportunity for an attacker to make use of a poisoned file is quite low.


## Next Up

We now have persistent state implemented! 
This is the last major piece of functionality in Terninger to fully implement Fortuna!
And, because I've been very slack with my blog, it's been in production for ~18 months!

You can see the [actual Terninger code in GitHub](https://github.com/ligos/terninger/). 
And the main [NuGet package](https://www.nuget.org/packages/Terninger).

Next up: a major improvement to `PingStatsSource` which uses persisted state.

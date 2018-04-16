---
title: Building a CPRNG called Terninger - Part 9 The Scheduler
date:  2018-02-17
tags:
- Dice
- Fortuna
- RNG
- CPRNG
- Crypto
- Terninger-Series
- Random
- C#
- .NET
- Threading
categories: Coding
---

The scheduler which ties all the parts together.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/).

So far, we have all the parts needed to implement the cryptographically secure Fortuna random number generator: a PRNG, an accumulator of entropy, and sources of entropy. 


## Goal

Put all the parts together to make the CPRNG by using a scheduler to do the work.

Fortuna does not have a scheduler as such.
It assumes sources of entropy call into Fortuna and deliver entropy; that is, a push model.
Terninger uses a pull model: the generator polls entropy sources on a periodic basic to get entropy.
And this will use a basic scheduler.

On our crude diagram, we're producing data at the far right.
But the scheduler will be running to pull data from the very left, all the way through the different components of the generator.
And in the end, we'll be able to produce a random key.

```
Raw entropy ->             -> pools ->
Raw entropy -> accumulator -> pools -> re-seed material
Raw entropy ->             -> pools ->
```

Actually, we'll produce many random keys over time.
Over a very long time, potentially.
An instance of Fortuna or Terninger may have a lifetime measured in years, decades or longer (if its internal state is serialised to disk).


### Architecture

The basics of our scheduler will be a thread executing a processing loop:

1. Initialise the entropy sources.
2. Poll the entropy sources.
3. Accumulate the entropy received.
4. On occasion, re-seed the internal PRNG.
5. Optionally, wait for a while.
6. Go back to 2.

That's about as simple as it gets.
Well, as simple as things can be when dealing with multi-threaded code.


### PooledEntropyCprngGenerator - Data

Data structures should drive implementations, so lets look at the data required to derive seed material.

```c#
public class PooledEntropyCprngGenerator : IRandomNumberGenerator
{
    // The PRNG based on a cypher or other crypto primitive, as specifeid in section 9.4.
    private readonly IReseedableRandomNumberGenerator _Prng;
    // The entropy accumulator, as specified in section 9.5.
    private readonly EntropyAccumulator _Accumulator;
    // Multiple entropy sources, as specified in section 9.5.1.
    private readonly List<IEntropySource> _EntropySources;
    private readonly List<IEntropySource> _InitialisedEntropySources;
    public int SourceCount => this._EntropySources.Count;

    // A thread used to schedule reading from entropy sources.
    private readonly Thread _SchedulerThread;

    // Event raised after each re-seed.
    public event EventHandler<PooledEntropyCprngGenerator> OnReseed;

    // Required by IRandomNumberGenerator
    public int MaxRequestBytes => _Prng.MaxRequestBytes;

    // Counters
    public Int128 BytesRequested { get; private set; }
    public Int128 ReseedCount => this._Accumulator.TotalReseedEvents;
}
```

There's quite a few fields and properties there.

An `IReseedableRandomNumberGenerator` is our internal random number generator. 
It's only cryptographically secure if we re-seed it regularly.
And I've extended the interface slightly to allow that re-seeding.

The `EntropyAccumulator` is the accumulator which pools incoming entropy from the `List<IEntropySource>`.
There's a separate list which contains the sources which successfully initialise.

We have our `Thread`, which will execute the processing loop.
And an event which is raised on each re-seed, if consumers are interested in such a thing.

And finally, a few properties to report statistics.

The constructor simply accepts the data structures we need.

```c#
public PooledEntropyCprngGenerator(
        IEnumerable<IEntropySource> sources, 
        EntropyAccumulator accumulator, 
        IReseedableRandomNumberGenerator prng) 
{
    // Null checks removed.

    this._Prng = prng;      // Note that this is unkeyed at this point.
    this._Accumulator = accumulator;
    this._EntropySources = new List<IEntropySource>(sources);
    this._InitalisedEntropySources = new List<IEntropySource>(_EntropySources.Count);
    this._SchedulerThread = new Thread(ThreadLoop, 256 * 1024);
    _SchedulerThread.Name = "Terninger Worker Thread";
    _SchedulerThread.IsBackground = true;

    if (_EntropySources.Count < 2)
        throw new ArgumentException($"At least 2 entropy sources are required. Only {_EntropySources.Count} were provided.", nameof(sources));
}


```


### Getting Started

The generator is not doing anything once constructed.
We need to tell it to start running first.


```c#
private bool _RunningCoreLoop = false;      // Set to true after initialisation.

public void Start()
{
    this._SchedulerThread.Start();
}

public async Task StartAndWaitForInitialisation()
{
    // TODO: work out how to do this without polling.
    this.Start();
    while (!_RunningCoreLoop)
        await Task.Delay(100);
}
public Task StartAndWaitForFirstSeed() => StartAndWaitForNthSeed(1);
public Task StartAndWaitForNthSeed(Int128 seedNumber)
{
    if (this.ReseedCount >= seedNumber)
        return Task.FromResult(0);
    this.Start();
    return WaitForNthSeed(seedNumber);
}

private async Task WaitForNthSeed(Int128 seedNumber)
{
    // TODO: work out how to do this without polling.
    while (this.ReseedCount < seedNumber)
        await Task.Delay(100);
}
```

We can ask the generator to `Start()`, but we can't use it until it has an initial seed.
So there are methods which return a `Task` indicating when the first (or nth) seed was generated.

I'm not sure if there's any better way of waiting for a complex condition to be true (the nth seed) other than polling.


### Stopping

Once we've consumed the randomness we required, we could just `Dispose()` or discard the generator, but it's better form to provide a well defined way to `Stop()` it.

To do that, we need to introduce a basic [thread synchronisation primitive](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/threading/thread-synchronization), in the form of a [CancellationTokenSource](https://msdn.microsoft.com/en-us/library/dd997289.aspx).
(In addition to `_RunningCoreLoop`).

```c#
public bool IsRunning => _SchedulerThread.IsAlive;
private readonly CancellationTokenSource _ShouldStop = new CancellationTokenSource();

public void RequestStop()
{
    _ShouldStop.Cancel();
}
public async Task Stop()
{
    _ShouldStop.Cancel();
    await Task.Delay(1);
    // TODO: work out how to do this without polling.
    while (this._SchedulerThread.IsAlive)
        await Task.Delay(100);
}
```

There is no way to force the generator to stop; we can only ask it and wait until it's finished.
However, if we code our processing loop right, it should respond pretty quickly.


### Force a Reseed

The last public method for the generator is to force a reseed.
This may be required because of a significant event in the application, the computer waking from sleep or the user's request.

Again, we need another synchronisation object: a [WaitHandle](https://msdn.microsoft.com/en-us/library/system.threading.waithandle.aspx), so the generator will wake quickly in response to our request.

```c#
private readonly EventWaitHandle _WakeSignal = new EventWaitHandle(false, EventResetMode.AutoReset);
public EntropyPriority EntropyPriority { get; private set; }

public PooledEntropyCprngGenerator(...) 
{
    // Rest of the constructor is here.

    this.EntropyPriority = EntropyPriority.High;
}


public void StartReseed()
{
    Reseed();
}
public Task Reseed() {
    this.EntropyPriority = EntropyPriority.High;
    this._WakeSignal.Set();     // Will wake up the processing loop if it is sleeping.
    return WaitForNthSeed(this.ReseedCount + 1);
}
```

The `EntropyPriority` field is an enum with *low*, *normal* and *high* levels.
Where `EntropyPriority.High` signals that a new seed should be generated as quickly as possible.
There's some more discussion about this under *How Hard Should I Work*, below.


### Processing Loop

Finally, the real core of the generator!

**1. Initialisation**

The initialisation logic simply loops over the sources the generator was given, and transfers the successful ones to a different collection for ease of polling.
As you can tell from my comments, I'm not a big fan of the initialisation being in the generator as it must take a dependency on the configuration, but this will do for now.

I'm also using [GetAwaiter().GetResult()](https://stackoverflow.com/questions/17284517/is-task-result-the-same-as-getawaiter-getresult) to interact with `Tasks`.
This is the thread in control of everything, so it has to block here.

```c#
private void ThreadLoop()
{
    // TODO: I don't want no config gumph in here!
    var emptyConfig = new EntropySourceConfigFromDictionary(Enumerable.Empty<string>());
    
    // Start initialising sources (step 1).
    // TODO: initialise N in parallel.
    foreach (var source in _EntropySources)
    {
        var initResult = source.Initialise(emptyConfig, EntropySourcePrngFactory)
                                .GetAwaiter().GetResult();
        if (initResult.IsSuccessful)
            _InitalisedEntropySources.Add(source);
        // TODO: log unsuccessful initialisations.
    }
}
```

**2 and 3. Polling and Accumulating**

Is a simple loop over the initialised entropy sources.
There are locks in place to allow other threads to interact with the accumulator.
And repeated checks to see if the loop needs to stop via `IsCancellationRequired`.

The most obvious improvement is to request data from multiple sources in parallel.
However, many sources will either a) be entirely synchronous, or b) frequently return `null` synchronously because they have a delay built in.
So, parallelism may actually not be very advantageous.


```c#
private void ThreadLoop()
{
    // Initialisation is done!

    while (!_ShouldStop.IsCancellationRequested)
    {
        _RunningCoreLoop = true;

        // TODO: start reading as soon as the first source is initialised.
        // Poll all initialised sources.
        foreach (var source in _InitalisedEntropySources)
        {
            // TODO: read up to N in parallel.
            var maybeEntropy = source.GetEntropyAsync().GetAwaiter().GetResult();
            if (maybeEntropy != null)
            {
                lock (_AccumulatorLock)
                {
                    _Accumulator.Add(new EntropyEvent(maybeEntropy, source));
                }
            }
            // TODO: randomise the order of entropy sources to prevent one always being first or last (which can potentially bias the accumulator).
            if (_ShouldStop.IsCancellationRequested)
                break;
        }

        // More after this...
    }
}
```

**4. Reseed**

The reseed condition in `ShouldReseed()` is simple for now: depending on the `EntropyPriority` we need to accumulate a certain amount of entropy before reseeding - higher priorities require less entropy and thus reseed more quickly.

Otherwise, reseeding involves asking the accumulator for the `NextSeed()` and pushing it into the underlying random number generator via `Reseed()`.
It then resets the priority and invokes an event.


```c#
private void ThreadLoop()
{
    while (!_ShouldStop.IsCancellationRequested)
    {
        // Polling is done.


        // Determine if we should re-seed.
        if (this.ShouldReseed())
        {
            byte[] seedMaterial;
            lock (_AccumulatorLock)
            {
                seedMaterial = _Accumulator.NextSeed();
            }
            lock (this._PrngLock)
            {
                this._Prng.Reseed(seedMaterial);
            }
            if (this.EntropyPriority == EntropyPriority.High)
                this.EntropyPriority = EntropyPriority.Normal;
            this.OnReseed?.Invoke(this, this);
        }


        // More after this...
    }
}

private bool ShouldReseed()
{
    if (this._ShouldStop.IsCancellationRequested)
        return false;
    else if (this.EntropyPriority == EntropyPriority.High)
        // TODO: configure how much entropy we need to accumulate before reseed.
        return this._Accumulator.PoolZeroEntropyBytesSinceLastSeed > 48;
    else if (this.EntropyPriority == EntropyPriority.Low)
        // TODO: use priority, rate of consumption and date / time to determine when to reseed.
        return this._Accumulator.MinPoolEntropyBytesSinceLastSeed > 256;
    else
        // TODO: use priority, rate of consumption and date / time to determine when to reseed.
        return this._Accumulator.MinPoolEntropyBytesSinceLastSeed > 96;
}
```



**5. Sleep**

The thread then sleeps until it is time to poll again.
Once again, the actual sleep time is determined via the `EntropyPriority`.

However, there is no call to [Thread.Sleep()](https://msdn.microsoft.com/en-us/library/system.threading.thread.sleep.aspx), quite deliberately.
Instead, we sleep as a side effect of [WaitHandle.WaitAny()](https://msdn.microsoft.com/en-us/library/system.threading.waithandle.waitany.aspx).
This will block the current thread until either a) the sleep time expires, or b) one of the threading primitives is signalled (either a request to cancel or reseed).
This improves the responsiveness of the generator to external events.


```c#
private void ThreadLoop()
{
    while (!_ShouldStop.IsCancellationRequested)
    {
        // Polling and reseed is done.


        // Wait for some period of time before polling again.
        var sleepTime = WaitTimeBetweenPolls();
        if (sleepTime > TimeSpan.Zero)
        {
            // The thread should be woken on cancellation or external signal.
            int wakeIdx = WaitHandle.WaitAny(_AllSignals, sleepTime);
            var wasTimeout = wakeIdx == WaitHandle.WaitTimeout;
        }
    }   // This really is the end of the loop.

    // TODO: work out how often to poll based on minimum and rate entropy is being consumed.
    private TimeSpan WaitTimeBetweenPolls() => 
        EntropyPriority == EntropyPriority.High ? TimeSpan.Zero
      : EntropyPriority == EntropyPriority.Normal ? TimeSpan.FromSeconds(5)
      : EntropyPriority == EntropyPriority.Low ? TimeSpan.FromSeconds(30)
      : TimeSpan.FromSeconds(1);     // Impossible case.
}
```


### Sample Usage

At this point, we have a working cryptographic random number generator in `PooledEntropyGenerator`!
Using it is rather cumbersome in that we need to supply all its inputs, but making it nice can wait.

```c#
var sources = new IEntropySource[] { 
    new CryptoRandomSource(), 
    new CurrentTimeSource(), 
    new GCMemorySource(), 
    new NetworkStatsSource(), 
    new ProcessStatsSource(), 
    new TimerSource() 
};
var acc = new EntropyAccumulator(new StandardRandomWrapperGenerator());
var rng = new PooledEntropyCprngGenerator(sources, acc);

await rng.StartAndWaitForFirstSeed();
var bytes = rng.GetRandomBytes(16);

await rng.Stop();
```

We need to arrange some nicer interfaces to constructing the generator, finding and initialising the various sources, and waiting for the first seed so the generator is usable.
But it does work!
Hurrah!


### How Hard Should We Work?

Fortuna leaves implementers to decide how aggressive they should be in accumulating entropy and reseeding the generator.
Section `9.5.2` says to reseed when the first pool is *"long enough"*, which is quite vague.
`9.5.5` is more specific recommending the first pool should have accumulate between 32 and 64 bytes before reseeding, which makes sense based on the use of SHA256.
However, Fortuna makes no reference that I can see to how frequently entropy sources should produce data (remembering that Fortuna assumes sources are pushing to the accumulator; Terninger is polling the sources).

We could poll very quickly, which produces more entropy but consumes more CPU time (and electricity / battery).
We could poll slowly, which risks an attacker learning the internal state and being able to predict the random output.
There's no obvious answer, and consumers of the generator almost certainly want to decide this themselves.

Currently, `EntropyPriority` is what drives the time between polling and reseed events.
But its much too simple.

I can see the following as potential factors:

* Has the generator made its first seed? Or second seed?
* Has the generator recently been suspended to disk or sleep? (Where its internal state may be observed).
* How much output has been requested? Over what time period?
* Does the application have minimum / maximum times between reseeds?
* Does the application require reseeding after a particular amount of output?

My plan is to allow minimum and maximum bytes of output and min / max periods of time to determine hard limits.
And then allow the generator to slow polling down if not much entropy is being requested from it. 




### Future Work

The actual source code has a whole heap of TODO's in it.
There are any number of ways I can improve the generator in the future:

* Instead of running on a dedicated thread, the scheduler could run on any timer based event loop (eg: WinForms Timer, WPF Dispatcher, etc). That might be useful in some scenarios, and would dramatically reduce memory usage.
* Move the configuration and initialisation logic for Entropy Sources out of the generator's main processing loop. Probably even out of the generator altogether.
* See if there's a way I can avoid polling in the `Start()` and `Stop()` methods.
* Be smarter about reading from entropy sources in parallel.
* Randomise the order entropy sources are polled in, to prevent one always being first or last.
* Make the scheduler loop smarter about how frequently it reseeds and how long it sleeps between polling.


## Next Up

Now we can produce cryptographically secure random data using `PooledEntropyCprngGenerator`.
We've done it!
A minimum viable CPRNG!

You can see the [actual code in BitBucket](https://bitbucket.org/ligos/terninger/src/58f6b757d3a9127ae9f03b27bb17702e5f6f5d23/Terninger/Generator/PooledEntropyCprngGenerator.cs?at=default&fileviewer=file-view-default).

Next up, we'll re-work the console app to be able to use either the PRNG or CPRNG and output random data. 
So we can actually see the random-ness we've worked so hard to create.


---
title: Building a CPRNG called Terninger - Part 8 Entropy Sources
date: 2018-01-24
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
categories: Coding
---

How to generate enough entropy to make the generator random.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the Fortuna CPRNG.

It's been a while since my last Terninger post, but so far, we have the PRNG `CypherBasedPrngGenerator` with various options, a console app which outputs random data to file or stdout. And the beginning of the crypto secure generator, that is, the entropy accumulator.


## Goal

Build a number of *entropy sources* for Fortuna, as [specified](https://www.schneier.com/academic/paperfiles/fortuna.pdf) in section 9.5.1.

These are the root of all entropy in Fortuna and Turninger.
They need to generate bytes which are unpredictable, and constantly changing.
There need to be a number of them, to make it harder for an attacker to control or influence the generator.
And, I'd like them to be easily extendible via a simple interface.

They don't need to be uniformly random, although that helps.
They don't need to produce entropy at any particular rate, although more is usually better. 

In the crude diagram from the last past, we're at the very left side of the diagram.

```
Raw entropy ->             -> pools ->
Raw entropy -> accumulator -> pools -> re-seed material
Raw entropy ->             -> pools ->
```


### IEntropySource

Lets start with an interface.

```c#
public interface IEntropySource : IDisposable
{
    /// <summary>
    /// A unique name of the entropy source. Eg: Type name.
    /// </summary>
    string Name { get; }


    /// <summary>
    /// Initialise the entropy source. Returns a task indicating if it was successful or not.
    /// Configuration and a PRNG are available if the source requires them.
    /// </summary>
    Task<EntropySourceInitialisationResult> Initialise(
        IEntropySourceConfig config, 
        Func<Terninger.Generator.IRandomNumberGenerator> prngFactory
    );

    /// <summary>
    /// Gets entropy from the source.
    /// A source may return null if there is no entropy available.
    /// There is no limit to the amount of entropy which can be returned, but more than 16kB is overkill.
    /// </summary>
    Task<byte[]> GetEntropyAsync();
}
```

The two interesting methods are `Initalise()` and `GetEntropyAsync()`.

Both are async, which allows entropy sources to perform IO operations to derive entropy (eg: network calls, disk accesses, microphones, web cams, etc).

`Initialise()` is a glorified constructor. 
It is async because it may need to probe hardware or load data.
It should return a value that indicates if it was initialised successfully or not, and give some clue as to why it failed (eg: configuration was invalid, hardware isn't present, system isn't supported, user hasn't given permission, etc). 
It has access to a configuration object, which I'll discuss below, so users can tweak settings if required (although I want all sources to work out-of-the-box with no configuration required).
Finally, it can create a pseudo random generator for internal use (it shouldn't use this to directly generate bytes, but may use it to shuffle lists of data).

Overall, I intend Terninger to be able to probe DLLs / assemblies for any classes which implement `IEntropySource`, then create and try to initialise them without any ill effects on any system.
Or, in other words, I want this to facilitate a zero config and zero admin experience (while not ruling out the option of configuration by a professional).

`GetEntropyAsync()` is where all the action happens!
This should return a` byte[]` containing whatever entropy it has available.
It can be async, to facilitate getting this entropy via IO.
It may choose to return `null` if no entropy is available.
There is no limit to how many bytes it can return, but there's little point returning more than a few kilobytes.

Fortuna recommends entropy sources should *not* hash their result (as the accumulator does that).
But they should only return bytes which are meaningfully random, that is, returning the current time is good, but the current date is likely to be too predictable.

And that's it!
With this interface, the only limits to entropy are our imagination (and the hardware we're running on)!


### IEntropySourceConfig

Before I get into implementations, a brief look at how we can configure an `IEntropySource`.

Usually, I'd make strongly typed configuration objects, often based on JSON files, and possibly use dependency injection.
However, for the core of Terninger, I want minimal dependencies (which means no NuGet packages, no Json.NET, no fancy dependency injection) and high extensibility (so no strongly typed objects).
Which means we're back to a readonly key-value lookup:

```c#
/// <summary>
/// Interface for entropy sources to access configuration variables.
/// </summary>
public interface IEntropySourceConfig
{
    /// <summary>
    /// Returns the value of a named configuration item.
    /// Null represents the value does not exist in the config source.
    /// Empty string represents a value set to empty.
    /// </summary>
    string Get(string name);

    /// <summary>
    /// Returns true if the named configuration item is defined in the config source, false otherwise.
    /// </summary>
    bool ContainsKey(string name);
}
```

You can get configuration items based on string lookups.
Generally, the names should resemble an object structure with some basic namespacing (eg: `CurrentTimeSource.Enabled`).

You can also check if the key is even defined or not (either via `ContainsKey()` or checking if `Get()` returns `null` instead of empty string).
This subtle distinction allow each source to have some hard coded defaults, which can be overridden if specified in the configuration.



### Simple Implementation - CurrentTimeSource

Lets look at an actual implementation: `CurrentTimeSource`.

This is the classic way to seed a random number generator, use the current date and time.

In Terninger, this will return the current time on a regular interval, however the exact time (in the millisecond range) will be unpredictable.
I haven't tried to gauge how unpredictable it is, but on an old Windows system with low precision timers you'd have at least ~100 possible sub-second possibilities.
More modern system have sub-millisecond precision, but always good to be conservative!

```c#
public class CurrentTimeSource : IEntropySource
{
    private bool _HasRunOnce = false;

    public string Name => typeof(CurrentTimeSource).FullName;

    public Task<EntropySourceInitialisationResult> Initialise(IEntropySourceConfig config, Func<IRandomNumberGenerator> prngFactory)
    {
        if (config.IsTruthy("CurrentTimeSource.Enabled") == false)
            return Task.FromResult(EntropySourceInitialisationResult.Failed(EntropySourceInitialisationReason.DisabledByConfig, "CurrentTimeSource has been disabled in entropy source configuration."));
        else
            return Task.FromResult(EntropySourceInitialisationResult.Successful());
    }

    public Task<byte[]> GetEntropyAsync()
    {
        byte[] result;
        if (!_HasRunOnce)
        {
            // On first run, we include the entire 64 bit value. 
            result = BitConverter.GetBytes(DateTime.UtcNow.Ticks);
            _HasRunOnce = true;
        }
        else
        {
            // All subsequent runs only include the lower 32 bits.
            result = BitConverter.GetBytes(unchecked((int)DateTime.UtcNow.Ticks));
        }
        
        return Task.FromResult(result);
    }
}
```

The configuration is read in `Initialise()` checks the config to see if it is disabled. 
`IsTruthy()` returns a nullable bool: true, false or not set - the configuration must explicitly disable the source; it's enabled if the configuration makes no reference.
Otherwise, there's nothing else to configure!

`GetEntropyAsync()` is actually entirely synchronous and based around `DateTime.UtcNow`.
It will only return the low 32 bits of the current time except when first called.


### Complex Implementation - ProcessStatsSource

A more complex source of entropy is the current state of running processes on the computer.
I'll work through this one more slowly.

```c#
public class ProcessStatsSource : IEntropySource
{
    public string Name => typeof(ProcessStatsSource).FullName;

    // This many properties are read from each process. Based on available properties.
    private const int _ItemsPerProcess = 17;            

    private IRandomNumberGenerator _Rng;

    // Config properties.
    private DateTime _NextSampleTimestamp;
    // This many Int64 stats are combined into one final hash. 70 should span a bit over 4 processes each.
    private int _ItemsPerResultChunk = 70;              
    public int StatsPerChunk => _ItemsPerResultChunk;
    // 10 minutes between runs, by default.
    private double _PeriodMinutes = 10.0;               
    public double PeriodMinutes => _PeriodMinutes;

    public ProcessStatsSource() : this(10.0, 70, null) { }
    public ProcessStatsSource(double periodMinutes) : this(periodMinutes, 70, null) { }
    public ProcessStatsSource(double periodMinutes, int itemsPerResultChunk) : this(periodMinutes, itemsPerResultChunk, null) { }
    public ProcessStatsSource(double periodMinutes, int itemsPerResultChunk, IRandomNumberGenerator rng)
    {
        this._PeriodMinutes = periodMinutes >= 0.0 ? periodMinutes : 10.0;
        this._ItemsPerResultChunk = itemsPerResultChunk > 0 ? itemsPerResultChunk : 70;
        this._Rng = rng ?? StandardRandomWrapperGenerator.StockRandom();
    }

    public void Dispose()
    {
        var disposable = _Rng as IDisposable;
        if (disposable != null)
            DisposeHelper.TryDispose(disposable);
        disposable = null;
    }
}
```

This captures the state required (mostly configuration), a constructor and `Dispose()`.
We capture a random number generator to allow for some basic mixing of entropy.
The remaining state is used to determine how frequently it will poll the system for entropy (under the assumption that most of the time processes won't change much), and the number of "items" from processes will be converted into final bytes (that will make more sense when you see `GetEntropy()`).


```c#
public class ProcessStatsSource : IEntropySource
{
    public Task<EntropySourceInitialisationResult> Initialise(IEntropySourceConfig config, Func<IRandomNumberGenerator> prngFactory)
    {
        if (config.IsTruthy("ProcessStatsSource.Enabled") == false)
            return Task.FromResult(EntropySourceInitialisationResult.Failed(EntropySourceInitialisationReason.DisabledByConfig, "ProcessStatsSource has been disabled in entropy source configuration."));

        config.TryParseAndSetDouble("ProcessStatsSource.PeriodMinutes", ref _PeriodMinutes);
        if (_PeriodMinutes < 0.0 || _PeriodMinutes > 1440.0)
            return Task.FromResult(EntropySourceInitialisationResult.Failed(EntropySourceInitialisationReason.InvalidConfig, new ArgumentOutOfRangeException("ProcessStatsSource.PeriodMinutes", _PeriodMinutes, "Config item ProcessStatsSource.PeriodMinutes must be between 0 and 1440 (one day)")));

        config.TryParseAndSetInt32("ProcessStatsSource.StatsPerChunk", ref _ItemsPerResultChunk);
        if (_ItemsPerResultChunk <= 0 || _ItemsPerResultChunk > 10000)
            return Task.FromResult(EntropySourceInitialisationResult.Failed(EntropySourceInitialisationReason.InvalidConfig, new ArgumentOutOfRangeException("ProcessStatsSource.StatsPerChunk", _ItemsPerResultChunk, "Config item ProcessStatsSource.StatsPerChunk must be between 1 and 10000")));

        _Rng = prngFactory() ?? StandardRandomWrapperGenerator.StockRandom();
        _NextSampleTimestamp = DateTime.UtcNow;

        return Task.FromResult(EntropySourceInitialisationResult.Successful());
    }
}
```

The `Initialise()` method reads various details from configuration, and sets fields as appropriate.
If values are not defined in the configuration, defaults are used.
Finally, there's validation and defensive coding as well.


```c#
public Task<byte[]> GetEntropyAsync()
{
    // This reads details of all processes running on the system, and uses them as inputs to a hash for final result.
    // Often, different properties or processes will throw exceptions.
    // Given this isn't trivial work, we run in a separate threadpool task.
    // There's also a period where we won't sample.

    // Return early until we're past the next sample time.
    if (_NextSampleTimestamp > DateTime.UtcNow)
        return Task.FromResult<byte[]>(null);

    return Task.Run(() =>
    {
        var ps = Process.GetProcesses();

        var processStats = new long[ps.Length * _ItemsPerProcess];

        // Read details from all processes.
        // PERF: This takes several seconds, which isn't helped by the fact a large number of these will throw exceptions when not running as admin.
        for (int i = 0; i < ps.Length; i++)
        {
            var p = ps[i];
            processStats[(i * _ItemsPerProcess) + 0] = p.TryAndIgnoreException(x => x.Id);
            processStats[(i * _ItemsPerProcess) + 1] = p.TryAndIgnoreException(x => x.MainWindowHandle.ToInt64());
            processStats[(i * _ItemsPerProcess) + 2] = p.TryAndIgnoreException(x => x.MaxWorkingSet.ToInt64());
            processStats[(i * _ItemsPerProcess) + 3] = p.TryAndIgnoreException(x => x.NonpagedSystemMemorySize64);
            processStats[(i * _ItemsPerProcess) + 4] = p.TryAndIgnoreException(x => x.PagedMemorySize64);
            processStats[(i * _ItemsPerProcess) + 5] = p.TryAndIgnoreException(x => x.PagedSystemMemorySize64);
            processStats[(i * _ItemsPerProcess) + 6] = p.TryAndIgnoreException(x => x.PeakPagedMemorySize64);
            processStats[(i * _ItemsPerProcess) + 7] = p.TryAndIgnoreException(x => x.PeakVirtualMemorySize64);
            processStats[(i * _ItemsPerProcess) + 8] = p.TryAndIgnoreException(x => x.PeakWorkingSet64);
            processStats[(i * _ItemsPerProcess) + 9] = p.TryAndIgnoreException(x => x.PrivateMemorySize64);
            processStats[(i * _ItemsPerProcess) + 10] = p.TryAndIgnoreException(x => x.WorkingSet64);
            processStats[(i * _ItemsPerProcess) + 11] = p.TryAndIgnoreException(x => x.VirtualMemorySize64);
            processStats[(i * _ItemsPerProcess) + 12] = p.TryAndIgnoreException(x => x.UserProcessorTime.Ticks);
            processStats[(i * _ItemsPerProcess) + 13] = p.TryAndIgnoreException(x => x.TotalProcessorTime.Ticks);
            processStats[(i * _ItemsPerProcess) + 14] = p.TryAndIgnoreException(x => x.PrivilegedProcessorTime.Ticks);
            processStats[(i * _ItemsPerProcess) + 15] = p.TryAndIgnoreException(x => x.StartTime.Ticks);
            processStats[(i * _ItemsPerProcess) + 16] = p.TryAndIgnoreException(x => x.HandleCount);
        }

        // Remove all zero items (to prevent silly things like a mostly, or all, zero hash result).
        var processStatsNoZero = processStats.Where(x => x != 0L).ToArray();

        // Shuffle the details, so there isn't a repetition of similar stats.
        processStatsNoZero.ShuffleInPlace(_Rng);

        // Get digests of the stats to return.
        var result = ByteArrayHelpers.LongsToDigestBytes(processStatsNoZero, _ItemsPerResultChunk);

        // Set the next run time.
        _NextSampleTimestamp = DateTime.UtcNow.AddMinutes(_PeriodMinutes);

        return result;
    });
}
```

The main guts involves reading many useful properties from current system processes, accumulating them, and finally turning them into a digest of bytes.
I'm using `Int64` as the common type when accumulating, as most counters are `Int64`s or can be converted to them easily.

If Terniner is running in user mode, the details of many processes are not available and will throw exceptions, so there's a helper method to wrap the try-catch.
Unfortunately, exceptions aren't very fast, which makes this run quite slow.

The final digest process involves our random number generator: we shuffle the meaningful results so that long running processes don't generate repetitive patterns in the output.
Finally, we break all the `Int64`s up into chunks (based on configuration, 70 by default) and produce digests of them (using SHA256).

This produces around 1kB (8k bits) of entropy on my Windows 10 machine in user mode.


### Other Sources

I'll give a brief overview of the other sources which have been implemented.
I probably got a bit carried away with the number and variety, which made this update well overdue (although, two [computer](/2017-11-03/Restoring-From-Backup.html) [failures](/2017-12-02/Recovering-From-A-Dead-CPU.html) contributed as well).

**NullSource** and **CounterSource**

These are meant for testing and are disabled by default.
They return empty byte arrays and an incrementing counter respectively.

**CryptoRandomSource**

This cheats and asks the system for entropy via `System.Security.Cryptography.RandomNumberGenerator`.
Both Windows and Linux kernels have their own cryptographic random number source, and this simply leans on it.
This is usually good practice, unless you're rolling your own CRNG.
But, even in Terniner, there's little harm leveraging this source (as long as there are many others available).

**TimerSource**

This is a variation on `CurrentTimeSource`.
Rather than using `DateTime.UtcNow`, this returns `StopWatch.ElapsedTicks`.
Again, while it will always be counting up, the exact value you get each time will be highly unpredictable.

**GCMemorySource**

The exact amount of memory in use isn't easily predictable, especially in a managed environment like the CLR.
This source reads statistics from the garbage collector via the `GC` class.
It's big plus is its portable: all mainline CLRs have a garbage collector.
However, once you have read the current memory usage once, the next sample is highly likely to be similar - the only mitigating factor is that Terniner will generate some memory churn in its normal operation - but it it's a rather poor source of entropy over short periods of time. 

**NetworkStatsSource**

Similar to `ProcessStatsSource`, this reads a variety of statistics from network adapters.
It divides between *static* statistics (eg: IP address, network card name) and *dynamic* statistics (eg: packet count), and *static* items are only queried once.
Most systems only have a few network adapters at most, so this isn't as effective as `ProcessStatsSource`, but individual samples are likely to be more random.

**PingStatsSource**

Rather different from previous source, this makes a number of [ping](https://en.wikipedia.org/wiki/Ping_&#40;networking_utility&#41;) requests and uses the timing of responses to derive entropy.
Because only a small amount of entropy is gathered from each ping, this isn't all that effective.
I'm also aware that not all devices will have access to (or be willing to grant access to) network resources, so it can be disabled or enabled in config.
The servers used are public DNS servers, so they should be pretty reliable.

Pings (or *ICMP echo response* packets) are sometimes blocked by firewalls, so an extension of this source is TCP / UDP pings.
That is, opening a TCP connection or sending a single UDP packet (or even a basic DNS request given the servers I'm using are DNS servers) would be more reliable.
And also more complicated, so I'll think about it in the future.

**ExternalWebContentSource**

Building on the spirit of `PingStatsSource`, this source makes web requests to various popular websites.
It queries things which have a high degree of change (eg: news websites, [recent Tweets](https://twitter.com/), [Flikr posts](https://www.flickr.com/explore), etc) and uses the content as a source of entropy (as well as timing).
Because any user which queries these sites at the same time will have the same results, this includes a small amount of *static local entropy*, that is, things like hostname, IP address, etc.
Because there are a relatively large number of websites on the list, and each have the potential for a large amount of entropy based on content, this produces quite a bit of entropy.

**ExternalServerRandomSource**

Pushing the item of network based entropy to an extreme, this queries other servers which produce random numbers.
There are only a few of these, but they allow an extra-ordinary amount of entropy for a handful of web requests (*extra-ordinary* as in they could derive enough entropy to seed all pools several times over).
Again, these incorporate *static local entropy* because their results may be observed.

There are 6 individual sites which are supported.
On reflection, I should have created 6 separate sources, one for each site, but I'll fix that some other day.


### Testing

There are a few levels of testing for the entropy sources.

**Unit tests** are employed to ensure the constructors / configuration sets properties as expected.
These are particularly uninteresting tests, but needed to exercise all code paths.

**Fuzzing tests** which save the results of actually gathering a small amount of entropy.
These are used to observe (in an ad-hoc way) what the sources produce over a short period of time.

**Network tests** which make real network calls (for `PingStatsSource`, etc).
These need to check servers haven't disappeared off the air or changed their interfaces.

Note that all these are implemented as test methods (using Microsoft's test framework), but they are logically different things.

Also, because so many of these are testing external resources, I haven't tightened them up as much as I'd like.
But, it's going to be very hard to test all possible combinations in a controlled fashion.

I have another idea for improving ad-hoc testing in the future.
But that will have to wait for another update.


### Future Work

The variety of sources of entropy are very limited when we confine ourselves to sources common to all possible platforms (time and memory is realistically all we have).
But if you start taking dependencies on particular devices, hardware or platforms, we're effectively unlimited in variety!
(It is worth remembering that end-user devices like laptops have the widest variety easily accessible, while servers have the least).

Here are some examples:

* [Hardware random generators](https://en.wikipedia.org/wiki/Hardware_random_number_generator) (cost starts from ~US$50), or a [Yubikey](https://www.yubico.com/products/yubikey-hardware/) which can be used to sign a counter (for a de-facto random generator).
* External devices which record or observe the real world. Eg: webcams, audio inputs, observable WiFi base stations.
* Keyboard or mouse movements (and timings) from the user.
* Phone sensors (GPS, compass, orientation, etc).
* CPU based random number instructions (eg: [Intel RDRAND](https://en.wikipedia.org/wiki/RdRand)).
* External network devices (eg: a Raspberry Pi with camera consumed by another server).


One thing which I'm not comfortable with is the `IEntropySource.Initialise()` method.
Although it is easy for an interface, I'd much prefer an async constructor.
C# doesn't have async constructors though, so this will become a `static IEntropySource CreateAsync()` method.


## Next Up

Now we have a variety of entropy sources to feed into the accumulator and generate highly unpredictable seed material for the `CypherBasedPrngGenerator`.
Effectively, we have all the components Fortuna requires!

You can see the [actual code in BitBucket](https://bitbucket.org/ligos/terninger/src/72585374f20604c961829d91dab94bdc23f6d446/Terninger/EntropySources/?at=default).

Next up, we'll implement a *scheduler* which will be responsible for doing things.
That is, it will joining the entropy sources to the accumulator and re-seed the actual generator at regular intervals. 

And then we should have something very close to a working CPRNG!


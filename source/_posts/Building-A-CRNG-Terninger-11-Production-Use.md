---
title: Building a CPRNG called Terninger - Part 11 Production Use
date: 2018-05-28
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

Finishing touches and actually using it!

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/).

So far, we have a working *Pooled Generator* which implements does everything we need and produces random numbers. 


## Goal

Tidy up loose ends.
Improve the re-seeding process.
Improve the accumulator.

And deploy Terninger into [makemeapassword.ligos.net](https://makemeapassword.ligos.net).

Yep, its time to make Terninger do something practical: make people's passwords!


## Loose Ends

Although the pooled generator works, there are some improvements to make before I'm prepared to put it into production.


### Stop Firehose Entropy Sources

I have previous noted that there is nothing to stop a single ["firehose" entropy source overwhelming the accumulator](/2017-10-06/Building-A-CRNG-Terninger-7-Entropy-Accumulator.html).
If an attacker controlled such a source, it may become possible for them to guess the next key derived at a re-seed event.

There will always be some variation how much entropy each source can supply.
The more sources and more mixed pools become over time the better.
But the important thing is we don't want any particular pool to be dominated by a single source.

The Fortuna spec is silent on if a pool *MUST* accept entropy, so I'll assume that it *MAY* ignore entropy if it chooses.
Which leads to a pretty simple concept: pick some ratio of total entropy which can come from one source, count how much entropy has been accepted into the pool for each source seen, and reject any entropy which would exceed the threshold.

As I found, there are a few gotchas which apply to my simple algorithm.
I'll explain them after an abbreviated implementation.

```c#
public sealed class EntropyPool {
    // Dictionary to track usage by source.    
    private readonly Dictionary<IEntropySource, int> _CountOfBytesBySource = 
        new Dictionary<IEntropySource, int>(EntropySourceComparer.Value);


    internal void Add(byte[] entropy, IEntropySource source)
    {
        // Determine how much of the packet will be accepted.
        _CountOfBytesBySource.TryGetValue(source, out var countFromSource);
        var bytesToaccept = BytesToAcceptFromSource(entropy.Length, countFromSource);

        if (bytesToaccept <= 0)
            // Ignoring this packet entirely.
            return;
        
        // Accumulate the packet into the hash function.
        // Note that this may only incorporate part of the packet.
        _Hash.TransformBlock(entropy, 0, bytesToaccept, null, 0);

        // Increment counters. 
        // Note that this may overflow for very long lived pools.
        if (_CountOfBytesBySource.Count <= MaxSourcesToCount 
                && countFromSource < Int32.MaxValue) 
        {
            try {
                _CountOfBytesBySource[source] = countFromSource + bytesToaccept;
            } catch (OverflowException) {
                _CountOfBytesBySource[source] = Int32.MaxValue;
            }
        }
        TotalEntropyBytes = TotalEntropyBytes + bytesToaccept;
        EntropyBytesSinceLastDigest = EntropyBytesSinceLastDigest + bytesToaccept;
    }
}
```

Changes: The `Add()` method now calls `BytesToAcceptFromSource()` to decide how much entropy it should actually accumulate into the hash function.
That's where most of the logic lies.

And it also keeps track of the counters. 
Minor gotcha: given a long lived pool, a single source may exceed `Int32` bytes.
My solution is to ignore overflow: that is, I assume that once we have more than 2^31 bytes of entropy from multiple sources, an attacker is going to struggle to guess the results anyway.

Lets look at `BytesToAcceptFromSource()`:

```c#
// Allowed 0.0 to 1.0, default of 0.6 in constructor.
private readonly double _MaxSingleSourceRatio;      
// Set to 3/4 of the hash size (48 bytes when the default of SHA512 is used).
private readonly int _SingleSourceCountAppliesFrom;
// After this many sources, we don't bother with the single source rule.
private static readonly int MaxSourcesToCount = 256;

private int BytesToAcceptFromSource(int byteCount, int countFromSource)
{
    // When minimal entropy has been received, we accept everything.
    if (EntropyBytesSinceLastDigest < _SingleSourceCountAppliesFrom)
        return byteCount;
    // If we have a stack of sources, we accept everything.
    if (_CountOfBytesBySource.Count > MaxSourcesToCount)
        return byteCount;

    // Allow a pool with evenly split sources to exceed the threshold by a small amount.
    var halfHashLength = _QuarterHashLengthInBytes * 2;
    var allowExtraBytes = _CountOfBytesBySource.Count > 1 
                    && (_CountOfBytesBySource.Values.Max() - _CountOfBytesBySource.Values.Min() <= halfHashLength);
    var extraAllowance = allowExtraBytes ? halfHashLength : 0;

    // Otherwise, we enforce the source ratio.
    var maxBytesAllowed = (int)(
                            (EntropyBytesSinceLastDigest > Int32.MaxValue ? Int32.MaxValue : (int)EntropyBytesSinceLastDigest) 
                            * _MaxSingleSourceRatio
                        )
                        + extraAllowance;
    var result = maxBytesAllowed - countFromSource;
    if (result < 0)
        return 0;
    else
        return Math.Min(byteCount, result);
}
```

The first gotcha is the ratio doesn't apply until a minimal amount of entropy has been gathered.
That's what `_SingleSourceCountAppliesFrom` is all about.
That is, the very first packet technically is 100% of the pool!
So until we've accumulated 3/4 of the hash size, we accept everything from any source.

I don't want the pools to allocate too much memory keeping track of bytes received from each source.
So there's a 256 source limit.
I figure with that many sources, things should be pretty well mixed!

`maxBytesAllowed` is the core of the calculation. 
It works out how many bytes the current can have as a maximum, based on the allowed ratio.
And a subtraction and `Math.Min()` will get the final number of bytes it will accept.
This also allows for accepting partial packets (ie: 16 of 32 bytes).

The real gotcha is `extraAllowance`.
It turns out you can "deadlock" the algorithm if you set the ratio to `0.5` and interleave 2 sources producing equal sized packets of entropy.
Basically, each source get to the 48 byte minimum, and any additional entropy exceeds the 50% limit.
So nothing further is accepted.
(And, yes, I only noticed this after I wrote a unit test to that effect).

There are a few ways to overcome this problem.
`extraAllowance` could allow the pool to exceed the threshold by up to half the hash size (usually 32 bytes), which is enough always allow the algorithm to make progress (albeit more slowly).
You could have more than 2 sources: 3 or more doesn't run into this problem because the 50% threshold becomes 33% (or 25% for 4, etc).
Or, you could change the threshold: `0.6` is enough to allow 2 sources to work.

In the end, `extraAllowance` is the general solution, and using 60% threshold rather than 50% provides additional insurance.


### Buffered Generators

The main PRNG in Terninger is the `CypherBasedPrngGenerator`.
Fortuna requires the generator to destroy its key, generator a new one and re-key after every call.
This provides [forward secrecy](https://en.wikipedia.org/wiki/Forward_secrecy), which means an attacker can't rewind the generator to work out previously generated numbers if they work out the current seed.

Unfortunately, it's also painfully slow for the most common use cases of random number generators: requesting single `Int32`s.
As an example, the when the default `CypherBasedPrngGenerator` is asked for a single `Int32`, it will generate 48 bytes: 4 bytes for your `Int32`, 32 bytes for a new seed, and 12 bytes are discarded (because it can only produce 16 byte blocks).

But 44 wasted bytes is only half the story.
The *re-keying* part of the operation is slow.
As in 100x slower than the encrypting part: my laptop can encrypt 128 bytes in 25 ns, but to re-key the AES cypher takes 2400 ns.

Now imagine our generator produced a larger block of bytes (instead of absolute minimum) and stored that in an internal buffer for future requests.
What would that mean?

Lets think about the security impact first: as long as the generator still re-keyed after filling its buffer, we haven't lost our forward secrecy property.
The main impact is the next, say, 1024 bytes of random-ness is sitting in memory.
And if an attacker read that buffer somehow, they could just read the numbers straight up.
Of course, the attacker could also just read the current seed value and know **all** the random numbers this particular generator will every produce (at least until the next re-seed from an external entropy source like `PooledEntropyCprngGenerator`).
So, there are risks to a buffer, but I think they're acceptable.

What about performance: well, lets do some math.
Assume we're asking for each `Int32` individually (as any normal programmer would do), and running on my laptop (2400 ns to re-key, 25 ns to encrypt 64 bytes).

| # Int32s | Buffer Size | # Re-key's | Encrypted | Total Time    | Avg per Int32 |
|----------|-------------|------------|-----------|---------------|---------------| 
| 1        | 48 B        | 1          | 48 B      | ~2,450 ns     | ~2,450 ns     |
| 10       | 48 B        | 10         | 480 B     | ~24,200 ns    | ~2,420 ns     |
| 100      | 48 B        | 100        | 4800 B    | ~242,000 ns   | ~2,420 ns     |
| 1000     | 48 B        | 1000       | 48000 B   | ~2,400,000 ns | ~2,400 ns     |
| 1        | 1024 B      | 1          | 1024 B    | ~2,800 ns     | ~2,800 ns     |
| 10       | 1024 B      | 1          | 1024 B    | ~2,800 ns     | ~280 ns       |
| 100      | 1024 B      | 1          | 1024 B    | ~2,800 ns     | ~28 ns        |
| 1000     | 1024 B      | 4          | 4096 B    | ~11,200 ns    | ~11 ns        |

The theory says the buffered version would be better in every case except when we only ever ask for a single `Int32`.
And the more we ask for, the better the numbers get.

But don't take my maths as gospel, here's some [Benchmark .NET](https://github.com/dotnet/BenchmarkDotNet) numbers for how long it takes to generate a single `Int32`.
Clearly there's more going on than the theory is accounting for, but the 100x difference is still there.

```
BenchmarkDotNet=v0.10.14, OS=Windows 10.0.17134
Intel Core i5-7200U CPU 2.50GHz (Kaby Lake), 1 CPU, 4 logical and 2 physical cores
Frequency=2648438 Hz, Resolution=377.5810 ns, Timer=TSC
  [Host]     : .NET Framework 4.7.1 (CLR 4.0.30319.42000), 64bit RyuJIT-v4.7.3101.0
  DefaultJob : .NET Framework 4.7.1 (CLR 4.0.30319.42000), 64bit RyuJIT-v4.7.3101.0

 Method | BufferSize |         Mean |       Error |        StdDev |       Median |
------- |----------- |-------------:|------------:|--------------:|-------------:|
  Int32 |          0 | 12,766.34 ns | 255.2198 ns |   672.3510 ns | 12,628.43 ns |
  Int32 |       1024 |    170.91 ns |   2.2647 ns |     2.0076 ns |    170.91 ns |
  Int32 |       4096 |    146.40 ns |   5.4031 ns |    15.7611 ns |    138.61 ns |
```

Based on all that, Terninger defaults to a 1kB buffer for all `CypherBasedPrngGenerator`s, but gives you the option of unbuffered if you prefer.


### Configure the Pooled Generator

[In part 1](/2017-05-08/Building-A-CRNG-Terninger-1-Introduction.html), I said that I wanted Terninger to have useful defaults, but all the knobs and dials required to customise its operation.
When I left the `PooledEntropyCprngGenerator` last time it let you supply the PRNG, the accumulator and entropy sources.
But gave you no way to control how often it re-seeded or how quickly it gathered entropy.

Well, there is now a `PooledGeneratorConfig` class.

**Reseeds** are controlled by time (between 100 ms and 12 hours), amount of randomness read from the generator (default: 16MB) and entropy read into the first pool (default: 128 bytes).
Exceed the time or amount read from the generator and a re-seed is forced.
However, in usual operation, the first pool will accumulate 128 bytes and trigger a re-seed.

Entropy source **Poll Period** is based on the priority level the generator is currently in.
*High* polls every millisecond (effectively no delay at all), *Normal* polls every 10 seconds, and *Low* polls every 60 seconds.

The generator jumps to *High* priority if an immediate re-seed is requested (or the generator has never been seeded).
It drops to *Normal* after the re-seed.
It can drop to *Low* when no random numbers have been requested from the generator, AND after some number of re-seeds (default: 10) or some period of time (default: 2 hours).

When in Fortuna mode, the defaults are changed such that low priority is not possible and re-seeds are more aggressive (triggered after less time and less requested random numbers).


## Into Production!

OK, we've improved the accumulator's security, made it generate numbers faster and added configuration options to the pooled generator.

Time to actually use Terninger in anger!

### Nice Entry Points

As I've been using Terninger in unit tests, I found certain patterns repeating themselves.
These repeated themselves again in [makemeapassword.ligos.net](https://makemeapassword.ligos.net).
So there are some nice entry points to quickly get you up and running.

```c#
namespace MurrayGrant.Terninger {
    public class RandomGenerator {
        public static PooledEntropyCprngGenerator CreateFortuna() { ... }
        public static PooledEntropyCprngGenerator CreateTerninger() { ... }
    }
}
```

These create the Fortuna or Terninger pooled generator.
Note that the generator hasn't started accumulating entropy just yet, so you can add more sources or change the settings (more on that below in `Actually Using It`).


```c#
namespace MurrayGrant.Terninger {
    public class RandomGenerator {
        public static IEnumerable<IEntropySource> StandardSources() { ... }
        public static IEnumerable<IEntropySource> NetworkSources(
                        string userAgent = null, 
                        string hotBitsApiKey = null, 
                        Guid? randomOrgApiKey = null) { ... }
        public static IEntropySource UserSuppliedEntropy(byte[] entropy) { ... }
    }
}
```

These are 3 common sources of entropy.
`StandardSources()` are actually already included in `CreateTerninger()` and `CreateFortuna()`, but they are the timing, memory and environmental stats.
`NetworkSources()` are the ones which generate active network traffic; you need to opt-in for these.
`UserSuppliedEntropy()` is a simple way to push a one-off packet of entropy into the generator at startup.


```c#
namespace MurrayGrant.Terninger {
    public class RandomGenerator {
        public static IRandomNumberGenerator CreateCypherBasedGenerator() { ... }
        public static IRandomNumberGenerator CreateCypherBasedGenerator(byte[] seed) { ... }
        public static IRandomNumberGenerator CreateUnbufferedCypherBasedGenerator() { ... }
        public static IRandomNumberGenerator CreateUnbufferedCypherBasedGenerator(byte[] seed) { ... }
    }
}
```

Finally, these are ways to create the `CypherBasedPrngGenerator`.
Effectively, these are `System.Random` on steroids.
That is, they are deterministic random bit generators, or pseudo random number generators based on an initial seed.
You can either supply your own seed, or let it derive a seed from the system crypto random number generator.

The main improvement of these over `System.Random` is they require a 32 byte seed, while `System.Random` can only accept a 4 byte seed.
This means a `CypherBasedPrngGenerator` has 2^256 possible output streams (a really big number), compared to 2^32 for `System.Random`.

There are plenty of applications for a random generator which need more than 2^32 combinations.
Eg: all possible combinations of a deck of cards. 
And because this is pseudo random, if you use the same seed you get the same sequence of random numbers, which might be useful in distributed scenarios (eg: real time strategy games). 


### Settable Source Names

As I was watching the log messages produced over a few hours, I found the default naming convention for entropy sources was... overly verbose.
It also didn't allow any consumer to customise the name (eg: say I have several generators of the same type, but with different parameters).
They were previously named the full namespace and type name of the entropy source class.

Now, they have settable names.
By default, they use the type name without namespace, unless you supply your own name. 
And when you add them to a `PooledEntropyCprngGenerator` if the name is already in use the generator unique-ifies them with a number (eg: "TimerSource 1", "TimerSource 2", etc).

This makes the logs just that little bit easier to read.


### Actually Using It

Here's the actual (and recommended) usage pattern in [makemeapassword.ligos.net](https://makemeapassword.ligos.net).

```c#
using System.Configuration;
using MurrayGrant.Terninger;
using MurrayGrant.Terninger.Generator;

public static class RandomService {
    public static readonly PooledEntropyCprngGenerator PooledGenerator =
            RandomGenerator.CreateTerninger()
            .With(RandomGenerator.NetworkSources(
                userAgent: "Mozilla/5.0; Microsoft.NET; makemeapassword.ligos.net; makemeapassword@ligos.net; bitbucket.org/ligos/Terninger",
                hotBitsApiKey: ConfigurationManager.AppSettings["HotBits.ApiKey"],
                randomOrgApiKey: ConfigurationManager.AppSettings["RandomOrg.ApiKey"].ParseAsGuidOrNull()
                )
            )
            .StartNoWait();
}
```

This creates the standard Terninger generator (`PooledEntropyCprngGenerator`), adds network sources, configures a polite useragent and a few API keys, and starts it going.
I know [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) is all the rage these days, but this is the plain old CLR singleton pattern, which works just fine (`PooledEntropyCprngGenerator` is threadsafe).
The singleton is recommended because `PooledEntropyCprngGenerator` is quite heavyweight (it owns a CLR thread, the accumulator and associated pools, and takes a non-trivial amount of time to initialise), and you only need it to produce small amounts of entropy (enough for cryptographic keys; usually 32 bytes, perhaps as much as 1kB for large RSA keys).

The generator is not immediately usable after it starts; first it must gather a minimal amount of entropy.
There's an alternate `StartAndWaitForSeedAsync()` which you can `await` if you want to be sure Terninger is ready to roll.
Either way, once the first seed is generated, Terninger will never block when you request random numbers from it.


```c#
using MurrayGrant.Terninger;

public async Task UseRandomness() {
    using (var random = 
        await RandomService.PooledGenerator.CreateCypherBasedGeneratorAsync())
    {
        var randomInt = random.GetRandomInt32();
    }
}
```

You can use `PooledEntropyCprngGenerator` directly if you want, but you'll be contending between threads and there's a small amount of locking overhead.
The recommended pattern is to create (and seed) a separate `CypherBasedPrngGenerator` from the main `PooledEntropyCprngGenerator`, and use the lightweight generator for your random numbers.
The random generator is disposable, which zeros out the seeds when you're done with it.

As I'm starting Terninger and not waiting for the first seed, I need to `await CreateCypherBasedGeneratorAsync()` in case Terninger hasn't generated its first seed.
If you awaited the first seed already, you can call `CreateCypherBasedGenerator()` instead.

That's it!
The pattern is a) create a singleton `PooledEntropyCprngGenerator`, b) remember to `await` the first seed, c) use a `CypherBasedPrngGenerator` for your random numbers.


## Future Work

* I need to get Terninger up on **[nuget](https://www.nuget.org/)**.
* But before that, I'd like to port it to **[.NET Standard](https://docs.microsoft.com/en-us/dotnet/standard/net-standard)**, and possibly break the network sources out to a separate DLL.
* And .NET Standard implies at least a little **testing on Linux**.
* Polling the random sources can be slow, particularly at startup, so **polling in parallel** would improve that.
* Finally, Fortuna requires **serialisation of the internal state of the generator**, so it can restart quickly.


## Next Up

We now have a usable random generator based on Fortuna.
And its in use in at least one app!

You can see the [actual Terninger code in BitBucket](https://bitbucket.org/ligos/terninger/src/12a95faff94039b6a520932d35defb1ae7fa5999/Terninger/?at=default).
And the [code for makemeapassword.ligos.net](https://bitbucket.org/ligos/makemeapassword/src/d39f2c1f46aa6de7ce25284f07258d6f55573f20/MakeMeAPassword.Web/Services/RandomService.cs?at=default&fileviewer=file-view-default) as well.

Next up, .NET Standard and nuget.



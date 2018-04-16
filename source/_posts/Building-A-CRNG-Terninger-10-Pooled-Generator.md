---
title: Building a CPRNG called Terninger - Part 10 Pooled Generator
date: 2018-04-16  
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

The Pooled Generator writing to console.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/).

So far, we have a *Pooled Generator* which implements does everything we need: gathering entropy, accumulating it over time, and generating random output based on regular re-keying. 


## Goal

Make the Pooled Generator usable from the console app.

And clean things up.


## Clean Up

There were plenty of things which I didn't like about where I last left Terninger.
So time for a tidy up / refactor / improvement session.

### Remove Configuration / Initialisation

The `IEntropySource.Initialise()` method was one that made me more and more uncomfortable as I coded.
This allows Entropy Sources to potentially scan for required hardware (eg: a hardware RNG), ask user for permission (eg: to use GPS data), or load configuration (eg: from an external file).

However, no sources interact with hardware yet.
So the whole idea is rather pointless.

And the configuration, while a nice idea, meant that the `IEntropySource` objects couldn't mark any fields `readonly`, and effectively had two ways of initialising: a constructor and the Initialise() method.
This lead to extra code in the `GetEntropy()` method, checking for nulls or silly values, when that should be done in the constructor.
I just couldn't guarantee the constructor would always be called and obvious object invariants enforced.

And, in the Pooled Generator's entropy loop, there was a section of initialisation which was... well... awkward.
It was there because it had to be, but didn't fit.

So, it's all gone!

By "gone" I mean "moved to another assembly".

I figure the idea of async initialisation and reading from config files is a good one.
But it's a value-add thing: it can be added later to make things better.
For now, programmers can just write a few more lines of code to do their own initialisation for now.
So, there's a `Terninger.Config` project with the configuration code, which can just sit there until I get around to finishing it off.



### Add Priority When Getting Entropy

The Pooled Generator has the notion of **Priority**.
**High** priority means it needs to re-key the internal RNG as soon as possible (usually because it's just been created).
**Normal** is when we need to keep entropy ticking over, re-keying at a reasonable frequency.
And **Low** priority means the generator hasn't been used in ages and should slow down a little, to reduce resource usage.

However, this notion of priority is useful to entropy sources as well.
Many are limited in some way (eg: most online generators have some kind of quota, hardware devices may be quite slow to gather entropy), so its nice to slow them down if their entropy isn't needed really urgently.
Conversely, if we need to re-key right now, lets ignore the quotas and limits and just get all the entropy we can lay our hands on!

So, the IEntropySource interface now knows the current generator priority:

```c#
public interface IEntropySource {
    Task<byte[]> GetEntropyAsync(EntropyPriority priority)
}
```

Each Entropy Source can choose to use that priority as it sees fit.
Some return more entropy in *High* priority (eg: `CryptoRandomSource`).
Most expensive sources work on a period to reduce resource usage (eg: network calls or high CPU usage), they scale their periods back in *Low* priority, and effectively ignore any periods / limits / quotas in *High* priority.


### Reorganise Entropy Sources

Entropy sources are pretty varied.
But there are 3 divisions by namespace now:

1. **Local** - sources which use local entropy (eg: current time, memory usage, or other environmental statistics).
2. **Network** - sources that actively generate network traffic (eg: ping timings, or HTTP requests to 3rd party random number generators).
3. **Testing** - sources that are really just for testing purposes (eg: null or counter sources).

If a consumer of Terninger doesn't want any network traffic (for whatever reason) its now very clear.

The most obvious future category I can think of is **Hardware** (for sources which require special hardware support).
But dividing things up by platform might make sense too (like *Linux*, *Android*, or *Windows*). 

And previously, I had all the 3rd party web-based random number generators in the same class.
This was a bit of a hang over from how I consumed them from [makemeapassword.org](https://makemeapassword.ligos.net), but didn't really fit with Terninger.
They now have one class each, which makes them easier to opt-in or out and configure.


### Unit Testing

There are now unit tests for all entropy sources, particularly the ones which generate network traffic.
Most of my coding happens when I don't have Internet access (ie: train trips or flights), so they were hard to test!
Well, they're tested now.

More than that, there's a clear split between classic unit tests and slower tests which aren't true "unit" tests in the [TDD](https://en.wikipedia.org/wiki/Test-driven_development) sense.
The `Terninger.Test` project is the unit tests, `Terninger.Test.Slow` are the rest.

There are effectively 2 categories in the *slow* bucket:

* Tests which run for a long period and log results to disk. Effectively "fuzzing" the tested code. This includes logging the output of *entropy sources* to disk so I can examine them later, the pattern the `EntropyAccumulator` follows, and the distribution of the `RandomNumberExtensions` like `GetRandomInt32()`.
* Tests which actually make network calls. These are slow by nature. And a few sources have pretty strict quotas, so I can't just spam them.

Because the "fuzzing" style tests are now explicitly marked as "slow", I run them harder. 
Usually by running them 10x longer.


### Improvements to Main Entropy Loop

The `PooledEntropyCprngGenerator.ThreadLoop()` method has been refactored significantly.
This code is what makes Terninger (and Fortuna) crypto-safe, so it makes sense to invest time in it.
(Usually I refer to this as the **main entropy loop**).

First off, there's a top level exception handler.
It doesn't do much other than `Dispose()` the generator and log a fatal exception.
But at least it doesn't kill the thread (which may take down the whole process).

```c#
try {
    ThreadLoopInner();
} catch (Exception ex) {
    Logger.FatalException("Unhandled exception in generator. Generator will now stop, no further entropy will be generated or available.", ex);
    this.Dispose();
}
```

The main loop now has lots of logging, mostly so I can see what's going on.
Most of the log messages are at *Trace* level, so it's very quiet by default.

The individual steps of the main entropy loop have been extracted to separate methods.
As more complexity and logging creeps into the loop, the separate methods make things much easier to understand.
The top level loop is essentially 4 method calls, a bit of logging and then sleeping before the next loop.

Finally, when polling source in *High* priority, the loop will end quickly once enough entropy has been accumulated.
That means, it will re-seed as soon as enough entropy is available.
(Previously, it would continue reading entropy from all remaining sources, which may take considerable time).



## Console App

OK, that's enough clean up!
I've added support to the console app to use the `PooledEntropyCprngGenerator`, so the crypto-safe generator is now accessible to anyone who can run a command line app!

```
PS C:\Users\...\Release> .\Terninger.exe --generator TerningerPooled
07:51:24 | INFO | MurrayGrant.Terninger.Console.Program | Terninger CPRNG   © Murray Grant
07:51:24 | INFO | MurrayGrant.Terninger.Console.Program | Generating 64 random bytes.
07:51:24 | INFO | MurrayGrant.Terninger.Console.Program | Source: non-deterministic CPRNG - MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator

7FAD2727C4C901DB555EBA5ECE12FB28FC46299A352833F0DE92991C5F321FA2EF03470470B727A54B96E5C1F1484139BC9F82E3A1F6D6E5A968D1B63014BD16

07:51:26 | INFO | MurrayGrant.Terninger.Console.Program | Generated 64 bytes OK.
```

### Different Generators

The main change to the console app is to add a `--generator` option, which allows the user to choose between several different random number generators:

* **StockRandom**: `System.Random`, the standard .NET RNG.
* **CryptoRandom**: `System.Security.Cryptography.RandomNumberGenerator`, the standard .NET crypto safe RNG.
* **TerningerCypher**: `Terninger.Generator.CypherBasedPrngGenerator`, the Terninger PRNG (default).
* **TerningerPooled**: `Terninger.Generator.PooledEntropyCprngGenerator`, the fully fledged Terninger CPRNG.

*StockRandom* and *TerningerCypher* are both deterministic, when they use the same seed value.
*CryptoRandom* takes no seed and leverages the OS crypto safe RNG, *TerningerPooled* uses the `IEntropySource` implementations to derive a seed. Neither *CryptoRandom* nor *TerningerPooled* are deterministic.

There are a couple of other new command line options, to control *TerningerPooled*:

* `--netSources`: enables network based `IEntropySource`'s (disabled by default).
* `--poolLinear` and `--poolRandom`: controls the number of pools used by the entropy accumulator.

Finally, there are `--debug` and `--trace` options to see more log messages, if you want to see what's going on under the hood.

```
PS C:\Users\...\Release> .\Terninger.exe --generator TerningerPooled --debug
08:01:23 | INFO | MurrayGrant.Terninger.Console.Program | Terninger CPRNG   © Murray Grant
08:01:23 | INFO | MurrayGrant.Terninger.Console.Program | Generating 64 random bytes.
08:01:23 | INFO | MurrayGrant.Terninger.Console.Program | Source: non-deterministic CPRNG - MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator
08:01:23 | DEBUG | MurrayGrant.Terninger.Console.Program |     Using 16+16 pools (linear+random), 7 entropy sources, crypto primitive: Default, hash: Default
08:01:23 | DEBUG | MurrayGrant.Terninger.Console.Program | Seed source: System environment.
08:01:23 | DEBUG | MurrayGrant.Terninger.Console.Program | Output target: Standard Output., style Hex

08:01:23 | DEBUG | MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator | Read 192 byte(s) of entropy from source 'MurrayGrant.Terninger.EntropySources.Local.NetworkStatsSource' (of type 'NetworkStatsSource').
08:01:23 | DEBUG | MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator | Read 4 byte(s) of entropy from source 'MurrayGrant.Terninger.EntropySources.Local.TimerSource' (of type 'TimerSource').
08:01:23 | DEBUG | MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator | Read 8 byte(s) of entropy from source 'MurrayGrant.Terninger.EntropySources.Local.CurrentTimeSource' (of type 'CurrentTimeSource').
08:01:25 | DEBUG | MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator | Read 1,440 byte(s) of entropy from source 'MurrayGrant.Terninger.EntropySources.Local.ProcessStatsSource' (of type 'ProcessStatsSource').
08:01:25 | DEBUG | MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator | Beginning re-seed. Accumulator stats (bytes): available entropy = 1644, first pool entropy = 64, min pool entropy = 36, max pool entropy = 64, total entropy ever seen 1644.
08:01:25 | DEBUG | MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator | After reseed in High priority, dropping to normal.
3BBC4F1D9E320F988203EC2270D1D5656D58ADB1FA087E29D97E35B38E2B9FE634BCDB4D797CA7A50B46431169527A59F74A32A0B9B024E1909C9F82095409A708:01:25 | DEBUG | MurrayGrant.Terninger.Generator.PooledEntropyCprngGenerator | Sending stop signal to generator thread.


08:01:25 | INFO | MurrayGrant.Terninger.Console.Program | Generated 64 bytes OK.
08:01:25 | DEBUG | MurrayGrant.Terninger.Console.Program | 64 bytes generated in 2.10 seconds (0.00MB / sec)
```


### Future Work

The main work outstanding is in the main entropy loop:

* It needs to be much smarter about when it re-seeds. Taking into account the time between last re-seed, how much entropy has been produced since last re-seed, priority, sleep durations, etc.
* There will need to be configuration (via the constructor) to control the above, with sane defaults.
* The entropy sources need to be queried in parallel to achieve better throughput.

Less major work includes:
* A buffered generator which doesn't re-seed after every request. Primarily to improve speed when generating individual random numbers (which is what 99% of consumers will be doing).
* Prevent individual accumulator pools being dominated by any one source. This reduces the risk of an adversary, which controls a "fire hose" source, being able to guess the internal state of the accumulator.
* A nice method to create a pseudo random generator from the main pooled generator.


## Next Up

We now have a usable random generator based on Fortuna.
And a console binary people can use to get randomness from it.

You can see the [actual code in BitBucket](https://bitbucket.org/ligos/terninger/src/ad9fd43fa2fdbe8b2471bd4e18fbae9fc29aa62e/Terninger/?at=default).

Next up, we will make a few of the improvements listed in *Future Work*.
And then, once I'm comfortable, consume the generator in a real app: [makemeapassword.ligos.net](https://makemeapassword.ligos.net).

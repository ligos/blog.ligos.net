---
title: Building a CPRNG called Terninger - Part 7 Entropy Accumulator
date: 2017-10-06
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

The accumulator to buffer incoming entropy and generate new seed material.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the Fortuna CPRNG.

So far, we have the PRNG `CypherBasedPrngGenerator` with various options, a console app which outputs random data to file or stdout, and can produce random numbers as well as bytes.


## Goal

Build the *accumulator* for Fortuna, as [specified](https://www.schneier.com/academic/paperfiles/fortuna.pdf) in section 9.5.

Effectively, the accumulator is a buffer which receives entropy from multiple sources, distributes that into many pools, then uses those pools to generate material to re-seed the core PRNG from time to time.

Or, as a very crude ascii diagram:

```
Raw entropy ->             -> pools ->
Raw entropy -> accumulator -> pools -> re-seed material
Raw entropy ->             -> pools ->
```

The accumulator is designed in such a way that the seed material it produces is extraordinarily unpredictable.
So unpredictable that an attacker would need to control every incoming source of entropy, over the entire lifetime of the generator to compromise it.

### Int128

But before I get into to actual accumulator, I'm going to introduce an `Int128` type.

There are numerous counters which will be ticking up over the lifetime of a Fortuna or Terninger instance.
Given that section 9.5.2 allows for a minimum lifetime for a Fortuna instance of **13 years**, I'm not convinced `Int64` will be big enough.

I'm not interested in building my own `Int128` type, so decided on [Alexander Logger's *BigMath*](https://github.com/everbytes/BigMath) implementation.
And I updated any counters in the `CypherBasedPrngGenerator` class to be `Int128`.

The main issue I found with `BigMath.Int128` is it was build with [unchecked](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/unchecked) on by default (which is the default for C#), while I have it off for Terninger (for paranoia sake).
Various unit tests failed with `OverflowException`; I needed to add a few `unchecked` blocks to make it work.


### Pools

Pools are defined in section 9.5.2 of the [Fortuna spec](https://www.schneier.com/academic/paperfiles/fortuna.pdf).
32 of them are specified for an accumulator, and entropy is distributed into them.

In theory, each pool is a binary buffer, of unlimited length.
In practise (and assumed in the spec), they are a hash function which keeps partially computing the hash of all incoming entropy, and produces the final result when they are emptied.

```c#
public sealed class EntropyPool
{
    private readonly HashAlgorithm _Hash;

    // Counters so we know how much entropy has accumulated in this pool.
    public Int128 TotalEntropyBytes { get; private set; }
    public Int128 EntropyBytesSinceLastDigest { get; private set; }

    // Default to SHA512 as the hash algorithm.
    public EntropyPool() : this(SHA512.Create()) { }
    public EntropyPool(HashAlgorithm hash)
    {
        _Hash = hash;
    }

    public void Add(EntropyEvent e)
    {
        // Accumulate this event in the hash function.
        _Hash.TransformBlock(e.Entropy, 0, e.Entropy.Length, null, 0);

        // Increment counters.
        TotalEntropyBytes = TotalEntropyBytes + e.Entropy.Length;
        EntropyBytesSinceLastDigest = EntropyBytesSinceLastDigest + e.Entropy.Length;
    }

    public byte[] GetDigest()
    {
        // As the final block needs some input, we use part of the total entropy counter.
        _Hash.TransformFinalBlock(BitConverter.GetBytes(TotalEntropyBytes.Low), 0, 8);
        EntropyBytesSinceLastDigest = Int128.Zero;
        return _Hash.Hash;
    }
}
```

Compared to the accumulator itself, a pool is very simple.

The spec recommends SHA256, but I am using SHA512 as the default.
`Add()` accepts some entropy, accumulates it in the hash function and then increments counters.
`GetDigest()` finalises the partial hash computation, resets a counter and returns the hash.


### An Entropy Event

Section 9.5.3.1 discusses what a "packet" of entropy should look like.
The entropy, length and pool number.

My implementation is a very basic immutable class.
C# arrays encode both the entropy and length, and I include the entropy source rather than destination pool, for reasons outlined below.

```c#
public sealed class EntropyEvent
{
    public byte[] Entropy { get; private set; }
    public Type Source { get; private set; }

    public EntropyEvent(byte[] entropy, Type source)
    {
        this.Entropy = entropy;
        this.Source = source;
    }
}
```

Fortuna specifies that the entropy sources should specify which pool to place their entropy in.
That assumes the sources are, at least for the most part, trustworthy.
Which the spec itself admits is an assumption which will not always be true: an attacker must be assumed to control some entropy source: either with knowledge of entropy produced, or ability to influence the entropy's content.
The spec goes on for some length about how it might guarantee entropy is correctly distributed amoung pools, before basically admitting it can't.

Time to play [threat model](https://en.wikipedia.org/wiki/Threat_model): Fortuna assumes it will be implemented in an OS kernel with public C style functions.
As such, it can't tell the difference between an attacker calling `Pool.Add()` with malicious or known entropy, and legitimate calls from real entropy sources.

Turninger is going to be in user processes without any cross-process public interface (at least out of the box).
So the above scenario is much less likely.
(Plugin entropy sources are planned, so that's a potential source of malicious code / entropy).
But the standard process boundary provides a reasonable degree of protection.

The other defence I have planned involves the `Source` property.
If an attacker seeds the accumulator with known entropy, its goal is to flood pools such that they are entirely known by the attacker.
Thus the attacker could derive the internal key.

However, as pools know the `Source` of entropy, they could simply discard tainted packets.
Deciding *tainted* vs *legitimate* is [impossible](https://en.wikipedia.org/wiki/Halting_problem), but a pool can prevent any one source filling it.
That way, as long as some entropy is received from *different* sources, the attacker can never completely control a pool.

Now, a malicious source could simply lie and put the wrong type in the `Source` property.
This is basically the same attack the Fortuna spec considers.
However, its possible to verify the `Source` type matches the actual source instance at run time in the CLR (although the pool and accumulator probably can't do that).
And I'll take advantage of that fact in future work.

As a final note, and as mentioned in 9.5.3.1 of the spec, if an attacker has arbitrary access to the address space of the process, all bets will be off. 
And, it will probably be simpler for them to just read (or even set) the current key material and be done with it (and in the CLR, all that would take is a reflected call against a private field or method).


### The Accumulator

The accumulator contains multiple pool objects and manages access to them.
9.5.2 specifies 32 pools, and I'll allow between 4 and 64.

(There are a stack of counters, statistics and other properties on the class.
In the interest of brevity, I'll omit them here).

```c#
public sealed class EntropyAccumulator
{
    private readonly EntropyPool[] _Pools;
    private ulong _ReseedCount;
    private int _PoolIndex;

    public EntropyAccumulator(int poolCount, Func<HashAlgorithm> hashCreator)
    {
        _Pools = new EntropyPool[poolCount];
        for (int i = 0; i < _Pools.Length; i++)
            _Pools[i] = new EntropyPool(hashCreator());
        _ReseedCount = 0;
        _PoolIndex = 0;
    }

    public void Add(EntropyEvent entropy)
    {
        if (_PoolIndex >= Pools.Length)
            _PoolIndex = 0;
        _Pools[_PoolIndex].Add(entropy);
        _PoolIndex = _PoolIndex + 1;
    }
    
    public byte[] NextSeed()
    {
        ulong reseedCount = unchecked(_ReseedCount + 1);

        // Get digests from all the pools to form the final seed.
        // The poolsUsedMask tells us which pools were selected, primarily for unit testing.
        var digests = new List<byte[]>();
        ulong poolsUsedMask = GetDigestsFromPools(digests, reseedCount);

        // Flatten the result.
        // PERF: a block copy function will likely be faster.
        var result = digests.SelectMany(x => x).ToArray();

        // Update counters and other properties.
        _ReseedCount = reseedCount;
        TotalReseedEvents = TotalReseedEvents + 1;
        PoolsUsedInLastSeedGeneration = poolsUsedMask;

        return result;

    }

    private ulong GetDigestsFromPools(ICollection<byte[]> digests, ulong reseedCount)
    {
        // Based on Fortunata spec 9.5.5
        // Will always add at least one digest from a pool (pool zero).
        ulong poolsUsedMask = 0;
        for (int i = 0; i < _Pools.Length; i++)
        {
            if (PoolIsUsed(i, reseedCount))
            {
                digests.Add(_Linear[i].GetDigest());
                poolsUsedMask = poolsUsedMask | (1UL << i);
            }
        }
        return poolsUsedMask;
    }

    private static bool PoolIsUsed(int i, ulong reseedCount)
    {
        // 9.5.2
        // Pool P[i] is included if 2^i is a divisor of r. Thus, P[0] is used every reseed, P[1] every other reseed, P[2] every fourth reseed, etc
        var pow = ULongPow(2, i);
        var remainder = reseedCount % pow;
        var result = remainder == 0;
        return result;
    }
}
```

So far, this follows the Fortuna spec quite closely (aside from the accumulator managing the pools, which is disallowed in section 9.5.3.1, but I'll mitigate in other ways, as outlines above).

`Add()` distributes the incoming entropy across pools in a round-robin fashion.
It assumes all incoming entropy is of similar size, which won't be the case, so it could split larger chunks into 8 or 16 bytes and distribute across more pools.
Otherwise, it doesn't get much simpler.

The real interest is in `NextSeed()`.
This walks all pools and checks if each will be used in deriving key material.
Based on the Fortuna spec, larger numbered pools are included less often.
Pool zero is always used, pool one is used every second request, pool two every fourth, and so on. 
This means that entropy accumulated in the distant past (possibly weeks or years ago) is occasionally included in a new seed, which makes for a very unpredictable result - just what a crypto random number generator needs!


### Distribute Larger Packets of Entropy

As mentioned above, a 1kB packet of entropy (say from a [hardware random number generator](https://en.wikipedia.org/wiki/Comparison_of_hardware_random_number_generators)) would be placed in a single pool.
As would an 8 byte result from `DateTime.UtcNow`.
This isn't particularly fair, so lets fix it.

```c#
public void Add(EntropyEvent entropy)
{
    // Based on Fortunata spec 9.5.6

    // Entropy is added in a round robin fashion.
    // Larger packets are broken up into smaller chunks to be distributed more evenly between pools.
    var poolIndex = _PoolIndex;
    foreach (var e in entropy.ToChunks(_ChunkSize))
    {
        if (poolIndex >= _Pools.Length)
            poolIndex = 0;
        _Pools[poolIndex].Add(e, entropy.Source);
        poolIndex = poolIndex + 1;
    }
    _PoolIndex = poolIndex;
}
```

A 16 byte chunk size works well. 
It's smaller than any common hash function, so ensures good distribution of entropy from multiple sources against each pool.


### A Random Accumulator

Dodis et al proposes [distributing entropy using a PRNG](https://eprint.iacr.org/2014/167.pdf) in sections 5.2 and 6.3; that is in `Add()`.
Their rationale is it reduces the time for the accumulator to recover when faced with an attacker pushing large amounts of entropy into the generator.
That is, someone with a fire hose and flooding the lower numbered pools may be able to guess the internal state / key of the generator.
And it would take a while before enough untainted entropy arrived and enough re-seeds happened before the attacker loses that edge.

I don't quite understand Dodis's maths, but I would like to achieve the same end.
So, rather than randomising in `Add()`, Terninger will allow for *random pools* which are selected at random in `NextSeed()`.

The original pools are referred to as *Linear Pools*, for the sake of clarity.


```c#
public sealed class EntropyAccumulator
{
    // _Pools remains, but we also have...
    private readonly EntropyPool[] _RandomPools;
    private readonly IRandomNumberGenerator _Rng;

    // Contains the content of _Pools and _RandomPools, for ease of access.
    private readonly EntropyPool[] _AllPools;


    public byte[] NextSeed()
    {
        // Get the number used to determine which pools will be used.
        ulong reseedCount = unchecked(_ReseedCount + 1);

        // Get digests from all the pools to form the final seed.
        var digests = new List<byte[]>();

        // Linear pools.
        var linearPoolUsedMask = GetDigestsFromLinearPools(digests, reseedCount);

        // Random pools.
        var randomPoolUsedMask = GetDigestsFromRandomPools(digests);

        // Flatten the result.
        // PERF: a block copy function will likely be faster.
        var result = digests.SelectMany(x => x).ToArray();

        // Update counters and other properties.
        _ReseedCount = reseedCount;
        TotalReseedEvents = TotalReseedEvents + 1;
        LinearPoolsUsedInLastSeedGeneration = linearPoolUsedMask;
        RandomPoolsUsedInLastSeedGeneration = randomPoolUsedMask;

        return result;
    }

    private ulong GetDigestsFromRandomPools(ICollection<byte[]> digests)
    {
        // Based on Dodis et al sections 5.2 and 6.3.
        ulong randomPoolUsedMask = 0;
        if (_RandomPools.Length > 0)
        {
            // Create a bit mask to determine which pools to draw from.
            ulong randomPoolNumber = 0;
            ulong randomPoolMask = (1UL << (_RandomPools.Length)) - 1;
            var anyDigests = digests.Any();
            do
            {
                // Chance of random selection is at best 1/2, and may be less, depending on the value of _RandomFactor.
                randomPoolNumber = _Rng.GetRandomUInt64();
                for (int i = 0; i < _RandomFactor; i++)
                    randomPoolNumber = randomPoolNumber & _Rng.GetRandomUInt64();

                // If any random pools are defined, and there isn't already a digest, we must ensure at least one pool is drawn from.
            } while (!anyDigests && (randomPoolNumber & randomPoolMask) == 0);

            // Read from pools.
            for (int i = 0; i < _RandomPools.Length; i++)
            {
                if (PoolIsUsedRandom(i, randomPoolNumber))
                {
                    digests.Add(_RandomPools[i].GetDigest());
                    randomPoolUsedMask = randomPoolUsedMask | (1UL << i);
                }
            }
        }
        return randomPoolUsedMask;
    }    

    private static bool PoolIsUsedRandom(int i, ulong rand)
    {
        var maybeSetBit = rand & (1UL << i);
        return maybeSetBit > 0;
    }    
}
```

Turninger now adds entropy from the random pools to the normal / "linear" pools.
Currently, there is a 1 in 8 chance each of the random pools will be used.
A simple bit mask is used to determine if each pool will be included.
And their usage pattern should be unpredictable (unless you know the key behind the PRNG).

So now higher order pools are used, which gains the best of both worlds.


### Testing the Accumulator

There are a variety of unit tests which sanity check core behaviours of the accumulator and pools.
But I also include some statistics of the first 1000 seeds generated as a text file, which should illustrate how the whole accumulator works (and sanity check its working correctly).

The output below is the first 64 seeds.
It's a delimited / fixed width text file with the following columns:

1. Seed number
2. Entropy in the accumulator **before** the seed was generated
3. Number of pools drawn on for that seed
4. Bit mask of linear pools drawn on
5. Bit mask of random pools drawn on

Things of note:

* The accumulated and unused entropy is slowly ticking up, as not all pools are drawn on for each seed.
* There is a clear pattern to how the linear pools are used.
* There is no clear pattern to the random pools.

```
Seed:Ent'py:# :Pools (linear)  :Pools (random)   
0001:000512:03:               1:1100000000000000
0002:000976:04:              11:            1100
0003:001376:03:               1:      1010000000
0004:001776:05:             111:     10000010000
0005:002048:04:               1:      1000001010
0006:002384:03:              11:            1000
0007:002832:06:               1:  10001000100101
0008:002880:05:            1111:             100
0009:003136:03:               1:      1000000001
0010:003568:06:              11:  10100101000000
0011:003504:04:               1:      1010001000
0012:003760:05:             111:     10010000000
0013:004016:03:               1:   1000000100000
0014:004208:03:              11:       100000000
0015:004608:05:               1:  11000000011000
0016:004752:07:           11111:   1000000000001
0017:004640:02:               1:1000000000000000
0018:004880:03:              11:     10000000000
0019:005248:02:               1:              10
0020:005520:05:             111:1000010000000000
0021:005840:02:               1:  10000000000000
0022:006240:03:              11:      1000000000
0023:006528:03:               1:       100000100
0024:006640:09:            1111:1100010001000100
0025:006176:03:               1:       100000001
0026:006496:03:              11:              10
0027:006848:03:               1:              11
0028:007296:06:             111: 100010000100000
0029:007328:05:               1: 100000000010011
0030:007520:05:              11:1010001000000000
0031:007616:01:               1:               0
0032:008112:08:          111111:   1000000000001
0033:007312:02:               1:              10
0034:007744:03:              11:   1000000000000
0035:008176:08:               1:   1010001111010
0036:007808:06:             111: 100000100100000
0037:007904:01:               1:               0
0038:008400:03:              11:              10
0039:008816:05:               1:1000110000000010
0040:008624:06:            1111:     10100000000
0041:008816:04:               1: 110000001000000
0042:008960:03:              11:       100000000
0043:009392:07:               1:1110000000101100
0044:009216:06:             111:1000100000000010
0045:009440:03:               1:            1010
0046:009888:04:              11:   1000000010000
0047:010000:08:               1: 100011100110100
0048:009824:08:           11111:  10010000000010
0049:009696:02:               1:            1000
0050:010128:03:              11:           10000
0051:010544:03:               1:      1000000001
0052:010672:04:             111:    100000000000
0053:010944:02:               1:           10000
0054:011392:08:              11:  10010000111001
0055:011408:03:               1:      1010000000
0056:011152:05:            1111:       100000000
0057:011280:04:               1:    100001010000
0058:011392:04:              11:    100000010000
0059:011824:04:               1:       100011000
0060:012176:04:             111:          100000
0061:012480:05:               1:   1010010000010
0062:012320:06:              11:   1001000001100
0063:012368:04:               1:    101010000000
0064:012736:09:         1111111:     10000000100
```


### Future Work

There are a few improvements I can think of.

The accumulator is currently not **thread safe**.
This almost certainly needs to change when entropy comes from real sources.
But I'm hesitant to add locks until I know what the access and usage patterns will be.

I already mentioned that pools could **reject incoming entropy** based on its source.
Preventing any single source dominating a pool is the most obvious use of this property.
Other heuristics could be used as well, but I can't think of any with such a clear benefit for minimal effort.

Pools could validate the source `Type` implements an appropriate interface.
This very slightly raises the bar for any attacker.
Although its trivial for a malicious source to implement the right interface, so there seems little point.


## Next Up

The accumulator has been implemented and does everything Fortuna requires, plus more.
It even produces new seed material to send to the `CypherBasedPrngGenerator`, which would make the PRNG crypto safe.

You can see the [actual code in GitHub](https://github.com/ligos/terninger/tree/83737e75948013d4bbee7ec0f21f38a0863320e5).

Next up, we'll implement some basic entropy sources (very similar to the *cheap entropy* already generated). 
And the key component to connect all our objects together and make them useful: a scheduler to do all the things which need *doing*.
(That is, a thread to actually do the work).



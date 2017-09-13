---
title: Building a CPRNG called Terninger - Part 6 Additional Crypto Primitives
date: 2017-09-13
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

Give developers the option to use other block cyphers or hash algorithms.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the Fortuna CPRNG.

So far, we have the PRNG `BlockCypherCprngGenerator`, a console app which outputs random data to file or stdout, and can produce random numbers as well as bytes.


## Goal

Programmers love options, even if we won't end up using them.
Although the [Fortuna spec](https://www.schneier.com/academic/paperfiles/fortuna.pdf) specifies the use of AES-256 and SHA256 the the cryptographic primitives, it says other block cyphers could be used ([Blowfish](https://en.wikipedia.org/wiki/Blowfish_&#40;cipher&#41;) is mentioned by name).

I want the PRNG to be able to use any logical combination of crypto functions.
Note the PRNG needs a random bit generator (which could be a block cypher or hash function) and a hash function (for mixing key material).

Eg: AES-128 + SHA256, or Rijndael-256 + SHA512, or HMAC-SHA256 + SHA256.

We should also be able to use different implementations of a cypher / hash function (eg: managed vs native).


### Cypher Counter

Fortuna assumed a 16 byte *block size*.
While 16 bytes is a good minimum, but there's no reason why that block size couldn't be larger.

Fortuna treats this block as both a buffer (which it encrypts to generate pseudorandom bits) and a counter (which it increments).
My original implementation used a fixed 16 byte buffer, which it incremented in two 64 bit parts (using exception handling as flow control):

```c#
private void IncrementCounterData()
{
    try {
        ulong c1 = BitConverter.ToUInt64(_CounterData, 0) + 1;
        var c1Bytes = BitConverter.GetBytes(c1);
        Buffer.BlockCopy(c1Bytes, 0, _CounterData, 0, c1Bytes.Length);
    } catch (OverflowException) {
        // Lower half overflowed: increment the upper half and reset lower.
        try {
            ulong c2 = BitConverter.ToUInt64(_CounterData, 8) + 1;
            var c2Bytes = BitConverter.GetBytes(c2);
            Array.Clear(_CounterData, 0, 8);
            Buffer.BlockCopy(c2Bytes, 0, _CounterData, 8, c2Bytes.Length);
        } catch (OverflowException) {
            // Both overflowed: reset counter.
            Array.Clear(_CounterData, 0, _CounterData.Length);
        }
    }
}
```

I toyed with various obscure c# constructs (like [fixed buffers in a struct]) to create a really nice abstraction of an `Int128` or `Int256`. 
(Perhaps the [Span<T> class](https://github.com/dotnet/corefxlab/blob/master/docs/specs/span.md) [may help](http://adamsitnik.com/Span/), but it's quite experimental at this time).
And all the crypto functions operate on `byte[]`, so it was just easier to use a byte array and `BitConverter` to create the counter.


```c#
public class CypherCounter
{
    private readonly byte[] _Counter;
    public int BlockSizeBytes { get; private set; }     // Of the cypher.

    public void Increment() { ... }
    public void EncryptAndIncrement(ICryptoTransform cypher, byte[] buffer, int blockNumber) 
    {
        cypher.TransformBlock(...);
        Increment();
    }
}
```

The basic interface is straight forward enough: the counter is now encapsulated in a class.
We can `Increment()` or `EncryptAndIncrement()`.
The former is mostly there for unit testing, the later means the `_Counter` never leaves this class, and is called from the PRNG.

The constructor (not shown) ensures the counter cypher block size and `_Counter` are correct (they should be equal).
And the class implements `IDisposable` (not shown) such that after it is destroyed it will throw an exception on use.

`Increment()` is split into a simple case (which only handles the lower `UInt64`), and the overflow case (which handles any size of counter).
Again, they use exception handling as flow control.

```c#
public void Increment()
{
    try {
        IncrementLower();
    } catch (OverflowException) {
        IncrementNested();
    }
}

private void IncrementLower()
{
    // PERF: common case.
    // Will throw on overflow.
    ulong c = BitConverter.ToUInt64(_Counter, 0) + 1;
    var bytes = BitConverter.GetBytes(c);
    Buffer.BlockCopy(bytes, 0, _Counter, 0, bytes.Length);
}
private void IncrementNested()
{
    // PERF: Uncommon case.
    var maxIterations = _Counter.Length / 8;
    for (int i = 0; i < maxIterations; i++)
    {
        try {
            // Will throw on overflow.
            ulong c = BitConverter.ToUInt64(_Counter, i * 8) + 1;       
            var bytes = BitConverter.GetBytes(c);
            Buffer.BlockCopy(bytes, 0, _Counter, i * 8, bytes.Length);
            // If this does not overflow, we should break out of the loop.
            return;     
        } catch (OverflowException) {
            // On overflow, clear the chunk we just overflowed on, and loop to increment the next chunk.
            Array.Clear(_Counter, i*8, 8);
        }
    }
}
```

Currently, it works in `UInt64` chunks, which means `_Counter` must be a multiple of 8 bytes.
This is no problem for most modern cyphers and hash functions.
But to support older functions like 3DES `IncrementNested()` would need to handle `UInt32`, `UInt16` and `Byte` sized parts in the last iteration of the loop, and that's just too much complexity for now.


### Other Cyphers

Now the counter is abstracted away, we can allow a cypher to be passed via the constructor, as long as it implements `SymmetricAlgorithm`.

```c#
public class BlockCypherCprngGenerator {
    public BlockCypherCprngGenerator(byte[] key, SymmetricAlgorithm encryptionAlgorithm) 
    {
        ...
        encryptionAlgorithm.BlockSize = _BlockSizeInBytes * 8;
        encryptionAlgorithm.KeySize = _KeySizeInBytes * 8;
        encryptionAlgorithm.Key = new byte[_KeySizeInBytes];
        encryptionAlgorithm.IV = new byte[_BlockSizeInBytes];
        _Cypher = encryptionAlgorithm;
        ...
    }
}
```

At this point, we simply keep adding arguments to the constructor (while leaving a nice sane default in place) to use with every combination of cypher and hash algorithm you can think of.
We can accept a specific counter value as well, so we don't have to start at zero.

```c#
public class BlockCypherCprngGenerator {
    public BlockCypherCprngGenerator(byte[] key
            , SymmetricAlgorithm encryptionAlgorithm
            , HashAlgorithm hashAlgorithm
            , CypherCounter initialCounter) 
    {
        // Lots of validation logic here.
        ...
    }
}
```

We just need to make sure we pass a reasonable combination of algorithms.
A list of validation criteria:

* The cypher controls the block size (16, 32 and 64 bytes are possible, 32 only available via Rijndael (the cypher underlying AES) or hash functions, 64 bytes only via SHA512).
* Block and key sizes must be 16, 32 or 64 bytes.
* The length of the initial key passed in must actually match the cypher key size.
* The counter length must match the cypher block size.
* The hash algorithm must produce at least as many bytes as the key.



### Additional (Cheap) Entropy

A rather embarrassing problem I ran into with my [ReadablePassphrase KeePass plugin](https://bitbucket.org/ligos/readablepassphrasegenerator/wiki/0.17.0-Fix-for-Non-Random-Passphrases) was the random number generator got disposed when I didn't expect, but kept on producing predictable random numbers (basically from a zero seed).
One way to mitigate this is to allow a source of entropy to be injected into the re-key events.
(The other way is for the generator to throw an exception when disposed, but that doesn't make for a very exciting blog post).

The generator accepts a `Func<byte[]>` which is expected to produce some amount of entropy,
which is incorporated into each new key.

```c#
public BlockCypherCprngGenerator(byte[] key, ...
        , Func<byte[]> additionalEntropyGetter) 
{ ... }

public void Reseed(byte[] newSeed)
{
    // As per spec: Compute new key by combining the current key and new seed material.
    var combinedKeyMaterial = _CryptoPrimitive.Key.Concat(newSeed);
    // Additional to spec: add the additional entropy, if any is supplied.
    var additionalEntropy = _AdditionalEntropyGetter();
    if (additionalEntropy != null && additionalEntropy.Length > 0)
        combinedKeyMaterial = combinedKeyMaterial.Concat(additionalEntropy);
    
    _CryptoPrimitive.Key = _HashFunction.ComputeHash(combinedKeyMaterial.ToArray())
                                .EnsureArraySize(_KeySizeInBytes);
}
```

The core generator should be as fast as possible, so the default providers of this entropy are classified as *cheap*.
On my laptop (which is ~5 years old), `CheapEntropy.Get16()` takes around 250ns, which is plenty fast enough.

It also needs to be highly portable (as I'd like to make Turninger run on [.NET Core](https://www.microsoft.com/net/core)), so entropy sources must be standard to .NET.
That leaves the most "interesting" sources of entropy unavailable, and we have to use timing and memory statistics.

```c#
public static byte[] Get16()
{
    // As the _CurrentProcess and _Stopwatch are both ThreadStatic.
    EnsureThreadStaticsInitialised();   

    var result = new byte[16]

    // Current date and time + CLR / GC memory stats.
    var ticks = DateTime.UtcNow.Ticks;
    var gcCollections = ((long)GC.CollectionCount(0) << 32)
                        & ((long)GC.CollectionCount(1) ^ (long)GC.CollectionCount(2));
    var gcTotalMemory = GC.GetTotalMemory(false);
    var a = BitConverter.GetBytes(ticks ^ gcCollections ^ gcTotalMemory);
    Buffer.BlockCopy(a, 0, result, 0, a.Length)

    // High precision timer ticks + Process working set & system uptime.
    var b = BitConverter.GetBytes(((long)Environment.TickCount << 32) ^ _CurrentProcess.WorkingSet64 ^ _Stopwatch.ElapsedTicks);
    Buffer.BlockCopy(b, 0, result, 8, b.Length)

    return result;
}
```

Two sources of time are used: `DateTime.UtcNow` and `StopWatch.ElapsedTicks`.
And two memory based sources: the current process working set and garbage collector statistics.
These are merged to fit in the 16 byte result.

Note, there is a `CheapEntropy.Get32()` which uses the same sources but does less merging.
This is slightly slower than the 16 byte version (~300ns).

An important feature of injecting additional entropy into the generator is it becomes non-deterministic.
When producing cryptographic keys, this is a desirable feature.
However, the same random number generator may be used for other tasks where determinism is preferred (eg: a [monte carlo simulation](https://en.wikipedia.org/wiki/Monte_Carlo_method) could be re-run using the same seed and produce the same result).
Also, when this generator is used with the larger Fortuna algorithm, Fortuna itself takes care of incorporating higher quality (and much more expensive) entropy.


### Using a Hash Function Instead of a Block Cypher

The generator can use any block cypher which implements `SymmetricAlgorithm`.
That lets us use managed and native versions of AES, and managed [Rijndael](https://msdn.microsoft.com/en-us/library/system.security.cryptography.rijndael.aspx) (the algorithm which underlies [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)).
But there are no other block cyphers in the .NET 4.5 BCL.

There are a bunch of hash functions, which should work just as well as a crypto primitive in generating pseudo random bits.
However, they don't implement `SymmetricAlgorithm`.
Instead, they all either directly implement `ICryptoTransform`, or can create an object which implements it.
And this is the core interface used to encrypt data (and thus create pseudo random bits).

So, there is an interface used to abstract all the different cyphers and hash algorithms to be *crypto primitives*. 


```c#
public interface ICryptoPrimitive : IDisposable
{
    string Name { get; }
    int KeySizeBytes { get; }
    int BlockSizeBytes { get; }
    byte[] Key { get; set; }
    ICryptoTransform CreateEncryptor();
}
```

This is effectively a drop in replacement for anything implementing `SymmetricAlgorithm`, as far as the PRNG is concerned.
(At this point, `BlockCypherCprngGenerator` got renamed to `CypherBasedPrngGenerator`).

```c#
public CypherBasedPrngGenerator(byte[] key
        , ICryptoPrimitive cryptoPrimitive
        ...) 
```

The `BlockCypherCryptoPrimitive` is a simple wrapper around any `SymmetricAlgorithm`.
So I won't bore you with details.


#### HashCryptoPrimitive

Things are more interesting with a `HashCryptoPrimitive`.
This lets you use anything that implements `HashAlgorithm` as a random bit generator (eg: MD5, SHA1, SHA2).
The key and block size is defined as the hash length (eg: 16 bytes for MD5, 32 for SHA256, 64 for SHA512).

An internal `HashAndKeyTransform` class implements `ICryptoTransform`. 
It combines the key and counter material in an array twice as large as the block / key size.
The key sits in the lower "chunk", the counter value is copied into the upper "chunk".
Then a hash is derived to get random bits.

```c#
internal class HashAndKeyTransform : ICryptoTransform {
    internal HashAndKeyTransform(HashAlgorithm hash, byte[] key) {
        _Hash = hash;
        _KeyAndData = new byte[key.Length * 2];
        _DataOffset = key.Length;
        Buffer.BlockCopy(key, 0, _KeyAndData, 0, key.Length);
    }

    public int TransformBlock(byte[] inputBuffer, int inputOffset, int inputCount, byte[] outputBuffer, int outputOffset) {
        // Incorporate the key and input into a single buffer, then hash.
        Buffer.BlockCopy(inputBuffer, inputOffset, _KeyAndData, _DataOffset, inputCount);
        var hashed = _Hash.ComputeHash(_KeyAndData);
        Buffer.BlockCopy(hashed, 0, outputBuffer, outputOffset, hashed.Length);
        return inputCount;
    }
}
```

#### HmacCryptoPrimitive

The `HmacCryptoPrimitive` works for any [HMAC](https://en.wikipedia.org/wiki/Hash-based_message_authentication_code) implementation (eg: HMAC-SHA256 or HMAC-SHA512).
In some ways, its a more natural fit to `ICryptoTransform`, as an HMAC already has a key.

However, there is a hitch: the .NET HMAC implementations don't let you change key part way through `TransformBlock()`.
So, the `HmacCryptoPrimitive` needs a `Func<HMAC>` to be able to create new instances, which happens whenever you set the Key property.

```c#
public class HmacCryptoPrimitive : ICryptoPrimitive {
    public HmacCryptoPrimitive(Func<HMAC> hmacCreator) {
        this._HmacCreator = hmacCreator;
        this._Hmac = hmacCreator();
    }
    public byte[] Key {
        get => _Hmac.Key;
        set 
            // Destroy the previous hmac.
            DisposeHmac();
            
            // As an HMAC cannot be re-keyed after it is first used, we recreate it completely on every re-key event.
            var hmac = _HmacCreator();
            hmac.Key = value;
            _Hmac = hmac;
        }
    }
}
```

Again, there is an internal class responsible for implementing `ICryptoTransform`.
This is simpler than normal hashes, as the key has already been incorporated into the HMAC.

```c#
internal class HmacAndKeyTransform : ICryptoTransform {
    internal HmacAndKeyTransform(HMAC hash) {
        _Hash = hash;
    }

    public int TransformBlock(byte[] inputBuffer, int inputOffset, int inputCount, byte[] outputBuffer, int outputOffset)
    {
        var hashed = _Hash.ComputeHash(inputBuffer, inputOffset, inputCount);
        Buffer.BlockCopy(hashed, 0, outputBuffer, outputOffset, hashed.Length);
        return inputCount;
    }
}
```

#### Static Instances

The `CryptoPrimitive` static class provides boiler plate methods to crate various common crypto primitives with the correct parameters.
These are used through the unit tests.

```c#
public static class CryptoPrimitive {
    public static ICryptoPrimitive Aes256()
    {
        var aes = Aes.Create();
        aes.KeySize = 256;
        return new BlockCypherCryptoPrimitive(aes);
    }
    public static ICryptoPrimitive Aes256Managed() => new BlockCypherCryptoPrimitive(new AesManaged() { KeySize = 256 });
    public static ICryptoPrimitive Aes128Managed() => new BlockCypherCryptoPrimitive(new AesManaged() { KeySize = 128 });
    public static ICryptoPrimitive Aes256Native() => new BlockCypherCryptoPrimitive(new AesCryptoServiceProvider() { KeySize = 256 });
    public static ICryptoPrimitive Aes128Native() => new BlockCypherCryptoPrimitive(new AesCryptoServiceProvider() { KeySize = 128 });

    public static ICryptoPrimitive HmacSha256() => new HmacCryptoPrimitive(() => new HMACSHA256(new byte[32]));
    public static ICryptoPrimitive HmacSha512() => new HmacCryptoPrimitive(() => new HMACSHA512(new byte[64]));

    public static ICryptoPrimitive Sha256() => new HashCryptoPrimitive(SHA256.Create());
    public static ICryptoPrimitive Sha512() => new HashCryptoPrimitive(SHA512.Create());
    public static ICryptoPrimitive Sha256Managed() => new HashCryptoPrimitive(new SHA256Managed());
    public static ICryptoPrimitive Sha512Managed() => new HashCryptoPrimitive(new SHA512Managed());
    public static ICryptoPrimitive Sha256Native() => new HashCryptoPrimitive(new SHA256Cng());
    public static ICryptoPrimitive Sha512Native() => new HashCryptoPrimitive(new SHA512Cng());
}
```


### Console App

I updated the console app to allow the above features to be used.
This isn't particularly exciting, but does allow a simple way to test different combinations of crypto primitives.

I also used the console app and [practrand](http://pracrand.sourceforge.net/) to check all the crypto primitives are actually random (or at least no worse than my more [detailed investigation](/2017-06-02/Building-A-CRNG-Terninger-4-Random-Tests.html)).


### Future Work

The generator can create around 60MB of random bytes per second (on an i3-7100), however this assumes it is creating relatively large chunks of randomness at a time (32kB chunks).

Most random generators are asked for individual `Int32` or `Double` values.
And the generator in its current state is highly inefficient at this (although I haven't tried benchmarking it yet).
It generates one block (16 or more bytes), derives the number from it, discards any unused bytes, and then generates 2 more blocks to re-key itself.
A buffered generator would greatly improve performance, at the cost of having some randomness pre-generator and potentially observable.

Also, using a stream cypher such as [Salsa](https://en.wikipedia.org/wiki/Salsa20) or [ChaCha](https://en.wikipedia.org/wiki/Salsa20) would provide another crypto primitive, but they are byte rather than block orientated.
And not available in the .NET 4.5 BCL.
So not just yet.


## Next Up

We've added various options to the core PRNG, allowing for different crypto primitives (cyphers and hash functions) and incorporation of some cheap, low quality entropy.

You can see the [actual code in BitBucket](https://bitbucket.org/ligos/terninger/src/0f237a68972316c037845d6651a2ddd52ec36c95/Terninger/Generator/CypherBasedPrngGenerator.cs?at=default).

We're going to start building the *accumulator* part of Fortuna.
That is, the part that gathers entropy, mixes it up and uses that to regularly re-seed the generator.


---
title: Building a CPRNG called Terninger - Part 2 Basic Generator
date: 2017-05-14
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

The core PRNG of Fortuna.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the Fortuna CPRNG.


## Goal

I'm going to build the core PRNG of Fortuna.
Or, as its called in the spec, *the generator*.
[Section 9.4 in Fortuna](https://www.schneier.com/academic/paperfiles/fortuna.pdf) outlines how the generator works.

First up, I'm going to follow the pseudo code and translate it into C# as obviously and closely as possible.
That is, using AES and SHA256 as the cryptographic primitives, hard coding everything, and generally trying not to think very hard.
Plus add some unit tests to establish basic functionality.

Longer term I'm be aiming to make most aspects of the generator customisable.

The final goal for the generator is to generate enough random data to get decent results from the [dieharder](http://www.phy.duke.edu/~rgb/General/dieharder.php) random tests.
That implies a simple console application to dump the binary numbers to stdout.


## Implementing the Generator

I'm going to copy the Fortuna pseudocode, and then provide the equivalent C# implementation.
And there will be some extra C# methods and decorations to round it all out.

### C# Boilerplate

Before I implement each method, as Fortuna defines, I'll create a few boilerplate C# artifacts.

First up is the `IRandomNumberGenerator` interface.
This will be the most basic abstraction over various implementations of random number generators in Turninger.
It will also be the target of all helper and extension methods (eg: `GetRandomInt32()`).

The decision to fill `byte[]`s rather than return `byte[]`s is to allow performance conscious callers to reduce allocations. 
There will be an extension method which returns a `byte[]` as a convenience.

`MaxRequestBytes` will be explained shortly.

``` c#
// Interface to any source of random numbers based on filling byte arrays.
public interface IRandomNumberGenerator {
    // Maximum number of bytes which can be requested from the generator in one call.
    int MaxRequestBytes { get; }

    /// Fills the array with random bytes.
    /// Array must be between 0 and MaxRequestBytes in size.
    void FillWithRandomBytes(byte[] toFill);

    /// Fills the array with count random bytes at the specified offset.
    // Count must be between 0 and MaxRequestBytes in size.
    void FillWithRandomBytes(byte[] toFill, int offset, int count);
}
```

Next is the `BlockCypherCprngGenerator` class, which will be the core random number generator.
It implements `IRandomNumberGenerator` from above, and also `IDisposable` as .NET's crypto classes also implement `IDisposable`.
The `Dispose()` method also gives opportunity to zero any seeds, keys or other potentially sensitive data.

I'm also adding some basic counters, to allow for slightly more effective unit tests.

``` c#    
public class BlockCypherCprngGenerator : IRandomNumberGenerator, IDisposable
{
    public long BytesRequested { get; private set; }
    public long BytesGenerated { get; private set; }

    private bool _Disposed = false;

    public void Dispose()
    {
        if (_Disposed) return;
        ...
        _Disposed = true;
    }    
}
```

### Section 9.4 - The Generator

Fortuna defines it's generator as a 256 bit block cypher (AES recommended) and a 128 bit counter to be encrypted by the cypher.
It also defines a maximum amount of data to be generated in a single request and re-seed event. 
This is to allow the possibility of duplicated blocks, which a true random source would produce now and then (and are apparently impossible with counter arrangement).

It's worth noting at this point that the class is not threadsafe in any way.
That is, it makes no use of locks or synchronisation primitives for highest possible single threaded speed.

``` c#    
public class BlockCypherCprngGenerator {
    // AES with 256 bit key, as specified in 9.4
    private readonly SymmetricAlgorithm _Cypher;
    // A 128 bit integer, and a string of bytes to be encrypted.
    private readonly byte[] _CounterData;           

    // SHA256, as specified in 9.4
    private readonly HashAlgorithm _HashFunction;
    
    public int MaxRequestBytes => 2 << 20;      // As sepecified in 9.4.4.

    // Block and key sizes in bytes, to help with array indexing.
    private const int _BlockSizeInBytes = 128 / 8;
    private const int _KeySizeInBytes = 256 / 8;
}
```

There's quite a bit more discussion in the Fortuna spec under 9.4, but the above is enough to get us started.


### 9.4.1 - Initialisation

Fortuna's initialisation method basically just sets things to zero.
I'm going to depart from that and require an external seed as part of initialisation.
That is, when you create this generator, it will re-seed itself as part of the constructor.


``` c#    
public class BlockCypherCprngGenerator {
    public BlockCypherCprngGenerator(byte[] key) 
    {
        if (key == null) throw new ArgumentNullException(nameof(key));
        if (key.Length != _KeySizeInBytes) throw new ArgumentOutOfRangeException(nameof(key), $"Key must be ${_KeySizeInBytes} bytes long.");

        // Create the cypher and set key / IV sizes.
        _Cypher = new AesManaged() {
            KeySize = 256,
            Key = new byte[_KeySizeInBytes],
            IV = new byte[_BlockSizeInBytes],
            Mode = CipherMode.CBC,
        };
        _CounterData = new byte[_BlockSizeInBytes];
        _HashFunction = new SHA256Managed();

        // Difference from spec: re key our cypher immediately with the supplied key.
        Reseed(key);
    }
}
```

### 9.4.2 - Reseed

The re-seed operation incorporates some amount of new seed data into the current seed.
It uses SHA256 to do this (which has the nice benefit of producing a new seed of exactly the same size as our cypher).
I follow the spec exactly here.

This method is public as consumers can use it to inject their own random seed data.

``` c#
public class BlockCypherCprngGenerator {
    public void Reseed(byte[] newSeed)
    {
        // Section 9.4.2 - Reseed
        if (newSeed == null) throw new ArgumentNullException(nameof(newSeed));
        if (newSeed.Length < _Cypher.Key.Length)
            throw new InvalidOperationException($"New seed data must be at least {_Cypher.Key.Length} bytes.");

        // Compute new key by combining the current key and new seed material using SHA 256.
        var combinedKeyMaterial = _Cypher.Key.Concat(newSeed).ToArray();
        _Cypher.Key = _HashFunction.ComputeHash(combinedKeyMaterial).ToArray();

        // Increment the counter data.
        IncrementCounterData();
    }
}
```

### 9.4.3 - Generate Blocks

This is where the real action is!
We allocate a buffer to hold the resulting random data, create an encryptor, then encrypt the required number of blocks and increment the counter.

The `ICryptoTransform` object returned by `_Cypher.CreateEncryptor()` is .NET's low level crypto primitive.
It encrypts or decrypts individual blocks from one buffer to another.
And also has a facility to process a final block, to deal with padding (although I don't care about that because we only ever encrypt whole blocks).

Most *how do I encrypt stuff* style of articles in .NET focus on using `CryptoStream`, and I don't think I've ever dealt with `ICryptoTransform` in my life.
So I checked [Reference Source](http://referencesource.microsoft.com/) to see exactly what it does, and found that [RijndaelManagedTransform](http://referencesource.microsoft.com/#mscorlib/system/security/cryptography/rijndaelmanagedtransform.cs,e30508030a4adc1e) (implementing `ICryptoTransform`) is where the guts of the AES implementation lives, including [TransformBlock()](http://referencesource.microsoft.com/#mscorlib/system/security/cryptography/rijndaelmanagedtransform.cs,86aba1eac502d0f7).
I also found that there's a whole stack of complexity tied up in deal with padding correctly.

``` c#
public class BlockCypherCprngGenerator {
    private byte[] GenerateRandomBlocks(int blockCount)
    {
        // Allocate result buffer according the number of blocks required.
        var result = new byte[blockCount * _BlockSizeInBytes];

        // Create an ICryptoTransform object.
        var encryptor = _Cypher.CreateEncryptor();
        // Encrypt the requested blocks into the result buffer.
        for (int i = 0; i < blockCount; i++)
        {
            encryptor.TransformBlock(_CounterData, 0, _CounterData.Length, result, i * _BlockSizeInBytes);
            // Increment the counter after each block.
            IncrementCounterData();
        }

        // Count bytes generated.
        BytesGenerated = BytesGenerated + result.Length;
        return result;
    }
}
```

### 9.4.4 - Generate Random Data

This is the final method, and main public interface to the PRNG.
It does some validation of number of bytes requested (that's where `MaxRequestBytes` comes in), 
creates sufficient random blocks to satisfy the request (which may be more bytes than are strictly required), 
copies the result into the buffer we were passed,
and finally re-seeds itself with random data from the generator.

The last re-seed step is one way Fortuna protects against 'rewinding' to previously generated values.
If an attacker manages to observe or derive the seed at a point in time, they can't reverse or guess the last value of the seed because you can't reverse the encrypted value (which is the whole point of encryption!).

However, once the bad guy learns the seed, they can easily 'fast forward' to future random values.
The only things which stop that is re-seeding using external entropy.
(But that's skipping well ahead of where we're up to).


``` c#
public class BlockCypherCprngGenerator {
    public void FillWithRandomBytes(byte[] toFill, int offset, int count)
    {

        // Validation.
        if (toFill == null) throw new ArgumentNullException(nameof(toFill));
        if (count <= 0) throw new ArgumentOutOfRangeException($"At least one byte of random data must be requested.");
        if (count > MaxRequestBytes) throw new ArgumentOutOfRangeException($"A maximum of {MaxRequestBytes} bytes of data can be requested per call.");

        // Determine the number of blocks required to fullfil the request.
        int remainder;
        var blocksRequired = Math.DivRem(count, _BlockSizeInBytes, out remainder);
        if (remainder > 0)
            blocksRequired = blocksRequired + 1;

        // Generate blocks and copy to output.
        // In the event the requested bytes are not a multiple of the block size, additional bytes are discarded.
        var randomData = GenerateRandomBlocks(blocksRequired);
        Buffer.BlockCopy(randomData, 0, toFill, offset, count);

        // After each request for random bytes, rekey to destroy evidence of previous key.
        // This ensures you cannot "rewind" the generator if you discover the key.
        var newKeyData = GenerateRandomBlocks(2);
        Reseed(newKeyData);

        // Counting bytes requested.
        BytesRequested = BytesRequested + toFill.Length;
    }
}
```

That's it!
An entire high quality PRNG built from existing and well known cryptographic functions.

My implementation comes to just under 200 lines of c#.
And that includes excessive comments for sake of public demonstration.

### Unit Tests

I've got some basic unit test to establish the generator is working as expected.
Or at least not doing anything totally stupid.

They're available with the rest of the code in the [BlockCypherTests](https://github.com/ligos/terninger/blob/c18d9c09a7b0edcd532cf29761a1e4964ced04aa/Terninger.Test/BlockCypherTests.cs) class.

### BitBucket Repository

I'll be making the source available for [Turninger in GitHub](https://github.com/ligos/terninger).

[Commit for this post](https://github.com/ligos/terninger/tree/c18d9c09a7b0edcd532cf29761a1e4964ced04aa) and implementation of [BlockCypherCprngGenerator](https://github.com/ligos/terninger/blob/c18d9c09a7b0edcd532cf29761a1e4964ced04aa/Terninger/Generator/BlockCypherCprngGenerator.cs).

There may be other projects and classes, depending on what I've been up to.
Consider them a sneak peak into what I'm planning.


## Next Up

Now we have the core Fortuna PRNG working, my options are:

1. Profile and optimise it so it goes fast.
2. Allow it to be customised (different cyphers, hash algorithms, etc).
3. Make a console app so we can output random data.

In the interest in achieving [minimum viable product](https://en.wikipedia.org/wiki/Minimum_viable_product) as quickly as possible, I'm going for option 3.
So next up I'll build a console app that dumps random numbers to stdout.




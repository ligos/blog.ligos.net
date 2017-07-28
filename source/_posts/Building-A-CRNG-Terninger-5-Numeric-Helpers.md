---
title: Building a CPRNG called Terninger - Part 5 Numeric Helpers
date: 2017-07-28
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

So you can get random numbers, not just random bytes.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the Fortuna CPRNG.

So far, we have the PRNG `BlockCypherCprngGenerator`, which has been verified as random, and a console app which outputs random data to file or stdout.


## Goal

Programmers usually need random numbers rather than just random bytes.
So we're going to write a bunch of helper functions to read bytes from any `IRandomNumberGenerator`, and return a number meeting some critera.

We also need to check their outputs are uniformly distributed (although not to the same degree of rigour as testing the core generator).

### Boolean Helper

All the helper methods will be extension methods, as we are adding value to anything which implements `IRandomNumberGenerator` (and I'm expecting there to be several implementations in Terninger).

There is a (small) performance hit to this because we'll always be calling through an interface.
But that should be minor compared to the cost of generating random bytes using a block cypher.

```
public static bool GetRandomBoolean(this IRandomNumberGenerator generator)
{
    var buf = new byte[1];      // PERF: pre-allocate or pool or cache the buffers.
    generator.FillWithRandomBytes(buf);
    return buf[0] >= 128;       // Low values of the byte are false, high values are true.
}
```

Booleans are easy because there are only two options.
We read one byte, and check if its greater than or equal to 128.
Which gives a 50% chance of `true` or `false`.

(And yes, I had to think hard about whether 127 or 128 was the right number, and if I should use *greater than* or *greater than or equal to*).

And I've noted the allocation of an array as a future performance improvement.


### Integer Helper

Integers are more interesting, and more important to developers.
The standard [Random](https://msdn.microsoft.com/en-us/library/system.random.aspx) class will generate integers within ranges, which lets a programmer randomly chose an element in an array (among other things).

```
var rand = new Random();
var randInt = rand.Next();    // Any random positive int from 0..Int32.MaxValue
var randBetweenZeroTo9 = rand.Next(10);     // 10 possiblities from 0..9
var randFromThreeTo10 = rand.Next(3, 10);   // 7 possibilities from 3..9
```

I've already implemented this in [makemeapassword.org](https://bitbucket.org/ligos/makemeapassword/src/c976760afc56efd80124f10ca72a03a8c12852d7/MakeMeAPassword.Web/Services/RandomService.cs?at=default&fileviewer=file-view-default), but there was a little refactoring in order.

```
public static uint GetRandomUInt32(this IRandomNumberGenerator generator)
{
    var buf = new byte[4];      // PERF: pre-allocate or pool or cache the buffers.
    generator.FillWithRandomBytes(buf);
    var i = BitConverter.ToUInt32(buf, 0);
    return i;
}
```

The most primitive method does not generate integers, but unsigned integers in the range 0..2<sup>32</sup>.
So far, that's pretty much the same as `GetRandomBoolean()`.

```
public static int GetRandomInt32(this IRandomNumberGenerator generator)
{
    var i = GetRandomUInt32(generator);
    return (int)(i & (uint)Int32.MaxValue);
}
```

To get a random integer (`Int32`), we simply mask off to top bit of the `UInt32`.
Again, this is easy enough.

But getting a random int with a maximum is more tricky.
For powers of two, we'd just need to mask off the top bits.
However, we don't have that luxury; any int is a possible maximum.

```
public static int GetRandomInt32(this IRandomNumberGenerator generator, int maxExlusive)
{
    uint k = (((uint)Int32.MaxValue % (uint)maxExlusive) + (uint)1);
    var result = GetRandomInt32(generator);
    while (result > Int32.MaxValue - (int)k)
        result = GetRandomInt32(generator);
    return result % maxExlusive;
}
```

I'm not going to pretend I understand how the modulus (`%`) operator is working here; I think it is masking the top (unused) bits off the random number.
We still need to loop until we find a number less than our maximum, lest we end up with a skewed distribution above (or below) the nearest power of 2.

(Credit to **Peter Taylor** on [StackOverflow Code Review](http://codereview.stackexchange.com/questions/6304/algorithm-to-convert-random-bytes-to-integers) for this concept).

```
public static int GetRandomInt32(this IRandomNumberGenerator generator, int minValue, int maxValue)
{
    return minValue + GetRandomInt32(generator, maxValue - minValue);
}
```

Once we have a uniform distribution of ints from 0..n, it's easy to allow the *0* to be arbitrary.

And we can use exactly the same concepts for generating `UInt64` and `Int64` values.


### Floating Point Helper

Random number generators tend to produce floats and doubles as values between 0 and 1.
In many ways, the floating point helpers are the simplest to implement.

```
public static double GetRandomDouble(this IRandomNumberGenerator generator)
{
    return GetRandomUInt64(generator) * (1.0 / UInt64.MaxValue);
}
```

Although simple, it relies on at least two important things:

1. That floating point numbers can represent really small values (that is, `1.0 / UInt64.MaxValue` is usable and doesn't get rounding into zero).
2. That the .NET framework will magically convert an `Int64` or `Int32` into a `Double` or `Single` without me thinking about where the bits go.


### Decimal Helper

Unlike the trick used for floating point numbers, the [Decimal](https://docs.microsoft.com/en-us/dotnet/api/system.decimal?view=netframework-4.7) type has no such short cut.
To get maximum precision in a `Decimal` we need three `Int32`s (as decimals have around 96 bits of internal precision), and .NET has no `Int128` type to do the magic division and multiplication.

```
public static decimal GetRandomDecimal(this IRandomNumberGenerator generator)
{
    var rawBytes = new byte[12];
    generator.FillWithRandomBytes(rawBytes);

    var lo = BitConverter.ToInt32(rawBytes, 0);
    var mid = BitConverter.ToInt32(rawBytes, 4);
    var hi = BitConverter.ToInt32(rawBytes, 8) & 0x7ffffff;     
    var d = new decimal(lo, mid, hi, false, 28);
    d = d * 4.038m;
    return d;
}
```

Here, we manually fill the content of a decimal with those 3 random `Int32`s.

The masking of the `hi` value is to ensure the values produced are not greater than 1.
However, that mask produces values between 0 and 0.25.
So, that magic `4.038m` is a scaling factor to produce the required 0 to 1.0 range.

The really cool part about this implementation is there are no loops involved!
And, you have around 94 bits of precision in the random number.


### Guid Helper

[Guids](https://en.wikipedia.org/wiki/Universally_unique_identifier) can be generated as large random numbers.
Effectively, they are a 122 bit random number, with 6 bits set as special 'version' or 'variant' markers.

```
public static Guid GetRandomGuid(this IRandomNumberGenerator generator)
{
    var rawBytes = GetRandomBytes(generator, 16);
    rawBytes[7] = (byte)(rawBytes[7] & (byte)0x0f | (byte)0x40);        // Set the magic version bits.
    rawBytes[8] = (byte)(rawBytes[8] & (byte)0x3f | (byte)0x80);        // Set the magic variant bits.
    var result = new Guid(rawBytes);
    return result;
}
```

Beyond masking out the special bits, there's nothing unusual going on here: just generate random bytes and feed them into the Guid.

Compared to `Guid.NewGuid()`, I'm not sure if this helper is any *better* in terms of randomness or performance.
But it is an alternative that has no "magic" involved (that is, we can see all the source code).


### Tests - Unit Tests

So how do you test a random number generator?
(Other than re-writing the more [comprehensive test suites I already ran](/2017-06-02/Building-A-CRNG-Terninger-4-Random-Tests.html)).

For the moment, I've settled on two basic tests.

The first is to hard code the first 10 values returned when using a null seed.
This tests for determinism, and no silly exceptions, but not much else: its a very basic regression test.

```
[TestMethod]
public void Get10RandomInt32s()
{
    var prng = new BlockCypherCprngGenerator(new byte[32]);
    // First 10 int32s pre-computed based on null seed and default generator.
    Assert.AreEqual(prng.GetRandomInt32(), 1379390326);
    Assert.AreEqual(prng.GetRandomInt32(), 676360365);
    Assert.AreEqual(prng.GetRandomInt32(), 1023835137);
    Assert.AreEqual(prng.GetRandomInt32(), 749283119);
    Assert.AreEqual(prng.GetRandomInt32(), 2065228089);
    Assert.AreEqual(prng.GetRandomInt32(), 1214441829);
    Assert.AreEqual(prng.GetRandomInt32(), 1388754928);
    Assert.AreEqual(prng.GetRandomInt32(), 1759670182);
    Assert.AreEqual(prng.GetRandomInt32(), 1053759929);
    Assert.AreEqual(prng.GetRandomInt32(), 2102486681);
}
```

The second is much harder to automate, and tries to make sure the *distribution* of numbers is uniform.
This is of a particular concern when getting an integer in a non-power-of-two range.
The results get dumped out to a text file as raw values and as a histogram, and I inspect them manually (and you can inspect them below).

```
[TestMethod]
[TestCategory("Random Distribution")]
public void RandomInt32Distribution_ZeroTo47()
{
    var prng = new BlockCypherCprngGenerator(new byte[32]);
    // Produces a histogram of 10000 random int32s in the range 0..47 and also writes the raw values out.
    var histogram = new int[47];
    using (var sw = new StreamWriter(nameof(RandomInt32Distribution_ZeroTo47) + ".raw.txt", false, Encoding.UTF8))
    {
        for (int i = 0; i < 10000; i++)
        {
            var theInt = prng.GetRandomInt32(47);
            Assert.IsTrue(theInt >= 0 && theInt < 47);
            histogram[theInt] = histogram[theInt] + 1;
            sw.WriteLine(theInt);
        }
    }
    WriteHistogramToTsv(histogram, nameof(RandomInt32Distribution_ZeroTo47) + ".txt");
}

```

### Tests - Excel Graphs

For each different helper method, there's a fuzzing test which dumps 10,000 results to a text file, which I can import into Excel to graph and check the distribution.
Graphs follow:

<img src="/images/Building-A-CRNG-Terninger-5-Numeric-Helpers/graph-scatter-single.png" class="" width=300 height=300 alt="Scatter Chart of Single (float32)" />

<img src="/images/Building-A-CRNG-Terninger-5-Numeric-Helpers/graph-scatter-double.png" class="" width=300 height=300 alt="Scatter Chart of Double (float64)" />

<img src="/images/Building-A-CRNG-Terninger-5-Numeric-Helpers/graph-scatter-decimal.png" class="" width=300 height=300 alt="Scatter Chart of Decimal" />

<img src="/images/Building-A-CRNG-Terninger-5-Numeric-Helpers/graph-scatter-int.png" class="" width=300 height=300 alt="Scatter Chart of Int32" />

<img src="/images/Building-A-CRNG-Terninger-5-Numeric-Helpers/graph-histogram-int47.png" class="" width=300 height=300 alt="Histogram of Int32 0..46" />

<img src="/images/Building-A-CRNG-Terninger-5-Numeric-Helpers/graph-scatter-long.png" class="" width=300 height=300 alt="Scatter Chart of Int64" />

<img src="/images/Building-A-CRNG-Terninger-5-Numeric-Helpers/graph-histogram-long47.png" class="" width=300 height=300 alt="Histogram of Int64 0..46" />

These are obviously not as rigorous as the [previous random test](/2017-06-02/Building-A-CRNG-Terninger-4-Random-Tests.html), but good enough to make sure there are no obvious distribution problems.

(Note that Excel's numbers are always double precision floats, so we lose some precision for Decimal and Int64 tests).


### Tests - Benchmarks

I coded some basic benchmarks which ask for one number from each of the helper methods using [Benchmark .NET](https://github.com/dotnet/BenchmarkDotNet).
Here are the results on my laptop:

```
BenchmarkDotNet=v0.10.8, OS=Windows 10 Redstone 2 (10.0.15063)
Processor=Intel Core i5 CPU M 460 2.53GHz, ProcessorCount=4
Frequency=2468207 Hz, Resolution=405.1524 ns, Timer=TSC
  [Host]     : Clr 4.0.30319.42000, 64bit RyuJIT-v4.7.2101.1
  DefaultJob : Clr 4.0.30319.42000, 64bit RyuJIT-v4.7.2101.1

        Method |     Mean |     Error |    StdDev |
-------------- |---------:|----------:|----------:|
       Boolean | 12.36 us | 0.2450 us | 0.6412 us |
        UInt32 | 13.42 us | 0.3503 us | 1.0108 us |
         Int32 | 14.35 us | 0.3848 us | 1.0979 us |
 Int32_Range32 | 14.13 us | 0.3602 us | 1.0101 us |
 Int32_Range33 | 12.11 us | 0.3604 us | 0.9925 us |
 Int32_Range47 | 12.10 us | 0.2992 us | 0.8535 us |
        UInt64 | 12.56 us | 0.3036 us | 0.8513 us |
         Int64 | 13.57 us | 0.2674 us | 0.3570 us |
        Single | 13.84 us | 0.3163 us | 0.8605 us |
        Double | 13.76 us | 0.4141 us | 1.1124 us |
       Decimal | 11.84 us | 0.2335 us | 0.4211 us |
          Guid | 13.11 us | 0.4840 us | 1.3085 us |
```


All helper methods are pretty similar in performance.
Within a few microseconds of each other.

Because every time you call any of the numeric helpers the `BlockCypherCprngGenerator` will generate 16 random bytes (usually only 8 or less bytes will actually be used), and then a further 32 random bytes to re-key the generator (in line with the strict forward secrecy requirements of Fortuna).

Basically, the expensive part of generating an random number is encrypting 3 blocks with AES and re-keying the cypher. 

I'll investigate how much I can mitigate and improve this in the future.


## Next Up

We've added an API to generate random numbers to make the core Fortuna / Terninger PRNG more useful to application developers.

You can see the [actual code in BitBucket](https://bitbucket.org/ligos/terninger/src/562a727372c1e348daa534338e94623e3b6c7094/Terninger/RandomNumberExtensions.cs?at=default&fileviewer=file-view-default).


The next step will be to allow customising the PRNG.
Some customisations will be to allow flexibility (different block cyphers), some for new functionality (adding small amounts of additional entropy), and some with performance in mind (larger buffer and block sizes).


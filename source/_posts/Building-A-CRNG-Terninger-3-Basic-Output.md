---
title: Building a CPRNG called Terninger - Part 3 Basic Output
date: 2017-05-20
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

A console app to see random output.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the Fortuna CPRNG.

So far, we have implemented `BlockCypherCprngGenerator`, which fills a `byte[]` with random data using AES to encrypt a counter.


## Goal

This time, we're going to write a console app which will let us see random output as hex characters on the console.
It will require accepting a seed from the command line to initialise the generator.

The app should also be able to write binary output, suitable for piping to an analysis program like [dieharder](http://www.phy.duke.edu/~rgb/General/dieharder.php).
And also save output to a file.

## Implementing the Console App

Rather than starting with the boilerplate like last time, I'm going to start with the heart of app.
Then I'll work outwards to the interesting parts which support the core.
Although it's really pretty straight forward.


### Writing Random Data

``` c#
private static void RunMain()
{
    // Load our inputs and outputs.
    var seed = DeriveSeed();
    var outputWriter = GetOutputWriter();

    long generatedBytes = 0L;
    // Open the output.
    using (var outStream = GetOutputStream())
    using (var crng = new BlockCypherCprngGenerator(seed))
    {
        long remaining = byteCount;
        byte[] buf = new byte[OutBufferSize];       // 32k

        // Read and write in buffered chunks (for larger requests).
        while (remaining > buf.Length)
        {
            crng.FillWithRandomBytes(buf);          // Fill one buffer with randomness.
            generatedBytes = generatedBytes + buf.Length;       // Increment counter.
            outputWriter(outStream, buf);           // Write the buffer to out output stream.
            remaining = remaining - buf.Length;     // Decrement remaining.
        }

        // The remaining bytes required.
        if (remaining > 0L)
        {
            buf = new byte[(int)remaining];         
            crng.FillWithRandomBytes(buf);
            generatedBytes = generatedBytes + buf.Length;
            outputWriter(outStream, buf);
        }
    }
}
```

We start by loading, initialising and opening our inputs and outputs.

The core loop is fill a buffer with random bytes and then writes that buffer to the output stream.
We use a fixed size buffer until the last request, where we allocate a smaller buffer for whatever is left over.

You can see the [actual code in GitHub](https://github.com/ligos/terninger/blob/bbf6123d779df55cf7e8388aeab82afcc8a9665e/Terninger.Console/Program.cs), which has some more stuff going on (to print nice things to the console, and handle cancellation via `CTRL+C` gracefully).


### Output Writer

The first unknown is the `outputWriter`.
And my use of `var` doesn't help here!

It's an `Action<Stream, byte[]>`.
That is, a method that takes a stream and byte array, and does something with them.
In this case, the output stream and our buffer of random bytes, and copies the buffer to the stream.

I'm using it as an abstraction to cope with two different *output styles*: binary and hex.

``` c#
private static Action<Stream, byte[]> GetOutputWriter()
{
    if (outputStyle == OutputStyle.Hex)
        return (output, buf) =>
        {
            // Format bytes to hex.
            for (int i = 0; i < buf.Length; i++)
            {
                byte b = buf[i];
                output.WriteByte(b.ToHexAsciiHighNibble());
                output.WriteByte(b.ToHexAsciiLowNibble());
            }
        };
    else if (outputStyle == OutputStyle.Binary)
        // Direct copy.
        return (output, buf) => output.Write(buf, 0, buf.Length);
    else
        throw new Exception("Unexpected outputStyle: " + outputStyle);
}
```

I've defined my actions inline, because they're quite simple.
The main complexity is writing hex characters (eg: 1B7F9D3A) needs to handle each byte in two halves.

The careful reader will also note that `outputStyle` is a global.
Yes, it really is a global `static` variable.
All my command line parsing simply sets static variables. 
Its not pretty, nor best practice, but its simple, direct and effective.


### Output Stream

Getting the output stream is pretty easy.
There are two obvious choices: a file or stdout.

``` c#
private static Stream GetOutputStream()
{
    if (outFile == null)
        // Null output (mostly for benchmarking).
        return Stream.Null;
    else if (outFile == "")
        // Standard output.
        return Con.OpenStandardOutput(OutBufferSize);
    else
        // File output.
        return new FileStream(outFile, FileMode.Create, FileAccess.Write, FileShare.None, OutBufferSize);
}
```

I decided to sneak a `Null` output in there, so I could eliminate a potential overhead when benchmarking.

Otherwise, I'm using the shortened `Con` for the normal `Console` object.
And the [OpenStandardOutput](https://msdn.microsoft.com/en-us/library/16f09842.aspx) method to get a `Stream`, rather than the `TextWriter` of `Console.Out`.
Writing binary to a `Stream` works much better than a `TextWriter` (I tried; it didn't quite work).


### Getting A Seed

Finally, the main input is some sort of seed value.

There are plenty of places we could get a seed from.
For now, you have to pass it in via the command line (although I'm planning to gather entropy from the current system environment later).

``` c#
private static byte[] DeriveSeed()
{
    if (String.IsNullOrEmpty(seed))
        // No seed: use null array.
        return new byte[32];
    if (seed.IsHexString() && seed.Length == 64)
        // A 32 byte seed as hex string.
        return seed.ParseFromHexString();
    else if (File.Exists(seed))
    {
        // A file reference: get the SHA256 hash of it as a seed.
        using (var stream = new FileStream(seed, FileMode.Open, FileAccess.Read, FileShare.Read, 64 * 1024))
            return new SHA256Managed().ComputeHash(stream));
    }
    else
        // Assume a random set of characters: get the SHA256 hash of the UTF8 string as a seed.
        return new SHA256Managed().ComputeHash(Encoding.UTF8.GetBytes(seed));
}
```

Four options this time:

1. No seed was supplied: we use an array of zeros.
2. A hex string matching the desired key size: we'll use that exactly as-is.
3. A path to a file: grab the SHA256 hash of it.
4. Anything else: assume a password and hash to get enough bytes.


### Other Boilerplate

You can see the other [bits and pieces in GitHub](https://github.com/ligos/terninger/tree/bbf6123d779df55cf7e8388aeab82afcc8a9665e).
They aren't particularly relevant to getting random bytes, but are rather important to make a functional console app.

* A top level exception handler that wraps everything in a giant try-catch block.
* Command line parsing into static variables - not pretty, but very effective.
* Printing usage / help. Yep, every console app needs this.
* Printing what the program is doing to the console. So you know you have the right arguments.
* `CTRL+C` cancellation handler. To gracefully end.


### Output

Behold! 
The output of Terninger!

```
> Terninger.Console.exe
Terninger CPRNG   © Murray Grant
Generating 64 random bytes as Hex output.
Seed source: Null seed - WARNING, INSECURE: the following random numbers are always the same.
Output target: Standard Output.

76D33752DFEB1B78F298101006618DA8A38B0E5EA770F956DA73D67C88FC74E9
25A133740FA2102E098DF39A452710C2D92FDBF774D1C8319CABD15A0AB922CA

Wrote 64 bytes in 0.07 seconds (0.00MB / sec)
```

With no argument, we use a null seed, hex output and generate 64 bytes.

Because of the fixed seed, anyone who runs Terninger should get the same "random" bytes.
Be this a warning to anyone who things things are random just because they look like garbage!
(This kind of thing has caused me [significant pain](https://github.com/ligos/readablepassphrasegenerator/wiki/0.17.0-Fix-for-Non-Random-Passphrases)).

```
> Terninger.Console.exe -s 1 -c 512
Terninger CPRNG   © Murray Grant
Generating 512 random bytes as Hex output.
Seed source: SHA256 hash of random string / password / passphrase.
Output target: Standard Output.

8802A4224971A9458EDEDDA85046A514E5CEFE0D1525C178D7B2D8AEB422BCA
....
04BB66014A7D0A3A720CBB8B85F01DAF07C8EFA2A96554653CB455961045F79

Wrote 512 bytes in 0.25 seconds (0.00MB / sec)
```

Choose a seed and more bytes.

```
> Terninger.Console.exe -s 1 -c 128000 -outstyle binary -o out.bin
Terninger CPRNG   © Murray Grant
Generating 128,000 random bytes as Binary output.
Seed source: SHA256 hash of random string / password / passphrase.
Output target: out.bin

Wrote 128,000 bytes in 0.05 seconds (2.30MB / sec)
```

<img src="/images/Building-A-CRNG-Terninger-3-Basic-Output/random-file.png" class="" width=300 height=300 alt="The same sequence of random bytes as a binary file" />

```
> Terninger.Console.exe -s 1 -c 12800000 -outstyle binary -outnull
Terninger CPRNG   © Murray Grant
Generating 12,800,000 random bytes as Binary output.
Seed source: SHA256 hash of random string / password / passphrase.
Output target: Null stream.
............
Wrote 12,800,000 bytes in 1.78 seconds (6.85MB / sec)
```

On my rather old laptop, I get between 6.5MB and 7.0MB per second.
That's pretty poor considering [benchmarks of more recent hardware for AES](https://cryptopp.com/benchmarks.html) are closer to 600MB / sec.
But its somewhere to start.


## Next Up

Next step to to analyse the random numbers produced by the generator to see how random they really are.

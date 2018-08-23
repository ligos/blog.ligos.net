---
title: Building a CPRNG called Terninger - Part 12 Porting to .NET Standard
date: 
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
- .NET Standard
- .NET Core
categories: Coding
---

.NET Standard, modularisation and NuGets

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/).

So far, I've put Terninger into production in [makemeapassword.ligos.net](https://makemeapassword.ligos.net). 


## Goal

I want Terninger to be available on NuGet to as wide and audience as I can manage.
Including not-Windows platforms (like Linux).
And this means porting it to .NET Standard.

I started wanting a nice simple scenario where I'd target one .NET Standard and all frameworks out there can use Terninger.
If only it were so simple!

### What .NET Standard?

First decision: what [.NET Standard](https://docs.microsoft.com/en-us/dotnet/standard/net-standard
) should I target?
The answer was pretty simple, **.NET Standard 1.3** is the first to support cryptography classes like AES and SHA, so that's my choice!

Project count: 1, frameworks targeted: 1.



### Split off Network Entropy Sources


I wanted the core of Terninger available as its own NuGet package.
That is, the `CypherBasedPrngGenerator` (the deterministic PRNG based on AES), `RandomNumberExtensions` (which converts random bytes in a `byte[]` to random `Int32`s) and the core `PooledEntropyCprngGenerator` (which is the CPRNG which is based on Fortuna).

So I started by splitting off the active network entropy sources into their own assembly `Terninger.EntropySources.Network`.
And then converted the main Terninger project to target .NET Standard 1.3 with the new <strike>light weight</strike> sdk-style project file format.

Project count: 2, frameworks targeted: 1.


### Make Changes for .NET Standard 1.3

OK, time to port.
Starting from the most basic classes, I made the changes required for .NET Standard 1.3.
Easy stuff:

* Remove *assemblyinfo.cs*.
* There's no `Math.DivRem()` in 1.3, so I implemented it myself.
* There's no `Thread` in 1.3, so I converted to `Task`.
* My default log target was using `System.Diagnostics.Trace.WriteLine()`, which isn't in 1.3, so I implemented a workaround for unit test projects.

But then I ran into some more difficult problems:

* I use `System.Diagnostics.Process.WorkingSet64` in my basic `CheapEntropy` functions, but that's not available until 2.0. It's also the basis of `ProcessStatsSource`.
* There are no native encryption classes available in 1.3, and things like the `CryptoServiceProvider` family or `Cng` family are only applicable to Windows anyway.
* `System.Net.NetworkInformation.NetworkInterface` isn't available until 2.0 as well, which is what `NetworkStatsSource` uses.

I might have avoided these (or at least been more aware of them) if I used the [Portability Analyzer](https://docs.microsoft.com/en-au/dotnet/standard/analyzers/portability-analyzer).


### Target .NET 4.5.2 and Standard 2.0

At this point I realised there were enough edge cases which made .NET Standard 1.3 difficult, that I'd a) need to split `ProcessStatsSource` and `NetworkStatsSource` into a separate assembly targeting .NET Standard 2.0, and b) I should multi-target 2.0 in the main Terninger assembly to gain benefits where I can.

And, at the same time, targeting .NET 4.5.2 would also give me the benefits of Standard 2.0, while also allowing for older desktop users (as Standard 1.3 is first supported by .NET 4.6).

So, the main Terninger project multi-targets Standard 1.3, 2.0 and .NET 4.5.2.
And I have a `Ternigner.EntropySources.Extended` which only targets 2.0 and 4.5.2.

Within the main Terninger project, `CheapEntropy` now supported `System.Diagnostics.Process.WorkingSet64` via compiler conditionals (in Standard 2.0 and .NET 4.5.2).
Before long, I made separate `PortableEntropy` which only uses Standard 1.3 APIs; while `CheapEntropy` is only available for the higher frameworks.

Project count: 3, frameworks targeted: 3.



### And Now for the Real Train Wreck: Hash Algorithms

This was, by far, the worst part of the whole process.

By now, I was committed to Standard 1.3, 2.0 and .NET 4.5.2.
And hash algorithms are subtly different in all of them.

My original implementation used [HashAlgorithm](https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.hashalgorithm?view=netframework-4.7.2) as the, well, hash algorithm.
This has been around as long as I've been using .NET (at least from the 1.1 days), and is an abstract class which lets you plug whatever hash algorithm in you want.
And it worked fine for .NET 4.5.2.

In fact, it is OK in all target frameworks as long as you want to calculate the hash of a `byte[]`.
That is, as long as you're using `HashAlgorithm` as an elaborate version of `Func<byte[], byte[]>`, all is well.

But my `EntropyPool` class is using an *incremental hash* (which the Fortuna spec strongly recommends).
Which means you add data to `HashAlgorithm` little by little over many calls, until you need to get the final hash.
And this works fine with `HashAlgorithm` and .NET 4.5.2.

But `HashAlgorithm.TransformBlock()` isn't available in Standard 1.3.
It has an alternative called [IncrementalHash](https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.incrementalhash?view=netframework-4.7.2
), which is effectively the same thing (with a simpler API as well).

OK, they [moved my cheese](https://en.wikipedia.org/wiki/Who_Moved_My_Cheese%3F), I can cope.
`IncrementalHash` for the win!
Except, it isn't available in .NET 4.5.2. 
Bugger.

OK, surely there's some kind of relationship between the two, so I can inherit one from the other?
Nope.
And worse than that, `IncrementalHash` is [sealed](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/sealed), so I can't build a wrapper for `HashAlgorithm`.
It doesn't implement an interface which would give me some kind of common base.
And it seems to only support a closed set of internal hash algorithms (MD5, SHA1, SHA2).

The [apisof.net](https://apisof.net/) site has very good information about what APIs are available in each possible target, and its summary of [IncrementalHash](https://apisof.net/catalog/System.Security.Cryptography.HashAlgorithm) and [HashAlgorithm](https://apisof.net/catalog/System.Security.Cryptography.IncrementalHash) are listed in this table:

Framework     | HashAlgorithm.TransformBlock()  |  IncrementalHash
--------------|---------------------------------|--------------------
.NET 4.5.2    | Yes                             | No
Standard 1.3  | No                              | Yes
Standard 2.0  | Yes                             | Yes

So, if I restricted myself entirely to Standard 2.0 and newer, then this would all be easy.
But it seems silly to abandon support for older frameworks when I just need `HashAlgorithm.TransformBlock()`.

Now, I still wanted to support 3rd party hash algorithms, so I wanted to keep `HashAlgorithm` available.
But only as a fallback; if `IncrementalHash` is a possibility then I wanted to use the new and shiny.

And the only way that was possible was via a bunch of compiler conditionals.
Really ugly ones.
Littered throughout my lovely clean `EntropyPool` class.
Making it twice as long and 5 times as complex.

Finally, I decided to see what 3rd party hash implementations use, which might influence my decision.
And found a [popular implementation](https://www.nuget.org/packages/System.Data.HashFunction.Blake2/) System.Data.HashFunction.Blake2 of [blake2](https://blake2.net/).
Which uses... it's own interface, not `HashAlgorithm`, nor `IncrementalHash` (and doesn't appear to support incremental hashing anyway).

At that point I decided the train wreck was bad enough and called it quits.


Project count: 3, frameworks targeted: 3, classes with messy compiler conditionals: 1.


### Native vs Managed vs Default Crypto

I was using `CryptoServiceProvider` and `Cng` as native Windows crypto implementations.
They were significantly faster than the managed equivalents and, well, in .NET 4.5.2 on Windows, they're available for free.

Not in Standard 1.3.
Double not when I want it to run on Linux.

The simple solution is to use `Aes.Create()` instead of `new AesCryptoServiceProvider()`.
And the console app now has a 3 state option: *native*, *managed* and *default*.
And default uses `Aes.Create()`, so everything is happy.

But I still wanted a native vs managed option, because... well, I like options.
Although, I couldn't find a nice way directly target any native Linux crypto (or even distribution specific).
Instead, while I was playing around with [benchmark.net](https://github.com/dotnet/BenchmarkDotNet), I found this:


```
BenchmarkDotNet=v0.11.0, OS=Windows 10.0.17134.228 (1803/April2018Update/Redstone4)
Intel Core i5-7200U CPU 2.50GHz (Max: 2.70GHz) (Kaby Lake), 1 CPU, 4 logical and 2 physical cores
Frequency=2648439 Hz, Resolution=377.5809 ns, Timer=TSC
  DefaultJob : .NET Framework 4.7.2 (CLR 4.0.30319.42000), 64bit RyuJIT-v4.7.3132.0

                 Method |        Mean |       Error |      StdDev |
----------------------- |------------:|------------:|------------:|
       Encrypt8BlockCng |    445.2 ns |   5.8876 ns |   5.2192 ns |
       Encrypt8BlockCsp |    571.0 ns |   2.7436 ns |   2.5663 ns |
   Encrypt8BlockManaged |  4,673.8 ns |  16.9180 ns |  14.9974 ns |
          Encrypt8Block |    572.1 ns |   2.0437 ns |   1.9117 ns |


BenchmarkDotNet=v0.11.0, OS=Windows 10.0.17134.228 (1803/April2018Update/Redstone4)
Intel Core i5-7200U CPU 2.50GHz (Max: 2.70GHz) (Kaby Lake), 1 CPU, 4 logical and 2 physical cores
Frequency=2648439 Hz, Resolution=377.5809 ns, Timer=TSC
.NET Core SDK=2.1.302
  DefaultJob : .NET Core 2.1.2 (CoreCLR 4.6.26628.05, CoreFX 4.6.26629.01), 64bit RyuJIT

                 Method |       Mean |      Error |     StdDev |
----------------------- |-----------:|-----------:|-----------:|
       Encrypt8BlockCng |   436.8 ns |  0.9573 ns |  0.7994 ns |
       Encrypt8BlockCsp |   437.8 ns |  2.6270 ns |  2.1937 ns |
   Encrypt8BlockManaged |   432.5 ns |  1.9325 ns |  1.8077 ns |
          Encrypt8Block |   429.7 ns |  0.8458 ns |  0.7063 ns |
```


Apparently, in .NET Core 2.1, the managed and native implementations of AES are almost identical in performance!

I'm not sure how they managed this orders-of-magnitude level of improvement (I suspect some [JIT intrinsics](https://docs.microsoft.com/en-us/dotnet/api/system.runtime.compilerservices.isjitintrinsic?view=netstandard-2.0
)), but given my main reason for using native crypto was performance, I decided to spend my time elsewhere!


### Dynamic

Finally, before I could build the main `Terninger` project, I needed to include [Microsoft.CSharp](https://www.nuget.org/packages/Microsoft.CSharp/) and [System.Dynamic.Runtime](https://www.nuget.org/packages/System.Dynamic.Runtime/) as [LibLog](https://github.com/damianh/LibLog) uses the [dynamic](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/dynamic) keyword to support various logging frameworks. 

Back when `dynamic` was new, in the .NET 4.0 days, it effectively meant shipping a special version of the c# compiler to compile and evaluate your `dynamic` code.
I'm not sure how things have changed since the [Roslyn](https://github.com/dotnet/roslyn) compiler though.

I also needed to define `LIBLOG_PORTABLE`, to exclude a bunch of attributes that aren't supported in Standard 1.3.

Project count: 3, frameworks targeted: 3, classes with messy compiler conditionals: 1, 3rd party DLLs: 2.


### Extended and Network Sources

The extended sources (`ProcessStatsSource` and `NetworkStatsSource`) were pretty much unchanged.

I found many network sources use `StaticLocalEntropy`, which leverage process, network and environmental values which are usually different between computers, but are otherwise pretty static (think computer name, IP address, etc).
But static entropy could be useful in non-network scenarios, so it landed in the `Extended` project.

I found that [WebClient](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient?view=netframework-4.7.2) is no longer recommended, but [HttpClient](https://docs.microsoft.com/en-us/dotnet/api/system.net.http.httpclient?view=netframework-4.7.2
) is the new and shiny.
So I converted all HTTP requests to use `HttpClient`.
Which was pretty straight forward, and lets me break a dependency on the ugly [ServicePointManager](https://docs.microsoft.com/en-us/dotnet/api/system.net.servicepointmanager?view=netframework-4.7.2
) to define which TLS versions are supported (except in 4.5.2).

In moving the HttpClient, I found the [User-Agent](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent) string actually has a defined format, and `HttpClient` enforces it!


### Unit Tests

Running unit tests gave lots of failures.
Mostly down to me forgetting to set the *CheckForOverflowUnderflow* project setting (I want overflow and underflow to throw exceptions, and there are places in code where I depend on those exceptions for flow-control).

In my professional work, unit tests are a luxury I can rarely afford.
Simply because they cost time and money to build and maintain.
I realise they often pay that cost back over time, but the desire for up-front results as quickly as possible means automated tests (of all sorts) get neglected.
And, I prefer to leverage the compiler and static type checking for correctness as much as possible (unit tests are an automated way to fill holes in your compiler).

Having said all that, I'm very happy with the automated tests I had.
They definitely caught bugs after my big refactor.

Oh, a big hint: when random things don't work with automated tests, use `dotnet new` to create an empty sdk-based project with the right NuGet packages (which you can copy back to your project).
Apparently, package versions are quite important these days.
Unless you enjoy errors like "this assembly contains no tests".


### NuGet vs Project References

An issue I had with [ReadablePassphrase](https://bitbucket.org/ligos/readablepassphrasegenerator) was NuGet vs Project references.
If I'm producing NuGets, then all references need to be NuGet `<PackageReference>` elements in the project file.
But the development and debugging experience of that isn't brilliant.

`<ProjectReference>` elements give a fantastic development experience, but don't create the right NuGet packages.

My solution: pick the best of both worlds!

By default, I use `<ProjectReference>`, so my development is nice.
But all those references have matching `<PackageReference>`'s, with a special `RefNugets` build property.
Here's the relevent part of the project file.

```
  <!-- FOR DEVELOPMENT -->
  <ItemGroup Condition="'$(RefNugets)'!='True'">
    <ProjectReference Include="..\Terninger\Terninger.csproj" />
    <ProjectReference Include="..\Terninger.Random.Cypher\Terninger.Random.Cypher.csproj" />
    <ProjectReference Include="..\Terninger.Random.Pooled\Terninger.Random.Pooled.csproj" />
    <ProjectReference Include="..\Terninger.EntropySources.Extended\Terninger.EntropySources.Extended.csproj" />
    <ProjectReference Include="..\Terninger.EntropySources.Network\Terninger.EntropySources.Network.csproj" />
  </ItemGroup>

  <!-- FOR NUGET BUILDS -->
  <ItemGroup Condition="'$(RefNugets)'=='True'">
    <PackageReference Include="Terninger.Random.Cypher" Version="0.1.0" />
    <PackageReference Include="Terninger.Random.Pooled" Version="0.1.0" />
    <PackageReference Include="Terninger" Version="0.1.0" />
    <PackageReference Include="Terninger.EntropySources.Extended" Version="0.1.0" />
    <PackageReference Include="Terninger.EntropySources.Network" Version="0.1.0" />
  </ItemGroup>
```

And then the build command: `dotnet pack Terninger -c Release /p:RefNugets=True`


### Annoying NuGet Gotcha

Just when I was finishing off my changes and scripted out hashes and signatures of all my packages, NuGet.org decided to change all uploaded NuGets by [repo signing them](https://blog.nuget.org/20180810/Introducing-Repository-Signatures.html).
Now I love the idea of NuGet.org signing packages, it just means my workflow generating them is trickier.

Realistically, I have to upload, wait for the packages to be processed and signed by NuGet.org, and finally download my own (signed and modified) packages to sign them myself.

I could buy a code signing cert, but I'm tight.


### Split Terninger, Again

The most fundamental part of Terninger is the `CypherBasedPrngGenerator`, which is a high quality, deterministic PRNG based on AES with a 128 bit or 256 bit seed.
If you can refresh the seed regularly, it is borderline crypto-safe.

The standard [System.Random](https://docs.microsoft.com/en-au/dotnet/api/system.random?view=netframework-4.7.2) class uses a 32 bit seed, and most 3rd party PRNGs in the .NET world are the same.
But 32 bits isn't big enough for many scenarios.
Eg: it can't shuffle a [deck of 52 cards](https://en.wikipedia.org/wiki/Playing_card) (`52!` is bigger than `2^32`).
And almost any complex scenario, model or game will need a seed larger than 2^32 to allow the astronomical number of possibilities to be... well... possible.

Now, if you wanted to pick up the Terninger `CypherBasedPrngGenerator` (but not use anything else), you still need the packages to support `dynamic`.
I want the lowest level component to be most accessible.
So time to split assemblies again!

`Terninger.Random.Cypher` is the bottom of the dependencies. 
It targets .NET Standard 1.3 and .NET 4.0.
And, given a 32 byte seed, you can get an awful lot of random numbers really fast.
No reference to `System.Dynamic.Runtime` or `Microsoft.CSharp` required.

`Terninger.Random.Pooled` adds the more complex and very non-deterministic `PooledEntropyCprngGenerator`.
It targets .NET Standard 1.3 and 2.0 and .NET 4.5.2.
The `dynamic` packages are required (because [liblog](https://github.com/damianh/LibLog) is required for any meaningful statistics or diagnostics).

And the `Terninger` package is still there as a meta-package and an easy entry point.

Project count: 5, frameworks targeted: 4, classes with messy compiler conditionals: 1, 3rd party DLLs: 2.

### Changed the Accumulator Default

I reviewed one of the unit tests which showed the `EntropyAccumulator` burned through to it's 16th pool a little too quickly for my liking.
The point of Fortuna is the higher pools are very rarely touched (where "very rare" means once every year or so).

So I changed the defaults from 16 linear and 16 random pools, to 28 linear and 12 random.
Which takes the total to 40 (rather than the original 32).
And, if the 28 pools are used once per second, it should take around 8 years before the last one is called upon (as opposed to under 1 day with 16 pools).

For reference, Fortuna specifies 32 linear pools and a 100ms minimum key refresh period, which would take ~13 years before the 32nd pool is required.

(You can have up to 64 linear + 64 random pools, if you really want.
And, yes, that would be overkill)!

### Linux and NuGets

Here's the console app running on Linux and .NET Core!

<img src="/images/Building-A-CRNG-Terninger-12-Porting-To-Net-Standard/debian-wsl.png" class="" width=300 height=300 alt="Running On Debian (WSL)" />


<img src="/images/Building-A-CRNG-Terninger-12-Porting-To-Net-Standard/ubuntu-baremetal.png" class="" width=300 height=300 alt="Running On Ubuntu (WSL)" />

And a link to the [main NuGet package: **Terninger**](https://www.nuget.org/packages/Terninger).

## Future Work

* Fix up the **hash algorithm mess** into my own class which deals with all the ugliness, and allows 3rd party algorithms.
* Improving the start up performance of Terninger by **polling entropy sources in parallel**.
* Improving the **network sources** to be smarter and consume data from more websites (in particular, my [Raspberry Pi](https://www.raspberrypi.org/) with [MotionEye](https://github.com/ccrisan/motioneye/wiki)).
* That nagging problem of Fortuna requiring **serialisation of the internal state of the generator**.

A reflection: refactoring makes me feel good, supporting more platforms and environments makes me feel good.
But I spent more time than I wanted, haven't really added any new features, and have introduced more complexity.
I guess this is why you need to fix bugs, improve code, **and** implement new features.


## Next Up

Terninger is now available to anywhere .NET Standard is (which means .NET Core on Linux and Windows, plus the regular .NET Desktop Framework on Windows)!

You can see the [actual Terninger code in BitBucket](https://bitbucket.org/ligos/terninger/src/default/). 
And the main [NuGet package](https://www.nuget.org/packages/Terninger).

Next up: parallel entropy source polling, and maybe some more entropy sources.



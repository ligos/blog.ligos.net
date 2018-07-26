---
title: Porting ReadablePassphrase to .NET Core and Publishing NuGets
date: 2018-07-26
updated: 
tags:
- ReadablePassphrase
- Password
- .NET
- .NET Core
- .NET Standard
- NuGet
- Porting
- Compatibility
categories: Technical
---

My first steps into .NET Core & NuGet

<!-- more --> 

## Background

My last [Terninger post](/2018-05-28/Building-A-CRNG-Terninger-11-Production-Use.html) ended with my plan to migrate it to .NET Standard and NuGet.
And I've always known this would be a reasonably big move.

[.NET Core 2.1 LTS](https://blogs.msdn.microsoft.com/dotnet/2018/05/30/announcing-net-core-2-1/) landed a while back, and unlike 1.0, it has a much wider feature set; considerably fewer missing APIs when compared to the desktop frameworks.
I've started a new work project targeting .NET Core, so getting a bit of experience in there.

I'm planning to migrate [Make Me a Password](https://makemeapassword.ligos.net/
) to ASP.NET Core, so I can host it on a non-Windows box.
[Make Me a Password](https://makemeapassword.ligos.net/
) is my consumer of Terninger, but it also consumes the [Readable Passphrase Generator](https://bitbucket.org/ligos/readablepassphrasegenerator/).
So, to kill a few birds with one stone, I decided to port the [Readable Passphrase Generator](https://bitbucket.org/ligos/readablepassphrasegenerator/) to .NET Standard and .NET Core.


## Requirements

Readable Passphrase Generator has two main artefacts:

* The [KeePass Plugin](https://bitbucket.org/ligos/readablepassphrasegenerator/wiki/KeePass-Plugin-Step-By-Step-Guide) - its original use case (complete with a [strong name](https://docs.microsoft.com/en-us/dotnet/framework/app-domains/strong-named-assemblies)).
* And a [Console App](https://bitbucket.org/ligos/readablepassphrasegenerator/wiki/How-to-Use-the-Console-App), to allow usage [outside of KeePass](https://bitbucket.org/ligos/readablepassphrasegenerator/wiki/Running-Under-Linux).

Those both need to stay.
But in addition, I'd like to produce:

* .NET Standard NuGet packages for the generator; that is, the [C# API](https://bitbucket.org/ligos/readablepassphrasegenerator/wiki/Public-API).
* A .NET Core console app, to prove it works (and perhaps widen its reach further).

On top of that, whatever I end up with needs to be easy for me to maintain.
I don't make many changes (other than adding new words to the dictionary from time to time), so building and releasing needs to be dead simple.


## The Road to .NET Core

So here's the account of how I got there (fortunately, its just an account, not a saga).

### Planning and Architecture

First up, I needed to decide what .NET Standard to target.

[.NET Standard](https://docs.microsoft.com/en-us/dotnet/standard/net-standard) is an abstract API which library developers can target and different .NET frameworks can implement.
Target lower versions of .NET Standard and your library is available to more frameworks, but has less APIs available to it.

Readable Passphrase Generator originally targeted .NET 3.5 (wow, that's old now!), and its API usage is pretty minimal.
Only recently I upgraded it to target .NET 4.0 (and that was only because I couldn't get 3.5 to work on a new laptop)!

So I decided to target .NET Standard 1.3, which supports .NET 4.6.
It covers off everything I need. 

Next up, I tried using the new DLLs with the KeePass plugin.
And it didn't work.
So I need to build two copies, one for .NET Standard 1.3, and one for .NET 4.0.

So, do I multi-target or have multiple project files, one for each platform?
Multiple projects used to be the way to go, but the [.NET Core new project format](https://docs.microsoft.com/en-us/dotnet/core/tools/project-json-to-csproj) allows you to target multiple frameworks in a single project via the `TargetFrameworks` tag.
Didn't take me long to realise more projects means more maintenance, so I went with `TargetFrameworks`.

### New Project File

Lets have a look at the project file ([complete file is here](https://bitbucket.org/ligos/readablepassphrasegenerator/src/default/trunk/ReadablePassphrase.Core/ReadablePassphrase.Core.csproj)).
It is light weight compared to the old project file, most of the basic properties are there to support the NuGet package - just the `TargetFrameworks` tag is enough to make it build.
You can specify [multiple frameworks](https://docs.microsoft.com/en-us/dotnet/standard/frameworks), and I've got the two I'm supporting.

```
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFrameworks>netstandard1.3;net40</TargetFrameworks>
  </PropertyGroup>

</Project>
```

OK, that tiny project file is a bit of a lie.
Multi-targeting gets interesting because each framework needs special attention.
And the `Condition` attribute becomes your new best friend.

The .NET Standard side of things includes some NuGet packages:

```
<PropertyGroup 
    Condition="'$(Configuration)|$(TargetFramework)|$(Platform)'=='Release|netstandard1.3|AnyCPU'">
  <DocumentationFile>bin\Release\netstandard1.3\ReadablePassphrase.Core.xml</DocumentationFile>
</PropertyGroup>

<ItemGroup>
  <PackageReference 
    Include="System.Security.SecureString" 
    Version="4.3.0" 
    Condition="'$(TargetFramework)'=='netstandard1.3'" 
  />
  <PackageReference 
    Include="System.Reflection.Extensions" 
    Version="4.3.0" 
    Condition="'$(TargetFramework)'=='netstandard1.3'" 
  />
  <PackageReference 
    Include="System.Reflection.TypeExtensions" 
    Version="4.3.0"
    Condition="'$(TargetFramework)'=='netstandard1.3'" 
  />
</ItemGroup>
```

And .NET 4.0 includes the strong name signing stuff. 

```
<PropertyGroup 
    Condition="'$(Configuration)|$(TargetFramework)|$(Platform)'=='Release|net40|AnyCPU'">
  <DocumentationFile>bin\Release\net40\ReadablePassphrase.Core.xml</DocumentationFile>
  <SignAssembly>true</SignAssembly>
  <AssemblyOriginatorKeyFile>MurrayGrant.snk</AssemblyOriginatorKeyFile>
</PropertyGroup>

```

One of my biggest take aways targeting multiple frameworks is you end up spending more time directly editing the project file.
Rather than managing merge conflicts, you're changing framework conditionals.
All in all, that's a pretty good trade off!


### Compiler Errors

At this point I was down to fixing a bunch of compiler errors.
Most were pretty easy.
Solutions involved either a) working out an alternate way of doing the same thing compatible in both frameworks, or b) [conditional compiler directives](https://docs.microsoft.com/en-us/dotnet/standard/frameworks) based on frameworks. 

Easy stuff:

* There's no more `AssemblyInfo.cs`, the new project file takes care of that. Delete that file.
* No `Serialisable` attribute .NET Standard - conditionals to sort that out.
* `ApplicationException` is no more. I just changed to throwing `Exception`.

And one other little change: using `RandomNumberGenerator.Create()` instead of `new RNGCryptoServiceProvider()`. 
To allow for a slightly more cross platform random number generator.


### Reflection Dramas

The more difficult problem was reflection.
Readable Passphrase Generator uses reflection in two places 1) to load the dictionary file, and 2) to load and save phrase definitions.

**Problem 1**: I use the entry point assembly to [find the directory](https://bitbucket.org/ligos/readablepassphrasegenerator/src/default/trunk/ReadablePassphrase.Core/Dictionaries/ExplicitXmlDictionaryLoader.cs) containing the XML dictionary file.
That is, `System.Reflection.Assembly.GetEntryAssembly().Location`. 
But there's no `Assembly.GetEntryAssembly()` in .NET Standard 1.3. 
It only appears in 1.5. 

After a bunch of research, I couldn't find a solution to this one.
So I changed the behaviour slightly: I used `Directory.GetCurrentDirectory()` instead.
Not as reliable as `GetEntryAssembly` but good enough for my purposes.
(And, once I published NuGets, I ended up with a different solution to the default dictionary - read on!).

**Problem 2**: Loading and saving phrase definitions involves reflecting over some attributes.
But .NET Standard uses `GetTypeInfo()` (plus some extension packages) instead of `GetType()`.
However, .NET 4.0 doesn't know about `GetTypeInfo()`.
So more compiler conditionals, and a [wrapper extension method](https://bitbucket.org/ligos/readablepassphrasegenerator/src/default/trunk/ReadablePassphrase.Core/Helpers/TypeHelpers.cs).


That's about it, simple project yields reasonably easy problems to fix.
And now it compiles!


### Building

Now I needed to fix some simple build scripts (cmd files).
I'm not interested in cross platform builds, so its just some tweaks to the cmd files.

I get to use the [dotnet](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet?tabs=netcore21) command for this (rather than the old `msbuild`; although I believe `dotnet` is wrapping `msbuild` anyway).

* **dotnet clean**: clean the project / solution.
* **dotnet build**: build the project / solution.
* **dotnet publish**: build the project / solution ready for distribution.
* **dotnet pack**: build nuget package for project.

Script changes for [building the console app](https://bitbucket.org/ligos/readablepassphrasegenerator/src/default/trunk/build%20console.cmd) involved creating new zip files for <del>.NET Standard</del> err... .NET Core.
This was when I realised the framework for entry points (eg: console apps) can't be .NET Standard.
.NET Standard is for library or package developers, .NET Core is for actually running applications.

The [KeePass Plugin build](https://bitbucket.org/ligos/readablepassphrasegenerator/src/default/trunk/build%20PLGX.cmd) can use `dotnet build` to get .NET 4.0 binaries, but you then need to copy everything required to a separate folder to build the [PLGX file](https://keepass.info/help/v2_dev/plg_index.html).
Including the old project file, because KeePass uses it to build the PLGX (particularly to work out references).

Finally, I get to testing!
Slightly more complicated than before:

* KeePass plugin on Windows 
* KeePass plugin Linux (OK, I'll admit to not testing this one personally)
* Console app on .NET 4.0 Windows
* Console app on Mono Linux 
* Console app on .NET Core Windows 
* Console app on .NET Core Linux

I used [WSL](https://docs.microsoft.com/en-us/windows/wsl/about) with the new [Debian 9 distribution](https://www.microsoft.com/en-au/p/debian-gnu-linux/9msvkqc78pk6) to do the Linux testing. 
I have no idea how close WSL is to a real Linux install, but .NET Core and Mono ran fine.


### Publishing NuGets

The last step was to get the project out onto NuGet.

And again, the big picture decision I needed to make was either one package for everything, or one package per project?

The guidelines on [NuGet's doco](https://docs.microsoft.com/en-us/nuget/create-packages/creating-a-package) pushed me to the direction of one per project.
Which, at this point, meant 2 packages:

* The `Words` project (which contains interfaces, abstract classes and data entities; it's only useful on its own if you want to build your own dictionary loader).
* The `Core` project (which has all the useful stuff).

The dictionary had been distributed as a separate (gzipped) xml file. 
But that would mean you'd acquire code from NuGet, then the dictionary (which is really quite essential) would need to come from somewhere else.
Which sounds like a silly idea.

So I created a new project & package for the `DefaultDictionary`.
This contains the gzipped dictionary as an embedded resource, and a simple method to load it.

Next problem: you need to acquire 2 packages to use the passphrase generator: `Core` and `DefaultDictionary`.
That strikes me as extra work which 99% of people wouldn't care for.

So I created yet another new project & package `ReadablePassphrase`.
This one is a (highly simplified) [meta package](https://docs.microsoft.com/en-us/dotnet/core/packages#metapackages), like [Microsoft.AspNet.App](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/metapackage-app?view=aspnetcore-2.1).
Effectively, its a project with a static `Generator.Create()` method, and dependencies on `Core` and `DefaultDictionary`.

So now, 99% of consumers can just use [ReadablePassphrase](https://www.nuget.org/packages/ReadablePassphrase/), and anyone who wants to do something unusual (like use a different dictionary, or use different code to load the dictionary) can reference individual packages.

In retrospect, I probably should have just bundled everything into one package, but at least I learned something!


### Referencing NuGets

As I created each NuGet package, I realised I couldn't refer to each project any longer.
That is, `ProjectReference` elements in the project file don't work; after all, each of my projects are in NuGets now, and for `dotnet pack` to figure out the dependencies, it needs to work in terms of packages instead.

So, `ProjectReference` elements get replaced with `PackageReference`.
And I add a `NuGet.config` file to my top level solution folder, to tell NuGet to find my local (as yet, unpublished) packages on my computer:

```
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <add key="ReadablePassphraseBuilds" value="../releases" />
    </packageSources>
</configuration>
```

So as each package is created in my `releases` folder, consumers of it find the package on my computer.


### Consuming it!

Finally, the ultimate test: consume the generator from [Make Me A Password](https://bitbucket.org/ligos/makemeapassword/src).

This was just like any other NuGet package: I deleted the old DLLs from the [lib](https://bitbucket.org/ligos/makemeapassword/src/default/MakeMeAPassword.Web/Lib/) folder, and included [ReadablePassphrase](https://www.nuget.org/packages/ReadablePassphrase/) via NuGet.
And, for sake of setting a good example, I followed my own [documentation for using the generator](https://bitbucket.org/ligos/readablepassphrasegenerator/wiki/Public-API).

And it worked!

Except, Make Me a Password lets you download the dictionary.
Which works fine when the dictionary is a stand alone file, but less so when its wrapped up as an embedded resource.

I've subsequently added a method to the `DefaultDictionary` package which provides the `Stream` of the dictionary.
But it came too late for the NuGet.


### Outstanding Issue - Debug Symbols

`dotnet pack` can create package versions with debug symbols with the `--include-symbols` option.
However, this doesn't include the PDB files in the main package, but creates an additional *symbol* package which includes the DLLs *and* PDBs.

I haven't worked out how I should publish the symbol packages just yet.
And, I'd prefer to simply include PDBs with the main package.
I'll sort that out next time I deploy.

### Outstanding Issue - Package Signing

A recent change in my deployments was to provide [signatures and hashes](https://bitbucket.org/ligos/readablepassphrasegenerator/wiki/Signatures-and-Hashes) for all binaries (PLGX, and console apps).

These changes took me from 2 binaries to sign to 11!
That was 1 PLGX and 1 ZIP, and is now 1 PLGX, 2 ZIPs (Console for .NET Desktop and .NET Core) and 8 NUPKG files (4 normal, 4 debug symbol)!
I'll need to work out an automated way of producing them, because it's painful to do it manually.

NuGet has recently added support for [package signing](https://docs.microsoft.com/en-us/nuget/create-packages/sign-a-package), however, it uses X.509 code signing certificates.
And those aren't free - [the cheapest](https://www.certum.eu/en/cert_offer_code_signing/) I could find is around AU$50.
So, until I get a few [donations](https://blog.ligos.net/donate.html), I won't be code signing yet.


## Conclusion

Well, it wasn't exactly trivial, but certainly wasn't too hard either.
I've created my first .NET Standard library, first .NET Core project, and first NuGet packages.
And, hopefully, made it just a little bit easier for people to consume the Readable Passphrase Generator.

Overall, the differences between .NET Desktop, .NET Core and .NET Standard are pretty small.
Reflection is the main outstanding still, but no where as bad as the .NET Core 1.0 days, and some helper methods and compiler conditionals work around the problems well enough.

I suspect Terninger will be easier, because it isn't going to be multi-targeting frameworks (yet).
I'll see how I go!

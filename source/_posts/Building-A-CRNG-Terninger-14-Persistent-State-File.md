---
title: Building a CPRNG called Terninger - Part 14 Persistent State File
date: 2022-10-28
tags:
- Dice
- Fortuna
- RNG
- CPRNG
- Crypto
- Terninger-Series
- Random
- C#
- Save
- Persistent-State
categories: Coding
---

Saving state to a file.

<!-- more --> 

## Background

You can [read other Terninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/), or see [the source code](https://github.com/ligos/terninger).

So far, I've put Terninger into production in [makemeapassword.ligos.net](https://makemeapassword.ligos.net). 

## Goal

It's been a long while since my last Terninger post, but it's been working well enough and my time has been spent in other places.

There is one major feature of Fortuna which I never implemented: **persistent state**.

That is, the ability for `PooledEntropyCprngGenerator` to save its internal state to disk.
This state would include digests of all pools which have gathered entropy (plus various other information).

Without this feature, every time I restart [makemeapassword.ligos.net](https://makemeapassword.ligos.net), Terninger needs to start reading entropy from scratch.
As I reboot my servers each week to avoid memory leaks and other random badness, that means Terninger can only accumulate entropy for 7 days before it has to start again.

With this feature, the accumulated entropy should increase forever (as long as the file on disk remains).
And I'm serious about the *forever* part - each pool accumulates using SHA512, and 2^512 is a [really big number](https://en.wikipedia.org/wiki/Names_of_large_numbers).


### Sub Goals

The reason persistent state took so long to implement (other than me getting distracted with other projects), is it has a number of moving parts.
Rather than one giant post, I'll split this up into smaller ones:

1. Saving and loading the state (this post).
2. Getting and setting the state from components which make up Terninger.
3. Integrating points 1 and 2 with the main entropy gathering worker loop.

### Details

Drilling into point 1 in a bit more detail, here's what I want to achieve:

* The C# interfaces to load and save.
* An out of the box solution for persistent state - the simplest solution is a text file on disk.
* The out of the box solution should have no external dependencies - as I'm targeting `netstandard 1.3`, that rules out JSON and XML.
* A way to extend Terninger to load and save to other locations - if someone wants to save an encrypted file or to a database then they should be able to.
* The C# data structures required to represent discrete pieces of data in memory: key + value pairs work very nicely.
* A way to keep data from different objects separate - that is, some kind of namespace or nesting.
* Values must have strong support for binary data - because the primary use case is storing SHA512 digests.

## File Format

Data always survives longer than code.
So I think long and hard about the on-disk and in-memory format of any kind of persistent state.

Once I've worked out what the data looks like, other code and interfaces become relatively obvious.

Creating a namespaced key value pair is easy enough:

```cs
public readonly struct NamespacedPersistentItem {
  public readonly string Namespace;
  public readonly string Key;
  public readonly byte[] Value;
}
```

Saving that to a text file is easy: pick a delimiter (tab works well), base64 encode the `Value`, and store each item on a separate line. Eg:

```
ANamespace <TAB> AKey           <TAB> WusWRBaOzm7zX3KQzdNhVpS+6aJHvpCXO8P1yJq3Zi0=
Terninger  <TAB> UniqueId       <TAB> V3VzV1JCYU96bTd6WDNLUXpkTmhWcFMrNmFKSHZwQ1hPOFAxeUpxM1ppMD0
Terninger  <TAB> BytesRequested <TAB> VmpOV2VsW
Terninger  <TAB> InternalState  <TAB> VjNWelYxSkNZVTk2YlRkNldETkxVWHBrVG1oV2NGTXJObUZLU0had1ExaFBPRkF4ZVVweE0xcHBNRDA
```

However, I found pretty quickly that it wasn't just binary data that needed to be stored.
There were plenty of numbers (some `Int64`s and also `Int128`s), guids and strings which don't need to be base64 encoded at all (so long as they don't contain the delimiter).
Base64 encoding everything makes the file really hard for a human to read.

If I can't understand the content of the persistent state file, I'm probably going to get it wrong.
So I added a way to encode the binary value in different ways:

```cs
public readonly struct NamespacedPersistentItem {
  public readonly string Namespace;
  public readonly string Key;
  public readonly ValueEncoding Key;
  public readonly byte[] Value;
}

public enum ValueEncoding {
  Base64,
  Hex,
  Utf8Text,
}
```

This allows easier to understand string encodings of binary values, particularly for strings or numbers.
For example, all these encode the value `42`, and the last one is easiest for a human to read:

```
Terninger  <TAB> BytesRequestedAsBinary <TAB> Base64   <TAB> KgAAAA==
Terninger  <TAB> BytesRequestedAsHex    <TAB> Hex      <TAB> 2A000000
Terninger  <TAB> BytesRequestedAsUtf8   <TAB> Utf8Text <TAB> 42
```

Note the `ValueEncoding` doesn't affect the content of `Value` in memory.
It's more of a recommendation of how to save that `Value` in a way humans can read it (relatively) easily.

The last part of any file format is a **header**, because storing a big tab separated file with no context or metadata is likely to cause problems in future.
The Terninger file header is a single, tab delimited line with the following fields:

1. [A magic number](https://en.wikipedia.org/wiki/List_of_file_signatures) - the constant UTF8 text `TngrData`. Which also happens to fit in a `UInt64`.
2. The file version number. We're starting with version `1`!
3. An SHA256 checksum of the contents of the file (excluding the header line). If the file is damaged, this will prevent us loading corrupt data. Note this doesn't stop malicious actors seeding a poisoned file.
4. The number of lines / records in the file. This isn't required to parse the file, but helpful anyway.

An example header:

```
TngrData <TAB> 1 <TAB> UDpxL5ZiKhda8ok3/asKFbmdaihfvAzJmVhxzBP/SaI= <TAB> 3
```

This represents a simple to read and write data format capable of storing all the state Terninger requires. 
It also is extendable (via namespaces) to be used by `IEntropySource` implementations, if they need to store persistent state.

Here's an example file from a unit test:

```
TngrData <TAB> 1 <TAB> DBvlW8Nt/XTVKr/aMGWZd8N6KQ9nb8d+BNBWbfzSs8A= <TAB> 6
Namespace     <TAB> Key     <TAB> Utf8Text <TAB> Data
Namespace     <TAB> Key2    <TAB> Utf8Text <TAB> Otherdata
Namespace     <TAB> Integer <TAB> Hex      <TAB> 2A000000
Global        <TAB> Thing   <TAB> Base64   <TAB> AAECAwQFBgcJCgsMDQ4P
Global        <TAB> Key     <TAB> Utf8Text <TAB> Data
SomeNamespace <TAB> aKey    <TAB> Utf8Text <TAB> value
```


## API

When in memory, the persistent state is represented as a `PersistentItemCollection`.
It allows getting, setting and removing single items or whole namespaces of items.
Internally, it is a dictionary of `namespace > items`, and within each namespace a dictionary of `key > value`.
When getting a whole namespace, it will return an `IDictionary<string, NamespacedPersistentItem>`, which is the structure used by consumers of the collection.

```cs
public class PersistentItemCollection {
  public IDictionary<string, NamespacedPersistentItem> Get(string itemNamespace);

  public void SetNamespaceItems(string itemNamespace, IDictionary<string, NamespacedPersistentItem> items);
  public void SetNamespace(string itemNamespace, IEnumerable<NamespacedPersistentItem> items);
  public void SetItem(NamespacedPersistentItem item);
}
```

There are two interfaces to read and write the in-memory data:

```cs
public interface IPersistentStateReader {
  Task<PersistentItemCollection> ReadAsync();
}
public interface IPersistentStateWriter {
  Task WriteAsync(PersistentItemCollection items);
}
```

I don't think it gets simpler.
We have a collection of `NamespacedPersistentItem`s in a `PersistentItemCollection`, and can read the content of a whole file into memory, and then write an entire collection to file.
Might not be the most efficient algorithm, but we aren't going to be reading / writing very often, nor will be writing MBs of data.

There are two implementations of these interfaces:
* `TextStreamReader` and `TextStreamWriter`, which are able to read / write the Terninger file format to a `Stream`.
* And `TextFileReaderWriter`, which uses the stream reader / writer implementations and writes to a file on disk.

## Extending the API

As we have simple interfaces, anyone can implement a reader / writer that works differently.
For example, you may want to store persistent state in a database, or a web service, or in an encrypted file, etc.
In all cases, the implementation is relatively easy, and you can then pass your reader & writer to any Terninger instance.

If you happen to be reading / writing a `Stream` and are happy with the delimited format, then you can use `TextStremReader` and `TextStreamWriter` to look after that part.

## Namespaces and Data Isolation

The primary reason data is stored in namespaces is to isolate different parts of Terninger from each other.
The `EntropyAccumulator` is a security sensitive area of Terninger, because if you can observe the pool of entropy, it is possible you can predict future random numbers - which kinda breaks everything!
And if you can write a `MaliciousEntropySource` which spies on other persistent state, that's bad.

So any one component of Terninger can only see data for its namespace, and not other components.
The main `PooledEntropyCprngGenerator` class will ensure a component can only see its own key-value-pair list of data.
This isolation mitigates the security risk.
It also makes it easier to implement persistence within each component, as it only needs to worry about its own data.

## Security

Persistent state represents a huge security risk.

1. If you can read the persistent state on disk then you may be able to predict future random numbers.
2. If you can write to persistent state you can poison the generator and influence future random numbers.

For now, I'm just going to acknowledge the risk.
I'll discuss mitigation in a future post.

## Why not?

There are some alternative implementations I didn't go with.

### Why not arbitrary nesting instead of namespaces?

Because arbitrary nesting is harder than a fixed two level hierarchy.
And, even after implementing everything, I've only found one use case where nesting would have been helpful, and there was a simple (if tedious) work around.

### Why isn't the file encrypted, or signed, or somehow protected from the Bad Guys™?

Because it won't help.

Terninger itself needs to read the file, and if the file is encrypted then Terninger needs to know the key.
If you have a hard coded key baked into Terninger, any malicious attacker can reverse engineer Terninger to find the key (or just find the key on Github).

Perhaps you could store the key somewhere else, and that keeps the key out of the hands of our malicious attacker.
That might help, but the attacker could still find the key, and then game over.
Also, that's something else for the user of Terninger to manage - a persistent state file & a separate key.

Maybe you encrypt the key, which encrypts the persistent state.
Oh dear! We're now in infinite recursion!

Getting that kind of encryption right (and actually ensuring it provides meaningful benefits) is really hard.
And there are other mitigations I will describe in future posts.

Anyone can implement their own `IPersistentState[Reader|Writer]` if they really want this feature.


## Future Work

After writing the above interfaces and code, I found that separating the reader and writer as separate interfaces makes Terninger slightly difficult to configure.
Because you have to pass the same instance twice:

```cs
var readerWriter = new TextFileReaderWriter("/some/path/terninger.txt");
var terninger = PooledEntropyCprngGenerator.Create(
  ...
  , persistentStateReader: readerWriter
  , persistentStateWriter: readerWriter
);
```

I'm not sure if I'll ever bother to change this, but it was a bit annoying that I couldn't do this:

```cs
var terninger = PooledEntropyCprngGenerator.Create(
  ...
  , persistentStateReaderWriter: new TextFileReaderWriter("/some/path/terninger.txt");
);
```

## Conclusion

We have the data structure to keep persistent state on disk.
And the code required to load and save it.
And the API meets my non-functional requirements.

You can see the [actual Terninger code in GitHub](https://github.com/ligos/terninger/). 
And the main [NuGet package](https://www.nuget.org/packages/Terninger).

## Next up

Define an interface to get and set state from components. That is, how we add / remove from the `PersistentItemCollection`.

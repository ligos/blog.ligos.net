---
title: Building a CPRNG called Terninger - Part 15 Object State
date: 2024-01-16
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

Getting and setting state on objects.

<!-- more --> 

## Background

There's been a short (well, long) delay getting this post up. Sorry about that. 🙁

You can [read other Terninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/), or see [the source code](https://github.com/ligos/terninger). 

So far, I've put Terninger into production in [makemeapassword.ligos.net](https://makemeapassword.ligos.net). 

And we're up to the second part of **persistent state**:

1. [Saving and loading the state](/2022-10-28/Building-A-CRNG-Terninger-14-Persistent-State-File.html).
2. **Getting and setting the state from components which make up Terninger (this post).**
3. Integrating points 1 and 2 with the main entropy gathering worker loop.

## Goal

Now we are able to load and save state to a file on disk, we need a way to gather that state from in-memory objects (before we save), and to set state on in-memory objects (after we load).

Essentially, we need a way to get and set properties / fields on objects based on the file.

### Details

Here are the requirements in detail:

* Define an interface to represent getting and setting persistent state from an object.
* Implementing that interface on an object should be enough to enable usage of persistent state.
* Objects should have no knowledge of how their state is saved / loaded; they just parse or return bundles of state objects.
* Getting and setting should be implemented for core `PooledEntropyCprngGenerator` and related classes, such that entropy state is persisted across server restarts.

## Interface

Unlike loading and saving, getting and setting will always be implemented on the same objects, so it makes sense to only have one interface.
The simplest thing that could possibly work is:

```cs
public interface IPersistentStateSource {
  void Initialise(IDictionary<string, NamespacedPersistentItem> state);

  IEnumerable<NamespacedPersistentItem> GetCurrentState();
}
```

The simplest thing for a getter and setter is... well... a getter and a setter!

`Initialise()` will only be called once, when the implemented object is loading, after reading from an `IPersistentStateReader` implementation.
While `GetCurrentState()` will be called regularly over the lifetime of the generator, as state will change over time.
The result of `GetCurrentState()` can be passed to an implementation of `IPersistentStateWriter` to save.

### Use Cases

A short digression is in order at this point.

There are two use cases I have in mind for persistent state:

1. The core state in a `PooledEntropyCprngGenerator`, such that we accumulate entropy across machine restarts.
2. State which is useful in other objects, such as entropy sources (`IEntropySource`).

Because the state in a `PooledEntropyCprngGenerator` is always changing as entropy accumulates, the simple interface will work fine.

But entropy sources may not update their persistent state very often.
Many sources execute on a period measured in minutes or hours, so nothing may have changed since the last save.

### HasUpdates

To support slightly more efficient operation with entropy sources, I add a `HasUpdates` property.

```cs
public interface IPersistentStateSource {
  ...
  bool HasUpdates { get; }
}
```

This allows any objects which supports persistent state to communicate if calling `GetCurrentState()` will returns something different since last time.
And means that entropy sources which rarely change state can stay dormant for longer.

### PersistentEventType

Finally, there is a context enum passed to `GetCurrentState()`:

```cs
public enum PersistentEventType
{
    // A reseed has just occurred.
    Reseed = 1,

    // A regular periodic interval for writing state.
    Periodic = 2,

    // The pooled generator is stopping. This is the last opportunity to write persistent state.
    Stopping = 3,
}
```

This gives the object some context about what is happening, and hints at what state it should return.
In particular, `Stopping` is the last opportunity to save state before the generator stops - so you should return something in at least that case!

This enum is similar to `EntropyPriority`, which allows an entropy source to decide how aggressively it returns entropy, depending on the needs of the generator.

However, after completing all the persistent state functionality, I can't think why `GetCurrentState()` would *not* return every piece of state every time it is called.
`HasUpdates` is a better way to signal "I have nothing new".

Oh well, it's in the API now.

### Final IPersistentStateSource

Here is the final interface:

```cs
public interface IPersistentStateSource {
  void Initialise(IDictionary<string, NamespacedPersistentItem> state);
  bool HasUpdates { get; }
  IEnumerable<NamespacedPersistentItem> GetCurrentState(PersistentEventType eventType);
}
```

## Implementing

Just defining an interface is the easy part. We also need to implement it on required classes!

### Simple Implementation: PooledEntropyCprngGenerator

The main `PooledEntropyCprngGenerator` has two persistent fields.
There are a number of other fields, but they are contained in other classes.

1. A `UniqueId` which is a `Guid`.
2. A `BytesRequested` counter, which is an `Int128`.

The implementation goes like so:

```cs
void Initialise(IDictionary<string, NamespacedPersistentItem> state)
{
  if (state.TryGetValue(nameof(UniqueId), out var uniqueIdValue)
      && uniqueIdValue.Value.Length == 16)
  {
    UniqueId = new Guid(uniqueIdValue.Value);
  }

  if (state.TryGetValue(nameof(BytesRequested), out var bytesRequestedValue)
      && Int128.TryParse(bytesRequestedValue.ValueAsUtf8Text, out var bytesRequested))
  {
    BytesRequested = bytesRequested;
  }
}

bool HasUpdates => true;

IEnumerable<NamespacedPersistentItem> GetCurrentState(PersistentEventType eventType)
{
    yield return NamespacedPersistentItem.CreateBinary(nameof(UniqueId), UniqueId.ToByteArray());
    yield return NamespacedPersistentItem.CreateText(nameof(BytesRequested), BytesRequested.ToString("d", formatProvider: CultureInfo.InvariantCulture));
}
```

**Initialising** is a repetitive parsing process. Try read a field from the state dictionary, try parse the value, and if everything succeeds, set the appropriate property. 
Other classes have more state, but similar repetitive defensive code.
If anything cannot be parsed correctly, it is simply ignored.

**HasUpdates** always returns true. That's a bit a lie, but who cares about efficiency with just two fields.

**GetCurrentState** simply returns a collection of each field, either as a `byte[]` or `string`.


### Nested State: EntropyAccumulator / EntropyPool

The `PooledEntropyCprngGenerator` has an `EntropyAccumulator` member, which is the really important part of the generator.
However, the accumulator is made up of many `EntropyPool` objects.
This is a nested array of complex objects, so how do we serialise it?

We do a bunch of copying and create some "array like" keys.
Which is a bit hacky, but its the only place we need to deal with nested arrays.

We save values to define the pool counts and then array like keys for nested data:

```
Pooled...Generator.Accumulator <TAB> LinearPoolCount <TAB> Utf8Text <TAB> 20
Pooled...Generator.Accumulator <TAB> RandomPoolCount <TAB> Utf8Text <TAB> 12

Pooled...Generator.Accumulator <TAB> LinearPool.0.TotalEntropyBytes           <TAB> Utf8Text <TAB> 3674
Pooled...Generator.Accumulator <TAB> LinearPool.0.EntropyBytesSinceLastDigest <TAB> Utf8Text <TAB> 16
Pooled...Generator.Accumulator <TAB> LinearPool.0.EntropyHash                 <TAB> Hex      <TAB> 5DC1F9...
Pooled...Generator.Accumulator <TAB> LinearPool.1.TotalEntropyBytes           <TAB> Utf8Text <TAB> 4179
Pooled...Generator.Accumulator <TAB> LinearPool.1.EntropyBytesSinceLastDigest <TAB> Utf8Text <TAB> 4
Pooled...Generator.Accumulator <TAB> LinearPool.1.EntropyHash                 <TAB> Hex      <TAB> C5D344...
...

Pooled...Generator.Accumulator <TAB> RandomPool.0.TotalEntropyBytes           <TAB> Utf8Text <TAB> 3290
Pooled...Generator.Accumulator <TAB> RandomPool.0.EntropyBytesSinceLastDigest <TAB> Utf8Text <TAB  80
Pooled...Generator.Accumulator <TAB> RandomPool.0.EntropyHash                 <TAB> Hex      <TAB> F82DF0...
Pooled...Generator.Accumulator <TAB> RandomPool.1.TotalEntropyBytes           <TAB> Utf8Text <TAB> 3824
Pooled...Generator.Accumulator <TAB> RandomPool.1.EntropyBytesSinceLastDigest <TAB> Utf8Text <TAB> 280
Pooled...Generator.Accumulator <TAB> RandomPool.1.EntropyHash                 <TAB> Hex      <TAB> 194BA2...
...
```

Each `EntropyPool` returns its 3 fields directly:

```cs
IEnumerable<NamespacedPersistentItem> GetCurrentState(PersistentEventType eventType)
{
  yield return NamespacedPersistentItem.CreateText("TotalEntropyBytes", TotalEntropyBytes.ToString("d", CultureInfo.InvariantCulture));
  yield return NamespacedPersistentItem.CreateText("EntropyBytesSinceLastDigest", EntropyBytesSinceLastDigest.ToString("d", CultureInfo.InvariantCulture));
  yield return NamespacedPersistentItem.CreateBinary("EntropyHash", GetCurrentDigest());
}
```

And the `EntropyAccumulator` copies that data into array like keys:

```cs
IEnumerable<NamespacedPersistentItem> GetCurrentState(PersistentEventType eventType)
{
  yield return NamespacedPersistentItem.CreateText("LinearPoolCount", _LinearPools.Length.ToString(CultureInfo.InvariantCulture));
  yield return NamespacedPersistentItem.CreateText("RandomPoolCount", _RandomPools.Length.ToString(CultureInfo.InvariantCulture));

  for (int i = 0; i < _LinearPools.Length; i++)
  {
      var pool = _LinearPools[i];
      var stateSource = (IPersistentStateSource)pool;
      foreach (var item in stateSource.GetCurrentState(eventType))
      {
          yield return $"LinearPool.{i}.{item.Key}");
      }
  }
  // And again for _RandomPools.
}
```

It's a bit of work, but effective.
If there were more nested arrays or objects, I'd consider a more robust approach.

### Security: Entropy Pool

OK, time to deal with the security problems that external state raises:

1. An attacker can read the persistent state on disk and be able to predict future random numbers.
2. An attacker can write to persistent state when the generator is stopped and poison the generator such that they can predict future random numbers.

In simpler terms: reading or writing persistent state is working with untrusted and potentially tainted data.

The **first problem** is dealt with in `EntropyPool.GetCurrentState()`: we don't save the current pool (hash) state, instead we save a hash of the hash.
This is fine when we re-read the hash into the pool, because the hash of the hash is just as random as the original hash.
But it hides the internal state of the generator because a hash function cannot be (easily) reversed.

```cs
IEnumerable<NamespacedPersistentItem> GetCurrentState(PersistentEventType eventType)
{
    var digest = GetCurrentDigest();
    AccumulateBlock(digest, digest.Length);
    var digestToPersist = GetCurrentDigest();
    AccumulateBlock(digest, digest.Length);
    yield return NamespacedPersistentItem.CreateBinary("EntropyHash", digestToPersist);
}
```

The **second problem** is dealt with partially in `EntropyPool.Initialise()`: we don't directly load the data from disk, but also include some extra entropy.

```cs
void Initialise(IDictionary<string, NamespacedPersistentItem> state)
{
  if (state.TryGetValue("EntropyHash", out var entropyHashValue))
  {
    AccumulateBlock(entropyHashValue.Value, entropyHashValue.Value.Length);
    var extraEntropy = PortableEntropy.Get32();
    AccumulateBlock(extraEntropy, extraEntropy.Length);
  }
}
```

There is another mitigation for the second problem which I'll discuss in the next post.

But I will note one thing which _won't_ work: **file security bits / ACLs**.
While using some kind of file system based security might mitigate the problem, it can't be relied upon - perhaps the state is being stored somewhere with no security.
Or, perhaps the attacker has the same (or higher) security context than Terninger, so they can write to the file anyway.

## Future Work

Potential points for improvement:

* Better support for arrays and other complex object graphs. I'll come back to that if there's a compelling need.
* Some kind of auto-serialisation - similar to how most JSON serialisers work.
* And we'll see how things pan out when I implement `IPersistentStateSource` for an `IEntropySource`. I have a particular use case in mind.

## Next Up

We now have a way to get and set persistent state on relevent objects.

You can see the [actual Terninger code in GitHub](https://github.com/ligos/terninger/). 
And the main [NuGet package](https://www.nuget.org/packages/Terninger).

Next up: we'll wire up the various `IPersistentStateSource`s and the `IPersistentStateReader` / `IPersistentStateWriter` in `PooledEntropyCprngGenerator` to load state as part of initialisation, and periodically save it.

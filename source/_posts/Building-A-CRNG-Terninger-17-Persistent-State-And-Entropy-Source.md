---
title: Building a CPRNG called Terninger - Part 17 Persistent State and Entropy Source
date: 2024-02-27 
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

Enhancing PingStatsSource with persistent state.

<!-- more --> 

## Background

You can [read other Terninger posts](/tags/Terninger-Series/) which outline my progress building a the [Fortuna CPRNG](https://www.schneier.com/academic/fortuna/), or see [the source code](https://github.com/ligos/terninger). 

So far, I've put Terninger into production in [makemeapassword.ligos.net](https://makemeapassword.ligos.net). And persistent state is working in the core generator

But I'd really like to use persistent state in entropy sources for fun and profit!
In particular, `PingStatsSource` has a limitation which can be overcome using persistent state: there is a hard coded list of servers it pings, which needs regular maintenance.

## Goal

1. Wire up persistent state with any entropy source. The source will be initialised on load, and included when state is saved.
2. Enhance `PingStatsSource` to track which servers are working using persistent state.
3. Enhance `PingStatsSource` to discover new servers by randomly scanning the Internet.

## Wire Up Persistent State to Entropy Sources

The convention is: any `IEntropySource` which also implements `IPersistentStateSource` will have persistent state loaded & saved automatically by `PooledEntropyCprngGenerator`.

There is already support to initialise objects from state on loading, so this should be pretty easy!
Simply call this method during initialisation:

```cs
private void InitialiseEntropySourcesFromPersistentState(PersistentItemCollection persistentState)
{
	if (persistentState == null)
		return;
	Logger.Trace("Initialising entropy sources from persistent state.");

	foreach (var source in _EntropySources)
	{
		if (source is IPersistentStateSource sourceForPersistentState)
		{
			sourceForPersistentState.Initialise(source.Name);
			Logger.Trace("Initialised entropy source '{0}' from persistent state.", source.Name);
		}
	}
}
```

That's easy!

Except, you can add additional `IEntropySource` objects to the generator after it starts.
And these should also be initialised.
Exactly once.

That's a bit more tricky.

Fortunately, there was already `SourceAndMetadata`, which combines an entropy source with some additional data (eg: has it thrown exceptions, does it complete synchronously or asyncronously).
So I added an `IsExternalStateInitialised` field, and wrapped the initialisation into `InitialiseFromExternalState()`.
That gets called every time we poll the source, and will return early if its already been initialised.

```cs
public void InitialiseFromExternalState(PersistentItemCollection state)
{
	if (IsExternalStateInitialised)
		return false;
	if (Source is IPersistentStateSource sourceForPersistentState) {
		sourceForPersistentState.Initialise(state.Get(Name));
	}
	IsExternalStateInitialised = true;
}
```

To **save** state, I added `GetPersistentStateOrNull(PersistentEventType eventType)` to `SourceAndMetadata`.
And simply called it when saving all the other persistent state, remembering to put each source into a namespace:

```cs
foreach (SourceAndMetadata sm in _EntropySources)
{
	var state = sm.GetPersistentStateOrNull(eventType);
	if (state != null) {
		persistentState.SetNamespace(sm.Name, state);
	}
}
```

And with that, all `IEntropySources` are wired up and ready to persist some state!

## Tracking Targets

`PingStatsSource` sends [ICMP echo requests](https://en.wikipedia.org/wiki/Ping_%28networking_utility%29) (aka, pings) to a hard coded list of servers.
There is a way to configure a custom list of servers, but I personally don't use it.

Unfortunately, even though I chose DNS servers as the list, which shouldn't change very often, they do change occasionally.
And so, I need to update the list every now and then.

Well, now we have persistent state, we can keep the list of servers there.
If a server disappears off the internet, we simply remove it from the list and move on with life.
The internal list becomes an initial seed, rather than the canonical list for all time.

OK, so how does this work?

First thing, we need to wire up `IPersistentStateSource` to load and save.
I won't show the code, because its very similar to [last time](/2024-01-16/Building-A-CRNG-Terninger-15-Object-State.html) where we create an array-like structure.
This is what ends up being saved:

```
PingStatsSource	TargetCount	Utf8Text	1024
PingStatsSource	Target.1	Utf8Text	1.0.0.1
PingStatsSource	Target.2	Utf8Text	1.1.1.1
PingStatsSource	Target.3	Utf8Text	1.241.94.128
PingStatsSource	Target.4	Utf8Text	100.11.201.175
PingStatsSource	Target.5	Utf8Text	101.201.69.196
PingStatsSource	Target.6	Utf8Text	103.1.206.179
PingStatsSource	Target.7	Utf8Text	104.132.20.107
...
```

The core internal state is a list of `PingTarget`.
We'll add and remove to this over the lifetime of the object, including via `IPersistentStateSource`.
(And, I'll come back to why the abstract `PingTarget` rather than simple `IPAddress`).

```cs
private List<PingTarget> _Targets = new List<PingTarget>();
```

The first time we get entropy, we check if there are any targets.
If not, we load up the internal seed list to get started.

```cs
if (_Targets.Count == 0)
	// No prior persisted state: load a seed list to get started.
	await InitialiseTargetsFromSeedSource();
```

When we gather entropy, we track which targets fail (timeout, network error, etc). 
Normally, we ping a target 6 times.
Well, if we get 6 failures, we assume the target is offline, and remove it.

```cs
List<PingAndStopwatch> targetsToSample = ...;
// Gather entropy
// ...

var failedTargets = targetsToSample
		.Where(x => x.Failures == _PingsPerSample)
		.Select(x => x.Target)
		.ToList();

// Other logic here...

foreach (var t in failedTargets) {
	_Targets.Remove(t);
}
```

That's it!
Targets which fail all 6 pings will be removed, never to be seen again.

Unfortunately, given enough time, we'll remove all the targets.
Better do something about that!

## Discover New Targets

In order to discover new targets, we need to find a valid IP address, and then send some pings to confirm it works.
Fortunately, the IPv4 address space is so full of reachable targets, that any random 32 bit number has a good chance of being valid.

```cs
private Task DiscoverTargets(int targetCount)
{
	var targets = new List<PingTarget>(targetCount);
	var bytes = new byte[4];

	while (targets.Count < targetCount)
	{
		// IPv4 address space is so full we can pick random bytes and its pretty likely we'll hit something.
		_Rng.FillWithRandomBytes(bytes);

		if (bytes[0] == 0
			|| bytes[0] == 127
			|| (bytes[0] >= 224 && bytes[0] <= 239)
			|| bytes[0] >= 240
		)
			// 0.x.x.x is reserved for "this" network
			// 127.x.x.x is localhost and won't give useful timings
			// 224-239.x.x.x is multicast
			// 240-255.x.x.x is reserved for future use (probably never)
			continue;
		
		var ip = new IPAddress(bytes);
		if (_Targets.Any(x => ip.Equals(x.IPAddress)))
			// Let's not add the same target twice!
			continue;

		targets.Add(new PingTarget(ip));
	}

	// Discovery runs 3 pings.
	// If any one of the pings returns OK, the target will be added.
	var targetsToSample = targets.Select(x => new PingAndStopwatch(x, _Timeout)).ToList();

	await Task.WhenAll(targetsToSample.Where(x => x.Failures >= 0).Select(x => x.ResetAndRun()).ToArray());
	await Task.WhenAll(targetsToSample.Where(x => x.Failures >= 1).Select(x => x.ResetAndRun()).ToArray());
	await Task.WhenAll(targetsToSample.Where(x => x.Failures >= 2).Select(x => x.ResetAndRun()).ToArray());

	var toAdd = targetsToSample.Where(x => x.Failures < 3).Select(x => x.Target).ToList();
	_Targets.AddRange(toAdd);
}
```

We want to add `n` new targets (where `n` is 8 by default).
So we generate `n` random IP addresses, excluding several ranges which we know are invalid up front.
We then send up to 3 pings to each target.
So long as any one ping succeeds, we add it to the list.

The IPv6 address space is, for all practical purposes, empty.
So randomly picking 128 bit numbers isn't going to work.
For now, I'm putting IPv6 discovery in the too-hard-basket and marking it with a great big `TODO`.

Moving on, let's add a few properties to the configuration so users have the option to turn off discovery (if they want) and to control the desired number of targets (`TargetsPerSample` was already there):

```cs
public class Configuration
{
	/// <summary>
	/// Number of targets to ping from the list each sample.
	/// Default: 8. Minimum: 1. Maximum: 100.
	/// </summary>
	public int TargetsPerSample { get; set; } = 8;

	/// <summary>
	/// Automatically discover new targets to ping by randomly scanning the Internet.
	/// Default: true.
	/// </summary>
	public bool DiscoverTargets { get; set; } = true;

	/// <summary>
	/// Count of targets to accumulate when discovering.
	/// Default: 1024. Minimum: 1. Maximum: 65536.
	/// Each target will be recorded in persistent state.
	/// </summary>
	public int DesiredTargetCount { get; set; } = 1024;
}
```

Finally, we wire this new method up to `GetInternalEntropyAsync()`, after we gather entropy:

```cs
if (_EnableTargetDiscovery && _Targets.Count < _DesiredTargetCount)
{
	await DiscoverTargets(_TargetsPerSample);
}
```

Now we remove targets which don't work, and automatically discover new targets which do.
And anything in `_Targets` is persisted, so we don't start from scratch next time around.

## TCP Ping

One last feature: TCP ping.

[ICMP echo request](https://en.wikipedia.org/wiki/Ping_%28networking_utility%29) is the technical name for what we refer to as _ping_.
But routers and firewalls can be configured to ignore _pings_ (which might provide some tiny improvement in security by pretending you aren't on the Internet).

But there are lots of web servers out there, listening on port 80 and 443.
They cannot ignore requests to those ports, because that is what web servers do.
Which means there are potentially more targets out there to be discovered.

Instead of an ICMP echo request, we will do the initial [3 way TCP handshake](https://www.geeksforgeeks.org/tcp-3-way-handshake-process/), which establishes a new TCP connection, and then immediately drop said connection.
This is roughly equivalent to a regular ICMP ping, just using TCP instead.

The code to achieve this is quite simple:

```cs
public async Task<(bool isSuccess, object error)> TcpPing(IPAddress address, int port, TimeSpan timeout)
{
	using (var socket = new Socket(IPAddress.AddressFamily, SocketType.Stream, ProtocolType.Tcp))
	using (var cancel = new CancellationTokenSource())
	{
		try
		{
			cancel.CancelAfter(timeout);
			await socket.ConnectAsync(address, port, cancel.Token);
			return (true, SocketError.Success);
		}
		catch (OperationCanceledException)
		{
			return (false, SocketError.TimedOut);
		}
		catch (SocketException ex)
		{
			return (false, ex.SocketErrorCode);
		}
	}
}
```

This works wonderfully, but we now have two kinds of `PingTarget`.
There is `IcmpTarget` and `TcpTarget`.
The ICMP target only needs an IP address to function, but the TCP target needs a port as well.

Actually, there are three kinds!
The third one is `IpAddressTarget` is just an IP address; we don't know if its ICMP or which TCP port to try.
But, we can run the discovery process on this address to convert it into `IcmpTarget`s and `TcpTarget`s.
These "naked" IP addresses are the seed list.

Here's some simple inheritance to model this:

```cs
abstract class PingTarget { 
	public IPAddress IPAddress { get; }
}
sealed class IcmpTarget : PingTarget {
}
sealed class TcpTarget : PingTarget {
	public int Port { get; }
}
sealed class IpAddressTarget : PingTarget {
}
```

How will we serialise and parse these?

The easiest is `IpAddressTarget`, it's interchangeable with a regular `IpAddress`:

```
1.1.1.1
2606:4700:4700::1111
```

Now we need a way to represent either a port number, or an ICMP ping.
There's a standard way to encode a [TCP Endpoint](https://learn.microsoft.com/en-us/dotnet/api/system.net.ipendpoint), and we'll use something similar for ICMP:

```
1.1.1.1:80
1.1.1.1:ICMP
[2606:4700:4700::1111]:80
[2606:4700:4700::1111]:ICMP
```

These can all be unambiguously parsed and serialised.
IPv4 is easy to split on the `:`, and IPv6 a bit more complex because we need to find matching square brackets.
For simplicity, I use `.ToString()` for serialisation (that's not always a good idea, but good enough in my case).
And the parser a static method following the `Try...()` pattern common in C#, the `out` parameter will be one of `IcmpTarget`, `TcpTarget` or `IpAddressTarget`.

```cs
class PingTarget {
  public static bool TryParse(string s, out PingTarget result) {
	...
  }
}
```

We also need a `Ping()` method.
I'm not usually a fan of inheritance, but in this case its very effective because each type can implement ICMP or TCP ping, as required:

```cs
class PingTarget {
	public abstract Task<(bool isSuccess, object error)> Ping(TimeSpan timeout);
}
```

The final piece of the puzzle is how to convert from the seed list containing `IpAddressTarget` into `IcmpTarget` and `TcpTarget`?
Well, as part of the main `GetInternalEntropyAsync()` method, we pick a few `IpAddressTarget`s, and run discovery on them:

```cs
var forDiscovery = _Targets.OfType<IpAddressTarget>().Take(_TargetsPerSample).ToList();
if (forDiscovery.Any())
{
	await DiscoverTargets(forDiscovery);
}
```

## That's All For Now!

We now have persistent state wired up to any entropy source which needs it.
And made meaningful improvements to `PingStatsSource` so it requires less of my attention.
It automatically removes servers when they go offline, and discovers new ones.

You can see the [actual Terninger code in GitHub](https://github.com/ligos/terninger/). 
And the main [NuGet package](https://www.nuget.org/packages/Terninger).

After a long time developing Terninger on and off, I'm going to stop posting about it.
Because the core functionality is all done!

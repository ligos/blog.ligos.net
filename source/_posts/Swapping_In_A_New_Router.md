---
title: Swapping In A New Router
date: 2019-04-22
tags:
- Mikrotik
- Network
- Internet
- Firewall
- vLAN
- Migration

categories: Technical
---

How to upgrade your router with minimal downtime.

<!-- more --> 

## Background

I have been using a [Mikrotik RB2011](https://mikrotik.com/product/RB2011UiAS-2HnD-IN) for several years as my [Internet router & gateway](/2017-02-16/Use-A-Mikrotik-As-Your-Home-Router.html).
But it's time to upgrade!
I got a shiny new [hEX S](https://mikrotik.com/product/hex_s) + [1G ethernet SFP module](https://mikrotik.com/product/S-RJ01) for Christmas, and it's time to swap it in as my new border router.

Of course, its not quite that easy.
I'm hosting [makemeapassword.ligos.net](https://makemeapassword.ligos.net/), this blog, and various other smaller things.
And I'd like to keep downtime to a minimum - both externally, and internally (kids and wife don't like YouTube and Facebook not working).

And, the [NBN is coming](https://www.nbnco.com.au/) to my area in the next 3-6 months.
So my final setup will need to allow for my ADSL and NBN connections to run in parallel for a short time, while I make that cut over.


## Goal

I want my hEX S to be my main Internet gateway & router.
It should be my main Internet border device, my wAP should be connected to it, plus maybe a key server.

My old RB2011 will remain my guest WiFi AP (along with a 100Mb ethernet port), but will become more of a general purpose switch with a few VLANs.
There will be an uplink port to the hEX, but most wired devices will be physically connected to the RB2011.

<img src="/images/Swapping-In-A-New-Router/network-gear-before.jpg" class="" width=300 height=300 alt="Networking Gear Before Change-Over" />

All through this process, I want to minimise downtime - the less time devices don't work and can't get to the Internet, the better.


## Steps

Rather than planning this out in detail (and almost certainly find I'm wrong part way through), I'm going to dump my config, identify things which can be migrated easily, do the migration, test, rinse and repeat.

So, slowly, my RB2011 will do less and less, and my hEX will do more and more.
And at each step, I'll make sure things keep working.

I know there'll be some critical points where there will be downtime, so I'll highlight them, try to make them happen quickly, and always have a backout plan.


### 0. Dump Config

Mikrotik has 2 ways to do a [configuration backup](https://wiki.mikrotik.com/wiki/Manual:Configuration_Management): 1) `Files` -> `Backup` is a binary backup which is good for restoring in event of a hardware failure, and 2) `Console` -> `Export` is a text backup which scripts out commands that will restore your config. 
The later is human readable, the former is not.

```
[admin@Mikrotik-gateway] > export file=config 
```

And I end up with ~700 line text file with a whole stack of commands which represent everything I've changed in my router!


### 1. Physical Connections (and vLANS)

First up is to connect the hEX with the RB2011, both physically via ethernet, and by configuring the right vLANs, so my various networks appear correctly.
I'll end up with my main LAN, hosting LAN, phones and guest networks all appearing on the hEX (via a bunch of vLANs), each with their own IP address.
I also took this opportunity to assign (and name) the various physical ports on the hEX, and rename ports on the RB2011.

The way I've done the vLANs (as separate interfaces of the uplink port) means I also create a bridge for each network so I can connect ports together.
Rather than assigning IP addresses to the vLAN / port, I assign to the bridge.
This gives much more flexibility down the line if I need to change port assignments (eg: change `eth4` from LAN to Hosting).

<img src="/images/Swapping-In-A-New-Router/Interfaces-Bridges-Addresses.png" class="" width=300 height=300 alt="Interfaces, Bridge definition and IP Addresses" />

Port #2 is assigned as an uplink port to the RB2011, so it has various vLANs hanging off it.
Port #4 is the corresponding port on the RB2011.

<img src="/images/Swapping-In-A-New-Router/Interfaces-on-RB2011.png" class="" width=300 height=300 alt="Interfaces on RB2011" />

As much as I wanted to make port #1 the "most important" port, or group similar ports together (eg: hosting servers), pragmatism quickly took over: it really doesn't matter very much to the router, and as long as I label the interfaces correctly in the config, it doesn't matter too much to me either.
So things are a little jumbled, but that's OK.


### 2. Swap WiFi Over

Port #3 is designated as the port to my [wAP ac](https://mikrotik.com/product/RBwAPG-5HacT2HnD).
I replicated the vLAN settings for the wAP so I could just swap the cable across.

<img src="/images/Swapping-In-A-New-Router/Interfaces-Bridges-For-Wifi.png" class="" width=300 height=300 alt="Interfaces and Bridge for WiFi AP" />

As a convention for vLAN ids, I've chosen to use my subnet.
My phones network is `10.46.2.0/24`, so the vLAN id is `2`.
As long as there's a vLAN interface is on both routers, it just works.

<img src="/images/Swapping-In-A-New-Router/vLAN-Interface.png" class="" width=300 height=300 alt="Example vLAN Interface" />


### 3. Lots of Config

At this point, all the physical and vLAN config is done.
So time to transfer a stack of configuration across to the hEX.
I took the opportunity to review configuration as I migrated it, which meant I could tweak or remove some parts.

Your process will be different depending on how your network is configured, but here are a list of really important places to visit:

* **IP -> Pool:** where DHCP ranges live.
* **IP -> DHCP:** *Server*, *Networks* and *Leases* tabs - I have a stack of static leases that needed to be migrated.
* **IP -> DNS -> Static:** various important devices have DNS names assigned here.
* **Interfaces -> Interface List:** you may need to adjust the automatic lists here.
* **IP -> Firewall rules:** I had a stack of rules to review and migrate.
* **IPv6 -> Pool:** my static IPv6 assignments for each vLAN live here.
* **IPv6 -> DHCP Client:** required to use IPv6 over my ADSL PPPoE connection.
* **IPv6 -> Firewall rules:** these are simplier than IPv4, but still present.

You can either a) copy and paste the script (or parts of it) across to a RouterOS terminal, or b) manually recreate things in winbox / webmin.


### 3a. Something New: Interface Lists

For some reason, I've never realised [Interface Lists](https://wiki.mikrotik.com/wiki/Manual:Interface/List) existed, but they're pretty nifty.
They let you create groups of interfaces which can then be used when defining firewall rules.
The hEX came with a `WAN` list (containing `eth1`) and `LAN` list (which had the main LAN bridge, and I've added my phone bridge interface as well).
I also added an `INTERNAL` list (which is `LAN` plus my hosting and guest vLANs).


### 4. Cut Across Services (Slowly)

With all the config in place, it's time to switch some services from the RB2011 too the hEX.

**DNS** was the first.

Mostly because I'm using a pair of [Pi-hole](https://pi-hole.net/) servers for actual DNS queries, so there's not much happening here.
I have ~20 or so static DNS records for internal addresses of important devices, but otherwise the Pi-hole servers go direct to places like [Quad9](https://www.quad9.net/) or [Cloudflare](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/) for upstream DNS.

I changed the *Conditional Forwarder* in the Pi-holes to point to the hEX.
And did a `Resolve-DnsName router.ligos.local -Server 10.46.130.10` to test it worked.

It didn't.

My default firewall rules were to block traffic coming from my hosting network (where my main Pi-hole lives).
So needed to allow TCP & UDP traffic on port 53.


**DHCP** was next.

DHCP is considerably more important to network health than internal only DNS. 
So, after transferring all the config a few days earlier, I checked it all again - all looked OK.
I selected a single network that was non-critical, but still gets enough use to highlight any problems: *phones*.
And disabled the *DHCP Server* on the RB2011 and enabled it on the hEX.

I tested my phone was working OK after I turned WiFi off and on.
And then waited for 24 hours: no complaints, so all was working.

The next night I flipped the switch on my LAN, hosting and guest networks.
Waited for leases to expire and checked they were now coming from the hEX.

Then checked again the day after.

All was going OK!


### 5. Swap IP Addresses

I was getting very close to swapping Internet across to the hEX, but I wanted to swap the device IP addresses first.
The RB2011 had sat on `10.46.1.1` since it was first installed, and the hEX on `.2`.

To make this happen with minimal impact on my wider network, I used a feature of Mikrotik routers: you can assign them multiple IP addresses if you want.
(OK, I really don't consider it a feature, but its a very Mikrotik way of doing things - you pretty much always have the freedom to do whatever is possible, even if it might be pointless or not useful).
I assigned `.12` to the hEX and `.13` to the RB2011.
These would be *temporary* addresses, only used during the swap.

I updated DNS and DHCP to point to the temporary IPs, and waited until devices noticed (one hour, based on DHCP lease time).
(And I checked the Internet still worked afterwards).

Then I swapped the `.1` and `.2` addresses (which were not actually in use at this point).
Another round of updating DNS and DHCP and waiting for leases to renew.
(And checking everything kept on working).

Finally, I removed the temporary addresses (a few days later).

I also kept a static route in `IP -> Route` current during the whole process.
In theory, any packets which land on the wrong router should be forwarded to the right one, such that the Internet remains accessible.
No idea if it helped or not, but it served as a bit of an insurance policy.


### 6. Cut Across Internet

OK, moment of truth!

**Interfaces -> Add PPPoE** for my ADSL connection.

I waited until my wife and kids were asleep, opened an SSH connection and ran `tail -f` on [makemeapassword.ligos.net](https://makemeapassword.ligos.net/) access logs, and had my phone ready to receive notification from [Uptime Robot](https://uptimerobot.com/).

Then I swapped the cable from `eth1` on the RB2011 across to `eth1` on the hEX.
And waited a full minute before ADSL & PPPoE gremlins sorted themselves out and the interface went live.

<img src="/images/Swapping-In-A-New-Router/PPPoE-for-ADSL.png" class="" width=300 height=300 alt="The screenshot is almost 24 hours old, but that time is when the hEX went live!" />

I started madly checking Internet connectivity from my laptop and phone - they looked good!

I needed to force my [cadbane](https://cadbane.ligos.net/) hosting server to renew its DHCP lease, it was still using the temporary IPs as default route for some reason.
But then I started seeing activity on [makemeapassword.ligos.net](https://makemeapassword.ligos.net/). 

I flipped IPv6 router advertisements from the RB2011 to hEX, which propagated to devices within 60 seconds (IPv6 auto-config is wonderful).

Finally, I flipped the default static route (`IP -> Route` / `IPv6 -> Route`) so the RB2011 could still access the Internet (because, you know, it will need firmware updates and that kind of thing).

And it was (99%) working!
I went to bed and sanity checked everything the next morning, making a few tweaks here and there.

I think I had a 5 minute downtime window, maybe a little longer when [makemeapassword.ligos.net](https://makemeapassword.ligos.net/) wasn't accessible.
Which is pretty good!

<img src="/images/Swapping-In-A-New-Router/Interfaces-After.png" class="" width=300 height=300 alt="Interfaces After Cut Over" />


## Conclusion

Swapping routers is tricky, doubly so if you want to minimise downtime.

But by migrating little by little, and making sure things keep working after each change, a very small downtime window is possible!

<img src="/images/Swapping-In-A-New-Router/network-gear-after.jpg" class="" width=300 height=300 alt="Networking Gear After Change-Over (somehow all the cables got messier)" />
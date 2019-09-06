---
title: All You Need to Know About IPv6
date:  2019-09-06
tags:
- IPv6
- Internet
- Mikrotik
- Guide
categories: Technical
---

Making sense of `2001:44b8:3196:3a01:4542:4736:6f02:3454`.

<!-- more --> 

## Background

In Australia, its taken quite a while for [IPv6](https://en.wikipedia.org/wiki/IPv6) to catch on.
Mostly because we have around [2 IP addresses per person](https://en.wikipedia.org/wiki/List_of_countries_by_IPv4_address_allocation) here (in most other parts of the world people have to share IP addresses).

My ISP, [Internode](https://www.internode.on.net/), was the first Australian ISP to deploy IPv6, and I made a point of using it since at least 2013.

Recently, I've noticed other ISPs are getting on board.
When I arranged for [Exetel](https://www.exetel.com.au/) NBN at [church](https://wentyanglican.org.au/), it [supported IPv6 by default](https://forums.whirlpool.net.au/thread/34rwyzk3).
I checked my [dad's business](http://www.grantronics.com.au/) has IPv6 available via Exetel as well.
[A number of other ISPs](https://whirlpool.net.au/wiki/hw_feature_242) support IPv6 to some degree.

So, given that IPv6 is going mainstream down under, it's time to do a basic guide.

## IPv6 Addresses

Here's an IPv4 address: `220.233.65.115`.

And this is an IPv6 address: `2001:44b8:3196:3a01:4542:4736:6f02:3454`.

Let's compare them!

### They're Bigger

The most obvious thing is [IPv6 addresses](https://en.wikipedia.org/wiki/IPv6_address) are bigger.
They are 16 bytes long, instead of 4 (or 128 bits instead of 32).

Because they're so much longer, they're written differently.
IPv4 addresses were written in *dotted quad* notation, which is four decimal numbers separated by periods.
Eg: `192.168.1.2`.

IPv6 use hexdecimal notation, and separate groups of 2 bytes by a colon.
Eg: `2001:44b8:0000:0000:1234:5678:9abcd:ef01`

There's a special rule to make some addresses shorter: any run of zeros can be converted to `::`.
Eg: `2001:44b8::1234:5678:9abcd:ef01` is the same as the address above.

This makes certain addresses much shorter, like the one I statically assign to my router: `2001:44b8:3196:3a01::1`.

### Two Parts

IPv6 addresses come in two parts, the first 8 bytes are the *routing prefix* and the last 8 bytes are the *network identifier*.
IPv4 originally had an idea similar to this, but it got lost in history when we started running out of addresses.

So an example address `2001:44b8:3196:3a01:4542:4736:6f02:3454` has:


| Routing Prefix        | Network Identifier    |
|-----------------------|-----------------------|
| `2001:44b8:3196:3a01` | `4542:4736:6f02:3454` |


The routing prefix is the bit your ISP gives you, while the network identifier is determined by your computer.

This is how IPv6 works.
You will never be assigned a single address by your ISP, you always get a **prefix** or range of addresses.
And your devices chose their own network identifier, usually based on their hardware ethernet address.

The way people write routing prefixes is: `2001:44b8:3196:3a01::/64`.
The `::` has the same meaning as in addresses - all zeros.
The `/64` (read as *"slash sixty-four"*) refers to how many bits are used in the routing prefix - in this case, 64 of them.

The smallest possible IPv6 network is a `/64`, you are not allowed to break up networks any smaller than that.
So that means you have space for thousands of trillions of devices in your home network!
(Or, you can fit the entire IPv4 Internet into your LAN a few million times over)!
That means ISPs cannot assign you anything smaller than a `/64`, which is partly why you are always allocated a prefix.

Most ISPs don't assign a `/64`. 
Usually, you'll get a `/56` (a *"slash fifty six"*).
Which means 56 bits are used, so you can choose the remaining 8 (64 - 56 = 8) to create your own internal sub-networks. 
A `/56` gives you 2^8 or 256 possible sub-networks.

Some ISPs will only allocate a `/60` (4 bits or 16 networks).
If you're a large business, you may be allocated a `/48` (16 bits or ~64 thousand networks).

Why do you want sub-networks?
Perhaps you have a guest WiFi network, and you want to isolate it from your main network.
Perhaps you are hosting your own web server (like me) or mail server, and you want to isolate them.
Maybe you have VoIP phones that you want separate from your devices.
In each of those cases, the isolated network will receive a `/64` (because that's the smallest you can allocate), so you need at least a `/60` to make any of the above work.
While hosting is pretty uncommon for home users, guest networks and VoIP support are built into most home routers, so this isn't something for nerds, enthusiests or big business; it's par for the IPv6 course.


### You'll Always Have More than One

So far, I've only talked about publicly routable IPv6 address.
These all start with the number `2`.
But every network interface will also have a link-local IPv6 address, which starts with `fe80`.
Indeed, even if you don't have a public IPv6 address, you computer almost certainly has a link-local address.

Link-local is the IPv6 equivalent of `192.168.xxx.yyy` or `10.xxx.yyy.zzz` - it's private address space that is only accessible on a local network.
Except, link-local addresses are required to make IPv6 work, so you always have one (even if you have a public address as well).

If you're reading closely, you'll have picked out a privacy problem with IPv6.
Your *network identifier* is based on your computer's hardware, and will stay the same no matter what *prefix* you have, even for link-local addresses.
Here's an example from my hosting server [Cadbane](https://cadbane.ligos.net):

```
$ ip a
2: enp19s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    link/ether f0:4d:a2:7c:16:14 brd ff:ff:ff:ff:ff:ff
    inet6 2001:44b8:3196:3a02:f24d:a2ff:fe7c:1614/64 scope global mngtmpaddr dynamic
       valid_lft 2591777sec preferred_lft 604577sec
    inet6 fe80::f24d:a2ff:fe7c:1614/64 scope link
       valid_lft forever preferred_lft forever
```

The *network identifier* is `f24d:a2ff:fe7c:1614`, and appears for both the public address (starting with `2001`) and link-local address (starting with `fe80`).
Even if Cadbane receives a different *prefix*, the network identifier remains `f24d:a2ff:fe7c:1614`.
Indeed, that identifier is clearly based on the hardware ethernet address `f0:4d:a2:7c:16:14` - there are minor differences, but they're nearly identical.

Facebook, Google and other advertising companies love this: it's an automatic tracking cookie, built into IPv6.

Except, smart people realised this and made [RFC4941](https://www.rfc-editor.org/rfc/rfc4941.txt), which allows computer to do two things:

First, you don't have to use the hardware address of your network interface ([MAC address](https://en.wikipedia.org/wiki/MAC_address)) for your *network identifer*.
As long as whatever you choose won't change, that's OK.
So, you could use a [cryptographic hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function) to derive a *network identifier* from your MAC address, but keep your MAC secret.
Or, you could simply pick a random 64 bit number, save it somewhere, and use that.

That helps, but not much.
Because every connection you make will have still the same *network identifier*.
So you're also allowed to create a *temporary address*.
This is a short lived IPv6 address, which is basically a random number.
Every few hours, your computer generates a new random address for all outgoing connections, and deprecates any previous temporary addresses.
Which eliminates the "tracking cookie" part of IPv6.

Windows does this by default, as does Android.
I believe MacOS does as well.
My Debian Linux servers do not; I'm guessing there is an option to opt-in somewhere.

Here's an example from my laptop, you can see it had addresses 4 in total: 

* The main *IPv6 Address*, which never changes (and I've changed to protect my privacy).
* A *Preferred Temporary IPv6 Address*, which is used for new outbound connections.
* A old *Deprecated Temporary IPv6 Address*, which is kept for existing outbound connections.
* The *Link-local* address.

```
Ethernet adapter Ethernet:

   IPv6 Address. . . . . . . : 2001:44b8:3196:3a01:1234:5678:abcd:dcba(Preferred)
   Temporary IPv6 Address. . : 2001:44b8:3196:3a01:6882:3529:69a4:7209(Deprecated)
   Temporary IPv6 Address. . : 2001:44b8:3196:3a01:707f:fdef:623e:d3e6(Preferred)
   Link-local IPv6 Address . : fe80::1234:5678:abcd:dcba%8(Preferred)
```

### Names are Essential

Because they're longer, IPv6 addresses are harder to type.
That's not exactly earth shattering.
But there are some complications which make them even harder than at first glance.

In the end, it's best to assign names to your IPv6 addressable devices.
Most operating systems will cope with local names (eg: typing `cadbane` into an address bar).
Or, you should use DNS.

If you don't believe how bad it can be, read on!

Lets use my router's address as an example: `2001:44b8:3196:3a01::1`.

How would I type that into my web browser? `http://2001:44b8:3196:3a01::1`, right?

Unfortunately, not.

URLs let you enter a *port*.
By default, that's `80` for `http`, but it's common to run web servers on other ports, eg: `81`, `8080`, and others.
Software developers are always creating web servers on their computer, and each one ends up with a different port.

You port a port in a URL using a colon, like so: `http://127.0.0.1:81`.

But IPv6 has co-opted the colon `:` for other purposes.
So you have to write it with square brackets:

`http://[2001:44b8:3196:3a01::1]:81`

And it gets even worse with link-local addresses.
Because they have a fixed prefix and network identifier, it's possible to have duplicate addresses.
To fix that, link-local addresses sometimes come with a `%` at the end of them, to differentiate by network interface.

My laptop's link-local address is `fe80::1234:5678:abcd:dcba%8`. The `%8` for the eighth network interface in Windows.
Linux based systems tend to use `%eth0`, based on their own naming scheme.

In a URL, that percent symbol has special meaning: it is an [escape character](https://en.wikipedia.org/wiki/Escape_character).
So, to refer to a link-local address, you need to use `%25` instead of just `%` (escaping the escape character):

`http://[fe80::1234:5678:abcd:dcba%258]:81`

It's easier to revert to IPv4, or assign your devices meaningful names.

### Allocating Without DHCP

In IPv4, you generally use [DHCP](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol) to centralise configuration and management of addresses.
Not with IPv6.

IPv6 can work out a global address without any DHCP server.

The *network identifier* is the easy part: it's based on a fixed hardware address.
It's automatic and deterministic, even if it is effectively a random number.
(As an aside, IPv4 DHCP in most settings is usually to assign the IPv4 equivalent of a *network identifier* - the `xxx` in `192.168.1.xxx`).

So how do you get the *prefix*?
IPv6 has a protocol called [SLAAC](https://en.wikipedia.org/wiki/IPv6#Stateless_address_autoconfiguration_&#40;SLAAC&#41;), which is used to auto configure.
Part of which is a thing called [Neighbour Discovery](https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol).
This takes on the role of [ARP](https://en.wikipedia.org/wiki/Address_Resolution_Protocol), mapping IP addresses to ethernet addresses, and detecting duplicate addresses.
It also allows devices to query the network for routers, which can respond with a network prefix.
This is called *Router Advertisements* or *RA*.

So, your router can query your ISP for an IPv6 prefix (via [SLAAC](https://en.wikipedia.org/wiki/IPv6#Stateless_address_autoconfiguration_&#40;SLAAC&#41;), [DHCPv6](https://en.wikipedia.org/wiki/DHCPv6) or [PPPoE](https://en.wikipedia.org/wiki/Point-to-Point_Protocol_over_Ethernet)), and then pass that information onto your devices without any additional configuration!

### How Many Addresses, Really?

An IPv6 address has 128 bits, which means 2^128 addresses (or some huge number with 38 digits).
But, as we've seen, not all those addresses will be in use.
Indeed, IPv6 leaves most of it's address space empty, by design.

So how many addresses are really available?
Are we going to run out like with IPv4?

First off, [IANA](https://www.iana.org), the global body which issues IP addresses, has only allocated one eighth of the global IPv6 address space, or `2000::/3`.
Which is why every public IPv6 address you see starts with `2`.
You can read the [actual address allocations](https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xhtml) if you're interested.

Recall you can work out how many `/64` networks are available by subtracting the prefix from 64.
So `64 - 3 = 61` bits of address space.
Or `2,305,843,009,213,693,952` total networks.
That can contain the entire IPv4 address space many times over.
And it's only one eighth of what IPv6 has to offer!

But it's not that simple.
Because most IPv6 customers will get more than a `/64`.
Depending on residential, small business or multi-national corporation, your ISP may allocate a `/60`, `/56`, or `/48`.
ISPs themselves are being allocated `/32` blocks (and, I suspect, the really big tech corps like Google, Facebook, Amazon, Microsoft, etc).

I live in Australia, so I looked up [APNIC's](https://www.apnic.net) allocations.
They [publish their IPv6 assignments](https://www.apnic.net/manage-ip/manage-resources/address-status/apnic-resource-range/) on their own website, or you can see them on [the IANA publication](https://www.iana.org/assignments/ipv6-unicast-address-assignments/ipv6-unicast-address-assignments.xhtml).
They have several ranges, but the biggest is `2400:0000::/12`.
So lets crunch some numbers based on that.

Their `/12` give them 52 bits of address space.
They can allocate 2^20 `/32`s to ISPs.
That's a little over one million allocations.
Given that most ISPs only have one or two allocations so far, that can support hundreds of thousands of ISPs across the [Pacific, China, India and South East Asia](https://www.apnic.net/about-apnic/organization/apnics-region/).
This covers several of the world's most populus nations and over two billion people!
But it's more than enough.

How many customers can each ISP's `/32` cover (assuming they only have one)?
It depends on the allocation size, so here's some numbers:

* `/48` - for a large company: 2^16 or **~65 thousand**.
* `/56` - for a small company or enthusiest: 2^24 or **~16 million**.
* `/60` - for residential users: 2^28 or **~268 million**.

Given that ISP's need to allocate for households and businesses, not individuals, a single `/32` is enough for ISPs to cover a country - certainly one with the population of Australia.
Even countries like China and India, a single ISP could one or two `/32`s could allocate a `/60` to every household with room to spare.

And, if all this turns [pair shaped](https://www.urbandictionary.com/define.php?term=pear%20shaped), IANA can change how things work for `4000::/3` (which is the same size as above).

And again for `6000::/3`.
And `8000::/3`, `a000::/3`, and `c000::/3`.
Each the same size as our current `2000::/3`.

So, no.
We aren't about to run out of IPv6 addresses any time soon.

### Summary

That's lots of information and plenty of *"show working"* as well.
So here's a summary about IPv6 addresses:

* They are 128 bits / 16 bytes.
* They are written as hex in blocks of 4 characters, eg: `2001:44b8:3196:3a01:4542:4736:6f02:3454`.
* If there are blocks of zeros, they can be shortened like so: `2001:44b8:3196:3a01::1`.
* They have two parts: the *prefix* and *network identifier*. Both are 64 bites / 8 bytes.
* The *prefix* is allocated to you by your ISP. Your router will use a *router advertisement* to let your devices know.
* The *network identifier* is determined by your hardware, or some other fixed value.
* Your ISP should never allocate a single address or even single network, but always a prefix like (`/60`, `/56` or even `/48`).
* Link-local addresses are in the range `fe80::/10`, and are only valid for your LAN.
* Public addresses are in the range `2000::/3`, and are... well... public!
* You will have many addresses: link-local, public and temporary.
* Although the IPv6 address space is mostly empty (by design), there's heaps of *prefixes* to go around!


## IPv6 on Mikrotik

Mikrotik's support for IPv6 is usable, but [not brilliant](https://forum.mikrotik.com/viewtopic.php?f=2&t=151279).
This is a bigger problem if you're deploying Mikrotik in the data center, but for home use its just fine (and better than the normal garbage found in residential routers).

With that out of the way, let's look at what you need to get going.

First off, visit *System -> Packages* and enable *IPv6*.
It should be installed, but disabled, by default.
You'll need to reboot your router.

After then, there is an *IPv6* section available in Winbox, Webfig and Console.

### Pool

The first place to visit is **IPv6 -> Pool**.
Here you define *network prefixes*, similar to IPv4 -> Pool.

Generally, you'll define one `/64` pool for each VLAN or network you are running.
I've got ones for my main LAN, hosting DMZ, phones and a guest network.

You should statically define your pools in advance.
That is, create each pool **before** you get an assignment from DHCPv6 / SLAAC / PPPoE.
Because, when you do get your ISP prefix, it will occupy a `/56`, and Mikrotik won't let you create overlapping pools.
(I end up deleting the *dynamic* pool whenever I need to make changes to other pools).

This assumes your ISP assigns a static IPv6 prefix (all Australian ISPs I've worked with are doing this - you may need to visit a management portal to find your prefix).

<img src="/images/All-You-Need-to-Know-About-IPv6/Mikrotik-IPv6-Pool.png" class="" width=300 height=300 alt="IPv6 Pool" />

```
[admin@MikroTik-bdr01] /ipv6 pool> print detail
name="ipv6-pool-lan-nbn" 
   prefix=2001:44b8:3196:3a01::/64
   prefix-length=64 
name="ipv6-pool-hosting-nbn" 
   prefix=2001:44b8:3196:3a02::/64 
   prefix-length=64 
name="ipv6-pool-phones-nbn" 
   prefix=2001:44b8:3196:3a03::/64 
   prefix-length=64 
name="ipv6-pool-guest-nbn" 
   prefix=2001:44b8:3196:3a10::/64 
   prefix-length=64 

name="ipv6-pool-nbn-public" 
   prefix=2001:44b8:3196:3a00::/56 
   prefix-length=64 
   expires-after=1h35m27s 
```

You can see my various pools above (all `/64`s), plus the ISP assigned one (`/56`).


### Address

After you've made a pool, you can create an **IPv6 -> Address** and assign it to a network interface.

The only option you need to worry about is ticking *Advertise*.
That will enable *router advertisements* and let your devices configure themselves via SLAAC.

All network interfaces will be automatically assigned a link-local address.

<img src="/images/All-You-Need-to-Know-About-IPv6/Mikrotik-IPv6-Address.png" class="" width=300 height=300 alt="IPv6 Addresses" />

```
[admin@MikroTik-bdr01] /ipv6 address> print detail
address=2001:44b8:3196:3a01::1/64 
   from-pool=ipv6-pool-lan-nbn 
   interface=bridge-main-lan 
   eui-64=no 
   advertise=yes 
   no-dad=no 

 address=2001:44b8:3196:3a02::1/64
   from-pool=ipv6-pool-hosting-nbn
   interface=bridge-hosting 
   eui-64=no
   advertise=yes
   no-dad=no 

 address=2001:44b8:3196:3a03::1/64
   from-pool=ipv6-pool-phones-nbn
   interface=bridge-phones 
   eui-64=no
   advertise=yes 
   no-dad=no 

address=2001:44b8:3196:3a10::1/64
   from-pool=ipv6-pool-guest-nbn
   interface=bridge-guest
   eui-64=no
   advertise=yes 
   no-dad=no 


address=fe80::ba69:f4ff:fe86:8d67/64 
   from-pool="" 
   interface=bridge-main-lan
   eui-64=no 
   advertise=no 
   no-dad=no 

address=fe80::ba69:f4ff:fe86:8d67/64 
   from-pool="" 
   interface=bridge-guest
   eui-64=no 
   advertise=no 
   no-dad=no 

...
```

After this, your devices should have a public IPv6 address based on the prefix assigned to your network!


### DHCP Client

However, its unlikely they'll be able to access the IPv6 Internet just yet.
You'll need to get an assignment from your ISP.
With the Australian ISP's I've worked with, that involves **IPv6 -> DHCP Client**.
(You might be able to configure a default route to accomplish the same thing, but it depends on your ISP).

<img src="/images/All-You-Need-to-Know-About-IPv6/Mikrotik-IPv6-DHCP-Client.png" class="" width=300 height=300 alt="DHCP Client" />

```
[admin@MikroTik-bdr01] /ipv6 dhcp-client> print detail
interface=pppoe-internode-nbn 
   status=bound 
   request=prefix 
   add-default-route=yes 
   default-route-distance=1 
   use-peer-dns=no 
   rapid-commit=no 
   pool-name="ipv6-pool-nbn-public" 
   pool-prefix-length=64 
   dhcp-options="" 
   prefix=2001:44b8:3196:3a00::/56, 1h37m9s 
```

A few options here:

* `use-peer-dns`: I have this disabled because I'm using a [Pi-Hole](https://pi-hole.net/) for DNS. Enable to automatically use your ISP's DNS servers.
* `rapid-commit`: [Mikrotik had some bugs](https://forum.mikrotik.com/viewtopic.php?p=701294) around this recently, so its best to disable. It's benefit is very marginal anyway.
* `request`: You should always request a *prefix*. Some ISPs also require an *address*. I don't know what *info* does.
* `pool-name`: This is the name which will be dynamically added under *IPv6 -> Pool*.

### Firewall

Finally, IPv6 has its own firewall.
Generally, I leave this pretty open, and rely on devices' own IPv6 firewall.

There are some important things you need to allow, or your IPv6 connectivity will be broken: ICMPv6, UDP traceroute and DHCPv6 prefix delegation.
Otherwise, this is the same as IPv4 firewall, just simpler.

<img src="/images/All-You-Need-to-Know-About-IPv6/Mikrotik-IPv6-Firewall.png" class="" width=300 height=300 alt="IPv6 Firewall" />

```
[admin@MikroTik-bdr01] /ipv6 firewall filter> print detail
;;; Allow ICMP
chain=input action=accept protocol=icmpv6
chain=output action=accept protocol=icmpv6
chain=forward action=accept protocol=icmpv6

;;; UDP Traceroute
chain=input action=accept protocol=udp port=33434-33534
;;; accept DHCPv6-Client prefix delegation
chain=input action=accept protocol=udp 
   src-address=fe80::/16 dst-port=546 

;;; Drop incoming VNC
chain=forward action=drop protocol=tcp 
   in-interface-list=WAN dst-port=5900

;;; Drop incoming SMB / CIFS
chain=forward action=drop protocol=tcp 
   in-interface-list=WAN dst-port=445,137,138,139

;;; Block access by default
chain=input action=drop in-interface-list=WAN 
```

## Conclusion

IPv6 is new and different.
But not that different.

In many ways, it's simpler to configure and make sense of than IPv4.
The smart people in charge of the Internet have learned from IPv4 and made IPv6 better!

Hopefully, after reading this post, you've got enough understanding of IPv6 to be comfortable using it in your home or small business.

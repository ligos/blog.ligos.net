---
title: PPPoE Server on Mikrotik
date: 2019-11-04
tags:
- Internet
- Mikrotik
- Guide
- PPPoE
- ISP
categories: Technical
---

How to be an ISP!

<!-- more --> 

## Background

The [NBN](https://www.nbnco.com.au/) arrived at my address recently!

Well, it half did.
My unit has the [NBN available](/2019-07-05/Internode-HFC-NBN-With-Mikrotik.html) since July 2019.
But the other 5 units in our complex had to wait until October.
Such are the whims of large, government run projects with significant political interferance (not that I'm knocking it, I'm greatful for any improvement on 4Mbps ADSL).

Apparently, the physical cable for my unit runs from the telecommunications pit on the street, while all other units are run from a separate pit within the unit complex.
And "something" made it difficult to do the run from the street to our common property.
(I never got a straight story about what "something" actually was).

Anyway, I jumped on the bandwagon 30 seconds after I found the connection was available (because 4Mbps ADSL sucks).
My neighbour (suffering even slower ADSL speeds), rang me the next day to complain that NBN was at my unit but not his!

So, I offered to share my connection.

## Goal

Allow Internet connections to up to five additional units in my complex via WiFi or [PPPoE](https://en.wikipedia.org/wiki/Point-to-Point_Protocol_over_Ethernet), so that they can use their existing residential routers.

Sub goal: No puchases of additional equipment - my [hEX S](https://mikrotik.com/product/hex_s) and [RB2011](https://mikrotik.com/product/RB2011UiAS-2HnD-IN) Mikrotik devices, plus any old equipment lying around are all I can use.

## Last Mile... err... Meter Connection

It's ~60m from the street to the furthest unit in our complex.
All are single storey.
Four share common walls, and the two others are physically separate (with a driveway running between them, but sharing one common wall).

My plan was:

* Use a [guest WiFi network](/2016-10-04/Create_Another_Network_On_A_Mikrotik.html) for the closest unit, as coverage is pretty good through one wall.
* Run an ethernet cable through the ceiling cavity for other units.
* If more than one neighbour is interested, I'll need an old switch to split my one available ethernet port / cable.

As it turns out, the two neighbours who signed up were well beyond my WiFi range, so I never used that option.
Instead we ran ethernet (in cheap conduit) from my unit, out through my roof, via the rain gutter to the closest neighbour.
He had an old 100Mbps switch which he used to split from my router to his own, and another cable run to the furthest unit, while keeping clear of the driveway.

<img src="/images/PPPoE-Server-On-Mikrotik/Cable-Run-Roof.jpg" class="" width=300 height=300 alt="The Cable Runs Out of My Roof Tiles - its Really Caustrophobic in the Ceiling Cavity Near the Edges" />

<img src="/images/PPPoE-Server-On-Mikrotik/Cable-Run-Tech.jpg" class="" width=300 height=300 alt="Skilled ISP Technicians (aka My Neighbours) Doing the Cable Run. That's 100m of Cat6 Ethernet Cable on the Left." />

## PPPoE

Most ISPs I've worked with in Australia require your router to connect via PPPoE.
This allows them to share or abstract telecommunications infrustructure, and present the same logical way of connecting.
It's more and more common for all Internet connections to come via a physical ethernet connection from a modem of some kind, but the login to your ISP requires a PPPoE login.

## PPPoE Server

First step was to configure my HeX router to allow my neighbours to connect with PPPoE.

Goto *PPP > Profile*, and create a new Profile.
As with a [L2TP VPN](/2019-10-27/L2TP-VPN-on-Mikrotik.html), this profile will let us share configuration between all logins.
I've configured DNS to use the router and [Quad9](https://www.quad9.net/), disabled compression and [UPnP](https://en.wikipedia.org/wiki/Universal_Plug_and_Play).

<img src="/images/PPPoE-Server-On-Mikrotik/Mikrotik-PPP-Profile.png" class="" width=300 height=300 alt="PPP Profile" />

```
/ppp profile
add dns-server=192.168.131.1,9.9.9.9 name=pppoe-local \
    use-compression=no use-upnp=no
```

Next, *PPP > Secret*, and add logins for each user.
I created a login for myself and plus all other units.
Then assigned static IP addresses and IPv6 prefixes from a new, isolated subnet.
And selected the profile I just created.

<img src="/images/PPPoE-Server-On-Mikrotik/Mikrotik-PPP-Secret.png" class="" width=300 height=300 alt="PPP Secret / Login" />

```
/ppp secret
add local-address=192.168.131.1 name=unit1 password=Unit1Password 
    profile=pppoe-local remote-address=192.168.131.11 
    remote-ipv6-prefix=2001:44b8:3196:3a10::/60
add local-address=192.168.131.1 name=unit2 password=Unit2Password 
    profile=pppoe-local remote-address=192.168.131.12 
    remote-ipv6-prefix=2001:44b8:3196:3a20::/60
add local-address=192.168.131.1 name=unit3 password=Unit3Password 
    profile=pppoe-local remote-address=192.168.131.13 
    remote-ipv6-prefix=2001:44b8:3196:3a30::/60
add local-address=192.168.131.1 name=unit4 password=Unit4Password 
    profile=pppoe-local remote-address=192.168.131.14 
    remote-ipv6-prefix=2001:44b8:3196:3a40::/60
add local-address=192.168.131.1 name=unit5 password=Unit5Password 
    profile=pppoe-local remote-address=192.168.131.15 
    remote-ipv6-prefix=2001:44b8:3196:3a50::/60
add local-address=192.168.131.1 name=unit6 password=Unit6Password 
    profile=pppoe-local remote-address=192.168.131.16 
    remote-ipv6-prefix=2001:44b8:3196:3a60::/60
```

Finally, goto *PPPoE > PPPoE Servers*, and create a new *PPPoE Service*.
Select the profile created above, and bind it to the interface which will be connected to your customers... err... neighbours.

I only had one spare port, so I bound directly to the ethernet port.
If you're planning to do multiple cable runs to several ports on your router, you'll need to create a [bridge](https://wiki.mikrotik.com/wiki/Manual:Interface/Bridge) and bind the PPPoE server to the bridge.

<img src="/images/PPPoE-Server-On-Mikrotik/Mikrotik-PPP-PPPoE-Server.png" class="" width=300 height=300 alt="PPP Server" />

```
/interface pppoe-server server
add default-profile=pppoe-local disabled=no interface=ether5-otherUnits \
    service-name=pppoe-server
```

Finally, add a *PPPoE Server Binding* interface for each user.
This was an optional step with a VPN, but a named interface is a must when each user will need a queue and firewall rules.

<img src="/images/PPPoE-Server-On-Mikrotik/Mikrotik-Interface-PPPoE-Server-Binding.png" class="" width=300 height=300 alt="PPPoE Server Interfaces for each user" />

```
/interface pppoe-server
add name=pppoe-unit1 service=pppoe-server user=unit1
add name=pppoe-unit2 service=pppoe-server user=unit2
add name=pppoe-unit3 service=pppoe-server user=unit3
add name=pppoe-unit4 service=pppoe-server user=unit4
add name=pppoe-unit5 service=pppoe-server user=unit5
add name=pppoe-unit6 service=pppoe-server user=unit6
```

That's it!
All the PPPoE stuff is done!

Mikrotik reference for [PPPoE](https://wiki.mikrotik.com/wiki/Manual:Interface/PPPoE).

## Isolated Network

At this point, you need an [isolated network](/2016-07-28/How-To-Make-An-Isolated-Network.html) on your router.
[This should give you details](/2016-10-04/Create_Another_Network_On_A_Mikrotik.html), but the summary is:

* New IP Address
* Firewall rules (make sure you drop any traffic going to your LAN)
* Queues (so that no one customer can use all the bandwidth)

Unlike most new networks, this does not require a DHCP server, because I've chosen to statically allocate IP addresses for each user.
Even if you were serving 100 units, I'd still stick with a static allocations for each one - it makes troubleshooting and management easier, and it's not like the units come and go like real customers do.

For queue configuration, I found that 44/16Mbps works well. 
I've got three households sharing a 100/40Mbps connection (which is closer to 85/35Mbps in real life) and allocating around half the available bandwidth each seems to work.
And yes, that limit applies to me as well my neighbours!
Just remember to use an `sfq` [queue](https://wiki.mikrotik.com/wiki/Manual:Queue); the out-of-the-box `fifo` queues can cause latency issues due to [buffer bloat](https://en.wikipedia.org/wiki/Bufferbloat).

<img src="/images/PPPoE-Server-On-Mikrotik/Mikrotik-Queue.png" class="" width=300 height=300 alt="Queue to Share the Bandwidth" />

```
/queue type
add kind=sfq name=sfq-normal
/queue simple
add dst=pppoe-internode-nbn max-limit=16M/44M name=q-unit1-pppoe queue=\
    sfq-normal/sfq-normal target=pppoe-unit1
...
add dst=pppoe-internode-nbn max-limit=16M/44M name=q-unit6-pppoe queue=\
    sfq-normal/sfq-normal target=pppoe-unit6
```

## Client Configuration

The router is all configured.
All that remains is to configure my neighbour's routers.

The assumption is, your neighbour already has a residential router with an ethernet port for WAN access.

If, like me, you consider most residential routers total crap and avoid them like plague, may I recommend Mikrotik's [hAP ac²](https://mikrotik.com/product/hap_ac2) device.
It has 2.4 and 5Ghz WiFi, 5 ethernet ports, 4 cores, runs RouterOS and [costs AU$110](https://shop.duxtel.com.au/product_info.php?products_id=503).
That is, it's a pretty good device for home users to get started with Mikrotik, and has similar headline specs to ["high end" residential routers](https://netgear.com.au/home/products/networking/wifi-routers/R7000P.aspx), which cost twice as much.

But it turns out PPPoE isn't as standard as I thought (or some providers lock their devices to their own networks).
Both neighbours ran into trouble with routers.
In one case, the router had a terrible web interface and simply didn't offer the right options.
Another router said it supported username & password logins and PPPoE, but it would never connect.
Both routers had an ethernet WAN port, and one was even "NBN certified" and was in use with an old ISP.

In the end, I got them both going using newer routers.

All routers are different, but here are two way to try and make them work:

### Play Dumb

Go through whatever configuration wizard the router offers.
Say that you need a login, enter the username and password from *PPP Secrets* (eg: `unit1` / `Unit1Password`).
Click next / save / OK, and hope for the best.

If it doesn't work, try the next option:

### Advanced Settings

I prefer to know what's actually going on, but that's just me.
Find the router's "advanced settings" or "expert mode", and you should find something like this:

Setting | Value | Example
--------|-------|---------
Connection Type | PPPoE | 
Username | Designated Username | `unit1`
Password | Designated Password | `Unit1Password`
Address | DHCP | Might also be labelled *automatic*
DNS | Automatic | Or *ISP assigned*

Higher end routers may have several options for your WAN connection (eg: ethernet or cable, ADSL, 4G / LTE).
You'll want to choose *ethernet* or however it's labelled.

If you're able to configure a Mikrotik device, entered a few basic settings is straight forward.
Assuming the router supports such settings and labels them intelligently (and that's a big assumption).

If all else fails, you could see if the manufacturer provides any documentation or a forum where you can ask a question.

### Connected!

Once configured, residential routers should Just Work™, and think that the "Internet" comes from the upstream Mikrotik device.
You should see the assigned IP address in the *status* page.

<img src="/images/PPPoE-Server-On-Mikrotik/Mikrotik-Interface-PPPoE-Status.png" class="" width=300 height=300 alt="Connection Status - Almost 4 Days Up" />

And the graphs / aggregate traffic statistics.

<img src="/images/PPPoE-Server-On-Mikrotik/Mikrotik-Interface-PPPoE-Traffic.png" class="" width=300 height=300 alt="Connection Traffic - 23GB down, 0.7GB up" />

## Billing

If my ISP ever comes and reads this, I want to be very clear than I'm **cost sharing**.
That is, I'm not attempting to setup a rival ISP to cheat them out of a few extra customers.
I'm just trying to help out poor neighbours who were on 4Mbps ADSL.

I've subscribed to the highest cost plan for [Internode](https://www.internode.on.net/), and added a "power pack" (to gain a static IP address).
Partly so I can be sure there's enough bandwidth to go around, and partly to tell my ISP "I'm not cheating you".

I just split the cost equally between each neighbour and myself.
They have my bank details, and deposit the amount each month.

## Conclusion

As at writing, I am serving Internet to two other units in our complex.
Including my own unit, that's three of six sharing a single 100/40Mbps connection.
With no adverse effects or obvious slow downs, even during the evening peak when half the city is watching Netflix.

With some long ethernet cables, a Mikrotik router running as a PPPoE server makes it quite easy to pretend I am an ISP.
And the [hEX S](https://mikrotik.com/product/hex_s) device has more than enough CPU to push 100Mbps to ~30 devices.

The only down side is that I'm now "ISP Murray" in my neighbours' address book, aka *tech support*.
Fortunately, Mikrotik is reliable enough that I haven't had to field any 2am support calls.
Yet.


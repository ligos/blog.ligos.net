---
title: How to Make an Isolated Network
date: 2016-07-28
tags:
- Mikrotik
- Network
- Isolated
- vLAN
- Switch
- Hyper-V
- Malware
- Nmap
categories: Technical
---

A network which can access the Internet, but not other machines on the LAN.
Not even ethernet frames.

<!-- more --> 

## Background

I was asked to give a short presentation at my church on [how to remove a virus from your PC](/2016-06-16/How-To-Remove-Malware-From-Your-PC.html).
And I thought the best way to do that is to install some malware and actually remove it.

Now I try to maintain good habits with computer security.
I use a password manager for all passwords (much to my wife's dislike).
I maintain a website dedicated to [generating easy to remember yet difficult to guess passwords](https://makemeapassword.org/). 
I run as a standard user on all computers; no admin without another password.
I have two-factor authentication active where ever I can (even on my 6 year old's Google account).

And I am painfully aware how [destructive](https://en.wikipedia.org/wiki/CryptoLocker) malware can be.

So deliberately installing malware on my network was not going to be taken lightly. 

## Goal

I already have a guest WiFi network, which is isolated from my main LAN.
But I figured I should learn something in this process, and decided to isolate a wired network.

* A single ethernet port is designated **isolated**
* It can access anything on the Internet
* It cannot access anything on my LAN (in particular, SMB / CIFS file shares)
* Ideally, it should not be aware of my LAN at all (no broadcast packets, no tricky ethernet level tricks)
* To simplify things, a public IPv6 address will not be offered 

## Technology Used

We'll be using the following (in order of importance):

* A [Mikrotik router](http://routerboard.com/RB2011UiAS-2HnD-IN)
* Hyper-V
* An additional network card 

## Layers - Network Theory

To isolate one network from another, we need to separate them at two levels:

1. The network layer (3 and 4 in the [OSI model](https://en.wikipedia.org/wiki/OSI_model), or [TCP/IP](https://en.wikipedia.org/wiki/Internet_protocol_suite) in the real world). This would mean separate netmasks and address ranges.
2. The data link layer (2 in the [OSI model](https://en.wikipedia.org/wiki/OSI_model), or [Ethernet](https://en.wikipedia.org/wiki/Ethernet) in the real world). This means separate vLANs or network switches.

### Restricting at Layer 3/4 (TCP/IP)

Restricting communications at the TCP/IP level is done via creating a new network and firewall rules.

Creating a new network is streight forward, but multi-step:

1. Add a new IP address to the *isolated* port (*IP -> Addresses*)
2. Add a new IP address pool for DHCP (*IP -> Address Pool*)
3. Add a new DCHP server listening on the *isolated* port for the address pool

(I'll write up a separate post for those details.)

Then we need to add appropriate firewall rules.
Mikrotik routers allow all traffic by default.
So I add a **drop everything** rule at the end of my routing table, and then allow traffic as required.

Conceptually, this looks like:

* Some accounting rules tracking bytes in and out (so I can see that traffic is flowing)
* Allow packets to / from the router (for DNS, DHCP, etc)
* Allow packets to / from the Internet via NAT
* Drop anything for my LAN 

And the actual implementation (note references to `ether10-isolated`):

```
[admin@Mikrotik-gateway] /ip firewall filter> print

 5    ;;; Incoming Stats    
      chain=forward action=passthrough in-interface=pppoe-internode out-interface=ether10-isolated log=no log-prefix="" 
 
 8    ;;; Outgoing Stats
      chain=forward action=passthrough in-interface=ether10-isolated out-interface=pppoe-internode log=no log-prefix="" 

26    ;;; Allow DNS access for all internal    
      chain=input action=accept protocol=udp src-address-list=isolated dst-port=53 log=no log-prefix="" 

36    ;;; Accept to established connections
      chain=input action=accept connection-state=established log=no log-prefix="" 

37    ;;; Accept to related connections
      chain=input action=accept connection-state=related log=no log-prefix="" 

41    ;;; Drop access to LAN from isolated network
      chain=forward action=drop dst-address-list=all_internal in-interface=ether10-isolated log=no log-prefix="" 

43    ;;; Drop access to Router from isolated network
      chain=input action=drop in-interface=ether10-isolated log=no log-prefix=""  

[admin@Mikrotik-gateway] /ip firewall nat> print

11    ;;; Main NAT rule
      chain=srcnat action=masquerade src-address-list=all_internal out-interface=pppoe-internode log=no log-prefix="" 

12    chain=srcnat action=masquerade src-address-list=isolated out-interface=pppoe-internode log=no log-prefix="" 

[admin@Mikrotik-gateway] /ip firewall nat> 

```
### Restricting at Layer 2 (ethernet)

Restricting at the ethernet layer is more difficult, and something I'd never tried in the past.

I tried creating vLANs and managed to isolate every device on my LAN from every other device!
And then hit `CTRL+Z`.

Mikrotik routers, however, have a programmable network switch.
The [documentation](http://wiki.mikrotik.com/wiki/Manual:Switch_Chip_Features) seemed to say that you can create [switch groups](http://wiki.mikrotik.com/wiki/Manual:Switch_Chip_Features), 
where certain ports function as if they were part of a network switch (layer 2), and others as routed ports (layer 3/4).
If I could take a single port out of a switch group, that should physically isolate it. 

By default, my [router](http://routerboard.com/RB2011UiAS-2HnD-IN) had the five 100Mb ports configured as one switch group, and the gigabit ports as no switch group.
(Apparently, the gigabit ports are [bridged](http://wiki.mikrotik.com/wiki/Manual:Interface/Bridge) and use [fast path routing](http://wiki.mikrotik.com/wiki/Manual:Fast_Path) to achieve near wire speed performance.
This means they act like a switch, but you can use firewall rules against individual ports.
Although I'm still not 100% certain exactly what that means: [more information about bridge vs switch](http://forum.mikrotik.com/viewtopic.php?t=67492)).

I took one 100Mb ethernet port (number 10) out of the switch group, and named it *isolated*.  
Which was all I needed to do (after several hours of reading and incorrect attempts).

<img src="/images/How-To-Make-An-Isolated-Network/interface-details.png" class="" width=300 height=300 alt="Master port = none, taking it out of the switch group" />

### Connecting Devices

There were two devices I connected:

1. A physical PC acquired from work
2. A VM, hosted on my *do everything* server using [Hyper-V](https://en.wikipedia.org/wiki/Hyper-V)

The physical PC was easy enough: simply plug the cable in.

The VM required a little extra work.
Hyper-V networking is either internal to Hyper-V or part of a LAN.
There isn't any other option (although this appears to be changing, see below for more details).

So I connected a cheap USB network adapter and created a new External Network Switch, which was bound to the new NIC and named *isolated*.
The switch was configured not to share with the host OS; that is, Hyper-V takes exclusive use of the NIC and the host does not access it at all.

<img src="/images/How-To-Make-An-Isolated-Network/hyper-v-isolated-switch.png" class="" width=300 height=300 alt="Exclusive use of a $30 USB NIC" />

Then you assign the VM to use the *isolated* switch and plug the cable into the NIC.

Finally, running two devices from one ethernet port means you need an additional switch.
I had an old 100Mb 4 port router which worked for this.
Simply plug-in the isolated port from the Mikrotik, the physical PC and the USB NIC. 

### Testing

When a device connects to the isolated network, it sees a nice network in the `10.0.0.x` space.
It's default gateway, DNS and DHCP server is `10.0.0.1`.
So, any malware shouldn't be suspicious of my LAN over on `192.168.0.x`.

However, I wanted to be sure.
So I loaded [nmap](https://nmap.org/) on the isolated device, and told it to scan `192.168.0.0/24` from it's `10.0.0.x` network. 

Devices on my local network (determined via nmap scan from the 192.168.0.0/24 LAN):
```
192.168.0.1
192.168.0.2
192.168.0.3
192.168.0.4
192.168.0.5
192.168.0.20
192.168.0.21
192.168.0.30
192.168.0.31
192.168.0.40
192.168.0.190
192.168.0.197
```

Devices on my local network (as visible from the isolated network 10.0.0.0/24):
```
192.168.0.1
```

Only 192.168.0.1 (the router) was up and running.

That was enough for me to be satisfied the networks were isolated. 

(As an aside: I run this nmap test before the layer 2 isolation was in place, that is, before I'd taken the port out of the switch group.
I could not connect to any device on my LAN and nmap reported all open ports as filtered, but it was **aware of every live device on my LAN**.
Although I'm reasonably sure that is isolated enough, I really wanted to be sure)!
 
### Alternatives

#### vLANs

My first thought at isolating a network would be to set up a [vLAN](https://en.wikipedia.org/wiki/Virtual_LAN).
After all, that's what the networking guys do at my work.

I had never done any work with vLANs, so I wasn't very confident about this approach.
And managed to isolate every device from every other device while trying it out.
But I suspect someone who knew what they were doing could make it work.

#### Hyper-V NAT

I mentioned above that Hyper-V only has internal and external network switches.
Well, it appears they are implementing [NAT switches](https://msdn.microsoft.com/en-us/virtualization/hyperv_on_windows/user_guide/setup_nat_network) as well.

That should allow a VM to be isolated at layer 2 (via a Hyper-V switch) and 3/4 (via NAT).
And would have saved me $30 on the USB NIC. 

However, this feature was not available when I created my network.

## Conclusion

By taking a network port out of the normal network switch, and implementing the correct firewall rules, you can isolate a single port on a Mikrotik device.

This creates a highly isolated network which can access the Internet but not see any other device on your LAN.  
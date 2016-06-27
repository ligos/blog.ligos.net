---
title: Access Resources from Guest Networks
date: 2016-06-27 21:00:00
tags:
- Mikrotik
- Network
- Isolated
- Guest
- Firewall
- SMB
- Printer
categories: Technical
---

Allow access to network resource (like file shares) from guest networks.

<!-- more --> 

## Background

I have several networks, all routed via my Mikrotik router.
My main LAN.
A kids wifi network.
A guest wifi network.

They can all access the Internet, but access between networks is restricted by default.
So, if the kids managed to get [something nasty](https://en.wikipedia.org/wiki/CryptoLocker) on their computer, there's at least some chance of isolating it. 

But sometimes I really do want the kids to access our digital DVD collection.
Or print to our network printer. 

## Goal

Allow an otherwise isolated network access to specific resources on another network. 

Only the resources required should be accessible; we want to be as granular as possible.

## Firewall Rules

This boils down to adding a few firewall rules on the Mikrotik router and the computer sharing the resource. 

### SMB / CIFS / Windows File Sharing

The scenario here is to allow the kids access to digital content.
Photos, videos, DVDs, recorded TV, etc.

To do that from a Windows computer, we need to allow port `445` between the networks.
And ensure the server is listed as a **static DNS record** (because Windows File Sharing uses different ports for name resolution).

```
[admin@Mikrotik-gateway] /ip firewall filter> print

27    ;;; Allow SMB / CIFS access to Fileserver from kids static addresses
      chain=forward action=accept protocol=tcp src-address-list=internal_kids_fixed 
      dst-address-list=named_fileserver dst-port=445 log=no log-prefix="" 

[admin@Mikrotik-gateway] /ip firewall filter> 

[admin@Mikrotik-gateway] /ip dns static> print
 #     NAME                   ADDRESS                                                  TTL         
 0     router.ligos.local     192.168.0.1                                              1d          
 2     printer.ligos.local    192.168.0.3                                              1d          
[admin@Mikrotik-gateway] /ip dns static> 
```

Then, don't forget to update the firewall on the *Windows computer* as well.
By default, Windows' definition of a *private network* is things on the same subnet, but the kid's network is on a different subnet.
So add the kid's subnet to the `File and Printer Sharing (SMB-In)` rule, in the *Inbound Rules* section of Window Firewall.

<img src="/images/Access-Resources-From-Guest-Networks/windows-firewall.png" class="" width=300 height=300 alt="Allow the Kid's Network in Windows Firewall " />

A small aside: I'm making a point of adding all my networks, servers and devices to an address list under *Firewall*.
So rather than referring to a destination IP of `192.168.0.8`, I'll use a destination address list of `named_fileserver`.
Which makes it easier to understand what each device is and what rules are doing what.  

**Important Note:** Windows file shares is the very thing Crypto Locker looks for.
That is, it seeks out writable network shares and tries to encrypt files on them. 
My mitigation is to only give the kids *read-only* access to content, which will at least limit the damage they can cause. 

Oh, and backups.
The only sure defense against Crypto Locker is a backup.

### A Network Printer

The kids also need to print stuff.
And we have a network printer, which isn't shared via Windows File Sharing.

So another firewall rule to allow access:

```
[admin@Mikrotik-gateway] /ip firewall filter> print

28    ;;; Allow printer access from kids network
      chain=forward action=accept dst-address-list=named_printer in-interface=wlan-kids log=no 
      log-prefix="" 

[admin@Mikrotik-gateway] /ip firewall filter> 
```

I'm not sure what ports network printing needs, so I allow all ports.
And again, make sure there is a static DNS entry for your printer. 

Then, you simply add a printer in Windows.
And point it at the printer's DNS name.
(And probably download and install some very mediocre printer drivers; sigh.)

<img src="/images/Access-Resources-From-Guest-Networks/windows-printer.png" class="" width=300 height=300 alt="Add by TCP Address or hostname" />

<img src="/images/Access-Resources-From-Guest-Networks/windows-printer2.png" class="" width=300 height=300 alt="And enter your printer's address" />

Unsurprisingly, the network printer will gladly access network connections from anywhere.
So no firewall changes required on the device.
(In fact, I doubt many consumer network printers even have a firewall).

## Conclusion

Isolating networks and devices is a good idea from a security point of view (and quite easy on a Mikrotik router).
But networks do need to share data and access resources.

With a few simple firewall rules, you can selectively grant access as required.

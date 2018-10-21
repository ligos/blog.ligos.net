---
title: Mikrotik and LTE via Telstra / Huawei E8372
date: 2018-10-21
updated: 
tags:
- Mikrotik
- Router
- Home Router
- Gateway
- LTE
- 4G
- Mobile Internet
- Telstra
- Huawei
- Cellphone
- Mobile Phone
categories: Technical
---

Use the Telstra 4GX USB dongle (aka Huawei E8372) for 4G / LTE Internet on a Mikrotik router.

<!-- more --> 

## Background

Each year, we go on a family holiday.
The place we stay has no Internet (shocking, I know).

As in [previous years](/2017-08-16/Mikrotik-And-LTE-via-Android.html), I brought along a Mikrotik router with an LTE device - this time a USB dongle: the [Telstra Pre-Paid 4GX USB WiFi Plus](https://www.telstra.com.au/mobile-phones/prepaid-mobiles/telstra-pre-paid-4g-usb-wi-fi-plus).

Generally, the USB dongle is basically the same as connecting an Android device.
So I'm going to focus on:

* How it's different from [LTE via Android](/2017-08-16/Mikrotik-And-LTE-via-Android.html) or [other USB dongles](/2018-03-01/Mikrotik-And-LTE-via-USB-and-Failover.html).
* The Telstra dongle (a re-branded [Huawei E8372h](https://consumer.huawei.com/en/mobile-broadband/e8372/)).

<img src="/images/Mikrotik-And-LTE-Via-Telstra-Huawei-E8372/dongle-in-place.jpg" class="" width=300 height=300 alt="Telstra / Huawei In Production" />


## The Telstra Dongle / Huawei E8372h

This is a rather curious device.
I purchased it because it was cheap (big surprise there), and came with bonus data (10GB).
But found it contained more than I expected.

I was looking for a USB dongle, plain and simple.
Just something I could plug into my router and get an LTE connection.

But the dongle is actually a fully fledged router - DHCP, firewall, DMZ, virtual server, even WiFi.
You connect to it and you get a private IP address from it, and then you get routed through it to the Internet.

It has a basic status page which shows connection strength and remaining data.

<img src="/images/Mikrotik-And-LTE-Via-Telstra-Huawei-E8372/dongle-status-page.png" class="" width=300 height=300 alt="Status Page" />

An admin login lets you access all the usual settings you'd expect in a home router.
That is, a set of pretty poorly laid out pages to configure the device.

<img src="/images/Mikrotik-And-LTE-Via-Telstra-Huawei-E8372/dongle-settings-page.png" class="" width=300 height=300 alt="Configuration Page" />

In Windows, you need install a simple driver to use the device as a USB dongle (which is available on a "CD" drive on the device).
Or you can connect using WiFi, including other devices.

<img src="/images/Mikrotik-And-LTE-Via-Telstra-Huawei-E8372/windows-network-interface.png" class="" width=300 height=300 alt="Windows Network Interface" />

Some further details on the E8372: http://wirelessgear.com.au/telstra-4gx-usb-modem-huawei-e8372h-608/ and https://consumer.huawei.com/en/mobile-broadband/e8372/


### Why?

I find this a rather strange device.

If I want to connect to the Internet with a dongle, I don't need a router, I just need a modem.
I want the public IP address, not a NAT-ed connection (which is probably NAT-ed again at the carrier level these days).

If I want to share that connection with others, pretty much every operating system has a [hotspot function](https://en.wikipedia.org/wiki/Hotspot_%28Wi-Fi%29#Software_hotspots).

I can't run it unless its connected to a USB port - there's no external power.
Although there's a [more expensive model](https://www.telstra.com.au/mobile-phones/prepaid-mobiles/telstra-pre-paid-4gx-wi-fi-pro) with a battery (and a fancy LCD).

I guess Telstra thinks there's a market for such a device, and it works as advertised, although I struggle to understand why it exists.


## Compared to Android

My [previous connection via Android](/2017-08-16/Mikrotik-And-LTE-via-Android.html) had two big issues:

* Double NAT connection.
* The connection didn't automatically come up.

Double NAT is still a thing, because this is a router rather than a modem.

But the connection came up automatically after a reboot, which is better than the Android solution.
Otherwise, its mostly the same.

## Compared to other USB Dongles

Compared to other USB dongles, the only real difference is the double NAT.
Which would rule it out for 90% of serious uses.

There are some settings for Symmetric NAT and a DMZ IP address, which might help get past the double NAT.
Untested, may not work!


## On Mikrotik 

The dongle appears as a USB device, no surprise there.

<img src="/images/Mikrotik-And-LTE-Via-Telstra-Huawei-E8372/usb-device.png" class="" width=300 height=300 alt="USB Device for Huawei" />

And it appears as an LTE interface.
With "minimal" functionality.

<img src="/images/Mikrotik-And-LTE-Via-Telstra-Huawei-E8372/lte-interface.png" class="" width=300 height=300 alt="LTE Interface..." />

<img src="/images/Mikrotik-And-LTE-Via-Telstra-Huawei-E8372/lte-interface-status.png" class="" width=300 height=300 alt="...with minimal functionality" />

*Minimal* functionality just means there are no other settings exposed, not this its not working.
Everything else is just like the Android setup - you have an LTE interface, get a private IP address, and a default route.
No other tricky setup or surprises.


## Conclusion

The Telstra / Huawei dongle did a fine job on my holiday.
And would make a perfectly usable mobile broadband solution.

Although the double NAT is still a disappointment.
And the fact you can fit an entire router into a 100mm x 30mm dongle, when a modem would work just as well, makes me wonder where the world's engineering resources are going.
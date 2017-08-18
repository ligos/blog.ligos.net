---
title: Mikrotik and LTE via Android
date: 2017-08-16
updated: 
tags:
- Mikrotik
- Router
- Home Router
- Gateway
- How-To
- Step-By-Step
- LTE
- 4G
- Mobile Internet
- Android
- Cellphone
- Mobile Phone
categories: Technical
---

Use an old Android device for 4G / LTE Internet on a Mikrotik router.

<!-- more --> 

## Background

Each year, we go on a family holiday.
The place we stay has no Internet (shocking, I know).

Over the last few years, this hasn't been a big problem - just use our mobile devices, or just stay off the Internet for a week!

This year, the number of games which require some level of Internet connectivity has exceeded a critical point (basically all my son's Lego games need to connect to a server to work - silly DRM).
And, my son's computer is a desktop with no WiFi device, so tethering is painful.

I decided I'd connect my old [Galaxy Nexus](https://en.wikipedia.org/wiki/Galaxy_Nexus) Android phone to an old [RB751U Mikrotik](https://mikrotik.com/product/RB751U-2HnD) router, which was spare at [work](https://faredge.com.au).
This should give wired ethernet connectivity and Internet via 4G / LTE.


This article is based on [this post by Tito Muntasa](http://freakscontent.blogspot.com.au/2014/06/usb-tethering-android-in-mikrotik.html).

## Goal

Configure a Mikrotik router to use [4G](https://en.wikipedia.org/wiki/4G) / [LTE](https://en.wikipedia.org/wiki/LTE_&#40;telecommunication&#41;) to access the Internet.

I'm not going to show any other configuration you may need for a [Mikrotik device as a home router](/2017-02-16/Use-A-Mikrotik-As-Your-Home-Router.html), but you'd need to do that as well.

I'm also assuming that the LTE will be the primary and sole Internet connection (no fail over, no duel connections).


## Prerequisites

* An [Android](https://en.wikipedia.org/wiki/Android_&#40;operating_system&#41;) device, minimum version 4.4.4
* A Mikrotik router with USB port, minimum RouterOS version 6.7 (see [supported hardware](https://wiki.mikrotik.com/wiki/Supported_Hardware#4G_LTE_cards_and_modems))
* Mobile broadband on your Android device


### 0. Ensure your Android device can connect to the Internet

It's no good if your Android can't connect to the Internet.

I'm using a [pre-paid mobile broadband](http://www.vodafone.com.au/mobile-broadband/prepaid) service from [Vodafone Australia](http://www.vodafone.com.au/). 
Mostly because it was half price when I bought it.

I needed to go through the process of activating the service, and reboot my phone with the new SIM card.

If you're using your main phone or tablet, this should already be working.

(Oh, and it's worth disabling WiFi on your phone as well, as USB tethering will prefer WiFi over mobile broadband. 
Which causes confusion when testing).


### 1. Plug your phone into the router's USB port

The [RB751U](https://mikrotik.com/product/RB751U-2HnD) has a full sized USB port, so pretty much any phone USB cable will work.
My main [RB2011](https://mikrotik.com/product/RB2011UiAS-2HnD-IN) device has a micro USB port, so I need an adapter cable.

<img src="/images/Mikrotik-And-LTE-Via-Android/router-phone-usb.jpg" class="" width=300 height=300 alt="USB Connection" />


### 2. Enable USB tethering on your Android device

Before the Mikrotik router will recognise your phone / tablet, you need to enable USB tethering.

My old Galaxy Nexus is using a Cyanogen Mod 4.4.4 Android, which has USB tethering under **Settings -> More -> Tethering & portable hotspot -> USB tethering**.
Yours may be in a different location.

<img src="/images/Mikrotik-And-LTE-Via-Android/android-settings-1.png" class="" width=300 height=300 alt="Settings -> More" />

<img src="/images/Mikrotik-And-LTE-Via-Android/android-settings-2.png" class="" width=300 height=300 alt="Tethering &amp; portable hotspot" />

<img src="/images/Mikrotik-And-LTE-Via-Android/android-settings-3.png" class="" width=300 height=300 alt="USB tethering" />

**Important note**: I haven't been able to figure out how to automatically enable USB tethering on my Android device.
This means when you **reboot the router the Internet will not automatically come back up**.
You must **manually enable USB tethering again**.

This is fine for my scenario (a week long holiday), but would pose problems for a longer term connection.


### 3. Check the LTE interface / USB device

On your Mikrotik, you should see a new interface **lte1** and a new USB device.

<img src="/images/Mikrotik-And-LTE-Via-Android/lte-interface.png" class="" width=300 height=300 alt="LTE interface - that's my phone!" />

A list of connected USB devices can be found in *System -> Resources -> USB*.

<img src="/images/Mikrotik-And-LTE-Via-Android/resources-usb.png" class="" width=300 height=300 alt="The Galaxy Nexus is my phone" />


### 4. Enable a DHCP client

Android USB tethering works by looking like a USB network device, which your router / computer connects to and gets access to the Internet via DHCP.

As with most things in Mikrotik, you need to explicitly add a DHCP client for your new 3G / LTE interface.

*IP -> DHCP Client*

You should enable a *default route* and *Use Peer DNS*. 
Other settings aren't particularly important.

<img src="/images/Mikrotik-And-LTE-Via-Android/dhcp-client-details.png" class="" width=300 height=300 alt="DHCP Client - config details" />

<img src="/images/Mikrotik-And-LTE-Via-Android/dhcp-client.png" class="" width=300 height=300 alt="DHCP Client - in use" />

Its worth noting that there's a [double NAT](https://superuser.com/questions/521015/how-is-double-nat-bad-practically) going on here.
The Android device is presenting a `192.168.42.xxx` range to the router, and my Mikrotik is presenting the `10.46.10.xxx` range to devices which connect to it.
Each time, the devices will do a [network address translation](https://en.wikipedia.org/wiki/Network_address_translation) to make the Internet work.

This isn't a problem for my scenario (downloading stuff, consuming content), but will pose problems if you're trying to host a web server.


### 5. Check your route table

*IP -> Routes*

If all has gone well, you should see a new interface added which corresponds to the IP address in your DHCP client / LTE interface.

(Note: I've manually disabled a default route to my normal ADSL connection in this picture).

<img src="/images/Mikrotik-And-LTE-Via-Android/route-table.png" class="" width=300 height=300 alt="Routing the Internet via my phone" />


### 6. Tweak firewall rules

The default firewall rules assume the Internet is connected to the first ethernet port (`ether1`).
You'll need to change those rules to use `lte1` instead.

I also add a few *passthrough* firewall rules to track bandwidth usage (in Australia, mobile Internet is an order of magnitude more expensive than fixed line connections, per GB).

```
[admin@MikroTik] /ip firewall filter> print
Flags: X - disabled, I - invalid, D - dynamic 
 0  D ;;; special dummy rule to show fasttrack counters
      chain=forward action=passthrough 

 1    ;;; Client Usage of LTE
      chain=forward action=passthrough out-interface=lte1 log=no log-prefix="" 

 2    chain=forward action=passthrough in-interface=lte1 log=no log-prefix="" 

 3    ;;; Router usage of LTE
      chain=output action=passthrough out-interface=lte1 log=no log-prefix="" 

 4    chain=input action=passthrough in-interface=lte1 log=no log-prefix="" 

 5    ;;; defconf: accept ICMP
      chain=input action=accept protocol=icmp 

 6    ;;; defconf: accept established,related
      chain=input action=accept connection-state=established,related 

 7    ;;; defconf: drop all from WAN
      chain=input action=drop in-interface=lte1 log=no log-prefix="" 

 8    ;;; defconf: fasttrack
      chain=forward action=fasttrack-connection connection-state=established,related 

 9    ;;; defconf: accept established,related
      chain=forward action=accept connection-state=established,related 

10    ;;; defconf: drop invalid
      chain=forward action=drop connection-state=invalid 

11    ;;; defconf:  drop all from WAN not DSTNATed
      chain=forward action=drop connection-state=new connection-nat-state=!dstnat 
      in-interface=lte1 log=no log-prefix="" 
[admin@MikroTik] /ip firewall filter> 
```


### 8. Test on the router

You can ping `8.8.8.8` from *Tools -> Ping*, and you should see the passthrough firewall rules tick up.

### 9. Connect devices and use the Internet!

At this point, all looks good, so connect a device and use the Internet!

First thing I do is a speed test.
Mostly because its depressing how slow my ADSL is compared to LTE.

<img src="/images/Mikrotik-And-LTE-Via-Android/speed-test-lte.png" class="" width=300 height=300 alt="Internet working via LTE!" />

<img src="/images/Mikrotik-And-LTE-Via-Android/speed-test-adsl.png" class="" width=300 height=300 alt="For reference - my ADSL connection speed" />

Although in this case, they're both pretty ordinary.
I guess I get what I pay for (cheapest mobile broadband and ~5 year old mobile device)!

## Conclusion

Setting up a Mikrotik router to use an Android device is pretty straight forward.
Nothing particularly special is needed for supporting Android phones.

The double NAT and manual enabling of USB tethering are handicaps, not severe enough for my use.
If you want a more permanent LTE connection, check the Mikrotik list of [supported hardware](https://wiki.mikrotik.com/wiki/Supported_Hardware#4G_LTE_cards_and_modems).

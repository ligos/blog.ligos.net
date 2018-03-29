---
title: Mikrotik and LTE via USB Modem (and Failover)
date: 2018-03-01
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
- Modem
categories: Technical
---

Use a USB modem for backup Internet on a Mikrotik router.

<!-- more --> 

## Background

I received as SMS from my dad: 

> Internet out for over 12 hrs. 
> Have you ever set up Mikrotik with 3G modem?

I'd convinced my dad to replace an ageing (and occasionally faulty) router with a Mikrotik device a while back.
He had purchased a [hAP](https://mikrotik.com/product/RB951Ui-2nD), and configured it based on my [Mikrotik home router article](/2017-02-16/Use-A-Mikrotik-As-Your-Home-Router.html).
I'd reviewed what he did and tweaked a few things.
And it's been running quite smoothly since then.
But even the best router can't do much when there's no Internet to route!

He runs a [business from home](http://www.grantronics.com.au), and extended Internet downtime is bad.
So I referred him to the article I wrote about using an [Android device for 4G / LTE Internet](/2017-08-16/Mikrotik-And-LTE-via-Android.html) access.

Except he was using a 3G USB Modem rather than an Android phone, so it didn't quite work as nicely as I'd hoped.


## Goal

Document and configure my dad's router to allow him to use a 3G / LTE USB modem as a backup Internet connection if his [Optus cable](https://www.optus.com.au/shop/broadband/home-broadband/plans) connection fails.
(And maybe help a few other people on the Internet as well)!

Unlike my [holiday LTE setup](/2017-08-16/Mikrotik-And-LTE-via-Android.html), failover will be important: automatic will be preferred, but outages aren't very frequent, so simple manual steps will be allowed.


## Prerequisites

* A Mikrotik router with USB port,
* A supported USB 3G / LTE modem (see [peripherals](https://wiki.mikrotik.com/wiki/Manual:Peripherals) and [supported hardware](https://wiki.mikrotik.com/wiki/Supported_Hardware))


### 0. Ensure your USB modem can connect to the Internet

If your modem doesn't work, it will be a pain to troubleshoot on your router.
So double check it connects successfully in a more supported environment (eg: Windows laptop).

My dad is using a [Huawei E1762 USB 3G modem](http://www.3gmodem.com.hk/Huawei/E1762.html).
Which has minimal documentation on the Internet.


### 1. Plug the USB modem into the router's USB port

Depending on your router you may need a USB adapter cable.
My dad's hAP has a full size USB port, so he just plugged it in.

<img src="/images/Mikrotik-And-LTE-Via-USB-and-Failover/router-usb-modem.jpg" class="" width=300 height=300 alt="3G Modem + USB Connection" />


### 2. Check the USB device

Check in *System -> Resources -> USB* for the modem you just connected.
If there's nothing there, it may not be supported and you'll need to find an alternative.

<img src="/images/Mikrotik-And-LTE-Via-USB-and-Failover/system-resources-modem.png" class="" width=300 height=300 alt="The Huawei USB modem" />


### 3. Create a PPP or LTE Interface

My dad's modem is a 3G device, so he created a new [PPP Client](https://wiki.mikrotik.com/wiki/Manual:Interface/PPP) in **Interfaces -> New -> PPP Client**.
You may need to set an APN, username or password (check with your service provider for this information); dad's using an Optus service so his APN is `yesinternet`.
The Status should change to *waiting for packets...*, then *link established* and finally *connected*.

If you have a newer and faster LTE / 4G modem, an [LTE interface](https://wiki.mikrotik.com/wiki/Manual:Interface/LTE) should automatically be created.
However, you may still need to set an APN, username or password.

<img src="/images/Mikrotik-And-LTE-Via-USB-and-Failover/ppp-interface.png" class="" width=300 height=300 alt="PPP Interface" />

You should also set the *default route distance* to `2`.
This will force the router to prefer your primary link over the 3G / LTE one.

At this point we should have a working cellular interface.
You can test it by disabling your main Internet interface (eg: Cable / ADSL / Ethernet / whatever) temporarily (remember to turn [safe mode](/2018-02-22/Making-Mikrotik-Safe.html) on before you accidentally delete it!!).
Your Internet should still work and you should see activity on the PPP / LTE interface.

You can use *Tools -> Ping* to test connectivity from the router itself (eg: to `8.8.8.8`).


### 4. Check your route table

*IP -> Routes*

You should see two default [routes](https://wiki.mikrotik.com/wiki/Manual:IP/Route).
Your router will prefer the primary connection (ie: cable, ADSL, etc) to the cellular one because it has a smaller distance.

<img src="/images/Mikrotik-And-LTE-Via-USB-and-Failover/route-table.png" class="" width=300 height=300 alt="Routing the Internet via cable and 3G" />

However, both the primary and cellular interfaces will always be "up", as far as routing is concerned (because the ethernet cable is plugged in).
That is, even when your primary interface service does down, the router will keep trying to send traffic over your cable / ADSL / fibre link (even when the packets can't go anywhere).

To switch over to the cellular backup interface, you should disable your primary interface.
(And remember to re-enable it when it's working again, of course).

This is a slightly manual process.
However, if your primary interface is very reliable and you don't really mind a few minutes down time while someone notices the Internet has dropped, logs into your router and clicks *disable*, then it is perfectly functional.
(My dad prefers this approach, because cellular data is an order of magnitude more expensive in Australia, and he wants to know when he's switched over to 3G).


### 5. Configure routing for failover

But we can automate the switch from primary to backup interface (and back again) using a few simple routing rules.
**Be warned:** this assumes a particular IP address as the default gateway; it is not picking it up automatically from DHCP.

We need to set the *Check Gateway* option to `ping`, so the router can detect when a link has gone down.
Unfortunately, the default route created from DHCP does not let us do that - all fields are read only.

So, make a **copy** the default route.
Set *Check Gateway* to `ping`.
And then disable this route.

<img src="/images/Mikrotik-And-LTE-Via-USB-and-Failover/default-route-with-check-gateway.png" class="" width=300 height=300 alt="The default route with `check gateway` set." />

Next, hop over to *IP -> DHCP Client* and set *Add Default Route* to `no`.
Your primary interface's dynamic default route will disappear.

<img src="/images/Mikrotik-And-LTE-Via-USB-and-Failover/no-default-route.png" class="" width=300 height=300 alt="Disable the primary interface deafult gateway." />

Back to the route table and enable the manual default route.
Now should now have 2 routes to the Internet: primary via cable / ADSL / whatever, and secondary via 3G / LTE.

<img src="/images/Mikrotik-And-LTE-Via-USB-and-Failover/route-table-with-failover.png" class="" width=300 height=300 alt="Routing the Internet with automatic failover - The only difference is a 'D' (for dynamic) is missing." />

My dad simulated an Internet failure by turning off his cable modem (but not removing the  ethernet cable).
The router sees the ethernet port as still connected, but it can't actually reach the Internet.
It takes about 30 seconds for the router to notice and switch to routing over the backup 3G interface.
After plugging the cable back in, it took another 30 seconds to switch back to the primary cable interface (mostly the cable modem sorting itself out).

**Important:** All this assumes your Internet gateway does not change. 
That is, we just hard coded a default gateway into your router.
In other words, **if your gateway ever changes your Internet will break and you'll probably forget to check the route table.**
You should only do this if you have a static IP address, and even then be very wary.


**Routing References**

We've followed the [simple failover configuration](https://wiki.mikrotik.com/wiki/Two_gateways_failover), but if you have more complex requirements or more than 2 WAN links, you may want to consider a more [advanced failover configuration](https://wiki.mikrotik.com/wiki/Advanced_Routing_Failover_without_Scripting).
And a [forum post with further failover information](https://forum.mikrotik.com/viewtopic.php?t=81679).


## Conclusion

You can now have your Mikrotik router configured with a backup WAN interface using a 3G or LTE USB modem.
And some very simple routing rules to switch to the backup link if the primary fails.
(Or, you can just disable the primary interface).
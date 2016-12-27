---
title: Recover a Broken Mikrotik Device
date: 2016-12-27
updated: 
tags:
- Mikrotik
- Netinstall
- Netboot
- Bricked
- Broken
- Boot-Failure
categories: Technical
---

Your Mikrotik doesn't boot. Netinstall to the resuce!

<!-- more --> 

## Background

I was preparing a new [Mikrotik hEX](https://routerboard.com/RB750Gr3) router for church.
There was a recent product update which improved the CPU and RAM by 4x compared to previous revision.
But the device still only has 16MB of flash memory (a micro SD card can be installed for more storage), with under 6MB free out-of-the-box.

In an effort to remove packages it won't ever need (eg: wireless and hotspot) and free up space, I aggressively removed pretty much all packages and tried to install everything from scratch.

Apparently, removing the base **routeros-mmips** package isn't a wise move.

My brand new router no longer booted.

And it was three days before Christmas. 
So no hope of sending it back to [Duxtel](http://shop.duxtel.com.au/) to get a replacement (and I'm not sure if my pride would cope with that kind of RMA anyway).


## Steps 

I tried various ways of resetting the device. None worked except [netinstall](http://wiki.mikrotik.com/wiki/Manual:Netinstall).


### 0. Gotchas

There were two things which caused me problems:

My router was power cycling every 30 seconds, so Windows didn't see the ethernet port up for long enough for me to set an IP address.
I needed to plug my ethernet into another switch to set the IP first.
(This affects step 2).

I had Hyper-V installed (for phone development) and needed to remove it first.
The router never deteted the netinstall program and never connected to the bootp server while Hyper-V was running.
Seems netinstall and the Hyper-V virtual switch don't play nice together.
(This affects step 5).


### 1. Download Netinstall and Firmware

You may be offline while you do the netinstall procedure, so [download netinstall and correct packages](http://www.mikrotik.com/download) for your router before hand.
I used the **MMIPS Main Package** for my rev 3 hEX device (RB750Gr3).

If you are unsure of your router's specific model, try the netinstall process and it should identify your device.

If, by chance, you can still connect to your router, you can find the exact model in System -> Routerboard -> Model. 


### 2. Set Static IP on your Computer

You need to set a static IP address on your computer for a netinstall.
I used `10.0.0.50/24`, but any IP separate from your main network is OK.

In Windows 10, the adapter settings are in Control Panel -> Network and Internet -> Network and Sharing Centre

<img src="/images/Recover-a-Broken-Mikrotik-Device/windows-ethernet-adapter.png" class="" width=300 height=300 alt="Network Adapter Settings" />

Then Properties -> Internet Protocol Version 4 -> Properties -> Use the following IP address.

<img src="/images/Recover-a-Broken-Mikrotik-Device/windows-ethernet-adapter-static-ip.png" class="" width=300 height=300 alt="Static IP Address" />


### 3. Configure Netinstall

Start the Netinstall program.

You will need to run as an elevated user.

You will need to allow netinstall through your firewall to all IP addresses (public scope for the Windows Firewall).

Click *Net booting* and enter a **different IP address**, which will be assigned to the router during the boot process.
I used `10.0.0.51`.

<img src="/images/Recover-a-Broken-Mikrotik-Device/netboot-ip-configuration.png" class="" width=300 height=300 alt="Client / Router IP Address" />


### 4. Connect The Router

Connect your router port 1 directly to your computer's ethernet port.

I could only make netinstall work with port 1; other ports just didn't work.


### 5. Reboot The Router with Reset Button Held Down

Power off your router.

Click the tiny reset button down (labelled `RES` on my hEX router) and hold it down.
You'll need a sharp pencil, pen or paper clip for this.

Power your router on.

Wait for up to 30 seconds.
With the reset button still held down.

If everything is configured correctly, you should see the device listed in netinstall.
Once it is in netinstall, you can release the reset button.

<img src="/images/Recover-a-Broken-Mikrotik-Device/netboot-success.png" class="" width=300 height=300 alt="Netboot Was Successful!" />

The `Label` column shows the model of the device (if you didn't know which it was when downloading a package).

Select the device.


### 6. Select Package to Install

Browse to the folder you downloaded the RouterOS package(s).

You should see compatible packages listed below. 
If nothing is listed, you have downloaded the incorrect packages.

Select the package(s) you want to install (at minimum, you'll need the `system` package; the `base` package will have everything to get your device working again).

<img src="/images/Recover-a-Broken-Mikrotik-Device/netinstall-packages.png" class="" width=300 height=300 alt="Select Packages" />


### 7. Keep your Configuration?

If you tick the `Keep old configuration` checkbox, any configuration you have done (eg: IP addresses, passwords, firewall rules, etc) will be retained.

Untick the box, and you get an out-of-the-box configuration (router on 192.168.88.1 with no password).

Depending on what is keeping your router from booting, the former may not work (although it did in my case), the later should work no matter what.

<img src="/images/Recover-a-Broken-Mikrotik-Device/netinstall-keep-config.png" class="" width=300 height=300 alt="Keep Old Configuration?" />


### 8. Hit the Go Button

Click *Install* to begin the reset, reconfigure and reinstall.

<img src="/images/Recover-a-Broken-Mikrotik-Device/netboot-install.png" class="" width=300 height=300 alt="The Go Button" />


You'll get a progress bar, which sits on `partitioning and formating harddrive` for a minute or so with no other indication of progress.

Then it will transfer each of your packages.

<img src="/images/Recover-a-Broken-Mikrotik-Device/netboot-transferring.png" class="" width=300 height=300 alt="Transferring Packages..." />


If all goes well, it will say `Installation finished successfully`.
And your router will automatically reboot.


### 9. Set Your Ethernet Back to DHCP

Remember to remove the static IP configuration on your ethernet port and re-enable DHCP.

(Many years ago, I forgot this step and had the very unusual scenario of working IPv6 but non-working IPv4. 
Google was reachable, but pretty much all the rest of the Internet was dark.
Made for interesting troubleshooting!)


## Conclusion

If you manage to get your Mikrotik device into a non-bootable state, you can try a netinstall to fix it.

Netinstall should be usable and able to recover most software related problems.
(Faulty hardware should be returned or replaced).
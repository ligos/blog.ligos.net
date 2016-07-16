---
title: How to Upgrade an Old Computer
date: 2016-07-16
tags:
- Computer
- Hardware
- Upgrade
- Windows-10
- SSD
- Costings
categories: Technical
---

Even an 8 year old PC is usable, with $200 of upgrades.

<!-- more --> 

## Background

I was asked to give a short presentation at my church on [how to remove a virus from your PC](/2016-06-16/How-To-Remove-Malware-From-Your-PC.html).
And I thought the best way to do that is to install some malware and actually remove it.

So I asked around at work and found an old Dell Vostro desktop sitting unused in the store room.
No one wanted it, and the boss was happy for me to take it home. 

After I clicked on every spam email I received in the last month, did my presentation, and then wiped the computer.

<img src="/images/How-To-Upgrade-An-Old-Computer/installing-malware.jpg" class="" width=300 height=300 alt="I clicked on attachment in every spam email. You'll never guess what happened next!" />


## Goal

Get this ~8 year old computer running with Windows 10, a decent amount of RAM and an SSD.

The sort of thing which will be suitable for my kids to use for playing YouTube videos... errr... doing homework. 
 
(If Window 10 wasn't going to work, my fallback was [Ubuntu](http://www.ubuntu.com/) or similar, but I didn't need to go down that road).   

(Aside: Adding an SSD, or [solid state disk](https://en.wikipedia.org/wiki/Solid-state_drive), is by far the easiest way to transform an old, slow computer into a much faster one. 
Computers spend most of their time waiting to load things from the hard disk, and an SSD is something like 50x faster than older spinning [hard disk drives](https://en.wikipedia.org/wiki/Hard_disk_drive).
More RAM helps as well, but not as much as an SSD.
I always use an SSD, no exceptions.) 

### Original Specs

The PC was a [Dell Vostro 230](http://www.dell.com/support/home/au/en/audhs1/product-support/servicetag/BFBG62S/configuration) with Windows 7 Pro 64 bit.
It had a [Core 2 E7500 CPU](http://ark.intel.com/products/36503/Intel-Core2-Duo-Processor-E7500-3M-Cache-2_93-GHz-1066-MHz-FSB), 2GB of RAM anda 320GB hard disk.

<img src="/images/How-To-Upgrade-An-Old-Computer/before-upgrade.jpg" class="" width=300 height=300 alt="Dell Vostro 230 Before Upgrade" />

Inside, there was a PCI Express 16x slot, suitable for a video card. A 1x slot, and 2 legacy PCI slots.
(Which you can't see in this picture. Sorry.)

<img src="/images/How-To-Upgrade-An-Old-Computer/inside.jpg" class="" width=300 height=300 alt="Dell Vostro 230 Inside Before Upgrade" />


### Purchases

I bought some parts from [TechBuy](http://techbuy.com.au):

* A 120GB Intel SSD - AU$85
* 8GB RAM - AU$65
* A D-Link Wireless NIC - AU$28
* An audio cable to connect speakers built into the monitor - $5
* Postage - $8

Because the computer had a valid Windows 7 Pro license, I got to upgrade to Windows 10 Pro for free as part of Microsoft's upgrade program.

Total: **AU$191**

<img src="/images/How-To-Upgrade-An-Old-Computer/parts.jpg" class="" width=300 height=300 alt="Parts to be Installed" />


### Upgrade

Unfortunately, the computer didn't like the 8GB of RAM I bought.
So I installed the 8GB in another computer and swapped 4GB out.
4GB looks like the maximum the Vostro 230 will support, so 4GB it is.

I tested the 4GB RAM using [Memtest86](http://memtest86.com/) overnight without issue.
(Bad RAM is often the cause of system instability, so testing early is worth your while.)

I connected the SSD, and re-arranged the cables so they weren't quite as tangled.
I didn't have any way to mount the 2.5" device, but that wasn't a problem - the drive is so light the cables keep it in place.
After a reboot, the new disk appeared in the BIOS OK.

<img src="/images/How-To-Upgrade-An-Old-Computer/parts-installed.jpg" class="" width=300 height=300 alt="Parts Installed!" />

Finally, I installed the Wireless NIC in a PCI slot.
(I went for a PCI NIC because a video card is likely to take up two slots, so the PCI Express 1x slot would be unusable)

I clean installed Windows 10 from a USB, which was created on another computer, to the SSD.
The 320GB disk will remain for backups, games and other programs. 

<img src="/images/How-To-Upgrade-An-Old-Computer/installing-windows-10.jpg" class="" width=300 height=300 alt="Installing Windows 10" />

I didn't grab any benchmarks before or after, but the after experience is certainly more than acceptable.
Startup time is around 15 seconds.
Programs and apps load and run more than fast enough.

<img src="/images/How-To-Upgrade-An-Old-Computer/upgrade-complete.jpg" class="" width=300 height=300 alt="Upgrade Complete" />

And, most importantly, YouTube works. 

### A Month Later - A Video Card

The integrated video of older Intel CPUs is very ordinary.
While web browsing, YouTube and Word worked OK, it was basically impossible to play any games.
And a kids computer needs some level of games (if only to get them off YouTube for a while).

I found an unused video card at work - some variant of an [AMD Radeon HD 8350](https://en.wikipedia.org/wiki/Radeon_HD_8000_series).
It's a pretty terrible video card, but more than capable of putting pixels on the screen.
(If I couldn't get this for free, similar cards cost between AU$20 and AU$50 on Ebay.)

And I swapped it into my do-everything-server (serving files, recording and viewing TV, hosting this blog, and a few VMs as well).
So the Vostro now has a mid range [Radeon HD 6570](https://en.wikipedia.org/wiki/Radeon_HD_6000_Series), which is probably powerful enough for it's gaming capacity, and my server has the dinky HD 8350, which is enough to watch TV.


## Conclusion

For less than $200, you can upgrade an old computer.
This computer (assuming nothing blows up) should be usable for the next 5 or so years.
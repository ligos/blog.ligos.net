---
title: Recovering from a Dead CPU
date: 2017-12-02
tags:
- Crash
- Hardware
- CPU
- Motherboard
- Windows Activation
- UEFI
- Storage Spaces
- Windows 10
- WIndows Upgrade
categories: Technical
---

When your CPU... errr... stops working.

<!-- more --> 

## Background

My [home media server](https://loki.ligos.net) serves various needs: hosting this blog, [recording over-the-air TV broadcasts](http://www.nextpvr.com/), our family file / media server, and to amuse my kids with [Minecraft](https://minecraft.net).

Each year, usually as Summer approaches, I clean all the dust out of it.
In past years, this was a necessity for reliable operation: the machine would overheat!
But I spent ~$50 on fans and a giant heatsink 18 months ago and its been much happier.

Oh, and there was something called the [Fall Creators Update](https://blogs.windows.com/windowsexperience/2017/10/17/whats-new-windows-10-fall-creators-update/) which needed installing.
So it was maintenance time!

After migrating websites to my laptop and getting a good night's sleep, I powered the box down and started vacuuming, brushing and cleaning.
I pull all the parts out so I can brush down connections and make sure dust is gone.


## The Problem

I tried to take the giant heatsink off the CPU. And it was so stuck that it half ripped the CPU out of its socket.

By the time I managed to get the CPU out, I'd bent ~200 pins.

<img src="/images/Recovering-From-A-Dead-CPU/bent-and-broken-pins.jpg" class="" width=300 height=300 alt="This was after I spent 45 minutes straightening pins. I count 4 broken ones. And no, it doesn't work any more." />

It's not often I swear or curse, but my own stupidity and incompetence sometimes knows no bounds!


## How to Fix It

After a futile effort to straighten the bent pins (which involved me breaking several), I gave up and looked for a replacement on [EBay](https://www.ebay.com.au/).
(The motherboard socket looked to have damage to it as well, so I needed both a CPU and motherboard). 


### 1. Find new Parts

I found a used [AMD A8-5600K CPU](https://en.wikipedia.org/wiki/Piledriver_&#40;microarchitecture&#41;) and a [Gigabyte ABCD](https://www.gigabyte.com/Motherboard/GA-F2A85X-D3H-rev-10) motherboard for a little over $100, which still supported DDR3 RAM (there was no way I wanted to buy new RAM as well). 
I figured this was as good as it gets, so I clicked 'Buy It Now'.

The A8 was ~5 years newer than my aging [Phenom II x4 925 series CPU](https://en.wikipedia.org/wiki/Phenom_II), although it has only 2 cores instead of 4.
The real upgrade was motherboard: which had more expansion slots and SATA ports.
As this computer is effectively a home server, more IO is always welcome (and rather hard to find on consumer gear).

A few days later, I received the new motherboard in the post.


### 2. Install New Parts

The golden rule with upgrading or updating hardware is do it slowly and carefully (perhaps I should have taken my own advice *before* I got in this mess).

I waited until Friday night and installed the new motherboard and CPU and RAM. Then I set [memtest86](https://www.memtest86.com/) running overnight.

<img src="/images/Recovering-From-A-Dead-CPU/new-motherboard-and-cpu.jpg" class="" width=300 height=300 alt="A secondhand new motherboard and CPU working nicely. Disks and expansion cards not installed yet. That's the giant hunk of aluminum which caused all the problems." />

Once I was satisfied the CPU, motherboard and RAM were happy, I plugged in the system disk (an SSD) and let Windows boot up.
It decided it needed to install a bunch of new drivers and reboot a few times, but otherwise was working as well as could be expected.

<img src="/images/Recovering-From-A-Dead-CPU/new-cpu-details.png" class="" width=300 height=300 alt="Shiny secondhand new CPU details!" />

Then I plugged in all the other disks (4 data disks, 2 backup disks, and a DVD burner).
And ran `chkdsk /F /R /B` on all the disks to re-check for bad clusters.

Two problems emerged at this point.

The first was the <del>BIOS</del> system firmware.
It decided it wanted to boot from the wrong disk and needed to be told that the SSD was the one to use.
Apparently, this has something to do with the [CSM](http://wiki.osdev.org/UEFI) part of [UEFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface), which is effectively telling the firmware boot in legacy BIOS mode.
I'm sure I could re-install Windows with [Guid partition tables](https://en.wikipedia.org/wiki/GUID_Partition_Table) and correct UEFI boot partitions, but that takes time which I didn't want to spend.

The second was my data disks.
They are in a [Storage Spaces](https://support.microsoft.com/en-us/help/12438/windows-10-storage-spaces) array to provide mirroring between 4 disks.
But it seems one of SATA cables wasn't quite plugged in right.
Windows detected IO errors, disabled the disk and Storage Spaces got all grumpy.
I'll post more information about this in a future blog, but I eventually got it sorted.


### 3. Re-Activate Windows

At this point, Windows was pretty happily running, but had decided that I had changed too much hardware and needed to re-activate Windows.

<img src="/images/Recovering-From-A-Dead-CPU/activation-fail.png" class="" width=300 height=300 alt="No activation for you!" />

I was expecting this.
From Windows 8 onwards, Windows stores the [license key in the motherboard non-volatile RAM](https://www.cnet.com/news/windows-8-moves-to-bios-based-product-keys/).
Which means if you replace your motherboard, the Windows license key suddenly disappears.
Even worse in my case, because I was using a second hand motherboard I probably had someone elses license key!
And the wrong license key and significant changes to hardware look an awful lot like a totally new computer, if you are a licensing component in Windows.

I called up Microsoft, stepped through about 8 levels of phone menu until I spoke to a person.
I explained that I had changed the motherboard and needed to re-activate Windows.
The only question I was asked was to read out my product key (which was an upgrade from Windows 8.1, itself an upgrade from 8.0, and yet another upgrade from 7), which the gentleman validated as legit.

After that I was transferred to Microsoft's level 1 helpdesk.
Unfortunately, this part took a bit longer than I would have liked (around 45 minutes).
The lady walked through some troubleshooting steps, then asked for remote access (which I gave) and used `slmgr` to re-initialise the Windows license.
After my original product key didn't work, she tried several alternate ones.
And a few reboots for good measure.
In the end I think I got an enterprise key of some sort, based on the messages in Settings.
Which was eventually activated using the very hidden phone activation screen invoked via `slui 4` (which I'd used on occasion back in the Windows XP days). 

<img src="/images/Recovering-From-A-Dead-CPU/activation-new-product-key.jpg" class="" width=300 height=300 alt="My helpdesk person resetting my product key." />

<img src="/images/Recovering-From-A-Dead-CPU/activation-phone-codes.jpg" class="" width=300 height=300 alt="This is very hard to find in Windows 10: command line `slui 4`." />

Although it took longer than I would have liked, all the Microsoft people I spoke to were professional and never questioned my story of a hardware change.
I'm not sure if they twigged to my level of IT expertise (I could easily be level 2 or 3 support), but they didn't ask dumb questions more than once.
(My favourite was "are you sure this computer is Windows 10 compatible", to which I bluntly answered "Yes. I am sure" with no further explanation)!

**A Lesson to Learn**

Through my phone call, I was told several times (by automated messages and real people) that you can re-activate Windows after a significant hardware change if you have your [license linked to your Microsoft account](https://support.microsoft.com/en-au/help/20530/windows-10-reactivating-after-hardware-change).
Small print: that Microsoft account must be an administrator on your computer.
While I use Microsoft accounts for all people in my family, 
they are all standard users (even me), and I have a separate local admin account.
Call me paranoid, but I want the keys to my kingdom in my hands, not Microsoft's!
Also, I don't trust anyone in my house with admin level rights (even me - I still need to type the admin password).

<img src="/images/Recovering-From-A-Dead-CPU/activation-no-account.png" class="" width=300 height=300 alt="What happens when you don't have an admin level Microsoft account." />


### 4. Upgrade Windows

Remember that half the reason I was doing maintenance on this computer was to install the latest major update to Windows 10 ([Fall Creators Update / version 1709](https://blogs.windows.com/windowsexperience/2017/10/17/whats-new-windows-10-fall-creators-update/)).
Well, after I was happy that a) the hardware was working OK, and b) Windows was activated and running, I actually installed the update.

Compared to all everything else, this was rather uneventful!


### 5. An Admin Level Microsoft Account

After all was upgrading and working nicely, I added the magic admin level Microsoft account (to all my Windows PCs).
I created a completely new Microsoft account for this.

Now, if things blow up, I have some hope of avoiding a lengthy phone call (maybe; untested, may not work).


## Conclusion

Breaking computer hardware makes me sad (mostly at myself).
Fortunately, fixing it was reasonably straight forward.
And, it would have been easier if I had an admin Microsoft account on the computer.

Several lessons learned.
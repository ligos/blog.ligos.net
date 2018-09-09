---
title: Re-Purposing Old Computer Gear
date: 2018-09-09
tags:
- Hardware
- Licensing
- Laptops
- Upgrade
- Linux Mint
- Admin Access
categories: Technical
---

Making old laptops useful.

<!-- more --> 

## Background

My parents received some old laptops with the instructions to "pass them onto underprivileged children".

Specifically, they were some old [Department of Education](https://education.nsw.gov.au/) laptops dating from around 2011.
And the "underprivileged children" were some [South Sudanese](https://en.wikipedia.org/wiki/South_Sudan) families at [church](https://wentyanglican.org.au).


## Goal

Make as many of these laptops useful for school homework, for the minimum amount of money (preferably, zero).

And, more generally, think about how useful old hardware is, and what to do if you receive a bunch of free gear.

Previously, I've [upgraded an old computer for my own children](/2016-07-16/How_To_Upgrade_An_Old_Computer.html), if you want a slightly different take.


## What Have We Got to Work With?

First up, I checked out what these laptops were.
Essentially, I made a basic inventory of their specs, for both hardware and software.

Of particular interest is if there are any valid software licenses (eg: for [Windows](https://www.microsoft.com/en-au/windows) or [Office](https://www.office.com/)).
And how much RAM each laptop has.
Icing on the cake would be an [SSD](https://en.wikipedia.org/wiki/Solid-state_drive), but it's pretty unlikely [2011 laptops distributed to children](https://en.wikipedia.org/wiki/Digital_Education_Revolution) have such luxuries.

Licenses are valuable because, well, they cost money and people are more familiar with Windows & Office than alternatives.
And RAM / SSDs are the key performance measures of most computers, more RAM or an SSD can be the difference between "fast" or "slow" computer.

Hardware specs are often printed on computers.
Failing that, you can use the [BIOS / firmware](https://en.wikipedia.org/wiki/BIOS), or check within Windows (search for "*system information*" in Windows) or [boot a Linux Live Image](https://en.wikipedia.org/wiki/List_of_live_CDs) to [get specs from Linux](https://www.binarytides.com/linux-commands-hardware-info/).

This is what I had:

* 3 x [Acer TravelMate TimelineX 8572T](http://www.lapspecs.com/detail/acer+travelmate+timelinex+8572t)
* 3 x [Lenovo Thinkpad T520i](https://www.lenovo.com/us/en/laptops/thinkpad/t-series/t520/)

All with 2GB RAM, spinning HDDs of 320GB - 500GB capacity, and 1st or 2nd gen i3 CPUs.
They all have academic Windows 7 Enterprise licenses and (I was told) MS Office.

<img src="/images/Repurposing-Old-Computer-Gear/laptop-stack.jpg" class="" width=300 height=300 alt="A stack of old laptops." />


## Define "Useful"

2GB of RAM is unusable in my mind, particularly without an SSD.
I'm not handing these laptops on unless they have 4GB.

Making use of the Windows and Office licenses is also high on my priority list.
And I was given admin logins such that this would be possible.


## Confirm They Work

First up, was to check the laptops work.
As in, they power on, and the admin login works.

With a few powerboards and some table space, I established they all start up, except one which had a broken power socket.
So that's a good start.

However, the admin login didn't work.
Bugger.

<img src="/images/Repurposing-Old-Computer-Gear/administrator-login-fail.jpg" class="" width=300 height=300 alt="That is not the right password." />

After some emails with the person who supplied the laptops, I concluded that the admin login password hadn't been set correctly, or the password they were telling me was wrong.


## Get a Valid Admin Login

There's a saying in computer security: [if the bad guy has physical access to your computer, it's not your computer any more](https://technet.microsoft.com/en-us/library/2008.10.securitywatch.aspx
).
With the right tools and a bit of time, it's pretty easy to get administrator rights to a Windows computer.

I used an [Ultimate Boot CD... errr... USB](http://www.ultimatebootcd.com/) to boot up the [Offline NT Password & Registry Editor](http://pogostick.net/~pnh/ntpasswd/) which can clear the local administrator password.
Which gave me valid admin logins... for the 3 Acer laptops.

The Lenovo laptops had a BIOS / firmware password, which prevented me from telling the computer to start from the Ultimate Boot <strike>CD</strike> USB.
I could get into the BIOS, but all the security settings were disabled.
That's a pain, but BIOS passwords can be cleared by clearing the non-volitile memory storing said password.

Lenovo laptops are nice in that Lenovo publishes [service manuals](https://support.lenovo.com/us/en/solutions/ht101562) which give very detailed instructions of how to disassemble their devices.
The [Thinkpad T520i service manual](https://download.lenovo.com/ibmdl/pub/pc/pccbbs/mobiles_pdf/t520_t520i_w520_hmm_en_0A60078_08.pdf) told me exactly how to access the "backup battery" to reset BIOS passwords (pages 85 and 43). 

Unfortunately, I didn't read 3 lines further down where it said: "*Attention: If the supervisor password has been forgotten and cannot be made available to the service technician, there is no service procedure to reset the password. The system board must be replaced for a scheduled fee.*".

Some further research showed that Lenovo "supervisor passwords" are stored in an [EEPROM](https://en.wikipedia.org/wiki/EEPROM), which is not affected by removing the backup battery.
People had some success clearing / recovering the EEPROM by either [reading its contents](https://forum.arduino.cc/index.php?topic=160222.0) or [shorting pins out while the laptop was powered on](https://davidzou.com/articles/bios-password-bypass).
Either of which I could do, but would require more effort that I was willing to spend.

So I tried the "social engineering" approach: I asked my friend who supplied the laptops if he knew the "supervisor password".
And he did!

Problem solved.


## Everyone Loves Licensing (actually, no they don't)

With an admin login, I logged into each of the laptops to see what software was installed.
Particularly, I wanted to see if they had valid Office licenses.

No, they did not.

<img src="/images/Repurposing-Old-Computer-Gear/windows-activation-error.jpg" class="" width=300 height=300 alt="Unable to activate Windows: DNS name does not exist." />

Windows complained almost immediately that it wasn't activated.
The error code `0x8007232B` was about a DNS lookup error.
I've never done serious enterprise Windows deployments, but you can install [Key Management Services](https://docs.microsoft.com/en-us/windows-server/get-started/server-2016-activation
) to activate individual devices.
Effectively, you host your own activation server.

These laptops couldn't find the Department of Education KMS server.
Which is no surprise, given they are on my network, not a school network.

I started Office up and got this error:

<img src="/images/Repurposing-Old-Computer-Gear/office-activation-error.jpg" class="" width=300 height=300 alt="Can't activate Office either." />

Sigh.

Without valid Windows or Office licenses, the value of these laptops reduced considerably.


## 4GB of RAM

I put aside the licensing problems for now.
Because I wasn't prepared to inflict 2GB devices on anyone - they'd just be too slow.

I had some spare [DDR3 Laptop RAM](https://en.wikipedia.org/wiki/SO-DIMM) around after my [old laptop died](/2017-11-03/Restoring-From-Backup.html).
Between that RAM, plus the faulty 6th laptop, I had exactly enough to upgrade 5 laptops to 4GB.

Handy tip: when you add / remove or change the RAM configuration of any device, run a memory test on it.
Windows has a [memory diagnostic](https://technet.microsoft.com/en-us/library/ff700221.aspx) built in, and there's also [memtest86](https://www.memtest86.com/) or [memtest86+](http://www.memtest.org/).
Almost all problems I've had with PCs is down to dodgy RAM (or dodgy drivers), so it's worth spending 30 minutes to double check.

I used memtest86+, and all the devices passed with 4GB!

<img src="/images/Repurposing-Old-Computer-Gear/laptops-memtest86.jpg" class="" width=300 height=300 alt="Memtest86+ running on two laptops" />


## Free Alternatives - Linux Mint & Libre Office

The requirements for the laptops was to help kids do their homework.
These days, that requires a) a web browser and b) ability to open PDFs and Word documents (`docx` files).
With added points if they can play YouTube videos.

[Linux Mint](https://linuxmint.com/) should be able to do that - in theory.
I've always known Linux Mint is good enough for basic browsing and typing, but never had cause to prove the point.

So I installed Mint onto one of the laptops.
Kicked off [Firefox](https://www.mozilla.org/) and checked YouTube works - yes it does.
Then checked [Libre Office](https://www.libreoffice.org/) can open a random Word doc - yep.
And finally downloaded a PDF and opened it - that worked too.

**Problem solved!**

I connected to my [guest WiFi network](/2016-10-04/Create_Another_Network_On_A_Mikrotik.html), and installed updates.
And installed [Chromium](https://www.chromium.org/) (because people like Chrome) and [cheese](https://wiki.gnome.org/Apps/Cheese) so kids can do silly things with webcams.

<img src="/images/Repurposing-Old-Computer-Gear/laptop-linux-mint.jpg" class="" width=300 height=300 alt="A shiny old laptop running Linux Mint" />

The whole Linux Mint installation process was entirely straight forward (at least for someone who's been tinkering with PCs since they were 10 years old).
Heck, most people capable of following instructions could do it.
There was never one time I needed to muck about with drivers, kernels or even the command line.

It looks like Windows (kinda).
And is capable of doing the things kids need for homework.
And 5 out of 6 laptops is a pass mark, at least in my book.


## Conclusion

PCs have reached a point of maturity where even 7 year old laptops are still useful.
Add a little RAM, install Linux Mint and they're "good enough" for basic web browsing, email, typing and homework.
Oh, and watching YouTube - this is extremely important for kids (well, at least my kids).

If I was to spend money on them, I'd definitely add an SSD.
But I'm aiming for spending nothing.

If you find old computer gear, check what is still usable.
Upgrade to minimum amount of RAM.
And, when there are no software licenses, install a [Linux distribution](https://en.wikipedia.org/wiki/List_of_Linux_distributions) for a minimum level of functionality (actually, Linux has plenty of functionality, but that's another post).

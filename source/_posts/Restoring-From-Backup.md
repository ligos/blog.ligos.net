---
title: Restoring From A Backup
date: 2017-11-03
tags: 
- Backup
- Restore
- Sysinternals
- Crashplan
- Dropbox
- Cloud
- File History
categories: Technical
---

How to restore from your backup after your computer dies.

<!-- more --> 

After ~7 years of use, my old [Acer Aspire 4820TG](https://www.notebookcheck.net/Review-Acer-Aspire-4820TG-Timeline-X-Notebook.30281.0.html) laptop finally died.
So I had to make practical use of my own instructions for [How to Backup Your Computer](/2017-06-13/How-to-Backup-Your-Computer.html).


## The Crash

My Acer never died completely, but it is not usable.
After running for somewhere between 15 and 90 minutes, it would crash.

<img src="/images/Restoring-From-Backup/acer-laptop-crash1.jpg" class="" width=300 height=300 alt="That can't be good" />
 
The errors seemed to relate to the video card and usually happened when it was running hot (as in, I would crash it in 5 minutes when playing any game).

<img src="/images/Restoring-From-Backup/acer-laptop-crash2.jpg" class="" width=300 height=300 alt="That's no better" />

Unfortunately, I couldn't fix it.
Replacing thermal goo didn't work.
Telling Windows to run everything as slow as possible didn't work.

So I decided it was time for a new laptop.
And that means restoring my data to the new computer.


## Steps of Restoring

Here are the steps I went through to restore my data to a new computer.


### 0. Alternate Working Environment

My immediate and most pressing problem was I couldn't do any work.
And when you need a computer to get paid, this is serious!

My phone can be used to get my personal email, even if its not as good as a full PC.
And, because my mail is hosted with Google, I can use [gmail.com](https://mail.google.com) to access it from anywhere (although it never came to that).

My [paid work](https://faredge.com.au) is mostly in my office.
When I'm working from home, I use Remote Desktop Connection to connect to my work computer - which is available on every Windows PC since Windows XP. 
My connection to the work network is an IPsec VPN via my [Mikrotik router](https://mikrotik.com), which wasn't affected.
I use a softphone app called [MicroSIP](http://www.microsip.org/), which needs a USB headset and a few minutes of configuration.

One day I used my [wife's laptop](/2017-09-21/Tear-Down-Acer-Spin-15.html), and then moved to my [son's desktop](/2016-07-16/How_to_Upgrade_an_Old_Computer.html) for the next few days. 
In both cases, I connected up my second monitor.

<img src="/images/Restoring-From-Backup/alternate-working-environment.jpg" class="" width=300 height=300 alt="Alternate working arrangements - my Son's computer" />

There was plenty of stuff I couldn't do (eg: move emails out of my inbox, write this blog, work on [Terninger](/tags/Terninger-Series/), write parish council minutes) for a week or so, but they waited.


### 1. Acquire New Hardware

Once I decided my laptop was unusable, I started looking for a replacement.
I found Lenovo was running a special on ThinkPads. 
These were available for under AU$800, for immediate delivery, and had the highly desireable feature of not crashing every 30 minutes.

Unfortunately, I had almost placed an order for the [14" model](https://www3.lenovo.com/au/en/laptops/thinkpad/thinkpad-edge/ThinkPad-E470/p/22TP2TEE470) on my dying laptop when it crashed.
A few hours later (after I'd attended to important tasks like getting my kids to school and answering work emails), I tried to order it again, only to find it was out of stock.

Bugger.

Instead, I ordered the [15" model - ThinkPad E570](https://www3.lenovo.com/au/en/laptops/thinkpad/thinkpad-edge/Thinkpad-E570/p/22TP2TEE570).
Which was bigger, heavier, uglier and cost $50 more.
But I'll live with it.

One bad point was that $800 doesn't get you an [SSD](https://en.wikipedia.org/wiki/Solid-state_drive), my intention was to swap the 1TB HDD out and put the SSD from my old laptop in.

Otherwise, it's a business laptop (albeit a low end one) so it has features I find useful:

* Wired ethernet port
* Extra memory slot (I can upgrade from 8GB to 16GB easily enough) 
* Full sized HDMI port
* VGA port (for plugging into ancient data projectors)
* Unpopulated M2 slot (can add a second disk)
* Easy to access internals


### 2. Check My Backups are Working

I've said before that [hardware can be replaced, but your data cannot](/2017-06-13/How-to-Backup-Your-Computer.html).
I checked my laptop backups were all OK:

* CrashPlan was up to date
* File History appeared to have files
* My last full disk image was from a week or so ago

As I was about to delete everything on my old laptop SSD to re-use it in the new laptop, I did a disk image of it using [Sysinternals Disk2VHD](https://docs.microsoft.com/en-us/sysinternals/downloads/disk2vhd).
This gave me a complete and perfectly up to date backup of my old laptop (and 4 backups in total).


### 3. Install the New Laptop

I started my new [ThinkPad E570](https://www3.lenovo.com/au/en/laptops/thinkpad/thinkpad-edge/Thinkpad-E570/p/22TP2TEE570) up once, just enough to link my Microsoft Account to it (so that its license was in the cloud).
That slow experience was enough to remind me why I always use an SSD.

I swapped the 1TB HDD out, and installed the SSD.
Then loaded the current version of Windows 10 (version 1709 - the Fall Creator's Update - had been release a week before) from scratch, destroying everything on the SSD.
And waited overnight for the usual round of updates (even for a two week old OS)!

<img src="/images/Restoring-From-Backup/hdd-out-ssd-in.jpg" class="" width=300 height=300 alt="Out with the HDD, in with the SSD!" />

You can mount any VHD using the *Disk Management MMC Snap-In* -> *More Actions* -> *Attach VHD*.
I tend to access it via right click the *Start Menu* -> *Computer Management*.
Once mounted (over the network in my case), I used the apps from my old laptop as a guide to download and install.

The following is a list of places apps commonly get installed:

* C:\Program Files
* C:\Program Files (x86)
* C:\Users\username\AppData
* C:\Users\username\AppData\Roaming\Microsoft\Windows\Start Menu
* C:\ProgramData

I spent a Saturday downloading and installing around 20GB of apps and updates (on and off through the day).
That's much more than most people would need - I installed [Visual Studio](https://www.visualstudio.com/) (~8GB) and [Logos Bible Software](https://www.logos.com) (~7GB), which make up the bulk of my downloads.

And then I needed to enter account details for most of these apps.
All those details were recorded in my [KeePass](https://keepass.info/) password database.


### 4. Restore Files From Backup

Although I had 3 separate backups of my old laptop, I didn't use them.
The only one I needed was the VHD disk image.

I maintain a crazy number of backups ([and recommend others do the same](/2017-06-13/How-to-Backup-Your-Computer.html)), but my actual SSD was OK.
It was the laptop it was in which had problems.
Removing the SSD from the laptop meant all my precious data was accessible again!

<img src="/images/Restoring-From-Backup/file-copy-vhd-to-ssd.png" class="" width=300 height=300 alt="From the Backup VHD to the new laptop." />

With the VHD mounted, this consisted of a giant copy and paste of all my Documents.

I decided to make use of [OneDrive](https://onedrive.live.com/) for all my Documents (recently acquired from an [Office365 subscription](https://products.office.com/en-au/office-365-home)) to keep my documents, as another backup.
I'm aware Microsoft can see all my stuff, but I a) prefer an extra backup over the potential loss of privacy, and b) I can still use my Local Documents for things I want to keep private, and c) I have an encrypted VHD on my computer for really sensitive things.


### 5. Keep Installing Things I Forgot

At this point, all my critical apps are running.
KeePass, email (with [certificates](/2017-01-02/SMIME-Email-and-Yubikey.html)), web browsers, Office, Visual Studio (and other development tools), DropBox, media players, 

I expect I'll need to keep on installing extra stuff (as required). 
And entering account details into apps.
And tweaking settings so programs do what I'd like.
You never re-install everything (and you probably don't want to either - get rid of the cruft!)


**GPG Private Keys**

One notable drama I had was my [KeyBase](https://keybase.io) GPG key.
My other keys were backed up and got re-imported without a problem, but KeyBase was nowhere to be found.
It wasn't in my password database, nor in my encrypted disk with my other GPG keys.

I mounted the VHD disk image and copied everything from my old GPG data folder (`C:\Users\username\AppData\Roaming\gnupg`) to my new computer.
That allowed me to export the key and save it with all my others. 



## Conclusion

A computer crash sucks.
Losing data sucks more.
Restoring from backups is painful, but much better than the pain of losing data.

I didn't need to delve into my backups (this time); I'm sure glad I have them.

Make sure you have a backup (or three). 
And make sure it's working **before** you need to use it.
 
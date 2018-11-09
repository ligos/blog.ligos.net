---
title: Repairing Storage Spaces After a Drive Failure
date: 2017-12-11
updated: 2018-11-10
tags:
- Crash
- Hardware
- HDD
- Hard Disk
- Storage Spaces
- Windows 10
categories: Technical
---

Backup, delete, and restore works wonders.

<!-- more --> 

## Background

My [home media server](https://loki.ligos.net) recently suffered a [CPU & Motherboard failure](/2017-12-02/Recovering-From-A-Dead-CPU.html).
This server uses [Windows Storage Spaces](https://technet.microsoft.com/en-us/library/hh831739&#40;v=ws.11&#41;.aspx) to make 4 x 1TB hard disks into a single 2TB array, with 2 way mirroring.
This helps with read performance a bit, but is mostly in place so that I can survive a drive failure.
It's like RAID, but managed by Windows instead of system firmware.


## The Problem

As part of my [CPU repair efforts](/2017-12-02/Recovering-From-A-Dead-CPU.html), I managed to break [Storage Spaces](https://support.microsoft.com/en-us/help/12438/windows-10-storage-spaces).
It thought that one of the four disks were unavailable.

<img src="/images/Repairing-Storage-Spaces-After-Drive-Failure/storage-spaces-badness.png" class="" width=300 height=300 alt="Storage Spaces doesn't like missing disks." />

Some further troubleshooting revealed that the system firmware wasn't recognising the disk either.

After breaking my CPU and motherboard, I was rather unimpressed that I'd also destroyed a hard disk.


## Storage Spaces Background

Microsoft made a big song and dance about Storage Spaces when it was released with [Windows Server 2012](https://technet.microsoft.com/en-us/library/hh831739&#40;v=ws.11&#41;.aspx).
My first impressions were from the server space, and they were mostly positive (servers with arrays 32 or 64 x 3TB SATA disks for very high performance and redundancy).
From a consumer side, they replaced the buggy but popular [Home Server Storage](https://en.wikipedia.org/wiki/Windows_Home_Server) *Drive Extender* product.

At release, reviews were pretty standard for a version one Microsoft product: [decent but with rough edges and gotchas](https://arstechnica.com/information-technology/2012/10/storage-spaces-explained-a-great-feature-when-it-works/).
The biggest gotcha, which I believe remains until today, is Storage Spaces will make a pool read-only if it gets into trouble.
This has the unfortunate side-effect of not letting you fix any problem with the pool (read-only does that).

In server 2012 R2, [tiering](https://technet.microsoft.com/en-us/library/dn387076&#40;v=ws.11&#41;.aspx) was added, where you could combine SSDs and HDDs for large capacity and high performance.
But it was only available on server SKUs.

And then there was nothing.
Everything went quiet.

Storage Spaces seemed to get minor improvements in the Windows 10 updates (I was prompted after one update to upgrade my pool and was warned my array wouldn't be readable by older version of Windows).
But there was little song and dance, and few people writing about it.

Well, here's my experience.



<small>(Aside: It seems in Server 2016, it's now [Storage Spaces Direct](https://docs.microsoft.com/en-au/windows-server/storage/storage-spaces/storage-spaces-direct-overview), which isn't just multi-disk arrays, but arrays which span multiple servers.
Which is definitely not meant for ordinary consumers).</small>



### Rules for Storage Spaces (home use)

Based on my research and experience, I came up with a few simple rules so I wouldn't get caught out by the gotchas.
Consider this my Storage Spaces best practises guide (for whatever that's worth)!

**1. Don't over-provision your pool**. 
That is, don't make your pool 10TB when you only have 2TB worth of disks. 
When you exceed your actual capacity, the pool will go read-only, with the only recourse to add more disks.
I slightly under-provision to make sure I don't get caught out.
That is, my pool is *1.79TB* but I have capacity for *1.8TB*.
(Expanding a pool by adding new disks is quite easy, so there's no real reason I can see to over provision).

**2. Have backup storage capacity available**.
If Storage Spaces thinks things are looking bad, it will attempt to redistribute data off a bad disk. 
If it decides things have gone horribly wrong, it will make your pool read-only.
At this point, you can usually read your data, but you need somewhere to copy it before troubleshooting and fixing Storage Spaces and your remaining disks.
This implies backup storage capacity equal to your pool.
(This could be on a bunch of USB disks, as long as you have enough around).

**3. If possible, have a cold spare disk**.
Two is even better.
Many of the problems you can run into with Storage Spaces can be resolved by adding a new disk or two.
And it will automatically redistribute data or expand your pool.
This also implies one or two spare SATA ports, which can be difficult to arrange with consumer motherboards (USB3 can be used temporarily, my experience with USB3 pools is they don't work very well).

**4. Don't use parity, mirroring only**.
The early reviews said [parity was very slow](https://arstechnica.com/information-technology/2012/10/storage-spaces-explained-a-great-feature-when-it-works/3/).
RAID5 and 6 are still pretty popular in the consumer space, because you get some redundancy at minimal cost.
However, with large arrays and disks, it's possible you'll get an [error when your array is rebuilding](http://evadman.blogspot.com.au/2010/08/raid-array-failure-probabilities.html) (it might be unlikely, but 1% is still a big gamble with critical data).
If that happens your array cannot rebuild.
All your data is gone.
(In other words: RAID5 isn't safe for use these days).
Oh, and all Microsoft's high end servers do triple mirroring; so safe to say parity just isn't a good idea these days.

**5. (Added 2018-11-10) Don't re-use old disks without wiping first**.
Storage Spaces magically knows what disks are in any pool based on metadata stored on each disk.
That's how it knows which disks are in a pool, and can tell you everything about a pool with just one disk available.
Unfortunately, it appears if you re-use disks from different pools, bad things can happen.
So, whenever adding disks to a pool, make sure you [wipe them first](https://dban.org/).
(See Štěpán's unfortunate story in the comments for all the details).


The unfortunate consequence of these rules is you need about three times the number of disks as compared to not using Storage Spaces.
That is two disks to get benefits of mirroring, and another disk as a backup.

Of course, the whole point of Storage Spaces is improved resiliency and reliability, so that shouldn't be a big surprise.



## How to Fix It

Back to my problem at hand.

I checked Windows Event Log and found that Storage Spaces thought a disk had failed and was "retired".
It tried to redistribute data off the bad disk for a while, and then went read-only (probably because of further errors from the bad disk).

<img src="/images/Repairing-Storage-Spaces-After-Drive-Failure/storage-spaces-disk-error.png" class="" width=300 height=300 alt="Error from Storage Spaces. Seriously, that's one of the best error messages I've ever seen!" />

<img src="/images/Repairing-Storage-Spaces-After-Drive-Failure/storage-spaces-disk-retired.png" class="" width=300 height=300 alt="And that's the end of my disk." />

[Link to error message](/images/Repairing-Storage-Spaces-After-Drive-Failure/storage-spaces-disk-error.txt)


### 0. Make a Backup

At this point I thought I had genuinely broken a disk.

And I didn't have a spare at hand (breaking one of my Storage Spaces rules, woops)!

I didn't want to take any chances, so I started copying everything I could off the pool.
I had two 1TB backup disks (one using [File History](https://support.microsoft.com/en-us/help/17128/windows-8-file-history) and the other for [Crashplan](https://www.crashplan.com/en-us/) (although [not for long](https://www.crashplan.com/en-us/consumer/nextsteps/)) and [full disk images](/2016-01-24/System-Image-Backups-With-Wbadmin.html)) plus an external 1TB USB disk available to me, so capacity wasn't a problem.

It took a few hours to copy everything.

Although the Pool was read-only and marked as "critical", there was no problems reading from it.

And then I made an extra copy of my family photos to an external USB drive, just to be sure.


### 1. Delete the Pool

At this point, my only option was to delete the pool so I could troubleshoot the individual disks.
And, hopefully, rebuild it with good disks.

There's a *Delete Pool* option in the control panel, which does exactly what you think it would.


### 2. Identify and fix the Problem Disk

Storage Spaces and Windows had clearly identified the problem disk with model number `ST31000524NS` and serial `9WK1D3JK`.
Unfortunately, all my disks are mounted such that I couldn't see any identifying information at all.
And I didn't particularly want to play a guessing game.

I restarted and looked at the computer firmware.
It listed each disk connected to each SATA port.
I had 8 devices connected, but only 7 were listed.
And port 4 was missing!

Turn the computer off.
A few minutes of tracing cables around.
Suspect disk identified!

I completely unplugged it (no SATA, no power) and checked it wasn't listed.
Then plugged power in: it was spinning, which is a good start.
Then I swapped the SATA cable: firmware was suddenly able to see the disk again!

Back into Windows and I could see all disks listed in Disk Management!

And there was much rejoicing!

<img src="/images/Repairing-Storage-Spaces-After-Drive-Failure/disk-management-blank-disks.png" class="" width=300 height=300 alt="I never thought I would be so glad to see unformatted disks!" />


### 3. Ensure the Disks were OK

After the possibility of disk errors and corruption, I decided a full test scan was in order.
I formatted all 4 1TB disks, and then ran `chkdsk /f /r /b` on them (in parallel of course) to ensure the whole disk could be read successfully.
All passed without problem.

(I'm aware there are [other tools](https://www.hdsentinel.com/help/en/61_surfacetest.html) which do a read-write-read-compare for the whole disk, but I wasn't that paranoid).

<img src="/images/Repairing-Storage-Spaces-After-Drive-Failure/chkdsk-bad-clusters.png" class="" width=300 height=300 alt="Testing for bad sectors..." />


### 4. Re-Create the Pool and Copy Data Back

Confident my disks were now happy, I re-created the Storage Spaces pool.
Remembering my 1st Storage Spaces rule, I provisioned 1.79TB of mirrored space (instead of the true maximum of 1.8TB).

And then bulk copied my data back with `robocopy /r:0 /w:0 /e`.
If *parity* is supposedly slow, mirroring is at least as fast as plain disks: averaging 100MB / sec.

<img src="/images/Repairing-Storage-Spaces-After-Drive-Failure/storage-spaces-restore.png" class="" width=300 height=300 alt="Peak write speed to my pool is 160MB/sec; average is closer to 100MB/sec" />

And then all was back to normal!


## Conclusion

My Storage Spaces rules still hold with the Windows 10 updates in 2017.
Don't over provision, have a cold spare, and you absolutely must have capacity to backup your entire array.
(Which reminds me, I need to get a cold spare).

However, never rule out more fundamental problems: a loose cable.
I suspect if I'd just re-seated the SATA cable while the pool was running, Storage Spaces would have worked everything out on its own.

Oh well.
On the plus side, I did get to test my backups and recovery procedures!


---
title: The Reliability of Optical Disks
date: 2022-04-02
updated: 2024-01-23
tags:
- Backup
- Archive
- CD
- DVD
- BluRay
- Optical
categories: Technical
---

How long will burned CDs / DVDs / BluRays last?

<!-- more --> 

## Background

I just finished an extended series on [Long Term Backups and Archives](/tags/Archiving-Series/).
A major shift in my personal and professional backup strategy is optical media, in particular, BluRay disks.

In 2009, I said goodbye to my DVD based backup strategy, because it was taking multiple disks to do a weekly snapshot of my documents and data.
And photos were already overflowing many DVDs.

[In 2017 my backup strategy](/2017-06-13/How-To-Backup-Your-Computer.html) involved:

1. Cloud based backups using <strike>CrashPlan</strike> BackBlaze.
2. Windows File History backups to a NAS.
3. Copy+Paste archives to external (offline) disks.

Five years later, in 2022, my strategy has changed to:

1. Cloud based backups using OneDrive & BackBlaze.
2. Windows File History to my TrueNAS for particular content that doesn't live on OneDrive.
3. Archives to triplicate BluRay disks, indexed via WinCatalog, two copies stored offsite.

## Goal

Discuss the reasons why I've moved back to optical disks as a key part of my backup strategy.
With particular attention on the reliability of optical disks - BluRay disks and M-Disks.

## History

My oldest backups are from the end of the year 2000, and are now on DVD+Rs.
Originally, they were burned to CD-Rs, but I migrated all my CDs to DVDs at some point and discarded the original CDs.
The oldest CD I can find is from 2003, containing a snapshot of all my documents at that time.
Its hard to tell the oldest DVDs, but I think 2004 or 2005 was when I moved from CDs to DVDs for backups.

Finally, the DVD era came to an end in 2009, giving way to HDDs and the cloud.

<img src="/images/The-Reliability-Of-Optical-Disks/old-cd-and-dvd.jpg" class="" width=300 height=300 alt="CD Burned in 2003, DVD from ~2005" />

What I didn't realise at the time, was that all these CDs and DVDs would become a grand experiment of reliability and longevity.
When I read data from these backup disks in 2021, I had a 100% success rate!

That's a perfect record after being stored for 12-18 years, in semi-controlled conditions (darkness, but no temperature or humidity control) and zero maintenance!

## Discussion

This high reliability is what drove me back to optical disks in 2021 - BluRay disks in particular.

The [45+ year storage requirement for church compliance data](/2021-04-11/Long-Term-Archiving-1-The-Problem.html) made me re-think how my backups would survive in the long term.
I wasn't comfortable with HDDs surviving that long, nor anything stored in the cloud.
Tapes are cheap, but their drives are expensive and my only experience with them is from 2002.
It was only when I tested these CDs and DVDs that I realised optical was a contender!
And further research showed that BluRay disks were readily available at a reasonable price.

So why chose optical disks over the alternatives (tapes, HDDs, cloud)?

As I've mentioned, having **hard data of their long term reliability** was a big factor.
Getting any kind of real world reliability data of storage mediums is really, really hard.
[Backblaze releases HDD stats](https://www.backblaze.com/blog/category/cloud-storage/hard-drive-stats/), which is the only public information I'm aware of.
Otherwise, you have to trust the manufacturer's "mean time between failure" figure.
And, when the time scales you're looking at is 45+ years, there is no real world data because no consumer digital storage technology has been invented for that long (tape have been around longer, but its not aimed at consumers).

So, having a few hundred optical disks of 10+ year age that I could test is a huge plus.
Real world data always trumps theory.

Optical disks are **write once**.
When it comes to storing compliance data, or long term backups that's a big plus.
Because the only way data can be tampered with is by replacing an entire disk (not impossible, but tricky).
While most storage mediums have some kind of "write protect" switch, write once optical media physically  cannot be written to multiple times. 

Optical disks have **less moving parts** than HDDs, and thus less that can break.
A HDD contains the physical media (disk platters), electronics to read said media, and software to make it all work.
If any one of those parts fails, it can be difficult, expensive or impossible to recover data.
Optical disks are just the physical media - the electronics and software are in a separate package (the reader).
If your reader breaks, you buy a new one for $200 and move on.
And if you media fails, well, you're no worse off than with HDDs.

HDDs, especially NAS disks, have an **"always on" assumption** - the disks are always online.
Indeed, the Backblaze data is all about disks that run 24/7.
On one hand, that's great because the NAS can scrub disks to [automatically detect and correct errors](https://openzfs.github.io/openzfs-docs/man/8/zpool-scrub.8.html).
On the other hand, that costs electricity.
And if you ever wanted to take disks offline and store them on a shelf, you don't really know how long they'll survive - unless you plug them in every now and then.

Optical disks, by definition, are **"always offline"**.
Once burned, they must remain stable without any scrubbing, error checking or automation.
They will be stored in a jewel case or a spindle, and will rarely (possibly never) be read.
And yet, the expectation is, that you will be able to read the disks without problem - even with zero maintenance.
Indeed, that was the outcome of my ~15 year experiment!

The write once and offline properties combine for another benefit: **optical disks are [ransomware](https://en.wikipedia.org/wiki/Ransomware) proof**.
As long as your backups are connected to a network and writable, it's possible they could be encrypted and held to ransom (or simply deleted).
That includes NAS servers, and the cloud.
But, because optical disks are offline and immutable, no remote hacker or malware can touch it - the only way they could be held to ransom is via physical theft (very possible, but not the current strategy of Internet Bad Guys™).

Finally, BluRay disks **improved the failure modes** compared to CDs and DVDs.
Their physical spec includes improvements such as a hard coating to reduce scratches, non-organic substrates, improved error correction, and improved track addressing.
See *references* below for several white papers on BluRay physical specifications.
(And I note these are theoretical improvements, only time will tell if they yield greater longevity).

There are certainly **problems with optical disks** though:

Their **capacity** isn't great compared to HDDs (or tape).
In the physical space of two x 4 TB HDDs, you might be able to fit 10 x 12cm optical disks.
The highest capacity BluRays are 128GB per disk, which is around 1.3TB in the same space.
For my purposes, I'm not generating enough data for this to be a problem.
But if you're dealing with 1080p or 4k video, you'll be filling many, many spindles of optical disks each year.

Optical disks are **slow** to read.
Their sequential read and random read speeds are 10-100x worse than even the slowest, cheapest HDD.
My experience is that as optical disks age they become harder to read, which makes them slower still.
So you don't want to be reading from them frequently, or doing a restore with the clock ticking.
Given they're designed as long term media, this isn't a big problem - but something to be aware of.

A big risk with optical disks is they are becoming a **niche technology**.
That is, they aren't as mainstream as they used to be in the 2000s.
Most laptops don't come with optical drives any more, and no one really misses them.
Software and content is delivered by streaming rather than disks.
So, its entirely possible they will go the way of floppy disks and become obsolete and difficult to purchase.
As of 2022, it is possible to buy brand new BluRay readers and media - although I note eBay is your friend if you want to [buy a wide variety of media](https://www.ebay.com.au/b/Blank-CDs-DVDs-Blu-ray-Discs/80135/bn_708330).

Because optical disks are offline media, you really need to **index or catalogue their content**.
That is, without some kind of catalogue you can browse or search, it's somewhere between hard and impossible to find what you need.
And putting 100 disks into a reader, one at a time, and slowly searching each of them really sucks (I tried).
In the 2000s, I never bothered with this, but I've become more disciplined this time around and am using [WinCatalog](https://www.wincatalog.com/) to catalogue all optical media.

Finally, optical disks are more **expensive** than HDDs - at least in cost per GB.
A 4TB NAS branded HDD costs ~AU$160, which is ~4c/GB.
My last BluRay purchase was for 3 x 50 spindles of 25GB disks costing AU$330, which works out to be ~9c/GB.
Obviously, you need a computer for that HDD, a reader for the BluRays, and factor in things like electricity and maintenance - a full total-cost-of-ownership comparison is more complex.
But in raw capacity, HDDs are cheaper.
Note that M-Disc BluRays are around 4x more expensive than regular BluRays, costing ~33c/GB.


## Test to Destruction

Given the primary reason to chose optical media over HDDs is long term reliability, I decided I should put them to the test.
I tested a DVD, 3 brands of BluRays (BD-R disks), and a BluRay M-Disc to destruction.

There are four things that will destroy any kind of media: **light, heat, moisture and time**.

I've already tried **time** (at least for ~15 years) and found CDs and DVDs are pretty resilient!
So I moved onto light and heat (I didn't test against moisture).

My **light test** consisted of placing the disk in an east facing window that would receive ~4 hours of direct sunlight each day.
While this isn't entirely scientific because I wasn't testing all the disks at the same time (some were tested in Summer and others in Winter), it's still a place to start.
I tested all disks this way.

<img src="/images/The-Reliability-Of-Optical-Disks/sunlight-test-window.jpg" class="" width=300 height=300 alt="Sunlight Test: an East facing window" />

My **heat test** is placing disks in a) my car (which is parked such that it has ~4 hours per day of sunlight) which acts as a greenhouse, b) my ceiling cavity (which is not insulated and can reach over 50℃ in Summer), and c) my freezer (which should be around -18℃).
I only tested the BluRay M-Discs for heat.

Updated in January 2024: Note that heat tests expose disks to some indirect light; while the cold test is stored in a dark freezer - I suspect this means the freezer disk will end up lasting longer.
Only time will tell.

**The TL;DR results**: keep optical disks out of direct sunlight and you should be good for a long time.

<img src="/images/The-Reliability-Of-Optical-Disks/tested-to-destruction-dvd-and-bluray-and-mdisc.jpg" class="" width=300 height=300 alt="DVD, BluRays and M-Disc - All Tested to Destruction" />

Results for direct sunlight:

Disk | Days Before Failure | Failure Mode
-----|---------------------|---------------
DVD  | < 90 | Completely unreadable; computer reports no disk when inserted. I didn't check very diligently, so not sure exactly when it failed.
BluRay (Ritek) | 38 days | Some sectors have errors; disk partially readable.
BluRay (Verbatum) | 38 days | Some sectors have errors; disk partially readable.
BluRay (Verbatum M-Disc) | 260 days | Some sectors have errors; disk readable after multiple attempts.

* Note the M-Disc was tested over Winter rather than Summer.

Direct sunlight is definitely something to avoid.
Keeping your optical media in darkness is your number one priority in storage.

Comparing longevity of regular vs M-Disc BluRay media, there's a factor of ~6x difference.
The marketing claims of M-Disc is they should last for "at least 100 years".
If we assume regular BluRays will last for the same 15 years as my CDs and DVDs, then an M-Disc should last ~90 years.
That's not quite what the manufacturer claims, but close enough - and confirms M-Disc media lasts longer.

Others have done similar [test to destruction for M-disc media](https://www.microscopy-uk.org.uk/mag/artsep16/mol-mdisc-review.html) which support my results.

**Tests for heat / cold** started in May 2021, and remain ongoing without failure (the 2021-2022 Summer was nowhere near as hot as previous year, so I suspect this test will continue for another year at least. [Temperature statistics for Sydney](https://reg.bom.gov.au/jsp/ncc/cdio/weatherData/av?p_nccObsCode=36&p_display_type=dataFile&p_stn_num=066037)).

Last updated _January 2024_:

Location              | Has it Failed?  | Days Before Failure | Failure Mode
----------------------|-----------------|---------------------|--------------
Freezer (cold)        | No              | 977+                | N/a
Car (heat)            | No              | 977+                | N/a
Ceiling Cavity (heat) | No              | 977+                | N/a

I'll update this table from time to time, as I check the disks.

The take away is: **keep optical disks out of direct sunlight**; even better in total darkness.
Heat / cold seems to be less critical.

## Always Test

I'm promoting optical media, and particularly BluRay M-Disc media, as a zero maintenance solution for  long term data storage.
However, given enough time, every form of digital media will eventually fail.

As long as we a) have multiple copies of the data, and b) can make new copies faster than failures, all is well.
That means we must have some kind of maintenance schedule in place to detect failures and make new copies.

Data stored on a NAS server has a big advantage here: any NAS will automatically check for errors, and notify if problems are found.
TrueNAS (via ZFS) will automatically correct errors.

But checking optical media for errors cannot be automated ([unless you can afford a robot / jukebox](https://kintronics.com/solutions/optical-jukeboxes-and-libraries/)) because the disks are stored separately to your computer.

Because I'm confident optical media, when stored away from direct light, will survive for 10 years, I'm going to check them every 5 years.
At least until I get some failures, so have some idea of when failures are likely to happen.

## References

* [Wikipedia - Optical Disc](https://en.wikipedia.org/wiki/Optical_disc)
* [Wikipedia - Blu-ray](https://en.wikipedia.org/wiki/Blu-ray)
* [Wikipedia - Blu-ray Disc - recordable](https://en.wikipedia.org/wiki/Blu-ray_Disc_recordable)
* [Hughs News - Authoritative Blu-Ray FAQ](http://www.hughsnews.ca/faqs/authoritative-blu-ray-disc-bd-faq)
* [White Paper Blu-ray Disc Format - 1. A Physical Format Specifications for BD-RE, 5th Edition, January 2018](/images/The-Reliability-Of-Optical-Disks/White_Paper_BD-RE_5th_20180216.pdf)
* [White Paper Blu-ray Disc Format - 1. B Physical Format Specifications for BD-R, 5th Edition, October 2010](/images/The-Reliability-Of-Optical-Disks/BD-R_physical_specifications-18326.pdf)
* [White Paper Blu-ray Disc Format - 1. C Physical Format Specifications for BD-ROM, 6th Edition, October 2010](/images/The-Reliability-Of-Optical-Disks/BD-ROM_physical_format_specifications-18327.pdf)
* [White Paper Blu-ray Disc Recordable Format Part 1 - Physical Specifications, 5th Edition, February 2006](/images/The-Reliability-Of-Optical-Disks/BD-R_Physical_3rd_edition_0602f1-13322.pdf)

## Conclusion

Optical media, and BluRay M-Discs in particular, are the most reliable way to do long term, offline data storage.
CDs and DVDs have lasted for 10-20 years and can still be read successfully.
BluRay media offers disk capacity of 25-128GB, and should have similar longevity.
The claims of special M-Disc media lasting 100+ years seems plausible - unfortunately, it will take another 99 years before we can confirm it!

Anyone who wants an offline, ransomware proof, 20+ year backup should consider BluRay optical media.

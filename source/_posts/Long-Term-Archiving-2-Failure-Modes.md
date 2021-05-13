---
title: Long Term Archiving - Part 2 - Failure Modes
date: 2021-05-13
tags:
- Backup
- Archive
- Church
- Compliance
- Legal
- Archiving-Series
categories: Technical
---

How many ways can a backup fail? Let's count!

<!-- more --> 

You can [read the full series of Long Term Archiving posts](/tags/Archiving-Series/) which discusses the strategy for personal and church data archival for between 45 and 100 years.

## Background

So far, we have a [broad strategy](/2021-04-11/Long-Term-Archiving-1-The-Problem.html) for making long term backups and archives.

To implement a viable technical solution, we need to be aware of why it **won't** work.
That is, we need to think of all the ways backups might fail over 100 years.
That is, we need to know exactly how robust we need to be.

That is, [failure modes](https://en.wikipedia.org/wiki/Failure_mode_and_effects_analysis).

## Goal

Define likely (and unlikely) failure modes for data storage over 45 - 100 years.
Remembering that over 100 years, even very unlikely failures become possible or even common.

I'll discuss the various failure modes below, and give some examples.

### Insta-Fails

The first group I call "insta-fail".
Which means, your backup was never viable in the first place.

Many other failure modes involve time: they become more likely over time, or your data degrades over time.
Insta-fails are instant - your data is gone in the blink of an eye!

Examples:

Your backup **didn't actually work**. 
Perhaps the backup disk wasn't plugged in. 
Perhaps you didn't run a manual process. 
Perhaps you don't even have a backup! 

If you never had a backup to start with well... you'll have nothing tomorrow, let alone in 45 years. 
Insta-fail!

A variation: your backup **didn't include the files you need to restore**. 
Perhaps you didn't configure your backup correctly (missing includes, wrong excludes).
Perhaps some files couldn't be copied because they were in use - remember that important databases and financial records are often in use 24/7.

If you never backed up the files you need well... you'll have nothing to restore tomorrow, let alone in 45 years.
Insta-fail!

Is your backup encrypted? Make sure you never **lose the password / encryption key**!
Modern encryption is built so that you need the exact password to decrypt your data - one character wrong is the same as everything wrong.
If you forget the password to your backup, or lose the paper you wrote it down on, or can't access your password manager - your backups are gone.
Well, the data might be perfectly preserved, but you'll never be able to read it.
Insta-fail!

This brings up a tricky question when storing data for 45+ years: should you encrypt it or not?
On one hand, there is almost certainly personally identifiable information in your backup, so you should encrypt it.
On the other hand, how do you backup the password to your backups?
Clearly you can't use your normal backups for the password, but how do you make sure the password survives 45+ years?
I'll discuss that in more detail in a future post.

There's a joke that goes: **"backups never fail, but restores do"**.
That's a jaded way of saying "restoring data is the important thing, backups are an incidental process along the way".
Don't forget to test you can restore from your backups on a regular (if infrequent) basis.


### Media Failure

Media failure is the most common thing people think of when storing data for a long time.
Your hard disks, or CDs, or tapes, or whatever slowly degrade over time to the point where they can no longer be read reliably.

However, your backup needs to survive a long time before the media itself cannot be read!
There are a few variations of this one, so lets think about examples:

**Your backups are lost**.
Perhaps your backups are on some USB hard disks, and you misplace them in some "safe" place.
Or you move house once, or twice, or thrice and they disappear (maybe into the trash, maybe into... well... somewhere).
Or they are filed into some system which makes no sense and they end up in some giant warehouse with the wrong label and no hope of finding them without inspecting all 1,000,000 items.

**Your backups are stolen**.
A variation on "lost" - you are robbed and your precious backup on USB disk that is connected to your laptop is pilfered along with your computer.
Remember that thieves don't discriminate: computer gear is computer gear is computer gear, and backups look just the same as any other computer gear.

**Your backups are destroyed**.
This is "lost" into tiny little bits.
Fire, flood, earthquake, tornado, and so on.
Note that it doesn't need to be a catastrophic event - a car crash while taking your backup hard disk home might be just as destructive as a fire.
I've had a number of USB disks fail simply because I dropped them once too often.
And if you are taking your backups home or off-site (which is a good thing) accidents become more likely.

In all these cases, if your backups are on physical media, you need to have that media in your hands to get the data off it.
If it's lost, stolen or destroyed - you have no backup.

**Your backups survive for years, but simply degrade over time**.
OK, now we're into the 45+ year realm!
Nothing bad happened, but given enough time, even the best media will fail.

It's an open question how long this will take, and depends on lots of environmental factors.
But hard disks are rated for, say, 100,000 hours of use - which is around 11 ½ years.
How might that change if the disks are in cold storage and never powered up?
What about solid state disks?
Or tapes?
Or optical media?

I've put together a basic table of different media and approximate life time, based on the Internet.
The "Refresh Interval" is the frequency you'd need to power up media and "scrub" for errors to achieve the "Life Time" reliably.
Note that I found it quite difficult to find hard data on long term media life time; most is speculation and guess work, with the occasional anectdote.
The best source is [BackBlazes' hard drive report](https://www.backblaze.com/blog/backblaze-hard-drive-stats-for-2020/), but that is for running and active drives, not cold storage.

This reflects a cold, hard reality: **no consumer media has survived 45 years, because none of this media was available 45 years ago**.

Media                       | Life Time    | Refresh Interval | Sources
----------------------------|--------------|------------------|----------
Hard Disk                   | 8-20 years   | 1-2 years        | [Source 1](https://www.reddit.com/r/DataHoarder/comments/ccwl6b/shelf_life_of_cold_ssds_vs_hdds/), [Source 2](https://lifehacker.com/how-long-can-a-hard-drive-hold-data-without-power-5808858), [Source 3](https://www.extremetech.com/computing/170748-how-long-do-hard-drives-actually-live-for), [Source 4](https://forums.tomshardware.com/threads/hard-drive-shelf-life.677074/), [Source 5](https://superuser.com/questions/284427/how-much-time-until-an-unused-hard-drive-loses-its-data), [Source 6](https://www.techjunkie.com/how-long-does-backup-media-last/), [Source 7](https://serverfault.com/questions/51851/does-an-unplugged-hard-drive-used-for-data-archival-deteriorate)
Solid State Disk / SD Card  | 5-10 years   | 6-18 months      | [Source 1](https://www.reddit.com/r/DataHoarder/comments/ccwl6b/shelf_life_of_cold_ssds_vs_hdds/), [Source 2](https://lifehacker.com/how-long-can-a-hard-drive-hold-data-without-power-5808858), [Source 3](https://www.techjunkie.com/how-long-does-backup-media-last/)
Optical (CD / DVD / BluRay) | 7-30 years   | None             | [Source 1](https://www.techjunkie.com/how-long-does-backup-media-last/), [Source 2](http://thexlab.com/faqs/opticalmedialongevity.html), personal experience
Magnetic Tape               | 15-50 years  | ???              | [Source 1](https://www.techjunkie.com/how-long-does-backup-media-last/), [Source 2](https://en.wikipedia.org/wiki/Linear_Tape-Open)

A short story about the "personal experience" for optical media:
I made backups from 2000-2010 on CDs and DVDs (stopping when my weekly backups exceeded capacity of single layer DVDs), burning data and leaving the media on spindles.
There was zero maintenance - disks went on spindles each week and were left in a cupboard.
Occasionally, I made two copies and stored the other copy at my parent's house.
I dug these disks out recently and was able to read *every* disk, except one from 1999!
There was definitely some degradation of older disks (reading was very slow), but only one hard failure.

So, ~50 CDs and DVDs tested out of ~200 burned.
Age: 10-20 years.
No maintenance.
No special environmental control: I kept them away from direct light and water, but temperature would range from 10°C to an only-in-Australian-Summer 40°C.

And 99.9% success!


### Cloud Provider Unavailable

Cloud providers like AWS, Azure and Backblaze claim crazy reliable data availability of 99.9999% or more.
And when they spend billions of dollars each year, they can probably do a better job than I can on a budget of $500.
But there are a few failure modes that can catch you unaware.

**Your Internet is down**.
Pretty obvious that you can't access the cloud when the Internet is down.

**Your Provider has a Temporary Outage**.
It's possible the provider has a serious network outage - though this is much less likely because they have multiple redundant connections.
What is more likely is an application issue, or an authorisation problem, or some other transient outage.
These usually only last a few hours, and only happen once or twice a year, but they do happen.

**Your Cloud Provider Disappears Forever**.
Yes, the cloud can disappear.
And much faster than you think!
Companies go out of business all the time, or decide cloud backups [aren't a profitable business model](https://web.archive.org/web/20170823001341/https://www.crashplan.com/en-us/consumer/nextsteps/).
While it is unlikely Amazon or Google or Microsoft will go out of business, over a 45-100 year time line who knows what might happen!
Remember, "the cloud" is a trendy way of saying "renting someone else's server" - rental agreements last a few years at most, not 45+ years.

**Your Cloud Account is Unavailable**
Personally, I think this is the scariest thing about using the cloud for long term archiving.
If you forget or lose your account password, your data is gone.
If the provider decides to [block access to your account](https://arstechnica.com/gadgets/2021/02/terraria-developer-cancels-google-stadia-port-after-youtube-account-ban/), your data is gone.
If a government takes legal action against a cloud provider, your data may be seized and unavailable.

Basically, there are things completely outside of your control that could block access to your data in the cloud.


### Media Obsolete

Technology gets old very fast.
And the new and shiny quickly replaces last year's amazing storage tech.
When you're thinking about a 45+ year time scale, whatever you use to store data today is definitely, 100%, without a doubt going to be obsolete when you really to read it.

[Floppy disks](https://en.wikipedia.org/wiki/Floppy_disk) are a nice example.
I haven't touched a floppy disk since... I can't remember!
And I don't own a computer capable of reading one any more.
If my backups are on floppy disks, I'm in trouble.

I have backups on [optical media](https://en.wikipedia.org/wiki/Optical_disc_drive) (CDs and DVDs).
Optical drives are not as popular as they once were, but some (not all) of my computers still have optical drives.
Perhaps optical drives will go the way of floppy disks in 10 years.

[SATA](https://en.wikipedia.org/wiki/Serial_ATA) is the standard interface for consumer hard disk drives.
20 years ago it was [IDE with 40 pin ribbon cables](https://en.wikipedia.org/wiki/Parallel_ATA).
35 years ago there were [ST506 controllers and MFM drives](https://en.wikipedia.org/wiki/ST506/ST412) - and yes, I remember using them when I was a kid.
[NVMe](https://en.wikipedia.org/wiki/NVM_Express) is becoming more popular, perhaps it will surpass SATA in the next 40-ish years, rendering all today's HDDs unreadable?

[USB](https://en.wikipedia.org/wiki/USB) is everywhere today.
But will it be in 40 years? 60 years? 100 years?
You need a laptop or desktop device to read a USB disk; but mobile phones and tablets are more popular, yet cannot read a USB disk.
If pocket computers completely replace desktops and laptops, how will you read your precious backups?

Using a [NAS appliance](https://en.wikipedia.org/wiki/Network-attached_storage) with an [Ethernet](https://en.wikipedia.org/wiki/Ethernet) UTP cable to store your backups?
I remember attending LAN parties in the mid-90's with 10BASE2 coax cable.
Wired ethernet seems to have stagnated in the consumer space recently, perhaps your next NAS will be WiFi only (I hope not, but who knows)!

Pretty much every storage technology in common use today didn't exist 45 years ago.
If you're storing data for 45+ years, be ready to migrate from old to new technology.

Fortunately, all my doom-saying isn't all that bad.
Almost all the tech I've mentioned above is still available, it just might require some eBay purchases to acquire niche equipment.


### Application Unavailable

Data can be available in open or proprietary formats.
Open formats like PDF, RTF, JPG or MP3 are readable by many applications.
**Proprietary files** are only readable by one application.
If you can't use that app any more, the data is also gone.

This kind of thing is very common in medical or industrial settings, less so for every day documents, pictures and videos.
So this is more applicable to businesses using niche or specialised software.

I looked through some old backups from late 90's and found `pm6` files.
For various reasons, most of my work in high school was done using [Adobe PageMaker](https://en.wikipedia.org/wiki/Adobe_PageMaker).
The last update for PageMaker was in 2001; I don't have the disks any more, and even if I did, Wikipedia says it doesn't work on Windows 10.
So I have no way of reading those files - that data is gone.

An insidious form of this is **proprietary backups**.
Imagine you purchase "Acme Backup", which saves your data in `acme` files that only it can read.
One day, Acme goes bust and your backup product is no longer supported.
No problem, you continue using Acme because "not supported" doesn't mean "it stops working".
But eventually, after a few computer upgrades it does stop working: Acme Backup is not compatible with Windows 2040.
Even if your `acme` backups files are available, you lack the software to restore from them.

Perhaps the proprietary application is still available, but you just lost the **license code** required to use it.
Best case, you need to buy a new license.
Worst case, the application is not sold any more and you're stuck.


### File Format Obsolete

This is a variation on *Application Unavailable*, but 100x worse.
Not only is the application obsolete, the data format is also obsolete.
That is, **nothing** out there can read your files.

Let me say, this is really, really, REALLY unlikely to happen.
Applications almost never remove support for such core functionality.

But imagine if someone came up with something better than JPEG - images could be stored without any loss of quality, in just a few kB, encoded and decoded with minimal CPU usage.
It is such a good format that everyone stops using JPEG.
Cameras, phones, even the Internet all switch to this magical new image format.
Eventually, application developers decide supporting JPEG is too difficult, too time consuming, and brings no benefit.
So they remove JPEG support.
And all those JPEG family photos from the early 2000s are unreadable. 

(Note that we already tried to come up with [a better JPEG](https://en.wikipedia.org/wiki/JPEG_2000) - it didn't take off).

Some of the core standard file formats include: JPEG, MP3, ZIP, PDF, UTF8 text.
And let's be honest, none of them are going to be obsolete any time soon.
But 100 years is a long time.

Perhaps the file system on your disk isn't supported any more.
NTFS, ZFS, UFS, Ext4 are all in common use - and again, support for these isn't likely to disappear.
But 100 years is a long time.

One real world example of an obsolete standard (albeit not a file format) is SSL.
The thing everyone calls SSL is actually TLS - [Transport Layer Security](https://en.wikipedia.org/wiki/Transport_Layer_Security).
The current version of TLS is 1.3.
Version 1.2 is also in common use.
And 1.0 and 1.1 are considered a security problem, so many servers are disabling them.
Poor old SSL is even older, being deprecated in 2015 as a security hazard.

So, if you're using an old version of [Netscape Navigator](https://en.wikipedia.org/wiki/Netscape_Navigator) from the late 90's, you cannot access most of the Internet.
And if you're sticking to Android 4, Windows XP, or any version of Internet Explorer before 11 (so 15-ish years ago), you're in the same boat.
All those backups in the cloud are inaccessible!


### Maintainer Unavailable

People are a key point of failure in any organisation.

It could be as simple as someone leaves the organisation and doesn't leave passwords required to access backups.
Or that person was responsible for the backup procedures, and never bothered to train a successor.
Or that person physically has the backup media.
If the person's gone, the backup may have gone with them.

Perhaps backups are still available, but their content was organised in a very unusual way.
Without the "librarian" who knows how it all works, content is lost in a maze of twisty backup disks, all alike.
Or there's a "computer guy" who just knows how the backups work - only he's gone.

On a long enough time line, the survival rate of everyone drops to zero.
People die.
Sometimes suddenly, sometime with lots of warning.
Either way, any knowledge about backups solely in their head is gone (eg: passwords, procedures, places).

In 45 years, I don't expect to be maintaining backups at Wenty Anglican.
In 100 years, I expect to be with the Lord.

Without key people, backups may be totally useless.
They need to pass their knowledge, expertise and passwords onto a successor.


### Fundamental Changes

Finally, there might be fundamental changes to undermine long term backups and archives.
Things that break our assumptions about how the world works.

The **English language will change**.
Probably not so much that we can't understand today's documents in 2121, but probably enough that they will be confusing or ambiguous.
A few hundred years and it's quite possible the English of 2021 won't be recognisable or understandable.
English might end up as a dead language.

Perhaps the **Internet will change** radically.
Maybe someone will undermine how HTTPS works and "the cloud" will no longer be a secure place to store data.
Maybe the global Internet will break into multiple Internets that can't access each other - China is already trying pretty hard to segregate itself.
It would suck if your cloud backups were in the other Internet, or behind a great firewall.

Perhaps **digital storage isn't a thing** any more.
It could be due to a [shortage of materials and chips](https://en.wikipedia.org/wiki/Chip_shortage), or a lack of rare earth materials used in high-tech devices, or simply storage stops getting cheaper.
Maybe a significant global event (pandemic anyone?) makes digital devices a luxury item and we can't afford to use them for archives.

**[Electricity](https://en.wikipedia.org/wiki/Electricity_generation) is rather fundamental** to digital storage - heck, even hard copies rely on printers, copiers and lighting.
No electricity, no digital anything, and definitely no backups.
One hundred fifty years ago, in 1871, electricity was well understood from scientific and engineering points of view, but not widely available to general population.
One hundred years ago, in 1921, electricity was a luxury that was available to upper classes only.
It seems unlikely that the power would go off permanently, but we need to remember its a relatively recent invention when trying to store data for 100 years.

COVID has reminded us that **disasters, natural or otherwise,** can cause significant social and economic disruption which may impact long term backups.
Few will maintain archives or keep passwords if they're in fear of their lives!
COVID has turned into a long disaster, lasting several years (even when vaccines being deployed at break neck speed).
While an earthquake or flood has an immediate impact, a pandemic is longer and more drawn out.
And requires a different approach to ensure archives survive.

(In case you're wondering, I'm not going to consider how to mitigate these fundamental changes. I'm just listing them to illustrate how hard long term data storage is).


## A Word About Hard Copies

I've focused on digital media all through this article.
But it's worth thinking how the failure cases apply to physical hard copies of documents (ie: paper).

Many failure cases are specific to digital data, and just don't apply to hard copies:

* Insta-fails
* The cloud: closest analogy is renting a storage unit.
* Media obsolescence: paper from 500 years ago is just as readable today.
* Software obsolescence: the mk1 eyeball is all you need to read.
* File format obsolescence: papers collected in a folder hasn't really changed.

Some failures apply equally to both:

* Media failures: paper degrades just like disks do.
* Fundamental changes: shifts in language are the same for digital or hard copies.

Hard copies are affected by some even more:

* Maintainer unavailable: without a good index, hard copies are really hard to search through. Even slow computers can search hundreds of documents per second. If your librarian is missing, your hard copies are a needle in a haystack.
* Natural disasters: paper is very vulnerable to moisture, light, fire, flood, etc. Storing them is trickier than digital.

The biggest disadvantage of hard copies is: they are **hard to copy**.
Computers are really good at making perfect copies over and over, really quickly.
That's why the solution for digital archiving is to just make lots of copies and compare them every now and then.
Hard copies are physically bigger, harder to copy and trickier to compare.
So although you can apply the same principals, its 100x more difficult in practice.


## Conclusion

Well, there certainly are a lot of ways data can be lost!
(And I'm not even claiming this is an exhaustive list).

I haven't really discussed how to stop these events, but that will come in the future.
And I expect many readers will already have answers in mind.

For now, let's just admit many things could go wrong.

Some are entirely within our control (so letting them go wrong is just dumb), others are predictable and preventable with appropriate maintenance, others are outside our control and we need to take special steps to mitigate them.
And some are really tricky to deal with - indeed, so hard that I simply can't address them on my $500 annual budget.

**Next up**: what data I'm interested in collecting (and what I'm not), and how I'll collect it.

[Read the full series of Long Term Archiving posts](/tags/Archiving-Series/).


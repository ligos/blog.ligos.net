---
title: Long Term Archiving - Part 1 - The Problem
date: 2021-04-11
tags:
- Backup
- Archive
- Church
- Compliance
- Legal
- Archiving-Series
categories: Technical
---

100 Years is a long time to store data.

<!-- more --> 

You can [read the full series of Long Term Archiving posts](/tags/Archiving-Series/) which discusses the strategy for personal and church data archival for between 45 and 100 years.

----

> TL;DR: [skip to the Implementation (part 6)](/2021-10-29/Long-Term-Archiving-6-Implementation.html).

----

## Background

In mid 2020, right as our church was working through what needed to happen to be COVID Safe and resume face-to-face meetings, we got a nasty surprise: 

We have to keep records relating to "Safe Ministry" **forever**.
That is, any records or documents that might be needed for a court case involve sexual abuse cannot be deleted.
Ever.

> Reliable and comprehensive Safe Ministry Records will be an important part of building a case against an alleged abuser of children in our churches, so it is vital that the correct information is recorded in a manner that is able to be kept **indefinitely** – in other words no Safe Ministry Record information can ever be deleted or thrown away. [Source](https://safeministry.org.au/safe-ministry-records-the-basics/)

After some reading of the [Royal Commission into Child Sexual Abuse](https://www.childabuseroyalcommission.gov.au/) I found a recommendation for storing records for a minimum of 45 years:

> We also recommend that institutions that engage in child-related work retain, for at least 45 years, records relating to child sexual abuse that has occurred or is alleged to have occurred. This is to allow for delayed disclosure of abuse by victims and to take account of limitation periods for civil actions for child sexual abuse (see Recommendations 8.1 to 8.3).

I asked: "is there any government or diococen assistance?" 
And found the answer is "No".

My initial response was: *"Are. You. Serious??!?!?
There is no way this is possible!"*

And the problem was parked until we had more breathing room post-COVID.

Well, in Sydney, we're doing pretty well with COVID at the moment, so time to deal with this storing-data-forever problem.


## Goal

My mission (which I have no choice but to accept - yay for government complience) is to develop a long term data archival strategy for [Wenty Anglican Church](https://wentyanglican.org.au).
The data must be readable in 45 years, and is desirable to be readable in 100 years (the approximate lifetime of a person).

This must be accomplished with off-the-shelf technology, implemented by myself in my spare time, be supported by non-technical volunteer users, and has a maximum budget of a few hundred dollars per year.

Bonus points if we are able to search the data and find relevent information in any way other than "trawling through everything year-by-year".

Sub-goal: accomplish the same aim for my own family.
If I can adopt a strategy that works for me, I have some hope of church doing the same.

----

*Aside*: 

Although I'm focusing this series on the technical requirement of "long term data archival", it's important to note that in a church context this requirement is part of wider policies and procedures to ensure the safety of everyone who comes on our property.
That includes church staff, volunteer workers, regular members, occasional visitors, one-off guests, contractors, and anyone else who might walk through our front door (or back gate).
It addresses physical, emotional, and spiritual safety.
It is particularly geared to protect minorities and vulnerable people (who have been terribly abused in church contexts in the past).

That is, this is not a box ticking exercise for government compliance.
It is part of our church's desire to [keep people safe](https://safeministry.org.au/faithfulness-in-service-code-of-conduct/), as we seek to share the good news of Jesus.


## Is This Even Possible?!?

My initial reaction to this requirement of 45+ year data retention was: this isn't possible!

The government is asking volunteer organisations (not just churches) to collect data in a systematic way, store it securely (as many records will identify people; thus raising privacy issues), and ensure it is still available in at least 45 years.

As so much data is digital these days, we need to come up with a digital solution.
Only thing is, 45 years ago (1976) the [personal computer was not a thing](https://en.wikipedia.org/wiki/History_of_personal_computers).
The cutting edge of digital storage was the [cassette tape](https://en.wikipedia.org/wiki/Commodore_Datasette) and could store perhaps 100kB.

In other words, we're being asked to do something that has literally never been done before, because the technology has not existed long enough yet!

However, I'm not one to be dissuaded by "impossible" goals.

While the digital technology has not existed to retain records for 45-100 years, the analog technology certainly has.

My church has paper records going back to 1919 (when the building was completed).
Governments have records going back hundreds of years.
And archaeology has been able to recover documents - OK [clay tablets](https://en.wikipedia.org/wiki/Complaint_tablet_to_Ea-nasir) - from thousands of years ago.

At church, we see [the Bible](https://en.wikipedia.org/wiki/Bible) as the supreme authority in matters of salvation.
It also happens to be a collection of documents that have been handed down over many generations - so a fitting yardstick for my current project!

The New Testament was collected from various sources into its [final form in 325AD at the Council of Nicaea](https://en.wikipedia.org/wiki/Development_of_the_New_Testament_canon).
And while there is plenty of debate how old the original source material is, the New Testament can be no younger than 1700 years, and is likely closer to 1900 years old (the latest material written in ~120AD).
The [Old Testament is messier](https://en.wikipedia.org/wiki/Development_of_the_Old_Testament_canon) (mostly because it's older) but consensus is it was essentially what we have today in 132BC when the [Greek Septuagint translation](https://en.wikipedia.org/wiki/Septuagint) was finalised.
And the original sources must be older (just [how old is a subject of much debate](https://en.wikipedia.org/wiki/Dating_the_Bible) that isn't relevant for my data storage project).

The point is: the Bible is a written document, originally created in an oral culture, written on materials that naturally decay, and often propagated and copied by volunteers.
Yet it has survived remarkably well for around two thousand years.

So storing records for 100 years is certainly not an easy task, but it's far from impossible.


## Strategy

I'll leave the details of long term archiving for future posts.
This is my overall strategy:


**Point 1: the data I store today will outlive me.** 

In 45 years time I'm not likely to be maintaining records at Wenty Anglican.
I might not even be a member there.
Heck, I might not be alive.

So I MUST, without fail, be able to hand data on to a successor.
I need one (or more) people in-training who can take over after I stop looking after the data.

The data itself (however and wherever its stored) must be documented enough that someone could pick up archiving even if I'm not around.
That is, storage needs to be simple, and self documenting.

If someone randomly comes across one piece of the archive (say a hard disk, DVD or cloud backup), they should be able to find their way to other parts of the archive.
That is, even if I disappear without handing on to a successor, the poor archivist who has to take over can piece things together from any one part of the archive.


**Point 2: whatever choices I make now will be wrong in 45 years.**

The technical details of backups and archiving will change over time.
And 45 years is a long time.
The decisions I make today will become obsolete, or wrong, or be superseded.

In 2000, my first backups were on burned CDs.
Later I moved to DVDs.
Then to hard disks and network attached storage.
And eventually the cloud.
Most recently, I've started using BluRay disks.

So I MUST, without fail, take a big step back and review my backups & archives every 10 years.
I need to be prepared to migrate before technologies become obsolete.
I need to look for new and better ways of storing data.
Worst of all, I need to migrate from old file formats to new ones (and I'm really not looking forward to that).

In other words, the technical details will definitely change over time.


**Point 3: as long as one copy is readable, all is well.**

Ultimately, long term archives are a [distributed data problem](https://en.wikipedia.org/wiki/Distributed_data_store).
And that has a well known solution:

1. Make many redundant copies of data. Distributed to multiple locations to prevent systematic failure.
2. Check the copies are still good on a regular basis.
3. When any go bad, make new copies from the good ones.

As long as one copy can be read, the data has survived.

Step 2 is the weak point, because it implies maintenance.
If maintenance is not automated (or at least scheduled) it won't happen.
And, given a long enough time line, all backups & archives will be lost - there is no media that will reliably survive 100+ years (even the 45 year minimum is a stretch).

So I MUST, without fail, have some kind of maintenance program to detect failures and replace them BEFORE all copies fail.

Incidently, this is how the Bible - in particular the New Testament - survived so well.
People just kept making more and more copies of it.
Even though the originals were lost, the copies (of copies, of copies...) survived.


## Future Articles

OK, you've come here not to read about some hand-waving high-level strategy, but concrete technical plans to achieve 45+ year data storage.
In the context of my own personal data, and for Wenty Anglican church (and definitely NOT for some big corporate organisation).

Here's what I plan to discuss in coming posts:

* **[Failure Modes](/2021-05-13/Long-Term-Archiving-2-Failure-Modes.html)**: the different ways data can be lost.
* **[Collecting Data](/2021-06-04/Long-Term-Archiving-3-Capturing-Data.html)**: what data will I archive and how will I get my hands on it.
* **[Access Patterns](/2021-08-07/Long-Term-Archiving-4-Access-Patterns.html)**: the way you to need to access data determines how it gets stored.
* **[Storage Options](/2021-10-09/Long-Term-Archiving-5-Platform-Options.html)**: the many ways you can store data - hard copies, on-site, cloud, archives.
* **[Implementation](/2021-10-29/Long-Term-Archiving-6-Implementation.html)**: the actual way I'll be storing data.
* **[File Formats](/2021-11-28/Long-Term-Archiving-7-File-Formats.html)**: which ones are likely to survive 45+ years.
* **[Organising Data](/2022-02-25/Long-Term-Archiving-8-Organising-Data.html)**: how to organise data so its self-documenting and can be connected to other parts.


## Conclusion

Long term archiving of data for 45+ years is tricky.
It's a goal that is longer than I've been alive!
But it is not impossible if you have many copies, maintain them, and are prepared to change (possibly radically).

I'm signing up for the long haul. 
Assuming it works, my grandkids will be reading this in 2121!


**Next up**: a discussion of what things can go wrong with backups over 100 years.
In other words - failure modes.

[Read the full series of Long Term Archiving posts](/tags/Archiving-Series/).


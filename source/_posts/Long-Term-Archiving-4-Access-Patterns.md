---
title: Long Term Archiving - Part 4 - Access Patterns
date: 2021-08-07
tags:
- Backup
- Archive
- Church
- Compliance
- Legal
- Archiving-Series
categories: Technical
---

Optimise for the common case.

<!-- more --> 

You can [read the full series of Long Term Archiving posts](/tags/Archiving-Series/) which discusses the strategy for personal and church data archival for between 45 and 100 years.

## Background

Last time, we listed the [failure modes](/2021-06-04/Long-Term-Archiving-2-Failure-Modes.html) possible when making long term backups and archives. Also remember the [broad strategy](/2021-04-11/Long-Term-Archiving-1-The-Problem.html).

The last thing we will consider before we get into the **how** of backups & archives is how we might need to access said backups & archives.

On one hand, this will require a certain amount of guess work.
On the other hand, it's very educated guess work.
And there are some strategies which will help even if we guess wrong.

## Goal

List the likely ways I need to access the backups & archives.
How often that might happen.
And how that influences my choice of technology.

## Some Observations

I'll start with some personal observations:

1. Our minimum retention period is 45 years. That's longer than I've lived!
2. I've occasionally needed to go to a backup to restore data, but its a very infrequent action.
3. I've done exactly one bare metal restore under duress. 

And some implications:

1. Backups & archives need to scale with time. Often you need to break a large dataset into small chunks. And just as often, you won't have all the data at the start; it will be created as you go.
2. Restoring from backups is a rare event. Optimise for the common case (a backup that will never be touched). But be very, very careful you don't optimise the backup out of existence.

Let's think about these in more detail.


## Time Series Data

The only way to structure long term backups is as time-series data. 
That is, data must be grouped by year (which works well for financial transactions) or when it was created, or last modified. 
That is, you store all the files, documents and records for 2020 on one disk, and all the data for 2021 on another, 2022 on another. and so on.

Nothing else works.
Nothing else scales.
Particularly when you have 45+ years of data to retain.

The good thing is there's only so much data you can create or modify in a given time period.
And unless you're Google or Facebook or Twitter, you can always backup *everything that changed* in the last year / month / week / day (choose whichever works best).
If you end up with a particularly large year / month / week / day, you can usually break it up into smaller chunks.
Or, in the worst case, split into multiple chunks (eg: A..K and L..Z, or first 100GB, second 100GB, etc).
That is, when I say "store all data on a disk", that may be "a set of disks" (2020 might only be 1 disk, but 2021 might be 2: January to June, and July to December).

Your backup media needs to scale with time as well.
And time is big; 45 years is a long time.
Some media does this better than others: hard disks in a server will eventually run out physical space in the server, while external hard disks can just pile up until your warehouse is full (and you can get very big warehouses).
Even if you decide to convert your warehouse into a [data center](https://en.wikipedia.org/wiki/Data_center) and with lots of servers, it will be much more expensive than the raw media - the servers themselves, people to maintain them, electricity to run them: they all cost money.
The cloud is very good as scaling up, if you chose the right storage product: "object storage" is effectively limitless, "block storage" has an upper limit.

(Aside: time also impacts media longevity, as we discussed in [part 2's failure modes](/2021-05-13/Long-Term-Archiving-2-Failure-Modes.html). I'll consider that in more detail in the next post).


## Access Scenarios

There are five access scenarios to consider:

1. You add more data to your backup.
2. You verify your backup media still works.
3. There is a catastrophic failure of your main system (eg: fire, theft, crash) and you need to restore **everything** (or almost everything).
4. There is a localised failure (eg: accidental deletion, file corruption) and you need to restore **one thing** (or a few).
5. Old data is needed from an archive (after being deleted from the main system) and you need to restore a few things.

Scenarios 1 and 2 are the regular operations of creating and maintaining backups.
Scenarios 4 and 5 are pretty much the same.
So, when you need to restore from backups, we're down to 1) **everything**, and 2) **a few things**.

If the *everything* scenario happens, you're going to grab all your backups and restore everything from them in sequence (or parallel if you can load multiple disks at once).
There's no worry about "do we need this or not?" - you need everything so the restore is done in bulk.
Access pattern is sequential, and [all media is really good at sequential](https://en.wikipedia.org/wiki/Hard_disk_drive_performance_characteristics#Data_transfer_rate).

If the *few things* scenario happens, you need to be more targeted in which backup disks you restore from.
You need some way of identifying which disk(s) are of interest.
So, at minimum, you should keep a list of the files on each disk separately.
Even better, an index or table of contents that you can look at without loading every disk.
Also, some backup technologies are much better at random access than others - HDDs, optical disks and the cloud are all good at reading one thing; tapes not so much.


## Access Frequency

Backups and archives are accessed, by nature, infrequently.
Here are the operations you perform on backups, in order of frequency (most frequent first):

1. **Adding to your backups**. Automated backups will be doing this daily (at minimum). And manual backups will be happening on a regular schedule (maybe every week or year).
2. **Verifying your backups**. Again, automated backups should do this daily or weekly. And manual backups monthly or annually.
3. **Restoring from backups**. People asking to restore an accidentally deleted file used to be pretty common. But these days most storage systems have automatic "versioning", so you can easily "go back in time" to a copy from last week (before you accidentally hit delete). That is, most day-to-day storage systems are so reliable that a catastrophic failure is the only reason to restore. That is, you may go several years before you truly need a backup; indeed, you may *never* need to restore anything.

Always optimise for your common operations.
There's no point making sure you can restore an individual file in under 5 seconds if it takes a week to back it up in the first place.
Making backups & archives need to be quick & painless (and automated whenever possible).
Verifying should also be straight forward.

Generally, people assume that pulling data from a backup doesn't happen instantly.
So if it takes an hour or even a day to complete a restore, that's OK.
(Of course, *always* ensure your users understand and agree to any time frames).


### A Special Case: Bare Metal Restore (Under Duress)

I've just said its OK if restores take time.
Well, this is a special case where it's not OK.

If your one and only server crashes, every minute longer the restore takes is a minute of lost productivity multiplied by every user (in a business, you can easily put a dollar figure on this; it gets big very quickly).

If you need [disaster recovery](https://en.wikipedia.org/wiki/Disaster_recovery), you need it fast!
So, you should a) plan your backups so a restore can happen fast, b) do practise runs so you understand exactly what needs to happen, and c) optimise & automate so that it happens faster!

Fortunately, not everyone needs disaster recovery - if my personal TrueNAS server fails and I can't get it running again in under 24 hours, it will be a headache for me, but its not like I'll lose a million dollars or get fired.


### A Special Case: Legal Request

For the data Wenty Anglican needs to retain for Safe Ministry purposes, there is one additional access scenario: a legal request.

I'd expect it to go something like:

> "B Bloggs has allegations of *&lt;insert terrible crime here&gt;* made against him / her. As the *police / prosecution / defence team*, we require all relevant ministry documents from Wenty Anglican pertaining to *B Bloggs* in the *ministry role of youth and children's leader* from *January 2027 to December 2030*."

I'm hoping that will never happen, but history shows that some people, given power over another, will [abuse it some of the time](https://www.childabuseroyalcommission.gov.au/) (Christians call that "sin").
So I'm expecting it will happen one day.

And that day will suck if I'm still in charge of church backups & archives.

From a data access point of view, I have a date range, so I can get any disks that have data for that period of time easily (time series data).

There are two additional criteria: the person, and the their role.
Ideally, I want some way to identify documents or data based on those criteria.
So that I don't need to trawl through 3 years of everything.

For now, I won't answer that question.
Part 8 will look into how to structure data within backups & archives, and how to create good indexes to find things within offline media.
But its something to keep in mind.

And you should consider if there are special access scenarios you need to optimise for in your particular situation.
Otherwise, you get to trawl everything.


## Conclusion

In this post, we've established all backups & archives need to be time-series data, broken down by year or month.
We've identified our core access scenarios: everything & a few things, and know we will need some kind of index for the *few things* scenario.
And we've identified how frequently we need to access our backups: very rarely - so we should optimise creating & verifying rather than restoring (unless you have a special case that demands otherwise).

Now that we've covered [failure modes](/2021-05-13/Long-Term-Archiving-2-Failure-Modes.html), identified [what needs to be on the backup](/2021-06-04/Long-Term-Archiving-3-Capturing-Data.html), and the ways we need to access the data, we're in a position to make intelligent decisions about what backup technology to use!

**Next up**: I will list different technology options for backups & archives. And discuss pros and cons of each, based on the criteria I've listed.

[Read the full series of Long Term Archiving posts](/tags/Archiving-Series/).


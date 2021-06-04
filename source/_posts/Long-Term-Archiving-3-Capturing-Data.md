---
title: Long Term Archiving - Part 3 - Capturing Data
date: 2021-06-04
tags:
- Backup
- Archive
- Church
- Compliance
- Legal
- Archiving-Series
categories: Technical
---

What to store? How to get it?

<!-- more --> 

You can [read the full series of Long Term Archiving posts](/tags/Archiving-Series/) which discusses the strategy for personal and church data archival for between 45 and 100 years.

## Background

Last time, we listed the [failure modes](/2021-05-13/Long-Term-Archiving-2-Failure-Modes.html) possible when making long term backups and archives. Also remember the [broad strategy](/2021-04-11/Long-Term-Archiving-1-The-Problem.html).

Before we consider the **how** of backups & archives, we need to ensure we can get our hands on the data we need!
After all, it's rather pointless to have a robust strategy for keeping 45+ years of data safe, if we forget to include crucial files or documents.

## Goal

List the data I need to store on backups & archives.
Then ensure I have access to said data.

## Part 0 - General Principals

Make a list of everything you need to backup.

The simplest list is "everything" - that way you won't forget!
Often "everything" ends up being too big and you have to choose, but we can cross that bridge later.

It might be too abstract to work out a meaningful list of "data".
so, you could check all devices you own / control and inspect the files on them.
You could list applications used and the files they use.
You could list all your cloud accounts to check for data in the cloud.
And don't forget hard copies.

Now you have a list of data (files, photos, videos, recordings, databases, financials, records, etc).
Figure out what devices they reside on.
Its possible you have a centralised server (or servers), or they could be stored on each device, or perhaps in the cloud.
Write down how you can access them.
Write down how large each category is (MB, GB, TB, etc) and how much it grows each year - often one or two categories will make up 90% or more of the total data size.
And finally, how you might include them in backups & archives (preferably via an automated process).

If you want, you can make the data list in priority order, and ensure most important things are backed up first.
The relative size of each category might mean those are backed up less frequently.

You could also define a lifetime - for my purposes, the lifetime is 45+ years for everything.
But it's possible some data only needs to be retained for a few months or years - that might indicate different backup strategies are required.


## Part 1 - Personal Data

Enough abstract principals, lets make some lists!

**The list of personal data I want backed up:**

* **Photos and videos** - from cameras / phones. ~350GB, growing by ~30GB / yr.
* **Larger videos** - these go for over 20 minutes, sometimes from 3rd party sources. ~80GB, growing by ~10GB / yr.
* **Music** - ripped CDs. ~10GB, growing by ~100MB / year.
* **Documents / source code** - from devices, cloud & [File History](https://support.microsoft.com/en-us/windows/file-history-in-windows-5de0e203-ebae-05ab-db85-d5aa0a199255). 30GB, growing by 500MB / year.
* **Occasional disk images** - taken when I decommission a device. ~50-150GB per image, one image every 2-5 years.
* **Email** - stored on GMail. ~5GB, growing by 250MB / year.
* **Cloud** - OneDrive is the only thing I care about. ~30GB, growing by 500MB / year.
* **Hard copies** - only of very important documents (birth certificates, university certificates, etc). 

**The list of personal devices:**

* A few PC computers - laptops and desktops (slowly shinking in number)
* A few servers - Linux boxes & TrueNAS server
* Android Mobile phones / tablets (slowly increasing in number)

I have passwords and admin rights to everything!
So no problem with access.
And all devices have OneDrive and / or [Syncthing](https://syncthing.net/) to automatically copy data to well known locations.

**How does the data on each device get to a backup?**

The rule is: if I want it backed up, it should end up on my [TrueNAS server](https://www.truenas.com/).
Otherwise, it should be in the Microsoft or Google clouds.
I can manage backups from all these locations, either via automated or manual processes.

* **Photos and videos**: any WiFi enabled Android device runs [Syncthing](https://syncthing.net/) which automatically mirrors photos to my TrueNAS server. A handful of cameras don't have WiFi, so they need to be manually copied.
* **Larger videos**: stored on TrueNAS
* **Music**: stored on TrueNAS
* **Documents / source code**: stored on individual devices + OneDrive. [File History]((https://support.microsoft.com/en-us/windows/file-history-in-windows-5de0e203-ebae-05ab-db85-d5aa0a199255) makes sure these get copied to TrueNAS regularly. Anything not copied automatically is captured in my bi-annual "manually export everything from the cloud to a local backup" (see below).
* **Disk images**: copied to TrueNAS on creation
* **Email**: bi-annual manual export.
* **Cloud**: bi-annual manual export.
* **Hard copies**: scanned / photographed as required. Ends up on TrueNAS.

Assumption: things stored in the cloud are pretty safe; I'm happy to do a manual bi-annual export.
I had an automated GMail backup to local files, but it broke years ago and I never fixed it.

A note about cloud data: Google, Microsoft and Facebook all have an [export all your data](https://support.google.com/accounts/answer/3024190/how-to-download-your-google-data?hl=en) function.
The format it is exported in is often mediocre, but it's better than nothing.
For other cloud services, you will need to search for an "export" function.
If one is not available, that's a big risk - if the provider goes out of business you will likely lose your data.

My *photos and videos* category is both the largest and fastest growing.
It's also my highest priority to survive any disaster or data loss event.


## Part 2 - Church Data

Church is considerably more complex.
The main reason is data is stored on various devices owned by volunteers; centralised digital storage is a relatively new thing.

**The list of church data I need to backup:**

* **OneDrive** - this is our main church digital storage. Sub divided as follows:
  * **Specific Ministries** - eg: childrens, youth, young adults, etc. ~1-5GB each, growing by ~100MB / year / ministry
  * **Sunday Meetings** - eg: Powerpoints / videos shown during church meetings. 5-10GB per year.
  * **Music** - eg: Song slide masters, recordings used when live music isn't possible. 5GB, growing by ~250MB / year.
  * **Recordings** - eg: audio and video recordings of church meetings. ~60GB per year.
  * **Documents** - relating to committee meetings, management, policies, financials, etc. 4GB, growing by ~250MB / year.
* **Email** - Office365 for staff, personal emails for volunteers. ~5GB, growing by ~500MB / year. No idea about personal email size.
* **Hard copies** - eg: records of weddings, baptisms, burials. Youth & children permission. Attendance rolls. ~250 documents / year.
* **Databases** - eg: Safe Ministry Compliance (cloud based SaaS), church contact details (MS Access). Under 1GB, growing by ~10MB / year.
* **Website** - [wentyanglican.org.au](https://wentyanglican.org.au), which is stored on git in [BitBucket](https://bitbucket.org/). Under 1GB.

**The list of devices I'll need to get data from:**

* Small number of church owned PCs / laptops. All Windows PCs.
* Large number of personal devices owned by members / leaders / staff. PCs, Android, Mac. I really don't know how many of these are out there; it's not feasible to get access to all of them.
* I have admin access to church devices, but not personal ones. I need to provide a way for people to make this data available.

**How does the data on each device get to a backup?**

This is the main complexity of our church environment.
I need to provide a way (probably via OneDrive) for people to store / submit data to church controlled systems.
That's a change to how people conduct their regular church ministry / work, so it's not trivial - I need to provide processes, documents and technical support to assist non-technical people in this transition.

* **OneDrive**: I can download everything from OneDrive. Or use something like [rsync](https://rsync.samba.org/) or [rclone](https://rclone.org/) to mirror to local or cloud storage.
* **Email**: Manual process to download from Office365. Personal email is more difficult - best option I've come up with so far is a special "backup" mail box in Office365 that people can send important messages to. That's clearly far from fool proof.
* **Hard copies**: Stored in filing cabinets / archive boxes. Scans made to OneDrive.
* **Databases**: Manual exports from cloud, or database backups for on-prem. Under 1GB, growing by ~10MB / year.
* **Website**: Automated git pulls to a local server.

Key to this strategy is to move more ministry related data to cloud storage.
The more data on servers / services I can access without asking, the easier I can automate backups.

One option I am toying with is [Nextcloud](https://nextcloud.com/), which is an "on-site DropBox".
Basically, something like OneDrive, but on our own hardware.
The main reason is to increase our control over data with personally identifiable or sensitive information.
It just so happens we have an existing Linux server with a few hundred GB of storage, which should be plenty enough for storing small documents.

The single largest category is *church meeting recordings*.
Since November 2020, we've been live streaming and doing video recordings of all Sunday meetings (plus various other events), which is ~1GB per meeting.
Previously, it was audio only recordings, which weighed in at 50MB per meeting.
These video recordings dwarf all other categories of data, so they'll need special treatment.
However, in terms of surviving 45+ years, they are only of historical importance - compliance data is what we really need to keep long term.


## Conclusion

We've identified the categories of data needed to be backed up, where they are stored and how we can get this data to a backup (at least at a very high level).
Essentially, we've identified how to get access or control of any data we need to backup.

Which boils down to: what devices do I need access to?
And: how can I export from my cloud service providers?

So make your lists and check them twice!

**Next up**: how will we need to access data? That is, access patterns will drive the storage technology chosen.

[Read the full series of Long Term Archiving posts](/tags/Archiving-Series/).


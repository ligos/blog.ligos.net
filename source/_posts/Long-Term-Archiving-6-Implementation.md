---
title: Long Term Archiving - Part 6 - Implementation
date: 2021-10-29
tags:
- Backup
- Archive
- Church
- Compliance
- Legal
- Archiving-Series
categories: Technical
---

The Interesting Part.

<!-- more --> 

You can [read the full series of Long Term Archiving posts](/tags/Archiving-Series/) which discusses the strategy for personal and church data archival for between 45 and 100 years.

## Background

So far, we have considered [the problem and overall strategy](/2021-04-11/Long-Term-Archiving-1-The-Problem.html), possible [failure modes](/2021-06-04/Long-Term-Archiving-2-Failure-Modes.html), how we will [capture the required data](/2021-06-04/Long-Term-Archiving-3-Capturing-Data.html), likely [access patterns](/2021-08-07/Long-Term-Archiving-4-Access-Patterns.html) of the backups, and finally, [listed possible options for backups and archives](/2021-10-09/Long-Term-Archiving-5-Platform-Options.html). 

With all the due diligence out of the way, it's time to describe the implementations chosen.


## Goal

Describe the implementation of my chosen long term archiving strategy (45+ years) for personal and church data.

## Personal

My family's personal data is split across four areas:

* **TrueNAS server** - photos, videos, music, file history from Windows devices, and full disk images.
* **OneDrive** - general documents, selected photos.
* **Google** - email.
* **Other cloud** - there's plenty of stuff I've forgotten, and I don't really care.

<img src="/images/Long-Term-Archiving-6-Implementation/countdooku-truenas-server.jpg" class="" width=300 height=300 alt="My TrueNAS server: CountDooku" />

The [TrueNAS](https://www.truenas.com/) is a frankenstein computer of parts from down the ages (oldest is ~10 years).
It has a 2 Core AMD CPU, 16GB RAM and 6TB usable storage (mirrored disks).
It is powered via a small UPS, which is designed to protect against a 5 minute outage and allow a safe shutdown (electricity is extremely reliable in Sydney, but thunderstorms happen in Summer).
Despite the low end (and second hand) hardware, it is one of the most reliable computers I've come across.

I consider OneDrive and Google very reliable cloud providers.
But I take a weekly snapshot of OneDrive using [RClone](https://rclone.org/).
GMail is more problematic to backup automatically, so I'm content to download a snapshot every couple of years.

Data on the TrueNAS is backed up to [BackBlaze B2](https://www.backblaze.com/b2/cloud-storage.html) cloud storage.
TrueNAS has a web front end to RClone that makes it much easier to understand and use.
Cost for B2 is ~AUD $6 / month with my current usage of ~700GB.

<img src="/images/Long-Term-Archiving-6-Implementation/bluray-spindles.jpg" class="" width=300 height=300 alt="BluRay backup spindles" />

BluRays are used for offline backups and archives.
So far, I'm sticking to single layer 25GB BDR disks as they are cheapest per GB and simplest (read: least  ways for them to fail), though I'm experimenting with larger capacity disks as well.
All important data is stored with triple redundancy (3 copies of each disk), and two copies are stored off-site.
I'm also using 3 different brands of disk, in case there's a systematic failure from a factory.
BluRay disks are the cheapest offline backup system for consumers (tape is out of my price range).
And optical media has the highest longevity I'm aware of in consumer hardware, which is good for archiving data for at least 20 years using standard disks.

<img src="/images/Long-Term-Archiving-6-Implementation/wincatalog-blurays.png" class="" width=300 height=300 alt="WinCatalog showing my BluRay disks" />

Data on TrueNAS and BluRays are indexed using [WinCatalog](https://www.wincatalog.com/).
This gives an explorer-like view across all disks, and facilitates searches and finding duplicates.
Unfortunately, it doesn't have a "find files that are NOT on a BluRay disk" feature - but the underlying database is [Sqlite](https://sqlite.org/index.html), so I have written my own [utility to find missing files](/images/Long-Term-Archiving-6-Implementation/CatalogQuerier.zip).
I also have written a [console app to generate hashes of each file](/images/Long-Term-Archiving-6-Implementation/ManifestMaker.zip) on a BluRay disk (the disk *manifest*), and that gets signed using PGP and KeyBase keys - which gives high confidence of reading data correctly.
The WinCatalog index & manifest files are stored separately on TrueNAS.

<img src="/images/Long-Term-Archiving-6-Implementation/manifest-file.png" class="" width=300 height=300 alt="A Manifest file for a BluRay - tab separated plain text, readable in Excel" />

Finally, every year or two, I manually gather up all data from cloud services and local storage and burn BluRays of them all.
This gives an occasional snapshot of all documents, email, etc.
I also make a snapshot on a hard disk of photos, videos, etc (ie: larger data that is also on BluRays).

Every 5-10 years, I get dissatisfied with some aspect of my backup system, so I re-visit and re-work it.
(This post outlines my latest iteration; previously I've used DVDs, HDDs, and cloud based systems).
This is an informal "review" process to evaluate if I should change due to hardware / software obsolescence (and unfortunately involves data migrations).

This strategy satisfies the [3-2-1 backup rule](https://en.wikipedia.org/wiki/Backup#3-2-1_rule):

* **Three copies of important data**: TrueNAS, BackBlaze / OneDrive, BluRays.
* **At least two backup media**: TrueNAS, BackBlaze, BluRays.
* **At least one copy off-site**: 1 cloud copy + 2 BluRay copies.

BluRay disks are expected to be readable in 20 years, likely more.
And provides an off-line, air-gapped, off-site archive.


## Church

Processes for church data are slower in taking effect, however we've done all the planning (and I've tested pretty much everything in a personal context anyway).

The main difference is church data is primarily on the cloud, to facilitate sharing.
Systems we're using include:

* **OneDrive** - for documents, recordings, etc.
* **BitBucket** - website git repo.
* **YouTube** - online videos & streaming platform.
* **Office365** - email.
* **Specialised cloud systems** - in particular, the Sydney Anglican Diocese has website for capturing records required for Safe Ministry.
* **Hardcopies** - we'll never be fully electronic.

The stronger use of cloud systems is because church members need to share data with each other.
We certainly have many computers on-site, but most members are volunteers who do their work from home, and sometimes need to access that content on-site (eg: for presentations, printing or post-processing).

Backup systems:

<img src="/images/Long-Term-Archiving-6-Implementation/Microsoft_Office_OneDrive.svg" class="" width=300 height=300 alt="OneDrive Logo" />

We view [OneDrive](https://onedrive.live.com/) as a system to store data we use on a day-to-day basis, as well as a backup system.
It provides features to assist sharing documents, and also retaining them in longer term.
It's more reliable than anything I could build on a limited budget for backups.
It's also quite simple to use, which is a big plus for church volunteers who might not be very technologically savvy.

<img src="/images/Long-Term-Archiving-6-Implementation/abraham-church-server.jpg" class="" width=300 height=300 alt="Church Server: Abraham" />

Data on OneDrive is mirrored to a local server (in case OneDrive disappears for some reason).
Currently, that server is an even older frankenstein than my home TrueNAS box.
It was cobbled together at short notice (to replace a failed server) from very old parts.
It's running Ubuntu server and has no web UI like TrueNAS does, so all admin is via SSH - which makes simple admin tasks more complex than they need to be.
It is using [ZFS](https://en.wikipedia.org/wiki/ZFS) to ensure data integrity.
There are plans to migrate to TrueNAS (possibly even first party TrueNAS hardware).

There is no additional backups to other cloud systems (eg: BackBlaze or AWS).
Due to our limited budget, and to keep things simple, we're classifying OneDrive as both our day-to-day storage and a cloud backup system.

We take periodic snapshots from all systems.
Some are automated (where possible) and others are manual.

<img src="/images/Long-Term-Archiving-6-Implementation/m-disc-blueray.jpg" class="" width=300 height=300 alt="There's aren't the actual BluRay M-Discs we'll use, but close enough" />

BluRays are also used for offline backups and archives, in a very similar way to my personal backups.
The main difference is church BluRays will use [M-Discs](https://en.wikipedia.org/wiki/M-DISC) - these are archive grade media designed to survive for "hundreds of years".
We're also planning to store an additional copy (ie: 4 in total) at the [Sydney Diocesan Archives](http://www.sydneyanglicanarchives.com.au/) - which have a better environment for storing disks long term.

<img src="/images/Long-Term-Archiving-6-Implementation/wincatalog-blurays.png" class="" width=300 height=300 alt="WinCatalog showing my BluRay disks" />

We're planning on using WinCatalog & manifests to index disks.
No changes from personal strategy here.

<img src="/images/Long-Term-Archiving-6-Implementation/compliance-report.png" class="" width=300 height=300 alt="The header for a compliance report template" />

One big difference from personal backups is a much more structured approach to procedures and reviews.
Because there are legal compliance requirements we need to meet (particular data must be available for at least 45 years), we need to regularly check we are actually meeting those requirements.
So there are template reviews drafted that will be done annually, and report back to our church's board of directors to ensure compliance.
These reviews include people focused questions - are people using the systems we've provided, is the data we need being stored. 
As well as technical questions - are backups working, can I read the media successfully, is the technology still viable.
And even the manual processes - so we remember to do them!

This strategy satisfies the [3-2-1 backup rule](https://en.wikipedia.org/wiki/Backup#3-2-1_rule):

* **Three copies of important data**: OneDrive / and other cloud systems, on-prem server, BluRays.
* **At least two backup media**: OneDrive, on-prem server, BluRays.
* **At least one copy off-site**: 1 cloud copy + 3 BluRay copies.

M-Disk BluRay disks are expected to be readable in 45+ years, possibly over 100 years (if the advertising proves correct).
And provides an off-line, air-gapped, off-site archive.


## Possible Single Points of Failures

Very long term backups need to have as few single points of failure as possible.
If there is a single link in the chain that can break and cause loss of ALL data, that is entirely unacceptable.

### Encryption

The biggest single risk is **encryption**.

If your backup is encrypted, it is impossible to restore unless you have the password / encryption key.
Of course, you want your backups encrypted because there's likely to be sensitive data in them.

<img src="/images/Long-Term-Archiving-6-Implementation/encryption-key.jpg" class="" width=300 height=300 alt="The matrix-like random characters are closer to a real encryption key." />

There is a fundamental tension here: 

1. Backups should be encrypted because they contain sensitive data.
2. Backups should not be encrypted because its a single point of failure that can prevent a restore when in duress.

My approach is: when making backups, I only encrypt cloud backups.

That is, data on the public cloud is encrypted (and RClone makes that easy).
But offline backups / archives are **not encrypted**.
That is, anyone who gets their hands on my BluRay disks can read everything.

Which is by design.

Because archives a) are often old enough the sensitive data has lost its value, b) designed to be the last resort when restoring, so need to be easily accessible, c) more likely to be read by someone after I'm dead (eg: grand kids, archeologists, etc).

I can manage security of BluRay disks by controlling physical access to them.
But if someone gets access to them in 100 years time, I'd prefer they can see their content rather than be thwarted by a password.

**Aside**: there are ways of keeping a backup password safe by distributing it to many people.
[Shamir's secret sharing algorithm](https://en.wikipedia.org/wiki/Shamir's_Secret_Sharing) is a way to do this such that a quorum of people are required to recover a password.
Or a "dumb" approach: have a long passphrase and give parts of it to different people.
Both likely introduce a delay if you're going to the backup of last resort, as you need to contact several people.


### Simplicity

Other than encryption, overly complex recovery processes are the most likely way reading data would fail.

There are three ways to mitigate:

1. Document the restore process.
2. Do test restores on a regular basis.
3. Remove un-needed complexity.

Items 1 and 2 are in place for church archives via compliance reports.
Less so for personal archives, but I still occasionally test the disks are readable.

Item 3 is my main focus here: **keep things simple**.

<img src="/images/Long-Term-Archiving-6-Implementation/wincatalog-files.png" class="" width=300 height=300 alt="The best backups are just files on a disk." />

My BluRay disks are, as much as possible, just a bunch of files burned to a disk.

If you put them in any BluRay drive connected to a laptop / desktop computer, you can browse them using your favourite app, and open them using whatever apps are available.
There's no requirement for Windows, or Microsoft products (although that's where much of the data originates).
The disks could be read on a Mac, or a Linux machine (or some new OS that comes out in 50 years time, as long as it can talk to a BluRay reader and supports [UDF](https://en.wikipedia.org/wiki/Universal_Disk_Format)).
And the files should be readable using many applications (JPEG photos, MP4 videos, MP3 music, DOCX documents, PDF documents, XLSX spreadsheets, etc).

In particular, I avoid compressing data.
The logic being: a single error has a higher chance of doing extensive damage to compressed data - but would only break a single file if not compressed.
And, most large files I deal with (video, audio, photos) are already highly compressed; documents and spreadsheets are small enough that it doesn't matter.

That is, the requirements to read my archive disks are a) the disks themselves, b) a BluRay drive, and c) a computer.

Special backup software should **NEVER** be required for long term archives.
It adds a layer of complexity that may cause difficulty when trying to restore data.
And you don't know what the scenario is when the disk is read (it might be after your house burned down and you have absolutely nothing beyond an off-site backup, or it might be your great grand kids in 100 years time, or it might be an archaeologist in 500+ years time).

If you only have one disk (because all the rest were damaged beyond repair somehow), you should be able to read everything from that one disk without dependencies on others.

The biggest layer of complexity I'm happy to add is for large files to span multiple disks.
This is pretty rare as I don't often work with files over 25GB.
But [full disk images](https://en.wikipedia.org/wiki/Virtual_disk_and_virtual_drive) are the one exception.

Having said all that, I'm happy to include **extra data** on each disk.
For example, the manifest file is not required to read anything on the disk - although it forms an index that may help someone find what they're looking for more quickly, and provides a hash to verify the file integrity.
I usually include [MultiPar](https://github.com/Yutaka-Sawada/MultiPar) parity data - that includes additional checksums to verify integrity, and may help recover a damaged disk.

However, none of that "extra data" is required to read the content on disk.


### Integrity

Also, I'd like to ensure the integrity of any data cannot be tampered with.
That is, if someone edits or replaces a file (or an entire disk), you should be able to clearly tell something has changed.

<img src="/images/Long-Term-Archiving-6-Implementation/manifest-signatures.png" class="" width=300 height=300 alt="Hashes and signatures of a manifest file." />

First off, all BluRay disks I use are write-once.
So it is technically impossible to accidentally or maliciously modify data on a disk.
However, a bad guy could make a copy of the disk with changes and replace the original with the copy.
Unless they are very careful, this would leave different date stamps or different media brands which could be noticed.

The WinCatalog index includes an SHA256 hash of each file, and the manifest files include SHA384 hashes.
Both are stored separately from disks, so even if someone replaced a disk with a new one (with dodgy data), that could be detected.
The bad guy would need to a) replace all disks in all physical locations, and b) update the index & manifest files which are stored separately to the disks.

I'm also signing the manifest files, so the signature would no longer be valid if the bad guy is tampering with things.
The bad guy could generate new PGP / KeyBase keys that look like mine, but are not.
However, KeyBase keys are public by default, so that should be very difficult.
(PGP keys can be published as well, but there is no central authority so nothing stopping an attacker doing exactly the same thing).

If I was implementing this in a larger corporate environment, I might ask many people to observe the process to create disks, inspect the disk contents and then ALL sign the manifest.
That is, you might have 2 or 3 or more people attesting to the correctness of a disk.
If the private keys for this process were stored on a hardware token (eg: [Yubikey](https://www.yubico.com/)), then the difficulty for an attacker to modify data without detection becomes extreme.

If I was really concerned about bad guys trying to alter data in deep archives, I could publish the original manifest files to a public location (like a [blockchain](https://en.wikipedia.org/wiki/Filecoin)), when the disks are created.
As blockchains are effectively append-only databases, an attacker would need to re-create the whole blockchain to change hashes.

For my use case, write-once media + hashes + signatures is more than enough.


## Conclusion

It took 5 posts and about 12 months of thinking to come to a reasonably simple (if overly redundant) backup strategy that can meet the 45+ year requirement.

By using on-prem (TrueNAS), cloud (BackBlaze / OneDrive) and offline storage (BluRays).
And keeping copies off-site.
And using two external indexing systems.
And keeping signed hashes of all files.

I am very confident my data will survive well into the future.
Even confident it will survive to my 45 year goal!

(And yes, I realise most of the 10+ year part is met via M-Disc BluRays. 
And 20+ years is met via "review backup technology and migrate if required".
Insert something about the journey being more important than the destination).

**Next up**: We aren't finished yet! I will discuss which file formats are suitable for long term archiving.

[Read the full series of Long Term Archiving posts](/tags/Archiving-Series/).


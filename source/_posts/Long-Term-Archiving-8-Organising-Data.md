---
title: Long Term Archiving - Part 8 - Organising Data
date: 2022-02-25
tags:
- Backup
- Archive
- Church
- Compliance
- Legal
- Archiving-Series
categories: Technical
---

Files you can find in 100 years.

<!-- more --> 

You can [read the full series of Long Term Archiving posts](/tags/Archiving-Series/) which discusses the strategy for personal and church data archival for between 45 and 100 years.

## Background

So far, we have considered [the problem and overall strategy](/2021-04-11/Long-Term-Archiving-1-The-Problem.html), and got to [my chosen implementation](/2021-10-29/Long-Term-Archiving-6-Implementation.html).

The last point I'll consider is: how do we organise our files and data so we can find stuff in 10, 20, 50 or even 100 years time?

## Goal

Develop a structure, guidelines and processes to organise files / data such that specific data can be found in reasonable time. 

This structure needs to be self-discoverable, as the original creator of the structure will not be available in 45 years.

This structure can apply to digital files and data, or physical documents. There are advantages to digital data storage, but we've considered a number of risks as well. Any structure should work with the physical as well as digital with minimal changes.

## Concepts

Before we go any further, we should remind ourselves that backups and archives are [infrequently accessed](/2021-08-07/Long-Term-Archiving-4-Access-Patterns.html).
We should always optimise for the common case, which is adding data to the archive.
Retrieving is far less common, so its acceptable if it takes a bit longer.
(Caveat: always check with stakeholders how long is acceptable).

With that out of the way, the way we organise data is dictated by how we need to **access** it.

If the access pattern is "restore everything", then the structure should reflect how the data appears in our regular systems.
Any additional structure just gets in the way.
However, "restore everything" is just one possible access pattern.

There are also certain **queries** we might want to ask our archives.
For example: find all the work photos from 2010-2016, or find that funny video of my kids from their first day of school, or find all the documents that refer to Mr Bloggs when he lead youth group.

Each of those queries has an explicit or implicit **time dimension** (Mr Bloggs only lead youth group from 2018-2023), plus various other parameters (file type, file content, and category).
While unlikely, it is possible the time range is "forever", in which case we just need to trawl everything - that will suck, but there's not much we can do about it.

Queries usually have some kind of **category or context** to them.
In the above examples, "work photos" or "kids first day at school" or "youth group".
These are the kinds of categories that can be incorporated into file structures to make things easier to find.
For example, we might decide to keep all youth group documents together, and all work photos in one place, and keep personal videos separate from work related ones.

There are additional levels of categorisation as well.
Perhaps work photos are also categorised by job number or location.
Personal videos might be kept by event.
And the "youth group" documents are sub-categorised into "permission forms", "lesson plans", "attendance" and "general resources".

The categorisation I've mentioned can be augmented by **tagging**.
Most systems (particularly the "physical document" system) can only put a file or document into one *category*.
That is, all your "attendance" documents can only physically exist in one place, the *youth group attendance 2020* folder.
But you can *tag* folders, documents or files with additional keywords.
Perhaps the youth leaders names are recorded on the front of the folder containing all the attendance documents.
Many photo apps support tagging people (often automatically via facial recognition) and geo-location.
And you can label a document with important keywords (either manually, or using an automated algorithm).
Tags can make it much quicker to find data of interest, without reading the entire document.

**File type** is usually straight forward - most computer file types are trivially identifiable from the end of their name (eg: `jpg` or `docx` or `mp4`).
And if not, the beginning of the file usually has a particular fingerprint (often referred to as [magic bytes](https://en.wikipedia.org/wiki/List_of_file_signatures)).

Finally, most computer systems support **security rights**, so that only authorised persons have access to particular files.
The simplest way to apply these rights are at a top level, so everyone involved with work job 41354 has access to all the job data, or everyone involved in youth ministry has access to all youth related data.
While it is possible to grant or revoke access at a more granular level, that brings additional complexity that I won't consider too deeply here.
Access to physical documents can be controlled in a similar way: different keys give access to different storage rooms or filing cabinets.

With those observations, we are ready to create a simple but effective structure for personal and church data.
This structure will form a **primary index**, or a way to locate specific files.
Additional **secondary indexes** will be listed as well, however they will always point to files that need to be retrieved via the primary index.


## Organisation / Primary Index

Here are the principals I follow for the primary index, or how files are physically organised on disk:

1. Part of the structure must be time series (eg: each year). This doesn't have to be the very top level, but closer to the top is better.
2. I choose some broad categories and sub-categories. These are repeated inside each year.
3. Three or four levels of nesting is usually enough, more becomes difficult to find. However, having too many files in one folder makes it equally hard to find things: there's a balance here.
4. Its worth spending time naming files well. Word documents and PDFs can (sometimes) be indexed, but scans or photographs cannot. A well named file can make it much easier to identify a document.
5. Consistency is key. Whatever conventions you come up with are not so bad if you follow them each year.
6. Self-discoverability is important. While a secondary index is very helpful, if you can't make sense of the files as they are physically organised, you're doing it wrong.

### Personal Examples

The top level provides very broad categories. Pictures, Music, Documents, etc.
And then various sub-categories within there. Often by person.

**Pictures** is the most structured area: 12 months after my first digital camera, I was already struggling to organise photos.
And it hasn't got any easier.
I quickly adopted a strict time series approach to storing photos, and created scripts to automate the process of getting photos from my camera (and more recently phone) into the `Library` folder.
As all my cameras are actually WiFi connected phones these days, the process is fully automated: once I connect to local WiFi, photos are automatically synchronised, post-processed and copied to the right folder.
I've used a number of secondary indexes for photos down the years - they've all ended up obsolete for one reason or another. 
Currently, I just click through photos month by month in Windows Explorer.

**Music** has always been managed by media players.
Rip content from CDs directly to an album, and let the media player index and organise it for me.
There's never been enough content to warrant time series here.

**Videos** has never had enough files for structured time series.
I generally have folders with a rough category / description + year.
Since COVID there's been lots more material added here, but not enough I care to re-arrange it.

**Documents** are again pretty ad-hoc.
Particularly other family members.

```
- Pictures
  - 3rd Party
    - Grandma's Trip to Europe 2001
    - Frodo's Photos from the Beach 2099
    ...
  - Library
    - 2020
      - 01
      - 02
      ...
      - 12
    - 2021
      - 01
      ...
  - Scans
    - Murray's Parents
    - Catherine's Parents
    - Someone Else's
    ...
- Music
  - Album 1
  - Album 2
  ...
  - Album N
- Videos
  - Church Tech Training 2021
  - Church Recordings during COVID
  - DVDs
  - Family Christmas 2010
  - Old VHS
  - School Concert 2016
- Documents
  - Murray
  - Catherine
  - Child 1
  - Child 2
  - Child N
- Backup
  - GMail
    - Murray
    - Catherine
    ...
  - OneDrive
    - Murray
    - Catherine
    ...
```

### Church Examples

Most of our church data is being stored on OneDrive, because of its combination of ease of use, price and functionality.
Even data that isn't primarily on OneDrive (on various other cloud based systems) gets exported and stored on OneDrive.
Its our single source of truth.

The top level category is based on **security roles**.
That is, different people are granted access to different areas as required for their ministry at church.

Then, there are more **specific ministry categories**.
For example, within the broad "children's ministry" category, we have "kids for Jesus" (our Sunday School) and "play time" (preschool).

Then, there is our **time series structure**.
A folder for each year which contains lesson plans, meeting documents, attendance rolls, etc. 

In some cases, there are additional folders for multi-year resources, or other buckets for files.

Finally, we need to take the extra time to name files descriptively.
Well, we try to, it doesn't always happen.

```
OneDrive
  - Admin
    - Advertising
      - 2019
      - 2020
    - Church Directory
    - Policy
    - Templates
  - Children's Ministry
    - Kids for Jesus
      - 2020
      - 2021
    - Playtime
      - 2020
      - 2021
    - SRE (Scripture)
      - 2020
      - 2021
    - Music Resources
  - Music
    - Sheet Music
    - Powerpoint Slides
    - MP3s
    - Videos
    - Copyright
  - Parish Council
    - Budget
    - Correspondence
      - 2010
      - 2011
    - Meetings
      - 2010
      - 2011
      ...
      - 2019
    - Policy
    - Property
  - Sunday Meetings
    - 2018
      - 2018-02-13
        - Powerpoint slides / runsheets.
    - Master Slides
    - Training Resources
  - Talk Recordings
    - 2018
      - 2018-02-13
        - MP3 / MP4 recordings
  - Youth Ministry
    - ROCK
      - 2018
      - 2019
```

## Secondary Index(es)

I'm running several secondary indexes against both personal and church data.

### Manifest Files

The first are the "manifest files", generated by my [ManifestMaker](/images/Long-Term-Archiving-8-Organising-Data/CatalogQuerier.zip) app.
These are simple tab separated text files which list the contents of each disk burned.
They include filename, size, created and modified dates, plus a content hash. 
And can be read by Excel.

While their primary purpose is integrity, they also provide a very crude way to search disk content without access to physical disks.

<img src="/images/Long-Term-Archiving-8-Organising-Data/manifest-file.png" class="" width=300 height=300 alt="A manifest file." />

### WinCatalog

The more featured index is [WinCatalog](https://www.wincatalog.com/).
This app shows a graphical view of disk content (and live / working files), with the same core attributes as manifest files (name, size, dates, hash).
In addition, it takes thumbnails of PDFs, Word documents and images, so you have basic visibility into file content.
And will index some file specific information, such as [EXIF](https://www.wincatalog.com/) details from photos, [ID3](https://en.wikipedia.org/wiki/ID3) metadata from audio and video media, and metadata from e-books.
It also allows you to tag disks, folders and files with arbitrary tags and user defined fields (although data entry for these is a manual process).

<img src="/images/Long-Term-Archiving-8-Organising-Data/wincatalog-main.png" class="" width=300 height=300 alt="Main screen of WinCatalog." />

WinCatalog has a reasonably powerful search function.
Allowing you to search by file date, size, name, type, location in catalog.
It also lets you search for duplicates by name, size and hash.

As an aside, I don't mind duplicate files.
If the same file ends up on multiple disks, that's extra redundancy!
And, having indexes by file hash mean you can instantly determine if the file is a true byte-for-byte duplicate, or just a file with the same name.

One search function I found WinCatalog lacks is to find files which do **not** appear on backup disks.
So, if I index all the "live data" and compare it to all backup disks, I would like a list of everything in "live" which is **not** in "backups".
That is, data that needs to be backed up!

While WinCatalog is a proprietary application, the underlying data is stored in an [SqlLite database](https://en.wikipedia.org/wiki/SQLite).
And I've created a [CatalogQuerier](/images/Long-Term-Archiving-8-Organising-Data/CatalogQuerier.zip) app to implement my "find data that isn't backed up anywhere" search.
I find this invaluable to ensure absolutely everything gets backed up.

The final search function lacking in WinCatalog is [full-text search](https://en.wikipedia.org/wiki/Full-text_search).
It does not (as of 2022) let you search for text within Word documents or PDFs, etc.
That would be a killer feature, particularly for church document searches!

### Media Player / Photo Databases

I've used various databases for photos, video and audio down the years.
All have eventually become obsolete or I've just run out of time to manage them.

* Some really old Adobe software I can't remember the name of.
* [IMatch](https://www.photools.com/imatch/) - a digital asset management system.
* [Windows Photo Gallery](https://en.wikipedia.org/wiki/Windows_Photo_Gallery) - part of the (now obsolete) Windows Live suite.
* The built in Windows Photo / Music apps in Windows 10.

These have various features like tags, facial recognition, geo-location.

### Windows Search

Windows has a full-text search feature.
This works very well to find content within a file, as long as the documents are on your local computer.
Fortunately, documents / PDFs are small enough that it is feasible to keep them all.

Apple and other vendors have their own search functions as well.

## References

The Sydney Anglican Diocese has some [good content about structuring data and retaining records](https://safeministry.org.au/wp-content/uploads/SM_Storeage-and-retention-of-records-Dec2021.pdf). I have issues with their over reliance of cloud based systems, but otherwise very good information.


## Conclusion

You are keeping backups and archives so you can retrieve data from them in the future.
Possibly the very far future.
You need a structure in place to make it reasonably easy to find particular files.
Even if you have inherited the archive from someone else, who inherited it from their predecessor.

Three or four levels of categorisation works quite well.
At least one of those level must be time series.
And files descriptively named.

If possible, it is highly recommended to keep one or more external secondary indexes.
This provides a centralised search functionality that can see the entire archive, even as it is broken into many disks.
And the ability to search using other criteria (eg: file content, thumbnails, and others).

This is the last part in my long term archiving series. 
I may report back in a few years about how my archives are going.

[Read the full series of Long Term Archiving posts](/tags/Archiving-Series/).


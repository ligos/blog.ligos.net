---
title: Connecting to OneDrive with RClone
date: 2025-05-30
tags:
- RClone
- OneDrive
- Windows
- Linux
- FUSE
categories: Technical
---

To work around Microsoft's "changes to backend services".

<!-- more --> 

## Background

I've used OneDrive as a relatively cheap cloud stoarge provider since ~2019.
This is for personal usage (source code, documents, etc), family use (sharing files and documents between family members), and church use (sharing Powerpoint slide decks, documents, even [long term data storage](/2021-10-29/Long-Term-Archiving-6-Implementation.html)).

Aside from the [recent 30% price increase to support AI](https://www.abc.net.au/news/2025-02-25/microsoft-365-subscription-price-hike-consumer-complaints-accc/104965682) (a feature that I don't use), OneDrive has been well behaved. 
I am able to share folders between different OneDrive accounts, and they appear as folders within your own OneDrive.
From there, the regular file sync functionality works like normal.

Alas!
Since January 2025, I've been affected by [Microsoft's "changes to backend services" on OneDrive](https://support.microsoft.com/en-us/office/add-shortcuts-to-shared-folders-in-onedrive-d66b1347-99b7-4470-9360-ffc048d35a33).
This means you can only interact with shared folders via a web browser.

For me, I can cope with that (although it definitely harder to use than files in Windows Explorer).
But for family and church members, this _web browser only_ approach to shared folders represents a significant change in functionality.
For many people, it involves hand-holding to show people how to accomplish the same tasks they were used to with Windows Explorer.

## Goal

I would like to go back to shared OneDrive folders in Windows Explorer.

Unfortunately, I am at the mercy of Microsoft and their "changes to backend services".
For over 4 months now!
Which is long enough that I'm starting to wonder if they've deliberately removed this functionality, or at the least dragging their feet so that people stop using it.

Time to find an alternative!

I have used [RClone](https://rclone.org/) to copy data between OneDrive and local disk (church backups to my NAS) and also local disk to [BackBlaze](https://www.backblaze.com/) (personal backups to the cloud).

Let's see if RClone can provide a useful alternative until Microsoft can complete their "changes to backend services".

## Installation

Installing is as simple as [downloading the appropriate zip file](https://rclone.org/downloads/) from the RClone website.
It runs on [GoLang](https://go.dev/), so there are stand alone binaries which works on many platforms.
Simply unzip to a convinient folder and you're done.

On my Windows machines, I unzip to `C:\Program Files\RClone`.

<img src="/images/Connecting-To-OneDrive-With-RClone/rclone-windows-installation.png" class="" width=300 height=300 alt="Installation on Windows" /> 

On Linux, I unzip to `/usr/local/bin/rclone`.
Or, just use `apt get rclone` (although the package manager version is little older than latest).


## Configure OneDrive Remote

While installation is easy, configuring is a little harder.

RClone uses the concept of [remotes](https://rclone.org/overview/).
These represent various cloud file systems.
You could have a couple of [Dropbox](https://rclone.org/dropbox/) remotes (each with a different login), many [Google Drive](https://rclone.org/drive/) remotes, an [SFTP](https://rclone.org/sftp/) server or three, perhaps a few [S3](https://rclone.org/s3/) object stores, and so on.

There is a [long list of supported remote storage systems](https://rclone.org/overview/).

Each configured remote is given a name, which is used in other RClone commands.

[Configuring a remote](https://rclone.org/commands/rclone_config/) involves entering server names, login credentials, etc.
There is a process to guide you through configuration.

```
$ rclone config

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> n

Enter name for new remote.
name> OneDrive-Test

Option Storage.
Type of storage to configure.
Choose a number from below, or type in your own value.
 1 / 1Fichier
   \ (fichier)
 2 / Akamai NetStorage
   \ (netstorage)
...
36 / Microsoft OneDrive
   \ (onedrive)
...      
```

For OneDrive, there are a stack of options, but the defaults work fine.

```
Storage> 36

Option client_id.
OAuth Client Id.
Leave blank normally.
Enter a value. Press Enter to leave empty.
client_id>

Option client_secret.
OAuth Client Secret.
Leave blank normally.
Enter a value. Press Enter to leave empty.
client_secret>

Option region.
Choose national cloud region for OneDrive.
Choose a number from below, or type in your own value of type string.
Press Enter for the default (global).
 1 / Microsoft Cloud Global
   \ (global)
 2 / Microsoft Cloud for US Government
   \ (us)
 3 / Microsoft Cloud Germany (deprecated - try global region first).
   \ (de)
 4 / Azure and Office 365 operated by Vnet Group in China
   \ (cn)
region>

Option tenant.
ID of the service principal's tenant. Also called its directory ID.
Set this if using
- Client Credential flow
Enter a value. Press Enter to leave empty.
tenant>

Edit advanced config?
y) Yes
n) No (default)
y/n>

Use web browser to automatically authenticate rclone with remote?
 * Say Y if the machine running rclone has a web browser you can use
 * Say N if running rclone on a (remote) machine without web browser access
If not sure try Y. If Y failed, try N.

y) Yes (default)
n) No
y/n>

2025/05/23 19:08:13 NOTICE: Make sure your Redirect URL is set to "http://localhost:53682/" in your custom config.
2025/05/23 19:08:15 NOTICE: If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth?state=VpOdyDTBqFZlMbr8aY8tOw
2025/05/23 19:08:15 NOTICE: Log in and authorize rclone for access
2025/05/23 19:08:15 NOTICE: Waiting for code...
2025/05/23 19:08:34 NOTICE: Got code
Option config_type.
Type of connection
Choose a number from below, or type in an existing value of type string.
Press Enter for the default (onedrive).
 1 / OneDrive Personal or Business
   \ (onedrive)
 2 / Root Sharepoint site
   \ (sharepoint)
   / Sharepoint site name or URL
 3 | E.g. mysite or https://contoso.sharepoint.com/sites/mysite
   \ (url)
 4 / Search for a Sharepoint site
   \ (search)
 5 / Type in driveID (advanced)
   \ (driveid)
 6 / Type in SiteID (advanced)
   \ (siteid)
   / Sharepoint server-relative path (advanced)
 7 | E.g. /teams/hr
   \ (path)
config_type>

Option config_driveid.
Select drive you want to use
Choose a number from below, or type in your own value of type string.
Press Enter for the default (BF77630123456789).
 1 / OneDrive (personal)
   \ (BF77630123456789)
config_driveid> 4

Drive OK?

Found drive "root" of type "personal"
URL: https://onedrive.live.com?cid=BF77630123456789&id=snip

y) Yes (default)
n) No
y/n>

Configuration complete.
Options:
- type: onedrive
- token: {"access_token":"<snip>","token_type":"Bearer","refresh_token":"<snip>","expiry":"2025-05-23T20:08:36.5716604+10:00"}
- drive_id: BF77630123456789
- drive_type: personal
Keep this "OneDrive-Test" remote?
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d>
```

Depending on the computer I'm working on, I may or may not have a web browser available (eg: running RClone on my NAS).
There is an option to do [authentication](https://rclone.org/commands/rclone_authorize/) on another computer, and copy the authentication token back to the config.

### 🚩🚩🚩 Config Limitation

An important limitation of OneDrive is you must configure and authenticate as the owner of the shared folders.
So if Bob has shared a folder with Charlie, and Charlie wants to use RClone for that shared folder, then Charlie actually needs to authenticate as Bob.

This will be a deal breaker for many scenarios.

For me, it is an acceptable risk, because I am the owner (or at least in control) of all the shared accounts within my family or church.


## List

Once a remote is configured, you can treat it similar to a drive letter or mount point with other RClone commands.

The simple way to test a config is working is getting a directory listing with [rclone ls](https://rclone.org/commands/rclone_ls/):

```
$ rclone ls OneDrive-Test:/
 17115946 Documents/2019 calendar (1).docx
 17111888 Documents/2019 calendar (2).docx
 18324276 Documents/2019 calendar.docx
  1144739 Documents/2019 calendar.pdf
  1574213 Documents/2019 calendar2.pdf
   105472 Documents/AntDiag SXTsq 5 ac.xls
  1610653 Documents/Car Seat Manual.pdf
...
```

Excellent! Configuration looks good!

Note that this will list _every_ file in _every_ folder. Press `CTRL+C` to stop once you can see it is working.

## Copy

One scenario at church involves post-processing [video recordings of church services](https://www.youtube.com/c/wentyanglican/live).
I use [ffmpeg](https://ffmpeg.org/) to transcode recordings from 5Mbps [H264](https://en.wikipedia.org/wiki/Advanced_Video_Coding) to constant quality [AV1](https://en.wikipedia.org/wiki/AV1) (at a much lower bitrate).

The church recording computer is an aging [Ivy Bridge i5-3550 desktop](https://www.intel.com/content/www/us/en/products/sku/65516/intel-core-i53550-processor-6m-cache-up-to-3-70-ghz/specifications.html), AV1 software encoding is pretty slow, and there are multiple recordings of different services to transcode.
The process for each Sunday takes around 24 hours.

At the end, I want to upload ~1.5GB of videos to OneDrive for archiving, and eventual upload to YouTube.

RClone can handle this after transcoding completes via the [copy command](https://rclone.org/commands/rclone_copy/).

```
$ rclone copy "D:\Videos\ForUpload" "OneDrive-Church:/Shared Folder/Videos" -v --bwlimit=2M
```

The `--bwlimit` option limits the bandwith RClone uses, so that it does not overwhelm other users at church.

## Sync

Church backups are replicated to my TrueNAS server using the RClone [sync command](https://rclone.org/commands/rclone_sync/). 

Sync is a one-way copy+delete. 
It copies new and changed data, and deletes target files which do not exist on the source.
So the target ends up looking like the souce.

So people at church use OneDrive as shared storage, and I arrange RClone to synchronize that data to be on my TrueNAS server, as a non-cloud backup (because even [the cloud can fail](/2021-05-13/Long-Term-Archiving-2-Failure-Modes.html)).

```
$ rclone sync "OneDrive-Church:/Shared Folder/Videos" "/mnt/data/ChurchBackup/Videos" -v --bwlimit=2M
2025/05/23 19:26:14 INFO  : 2025-04-18 09-21-18.mkv: Copied (new)
2025/05/23 19:26:15 INFO  : 2025-04-20 09-49-56.mkv: Copied (new)
2025/05/23 19:26:15 INFO  : 2025-04-20 11-50-18.mkv: Copied (new)
2025/05/23 19:26:16 INFO  : 2025-04-27 09-53-27.mkv: Copied (new)
...
```

## Mount!

The [mount command](https://rclone.org/commands/rclone_mount/) is the real game changer!

On Windows, it allows a remote target to appear as a local (or network) drive.
(It can do the same thing on Linux, but that kind of thing is much less exciting in the Linux world).

It does two-way sync: changes from OneDrive appear on the local computer, and local changes are copied to OneDrive.
And it has a local layer of caching, so once a file is downloaded, all local IO operations happen on temporary files on the local computer, which are periodically copied to OneDrive.

This is a viable work around for the OneDrive shared folder problem I have been facing (assuming the _security limitation_ mentioned above is acceptable).

First, you need to install [WinFSP](https://winfsp.dev/).
This is a user mode file system driver for Windows (similar to [FUSE on Linux](https://en.wikipedia.org/wiki/Filesystem_in_Userspace)), which allows user mode programs to implement a file system.

Installation is a simple next, next, next affair.

And then, use [RClone mount](https://rclone.org/commands/rclone_mount/) to create a local disk drive for OneDrive:

```
$ rclone mount "OneDrive-Church:/Shared Folder/Music" z: --network-mode --volname \\onedrive\music --vfs-cache-mode Full --vfs-refresh -v
```

There are a few options which I use:

* `--network-mode`: tells RClone to mound the disk drive as a network share. Windows makes allowances for higher latencey and lower reliability in this mode.
* `--volname \\onedrive\documents`: the network share name. RClone can make this up, but sometimes you end up with name clashes if you mount multiple folders, so I found making this explicit is best.
* `--vfs-cache-mode Full`: tells RClone to use full local caching. Remote files are copied locally, and all IO happens locally. RClone periodically uploads changes.
* `--vfs-refresh`: tells RClone to check for changes on startup. The initial mount process takes a few seconds longer, but you see the most recent remote files. This is front loading some work, so that later operations can be faster.

<img src="/images/Connecting-To-OneDrive-With-RClone/rclone-windows-mount.png" class="" width=300 height=300 alt="Mounted OneDrive on Windows" /> 

All in all, I find this works very well for editing the usual files we have on OneDrive: Word docs, Excel spreadsheets, Powerpoint slides, PDFs, and the occasional MS Access database.

### Mount Gotcha

There is one limitation: when opening these documents via MS Office on real OneDrive, multiple users can have the same document open. 
And also edit simultaniously. 

With RClone, this doesn't work.
And worse than just "doesn't work", but if someone opens a Powerpoint deck via `RClone mount`, and someone else edits via OneDrive, no one sees any errors! 
But someone loses their changes.

This has bitten us at least once at church, where someone made last minute changes, while we already have the slide deck showing in the auditorium.
And we don't find out there are missing slides until someone is speaking at the lecturn and wondering where their slides got to 😥


## Linux

You can use the same command to mount a OneDrive folder on Linux:

```
$ rclone mount "OneDrive-Church:/Shared Folder/Music" "/mnt/ChurchMusic" --vfs-cache-mode full --vfs-refresh -v

$ ls -l "/mnt/OneDrive-Music/Complete music folder"
drwxrwxr-x 1 wardens wardens 0 Sep  7  2022 '10,000 Reasons'
drwxrwxr-x 1 wardens wardens 0 Sep  7  2022 'All Creatures of Our God and King'
drwxrwxr-x 1 wardens wardens 0 Sep  7  2022 'All Glory Be To Christ'
drwxrwxr-x 1 wardens wardens 0 May 24 13:32 'All Glory, Laud and Honour'
drwxrwxr-x 1 wardens wardens 0 Mar  3 12:56 'All To Honour Jesus'
drwxrwxr-x 1 wardens wardens 0 Sep  7  2022 'Amazing Grace (My chains are gone)'
drwxrwxr-x 1 wardens wardens 0 Sep  7  2022 'Amazing Grace (Trad)'
...
```

Note that network shares are not a thing in Linux, so that option isn't used.

Also, the folder you mount needs to be writable by regular users.
Once that is done, a regular user can mount without `sudo`.


## Conclusion

[RClone](https://rclone.org/) is a viable work around to using shared OneDrive folders, so long as you can authenticate with the sharer, and don't mind occasional merge conflicts.

And I have started hearing rumours that Microsoft is restoring the local shared folder functionality. 
So I hope RClone won't be a work around for much longer.

Even so, RClone is a very useful tool at my disposal.
I'm sure it will be used in the future.
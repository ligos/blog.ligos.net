---
title: Experimenting With ZFS
date: 2019-08-24
tags:
- Linux
- Debian
- ZFS
- Experiment
- File System
- Best Practice
categories: Technical
---

Getting to grips with ZFS

<!-- more --> 

## Background

I'd like to start using [ZFS](https://en.wikipedia.org/wiki/ZFS).
I'd like to take advantage of its resiliency, protection against bit-rot, and maybe even some extra performance.

But ZFS is a complicated beast.
So before before I put it into production, I'd like to get a good understanding of how it works.
In particular, any best practices, gotchas, and (most of all) what to do when a disk fails and I need to replace it.

While I'm aware there are various "run these 5 commands and you'll have ZFS running on your machine" articles out there.
I want to take it slow.
And to have some documentation available when a disk inevitably fails.


## Goal

Develop an understanding of the following:

* The building blocks of ZFS, and how they fit together.
* Any gotchas I need to be aware of - and how to avoid them.
* How to add new disks to an existing array.
* How to replace a failed disk in an array.
* Any maintenance tasks that need to happen.

I have three concrete systems I'd like to deploy ZFS to, in order of readiness:

1. My recent K2SO server, which has 2 old 250GB spinning disks, and a 128GB SSD. This is already in service.
2. A planned remote backup node. Something which can be an off-site backup, but still within my city. Effectively, a custom NAS, probably with 2 x 6TB spinning disks.
3. Converting my existing media and file server to Linux. This has 4 x 1TB spinning disks, is currently running Windows and uses Storage Spaces for redundancy. However, because it's in service, it's lowest priority.

K2SO is running Debian Stretch, which is where I'll be experimenting.
I'm open to using [FreeNAS](https://www.freenas.org/) for other machines, if its simpler.

Once I've got my head around the concepts, I'll be doing practical tests on K2SO, including:

* Initial installation of ZFS.
* Creation of a basic array.
* A simulated disk failure and replacement.
* The addition of new disks.
* The retiring of old disks with larger ones.
* What happens when you fill a pool.

## ZFS Concepts

OK, time for some reading!

You can see the material I'm basing this article on at the bottom, under *References*.
I'll be making notes as I go along, and reference relevant sections.

The [FreeBSD handbook gives a useful glossery of ZFS concepts](https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/zfs-term.html
).
There isn't enough detail in there for a full conceptual understanding, but its a good place to start.
[Wikipedia's ZFS page](https://en.wikipedia.org/wiki/ZFS) has a surprisingly good conceptual description of vdevs and pools.


### 0. The 10000 Foot View

You have a bunch of disks.
You put them in a pool and ZFS does some magic to manage them all.
Finally, there's a file system presented on top of that.

<img src="/images/Experimenting-With-ZFS/ZFS-Conceptual-10000-foot-view.png" class="" width=300 height=300 alt="Disks in a pool, with ZFS magic." />

That is, ZFS is a way to pool lots of disks together and present them as a logical file system to your OS.

I'd go as far as saying that ZFS is a "pool orientated file system".
Or perhaps "pool centric" is the right term.
In any case, the pool is the main thing you work with in ZFS: disks go into a pool to provide underlying storage, and a file system is presented on top of that pool.
But the pool is the main "thing".


### 1. vdevs

The *vdev* is the fundamental ZFS unit of storage.
A vdev is where ZFS stores data.

It's also where all the meaningful redundency is implemented.
Mirrors, parity, RAID-Z all happens in vdevs, not in pools (although pools are aware of the redundency, and use it to their advantage).

So, we need a different picture:

<img src="/images/Experimenting-With-ZFS/ZFS-Conceptual-vdevs.png" class="" width=300 height=300 alt="Disks in vdevs in a pool, with ZFS magic." />

My own point of reference is [Microsoft Storage Spaces](https://docs.microsoft.com/en-us/windows-server/storage/storage-spaces/overview), which is different at this point.
Storage Spaces implements redundancy at the pool level (you make a "mirror" pool, throw disks at it, and Storage Spaces figures out how to allocate data such that required redundancy is met).
ZFS implements redundancy within vdevs (you pair individual disks together in mirrors).

In theory, this means ZFS can have a pool made up from mirrors and RAID-Z. 
In practice, I understand that is a bad idea (so don't copy the diagam above).

Because ZFS is *pool centric*, you cannot create a vdev without also adding it to a pool.
That is, I can't have 6 disks and create 3 mirrored vdevs.
Instead, I must create a pool, add 2 disks as a mirror, then the next two, and so on.
Conceptually, I find this a bit annoying; but it is what it is.

A bunch of vdev "facts":

* There are two major, and several minor, kinds of vdevs:
  * **Mirrors**: 2 way, 3 way and 1 way (which isn't really a mirror).
  * **RAID-Z**: data disks plus parity. Can have RAID-Z1, Z2 or Z3, which has one, two and three parity disks.
  * **Spare**: a hot spare disk.
  * **Log**: for the SLOG / ZIL, which improves synchronous write speed (ie: for databases which use transactions / `fsync()`). SSD recommended. Mirror recommended, but not essential.
  * **Cache**: for the L2ARC, which tiers commonly used data for reads onto faster disks. SSD recommended. Mirroring not required.
  * **File**: data provided by a file on disk. Mostly for testing purposes.
* Once you make a vdev, you can't modify it.
  * Except, you can go from unmirrored, to two way mirror, to three way mirror, and back again; RAID-Z isn't as forgiving.
* You can only add equal or larger disks to a mirror; excess storage won't be used.
  * Eg: 1TB mirror can add another 1TB or 2TB disk OK, but not a 500GB disk.
  * There is no rounding! So different models / vendor disks labelled as 1TB may be slightly different sizes - and will not work! Best to partition so there's a GB or two of headroom.
* In a mirror, if you replace *all* smaller disks with larger ones, you can gain access to the extra capacity.
* All redundency is at the vdev level.
  * Lose two disks in two different vdev mirrors and your data will still be OK.
  * Lose both disks in a vdev mirror and the whole pool is hosed.
* Individual disks are faster than two way mirrors, which are faster than three way mirrors, which are faster than RAID-Z1, which is faster than RAID-Z2, and RAID-Z3 is the slowest.
  * As with any blanket performance statements, you should work out your requirements and test under expected conditions to confirm if the above is true for you. Eg: If you're just writing backups once and hardly ever reading them, RAID-Z3 might be just fine.
* Removing disks from a vdev is... tricky. Some sources say you can, some say you can't. I think the functionality has appeared in newer versions of ZFS. And it only seems to apply to mirrors, not RAID-Z.
    


Vdev references:

* [Open ZFS](http://open-zfs.org/wiki/System_Administration#Low_level_storage)
* [Wikipedia](https://en.wikipedia.org/wiki/ZFS#Physical_storage_structure:_devices_and_virtual_devices)
* [Aaron Toponce](https://pthree.org/2012/12/04/zfs-administration-part-i-vdevs/)

### 2. Pools

Pools are a group of vdevs. 

Pools automatically load balance writes across all vdevs, so its better to keep the number of disks in a vdev to the absolute minimum, as long as you maintain the minimum redundency required.
That is, its better to have 6 disks in three 2 way mirrors than to have two 3 way mirrors (both in capacity and performance).
Even more so with RAID-Z: 8 disks will perform better when used as two 4 disk RAID-Z1 pools than one giant 8 disk vdev.

Here's some pictures (the first one is better):

<img src="/images/Experimenting-With-ZFS/ZFS-Conceptual-pools-optimal.png" class="" width=300 height=300 alt="It's better to do this." />

<img src="/images/Experimenting-With-ZFS/ZFS-Conceptual-pools-non-optimal.png" class="" width=300 height=300 alt="Than this." />


A bunch of pool "facts":

* The command to interact with pools is `zpool`.
* Adding additional vdevs to a pool is fine.
  * It's nice if the new vdevs are the same size as old ones, but the ZFS load balancing will sort things out over time.
* Pools have a *status*, which is usually ONLINE. Most other status' indicate something has gone wrong and the pool needs your attention.
* Pools in DEGRADED state will not automatically be fixed, even if you have a hot spare (unless you set the "autoreplace" property).
* *Resilvering* is the ZFS term for repairing a DEGRADED pool.
  * Although you can trigger resilvering without getting into a DEGRADED state.
* You can *replace* an existing disk in a pool, such that the pool never becomes DEGRADED and doesn't risk your data.
  * That is, you shouldn't just yank a bad disk out and stick a new one in. 
* Pools will automatically self-heal, using the redundency of vdevs and checksums. 
* The closest thing in ZFS to `fsck` or `chkdsk` is *scrubbing*.
  * This walks all data in the pool and verifies all checksums, fixing any problems as it goes.
* Mixing mirrors and RAID-Z vdevs in a pool is a bad idea; best to pick one or the other.
* Pools seem to have a unique id against them. So you can't just yank disks and move them to a different machine, you must *export* and *import* the pool.
* Pools are versioned based on the version of ZFS for your operating system. You need to *upgrade* your pool to use newer features.
  * With the more recent *feature flags* based versioning, moving pools between computers looks reasonably risky; you need to make sure the same features are supported on both operating systems.
* Pools have properties.
  * Some are calculated based on the pool itself, eg: size.
  * Some can be tweaked to change the characteristics of the pool, eg: changing the checksum algorithm.
  * Others can be enabled to opt into new features, eg: enabling compression.
  * And you can turn features off as well, eg: disable deduplication.
  * Important: Enabling or disabling a property does not change data already written; only new data uses the changed properties. So changing properties is always fast, but you may need to re-write data for it to take effect.
* Pool performance is usually pretty good for random reads and asynchronous writes.
  * Syncronous write performance can be improved by added an SSD as an SLOG / ZIL vdev.
  * Random read performance can be improved by adding more RAM or an SSD as a L2ARC vdev.
  * Pool capacity degrades when it fills. Over 80% full starts to significantly impact performance.
* *Deduplication* can be enabled on the pool, which will attempt to identify blocks of identical data and share their use between mulitple files.
  * As much as deduplication promises to magically save disk space, its usually more trouble than its worth.
  * Significantly more RAM is required for it to be fast, and most data isn't easily deduplicated anyway.

Pool references:

* [FreeBSD Handbook - Pool Basics](https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/zfs-quickstart.html)
* [FreeBSD Handbook - More Pools](https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/zfs-zpool.html)
* [Aaron Toponce on vdevs and Pools](https://pthree.org/2012/12/04/zfs-administration-part-i-vdevs/)
* [Aaron Toponce on Scrub / Resilver](https://pthree.org/2012/12/11/zfs-administration-part-vi-scrub-and-resilver/)
* [Aaron Toponce on Properties](https://pthree.org/2012/12/12/zfs-administration-part-vii-zpool-properties/)


### 3. Datasets and Volumes

Pools aggregate vdevs to provide logical storage. 
And vdevs provide raw storage to pools.
But we haven't seen a real filesystem yet!

ZFS lets you create datasets and volumes on top of a pool. 
So here's our final picture:

<img src="/images/Experimenting-With-ZFS/ZFS-Conceptual-datasets.png" class="" width=300 height=300 alt="Than this." />

A ZFS **dataset** is the closest thing to a filesystem: it provides a mountpoint and lets you do the usual file operations you expect (open, read, write, close, etc).
Space is always thinly provisioned from the pool.
And you can have lots of datasets on any one pool.

Each dataset can have different properties (eg: some doing compression, other not).
And datasets are defined in a heiarachy, so properties on the top level dataset automatically apply to children, unless overwritten.

A ZFS **volume** is a block device, which is backed by the ZFS pool.
You can use it to present as an iSCSI target, or for a raw VM disk, or to even create a non-ZFS filesystem on top of, like `ext4`.
I can't think of an obvious use case in my world for volumes, so I won't talk about them very much.


Dataset / volume "facts":

* The tool to interact with datasets or volumes is `zfs`.
* Datasets are always thin provisioned; only using space from the pool as required.
* Volumes are always thick provisioned; you must allocate their desired size up front.
* You get a root dataset for free when you create the pool.
  * So a pool called `tank` has a dataset called `tank` before you even run the `zfs` command.
* By convention, datasets are mounted based on their name
  * So that default pool dataset `tank` gets mounted at `/tank` by default.
  * Create `tank/logs` and it will end up on `/tank/logs`.
* Each dataset can access the full capacity of the underlying pool.
  * Of course, once the pool itself runs out of space, you're in trouble. But there's nothing to restrict the size of a dataset.
  * You can use *dataset quotas* to put an artificial limit on a single dataset (as well as the usual group / user quotas).
  * Conversely, a *dataset reservation* can dedicate a minimum chunk of the pool for a single dataset.
* Each dataset has *properties*, which inherit from the root to leaves.
  * These properties are frequently used to control features for particular datasets.
* ZFS can create point in time *snapshots* of datasets.
  * This lets you revert your dataset back to a particular point in time.
  * Because of how ZFS works, the initial snapshot is very cheap (in terms of time and space).
  * However, as current data diverges from a snapshot, additional space is required.
  * Lots of people think ZFS snapshots are the best thing since sliced bread. But, they aren't part of my initial use cases, so I won't go into detail about them.
* ZFS can use snapshots to *replicate* data to another server.
  * Differences between snapshots can be quickly calculated, so after the initial copy, subsequent updates only transfer changes.
* ZFS *compression* can be enabled per dataset, which tries to transparently compress / decompress blocks.
  * This trades off more CPU time (which is usually abundant) to potentially make less IOs (which are usually pretty expensive).
  * Overall, compression gives better results than deduplication, and doesn't require any more RAM.
* The prevailing wisdom seems to be: create many datasets. 
  * There's very little overhead in making them.
  * It gives you more options for isolating and administering your data.


Dataset and volume references:

* [Aaron Toponce on Filesystems](https://pthree.org/2012/12/17/zfs-administration-part-x-creating-filesystems/)
* [Aaron Toponce on Compression and Deduplication](https://pthree.org/2012/12/18/zfs-administration-part-xi-compression-and-deduplication/)
* [FreeBSD Handbook](https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/zfs-zfs.html)


### 4. You Can Usually Add, but Removing is... Tricky

ZFS is very flexible in terms of making changes while the filesystem is online.
This is particularly true of pools, and very true when you are adding.

But, things get tricky when you want to change or remove.

Shrinking a pool is just not supported.
In some respects, this makes sense: once you've allocated space, you can't really release it.
In practice, this means that once you add a vdev, you can't remove it from the pool - to reclaim one vdev you must destroy the whole pool.
(This restriction may be lifted in recent versions of ZFS on Linux, albeit with a performance penalty).

Another big restriction is that RAID-Z vdevs cannot be altered.
That is, you can't go from RAID-Z1 to RAID-Z2.
Mirrored vdevs don't seem to have this restriction (so you can do safe upgrades by making a two way mirror a temporary three way mirror, wait for the resilver, then remove an old disk).
The only way to go from RAID-Z1 to RAID-Z2 is to add a new vdev.
Although, that implies an additional 5 disks, and all my home storage enclosures would struggle to house that many disks at once.
So choose your vdev redundancy wisely!

Shrinking vdevs isn't a thing either.
You cannot introduce a new disk in a vdev which is smaller than existing ones.
Even one sector too small is too small.
And that means you should never use 100% capacity of disks, always reserve a few GB so that different model disks with the same advertised size will "fit" even if there's a few MB of difference.

As with my [experience with Windows Storage Spaces](/2017-12-11/Repairing-Storage-Spaces-After-Drive-Failure.html), always make sure your data is backed up.
That's true of any file system, storage provider, or even the cloud: if your data is is important enough to live on ZFS with checksums & mirroring, it's important enough to have another copy (or two) as a backup (at least one of which should be off-site).
If you get in trouble with ZFS, the main way out is: destroy your pool, re-create, and restore from backup.
(So make sure that backup is working)!

And keep things simple: ZFS has lots of cool features, but if all you need is a pair of mirrored disks then don't muck with the settings!

Large scale storage is tricky to do well, and there are plenty of ways you can make ZFS worse than optimal:


* [Aaron Toponce - zpool Caveats](https://pthree.org/2012/12/13/zfs-administration-part-viii-zpool-best-practices-and-caveats/)
* [Aaron Toponce - zfs Caveats](https://pthree.org/2013/01/03/zfs-administration-part-xvii-best-practices-and-caveats/)
* [ZFS on Linux - module paramters](https://github.com/zfsonlinux/zfs/wiki/ZFS-on-Linux-Module-Parameters)
* [Wikipedia - Inappropriately Specified Systems](https://en.wikipedia.org/wiki/ZFS#Inappropriately_specified_systems)
* [Wikipedia - ZFS Limitations](https://en.wikipedia.org/wiki/ZFS#Limitations)


## ZFS in Practice

OK, that's a stack of theory and heaps of reading I've done.

Time for practical tests.
I'm going to install ZFS on Linux on my Debian Stretch system, then run through some scenarios on

### Installing on Debian Stretch 

https://github.com/zfsonlinux/zfs/wiki/Debian

Add the backports repository:

```
$ cat /etc/apt/sources.list.d/stretch-backports.list
deb https://deb.debian.org/debian stretch-backports main contrib
deb-src http://deb.debian.org/debian stretch-backports main contrib

$ cat /etc/apt/preferences.d/90_zfs
Package: libnvpair1linux libuutil1linux libzfs2linux libzpool2linux spl-dkms zfs-dkms zfs-test zfsutils-linux zfsutils-linux-dev zfs-zed
Pin: release n=stretch-backports
Pin-Priority: 99
```

Do an `apt update` to load the new packages:

```
$ apt update
```

Install the kernel headers and other dependencies:

```
$ apt install dpkg-dev linux-headers-$(uname -r) linux-image-amd64
```

Install the zfs packages:

```
$ apt-get install zfs-dkms zfsutils-linux
```

This installs the [package for version 0.7 of ZFS for Linux](https://packages.debian.org/source/stretch-backports/zfs-linux).
There is a [version 0.8 package](https://packages.debian.org/source/experimental/zfs-linux), which has the latest features (including some ones around encryption and vdev removal), but its in the "experimental" Debian repository, so I'm going to hold off for now.

<img src="/images/Experimenting-With-ZFS/ZFS-License-Notice.png" class="" width=300 height=300 alt="License Notice: CDDL is incompatible with GPL." />

As part of the installation, you get a legal notice about the [GPL](http://www.gnu.org/licenses/gpl2.html) and [CDDL](http://hub.opensolaris.org/bin/view/Main/opensolaris_license) licenses: apparently [ZFS and Linux binaries can't be directly linked](https://github.com/zfsonlinux/zfs/wiki/FAQ#licensing), so we get a [DKMS kernel module](https://en.wikipedia.org/wiki/Dynamic_Kernel_Module_Support) instead of the usual monolithic Linux kernel binary.
Yay for legal things!

### A Test Pool

Then I make some testing files to create my first pool (following the lead of many ZFS examples, your pools should be named as various water holding objects - mine will be a [kiddy pool](https://www.bing.com/images/search?q=kiddy+pool)):

```
$ dd if=/dev/zero of=/mnt/disk2/zfs/vdisk_4g_1 bs=1G count=4
$ dd if=/dev/zero of=/mnt/disk2/zfs/vdisk_4g_2 bs=1G count=4
$ ls -shl /mnt/disk2/zfs
4.1G -rw-r--r-- 1 root root 4.0G Jun 10 12:57 vdisk_4g_1
4.1G -rw-r--r-- 1 root root 4.0G Jun 10 12:59 vdisk_4g_2
$ zpool create kiddypool mirror /mnt/disk2/zfs/vdisk_4g_1 /mnt/disk2/zfs/vdisk_4g_2
The ZFS modules are not loaded.
Try running '/sbin/modprobe zfs' as root to load them.
```

Well, that was disappointing.
You can get a list of current modules loaded by `cat /proc/modules`, and apparently zfs isn't loaded until it's needed.
I'll blindly follow the instructions...

```
$ modprobe zfs
$ zpool create kiddypool mirror /mnt/disk2/zfs/vdisk_4g_1 /mnt/disk2/zfs/vdisk_4g_2
$ zpool status kiddypool
  pool: kiddypool
 state: ONLINE
  scan: none requested
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddypool                      ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_1  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0

errors: No known data errors

$ zfs list
NAME        USED  AVAIL  REFER  MOUNTPOINT
kiddypool  85.5K  3.84G    24K  /kiddypool

$ ls / -al
...
drwxr-xr-x   2 root root     2 Jun 30 17:42 kiddypool
...
```

OK, that's much more promising!
I'll make some test datasets:

```
$ zfs create kiddypool/pictures
$ zfs create kiddypool/source

$ ls /kiddypool -l
drwxr-xr-x 2 root root 2 Jun 30 17:45 pictures
drwxr-xr-x 2 root root 2 Jun 30 17:45 source

$ zfs list
NAME                 USED  AVAIL  REFER  MOUNTPOINT
kiddypool            140K  3.84G    25K  /kiddypool
kiddypool/pictures    24K  3.84G    24K  /kiddypool/pictures
kiddypool/source      24K  3.84G    24K  /kiddypool/source
```

No point having datasets without data in them.
I've got the source code to Handbrake 1.2.2 available, plus some family pictures, so they'll do as test data:

```
$ cp -R ~/HandBrake-1.2.2 /kiddypool/source/
$ cp /mnt/disk1/syncthing/Pictures/*.jpg /kiddypool/pictures/
$ cp /mnt/disk1/syncthing/Pictures/*.JPG /kiddypool/pictures/

mujgrant@k2so:/mnt/disk2/zfs$ sudo du -sh /kiddypool/*
3.2G    /kiddypool/pictures
460M    /kiddypool/source

mujgrant@k2so:/mnt/disk2/zfs$ sudo zfs list
NAME                 USED  AVAIL  REFER  MOUNTPOINT
kiddypool           3.63G   215M    25K  /kiddypool
kiddypool/pictures  3.19G   215M  3.19G  /kiddypool/pictures
kiddypool/source     454M   215M   454M  /kiddypool/source

mujgrant@k2so:/mnt/disk2/zfs$ sudo zpool list
NAME        SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddypool  3.97G  3.63G   342M         -    27%    91%  1.00x  ONLINE  -
```

Yay!
I can haz ZFS :-)

Although, I've already broken one of the ZFS rules: don't use more than 80% capacity of a pool.
Woops.

Having read about the ARC, I checked memory usage during my copy.
It climbed from the usual usage of around 500MB for this machine to 1.5GB.
After a while, it dropped back to ~800M.

<img src="/images/Experimenting-With-ZFS/ZFS-Memory-Usage.png" class="" width=300 height=300 alt="ZFS uses lots of RAM." />

And just for fun, I scrubbed the pool:

```
mujgrant@k2so:/mnt/disk2/zfs$ sudo zpool scrub kiddypool
mujgrant@k2so:/mnt/disk2/zfs$ sudo zpool status
  pool: kiddypool
 state: ONLINE
  scan: scrub in progress since Sun Jun 30 17:59:26 2019
        83.1M scanned out of 3.63G at 16.6M/s, 0h3m to go
        0B repaired, 2.23% done
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddypool                      ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_1  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0

errors: No known data errors
```

And then destroyed the datasets, and the pool.

```
$ zfs destroy kiddypool/pictures
$ zfs destroy kiddypool/source
$ zpool destroy kiddypool

$ zfs list
no datasets available
$ zpool list
no pools available
```

### Pool and ZFS Properties

Next, I recreated my pool (spelling its name correctly this time), and listed all properties.
I want work out if any of the defaults should be changed.

```
$ zpool get all kiddiepool
NAME        PROPERTY                       VALUE                          SOURCE
kiddiepool  size                           3.97G                          -
kiddiepool  capacity                       0%                             -
kiddiepool  health                         ONLINE                         -
kiddiepool  autoreplace                    off                            default
kiddiepool  readonly                       off                            -
kiddiepool  ashift                         0                              default
... ~30 more ...
kiddiepool  feature@sha512                 enabled                        local
kiddiepool  feature@skein                  enabled                        local
kiddiepool  feature@edonr                  enabled                        local
```

```
$ zfs get all kiddiepool
NAME        PROPERTY              VALUE                  SOURCE
kiddiepool  type                  filesystem             -
kiddiepool  creation              Sun Jun 30 18:11 2019  -
kiddiepool  used                  84K                    -
kiddiepool  available             3.84G                  -
kiddiepool  referenced            24K                    -
kiddiepool  compressratio         1.00x                  -
kiddiepool  mounted               yes                    -
kiddiepool  quota                 none                   default
kiddiepool  reservation           none                   default
kiddiepool  recordsize            128K                   default
kiddiepool  mountpoint            /kiddiepool            default
kiddiepool  compression           off                    default
kiddiepool  atime                 on                     default
kiddiepool  relatime              off                    default
... ~50 more ...
```

In addition to pool and dataset properties, there's a stack of [Linux module properties](https://github.com/zfsonlinux/zfs/wiki/ZFS-on-Linux-Module-Parameters).
You can see the actual reference for your system by `man zfs-module-parameters`.

```
$ modinfo zfs
filename:       /lib/modules/4.9.0-9-amd64/updates/dkms/zfs.ko
version:        0.7.12-1~bpo9+1
license:        CDDL
author:         OpenZFS on Linux
description:    ZFS
srcversion:     A6D1B0339439B948E6BF693
depends:        spl,znvpair,zcommon,zunicode,zavl,icp
retpoline:      Y
vermagic:       4.9.0-9-amd64 SMP mod_unload modversions
parm:           zvol_inhibit_dev:Do not create zvol device nodes (uint)
... a few hundred more ...
parm:           zfs_abd_scatter_max_order:Maximum order allocation used for a scatter ABD. (uint)
```

That's a lot of knobs and dials to make sense of.
But I'd like to get an idea of any best practices which deviate from the defaults.
Here's what I've come up with, in order of importance:

* **Pool ashift**: 9 for 512 byte sectors, 12 for 4kB sectors, 13 for 8kB SSD blocks. If ZFS has direct visibility of the disk and the disk controller isn't lying about its sector size, this is automatic. However, because it can only be set at creation, you should use **12** for future proofing (otherwise you run into problems when you add a new 10TB disk with 4kB sectors, when your original 1TB disks had 512 byte sectors).
* **Kernel zfs_arc_max**: lets you limit the size of the ARC. If your system is running low on memory, this can help avoid out of memory errors. ARC uses up to two thirds (or one half, depending on the source) of physical memory (and the kernel will continue to allocate normal disk buffer), so reducing this can be important.
* **Dataset dedup**: deduplication should be disabled, unless you know you need it (hint: you don't).
* **Dataset atime**: can be disabled to stop metadata writes on file access.
* **Dataset relatime**: a compromise between `atime=off` and `atime=on`.
* **Pool autoreplace**: turn it on if you plan on have hot spares in your pool.
* **Dataset quota**: to restrict a particular dataset from growing beyond a given size.
* **Dataset recordsize**: the largest size of blocks used for files. Defaults to 128kB. You may see better performance for lots of small random writes if you use 8kB (ie: databases). Consider changing this on a per-dataset basis.
* **Dataset primarycache**: lets you disable the ARC for a dataset. Again, useful for databases which are doing their own caching.

I think that's the most important things.

### Scenario #1 - Disk Failure

Here's my *kiddiepool*, which is a mirrored vdev.

```
$ zpool status kiddiepool
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 19:48:35 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_1  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0

errors: No known data errors
```

Let's pretend we had some kind of failure on one of our mirrored disks, and it's now filled with zeros.

```
$ dd if=/dev/zero of=/mnt/disk2/zfs/vdisk_4g_1 bs=1G count=4
4+0 records in
4+0 records out
4294967296 bytes (4.3 GB, 4.0 GiB) copied, 36.0505 s, 119 MB/s

$ zpool status kiddiepool
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 19:48:35 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_1  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0
```

Hmm... that's not what I expected after one disk got nuked from orbit.
Let's try a scrub:

```
$ zpool scrub kiddiepool
$ zpool status kiddiepool
  pool: kiddiepool
 state: DEGRADED
status: One or more devices could not be used because the label is missing or
        invalid.  Sufficient replicas exist for the pool to continue
        functioning in a degraded state.
action: Replace the device using 'zpool replace'.
   see: http://zfsonlinux.org/msg/ZFS-8000-4J
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 19:51:26 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     DEGRADED     0     0     0
          mirror-0                     DEGRADED     0     0     0
            /mnt/disk2/zfs/vdisk_4g_1  UNAVAIL      0     0     0  corrupted data
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0

errors: No known data errors
```

That looks better... err... worse... err... more expected.
The [ZFS-8000-4J](http://zfsonlinux.org/msg/ZFS-8000-4J) link is actually pretty helpful, giving some examples of `zpool replace`.
Well, let's follow their example:

```
$ zpool replace kiddiepool /mnt/disk2/zfs/vdisk_4g_1 /mnt/disk2/zfs/vdisk_4g_6
$ zpool status kiddiepool
  pool: kiddiepool
 state: ONLINE
  scan: resilvered 122K in 0h0m with 0 errors on Thu Aug 22 19:57:55 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0

errors: No known data errors
```

That was very easy!

Note that ZFS automatically resilvered when I replaced the failed disk.

See also [ArchLinux simulated disk failure](https://wiki.archlinux.org/index.php/ZFS/Virtual_disks#Simulate_a_Disk_Failure_and_Rebuild_the_Zpool)

### Scenario #1.1 - Disk Failure of SLOG / External ZIL

If your SLOG / external ZIL failed on older versions of ZFS, you'd lose your whole pool.
On more recent versions, you now just lose any uncommitted transactions.
That's a pretty big difference, so I want to test this!

First off, we add a *log* device (and I'll copy some data as well):

```
$ zpool add kiddiepool log /mnt/disk2/zfs/vdisk_4g_4
$ zpool status kiddiepool
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 20:41:46 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0
        logs
          /mnt/disk2/zfs/vdisk_4g_4    ONLINE       0     0     0

errors: No known data errors

$ zfs list
NAME         USED  AVAIL  REFER  MOUNTPOINT
kiddiepool   455M  3.40G   454M  /kiddiepool
```

Oh no! 
Once again, something went horribly wrong with our disks:

```
$ dd if=/dev/zero of=/mnt/disk2/zfs/vdisk_4g_5 bs=1G count=4
$ zpool scrub kiddiepool
$ zpool status kiddiepool
  pool: kiddiepool
 state: DEGRADED
status: One or more devices could not be used because the label is missing or
        invalid.  Sufficient replicas exist for the pool to continue
        functioning in a degraded state.
action: Replace the device using 'zpool replace'.
   see: http://zfsonlinux.org/msg/ZFS-8000-4J
  scan: scrub in progress since Thu Aug 22 20:48:09 2019
        55.4M scanned out of 454M at 13.8M/s, 0h0m to go
        0B repaired, 12.19% done
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     DEGRADED     0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0
        logs
          /mnt/disk2/zfs/vdisk_4g_4    UNAVAIL      0     0     0  corrupted data

errors: No known data errors
```

Remember to `scrub` before any errors become visible.

I was able to continue to use the pool, even through the `logs` disk wasn't available.

Let's replace it:

```
$ zpool replace kiddiepool /mnt/disk2/zfs/vdisk_4g_4 /mnt/disk2/zfs/vdisk_4g_5
$ zpool status kiddiepool
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 20:51:04 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0
        logs
          /mnt/disk2/zfs/vdisk_4g_5    ONLINE       0     0     0

errors: No known data errors
```

You can even remove the `logs` disk from the pool:

```
$ zpool remove kiddiepool /mnt/disk2/zfs/vdisk_4g_5
$ zpool status
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 20:51:04 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0

errors: No known data errors
```

Overall, that was pretty easy!

### Scenario #2 - Adding Disks

A common scenaro: I started with small disks, then at some point in the future, I got some bigger ones.


```
$ zpool status
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 20:51:04 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0

errors: No known data errors

$ zpool list
NAME         SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  3.97G   454M  3.53G         -     3%    11%  1.00x  ONLINE  -
```

I have some new and shiny 8GB disks I'd like to add to my pool:

```
$ zpool add kiddiepool mirror /mnt/disk2/zfs/vdisk_8g_1 /mnt/disk2/zfs/vdisk_8g_2
$ zpool status
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 20:51:04 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_4g_2  ONLINE       0     0     0
          mirror-1                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_1  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_2  ONLINE       0     0     0

errors: No known data errors

$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  11.9G   454M  11.5G         -     1%     3%  1.00x  ONLINE  -
  mirror  3.97G   454M  3.53G         -     3%    11%
    /mnt/disk2/zfs/vdisk_4g_6      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_4g_2      -      -      -         -      -      -
  mirror  7.94G  21.5K  7.94G         -     0%     0%
    /mnt/disk2/zfs/vdisk_8g_1      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_2      -      -      -         -      -      -
```

That's great!
I've added new disks and my pool capacity has gone up!

Unfortunately, my existing data is still on my old disks.
If I copy new data, it gets balanced between the two vdevs pretty evenly.

```
$  zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  11.9G   909M  11.0G         -     1%     7%  1.00x  ONLINE  -
  mirror  3.97G   676M  3.31G         -     4%    16%
    /mnt/disk2/zfs/vdisk_4g_6      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_4g_2      -      -      -         -      -      -
  mirror  7.94G   233M  7.71G         -     0%     2%
    /mnt/disk2/zfs/vdisk_8g_1      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_2      -      -      -         -      -      -
```

But I can't remove vdevs from my pool:

```
$ zpool remove kiddiepool /mnt/disk2/zfs/vdisk_4g_6 /mnt/disk2/zfs/vdisk_4g_2
cannot remove /mnt/disk2/zfs/vdisk_4g_6: only inactive hot spares, cache, or log devices can be removed
cannot remove /mnt/disk2/zfs/vdisk_4g_2: only inactive hot spares, cache, or log devices can be removed
```

### Scenario #2.1 - Adding Larger Disks, and Retiring the Old Ones

So we can't remove vdevs, but we can replace mirrored disks one by one with larger ones.

```
$ zpool zpool replace kiddiepool /mnt/disk2/zfs/vdisk_4g_6 /mnt/disk2/zfs/vdisk_8g_3
$ zpool status
$ zpool status
  pool: kiddiepool
 state: ONLINE
status: One or more devices is currently being resilvered.  The pool will
        continue to function, possibly in a degraded state.
action: Wait for the resilver to complete.
  scan: resilver in progress since Thu Aug 22 21:07:20 2019
        691M scanned out of 909M at 11.9M/s, 0h0m to go
        568M resilvered, 76.01% done
config:

        NAME                             STATE     READ WRITE CKSUM
        kiddiepool                       ONLINE       0     0     0
          mirror-0                       ONLINE       0     0     0
            replacing-0                  ONLINE       0     0     0
              /mnt/disk2/zfs/vdisk_4g_6  ONLINE       0     0     0
              /mnt/disk2/zfs/vdisk_8g_3  ONLINE       0     0     0  (resilvering)
            /mnt/disk2/zfs/vdisk_4g_2    ONLINE       0     0     0
          mirror-1                       ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_1    ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_2    ONLINE       0     0     0

errors: No known data errors
```

This takes a bit longer as ZFS is resilvering from my old 4GB disk to the new 8GB one.
On the other hand, ZFS is also making sure my valuable data isn't lost in the process of upgrading disks!

```
$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  11.9G   909M  11.0G         -     1%     7%  1.00x  ONLINE  -
  mirror  3.97G   675M  3.31G         -     4%    16%
    /mnt/disk2/zfs/vdisk_8g_3      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_4g_2      -      -      -         -      -      -
  mirror  7.94G   234M  7.71G         -     0%     2%
    /mnt/disk2/zfs/vdisk_8g_1      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_2      -      -      -         -      -      -
```

Note that I'm not enjoying my new 8GB disks until I replace both. Let's do that:

```
$ zpool replace kiddiepool /mnt/disk2/zfs/vdisk_4g_2 /mnt/disk2/zfs/vdisk_8g_4
$ zpool status kiddiepool
mujgrant@k2so:~$ sudo zpool status
  pool: kiddiepool
 state: ONLINE
  scan: resilvered 675M in 0h0m with 0 errors on Thu Aug 22 21:11:53 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_3  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_4  ONLINE       0     0     0
          mirror-1                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_1  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_2  ONLINE       0     0     0

errors: No known data errors

$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  11.9G   909M  11.0G         -     1%     7%  1.00x  ONLINE  -
  mirror  3.97G   675M  3.31G         -     4%    16%
    /mnt/disk2/zfs/vdisk_8g_3      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_4      -      -      -         -      -      -
  mirror  7.94G   234M  7.71G         -     0%     2%
    /mnt/disk2/zfs/vdisk_8g_1      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_2      -      -      -         -      -      -
```

Bummer!
I still don't have my 8GB disks usable at full capacity - they're still only using 4GB.

Let's try a scrub (as this often helps ZFS notice things which have changed):

```
$ zpool scrub kiddiepool
$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  11.9G   910M  11.0G        4G     1%     7%  1.00x  ONLINE  -
  mirror  3.97G   676M  3.31G     4.00G     4%    16%
    /mnt/disk2/zfs/vdisk_8g_3      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_4      -      -      -         -      -      -
  mirror  7.94G   234M  7.71G         -     0%     2%
    /mnt/disk2/zfs/vdisk_8g_1      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_2      -      -      -         -      -      -
```

Well, at least it knows there's 4GB of `EXPANDSZ` space, even if its not available for use.
Apparently you need to tell ZFS to *grow* vdevs after they are *replaced*:

```
$ zpool online kiddiepool /mnt/disk2/zfs/vdisk_8g_3 -e
$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  15.9G   908M  15.0G         -     1%     5%  1.00x  ONLINE  -
  mirror  7.97G   675M  7.31G         -     2%     8%
    /mnt/disk2/zfs/vdisk_8g_3      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_4      -      -      -         -      -      -
  mirror  7.94G   233M  7.71G         -     0%     2%
    /mnt/disk2/zfs/vdisk_8g_1      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_2      -      -      -         -      -      -
```

At last! My new 8GB disks are online and in use!

### Scenario #4 - Filling the Pool and Recovering

Storage Spaces never coped very well if you filled the pool to capacity, so I always deliberately underprovisioned.
I'd like to see what ZFS does when there's zero bytes available in a pool.


```
$ cp -r /mnt/disk1/syncthing/Pictures/ /kiddiepool/Pictures1
$ cp -r /mnt/disk1/syncthing/Pictures/ /kiddiepool/Pictures2
$ cp -r /mnt/disk1/syncthing/Pictures/ /kiddiepool/Pictures3
...
$ cp -r /mnt/disk1/syncthing/Pictures/ /kiddiepool/Pictures9999
cp: cannot create regular file '/kiddiepool/Pictures4/20150103_IMG_5627.JPG': No space left on device

$ zpool status kiddiepool
  pool: kiddiepool
 state: ONLINE
  scan: scrub repaired 0B in 0h0m with 0 errors on Thu Aug 22 21:14:16 2019
config:

        NAME                           STATE     READ WRITE CKSUM
        kiddiepool                     ONLINE       0     0     0
          mirror-0                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_3  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_4  ONLINE       0     0     0
          mirror-1                     ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_1  ONLINE       0     0     0
            /mnt/disk2/zfs/vdisk_8g_2  ONLINE       0     0     0

errors: No known data errors

$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
kiddiepool  15.9G  15.4G   508M         -    44%    96%  1.00x  ONLINE  -
  mirror  7.97G  7.76G   213M         -    49%    97%
    /mnt/disk2/zfs/vdisk_8g_3      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_4      -      -      -         -      -      -
  mirror  7.94G  7.65G   294M         -    40%    96%
    /mnt/disk2/zfs/vdisk_8g_1      -      -      -         -      -      -
    /mnt/disk2/zfs/vdisk_8g_2      -      -      -         -      -      -

$ df -h
Filesystem                      Size  Used Avail Use% Mounted on
udev                            3.9G     0  3.9G   0% /dev
tmpfs                           788M   80M  708M  11% /run
/dev/sda2                        55G  3.5G   49G   7% /
...
kiddiepool                       16G   16G     0 100% /kiddiepool
```

According to `zpool list`, ZFS has reserved a small amount of space to allow it to continue operating. At this point, I could add new disks (those old 4GB ones should get me out of trouble). Or, I could simply remove some junk. Storage Spaces let you do the former, but not the latter - a full pool was made read-only.

ZFS certainly does better in this scenario.


## Final Deployment

My final deployment of ZFS on K2SO is pretty simple: 2 x 250GB spinning disks in a mirror.
Plus an 4GB partition set aside on the boot disk (SSD) for ZIL / SLOG.

```
$ cat /etc/modprobe.d/zfs.conf:
options zfs zfs_arc_max=4294967296
```

Here I set the maximum memory for the ARC to 4GB.
K2SO has 8GB of RAM, so 4GB should be a reasonable amount for the ARC.

```
$ zpool create -o ashift=12 -m /mnt/zfsdata zfsdata mirror \
                  /dev/disk/by-id/ata-ST3250312AS_9VYEMSGQ \
                  /dev/disk/by-id/ata-ST3250312AS_9VYEN7B6

$ zpool status -v
  pool: zfsdata
 state: ONLINE
  scan: none requested
config:

        NAME                          STATE     READ WRITE CKSUM
        zfsdata                       ONLINE       0     0     0
          mirror-0                    ONLINE       0     0     0
            ata-ST3250312AS_9VYEMSGQ  ONLINE       0     0     0
            ata-ST3250312AS_9VYEN7B6  ONLINE       0     0     0

errors: No known data errors

$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
zfsdata   232G   468K   232G         -     0%     0%  1.00x  ONLINE  -
  mirror   232G   468K   232G         -     0%     0%
    ata-ST3250312AS_9VYEMSGQ      -      -      -         -      -      -
    ata-ST3250312AS_9VYEN7B6      -      -      -         -      -      -

$ zfs list
NAME      USED  AVAIL  REFER  MOUNTPOINT
zfsdata   360K   225G    96K  /mnt/zfsdata
```

And then actually create my zpool, called `zfsdata`.
Creative, aren't I.

I specified an `ashift` of `12` to use 4kB blocks.
And a mount point at `/mnt/zfsdata`.
Disks were referenced via the Linux `/dev/disk/by-id` convention, which identifies disks by model and serial number, and won't change even if I move disks between controllers or to different SATA ports.
Note that I'm also using whole disks; I figure that 250GB is so small that any replacement disk will be bigger anyway.

```
$ zfs set relatime=on zfsdata
$ zfs set compression=on zfsdata
$ zfs set dedup=off zfsdata
```

I set some defaults for the root dataset: `relatime`, `compression` and no `dedup`.

```
$ zfs create zfsdata/syncthing

$ zfs list
NAME                USED  AVAIL  REFER  MOUNTPOINT
zfsdata             456K   225G    96K  /mnt/zfsdata
zfsdata/syncthing    96K   225G    96K  /mnt/zfsdata/syncthing
```

Then I created a separate dataset for my [Syncthing](https://syncthing.net/) data.
Each application will get its own dataset.

```
$ zpool add zfsdata log /dev/disk/by-partuuid/f068adc9-be7e-4d96-9172-e42362b6959a
$ zpool status
  pool: zfsdata
 state: ONLINE
  scan: scrub repaired 0B in 0h1m with 0 errors on Fri Aug 23 22:37:00 2019
config:

        NAME                                    STATE     READ WRITE CKSUM
        zfsdata                                 ONLINE       0     0     0
          mirror-0                              ONLINE       0     0     0
            ata-ST3250312AS_9VYEMSGQ            ONLINE       0     0     0
            ata-ST3250312AS_9VYEN7B6            ONLINE       0     0     0
        logs
          f068adc9-be7e-4d96-9172-e42362b6959a  ONLINE       0     0     0

errors: No known data errors

$ zpool list -v
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
zfsdata   232G  8.29G   224G         -     0%     3%  1.00x  ONLINE  -
  mirror   232G  8.29G   224G         -     0%     3%
    ata-ST3250312AS_9VYEMSGQ      -      -      -         -      -      -
    ata-ST3250312AS_9VYEN7B6      -      -      -         -      -      -
log      -      -      -         -      -      -
  f068adc9-be7e-4d96-9172-e42362b6959a  3.97G      0  3.97G         -     0%     0%
```

Finally, I add a 4GB partition on the SSD to be an external ZIL.
As I'm not using the whole SSD, it it reference by the UUID for the GPT partition.

### Partitions

Just for the record, here's how ZFS partitions your disks.

When it takes over an entire dist, it creates a GPT with one large ZFS partition (labelled *Solaris /usr & Apple ZFS* in [fdisk](https://www.tecmint.com/fdisk-commands-to-manage-linux-disk-partitions/), type `6A898CC3-1DD2-11B2-99A6-080020736631`), and a tiny reserved partition.
I presume the reserved one is for metadata.

```
Disk /dev/sdc: 232.9 GiB, 250059350016 bytes, 488397168 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 02AA9175-A2A7-EA41-BA60-2E56D05FC629

Device         Start       End   Sectors   Size Type
/dev/sdc1       2048 488380415 488378368 232.9G Solaris /usr & Apple ZFS
/dev/sdc9  488380416 488396799     16384     8M Solaris reserved 1
```

And this is how I partitioned the ZIL / SLOG partition:

```
Disk /dev/sda: 119.2 GiB, 128035676160 bytes, 250069680 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: A2764118-9C3B-4D67-8121-3CF3EC46666A

Device         Start       End   Sectors  Size Type
/dev/sda1       2048   1050623   1048576  512M EFI System
/dev/sda2    1050624 118237183 117186560 55.9G Linux filesystem
/dev/sda3  118237184 133861375  15624192  7.5G Linux swap
/dev/sda4  133861376 142249983   8388608    4G Solaris /usr & Apple ZFS
```

### Maintenance

The main maintenance task required for ZFS is a regular `zfs scrub` to check disks for errors and automatically repair.
Recommendations for consumer disks are to scrub weekly.
Here is an appropriate systemd timer (you'll need one for each zpool, if you have many):

```
$ cat /etc/systemd/system/zfs-scrub.timer

[Unit]
Description=Weeky zpool scrub

[Timer]
OnCalendar=weekly
AccuracySec=1h
Persistent=true

[Install]
WantedBy=multi-user.target


$ cat /etc/systemd/system/zfs-scrub.service

[Unit]
Description=Weekly zpool scrub

[Service]
Nice=19
IOSchedulingClass=idle
KillSignal=SIGINT
ExecStart=/sbin/zpool scrub zfsdata


$ systemctl daemon-reload
$ systemctl enable zfs-scrub.timer
$ systemctl start zfs-scrub.timer
$ systemctl start zfs-scrub.service

$ zpool status
  pool: zfsdata
 state: ONLINE
  scan: scrub in progress since Fri Aug 23 22:35:31 2019
        5.14G scanned out of 8.29G at 92.4M/s, 0h0m to go
        0B repaired, 62.07% done
config:

        NAME                          STATE     READ WRITE CKSUM
        zfsdata                       ONLINE       0     0     0
          mirror-0                    ONLINE       0     0     0
            ata-ST3250312AS_9VYEMSGQ  ONLINE       0     0     0
            ata-ST3250312AS_9VYEN7B6  ONLINE       0     0     0

errors: No known data errors

```


## References

The following sources were used when making this article:

* [Wikipedia's ZFS article](https://en.wikipedia.org/wiki/ZFS) - gives a surprisingly detailed conceptual overview.
* [Aaron Toponce's ZFS series](https://pthree.org/2012/04/17/install-zfs-on-debian-gnulinux/) - a little old (written in 2012), but detailed and practical.
* [OpenZFS Wiki](http://open-zfs.org/wiki/Main_Page) - official, but not as detailed as I'd hoped.
* [FreeBSD Handbook](https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/zfs.html) - ZFS has been available on FreeBSD for 10+ years, and the documentation reflects that! 
* [Oracle Solaris ZFS Administration Guide](https://docs.oracle.com/cd/E26505_01/pdf/E37384.pdf) - 300 pages of PDF covering pretty much everything. From 2013.
* [ArsTech Article on ZFS on Linux 0.8](https://arstechnica.com/gadgets/2019/06/zfs-features-bugfixes-0-8-1/) - highlighting recently available features.
* [OpenZFS on Linux FAQ](https://github.com/zfsonlinux/zfs/wiki/FAQ) - A variety of useful information.
* [FreeNAS Documentation](https://www.ixsystems.com/documentation/freenas/11.2-U5/freenas.html) - FreeNAS uses ZFS under the hood, and also provides good documentation.
* [Debian Documentation](https://wiki.debian.org/ZFS) - Introduction from Debian Wiki
* [Arch Linux Documentation](https://wiki.archlinux.org/index.php/ZFS) - More detailed wiki on ZFS.
* [Gentoo Linux Documentation](https://wiki.gentoo.org/wiki/ZFS) - Another ZFS overview, from Gentoo this time.
* [ZFS Best Practices Guide](https://www.serverfocus.org/zfs-best-practices-guide) - From ServerFocus, and lists a whole stack of things to keep in mind.
* [OpenZFS Basics by Matt Ahrens and George Wilson](https://www.youtube.com/watch?v=MsY-BafQgj4) - YouTube video.
https://www.youtube.com/watch?v=x9A0dX2WqW8 - Today's ZFS Michael W Lucas

## Conclusion

Wow! That was longer than I thought!

Actually, ZFS is there to store my precious photos of kids, so I want to understand it.
Losing data is never a fun experience.
So, what's a few thousand words to make sure my data is safe?

I've walked through the most important ZFS concepts: `vdevs`, `pools`, and `datasets`.
And put them into practice on a Debian Stretch machine.
And, tested a few obvious scenarios ZFS will need to cope with: disk failures, running out of space.
And, made a huge list of resources.

Hopefully this will keep my precious data safe, and maybe help someone else do the same.

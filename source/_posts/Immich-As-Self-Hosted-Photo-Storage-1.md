---
title: Immich as Self-Hosted Photo Storage - Part 1
date: 2026-08-29
tags:
- Debian
- Photos
- Immich
- Server
- Self-Hosted
- Android-App
- Docker
categories: Technical
---

My new Immich server to store personal photos.

<!-- more --> 

## Background

I have around 600GB of personal photos and videos collected over the last 25 years. But they are stored as a bunch of files on disk. It would be nice if I could more easily search and share them.

I have used [Lazygal](https://sml.zincube.net/~niol/repositories.git/lazygal/about/) to make photos available online. But that is just making thumbnails. 

I use [Syncthing](https://syncthing.net/) to upload photos from phones to my [TrueNAS](https://www.truenas.com/) box, and then a small dotnet app to do some minor post processing. But Syncthing isn't really a photo sharing app.

I would like something better. Perhaps [Immich](https://immich.app/) will be that something.

## Goal

I'm in the proof of concept stage at the moment, so my goal is:

- Install and configure [Immich](https://immich.app/) on a new Debian server.
- Configure photos from my phone to upload photos to my shiny new Immich server.
- Don't interrupt any other processes which are working just fine.
- Begin evaluating if Immich might be good for family members to upload, search and share photos.

## Hardware

I will run Immich on an end-of-life desktop I obtained from a company I did some work for years ago. All the parts are old, but usable:

- **CPU**: [i5-2400](https://www.intel.com/content/www/us/en/products/sku/52207/intel-core-i52400-processor-6m-cache-up-to-3-40-ghz/specifications.html) with 4 cores
- **RAM**: 12GB of DDR3
- **Disks**: 
  - 500GB HDD for boot and root
  - 256GB SSD for Postgres and swap
  - 2x1TB HDDs for Immich data (photos, thumbnails, backups, etc)

[Immich recommended minimum hardware](https://docs.immich.app/install/requirements) is 2 CPU cores and 8GB RAM, so I think I should be OK.

This server will be placed on my `hosting` network, which is isolated from main LAN, because it will be accessible to the public internet (behind an nginx reverse proxy for HTTPS and geo-blocking; details in a future post).

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Tarkin-Front.jpg" class="" width=300 height=300 alt="My New Immich Server Named Tarkin" /> 

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Tarkin-Top.jpg" class="" width=300 height=300 alt="The Inards of Tarkin" /> 

## Installation

I start my install as per the [Debian 13 Trixie](/2026-08-01/Debian-13-Trixie.html) conventions for a server, with the following configuration for disks during OS install:

- `/` is on a HDD
- `/srv` is on an SSD for Postgres
- `swap` is on the SSD as well
- `/mnt/zfsdata` will be the [ZFS](/2019-08-24/Experimenting-With-ZFS.html) mirrored HDDs


FDisk output:

```
Disk /dev/sdc: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: HGST HTS725050A7
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: A594F35D-3105-45CC-BC93-DD4B200CD6D8

Device       Start       End   Sectors   Size Type
/dev/sdc1     2048   2000895   1998848   976M EFI System
/dev/sdc2  2000896 976771071 974770176 464.8G Linux filesystem


Disk /dev/sda: 238.47 GiB, 256060514304 bytes, 500118192 sectors
Disk model: INTEL SSDSC2KW25
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 7F7A8E0C-F033-4A69-B5AE-A4E395A2E21A

Device        Start       End   Sectors   Size Type
/dev/sda1      2048  39063551  39061504  18.6G Linux swap
/dev/sda2  39063552 500117503 461053952 219.8G Linux filesystem


Disk /dev/sdb: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
Disk model: ST1000DM003-1CH1
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: B7DA82E7-B545-F141-A238-12D872510A3B

Device          Start        End    Sectors   Size Type
/dev/sdb1        2048 1953507327 1953505280 931.5G Solaris /usr & Apple ZFS
/dev/sdb9  1953507328 1953523711      16384     8M Solaris reserved 1



Disk /dev/sdd: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
Disk model: ST1000DM003-1CH1
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 18498ABC-FC5F-134F-8FB4-39C9FA858709

Device          Start        End    Sectors   Size Type
/dev/sdd1        2048 1953507327 1953505280 931.5G Solaris /usr & Apple ZFS
/dev/sdd9  1953507328 1953523711      16384     8M Solaris reserved 1
```

Mount points:

```
/dev/sdc2      on /                   type ext4 (rw,relatime,errors=remount-ro)
/dev/sda2      on /srv                type ext4 (rw,relatime)
zfsdata        on /mnt/zfsdata        type zfs  (rw,relatime,xattr,noacl,casesensitive)
zfsdata/immich on /mnt/zfsdata/immich type zfs  (rw,relatime,xattr,noacl,casesensitive)
```

Hmm... seems I physically attached the disks to random SATA ports. I like that modern systems don't really care.


## Configuration

Initial configuration followed my [server configuration for Debian 13 Trixie](/2026-08-01/Debian-13-Trixie.html) steps. Nothing too exciting here.

### ZFS

I configured the two 1TB HDDs as a zfs mirror, so they are mounted at `/mnt/zfsdata`:

```sh
$ zpool list -v
NAME                                  SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zfsdata                               928G   516K   928G        -         -     0%     0%  1.00x    ONLINE  -
  mirror-0                            928G   516K   928G        -         -     0%  0.00%      -    ONLINE
    ata-ST1000DM003-1CH162_S1DACJC4   932G      -      -        -         -      -      -      -    ONLINE
    ata-ST1000DM003-1CH162_Z1D610HZ   932G      -      -        -         -      -      -      -    ONLINE
```

```sh
$ zfs list
NAME             USED  AVAIL  REFER  MOUNTPOINT
zfsdata          516K   899G    96K  /mnt/zfsdata
zfsdata/immich    96K   899G    96K  /mnt/zfsdata/immich
```

And configured ARC to use up to 2GB of RAM. Which should leave a comfortable 8GB for Immich.

```sh
cat /etc/modprobe.d/zfs.conf 
options zfs zfs_arc_max=2147483648
```

### Docker Installation

It may surprise people to learn I have never used [Docker](https://www.docker.com/). That is mostly because I learned server admin before Docker was invented (and even before Virtual Machines were common), so figured out ways of solving the problems Docker addresses in other ways. 

However, the [recommended way to install Immich is using Docker](https://docs.immich.app/install/docker-compose). So time to learn something new!

[Docker has installation instructions for Debian](https://docs.docker.com/engine/install/debian/), which are pretty standard fare.

Add the Docker public key and `apt` repo (these commands are a summary, see the official doco for every command):

```sh
$ curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc

$ cat /etc/apt/sources.list.d/docker.sources
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
```

Install packages a bunch of packages:

```sh
$ apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Confirm the new services are running and enabled on startup:

```sh
$ systemctl enable docker.service
$ systemctl enable containerd.service
```

And finally, run the `hello world` example to confirm everything is happy:

```sh
$ sudo docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Again, I'm summarising the steps, please check the [official doco](https://docs.docker.com/engine/install/debian/) for all the details.

### Docker Configuration

Post install, there are some [recommended steps to configure Docker](https://docs.docker.com/engine/install/linux-postinstall/).

I didn't bother creating a `docker` group as this is a server and I don't mind sticking `sudo` in front of every command.

But, the default settings for logging seem to risk filling up the disk, which seems like a bad choice, so I [changed logging](https://docs.docker.com/engine/logging/configure/#configure-the-default-logging-driver) to use the `local` log-driver in `/etc/docker/daemon.json`. I also set log mode to `non-blocking`.

My `/etc/docker/daemon.json`:

```json
{
  "log-driver": "local",
  "log-opts": {
    "mode": "non-blocking"
  }
}
```

Apparently, the defaults are not sane, but retained for back compatibility. Sigh. 

I guess it could be much worse.


### Immich

Time to install the thing I came to install!

I followed the [Immich instructions to install using docker compose](https://docs.immich.app/install/docker-compose).

Decided to install into `/srv/immich`, which should put most Immich related binaries on the SSD. I downloaded the `docker-compose.yml` and `example.env` files, and made a few changes based on my environment.

> Aside: I tried the `docker-compose.rootless.yml`, because running as an unprivilaged user makes it much harder for the Bad Guys™️ to do bad things. Alas, some sub-processes of Immich assumed root to take ownership of various files / folders. Maybe I'll try switching over in future.

- `UPLOAD_LOCATION = /mnt/zfsdata/immich` - photos, thumbnails, etc will go on the zfs mirrored 1TB disks
- `TZ = Australia/Sydney` - yep, I'm in Sydney
- `DB_PASSWORD = MySuperSecretPassword!` - because you should never use default credentials

And then I spun the whole thing up with: `sudo docker compose up`

```
[+] up 70/72
 ✔ Image ghcr.io/immich-app/immich-server:v3                                                                               Pulled   178.2s
 ✔ Image ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da4... Pulled    95.0s
 ✔ Image docker.io/valkey/valkey:9@sha256:8e8d64b405ce18f41b8e5ee20aa4687a8ed0022d1298f2ce31cdcf3a76e09411                 Pulled   130.8s
 ✔ Image ghcr.io/immich-app/immich-machine-learning:v3                                                                     Pulled   160.3s
  ✔ Network immich_default            Created                                                                                          0.5s
 ✔ Container immich_redis            Started                                                                                          5.7s
 ✔ Container immich_machine_learning Started                                                                                          5.3s
 ✔ Container immich_postgres         Started                                                                                          5.8s
 ✔ Container immich_server           Started                                                                                          5.5s
```

The instructions recommend running as a daemon (background process), but I prefer to watch the debug spew up the screen for a first start. We will get to a `systemd` service once Immich is proven to run.

### Immich Post Install Steps

Now we have a running instance of Immich, we can browse to the server IP address and get a nice welcome screen!

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Welcome.png" class="" width=300 height=300 alt="Welcome to Immich" /> 

It will ask you to create the first user. I'm going to create a dedicated admin user, and a standard user for myself for  regular usage. Stops me accidentally doing dumb things that way.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Admin-User.png" class="" width=300 height=300 alt="Create the First (Admin) User" /> 

It asks you to login again.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-First-Login.png" class="" width=300 height=300 alt="First Login" /> 

It then asks you to set a few simple defaults (like timezone).

The tricky part is the _Storage Template_. While you can change it later, you can't easily rename all files already uploaded. The default is for `<Year>/<FullDate>/<Filename>` as the template. I tweaked mine to `<Year>/<Month>/<Filename>`, which is how I'm currently storing photos.

Currently, I add a prefix to every image uploaded based on phone / camera owner, but I can't see a way to replicate that in Immich. Instead, it uploads every person's images into a separate folder. I'll see if I find this a problem or not later.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Storage-Template.png" class="" width=300 height=300 alt="The Default is Probably OK. But I Tweaked it." /> 

Immich will nag you about configuring backups and downloading the mobile app (not pictured). You should 100% figure out some backups! As I am testing Immich, I'll ignore the nag screen for now.

Finally, we have a home screen!

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Main-Screen.png" class="" width=300 height=300 alt="The Home Screen of Immich!" /> 

First thing I do is [follow the instruction to create a user for myself](https://docs.immich.app/administration/user-management/).

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Create-User.png" class="" width=300 height=300 alt="Add Myself." /> 

For regular usage, I sign in as Murray instead of admin.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Murray-Login.png" class="" width=300 height=300 alt="Login as Myself." /> 

At this point, I have no photos uploaded, and that will happen via my phone. So time to [get the Immich app](https://docs.immich.app/features/mobile-app).

## Mobile App Usage

First up, you need to enter your Immich server IP address, and login.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Phone-Login.png" class="" width=300 height=300 alt="Login as Myself on my Phone." /> 

So far, there is nothing to see.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Phone-Empty.png" class="" width=300 height=300 alt="Empty Immich" /> 

You can tap on your Account to see some stats. Confirming that I really haven't used anything!

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Phone-Account.png" class="" width=300 height=300 alt="Usage Stats: Minimal on First Use!" /> 

You want to tap on the "cloud" / "sync" icon next to your account. Immich will ask what albums from your phone you want to backup.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Phone-Backup-First.png" class="" width=300 height=300 alt="Enable Backup" /> 

Go ahead and choose the Albums you want uploaded to Immich. I'll start with just my phone camera roll.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Phone-Backup-Choose.png" class="" width=300 height=300 alt="Choose Albums" /> 

Then you will see the regular backup screen, showing total photos on your device (~1000 for me), and how many are uploaded to your server (zero). 

You need to flip the big **Enable Backup** switch at the bottom!

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Phone-Backup.png" class="" width=300 height=300 alt="Set Backup to: On" /> 

You can drop back to the regular gallery screen and see the little cloud sync icons against your photos as they are sent to Immich for processing. This will take a while for your first upload as Immich is not just uploading but also doing face recognition, thumbnail creation and a bunch of other housekeeping.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Phone-Gallery.png" class="" width=300 height=300 alt="Immich Phone Gallery" /> 

If any of my instructions were unclear, [the Immich documentation shows pretty much the same thing](https://docs.immich.app/features/mobile-app).


## Web Usage

Now I have some photos uploaded from my phone, we can explore the web interface a little more.

The standard photo stream view is... well... a standard and familiar gallery style view.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Web-Photos.png" class="" width=300 height=300 alt="Immich Web Photos View" /> 

The _Explore_ view is a bit of a highlights reel, showing off some of Immich's features like face recognition and geolocation.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Web-Explore.jpg" class="" width=300 height=300 alt="Immich Web Explore View" /> 

The _Map_ view shows where you took photos based on GPS coordinates.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Web-Map.png" class="" width=300 height=300 alt="Immich Web Map View" /> 

Finally, you can do a _Search_ and the magic of machine learning means you find vaguely relevant things.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-1/Immich-Web-Search.png" class="" width=300 height=300 alt="Search for Computer, Get Computer-ish Things" /> 

So far, so good. Immich appears functional and useful.


## Auto Start

Once I confirmed Immich was running happily, I created a `systemd` service unit for Immich:

```
[Unit]
Description=Immich Docker Container
After=docker.service

[Service]
KillSignal=SIGINT
WorkingDirectory=/srv/immich
ExecStart=docker compose up
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
```

And did the systemd dance to enable it:

```sh
systemctl daemon-reload
systemctl enable immich.service
systemctl start immich.service
```

Finally, I restarted the machine a few times to confirm everything came up OK after a reboot.

## Conclusion

That is Immich installed on a brand new Debian server!

I'll evaluate it over the next month or so to see if it is a viable replacement for my current photo system (spoiler alert: from what I've seen so far, the answer is yes).

There is some additional house keeping I need before it is completely ready, including:

- A public URL using [my web server as a reverse proxy](https://docs.immich.app/administration/reverse-proxy).
- [Proper backups](https://docs.immich.app/administration/backup-and-restore).
- Importing my ~25 years of photos as an [external library](https://docs.immich.app/features/libraries).
- [Family sharing](https://docs.immich.app/features/partner-sharing) so everyone can see everyone's photos.

Part 2 will cover that, plus a bit more usage.

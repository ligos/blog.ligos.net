---
title: Immich as Self-Hosted Photo Storage - Part 2
date: 2026-09-27
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

Evaluating Immich to store personal photos.

<!-- more --> 

## Background

In my last post, [I built a server to host Immich](/2026-08-29/Immich-As-Self-Hosted-Photo-Storage-1.html).

Now its time to see if [Immich](https://immich.app/) is fit for purpose for storing photos for my family.

## Goal

Evaluate:

- Does the mobile app upload photos?
- Can I see other family member photos?
- How well does search work?
- Can I include photos from external libraries?
- How does the upgrade process work?
- How does Immich store photos?
- Sharing photos with others?
- Any other neat looking features I discover along the way!

## Completing The Install

There were a few things left over from my previous post, which need to be completed before I'm ready to use Immich seriously.

### One URL to Rule Them All

First, Immich needs to be accessible via one URL. Whether people are connecting from inside or outside my home network, connections need to work. And traffic which runs over the open internet must be encrypted via HTTPS.

This requires a reverse proxy, a little geoblocking, and some DNS records.

First up, I add both **public and internal DNS records** to point `immich.ligos.net` to my web server:

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/DNS_Record_Internal.png" class="" width=300 height=300 alt="Internal DNS Record in Mikrotik Router" /> 

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/DNS_Record_Public.png" class="" width=300 height=300 alt="Public DNS Record in Cloudflare" /> 

I am not proxying through Cloudflare because I don't need the extra security.

Now `immich.ligos.net` points to my `cadbane` webserver, via an internal IPv4 address, or external IPv4 and IPv6 addresses. 

Next step is to get my web server to run as a **reverse proxy** to point to my Immich server. Immich has a nice guide for using [Nginx as a reverse proxy](https://docs.immich.app/administration/reverse-proxy/). And I have several other web sites proxied through my public facing web server.

Merging Immich recommended and previous configs together, I got the following Nginx config:

```
server {
        root /mnt/zfsdata/www/immich.ligos.net;

        index index.html;

        server_name immich.ligos.net;

        access_log /mnt/zfsdata/www/log/immich.ligos.net.access.log;
        error_log /mnt/zfsdata/www/log/immich.ligos.net.error.log;

        # Various security headers 
        add_header Strict-Transport-Security max-age=15768000;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;

        # allow large file uploads
        client_max_body_size 50000M;

        # disable buffering uploads to prevent OOM on reverse proxy server and make uploads twice as fast (no pause)
        proxy_request_buffering off;

        # increase body buffer to avoid limiting upload speed
        client_body_buffer_size 1024k;

        # enable websockets: http://nginx.org/en/docs/http/websocket.html
        proxy_http_version 1.1;
        proxy_redirect     off;

        # set timeout
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        send_timeout       600s;

        # Proxy everything to the Immich server
        location / {
                proxy_pass                           http://192.168.1.111:2283;
                proxy_set_header   Host              $host;
                proxy_set_header   X-Real-IP         $remote_addr;
                proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Proto $scheme;
                proxy_set_header   Upgrade           $http_upgrade;
                proxy_set_header   Connection        "upgrade";
        }
}
```

Once I confirmed that was working using regular HTTP, I used [Certbot](https://certbot.eff.org/) to get a certificate and enable HTTPS. It adds a number of automated lines to the above config (which I won't show).

Finally, a little security: I **geoblock traffic outside Australia**, because that dramatically reduces the number of drive-by attacks.

This requires the Nginx Geo2IP module, and [Maxmind IP to Country database](https://www.maxmind.com/). The [Stack Harbor tutorial](https://stackharbor.com/en/knowledge-base/nginx-geoip-blocking/) is pretty good. I also used an [old StackOverflow post](https://stackoverflow.com/questions/64071451/how-to-block-a-page-for-certain-countries-geoip2-without-if), and the [Nginx reference docs](https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-by-geoip/).

The important thing to remember about geoblocking is it is very accurate at the country level, but quite poor at the city level. So great to block traffic outside of AU, but terrible to identify exactly where individual connections originate.

We need some packages:

```
$ apt install libnginx-mod-http-geoip2 libmaxminddb0
```

You need to sign up for a Maxmind account to get the geoip database up to date. Create a config with your details and the system will keep them up to date:

```
$ cat /etc/GeoIP.conf
# GeoIP.conf file for `geoipupdate` program, for versions >= 3.1.1.
# Used to update GeoIP databases from https://www.maxmind.com.
# For more information about this config file, visit the docs at
# https://dev.maxmind.com/geoip/updating-databases.

# `AccountID` is from your MaxMind account.
AccountID 999999

# `LicenseKey` is from your MaxMind account
LicenseKey REDACTED

# `EditionIDs` is from your MaxMind account.
EditionIDs GeoLite2-ASN  GeoLite2-Country
```

I then created an Nginx config file for geoblocking everywhere except local and AU addresses:

```
@cat /etc/nginx/conf.d/geoblock.conf 

# Set variable for internal and LAN addresses
# Everything is WAN except for known whitelisted address ranges
geo $lan_or_wan {
        default                         wan;
        127.0.0.0/8                     lan;
        192.168.0.0/16                  lan;
        59.167.129.207                  lan;
        ::1                             lan;
        fe80::/64                       lan;
        2001:44b8:3196:3a00::/56        lan;
}

# Geolookup IP address to country code
geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
        auto_reload 60m;
        $geoip2_country_code   country iso_code;
        $geoip2_country_name   country names en;
}

# Map the combination of LAN and CountryCode to a nice boolean
map $lan_or_wan$geoip2_country_code $is_geoblocked {
        default 1;
        lanAU   0;
        wanAU   0;
        lan     0;
}
```

Finally, we use an `if` in the Nginx config to return a `451` error: _Unavailable for Legal Reasons_. Because 403 Forbidden is too boring.

```
location / {
  # Geoblock everything outside AU
  if ($is_geoblocked = 1) {
    return 451;
  }
  ...
}
```

With all that done, I can change all Immich mobile apps to use `immich.ligos.net`. And it Just Works™️. Everywhere. (Except when we're overseas, which is rare).

### Backups

As Immich will become my primary place for uploading and storing family photos, and these are some of the most valuable digital assets in my possession, **backups are a necessity**.

Immich has a page of details about [backups, and more importantly, restoring](https://docs.immich.app/administration/backup-and-restore). They also have some [sample scripts](https://docs.immich.app/guides/template-backup-script) which use [Borg](https://www.borgbackup.org/) for backups, however these seem rather complex to me.

As I already have a [backup strategy](/2021-10-29/Long-Term-Archiving-6-Implementation.html) in place for my NAS (archiving regularly to [BluRay disks](/2022-04-02/The-Reliability-Of-Optical-Disks.html), and mirroring to [Backblaze](https://www.backblaze.com/)), all I need is an [rsync](https://rsync.samba.org/) script on a regular schedule in `/etc/crontab`:

```
$ rsync -av /mnt/zfsdata/immich/ immich_user@countdooku.ligos.local:/mnt/pool_4T/Backup/Immich
```

In the end, you need to put your own backup strategy in place. Go read about the [3-2-1 backup strategy](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/), and then implement it as you see fit for your context.

## Evaluation

OK, everything is set and ready to go from a technical point of view.

Let's see if Immich is any good!

### Mobile Uploads

The first and most important thing Immich needs to do is suck photos off our phones and upload them to the Immich server.

After adding the Immich app to everyone's phone, it did what it was supposed to do: upload photos! 

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_App_Backups.png" class="" width=300 height=300 alt="All my Photos are Backed Up!" /> 

✅ Photos upload from app to server.

However, it uploads every now and then, rather than right away. That is, your photos _will_ get uploaded, but it might take anywhere from a few minutes to a day before it happens. I'm OK with eventual consistency.

The approach the Immich app uses for uploads is to schedule app notifications for itself, and that triggers the logic to upload photos. It seems to work best if you use Immich as your photo gallery app - or at least semi-regularly open the Immich app. I suspect it isn't a completely zero maintenance thing; I will need to check in on each phone every 3-6 months to be sure.

To be fair, [Syncthing](https://syncthing.net/) often gets itself into a similar situation on family phones. Even though it is registered as a background service, Android will unload it, or stop loading it. Every now and then I need to double check phones are still syncing.

### Mobile App

The mobile app functions as you would expect. 

There is the standard list of photos you would expect in any gallery app. Performance has remained consistent as I have added more and more photos to Immich.

There are tabs to Search, view by Person, Location, Albums, etc.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_App_Photo_Timeline.png" class="" width=300 height=300 alt="The Photo Timeline in Immich Android App" /> 

Most things you can do in the web app are replicated on the phone.

However, the phone app is reliant on the Immich server. Browsing photos you have taken on your phone is fine. But most other features need internet connectivity. Particularly more powerful features like _Search_ or viewing other family member photos.

I don't think this is unreasonable, just remember that Immich is self-hosted, not a magic app. Just like other cloud based photo apps phone home for heavy lifting, Immich does as well. Only, you can point to the computer that is doing the lifting, unlike some nebulous "cloud server" in a random data center.

### Family Sharing

I want all family photos to be visible to all family members. That's how it works with [Lazygal](https://github.com/niol/lazygal) and my bunch-of-photos-in-folders right now.

The Immich [Partner Sharing](https://docs.immich.app/features/partner-sharing) feature largely achieves this. You need to invite and accept for all users, but once you've done that, everyone's photos are visible to everyone else. And there's a checkbox to view photos in the main photos timeline.

✅ Photos for whole family visible.

However, there is more to family sharing than just seeing photos. I want other Immich features to work across the whole library as well.

Initially, this seemed quite limited, with important features like Search and Face Recognition not crossing user boundaries. But I found in [version 3.2 of Immich](https://github.com/immich-app/immich/releases/tag/v3.2.0), there is a thing called "cluster groups" which lets you search across users (note: you need to opt-into this in addition to regular partner sharing).

This means search and people now work across the whole family. I can search for "dog" and get hits for photos from any user:

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Search_Dog_Across_Users.png" class="" width=300 height=300 alt="Those Videos are from my Wife's Phone" /> 

And search for myself under People and get hits from other users:

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_People_Across_Users.png" class="" width=300 height=300 alt="Those are Photos of me from my Wife's Phone" /> 

However, not everything has been hooked up across users. The Map view only shows your own photos:

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Map_for_Murray.png" class="" width=300 height=300 alt="Map View for Murray" /> 

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Map_for_Admin.png" class="" width=300 height=300 alt="Map View for Admin user (external libraries)" /> 

And, when you view someone else's photo, there is no indication who owns it on the web app (although the phone app _does_ have a _Shared By_ tag):

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Who_Owns_This_Photo.png" class="" width=300 height=300 alt="Me Doing a Jigsaw Puzzle - But Who Took The Photo?? (Spoiler: My Wife Did)" /> 

To quote from the v3.2 release notes (my emphasis): 

> We are very happy to ship the **first step** towards better sharing. 

I'm happy Immich development seems to be heading where I would like to land 🙂
It also looks like [sharing between users has been a long standing issue](https://github.com/immich-app/immich/issues/12614) - I think I've just arrived when their efforts are bearing fruit!

Improved sharing is important because of how External Libraries work (see below).

### Searching

✅ Immich lets you search photos. 

In the usual ways:

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Search_By_Date.png" class="" width=300 height=300 alt="Search By Date" /> 

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Search_By_Person.png" class="" width=300 height=300 alt="Search By Person" /> 

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Search_By_Location.png" class="" width=300 height=300 alt="Search By Location" /> 

One of the more interesting search features is a contextual or semantic search:

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Search_By_Context.png" class="" width=300 height=300 alt="Search For People in Red Shirts" /> 

This is clearly not as powerful as frontier machine learning models, as there is a red car in the results. But it's still the best semantic search feature I've been able to self-host.


### External Libraries

Immich lets you include photos from [External Libraries](https://docs.immich.app/features/libraries/). That is, photos which originate somewhere outside of Immich itself. This is rather important to me as I have ~25 years of photos in this category - and I'd really like Immich to handle them well.

These photos are located on my TrueNAS box, so I mount the network resource using [SSHFS](https://www.digitalocean.com/community/tutorials/how-to-use-sshfs-to-mount-remote-file-systems-over-ssh):

```
$ cat mnt-countdooku_pictures.mount 
[Unit]
Description=sshfs mount /mnt/countdooku_pictures
After=network-online.target
Requires=network-online.target

[Mount]
What=immich_user@countdooku.ligos.local:/mnt/pool-4T/Pictures
Where=/mnt/countdooku_pictures
Type=fuse.sshfs
Options=allow_other,reconnect,IdentityFile=/etc/ssh/keys/immich_user@countdooku.ligos.net,compression=no

# Make 'systemctl enable tmp.mount' work:
[Install]
WantedBy=multi-user.target
```

Then I add the mounted folder (read only) to the docker container in `compose.yaml`:

```yaml
name: immich

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    volumes:
      # Do not edit the next line. If you want to change the media storage location on your system, edit the value of UPLOAD_LOCATION in the .env file
      - ${UPLOAD_LOCATION}:/data
      - /etc/localtime:/etc/localtime:ro 
      # Add photos from CountDooku NAS
      - /mnt/countdooku_pictures:/mnt/media/CountDooku:ro
```

From there, I need to create the External Library as the admin user. I must assign a user to own these photos in Immich - I've chosen the admin user, as they are photos from everyone down the years.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_External_Library.png" class="" width=300 height=300 alt="External Library from NAS" /> 

Once created, you add folders based on the docker container path:

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_External_Library_Details.png" class="" width=300 height=300 alt="External Library Listing Each Year of Photos" /> 

Immich will search and index External Libraries overnight.

I have chosen to add each year at a time, because that gives me options in future when archiving out of Immich (ie: I could copy 2028 photos across to my NAS, delete them from the Immich server, and include them as part of the External Library). It also avoids overloading Immich creating thumbnails and transcoding videos for GBs of data - check [Administration > Job Queues](https://docs.immich.app/administration/jobs-workers) that all the queues are empty before adding another batch of photos.

Finally, because the partner sharing has enabled most search options across users, all the historical photos are indexed and searchable.

✅ I can include photos from external libraries.

### 3rd Party Sharing

The default is to share everything within my family. But sometimes I need to share with other people.

All the cloud photo services let you create an album and share it via a link and / or password. So what about Immich?

Yes. Yes it can do [Public Sharing](https://docs.immich.app/features/sharing). Both from an album, or by just selecting a bunch of photos and clicking the Share icon.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Share_Link.png" class="" width=300 height=300 alt="Share a Link with Anyone" /> 

The expiry date is a nice touch.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Shared_Folder.png" class="" width=300 height=300 alt="This is What Other People See" /> 

Note all shared items are under the `/s` folder of your Immich server. Recommendation to future Murray (and anyone taking my advice): add a uuid to the link to make it more difficult for drive-by downloads. Or, leave the URL blank and Immich is supposed to generate something random for you.

✅ Immich can share magic links of photos to anyone.

### Duplicates

As I have been trailing Immich in parallel with my regular photo upload system, I have photos for 2026 which are duplicated between both my NAS and Immich. I decided to add August as an External Library to see how Immich will handle duplicates.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_Duplicate_Images.png" class="" width=300 height=300 alt="Those Photos are Byte for Byte Identical" /> 

Immich has a [Duplicate Detection Utility](https://docs.immich.app/features/duplicates-utility), however because the photos are from different users, it doesn't pick them up. Instead, this feature is to find very similar photos you have uploaded - which it does seem to do.

Alas, I can't see a way to solve this problem within Immich itself. I suspect the easiest approach would be to not add 2026 as an external library folder, and manually upload any files from before my trial started into Immich.

❌ De-duplicate between Immich uploaded photos and External Libraries.

### An Upgrade

When I initially installed Immich, it was on version 3.0. By the time I had completed my trials and started to write this post, it was up to [version 3.2](https://github.com/immich-app/immich/releases/tag/v3.2.0). 

That's good because I got to experience the [upgrade process](https://docs.immich.app/install/upgrading/), which was rather painless:

- Stop Immich: `systemctl stop immich.service`
- Go to Immich folder: `cd /srv/immich`
- Pull new Docker assets: `docker compose pull`
- Start Immich: `systemctl start immich.service`

I guess this is another nice feature of Docker.

✅ Upgrade process is painless.

### Photo Storage (technical)

I'm interested in how Immich stores photos on disk, because I want to copy photos across to my NAS for long term archival. And this will be done via a script of some kind.

<img src="/images/Immich-As-Self-Hosted-Photo-Storage-2/Immich_File_Structure.png" class="" width=300 height=300 alt="Photos are Stored by User UUID, then Year and Month" /> 

The year and month scheme was what I configured during installation as the [Storage Template](https://docs.immich.app/administration/storage-template). Each user is referred to by a uuid, and photos are isolated by user.

That's not entirely convenient, but I can work with it.

✅ I can see a way to archive from Immich to long term bunch-of-photos-in-folders.

## Cut Over Plan

Immich looks like it meets my needs, but unless I can migrate 25 years of photos, it might not be viable at all.

How do I go from where I am now to using Immich as my primary photo storage? Here's my rough plan:

- Add previous years of photos as External Libraries.
- Decommission Lazygal.
- Manually upload any photos from 2026 not in Immich (as they won't be in External Libraries).
- Delete any photos from 2025 and earlier from Immich (they will appear in External Libraries only).
- Script to copy original photos from Immich to NAS photo library as backup / archive.
- Before 1st Jan 2027, turn off the old syncthing based approach.


## Conclusion

Overall, Immich looks like it will meet my needs 🎉

Which means my family can have a better experience looking at our photos from the beginning of time on their phones.
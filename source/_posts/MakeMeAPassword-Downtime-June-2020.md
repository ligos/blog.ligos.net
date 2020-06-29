---
title: MakeMeAPassword Downtime - June 2020
date: 2020-06-29
tags:
- Linux
- Debian
- Webserver
- Downtime
- Failure
- Monitoring
- IO
categories: Technical
---

Downtime Sucks.

<!-- more --> 

## Background

[MakeMeAPassword.ligos.net](https://makemeapassword.ligos.net/) is hosted on a laptop.
This is deliberate - the site barely requires any CPU and a laptop has a built in UPS.

However, the other day, it went down.
And I wasn't notified.

So, after around ~14 hours of down time, some polite users contacted me via email.
These arrived an hour after I went to sleep, so I didn't notice for another 8 hours.
For a grand total of 22 hours when no passwords could be generated from MakeMeAPassword. 

Overall, this made me rather sad.


### New Server / Laptop

A few weeks before this downtime, I'd transferred all my web hosting to a new server... err... laptop... err... server laptop.
This was to get a clean [Debian 10 install](/2020-06-27/Debian-10.4-Buster.html).

As part of this migration, I installed two SATA disks in a mirrored zfs pool to hold all the critical data for the webserver (which is basically all the content I host, plus log files).
Unfortunately, those two disks used both available SATA ports (and I had to remove the DVD drive to make room for the second).
I used a [USB flash drive](https://en.wikipedia.org/wiki/USB_flash_drive) as the root disk.

Turns out the flash drive I chose was rather cheap.
I ran the new laptop for a few months, and 2 days before I was ready to put it into production, the USB failed and went read-only.

I migrated the root partition to a HDD and booted the laptop from an old [USB HDD enclosure](https://en.wikipedia.org/wiki/Disk_enclosure).
This worked well enough, and the new laptop was put into service.

<img src="/images/MakeMeAPassword-Downtime-June-2020/obiwan-laptop-server.jpg" class="" width=300 height=300 alt="Obiwan: My New Server Laptop" />


## Fix the Immediate Problem

When I woke up and noticed the emails saying MakeMeAPassword was down, I visited the website on my mobile phone (which worked) and tried to generate a password (which timed out).

So I SSH-ed to the server to investigate further.
No problem connecting.
Started `htop` and didn't notice any obvious issues.
Even tried `atop` (because it includes IO stats), at nothing jumped out at me.

I tried to become root via `sudo -i`, so I could inspect log files.
And `sudo` simply didn't run.
(Because it's trying to write to `/var/log/auth.log`, and the disk isn't working).

This meant I a) couldn't inspect log files, and b) couldn't reboot using `shutdown`.

At this point I had several terminal windows open waiting for `sudo` to complete.
And `atop` was telling me `/dev/sdc` IO was taking 10+ seconds.

I walked over to the laptop and checked the console.
Took a photo in case I needed the exact error message later on.

<img src="/images/MakeMeAPassword-Downtime-June-2020/obiwan-console-io-errors.jpg" class="" width=300 height=300 alt="Right. IO errors are going to cause problems." />

And hit the power button.

Several tense seconds later, the machine started its boot sequence.
And ~30 seconds after the reboot, it was back up and asking for a login.

I checked MakeMeAPassword was working (both the static content and API).
Replied to the emails people had sent, and [posted an issue on GitHub](https://github.com/ligos/MakeMeAPassword/issues/1).

Then I went to work.
(Well, its COVID19, so "work" and "troubleshooting MakeMeAPassword" are conducted from the same physical location).


## Dissect Logs to Figure Out What Happened

During my lunch break, I dug into the log files to see if I could gather any more details about what happened, when it happened, and exactly how long the down time was for.
(Note that all dates and times are AEST UTC+10).

### syslog

The first place I looked was `/var/log/syslog`, there was a disturbing gap at 9:04:

```
Jun 23 09:00:01 obiwan CRON[11070]: (root) CMD (   PATH="$PATH:/usr/local/bin/" pihole updatechecker local)
Jun 23 09:03:56 obiwan systemd[1]: Stopping Network Time Synchronization...
Jun 23 09:03:56 obiwan systemd[1]: systemd-timesyncd.service: Succeeded.
Jun 23 09:03:56 obiwan systemd[1]: Stopped Network Time Synchronization.
Jun 23 09:03:56 obiwan systemd[1]: Starting Network Time Synchronization...
Jun 23 09:03:56 obiwan systemd[1]: Started Network Time Synchronization.
Jun 23 09:04:02 obiwan systemd-timesyncd[11733]: Synchronized to time server for the first time 72.30.35.89:123 (0.debian.pool.ntp.org).
Jun 24 07:12:12 obiwan kernel: [    0.000000] Linux version 4.19.0-9-amd64 (debian-kernel@lists.debian.org) (gcc version 8.3.0 (Debian 8.3.0-6)) #1 SMP Debian 4.19.118-2+deb10u1 (2020-06-07)
Jun 24 07:12:12 obiwan kernel: [    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-4.19.0-9-amd64 root=UUID=71c98b73-cd73-492a-8874-8723756a919d ro quiet consoleblank=600
Jun 24 07:12:12 obiwan kernel: [    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
Jun 24 07:12:12 obiwan kernel: [    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'
Jun 24 07:12:12 obiwan kernel: [    0.000000] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'
```

That's around 22 hours of dead silence.
Which is very unusual.

Unfortunately, there's no indication of what actually went wrong.
Some time after 9:04, the disk couldn't be written to.

### daemon.log

I took a look at `/var/log/daemon.log` as well (where [systemd](https://en.wikipedia.org/wiki/Systemd) logs to), and there was a similar "gap", and no indication why:

```
Jun 23 09:03:56 obiwan systemd[1]: Stopping Network Time Synchronization...
Jun 23 09:03:56 obiwan systemd[1]: systemd-timesyncd.service: Succeeded.
Jun 23 09:03:56 obiwan systemd[1]: Stopped Network Time Synchronization.
Jun 23 09:03:56 obiwan systemd[1]: Starting Network Time Synchronization...
Jun 23 09:03:56 obiwan systemd[1]: Started Network Time Synchronization.
Jun 24 07:12:12 obiwan systemd[1]: Starting Flush Journal to Persistent Storage...
Jun 24 07:12:12 obiwan systemd[1]: Started Helper to synchronize boot up for ifupdown.
Jun 24 07:12:12 obiwan systemd[1]: Started Flush Journal to Persistent Storage.
Jun 24 07:12:12 obiwan systemd[1]: Started Set the console keyboard layout.
Jun 24 07:12:12 obiwan systemd[1]: Started Create System Users.
Jun 24 07:12:12 obiwan systemd[1]: Starting Create Static Device Nodes in /dev...
```

### Nginx site access logs

I've configured all the nginx sites to log to the zfs mount point, rather than the default of `/var/log`.
This originally was because I didn't want to be writing to a USB memory stick too much, but has the nice side affect that logs kept being written there.
Here's part of the HTTP access log for MakeMeAPassword around 9:04 (IP addresses have been changed):

```
2001:1234:1:10::1 - - [23/Jun/2020:08:48:00 +1000] "GET /api/v1/readablepassphrase/json?s=RandomForever&pc=1&sp=n&whenNum=EndOfWord&nums=2&whenUp=StartOfWord&ups=999&maxCh=63 HTTP/1.1" 200 111 "https://makemeapassword.ligos.net/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36"
2001:1234:1:10::1 - - [23/Jun/2020:08:50:17 +1000] "GET /api/v1/alphanumeric/json?l=8&c=1&sym=n HTTP/1.1" 200 64 "https://makemeapassword.ligos.net/generate/alphanumeric" "Mozilla/5.0 (Linux; Android 8.1.0; vivo 1801) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Mobile Safari/537.36"
1.2.3.4 - - [23/Jun/2020:09:00:41 +1000] "HEAD / HTTP/1.1" 200 0 "https://makemeapassword.ligos.net" "Mozilla/5.0+(compatible; UptimeRobot/2.0; http://www.uptimerobot.com/)"
1.2.3.4 - - [23/Jun/2020:09:00:48 +1000] "GET /api/v1/passphrase/plain?pc=1&wc=3&minCh=20&ups=3&whenUp=StartOfWord&sp=y&nums=1&whenNum=EndOfPhrase HTTP/1.1" 200 27 "-" "curl/7.50.3"
1.2.3.4 - - [23/Jun/2020:09:05:37 +1000] "GET /api/v1/passphrase/plain?pc=1&wc=3&minCh=20&ups=3&whenUp=StartOfWord&sp=y&nums=1&whenNum=EndOfPhrase HTTP/1.1" 200 25 "-" "curl/7.50.3"
1.2.3.4 - - [23/Jun/2020:09:07:55 +1000] "GET /api/v1/readablepassphrase/json?s=RandomShort&pc=1&sp=y HTTP/1.1" 504 585 "https://makemeapassword.ligos.net/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36"
2001:1234:1:10::1 - - [23/Jun/2020:09:08:02 +1000] "GET /api/v1/passphrase/json?wc=7&pc=1&sp=n&whenUp=StartOfWord&ups=999&maxCh=63 HTTP/1.1" 499 0 "https://makemeapassword.ligos.net/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:77.0) Gecko/20100101 Firefox/77.0"
2001:1234:1:10::1 - - [23/Jun/2020:09:08:02 +1000] "GET / HTTP/1.1" 200 4672 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:77.0) Gecko/20100101 Firefox/77.0"
2001:1234:1:10::1 - - [23/Jun/2020:09:08:41 +1000] "GET /api/v1/passphrase/json?wc=7&pc=1&sp=n&whenUp=StartOfWord&ups=999&maxCh=63 HTTP/1.1" 499 0 "https://makemeapassword.ligos.net/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:77.0) Gecko/20100101 Firefox/77.0"
2001:1234:1:10::1 - - [23/Jun/2020:09:10:00 +1000] "GET /api/v1/alphanumeric/combinations?l=8&c=1&sym=n HTTP/1.1" 200 126 "https://makemeapassword.ligos.net/generate/alphanumeric" "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1"
2001:1234:1:10::1 - - [23/Jun/2020:09:10:01 +1000] "GET /favicon.ico HTTP/1.1" 200 3792 "https://makemeapassword.ligos.net/generate/alphanumeric" "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1"
2001:1234:1:10::1 - - [23/Jun/2020:09:10:02 +1000] "GET /favicon.png HTTP/1.1" 200 2164 "https://makemeapassword.ligos.net/generate/alphanumeric" "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1"
2001:1234:1:10::1 - - [23/Jun/2020:09:10:04 +1000] "GET /api/v1/alphanumeric/json?l=8&c=1&sym=n HTTP/1.1" 499 0 "https://makemeapassword.ligos.net/generate/alphanumeric" "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1"
1.2.3.4 - - [23/Jun/2020:09:12:17 +1000] "GET /keepass_plugins.version.txt HTTP/1.1" 200 37 "-" "-"
1.2.3.4 - - [23/Jun/2020:09:15:42 +1000] "HEAD / HTTP/1.1" 200 0 "https://makemeapassword.ligos.net" "Mozilla/5.0+(compatible; UptimeRobot/2.0; http://www.uptimerobot.com/)"
1.2.3.4 - - [23/Jun/2020:09:16:19 +1000] "GET /generate/alphanumeric HTTP/1.1" 200 3800 "-" "Mozilla/5.0 (Linux; U; Android 10; en-US; SM-A305F Build/QP1A.190711.020) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/13.2.0.1296 Mobile Safari/537.36"
1.2.3.4 - - [23/Jun/2020:09:16:20 +1000] "GET /api/v1/alphanumeric/combinations?l=8&c=1&sym=n HTTP/1.1" 200 126 "https://makemeapassword.ligos.net/generate/alphanumeric" "Mozilla/5.0 (Linux; U; Android 10; en-US; SM-A305F Build/QP1A.190711.020) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/13.2.0.1296 Mobile Safari/537.36"
```

(You'll need to scoll to the right to see more details).
The request at *23/Jun/2020:09:07:55 +1000* is the first indication anything is wrong: it has a 504 "gateway timeout" error.
And that's followed by some requests with [error 499, which is Nginx specific](https://stackoverflow.com/questions/12973304/possible-reason-for-nginx-499-error-codes).

However, requests to `/keepass_plugins.version.txt` continue to succeed (because that file is hosted on the zfs pool).
As are requests to non-API end points like `/generate/alphanumeric`.
And even requests to some API end points like `/api/v1/alphanumeric/combinations`.

But anything which tries to generate a password is failing.

### Nginx site error logs

The site error logs show lots of errors like this:

```
2020/06/23 09:07:55 [error] 1270#1270: *21693 upstream timed out (110: Connection timed out) while reading response header from upstream, client: 1.2.3.4, server: makemeapassword.ligos.net, request: "GET /api/v1/readablepassphrase/json?s=RandomShort&pc=1&sp=y HTTP/1.1", upstream: "http://[::1]:5001/api/v1/readablepassphrase/json?s=RandomShort&pc=1&sp=y", host: "makemeapassword.ligos.net", referrer: "https://makemeapassword.ligos.net/"
2020/06/23 09:18:16 [error] 1270#1270: *21758 upstream timed out (110: Connection timed out) while reading response header from upstream, client: 1.2.3.4, server: makemeapassword.ligos.net, request: "GET /api/v1/alphanumeric/json?l=12345678&c=87654321&sym=y HTTP/1.1", upstream: "http://[::1]:5001/api/v1/alphanumeric/json?l=12345678&c=87654321&sym=y", host: "makemeapassword.ligos.net", referrer: "https://makemeapassword.ligos.net/generate/alphanumeric"
```

And later on:

```
2020/06/23 18:10:28 [crit] 1270#1270: *26812 mkdir() "/var/lib/nginx/proxy/7/18" failed (30: Read-only file system) while reading upstream, client: 1.2.3.4, server: makemeapassword.ligos.net, request: "GET /api/v1/readablepassphrase/dictionary HTTP/1.1", upstream: "http://[::1]:5001/api/v1/readablepassphrase/dictionary", host: "makemeapassword.ligos.net", referrer: "https://makemeapassword.ligos.net/faq"
2020/06/23 18:10:35 [crit] 1270#1270: *26816 mkdir() "/var/lib/nginx/proxy/8/18" failed (30: Read-only file system) while reading upstream, client: 1.2.3.4, server: makemeapassword.ligos.net, request: "GET /api/v1/readablepassphrase/dictionary HTTP/1.1", upstream: "http://[::1]:5001/api/v1/readablepassphrase/dictionary", host: "makemeapassword.ligos.net", referrer: "https://makemeapassword.ligos.net/faq"
```

Seems that Nginx creates files (I'm guessing pipes for cross process communication, or perhaps temporary files to buffer the response) when it does its reverse proxy thing.
And here's confirmation that my root filesystem has gone read-only.

### Terninger Logs

My random number generator, [Terninger](https://github.com/ligos/terninger), logs pretty frequently when it re-seeds itself based on external entropy.
It goes silent from 9:01.

```
2020-06-23 08:33:32.5018|INFO|MurrayGrant.Terninger.Random.PooledEntropyCprngGenerator||5-|Re-seeded Generator using 128 bytes of entropy from 2 accumulator pool(s).
2020-06-23 08:49:36.6841|INFO|MurrayGrant.Terninger.Random.PooledEntropyCprngGenerator||5-|Re-seeded Generator using 448 bytes of entropy from 7 accumulator pool(s).
2020-06-23 09:01:37.8781|INFO|MurrayGrant.Terninger.Random.PooledEntropyCprngGenerator||5-|Re-seeded Generator using 384 bytes of entropy from 6 accumulator pool(s).
```

After reboot, it springs back into life.
But adds nothing to what we know.

```
2020-06-24 07:12:31.7333|INFO|MurrayGrant.Terninger.Random.PooledEntropyCprngGenerator||1-|Starting Terninger pooling loop for generator 08db99c3-fdf2-413d-a621-94db1d38288f.
2020-06-24 07:13:11.4071|INFO|MurrayGrant.Terninger.Random.PooledEntropyCprngGenerator||4-|Re-seeded Generator using 128 bytes of entropy from 2 accumulator pool(s).
```

### MakeMeAPassword statistics

Finally, I record statistics about each password generated.
Nothing identifiable, but enough so I have a very basic idea of what types of passwords people are requesting, how much randomness I need to serve those requests, and how long it takes to generate them.

```
2020-06-23	08:48:05.876	+10:00	ReadablePassphrase	1	81	0.1773	81	0.1773	InterNetworkV6	
2020-06-23	08:50:17.061	+10:00	AlphaNumeric	1	32	0.0551	32	0.0551	InterNetworkV6	
2020-06-23	09:00:48.305	+10:00	Passphrase	1	32	0.0753	32	0.0753	InterNetwork	
2020-06-23	09:00:52.640	+10:00	Passphrase	1	32	0.1055	32	0.1055	InterNetwork	
2020-06-23	09:00:57.021	+10:00	Passphrase	1	32	0.0772	32	0.0772	InterNetwork	
2020-06-23	09:05:37.379	+10:00	Passphrase	1	32	0.0831	32	0.0831	InterNetwork	
2020-06-24	07:13:11.622	+10:00	ReadablePassphrase	10	808	62.1438	80.8	6.21438	InterNetworkV6	
2020-06-24	07:13:35.797	+10:00	Passphrase	1	16	0.3671	16	0.3671	InterNetworkV6	
2020-06-24	07:19:55.862	+10:00	AlphaNumeric	1	32	0.1244	32	0.1244	InterNetwork	
2020-06-24	07:22:42.364	+10:00	AlphaNumeric	1	32	0.2262	32	0.2262	InterNetwork	
2020-06-24	07:24:06.103	+10:00	AlphaNumeric	1	32	0.2337	32	0.2337	InterNetwork	
2020-06-24	07:25:25.327	+10:00	Passphrase	1	16	0.2048	16	0.2048	InterNetworkV6	
```

Once again, there's a conspicuous gap from 9:05 onwards.

### What I Think Went Wrong

The evidence points to some kind of hardware failure between 9:05 and 9:08 local time.
This eventually caused the root filesystem to become read-only.
Which in turn caused some things to stop, but others to continue without problem.

Because the reboot worked, my best guess is there was a USB error which caused the USB HDD enclosure to stop working.


## Add Monitoring So I Know When It Breaks Next Time

One very bad thing was I didn't find out about the problem until 22 hours after it started.

I use [Uptime Robot](https://uptimerobot.com/) to alert me if any of my websites or computers go down.
It works by sending an HTTP HEAD or GET request to the website and expecting an HTTP 200 response.

The problem was the request was directed to https://makemeapassword.ligos.net not https://makemeapassword.ligos.net/api/v1/passphrase/json.
The only part of the site which had failed was the part which generated passwords.
Every other endpoint was still responding normally.

I even have SSH based monitoring for the server, and it was still working!

So I've told Uptime Robot to also monitor one of my API endpoints, so I find out if it breaks again.


## How to Stop IO Errors Before They Happen

IO errors usually mean a HDD is about to fail.
They're a special kind of bad.
The sort that makes sys-admins break out in a cold sweat.

A reboot is a good start, but I did a full check of the disk using [badblocks](https://wiki.archlinux.org/index.php/Badblocks).
This was only the read-only test, but it gives me some confidence the HDD itself isn't about to die.

```
$ sudo badblocks -v /dev/sdc
Checking blocks 0 to 312571223
Checking for bad blocks (read-only test): done
Pass completed, 0 bad blocks found. (0/0/0 errors)
```

That leaves the USB subsystem of the laptop, or the USB HDD enclosure as the most likely offenders.

In the week since the downtime happened, the server hasn't had any further issues.

### What About mSATA?

If I was using a desktop, there would usually be 4 or 6 SATA ports and I wouldn't be bothering with USB anything.
But the laptop only has 2 SATA ports, both in use by my mirrored zpool.
There isn't a physical SATA port to connect the root disk to.

There is an internal expansion slot for an mSATA device, however.
[Page 82 of the Linkpad T530 Hardware Maintenance Manual](http://photonicsguy.ca/_media/projects/t530/t530_hardware_maintenance_manual.pdf) confirms I could install a 60mm mSATA solid state drive.
Which would perform much better than a USB2 connected HDD, and is likely to be more reliable.

I [shopped around](https://www.mwave.com.au) my usual [Australian online](https://www.pccasegear.com/) computer [parts stores](https://www.techbuy.com.au/).
Only to find that mSATA barely rates a mention.
Seems that [M.2 form factor SSDs](https://en.wikipedia.org/wiki/M.2) are all the rage and no one cares for old slow mSATA in 2020.
There are [EBay stores that sell mSATA devices](https://www.ebay.com.au/b/mSATA-Solid-State-Drives/175669/bn_25872940), however even that page has plenty of M.2 devices.
Looks like for AUD $40-$80, I can get a 64GB mSATA device.

I'll keep it in mind if I get repeated failures.

## Conclusion

Downtime makes me sad.
And this downtime was particularly bad.

My apologies to all users of MakeMeAPassword.

The additional monitoring should prevent extended downtime.
And I'll be keeping a close eye on the server to ensure it's very reliable.

If worst comes to worst, I'll be spending money on an mSATA drive.

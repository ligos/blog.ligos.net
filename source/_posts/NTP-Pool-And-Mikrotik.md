---
title: NTP Pool and Mikrotik
date: 2018-01-29
updated: 2018-06-16
tags:
- Mikrotik
- Router
- NTP
- Pool
- Script
- Scheduler
categories: Technical
---

Update pool.ntp.org address on a Mikrotik Router.

<!-- more --> 

## Background

Time is very important for computers to do the right thing.

If your clock is wrong by a minute authenticator apps won't work.
Wrong by an hour and Windows Networking has problems.
Wrong by days and you risk SSL certificates expiring earlier (or later) than they should.
VPNs may stop working.
Datestamps on logs will be misleading.
Generally, wrong time is a Bad Thing™.

A particular Mikrotik router, which I administer, has a scheduled task to turn the guest WiFi off overnight and back on again in the morning.
I was told it wasn't working the other day, and found that the router's clock was wrong by about 10 hours after a power outage.

Correct time is very important.


## Goal

Configure a Mikrotik router to use the [pool.ntp.org public NTP server pool](http://www.pool.ntp.org/en/) in its [NTP client](https://wiki.mikrotik.com/wiki/Manual:System/Time).
So the clock will be set accurately.


## Update June 2018 - An Even Easier Alternative

Apparently, DNS based lookups are already available in Mikrotik routers.
But only in the **SNTP Client** not the **NTP Client** (note the **S** at the start).
And if you have manually installed the separate `ntp` package, the **SNTP Client** is hidden.

[SNTP Client Reference](https://wiki.mikrotik.com/wiki/Manual:System/Time#SNTP_client)

**System** -> **SNTP Client**

If you can't find it, check in **System** -> **Packages** for the `ntp` package, and remove it (unless you want your router to be an NTP server - you probably don't).
You'll need to reboot your router for this to take effect.

In the **SNTP Client**, set your primary and secondary NTP servers to `0.0.0.0`, and *Server DNS Names* to your desired NTP server (eg: `pool.ntp.org`).
And you're done!
It may take a 10-60 seconds while it updates your clock.

<img src="/images/NTP-Pool-And-Mikrotik/mikrotik-sntp-client.png" class="" width=300 height=300 alt="SNTP Client " />



## An Easier Alternative

**IP** -> **Cloud** -> **Update Time**

<img src="/images/NTP-Pool-And-Mikrotik/mikrotik-cloud.png" class="" width=300 height=300 alt="The Cloud! (aka DDNS and Update Time)" />

Mikrotik's [dynamic DNS](https://en.wikipedia.org/wiki/Dynamic_DNS) / [cloud](https://wiki.mikrotik.com/wiki/Manual:IP/Cloud) service allows you to update the time on your router.
This is much easier to configure than NTP and scripted tasks.

However, I've found it doesn't always work (for reasons I never understood).
And, you may be one of those people who don't want to use "cloud" things that aren't in their control.
If that's the case, read on.


## Try the Simple Thing First

I first tried to copy and paste `pool.ntp.org` into the **System** -> **NTP Client** settings.
Winbox helpfully resolved the DNS name into an IP address.

<img src="/images/NTP-Pool-And-Mikrotik/ntp-client-dns-name.png" class="" width=300 height=300 alt="Maybe a DNS name will work..." />

<img src="/images/NTP-Pool-And-Mikrotik/ntp-client-ip-addresses.png" class="" width=300 height=300 alt="Apparently not." />

Unfortunately, the whole idea of `pool.ntp.org` is there are heaps of servers sitting behind that name.
When you lookup `pool.ntp.org`, it returns different addresses each time.
That distributes the NTP load around many servers.
And servers may come and go over time (or IP addresses change).
(My DNS provider even has a special `POOL` [DNS record](https://support.dnsimple.com/articles/pool-record/) which does exactly this).

Resolving the name once and saving the IP address doesn't really fit the intent of `pool.ntp.org`.
Being a pragmatist, when I configured this router, I just ran with the *set it once and hope it keeps working* idea.

Last weekend was when it stopped working.


## A Scheduled Script to Update NTP Client

If a simple copy-paste wasn't going to work, a script which updates the IP addresses on a regular basis will.

Step-by-step guide time!


### 0. Install the NTP package

NTP isn't installed on Mikrotik routers by default.
Head over to the [download page](https://mikrotik.com/download) and grab the *extra packages* for your RouterOS build.
Upload the NTP package to your router and reboot to install.

### 1. Enable the NTP Client

**System** -> **NTP Client**

Tick the **Enabled** box, make the *Mode* `unicast` and stick some names or IP addresses into the server IP address slots.
If all is working correctly, the status bar should say *updating* and eventually *synchronized*.
And your router's clock should be correct.

<img src="/images/NTP-Pool-And-Mikrotik/ntp-client-ip-addresses.png" class="" width=300 height=300 alt="NTP Client Config." />

I advertise the NTP server on my router via DHCP (although I'm not sure many devices actually use it).
If you want to run an NTP server for your network make sure you allow *UDP* packets on *port 123* on your router.
If you only want your router's clock set right and don't care for internal devices using NTP, disable the NTP Server.


### 2. Create a Script to Configure NTP Client

**System** -> **Scripts**

A script will nicely resolve DNS names and then set the IP addresses in the NTP Client config.
Using C# and SQL in my day job, the [Mikrotik scripting language](https://wiki.mikrotik.com/wiki/Manual:Scripting) feels very basic (heck, even VBA feels nicer), but its more than what we need.
And there are a [variety of examples](https://wiki.mikrotik.com/wiki/Scripts) available to help you out.

Create a new script with the content below:

```
{
:local ntpServer "pool.ntp.org"
:local primary [resolve $ntpServer]
:local secondary [resolve $ntpServer]

/system ntp client set primary-ntp $primary
/system ntp client set secondary-ntp $secondary
}
```

The script defines the NTP server we will use (because I'm in Australia, I'm using `au.pool.ntp.org`, see [how to use pool.ntp.org](http://www.pool.ntp.org/en/use.html) for more info).
It then resolves the server name twice, which sets `$primary` and `$secondary` to ip addresses.
And finally sets the NTP Client primary and secondary addresses.

<img src="/images/NTP-Pool-And-Mikrotik/ntp-reload-script.png" class="" width=300 height=300 alt="NTP Reload Script." />

At this point it is wise to run the script to make sure it works OK.
Getting errors or debugging information from your script is rather painful.
But if it works OK, you should see the IP addresses change in NTP Client, and it re-synchronising.


### 3. Create a Scheduled Task to Run Your Script

**System** -> **Scheduler**

Create a new [schedule](https://wiki.mikrotik.com/wiki/Manual:System/Scheduler) and assign the *On Event* to be the name of your script.

The Mikrotik scheduler is very basic compared to [Cron](https://en.wikipedia.org/wiki/Cron) or [Task Scheduler](https://en.wikipedia.org/wiki/Windows_Task_Scheduler). I've set my interval to *1 day*, which changes to different servers reasonably often.

<img src="/images/NTP-Pool-And-Mikrotik/ntp-schedule.png" class="" width=300 height=300 alt="Schedule." />

And that's it!
The schedule will invoke the script each day and update your NTP Client server IP addresses.


## Conclusion

Mikrotik doesn't support NTP servers via DNS names, which makes `ntp.pool.org` difficult to use.
Scripting allows you to fix gaps in the standard feature line up of a product, and it works well for Mikrotik RouterOS.

Best of all, the clock on my routers is now correct!

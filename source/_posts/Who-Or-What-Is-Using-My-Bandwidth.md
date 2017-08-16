---
title: Who or What is Using my Bandwidth
date: 2016-04-24 17:30:00
updated: 2017-08-13
tags:
- Internet
- Bandwidth
- Diagnose
- Mikrotik
categories: Technical
---

How to use your MikroTik router to see exactly who or what is using your Internet bandwidth. 

<!-- more --> 

## The Problem 

I use my Internet for VoIP calls. 
Either for my work or my home phone.

But if a device is using excessive bandwidth, the call quality drops from "very good" to "totally unusable".

So, I need to track down what is using my bandwidth and disable / pause it.

## What Device?

[Mikrotik](http://www.mikrotik.com/) routers are pretty fantastic [devices](http://routerboard.com/).

We'll use two features to track down where my bandwidth is being used: *[interfaces](http://wiki.mikrotik.com/wiki/Manual:Interface)* and *[torch](http://wiki.mikrotik.com/wiki/Manual:Troubleshooting_tools#Torch_.28.2Ftool_torch.29)*.

These steps assume you're using [WinBox](http://wiki.mikrotik.com/wiki/Manual:Winbox), and have already logged in to your Mikrotik based gateway.


### Interfaces

First up is to identify bandwidth usage at a high level.
Click **Interfaces** from the top-level menu (top left).

You'll see a list of all interfaces on your router.
Which will include physical ports, WiFi interfaces (physical or virtual) and other interfaces including your PPPoE connection and LTE / 3G modems.

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/interfaces.png" class="" width=300 height=300 alt="All My Interfaces" />
 
Check your internet interface (usually PPPoE, or maybe LTE / 3G) to see how much bandwidth is currently being used.
You'll need to already know your connection limits / capacity in advance, as Microtik won't tell you that. 

Mine is using around 4Mbps downstream (Rx = receive) and 120kbps upstream (Tx = transmit).

(And yes, 4MBps is 90% of my downstream capacity. Yay for my ultra fast ADSL connection - and being about as far from the telephone exchange as I can possibly be). 

On the good side, I'm only using about 20% of my upstream capacity, so VoIP calls should be mostly OK.
But something is using all my download capacity.
So lets drill in further to find out what.

### Torch

Our gut reaction is to drill into the Internet interface.
This is actually wrong, but does get us closer to pointing fingers. 
So we'll start by doing the obvious and I'll show where we went wrong and how to fix it in a moment.
 
Double click your Internet interface and click *Torch* (bottom right). 
You should see a list of real-time traffic appear.
Sort by *Rx Rate* or *Tx Rate* so the offending IP addresses are listed at the top. 

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/torch-internet.png" class="" width=300 height=300 alt="What Is My Internet Doing Right Now" />


*UPDATE 2017-08-13*

**IMPORTANT:** If you are using the "webfig" web interface via a browser, you must tick the boxes to collect information about *protocol* and *port*.
If you don't do this, you'll see all IP addresses as `0.0.0.0`.
If you still find trouble getting torch working in *webfig*, please use *WinBox* instead.

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/webfig-torch.png" class="" width=300 height=300 alt="Torch in Webfig needs extra boxes ticked" />

*END UPDATE*


I have two IP addresses to look into: `150.101.98.69` and `23.7.19.36`.
Between them, they are using almost all my 4Mbps.
So more information about these IP addresses will help.

Unfortunately, the destination column (dst) is all the same `150.101.201.180`.
Which I happen to know if my public IPv4 address.
And this does not help us work out what local device is using bandwidth.

And this was our slight mistake before: drilling into the internet interface was not quite right.
We should have drilled into the **bridge** interface.

Fortunately, that is easy to fix: just change the **Interface** drop down in the top left to your bridge interface.

You'll notice that everything is backwards (src and dest, Rx and Tx just swapped), but that's OK.
Its just looking at things from the bridge's point of view. 

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/torch-bridge.png" class="" width=300 height=300 alt="What Is My Router Doing Right Now" />

Now we're in business!
We've got internal and external IP addresses, sorted by usage.

### Address Lookups

I happen to know that `192.168.25.100` is my laptop and `192.168.25.20` is my media server, so now I can start looking more closely in the next section.
But first, lets gather some more information about the external addresses.

I used `nslookup` on my windows laptop to get more information about the top 3 IP addresses:

IP              | Name
----------------|----------
150.101.98.69   | a150-101-98-69.deploy.akamaitechnologies.com
150.101.161.144 | *nothing*
23.7.19.36      | a23-7-19-36.deploy.static.akamaitechnologies.com

You can also cross check and get more information by doing a Who Is lookup on the IPs.
I like using [APNIC's Who Is](http://wq.apnic.net/apnic-bin/whois.pl) service; less ads than the commercial services.

Akamai Technologies is a content distribution network (or CDN), which means we're downloading something (thank you [captain obvious](http://uncyclopedia.wikia.com/wiki/Captain_Obvious)!).

## Netstat

To get more information from my laptop, I used `netstat -n -b` (on Windows, you'll need an elevated command prompt for [netstat's](https://technet.microsoft.com/en-us/library/bb490947.aspx) `-b` option).
This lists all open network connections and the process using them.

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/netstat.png" class="" width=300 height=300 alt="netstat -n -b" />

After a bit of digging, I found the IP address in question.
And the process that was listed against it was `chrome.exe`.

In fact, Chrome was listed several times for that IP address.

Chrome has a lovely *All Downloads* list, which (strangely enough) lists everything its currently downloading. 

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/chrome-download.png" class="" width=300 height=300 alt="What's Chrome Up To?" />

Oh, that right!
I'd just starting downloading a whole bunch of videos from [Build 2016](https://channel9.msdn.com/Events/Build/2016).

(And yes, I started downloading them to illustrate this how-to. It's always helps to know the answer before you start!)


## Something Much Harder

Here are three screenshots from the first time I used *torch*. 
It took a while, but I narrowed down to downloading the Windows 10 install packages.
 
It was made much harder to diagnose because Windows didn't ask me in advance (or provide any other indication it was downloading) and there was nothing special about the IPv6 address listed (Windows was using its new peer-to-peer update function).

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/harder-torch.jpg" class="" width=300 height=300 alt="Why Download From... errr... that Address?" />

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/harder-procmon.jpg" class="" width=300 height=300 alt="Looks a Bit Like Windows Update" />

<img src="/images/Who-Or-What-Is-Using-My-Bandwidth/harder-eventlog.jpg" class="" width=300 height=300 alt="Windows 10? But I'm Using Windows 8!" />
 
There was considerably more guess work involved in that case!

## Conclusion

You can use the *torch* function on Mikrotik routers to identify what local device is using bandwidth, and make a reasonable guess as to what external service its using.
And from there, use local tools to further identify exactly what program is responsible.  

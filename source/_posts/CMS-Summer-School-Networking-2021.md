---
title: CMS Summer School Networking 2021
date: 2021-01-24
tags:
- Mikrotik
- Event
- Audio
- Network
- Switch
- Access Point
categories: Technical
---

Live events run on Ethernet

<!-- more --> 

## Background

Each year my family and I attend a Christian missionary convention [CMS Summer School](https://www.nswsummerschool.org.au/).
The focus of the conference is to hear a series of in-depth Bible talks (5 x 45 min), receive updates from CMS missionaries serving around the world, and to support said missionaries in prayer and financially.
It is attended by ~4,000 people over 6 days.

In short, its the biggest church event I attend in a year.

A few years ago I volunteered for their "tech team", which does major work setting up the various infrastructure required for the conference.
This ranges from power and lighting, to audio and visual (and many other things in-between).

The "tech team" is the goto team for troubleshooting of any vaguely technical issue, plus operating cameras, sound desks, and making recordings.

As per other church meetings, it's effectively a big [live event](/2020-01-18/Managing-an-Event.html). Indeed, the biggest live event I have responsibilities at.

For the last two years, I've been responsible for implementing networking (among other things).


## Goal

To provide networking infrustructure for the conference.
This includes:

* Audio (via [Dante](https://www.audinate.com/meet-dante) devices)
* Live Streaming
* General Internet Access & WiFi
* Connectivity to Video Switcher

Other than in-ear communications and raw video from cameras, pretty much everything runs over ethernet.

Let's drill into a few of those in more detail.

### Dante Audio

Several team members work for [Audinate](https://www.audinate.com/), which created the [Dante](https://en.wikipedia.org/wiki/Dante_%28networking%29) audio protocol.
This is a high quality, low latency protocol to deliver uncompressed digital audio over IP and ethernet.
It achieves extremely tight latency between devices: ~300 microsecond latency is normal.
And is commonly used in the A/V industry.

From a networking point of view, it needs very low latency gigabit switches.

While the mixing desks and amplifiers use standard ethernet, we make heavy use of [Avios](https://www.audinate.com/products/devices/dante-avio), which are an analog to Dante audio adapter.
Most Avios require PoE switches.

I'm not an audiophile by any means, but I can understand the technical side of Dante.
It's basically software controlled audio (similar to the usual software controlled things I'm used in to my day job).

### Live Streaming

2020 was the year of COVID and the year of virtual everything.
CMS Summer School runs in January, and due to a number of [Sydney COVID cases](https://www.bloomberg.com/news/articles/2020-12-20/sydney-s-rising-covid-cases-raise-risk-for-christmas-festivities) in late December, the conference had to pivot from ~500 people in-person to essential persons on-site only (max of 200) live streamed conference with a two week warning.

We always knew live streaming would be our primary audience this year, but something like 95% of our audience ended up being virtual.

So high quality live streaming was very important.

Streaming was done via Vimeo using a [Teradek Vidiu Go](https://teradek.com/collections/vidiu-go-family) hardware device.
Obviously, high speed broadband internet is required.

### Internet Access & WiFi

The network needed Internet access.
The [KCC Conference Centre](https://www.kcc.org.au/), which hosts CMS Summer School, already has Internet access.
We just need to tap into it.
And provide WiFi APs so that wireless devices can connect to the network (there are apps which act as simplified mixing desks for Dante audio).

Nothing special here.

### Video Switchers

Video at CMS Summer School is delivered via 3 HD cameras over [SDI](https://en.wikipedia.org/wiki/Serial_digital_interface) to a [BlackMagic ATEM Video Switcher](https://www.blackmagicdesign.com/products/atem).
A matching video controller is used for live vision control.

Although the raw video does not run over ethernet, the control channel to the video switcher does.


## Implementation

While we tried various VLANs, trunking and other solutions to create isolated networks for Internet vs audio vs other data.
In the end, the best solution was 3 PoE switches in a flat config.
The most complexity was some bridging to create an isolated secondary network (to satisfy a Dante audio requirement).

* 3 x [CRS328-24P-4S+RM](https://mikrotik.com/product/crs328_24p_4s_rm): 24 port PoE switches
* 1 x [hAP2](https://mikrotik.com/product/hap_ac2): border router (also doubled as an AP)
* 3 x [hAP2](https://mikrotik.com/product/hap_ac2): WiFi APs

<img src="/images/CMS-Summer-School-Networking-2021/cms-network-diagram.png" class="" width=300 height=300 alt="Network Diagram (in all its MS Word glory)" />

The **border router** does NAT and some shaping using [simple queues](https://wiki.mikrotik.com/wiki/Manual:Queue).
It has the complex [firewall rules](https://wiki.mikrotik.com/wiki/Manual:IP/Firewall/Filter).
We thought we might need to do other complex things on this device (running HDMI over ethernet through it) but didn't need to.
It is also a WiFi AP, but only because of physical proximity to some of our equipment.

[Border Router config](/images/CMS-Summer-School-Networking-2021/bdr01-config.txt)

<img src="/images/CMS-Summer-School-Networking-2021/border-router.jpg" class="" width=300 height=300 alt="Border Router" />

The **videoland switch** is connected to the border router.
Videoland is where the video switcher lives and the live streaming happens, plus a few minor sub-title / graphics roles (powered by laptops with HDMI outputs).
There are no firewall rules on the switch; our goal is purely hardware switching for minimal latency.
Usually with Mikrotik devices, I use [VLAN interfaces](/2019-07-05/Internode-HFC-NBN-With-Mikrotik.html), but we found they are implemented in software and introduce additional latency that Dante could detect.

Between the border router & videoland switch, we have 24 ports of PoE ethernet + WiFi.

<img src="/images/CMS-Summer-School-Networking-2021/videoland-switch.jpg" class="" width=300 height=300 alt="Videoland Switch" />

**Live streaming** had a dedicated [NBN](https://www.nbnco.com.au/) connection (100Mb down / 40Mb up), plus a [4G / LTE](https://en.wikipedia.org/wiki/LTE_%28telecommunication%29) backup.
These were patched by the owners of the auditorium into a network switch; we just needed to run patch leads to the [Teradek Vidiu](https://teradek.com/collections/vidiu-go-family) devices.
The 4G backup functioned via WiFi: *Teradek > WiFi > switch > external 4G modems*.
Why? The Teradeks do an automatic fail over from ethernet to WiFi; so if the NBN were to fail, the stream would fail over automatically to 4G via WiFi.

In the end, the NBN never failed and the 4G was never used in anger (although we did manage to crash the Teradek due to a particular visual we used at one point).

<img src="/images/CMS-Summer-School-Networking-2021/live-stream-switch.jpg" class="" width=300 height=300 alt="Live Stream Switch" />

The **foldback land switch** patches from video land.
Foldback land is behind the stage controls audio so the band can hear themselves.
It's also where we have all the wireless microphone receivers, amps, etc.
And there's an X32 mixing desk which is considered our master device.
This switch is where DHCP runs from; so it is closest to our master mixing desk.

Dante audio requires duel, redundant and independent networks to function correctly.
And you can't fool it by simply connecting the secondary interface to your main switch, or "forgetting" to connect the secondary interface..
However, you can fool it by creating two, separate networks with no bridge between them.
So we do that for the ~4 devices which require it.

Once again, there's 24 PoE ethernet ports + WiFi.

[Foldback Land Switch config](/images/CMS-Summer-School-Networking-2021/sw01-config.txt)

<img src="/images/CMS-Summer-School-Networking-2021/foldback-land-switch-and-ap.jpg" class="" width=300 height=300 alt="Foldback Land Switch and AP" />

Note we only run **5GHz WiFi** on the APs.
And even then, it's configured on narrow 20MHz channels.
We're in an auditorium which has Ubiquity APs all over the place with guest networks - the 2.4GHz spectrum is completely full and useless for us.
And we aren't trying to push bulk data over WiFi, just ~100kB/sec of control data.
So its multiple APs on narrow, non-overlapping 5GHz channels.

[AP config](/images/CMS-Summer-School-Networking-2021/ap01-config.txt)

Finally, our **front of house** switch patches from foldback land for both primary and secondary networks.
Other than the secondary network, there's nothing extra here.

<img src="/images/CMS-Summer-School-Networking-2021/front-of-house-switch-and-ap.jpg" class="" width=300 height=300 alt="Front of House Switch and AP" />


## In Action

When in action, we see up to 60Mbps of traffic and 30kpps:

<img src="/images/CMS-Summer-School-Networking-2021/network-stats-mixer.png" class="" width=300 height=300 alt="Network Stats on X32 Mixer" />

But that can vary, depending on device:

<img src="/images/CMS-Summer-School-Networking-2021/foldback-land-interfaces.png" class="" width=300 height=300 alt="Foldback Land Interface List" />

And around 40 devices on DHCP:

```
[admin@sw01-foldback-poe] /ip dhcp-server lease> print
 #   ADDRESS                    MAC-ADDRESS       HOST-NAME          SERVER           LAST-SEEN                    
 1   192.168.16.61              34:F6:4B:00:00:00 AdmiralAckbar      dhcp-primary     24m31s                       
 2 D 192.168.16.198             00:15:64:00:00:00 X32-00-53-EB       dhcp-primary     1h35m3s                      
 3 D 192.168.16.194             00:1D:C1:00:00:00                    dhcp-primary     1h35m2s                      
 4 D 192.168.16.193             00:1D:C1:00:00:00                    dhcp-primary     1h35m1s                      
 5 D 192.168.16.191             00:0E:DD:00:00:00                    dhcp-primary     1h17m36s                     
 6 D 192.168.16.190             00:1D:C1:00:00:00                    dhcp-primary     1h34m59s                     
 7 D 192.168.16.189             00:1D:C1:00:00:00                    dhcp-primary     1h35m1s                      
 8 D 192.168.16.188             00:1D:C1:00:00:00                    dhcp-primary     1h35m1s                      
 9 D 192.168.16.187             00:1D:C1:00:00:00                    dhcp-primary     1h35m1s                      
10 D 192.168.16.186             00:1D:C1:00:00:00                    dhcp-primary     1h33m39s                     
11 D 192.168.16.185             00:1D:C1:00:00:00                    dhcp-primary     1h35m1s                      
12 D 192.168.16.184             00:1D:C1:00:00:00                    dhcp-primary     1h34m59s                     
13 D 192.168.16.181             58:B0:35:00:00:00 audio-laptop       dhcp-primary     39m54s                       
14 D 192.168.16.179             00:1D:C1:00:00:00                    dhcp-primary     1h15m37s                     
15 D 192.168.16.182             00:1D:C1:00:00:00                    dhcp-primary     1h15m30s                     
16 D 192.168.16.177             00:15:64:00:00:00 X32-04-33-A7       dhcp-primary     1h15m47s                     
17 D 192.168.16.176             00:15:64:00:00:00 X32P-01-5E-AC      dhcp-primary     1h15m42s                     
18 D 192.168.16.175             00:1D:C1:00:00:00                    dhcp-primary     1h34m59s                     
19 D 192.168.16.174             00:1D:C1:00:00:00                    dhcp-primary     1h34m59s                     
20 D 192.168.17.179             00:0E:DD:00:00:00                    dhcp-primary...  1h17m39s                     
21 D 192.168.17.178             00:1D:C1:00:00:00                    dhcp-primary...  1h35m2s                      
22 D 192.168.16.173             00:0E:DD:00:00:00                    dhcp-primary     1h17m31s                     
23 D 192.168.17.177             00:1D:C1:00:00:00                    dhcp-primary...  1h15m41s                     
24 D 192.168.17.176             00:1D:C1:00:00:00                    dhcp-primary...  1h15m38s                     
25 D 192.168.16.169             D0:37:45:00:00:00 Record-B           dhcp-primary     4m23s                        
26 D 192.168.16.167             40:6C:8F:00:00:00 packer-mac         dhcp-primary     1h34m58s                     
27 D 192.168.16.166             00:1D:C1:00:00:00                    dhcp-primary     1h35m1s                      
28 D 192.168.16.164             2C:36:F8:00:00:00 StageIO-Switch     dhcp-primary     1h34m55s                     
29 D 192.168.16.161             C8:BC:C8:00:00:00 Record-A           dhcp-primary     4m6s                         
30 D 192.168.16.160             6C:70:9F:00:00:00 iPad               dhcp-primary     18m14s                       
31 D 192.168.16.159             58:EF:68:00:00:00 CMSs-MBP           dhcp-primary     17m55s                       
32 D 192.168.16.152             00:1D:C1:00:00:00                    dhcp-primary     1h35m                        
33 D 192.168.16.199             C8:5B:76:00:00:00 LAPTOP-R6B5QC28    dhcp-primary     1h17m30s                     
34 D 192.168.16.144             2C:59:8A:00:00:00                    dhcp-primary     2m39s                        
35 D 192.168.16.141             00:E0:4C:00:00:00 Attila             dhcp-primary     sometime                     
36 D 192.168.16.140             82:4B:30:00:00:00                    dhcp-primary     30m16s                       
37 D 192.168.16.150             C6:F8:C0:00:00:00 Toms-iPhone        dhcp-primary     47m52s                       
38 D 192.168.16.139             C4:65:16:00:00:00 L19AU-33639        dhcp-primary     12m35s                       
39 D 192.168.16.138             00:E0:4C:00:00:00 Joshuas-MBP        dhcp-primary     1h34m55s                     
40 D 192.168.16.137             F2:6F:E9:00:00:00 Jymz               dhcp-primary     14s                          
41 D 192.168.16.135             00:E0:4C:00:00:00                    dhcp-primary     31m26s                       
42 D 192.168.16.134             74:E2:F5:00:00:00 Beth-iPad          dhcp-primary     27m18s                       
43 D 192.168.16.133             00:1D:C1:00:00:00                    dhcp-primary     9m1s                         
```


A couple of interesting things to point out:

1. The maximum required bandwidth for our 32 channel mixers is ~60Mbps. And many ports are operating as low as 4Mbps (AVIOs).
2. The bridge interface is not being used directly; the audio packets are entirely in the switch ASIC. This is rather unusual for me - all my home networking hits the bridge interface.
3. There are more discrete devices on the network then I thought (almost 50 configured via DHCP).


## Future

We couldn't do any VLAN trunking over single cables, because the software VLAN implementation caused Dante audio latency problems.
Fortunately, we didn't need to - we had enough network outlets to patch two flat networks.
However, if we want this feature, we'd need to work out how to implement it using [hardware switch rules](https://wiki.mikrotik.com/wiki/Manual:CRS3xx_series_switches#Switch_Rules_.28ACL.29).
There was even talk of converting the switches to [SwOS](https://wiki.mikrotik.com/wiki/SwOS/CSS326), to minimise the chance of using features implemented in software - but everyone on team is so familiar with [RouterOS](https://wiki.mikrotik.com/wiki/Manual:TOC) we're very hesitent.

We may move DHCP off the foldback land switch to the border router.
It's something in software on latency critical switches, and it really doesn't need to be there.
The leases are deliberately long enough to cover our live sessions, but short enough to expire before the next session begins.

Although not required this year, we've run HDMI over ethernet to get video to other parts of the property - around 150m away from video land (where the signal originates).
This is painful because a) we don't have enough cable runs to where the video needs to get to, b) its video only; we have to run Dante audio separately, c) it consumes too much bandwidth.
Given we had plenty of success with streaming via RTMP this year, I'm considering using it to replace HDMI over ethernet.
Rather than streaming out to YouTube or Facebook or wherever, and then back in again (with the 30 second delay and external bandwidth hit) we could run an [internal RTMP service via nginx](https://obsproject.com/forum/threads/how-to-set-up-your-own-private-rtmp-server-using-nginx.12891/) which can be consumed by any location with ethernet (even WiFi) on-site.
The main advantage is it runs combined audio & video at a high quality using 8.5Mbps, and solves most of our HDMI over ethernet problems.
The disadvantage is we need a smart device ([Raspberry Pi](https://pimylifeup.com/rtmp-streams/), [Android device](https://www.nvidia.com/en-us/shield/shield-tv/) or [Android TV](https://www.foxtechzone.com/2019/10/vlc-for-android-smart-tv.html)) to play the RTMP stream.
That and I haven't tested it.

We have a bunch of analog comms (think video director talking to camera operators), which I think is the very last bit of analog gear we use.
I'd like to get rid of that and run digital comms over Ethernet.
No idea what this involves though.


## Conclusion

CMS Summer School is a reasonably large live event.
And pretty much everything A/V runs over ethernet at live events.
Mikrotik devices are cheap, powerful and meet our requirements for pushing ~100Mbps around for Dante audio.
Along with our more minor networking needs, Mikrotik has us covered.

And that means speakers and missionaries can get on with their thing: sharing Jesus.


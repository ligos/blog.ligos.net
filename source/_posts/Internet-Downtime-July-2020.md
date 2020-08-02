---
title: Internet Downtime - July 2020
date: 2020-08-02
tags:
- Lightning
- Storm
- Downtime
- Failure
- Induction
- Mikrotik
categories: Technical
---

Downtime Sucks. Again.

<!-- more --> 

## Background

In my part of Sydney, the [NBN](https://www.nbnco.com.au/) Internet is connected via [HFC](https://en.wikipedia.org/wiki/Hybrid_fibre-coaxial).
That is, the last mile connection to the Internet is via a copper cable.

Due to a strange set of circumstances when the NBN was deployed in my block of 6 units, I'm [sharing my connection with 2 other units in our complex](/2019-11-04/PPPoE-Server-on-Mikrotik.html).
So there's ~150m of ethernet cable running across the roof of our block.
That is, I'm playing ISP for my neighbours.

Unfortunately, copper cables conduct electricity.
Even more unfortunately, lightning is made of electricity.


## A Thunderstorm

On 12/July/2020, there was a severe thunderstorm in my area.
I wasn't at home at the time (my family was at a friend's house for lunch), but even there the storm was pretty bad.

I got a message from [Uptime Robot](https://uptimerobot.com) that said my Internet connection was down, and I assumed there was a power outage from the storm.
So when I got home, I checked the circuit breakers and lights.
Only to find power was normal - everything was working, but no Internet.

### Determine Equipment Loss

I checked the HFC modem and noticed it didn't seem to have power.
So power-cycled it.
When that didn't have any effect, I power-cycled the UPS it's plugged into.

Again, nothing.

I checked other equipment and found my [hEX](https://mikrotik.com/product/hex_s) router had also failed.
(And later on, found an ethernet port on a server was also dead).

Here are some pictures of the hEX and HFC modem.
The hEX has visible damage, while I couldn't pick anything obviously broken about the HFC modem.

<img src="/images/Internet-Downtime-July-2020/faulty-hex-router-and-hfc-modem.jpg" class="" width=300 height=300 alt="The insides of the HFC Modem and hEX Router." />

<img src="/images/Internet-Downtime-July-2020/damage-to-hex-router.jpg" class="" width=300 height=300 alt="There was obvious damage to the hEX Router." />


At the time I was annoyed because both the modem and router were protected by separate UPSs, and the UPSs were fine.
Even the plug-packs which powered the devices were OK.


### Call ISP for Replacement Modem

You never call NBN Co directly, instead you need to register the fault with your ISP.

So I gave [Internode](https://www.internode.on.net/) a call.
As usual, their service was fantastic - the converstion went something along the lines of: "My Internet isn't working. There's no power lights on my NBN modem. And there was a thunderstorm a few hours ago. I think you can see where I'm going with this".

The tech didn't even bother troubleshooting anything with me, and helpfully arranged an appointment for an NBN tech to replace the HFC modem the next day.

### Find Alternative Mikrotik for Router

Long ago, my [very first Mikrotik device was a RB2011](/2017-02-16/Use-A-Mikrotik-As-Your-Home-Router.html).
It was the router which converted me to Mikrotik and meant I've never bought networking gear from another vendor since.

The hEX had replaced the RB2011 as my router ~18 months earlier, in preparation for the NBN becoming available.
Since then, the RB2011 was sitting on my desk as a smart switch in my "home office" (aka garage).

Well, it was time to push the RB2011 back into service as a real router!
Although it's hardware isn't as powerful as the hEX or even more recent [hAP ac²](https://mikrotik.com/product/hap_ac2), the software is identical.
So I was confident any feature I used in the hEX would also work with the RB2011. 


I pulled my latest backup script from the hEX, and started making appropriate changes to the RB2011.
Two things came out of this, 1) my backup was a few months old, so it wasn't perfect, and 2) I'm glad I take both a [system backup](https://wiki.mikrotik.com/wiki/Manual:System/Backup) and a [configuration export](https://wiki.mikrotik.com/wiki/Manual:Configuration_Management). The *backup* works for a like-for-like restore, but doesn't work when devices and configuration need to change - the *export* lets you restore parts of the configuration as required.

Finally, I installed it and physically connected all the cables, as required:

<img src="/images/Internet-Downtime-July-2020/rb2011-router.jpg" class="" width=300 height=300 alt="Everything old is new again - RB2011 once again routes my packets!" />

### Install Replacement Gear

I had everything plugged in and ready to go when the NBN tech arrived the following day.
(Incidently, it was the same tech which did my original installation around 12 months earlier).

After he tested the upstream HFC connection was still OK, he installed and connected a new HFC modem.
(He left the old broken one with me, as per the photos above).

Within 10 minutes, the RB2011 had established a connection to my ISP and I started getting notifications from [Uptime Robot](https://uptimerobot.com/) that I was back online!

An hour or so later, I connected up my neighbours again and enabled the [PPPoE server](/2019-11-04/PPPoE-Server-on-Mikrotik.html).
An accidental misconfiguration meant one of my neighbours wasn't online until the next morning.

For a lightning strike which damaged equipment, I was back up in under 24 hours!
And neighbours were up within 36!

That's a pretty good outcome!

(And even my neighbours are particularly happy with the level of support from their "ISP")!


## What Was The Cause?

I thought it was pretty likely there was a nearby [lightning strike](https://en.wikipedia.org/wiki/Lightning_strike) which caused the damage.
This was confirmed by neighbours who were at home at the time - they heard an extremely loud "bang", which caused a short power outage, and they also had equipment damaged (NBN modems and networking gear).

But right from the beginning, I knew there wasn't a direct strike on our building.
Lightning strikes involve a lot of energy: [thousands of ampers, tens of thousands of volts](https://www.windpowerengineering.com/how-much-power-in-a-bolt-of-lightning/), which works out to be at least one billion watts of energy discharged in milliseconds, for even a baby lightning bolt.

That much energy won't damage equipment, it will vaporise it!
(Or, if you're lucky, just set fire to it).

[Kenneth Schneider has some information about lighining strikes](https://www.arcelect.com/lightnin.htm), and [Littlefuse has more technical detail](https://www.littelfuse.com/~/media/electronics_technical/application_notes/esd/littelfuse_overview_of_electromagnetic_and_lighting_induced_voltage_transient_application_note.pdf) (which is completely over my head, but someone with an electrical background should get it).

Schneider has a fantastically understated quote:

> Lightning induced surges usually alter the electrical characteristics of semiconductor devices so that they no longer function effectively.

Err... yes, that's definitely what I experienced - "altered electrical characteristics" and my devices were "no longer functioning effectively".

Basically, lightning induced power surges can still damage and destroy equipment, even when the strike doesn't directly hit said equipment.
Usually, the strike is against the grounding wire above power-lines, but even that is enough to induce a surge in exposed electrical wiring.

150m of CAT6 cable and similar lengths of coaxial copper cable definitely qualify as "exposed wiring" when we're talking 100kV+.

This picture is by [W8JI](http://www.w8ji.com/), and posted on [the HAM Radio StackExchange](https://ham.stackexchange.com/a/1538):

<img src="/images/Internet-Downtime-July-2020/lightning-induced-current-diagram.jpg" class="" width=300 height=300 alt="Lightning can effect your equipment even when the strike is far away." />

At least 3 units in our complex lost HFC modems, and my router was destroyed, but there was no damage to UPSs protecting the modem and router.
So my guess is the induced current occurred in either the ethernet cables connecting our units, or the coaxial cable from the street to units - maybe both.


## Network Improvement for Next Time

My network had the Internet router at its core.
Literally, every device had to go through my hEX router to talk to something else.
Even though I have a separate WiFi access point, and other switches on my network.

<img src="/images/Internet-Downtime-July-2020/old-network-diagram.png" class="" width=300 height=300 alt="If the router fails, the whole network fails." />

This is pretty normal for most households - one device to rule them all.
Aka, [single point of failure](https://en.wikipedia.org/wiki/Single_point_of_failure).

When my hEX was destroyed, not only did I (and my neighbours) lose the Internet, I also lost my LAN.
I should know better than this; most of my professional life has been about mitigating the impact of technical failures.

So, when I get a replacement [hAP ac²](https://mikrotik.com/product/hap_ac2), it will be my Internet gateway / border device. 
And my RB2011 will be my DHCP server and run my internal network.
That way, another lightning strike may kill the hAP, but my LAN will (hopefully) continue functioning.

<img src="/images/Internet-Downtime-July-2020/new-network-diagram.png" class="" width=300 height=300 alt="No router, no internet. But the LAN continues to work." />

Oh, and Ubiquity sells a [gigabit rated Ethernet surge protector](http://dl.ubnt.com/datasheets/ETH-SP/ETH-SP-G2_DS.pdf) for AUD $30.
Even if I can't protect the HFC side, at least I can protect the Ethernet cables running between units.


## Conclusion

Downtime makes me sad.
And this downtime was particularly bad.

Again.

Unfortunately, there's not much I can do to protect against lightning strikes during thunderstorms.
Fortunately, they don't happen too often - this is the first one I've had first hand experience with (although my father tells me there was a similar incident at his house many years ago).

In the end, a quick response time from NBN Co and having my old trusty RB2011 available at quick notice meant I was back online within 24 hours.
I'll improve my internal network structure, and add some extra surge protectors in the hope of less damage next time.


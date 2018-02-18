---
title: Mikrotik Routers and the Remove Button
date: 2018-02-18
tags:
- Mikrotik
- Nuke it from Orbit
- Remove
- Networking
- User Interface
categories: Technical
---

Aka "nuke it from orbit".

<!-- more --> 

## Background

I've blogged in the past about using the [Mikrotik Torch](/2016-04-24/Who-Or-What-Is-Using-My-Bandwidth.html) function to work out what device is using network bandwidth.

The other day, I was on a business call when it started dropping in and out.
That usually means something is using all my pitiful ADSL bandwidth (3.5Mbps down, 800kbps up).
So I opened *winbox*, connected to my router and clicked **Torch** to work out the culprit.


## The Remove Button

Except I didn't click **Torch**.
I clicked **Remove**.

On the **Main LAN Bridge** interface.

And suddenly, everything stopped working.

The call I was on dropped.
My VPN disconnected.
The Internet wasn't accessible.
And I started receiving failure notifications from [Uptime Robot](https://uptimerobot.com/).

Worst of all, I couldn't connect to my router any more.


## What's A Bridge Anyway

A [bridge](https://wiki.mikrotik.com/wiki/Manual:Interface/Bridge) is the layer 2 interface in Mikrotik devices that connect a bunch of real or virtual interfaces together into one network.
Its not a physical interface like an ethernet port or even a switch, but a thing which only exists in software.
I think of it as a [layer 2.5](https://en.wikipedia.org/wiki/OSI_model#Layer_2:_Data_Link_Layer) device - sitting above layer 2 ethernet or SFP ports, but below layer 3/4 network protocols like TCP/IP.
On my LAN, most ethernet ports connect to it, plus a VLAN for WiFi coming from [my access point](/2018-01-01/Mikrotik-WiFi-Access-Point-With-VLAN.html).
It also has IP addresses (v4 and v6) and DHCP servers bound to it.

In effect, the **Main LAN Bridge** interface is the virtual "switch" for my home LAN.
(There are separate virtual interface for my phones, kids devices and guest WiFi).

So when I clicked **Remove** on the **Main LAN Bridge**, I effectively deleted my whole LAN.

<img src="/images/Mikrotik-Routers-and-the-Remove-Button/evil-remove-button.png" class="" width=300 height=300 alt="Nuke My Network from Orbit, or Just See What's Making it Slow" />


## Some Rather Negative Comments About Mikrotik's User Interface

I've written several [blog posts about Mikrotik](/tags/Mikrotik/).
They have been very positive.
And I am a total convert to their equipment: I refuse to install consumer grade networking equipment any longer; Mikrotik gives commercial grade quality at a price only slightly higher than consumer gear.
The only non-Mikrotik device on my network is a D-Link router, with all the routing functions disabled so it acts like a dumb switch.

I like that Mikrotik lets you do pretty much anything.
There aren't fancy interfaces or wizards.
Mikrotik gives you all kinds of building blocks, and lets you snap them together however you see fit.

If you want 3 ethernet ports plus a virtual WiFi AP all on the same network, that's fine.
If you want a bunch of other ports on a separate network, that's fine too.
If you want to create a custom inbound VPN, or a site-to-site IPsec tunnel, you can do that.
If you want to do weird and unusual things, your router won't stop you.

But **Remove** was just dumb.


### Dumb 1 - Buttons Right Next to Each Other

I count 3 or maybe 4 pixels between the two buttons.

*Remove* deletes the current interface with no confirmation, no undo and no recourse.
Delete the wrong thing and you lose connectivity with the router (and need to do a hardware reset).
I don't think I've ever clicked that button, because there's another *remove* button on lists, which I use instead.

<img src="/images/Mikrotik-Routers-and-the-Remove-Button/remove-button-that-I-use.png" class="" width=300 height=300 alt="This is the way I remove things" />

*Torch* on the other hand, has no ill effects.
It does nothing destructive to your router (beyond consume a few more CPU cycles).
Rather, it lets you examine - in detail - the traffic flowing across your network.

So we have a *nuke it from orbit* button and an *inspect* button right next to each other.

Not the greatest UI design.


### Dumb 2 - Interface Had Ports Connected to it

My **Main LAN Bridge** had a whole bunch of ports attached to it.
With live traffic flowing across it.

Surely, that's a big hint that it shouldn't be deleted.

Now, I totally understand you might want to delete the bridge one day.
So, force the user to remove all the ports attached to the bridge, so it's effectively a zero port switch.
Then let me delete it.


### Dumb 3 - Interface Had Other Services Bound to it

To add to the last point, it also had an IPv4 address and DHCP server bound to it.
The DHCP server has current leases. 
Not to mention a public IPv6 address, which serves router advertisements.

Just like *dumb 2*, if you want to delete an interface, first require the user to tear down the services and addresses which are bound to it.


### Dumb 4 - Other Functions Have Validation

Now I get that Mikrotik routers don't have the usual safety nets that consumer gear does.
That's usually a feature.
But it certainly has validation for particular configurations.

Want to add an IP address which is already in use on your network - nope, it refuses.
Want to configure impossible firewall rules (like a dst-NAT rule with a source interface) - sorry, you get an error.
Try to add a DHCP server to an interface before you configure an IP address - no go.

*Remove* seems like a pretty good function to have some kind of validation attached to it.


## How to Fix it?

OK. Enough whining from me.

I fixed this one by creating a new bridge.
Not exactly rocket science.

OK, I needed to create a new bridge using [TikApp](https://play.google.com/store/apps/details?id=com.mikrotik.android.tikapp&hl=en) on my phone.
(After all, my laptop couldn't connect to the router).

Turns out having my phones on a separate network isn't just nice for keeping nasty malware off my network.
My phone was totally unaffected by removing my main LAN - because my phones aren't on my main LAN!
Accidental redundancy!

Anyway, I needed to create a new bridge, add appropriate ethernet and WiFi ports, then bind an IP address to the bridge and create a DHCP server as well.

Actually, I didn't even need to create new IPs or DHCP servers.
The old ones were still there.
They just weren't bound to any interface.
Open them up and select the new bridge and everything started working again.

(I've since dedicated a real Ethernet port as *emergency*, with an special IP address and it's own DHCP server.
Ready to plug into if everything blows up again.)


## Conclusion

Mikrotik lets you do pretty much anything.
Including nuke your LAN from orbit.
Without any fuss like *are you really sure?*

And for once, that's not a feature, I'm calling it a bug.
I'll be raising it on their [forum](https://forum.mikrotik.com/index.php) to improve in future versions.

(PS: Mikrotik devices actually get regular updates, so its pretty likely it will get fixed... some day. Well, its 1000% more likely than with a consumer router).

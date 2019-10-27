---
title: L2TP VPN on Mikrotik, Android and Windows
date: 2019-10-27
tags:
- Internet
- Mikrotik
- Guide
- VPN
- Android
- Windows
categories: Technical
---

Make your own VPN.

<!-- more --> 

## Background

I haven't needed VPN access to my home network in the past.
Mostly, because my ADSL connection would would make it prohibitively slow.
But with a shiny new [NBN HFC connection](/2019-07-05/Internode-HFC-NBN-With-Mikrotik.html), I have bandwidth to burn!

It's also useful to have remote access to devices, in case something goes wrong or I need data that's not in the cloud.
And, with the right DNS settings, means I can get the benefit of [Pi-Hole](https://pi-hole.net/) blocking even when I'm on the road.

## Goal

Configure a Mikrotik router to allow L2TP VPN access for Windows and Android devices.
No additional VPN apps should be required on Windows or Android; out of the box providers only.


## Router Steps

First, we need to configure the router.

### Step 1 - Firewall Rules

Before we configure anything related to VPNs, we need to make sure we allow the right packets through the firewall.
I've allowed traffic on UDP ports 500, 1701 and 4500, plus two IP protocols relating to IPSec: *ipsec-esp (50)* and *ipsec-ah (51)*.

<img src="/images/L2TP-VPN-on-Mikrotik/IPSec-Firewall-Rules.png" class="" width=300 height=300 alt="IPSec related Firewall rules" />

```
/ip firewall filter
add action=accept chain=input comment="Allow L2PT / IPSec VPN access" \
    dst-port=500,1701,4500 in-interface-list=WAN protocol=udp
add action=accept chain=input in-interface-list=WAN protocol=ipsec-esp
add action=accept chain=input in-interface-list=WAN protocol=ipsec-ah
```

### Step 2 - Configure L2TP

Now we can configure the VPN!

[L2TP](https://en.wikipedia.org/wiki/Layer_2_Tunneling_Protocol) allows you to tunnel between two endpoints.
It doesn't provide encryption on its own, but is usually combined with [IPSec](https://en.wikipedia.org/wiki/IPsec) for security.

We need to add a *profile* and then a *secret*.
*Profiles* let you define behaviour for many connections, and then you can override some settings at the individual login level (*secret*).

Go to *PPP > Profiles*, and Add a new profile.
All I add here are internal DNS servers, because I want to take advantage of my [Pi-Hole](https://pi-hole.net/).
Everything else remains default.

<img src="/images/L2TP-VPN-on-Mikrotik/PPP-Profile-General.png" class="" width=300 height=300 alt="PPP Profile" />

```
add dns-server=192.168.1.19,192.168.130.31 name=l2tp-vpn
```

Now go to the *PPP > Secrets* tab, and Add a new secret.
You'll need to select your *profile*, and enter a *password*.
I assign a static IP addresses at this point as well, because I only have a small number of devices.
If you want a dynamic address, use an IPv4 *pool name* instead of an IP adderss.

<img src="/images/L2TP-VPN-on-Mikrotik/PPP-Secret.png" class="" width=300 height=300 alt="PPP Secret" />

```
add local-address=192.168.2.1 name=muj-phone password=ThePassword profile=\
    l2tp-vpn remote-address=192.168.2.118 remote-ipv6-prefix=\
    2001:44b8:3196:3a00::/64
```

The password you assign at this point isn't that important, as IPSec will protect it.

Although I have assigned an IPv6 prefix, neither my Android phone nor Windows 10 laptop made use of it.
Not sure if the problem is with the router, my configuration or the devices.

Finally, we can enable L2TP!
Go to *PPP* and click *L2TP*, and tick *Enabled*.
The important thing is to set *Use IPSec* to *required*, and to enter an approprate *IPSec secret* (you may like to generate one from [makemeapassword.ligos.net](https://makemeapassword.ligos.net), or use your password manager).

<img src="/images/L2TP-VPN-on-Mikrotik/PPP-L2TP.png" class="" width=300 height=300 alt="PPTP is Enabled!" />

```
/interface l2tp-server server
set allow-fast-path=yes default-profile=l2tp-vpn enabled=yes\
    ipsec-secret=S3cre1Pa$$w0rd use-ipsec=required
```

Recent RouterOS versions will automatically configure IPSec for you at this point.
This is a real help, because I've always found IPSec to be difficult to get right, and painful to troubleshoot when I get it wrong.
If you're running an older version, look at the "*Other Guides*" section below for details.

Mikrotik reference for [PPP](https://wiki.mikrotik.com/wiki/Manual:PPP_AAA), and [L2TP](https://wiki.mikrotik.com/wiki/Manual:Interface/L2TP).

### Step 3 - Muck With the IPSec Config (optional; not recommended)

As mentioned above, if you're on the most recent RouterOS firmware, IPSec will be configured correctly so it Just Works™.
Of course, I noticed that it hadn't turned the encryption up to 11 and decided to muck with it.
Eventually, after breaking everything, I swallowed by pride, deleted all IPSec config and let the L2TP re-add it correctly.

My recommendation is to very carefully note the exact dynamic configuration, and use the *Copy* function to make changes.

Here's what I have ended up with, for reference:

<img src="/images/L2TP-VPN-on-Mikrotik/IPSec-Profile.png" class="" width=300 height=300 alt="IPSec Profile with tweaked settings" />

<img src="/images/L2TP-VPN-on-Mikrotik/IPSec-Proposal.png" class="" width=300 height=300 alt="IPSec Profile with tweaked settings" />

```
/ip ipsec profile
set [ find default=yes ] enc-algorithm=aes-256,aes-128,3des

/ip ipsec proposal
set [ find default=yes ] auth-algorithms=sha256,sha1 \
    enc-algorithms="aes-256-cbc,aes-256-gcm,aes-192-cbc,aes-192-gcm,aes-128-cbc,aes-128-gcm,3des" \
    pfs-group=modp2048
```

I've just enabled a few more modern encryption options (SHA256 and AES256).
However, not all clients (I'm looking at you Windows 10) support SHA256, so the *profile* hash algorithm remains SHA1 (the default).
These settings work for my Windows and Android clients; make sure you test in your environment.

Mikrotik reference for [IPSec](https://wiki.mikrotik.com/wiki/Manual:IP/IPsec).

## Android Steps

Now, to configure an Android device.

My phone is running Android 8.1 via [Lineage OS 15.1](https://lineageos.org/); your device may be different.

Goto *Settings > Network & Internet > VPN*.
And tap the *plus / add* button.
And then the *Show advanced options* checkbox.

<img src="/images/L2TP-VPN-on-Mikrotik/Android-Add-VPN-Connection.png" class="" width=300 height=300 alt="Add VPN Connection in Android" />

Enter the following:

| Field  | Details | Example      |
|--------|---------|--------------|
| Name     | Something to identify your VPN | My Home |
| Type | L2TP/IPSec PSK | |
| Server Address | IP or DNS name for your router | vpn.ligos.net / 59.167.129.207 |
| L2TP Secret | blank | |
| IPSec identifier | blank | |
| IPSec preshared key | Your pre-shared key, | S3cre1Pa$$w0rd |
| DNS serach domains | blank | |
| DNS servers | blank | |
| Forwarding routes | blank | |
| Username | Your L2TP username | murray |
| Password | Your L2TP password | wordpass |

<img src="/images/L2TP-VPN-on-Mikrotik/Android-VPN-Details.png" class="" width=300 height=300 alt="VPN Connection Details in Android" />

Tap save.
And then tap your VPN and *Connect*.

After a few seconds, it should connect and you're good to go!

<img src="/images/L2TP-VPN-on-Mikrotik/Android-VPN-Connected.png" class="" width=300 height=300 alt="VPN Connected in Android" />

### Always On VPN

Android can be configured so all network traffic must go across a VPN.
This means your mobile provider cannot observe anything about your activity - they'll just see a stream of L2TP packets on UDP port 500.

I've opted to go for this option.
However, it does have several caveats:

* You need a static IP address; "all traffic" includes DNS - so you can't use a dynamic DNS service to work around this.
* You need to statically configure DNS servers. I'm not 100% sure why this is the case, because the router is perfectly capable of assigning DNS when the tunnel is created. And no traffic is allowed until the tunnel is up. In any case, you can use your router's internal IP address, internal DNS servers, or a public DNS service of your choice.

Make the following changes to your VPN settings:


| Field  | Details | Example      |
|--------|---------|--------------|
| Server Address | Your static IP address  | 59.167.129.207 |
| DNS servers | Space separated IP addresses of DNS servers | 192.168.0.1 1.1.1.1 |
| Always on VPN | ticked | ✓ |

<img src="/images/L2TP-VPN-on-Mikrotik/Android-AlwaysOn-VPN.png" class="" width=300 height=300 alt="Always On VPN Connected in Android" />

For the *DNS servers*, I recommend either a) use your router, b) use multiple internal servers (in my case, I have several [Pi Holes](https://pi-hole.net/)), or c) at least one public DNS server (eg: [Cloudflare](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/) or [Quad9](https://www.quad9.net/)). 
Without functioning DNS, the Internet just doesn't work.

## Windows Steps

Now to configure Windows.

Open *Seetings* and search for *Network Status*.
Select *VPN* from the menu on the left.
Click *Add a VPN Connection*.

<img src="/images/L2TP-VPN-on-Mikrotik/Windows-Add-VPN-Connection.png" class="" width=300 height=300 alt="Add VPN Connection in Windows 10" />

Enter the following:

| Field  | Details | Example      |
|--------|---------|--------------|
| VPN Provider     | Windows (built-in) |  |
| Connection name | Something to identify your VPN | My Home |
| Server address or name | IP or DNS name for your router | vpn.ligos.net / 59.167.129.207 |
| Type | L2TP/IPSec with pre-shared key | |
| Pre-shared key | Your pre-shared key | S3cre1Pa$$w0rd |
| Type of sign-in info | Username and password | |
| Username | Your L2TP username | murray |
| Password | Your L2TP password | wordpass |

<img src="/images/L2TP-VPN-on-Mikrotik/Windows-VPN-Details.png" class="" width=300 height=300 alt="VPN Connection Details in Windows 10" />

Click save.
And then click your VPN and *Connect*.

After a few seconds, it should connect and you're good to go!

<img src="/images/L2TP-VPN-on-Mikrotik/Windows-VPN-Connected.png" class="" width=300 height=300 alt="VPN Connected in Windows 10" />


## Active Connections

Mikrotik always gives you good status and diagnostic tools (compared to residential routers).
This is what you see when there's an active connection:

<img src="/images/L2TP-VPN-on-Mikrotik/PPP-Active-Connections.png" class="" width=300 height=300 alt="PPP Active Connections" />

Double click the PPP interface and you'll see the usual real time statistics and graphs.

<img src="/images/L2TP-VPN-on-Mikrotik/PPP-Interface-Status.png" class="" width=300 height=300 alt="PPP Interface Status" />

And similar details in IPSec.

<img src="/images/L2TP-VPN-on-Mikrotik/IPSec-Active-Peers.png" class="" width=300 height=300 alt="IPSec Active Peers" />

<img src="/images/L2TP-VPN-on-Mikrotik/IPSec-Installed-SAs.png" class="" width=300 height=300 alt="IPSec Installed SAs" />

If you manually create a L2TP interface with the same *name* and *user* as the dynamic one, that will let you assign the interface to firewall rules or interface lists.
You could also use a static IP address for this, but I've come to prefer interface lists rather than IP addresses in my firewall rules.
Simply see what the names are, disconnect your device, and manually create an L2TP interface.

```
/interface l2tp-server
add name=l2tp-muj-phone user=muj-phone
```


## Annoyances

My main use for VPN is on my phone.

The "always on" connection works as advertised, most of the time.
But it struggles when my LTE connection drops in and out, which happens on train trips - moving at speed and going in and out of tunnels.
It also doesn't cope that well when I connect and disconnect from WiFi - the device's IP address changes and the VPN sees packets from the wrong address.
Android will reconnect automatically, but the VPN takes ~60 seconds to notice the old connection was dropped, and doesn't always reconnect successfully.
Sometimes it takes 2 or 3 minutes to reconnect, only for the connection to drop again 2 minutes later.

Frustrating to say the least.

My other annoyance is the VPN doesn't pick up an IPv6 address; it's IPv4 only.
But a kind of restricted IPv4 - you can connect to other devices, but you can't discover them, probably because the VPN is in a different [broadcast domain](https://en.wikipedia.org/wiki/Broadcast_domain).
All that means [SyncThing](https://syncthing.net/) can't discover or connect other devices, even when I'm on my home WiFi.
And, SyncThing is how I upload photos from my phone to a computer.
So, every weekend (at least) I need to change the VPN to not "always on", so the phone can exist on my normal WiFi, connect to SyncThing peers, and upload photos.


## Future Work

I'd like to experiment with an [SSTP](https://en.wikipedia.org/wiki/Secure_Socket_Tunneling_Protocol) based VPN as well.
However, for that to work I need a ready supply of certificates.
And updating certificates on Mikrotik devices using LetsEncrypt is a little too complex for me right now.

I'd also like to get IPv6 working.
Partly because it seems to be 90% working, but mostly because I like the new and shiny, 


## Other Guides

Other guides for configuring a Mikrotik VPN include:

* https://manuth.life/l2tpipsec-vpn-server-mikrotik-routeros/
* https://saputra.org/threads/setup-mikrotik-as-l2tp-ipsec-vpn-server.31/

## Conclusion

You can create your own VPN on your Mikrotik router to access your home network from anywhere in the world.
Windows and Android have a built in L2TP + IPSec VPN provider which works out of the box.

This also lets you bounce all your traffic off your home IP address and hide any activity from your mobile provider (although, such activity is still visible to your ISP).

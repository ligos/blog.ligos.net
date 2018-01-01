---
title: Mikrotik WiFi Access Point with VLAN
date: 2018-01-01
updated: 
tags:
- Mikrotik
- Access Point
- Router
- VLAN
- WiFi
- Network
- Isolated
categories: Technical
---

Install a separate access point with isolated networks.

<!-- more --> 

## Background

Several years ago (2014), I got on the [Mikrotik](https://www.mikrotik.com/) bandwagon via an RB2011 series router.
Specifically, the [RB2011UiAS-2HnD-IN](https://mikrotik.com/product/RB2011UiAS-2HnD-IN) - which has 5 gigabit ethernet ports, 5 fast ethernet ports, and 2 channel 2.4GHz WiFi.

At the time, I had exactly one device which was 5GHz WiFi capable, so the lack of [5GHz 802.11ac](https://en.wikipedia.org/wiki/IEEE_802.11#802.11ac) support wasn't a problem.
Fast forward to 2017 and 5GHz support on client devices like phones and laptops is pervasive (every new device we acquired in 2017 supported 5GHz 802.11ac).
Even more pointed is that my wife's Acer Spin 15 has no wired ethernet port at all; it's WiFi all the way (or a USB ethernet adapter), so having a 5GHz access point is now quite desirable.

So, when my parents asked me what they could buy me for Christmas, I asked for a [Mikrotik wAP ac](https://mikrotik.com/product/RBwAPG-5HacT2HnD).
This is a WiFi access point with single gigabit ethernet port, 2 channel 2.4GHz and 3 channel 5GHz WiFi.
Many thanks to them!


## Goal

Installing an access point is usually nothing complicated.
But I run a total of 4 virtual WiFi access points, for various isolated networks.

To keep this isolation happening, we need to use VLANs to create... well... virtual LANs for my virtual access point.
So the goal of this exercise is to install and configure my shiny new wAP access point, and keep my 4 separate WiFi networks isolated.

Side note: [last time I tried to make VLANs work I failed miserably](/2016-07-28/How-To-Make-An-Isolated-Network.html). 
So no pressure or anything.



### 0. Unbox and basic config

Basic stuff first.
Unbox the wAP and plug it in to configure core LAN settings.

The wAP is powered via [power over ethernet](https://en.wikipedia.org/wiki/Power_over_Ethernet), delivered by a magic injector plus plug pack.
Which means I don't need a power point near the access point itself, only near my router. 
Nice!

I configured a static IPv4 address and set DNS and the default route to my router.
Then, got the access point to check for updates (confirming its network configuration is good) and installed said update.

Finally, I changed the default access points to `grant-new24` and `grant-new5`, and gave them both a password - in preparation for some later tests.


### 1. Physical Installation

Once I confirmed I can use WinBox to access the device, it's time for physical installation.
Mostly, this involves me drilling holes in my ceiling and cornice, and pulling ethernet cable through my ceiling cavity. 
Not particularly fun in my book.
But only needs to be done once.

The access point has various mounting options from a desktop stand to wall mount to mast mount.
I used double sided tape to attach to the wall and installed it up-side-down.
And I think the end result is pretty discrete.
It's also installed in a more central location than the RB2011, which is located at the far end of our living room.
(See below for a map).

<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/physical-no-ap.jpg" class="" width=300 height=300 alt="Cable without access point" />
<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/physical-ap1.jpg" class="" width=300 height=300 alt="Installed access point" />
<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/physical-ap2.jpg" class="" width=300 height=300 alt="Access point from another angle" />


### 2. Test AP range

At this point, I'm ready to configure the access point for real use.
But there's a question bugging me: which networks should be hosted on which devices?

That is, I have two 2.4GHz radios on two devices (each of which can occupy 2 usable channels out of a possible 3) and four networks I'd like to run.
Which combination will work the best?

The 5GHz situation is less complex as I only have a single 5GHz radio. 
But it does remain: should all networks run on 5GHz, or just some?

An important piece of theory at this point: WiFi uses a *shared medium* to send and receive data called the "radio spectrum" (aka "the air").
I've highlighted the key words *shared medium* because it means only one device can send to one other device at any given time.
If two devices attempt to send at the same time, their packets literally colide in mid-air (well, OK, they collide the in receivers radio circitry) and must be re-sent.
Also, it's half-duplex, which means you can't send and receive at the same time: one device sends while another receives, then the roles are reversed.
It's like [10BASE2 ethernet](https://en.wikipedia.org/wiki/10BASE2) using the old coax cable which I remember from the mid and late 1990's at LAN parties - there is only one wire shared between all devices so only one device can send at any one time.

This means to get the best out of WiFi, you should run separate networks on separate radios and separate frequencies (which is kind of like running separate wires for separate networks).
[An article on Ars Technica goes over this in great detail](https://arstechnica.com/information-technology/2017/03/802-eleventy-what-a-deep-dive-into-why-wi-fi-kind-of-sucks/).

(As a side note, Gigabit ethernet does not suffer from this problem because of high performance network switches which magically make sure packets going to and from each device never collide).


Anyway, back to my problem at hand: which networks, which devices, which channels?
Oh, and one other: should a create different SSIDs for the 2.4GHz and 5GHz networks, or just let my devices roam between them as they see fit?

I decided to create some heat maps of signal strength for my old access point and new, to see if that would help answer these questions.
(I usually use [Nirsoft WiFi Information View](http://www.nirsoft.net/utils/wifi_information_view.html) on Windows for pretty low level details of access points, but it doesn't do heatmaps. So I creating the heat maps using my Nexus 5X using the  
[Wifi Heat Map - Survey](https://play.google.com/store/apps/details?id=info.wifianalyzer.heatmap) app).

I live in a townhouse, which is a single storey dwelling that shares a wall with a neighbour (with 6 dwellings on our common property).
The interior of our unit is in the bottom left of the heatmaps, around two thirds of the area is outdoors.
It's pretty small, as far as WiFi coverage goes.
And Mikrotik devices are rather overpowered for my dwelling.

(By "overpowered" I mean my neighbour in unit 3 says the RB2011 has stronger signal strength than his home router; and mine has to penetrate 2 double brick walls and ~20m of space)!

(By "overpowered" I mean the RB2011 is visible to my phone around 50m away down my street on the [Wigle Wardriving](https://www.wigle.net/) app)!

<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/heatmap-rb2011-24ghz.png" class="" width=300 height=300 alt="RB2011 2.4GHz Heatmap - Access Point in Purple" />
<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/heatmap-wap-24ghz.png" class="" width=300 height=300 alt="wAP 2.4GHz Heatmap - Access Point in Blue" />
<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/heatmap-wap-5ghz.png" class="" width=300 height=300 alt="wAP 5Hz Heatmap - Access Point in Blue" />

Well, the amount of green wasn't very surprising!

The main thing I learned from that exercise was that the 5GHz network has shorter range, so phones need to have a 2.4GHz option.

In the end, I decided on the following 2.4GHz configuration, using the same SSIDs for 2.4 & 5GHz:

| Network  | 2.4/5GHz | Channels     | RB2011/wAP |
|----------|----------|--------------|------------|
| Main LAN | 2.4 & 5  | 6-13, 98-114 | wAP        |
| Phones   | 2.4 & 5  | 6-13, 98-114 | wAP        |
| Kids     | 2.4      | 1-3          | RB2011     |
| Guest    | 2.4      | 1-3          | RB2011     |

My general hope is this will use spectrum as widely as possible (eg: phones and kids are not on overlapping channels, and laptops on the main LAN will favour 5GHz).
It also has a nice benefit that I can disable the kids network without affecting the adults' phones or laptops!

So far (after a week of use), my devices have roamed pretty intelligently between 2.4 and 5GHz, depending on signal strength and proximity to access point.


### 3. Virtual Access Points and VLANs

OK, now the radios are configured on the access point, it's time to replicate the network level isolation of my previous setup.
Previously I had one device, several virtual access points and a separate network for each AP.
With my new access point, I'd like the router to handle as much of the configurations possible (eg: firewall, DHCP, etc), and the access point to well... just be an access point (with just the SSID and WPA2 passwords).
That is, 90% of the configuration is in the router, but the networks remain separate and isolated (except as allowed by the router's firewall).

Which means I must conquer my fear of [VLANs](https://wiki.mikrotik.com/wiki/Manual:Interface/VLAN).

In my head, the way Mikrotik does VLANs is like so:

* Create VLAN interfaces as children of the ethernet port, I think of these as virtual ethernet wires.
* Create a bridge which connects the VLAN "wire" to other ports or interfaces (eg: WiFi access points), I think of these as like a network switch you plug the VLAN "wires" into.
* Finally, assign a IP address (and IPv6 address) to the bridge interface, and you can then do all the usual firewall and DHCP things. 

I have no idea if this is the "right" way to do things or not, but it does work (at least in my environment).

Also, this was all done with the 6.40 version of RouterOS.
6.41 has a [new bridge implementation](https://wiki.mikrotik.com/wiki/Manual:Interface/Bridge#Bridge_VLAN_Filtering), which seems to treat a bridge much more like a switch when working with VLANs.


**3a. Access Point Configuration**

On the access point, create the following:

* Create a *virtual access point interface* (simply called *virtual* in the New Interface drop down menu) with an appropriate SSID, WiFi channel and security profile. Do not assign it a VLAN ID. [Doco about Wireless Interfaces](https://wiki.mikrotik.com/wiki/Manual:Interface/Wireless). 
    * (You can also just use the main WiFi access point, rather than a virtual one. I have one real Wireless interface and one Virtual on my AP).
* Create a *VLAN interface* as a child of the ethernet port. Assign it a VLAN ID (which you'll use on the router to connect the virtual wires); I'm using 10 and 20. [Doco about VLAN Interfaces](https://wiki.mikrotik.com/wiki/Manual:Interface/VLAN). 
* Create a *bridge interface*. And assign the access point and VLAN interfaces to the bridge. This is done through the *Bridge* menu. [Doco about Bridge Interfaces](https://wiki.mikrotik.com/wiki/Manual:Interface/Bridge). 

Here's the configuration on my wAP:

```
[admin@WiFi-AP] /interface> print
Flags: D - dynamic, X - disabled, R - running, S - slave 
 #     NAME                                TYPE       ACTUAL-MTU L2MTU  MAX-L2MTU
 0  RS ether1-router                       ether            1500  1600       4076
 1   S wlan-5-main-lan                     wlan             1500  1600       2290
 2  RS wlan-5-phones                       wlan             1500  1600       2290
 3  RS wlan-24-main-lan                    wlan             1500  1600       2290
 4  RS wlan-24-phones                      wlan             1500  1600       2290
 5  R  bridge-main-lan                     bridge           1500  1596
 6  R  bridge-phones                       bridge           1500  1596
 7  RS vlan-wifi-main-lan                  vlan             1500  1596
 8  RS vlan-wifi-phones                    vlan             1500  1596

[admin@WiFi-AP] /interface wireless> print
Flags: X - disabled, R - running 
 0    name="wlan-5-main-lan" mtu=1500 l2mtu=1600 mac-address=64:D1:54:BC:E5:1D 
      arp=enabled interface-type=Atheros AR9888 mode=ap-bridge 
      ssid="MainLAN" frequency=5500 band=5ghz-a/n/ac 
      channel-width=20/40/80mhz-Ceee scan-list=default wireless-protocol=802.11 
      vlan-mode=no-tag vlan-id=1 wds-mode=disabled wds-default-bridge=none 
      wds-ignore-ssid=no bridge-mode=enabled default-authentication=yes 
      default-forwarding=yes default-ap-tx-limit=0 default-client-tx-limit=0 
      hide-ssid=no security-profile=wifi-main-lan compression=no 

 1  R name="wlan-5-phones" mtu=1500 l2mtu=1600 mac-address=66:D1:54:BC:E5:1D 
      arp=enabled interface-type=virtual master-interface=wlan-5-main-lan 
      mode=ap-bridge ssid="Phones" vlan-mode=no-tag vlan-id=1 
      wds-mode=disabled wds-default-bridge=none wds-ignore-ssid=no 
      bridge-mode=enabled default-authentication=yes default-forwarding=yes 
      default-ap-tx-limit=0 default-client-tx-limit=0 hide-ssid=no 
      security-profile=wifi-phones 

 2  R name="wlan-24-main-lan" mtu=1500 l2mtu=1600 mac-address=64:D1:54:BC:E5:1E 
      arp=enabled interface-type=Atheros AR9300 mode=ap-bridge 
      ssid="MainLAN" frequency=2437 band=2ghz-b/g/n 
      channel-width=20/40mhz-Ce scan-list=default wireless-protocol=802.11 
      vlan-mode=no-tag vlan-id=1 wds-mode=disabled wds-default-bridge=none 
      wds-ignore-ssid=no bridge-mode=enabled default-authentication=yes 
      default-forwarding=yes default-ap-tx-limit=0 default-client-tx-limit=0 
      hide-ssid=no security-profile=wifi-main-lan compression=no 

 3  R name="wlan-24-phones" mtu=1500 l2mtu=1600 mac-address=66:D1:54:BC:E5:1E 
      arp=enabled interface-type=virtual master-interface=wlan-24-main-lan 
      mode=ap-bridge ssid="Phones" vlan-mode=no-tag vlan-id=1 
      wds-mode=disabled wds-default-bridge=none wds-ignore-ssid=no 
      bridge-mode=enabled default-authentication=yes default-forwarding=yes 
      default-ap-tx-limit=0 default-client-tx-limit=0 hide-ssid=no 
      security-profile=wifi-phones 

[admin@WiFi-AP] /interface vlan> print
Flags: X - disabled, R - running, S - slave 
 #    NAME                    MTU ARP             VLAN-ID INTERFACE                
 0 R  vlan-wifi-main-lan     1500 enabled              10 ether1-router            
 1 R  vlan-wifi-phones       1500 enabled              20 ether1-router            

[admin@WiFi-AP] /interface bridge> print
Flags: X - disabled, R - running 
 0  R name="bridge-main-lan" mtu=auto actual-mtu=1500 l2mtu=1596 arp=enabled 
      arp-timeout=auto mac-address=64:D1:54:BC:E5:1E protocol-mode=rstp 
      fast-forward=yes priority=0x8000 auto-mac=yes admin-mac=00:00:00:00:00:00 
      max-message-age=20s forward-delay=15s transmit-hold-count=6 ageing-time=5m 

 1  R name="bridge-phones" mtu=auto actual-mtu=1500 l2mtu=1596 arp=enabled 
      arp-timeout=auto mac-address=64:D1:54:BC:E5:1C protocol-mode=rstp 
      fast-forward=yes priority=0x8000 auto-mac=yes admin-mac=00:00:00:00:00:00 
      max-message-age=20s forward-delay=15s transmit-hold-count=6 ageing-time=5m 

[admin@WiFi-AP] /interface bridge port> print
Flags: X - disabled, I - inactive, D - dynamic 
 #    INTERFACE                BRIDGE                PRIORITY  PATH-COST    HORIZON
 0    wlan-24-main-lan         bridge-main-lan           0x80         10       none
 1 I  wlan-5-main-lan          bridge-main-lan           0x80         10       none
 2    vlan-wifi-main-lan       bridge-main-lan           0x80         10       none
 3    ether1-router            bridge-main-lan           0x80         10       none
 4    vlan-wifi-phones         bridge-phones             0x80         10       none
 5    wlan-5-phones            bridge-phones             0x80         10       none
 6    wlan-24-phones           bridge-phones             0x80         10       none
```

<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/wap-config-interfaces.png" class="" width=300 height=300 alt="Access Point Interface Configuration" />
<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/wap-config-bridge.png" class="" width=300 height=300 alt="Access Point Bridge Configuration" />


**3b. Router Configuration**

On the router, we'll replicate similar VLANs and bridges, and then do the IP level config:

* Create VLANs as child interfaces of the ethernet port your access point is connected to. Use the same VLAN ids as on the access point.
    * If you want one of those VLANs to be part of your main LAN, add it to your LAN bridge.
    * Otherwise, simply leave the VLAN interface as is.
* Assign IP addresses to the VLAN interfaces (*IP -> Address*).
    * This assumes your main LAN bridge interface already has an IP address.
* Configure DCHP against the VLAN interfaces (*IP -> Pool* and *IP -> DHCP Server*).
    * Again, this assumes your main LAN bridge interface already has DHCP running on it.
* Configure IPv6 addresses for the VLAN interface (*IPv6 -> Pool* and *IPv6 -> Address*).
* Reconfigure your firewall to block / allow access as desired.
    * I've got rules to deny access to my main LAN from other networks (eg: kids, guest, phones), unless there are explicit rules allowing access.

In general, once you have your VLAN interfaces created and bridged as required, you should configure IP and DHCP the same as any additional network.
Thus all DCHP, DNS, firewall, etc configuration is on the router alone.

Here's the relevant parts of my router config for the main LAN and phones networks, which are now hosted on my wAP device:

```
[admin@Mikrotik-gateway] /interface> print
Flags: D - dynamic, X - disabled, R - running, S - slave 
 #     NAME                                TYPE       ACTUAL-MTU L2MTU  MAX-L2MTU
 1  RS ether2-wifi                         ether            1500  1598       4074
 4  R  bridge-main-lan                     bridge           1500  1594
16  RS vlan-wifi-main-lan                  vlan             1500  1594
17  R  vlan-wifi-phones                    vlan             1500  1594

[admin@Mikrotik-gateway] /interface vlan> print
Flags: X - disabled, R - running, S - slave 
 #    NAME                   MTU ARP             VLAN-ID INTERFACE               
 0 R  vlan-wifi-main-lan    1500 enabled              10 ether2-wifi             
 1 R  vlan-wifi-phones      1500 enabled              20 ether2-wifi             

[admin@Mikrotik-gateway] /interface bridge> print
Flags: X - disabled, R - running 
 1  R name="bridge-main-lan" mtu=1500 actual-mtu=1500 l2mtu=1594 arp=enabled 
      arp-timeout=auto mac-address=4C:5E:0C:B8:D8:C6 protocol-mode=rstp 
      fast-forward=no priority=0x8000 auto-mac=no admin-mac=4C:5E:0C:B8:D8:C6 
      max-message-age=20s forward-delay=15s transmit-hold-count=6 
      ageing-time=5m 

[admin@Mikrotik-gateway] /interface bridge port> print
Flags: X - disabled, I - inactive, D - dynamic 
 #    INTERFACE               BRIDGE               PRIORITY  PATH-COST    HORIZON
 0    ether2-wifi             bridge-main-lan          0x80         10       none
 1    ether3-loki             bridge-main-lan          0x80         10       none
 2    ether4-garage           bridge-main-lan          0x80         10       none
 3    ether6-printer          bridge-main-lan          0x80         10       none
 6  D ether7-modem            bridge-main-lan          0x80         10       none
 9    vlan-wifi-main-lan      bridge-main-lan          0x80         10       none

[admin@Mikrotik-gateway] /ip address> print
Flags: X - disabled, I - invalid, D - dynamic 
 #   ADDRESS            NETWORK         INTERFACE                                
 2   ;;; Phone WiFi
     10.46.2.1/24       10.46.2.0       vlan-wifi-phones                         
 3   ;;; Main LAN
     10.46.1.1/24       10.46.1.0       bridge-main-lan                          
 5 D 150.101.201.180/32 150.101.32.108  pppoe-internode                          

[admin@Mikrotik-gateway] /ip pool> print
 # NAME                                                          RANGES                         
 2 dhcp-phones                                                   10.46.2.100-10.46.2.200        
 3 dhcp-lan                                                      10.46.1.100-10.46.1.200

[admin@Mikrotik-gateway] /ip dhcp-server> print
Flags: X - disabled, I - invalid 
 #   NAME            INTERFACE          RELAY           ADDRESS-POOL          LEASE-TIME ADD-ARP
 0   default         bridge-main-lan                    dhcp-lan              1d        
 3   wlan-phones     vlan-wifi-phones                   dhcp-phones           1d        
```

<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/router-config-interfaces.png" class="" width=300 height=300 alt="Router Interface Configuration" />
<img src="/images/Mikrotik-WiFi-Access-Point-With-VLAN/router-config-bridge.png" class="" width=300 height=300 alt="Router Bridge Configuration" />



**3c. Router Configuration for Guest Network**

I have my guest WiFi network running off my router, but am also including an ethernet port as part of that guest network.
So, I have created a separate guest bridge, which includes the guest WiFi interface and guest ethernet port.
No VLANs involved here, just bridging ports to a separate network.

```
[admin@Mikrotik-gateway] /interface> print
Flags: D - dynamic, X - disabled, R - running, S - slave 
 #     NAME                                TYPE       ACTUAL-MTU L2MTU  MAX-L2MTU
 9   S ether10-guest                       ether            1500  1598       2028
11   S wlan-guest                          wlan             1500  1600       2290
13  R  bridge-guest                        bridge           1500  1598

[admin@Mikrotik-gateway] /interface bridge> print
Flags: X - disabled, R - running 
 0  R name="bridge-guest" mtu=auto actual-mtu=1500 l2mtu=1598 arp=enabled 
      arp-timeout=auto mac-address=4E:5E:0C:B8:D8:CF protocol-mode=rstp 
      fast-forward=yes priority=0x8000 auto-mac=yes admin-mac=00:00:00:00:00:00 
      max-message-age=20s forward-delay=15s transmit-hold-count=6 
      ageing-time=5m 

[admin@Mikrotik-gateway] /interface bridge port> print
Flags: X - disabled, I - inactive, D - dynamic 
 #    INTERFACE               BRIDGE               PRIORITY  PATH-COST    HORIZON
10 I  wlan-guest              bridge-guest             0x80         10       none
11 I  ether10-guest           bridge-guest             0x80         10       none

[admin@Mikrotik-gateway] /ip address> print
 #   ADDRESS            NETWORK         
 0   ;;; Guest WiFi
     10.46.129.1/24     10.46.129.0     

[admin@Mikrotik-gateway] /ip pool> print
 # NAME                       RANGES                         
 0 dhcp-guest                 10.46.129.64-10.46.129.250     
 
[admin@Mikrotik-gateway] /ip dhcp-server> print
Flags: X - disabled, I - invalid 
 #   NAME            INTERFACE          RELAY           ADDRESS-POOL       
 1   wlan-guest      bridge-guest                       dhcp-guest         
```


## Conclusion

Using VLANs and bridges on Mikrotik devices allows you to add a new physical access point to your network.
From there you can transparently add new WiFi networks either to your main LAN or to separate isolated networks.
And then it's just a matter of firewall rules to allow or deny access between the networks.

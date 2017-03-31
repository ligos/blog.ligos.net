---
title: Use a Mikrotik as Your Home Router
date: 2017-02-16
updated: 2017-04-01
tags:
- Mikrotik
- Router
- Home Router
- Gateway
- How-To
- Step-By-Step
categories: Technical
---

For extra geek status, and a superior router.

<!-- more --> 

## Background

I've been using a Mikrotik router ([RB2011UiAS-2HnD-IN](https://routerboard.com/RB2011UiAS-2HnD-IN)) for several years.

Mostly, it was a reaction to my negative experience with home grade routers.

There were three main criteria in my purchase:

* Must have regular security updates 
* Must have wired and WiFi connectivity
* Must be reliable

I have not been disappointed!

But it was definitely not a simple process to get the Mikrotik up and going.
Hence, I want to share how to convert to Mikrotik.

## Goal

To configure, from scratch, a Mikrotik router (such as the [RB2011UiAS](https://routerboard.com/RB2011UiAS-2HnD-IN) or [hAP](https://routerboard.com/RB962UiGS-5HacT2HnT)) as a home router.
The following core functionality will be shown in detail:

* Configure your old ADSL router to bridge mode
* RouterOS and Firmware updates
* Local IP address
* DHCP
* Internet access
* Firewall
* IPv6
* DNS
* WiFi

I'll list some other features at the end, but the above is enough to get you off the ground.

Mikrotik have a rather limited selection of routers with integrated WiFi.
It is actually very common in commercial grade gear to have a separate router and access point.
Going down this road with Mikrotik is possible (eg: [hEX](https://routerboard.com/RB750Gr3) plus [BaseBox](https://routerboard.com/RB912UAG-5HPnD-OUT) or [wAP](https://routerboard.com/RBwAPG-5HacT2HnD)), but a bit too complex for this article.

## Important Note

I am writing this article referencing my router (connected to the Internet) and a spare (courtesy of my work, [Far Edge Technology](http://faredge.com.au)).
So, screenshots might not be 100% consistent and I may have missed some things.

Please let me know if I get anything wrong.

## Core Configuration

The main thing to remember with a Mikrotik is that all your configuration is more verbose.
For example, a regular home router may configure LAN settings as `IP Address`, `Netmask`, `DHCP ON / OFF` and `DHCP Range`.
Mikrotik splits these across `Addresses` (3 fields per address (no limit to addresses)), `Pools` (3 fields per pool), and `DHCP Server` (3 tabs, ~10 fields in total).

(As a side effect of using a Mikrotik router, your networking skills and knowledge are likely to increase)!

** IMPORTANT WARNING **

You will not have Internet connectivity in steps 1 to 3.

Please make a note of any passwords you need to connect to the Internet, ensure you have new connection details from your ISP handy, and have a mobile phone ready in case you to ask the Internet for help.
It's probably worth having your ISP's support number handy.
Indeed, if you're really paranoid, give them a call before hand and ask if there's anything special you should know (and to double check you have the right phone number).

** END IMPORTANT WARNING **

Lets get started.

### 0. Grab a Backup of Your Old Router

Seriously. 
Do it now.

Save it on your laptop.
And make a second copy on a USB or desktop or phone.

If things go really bad, you can always restore your backup and be no worse off.


### 1. Make You Old Router Into a Modem

This article assumes you have an ADSL connection.
Essentially, we will change your old router to just be an ADSL modem using what is called **bridge mode**.

Connect to your old router and search through the configuration.
Turn off WiFi. 
Turn off DHCP.
Set your LAN IP address to `192.168.88.2` (such that your modem remains accessible; your Mikrotik will be `192.168.88.1`).
Once you change your LAN IP address, your router will likely reboot.

If you have added any port forwarding, now is a good time to make a note of it.

In your Internet connection settings, look for an option called **bridge mode** and enable it.
It should clear all your connection settings (usernames, passwords, IP addresses, etc).
It will tell your old router to act like a modem and simply pipe raw network traffic through to your new Mikrotik router.
All your old router will do is establish ADSL line sync, but it won't be able to access the Internet directly.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/billion-bridge-mode.png" class="" width=300 height=300 alt="My old Billion router calls it 'Pure bridge'" />

Cable, fibre, wireless, ethernet, satellite or more exotic connections will have some differences at this point.
Eg: Cable users may already have a separate cable modem, they just need to disconnect their old router.

Things to watch out for:

* **VPI / VCI settings**: I have needed to make slight changes to these in some ADSL modems in bridge mode. Your ISP's configuration page should tell you what they need to be set to.
* **MAC Address**: some ISPs (particularly cable providers) require a certain MAC address on your router. If you called support they should have told you this, otherwise, the Mikrotik has an option for you to enter a MAC address.

(I've never used a fibre, ethernet or wireless ISP in the past, so I don't know what their particular gotchas are).


### 2. Unboxing a Mikrotik

Mikrotik hardware comes with the bare minimum.
The device, a power pack, and a piece of paper with very basic getting started instructions.

#### 2a - Power it up and login

Plug it into power, and you should hear some beeps as it boots up.

Connect port 1 of the Mikrotik to a LAN port on your old router.
This will be your Internet connection.

Connect your computer to another port on the Mikrotik (port 2 sounds good).

Your computer should be assigned an IP address in the `192.168.88.x` range.
And you can browse to the [admin login of your new Mikrotik router](http://192.168.88.1).


#### 2b - Download Winbox

If you have a Windows computer, there is a link at the bottom of the admin login page to download Winbox.
You should download it and use Winbox instead of the web interface.

Why use Winbox over a browser?

* Winbox can auto discover Mikrotik devices on your LAN
* Winbox can connect via IPv6 or MAC address (making it easier to change IPv4 addresses)
* Winbox shows statistics, packet flow and graphs in real time (in fairness, the web interface does this too)
* Winbox lets you have multiple windows for different parts of your configuration (yes, I know that web browsers have tabs too)
* Winbox lets you do drag & drop file transfers (good for manual updates)
* Winbox remembers a list of connections and passwords

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/winbox.png" class="" width=300 height=300 alt="Download Winbox today!" />

If you don't have a Windows device handy, the web interface is more than enough to get going, if slightly less polished.

#### 2c - Login

Either use Winbox or your browser to login to `192.168.88.1`.
The default username is `admin`, without any password.


### 3. Quick Set

When you first connect with Winbox to your router, you will receive a new setting notification.
If you understand what it says, that's great.
If not, don't worry.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/routeros-default-configuration-message.png" class="" width=300 height=300 alt="Welcome to your new Mikrotik Router" />

There are a list of menu items down the left side of the screen.
The very top one should be *Quick Set*.
Click it, and you'll get Mikrotik's *simplified setup*.
Which, for a home router / access point, is 80% of what you need.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-default.png" class="" width=300 height=300 alt="Wizard Configuration!" />

We'll tour through all the parts of this screen so you're all setup and on the Internet.
After each section, you should click *Apply* to save your changes.


#### 3a - Local Network

Although our priority is to get on the Internet, we need to check our LAN settings first.
If you change these later it causes much pain, so best do it up front.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-local-network.png" class="" width=300 height=300 alt="Local Network Settings" />

If you want to change your LAN subnet, **IP Address** is the place to do it (perhaps if you have some existing devices with static addresses).
Most home users can just use the `192.168.88.x` range without a problem.
(If you change the IP address of the router, you'll need to re-connect using your new IP address).

If you need extra static addresses, you can change the **DHCP Server Range**.
The default of 10 non-DHCP addresses is fine (minus one for your Mikrotik router and one for your old router), unless you have lots of servers.

Keep **NAT** ticked.
It's the thing that lets your devices access the Internet!

Tick **UPnP** (more info about [universal plug and play](https://en.wikipedia.org/wiki/Universal_Plug_and_Play)).
This allows network services to automatically open ports such that external users can connect.
There is a security risk for this, but it's usually enabled on home routers, and it makes things like [bittorrent](https://en.wikipedia.org/wiki/BitTorrent) and [skype](https://en.wikipedia.org/wiki/Skype) much happier.

If there's an option to **Bridge all LAN Ports**, it should be unticked.
All bar one of your LAN ports will be bridged.
Port 1, your Internet port, is the exception.
And it's a very, very important exception!


#### 3b - System Password

Before you go trying to connect your brand new router to the Internet, make sure it has a password!
Enter it twice.

Then disconnect and check your new password is required.

We'll get to checking for updates once the Internet works.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-system.png" class="" width=300 height=300 alt="Yes, you really do need a password" />

#### 3c - Wireless

Your WiFi is currently configured as open access, no password required.
Again, before we hop on the Internet, we need to add a password, and set a few other options.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-wireless.png" class="" width=300 height=300 alt="WiFi configuration" />

**Network Name** is the... err... name of the network you see on your phone / laptop when connecting.
You can change it to reflect your old router, or think up something new, or just keep the default.
Go crazy.

**Frequency** is what most home routers call *channels*.
Mikrotik shows the actual radio frequency of each WiFi channel.
You'll need to count from one to work out which MHz corresponds to which channel.

**Band** lets you enable / disable 2 GHz or 5 GHz, and the various WiFi protocols.
The default is fine.

**Country** should be set correctly so your router follows any local laws regarding use of channels.
Mikrotik routers sold in America have this set in hardware, apparently.

**WiFi Password** is where you enter your WiFi password.
8 to 63 characters (and yes, my WiFi password really is 63 characters long).


#### 3d - Internet

OK, with our LAN configured and passwords enabled, time to connect to the Internet!
This is where you should refer to your ISP's initial setup details, or call tech support if you get stuck.

Before we start with this, make sure the **Firewall Router** option is ticked.
That stops nasty people connecting to your router from the big bad Internet.

**Configuration**

Most ADSL services use [PPPoE](https://en.wikipedia.org/wiki/Point-to-point_protocol_over_Ethernet) to establish an Internet connection.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-internet-pppoe.png" class="" width=300 height=300 alt="PPPoE Connection" />

Enter your **PPPoE User** (which may be just a username, or your ISP email address) and **Password**.
The **Service Name** is optional, [my ISP](https://internode.on.net) does not require it; check with your ISP.

Click *Apply* and you should see *PPPoE Status* change to `connected`.

And you're on the Internet again!


**Other Configurations**

Depending on your ISP, you may need to use an **Automatic** connection (which just gets an Internet address via DHCP, no username or password required). 
Or you may have a **Static** address (pretty unlikely for a residential connection), in which case you'll enter details as provided by your ISP.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-internet-static.png" class="" width=300 height=300 alt="Static IP Connection" />

**Access Your Modem**

To access your modem via your browser, you'll need to connect it with another ethernet cable.
Simply connect an extra ethernet port from your Mikrotik to your old router.
Then you can browse to `192.168.88.2`, as you configured it in step 1.

(I'm sure there is a way to do this [without the extra cable](https://mybroadband.co.za/vb/showthread.php/409681-How-to-access-ADSL-Modem-on-Mikrotik-Ether1-Gateway), but I've tried several times and never managed to get it working).



#### 3e - Updates

Now you're back on the Internet, resist the urge to check Facebook, Twitter or download cat videos!

Instead, click the **Check for Updates** button.
There almost certainly will be updates.
Go install them and reboot your router.

(The reboot command is *System -> Reboot*, on the left menu.)

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-system.png" class="" width=300 height=300 alt="Updates" />

Regular updates is a major feature of Mikrotik over any home router.
They actually fix bugs, problems and security holes.
And deliver new features!

Crazy talk, I know.


#### 3f - Guest Wireless (optional)

If you want to configure a guest WiFi access point, you can do that.

However, all this does is create a second virtual access point with a different password.
Guests are still part of your main LAN network and can access other computers and devices on it.

It would be nice if this created a second isolated subnet to keep guests away from your main network, but alas it does not.


#### 3g - VPN (optional)

If you want to be able to connect to your home network from the road (via mobile data, work, someone else's house, when travelling, etc), you can enable a [Virtual Private Network](https://en.wikipedia.org/wiki/Virtual_private_network).

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/quickset-vpn.png" class="" width=300 height=300 alt="Updates" />

All you need to do is add a **VPN Password** (please make it better than this example).

This supports [PPTP](https://en.wikipedia.org/wiki/Point-to-Point_Tunneling_Protocol), [L2TP](https://en.wikipedia.org/wiki/Layer_2_Tunneling_Protocol) and [SSTP](https://en.wikipedia.org/wiki/Secure_Socket_Tunneling_Protocol) based VPNs.
At least one of which should work with most devices and computers out there.

And you connect using the address shown above (free dynamic DNS).

But be aware that *PPTP* is fundamentally flawed and not supported on modern devices (from 2016, iOS and Android refuse to connect to them).

(Note, I don't have this kind of VPN configured on my router, so my experience is rather limited).


### 4. Other Features

Lets venture out of the *Quick Set* menu to see other features.
Generally, clicking through the menus on the left is pretty harmless, as long as you don't change things.
And the defaults from *Quick Set* are a good template to start from (so you can see how all the pieces fit together).


**Interfaces**

This is a very good default screen to look at to get an overall picture of what's going on.
It shows network usage in real time (updating every second or so) for each physical or logical interface in your router.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/interfaces.png" class="" width=300 height=300 alt="Interfaces on my router" />

There isn't much to see on a router with no devices, so the screenshot is from my router. 
Two highlights from this moment in time: something is downloading at 2.1Mbps over my [ISP's](https://internode.on.net) PPPoE connection, and something on WiFi is receiving at 17Mbps from my [home server](https://loki.ligos.net).

Drilling into an interface gives more configuration details, statistics and the very powerful torch function.
You can use torch to [work out exactly what device is consuming bandwidth](/2016-04-24/Who-Or-What-Is-Using-My-Bandwidth.html) (and when you have a rather poor ADSL connection like me, that is very useful to know).


**Wireless**

Drilling into Wireless will show you any number of options and settings for your Router's [WiFi interface(s)](http://wiki.mikrotik.com/wiki/Manual:Interface/Wireless).
I won't go into details here; reading the Mikrotik documentation and Wikipedia is a good way to work out what it all means.

One highlight is that you can see the signal strength of connected devices in real time (also visible on *Quick Set*).
This shows the signal strength of the device as seen by **your router**, also known as the *return signal*.
The signal strength bars on your phone, laptop or device only shows the strength of the router's signal, but phones are much lower powered and have poorer antennas than your router does, so the signal the router sees is often the weakest link.


**IP -> Addresses**

This is where you add [IP addresses](http://wiki.mikrotik.com/wiki/Manual:IP/Address) for your router.
Typically, this is where you change your LAN address, but you should see your public IP address in here as well.


**IP -> Pools**

[Pools](http://wiki.mikrotik.com/wiki/Manual:IP/Pools) are where ranges of IP addresses are defined, which are most commonly used in DHCP configuration.

**IP -> DHCP**

As I alluded to near the beginning, [DHCP configuration](http://wiki.mikrotik.com/wiki/Manual:IP/DHCP_Server) is more complex in a Mikrotik, as compared to home routers.
Looking at the default configuration will help you make sense of it.

*Leases* shows the devices currently assigned IP addresses from your router.

If you want to assign your devices a fixed IP address via DHCP, you can do that on the *Leases* tab.
Either wait until a device connects, drill into it and click *Make Static*.
Or you can create a new lease and manually enter the MAC address.

If you want to create a separate subnet and a whole new DHCP scope, you need to make changes in the *DHCP* and *Networks* tabs.
Following the default config helped me greatly when starting out here.


**IP -> DNS**

Mikrotik routers run a small [DNS server](http://wiki.mikrotik.com/wiki/Manual:IP/DNS).
Mostly this just caches DNS queries so they are a bit faster for your local devices.

Two highlights: 
you can clear the DNS cache if you need to start fresh (note that this does not clear your ISP's DNS cache),
and you can add static DNS names for local devices (eg: `my-server.ligos.local`).


**IP -> Services**

Mikrotik routers run various [network services](http://wiki.mikrotik.com/wiki/Manual:IP/Services).
If you aren't using them, its best to turn them off so nasty hackers have less options to break into your device.

You can safely turn off:

* api
* api-ssl
* ftp
* telnet

**System -> Packages**

A Mikrotik router is made up of a large core package with most functionality, and several smaller packages which add extra features.
The [packages](http://wiki.mikrotik.com/wiki/Manual:System/Packages) screen shows what is currently installed.

This is also where you can *Check for Updates* from the Internet and view release notes of newer packages.

Note: other manufacturers allow 3rd parties to develop and distribute packages or add-ons for their routers or NAS devices.
This is not the case with Mikrotik.
All packages are exclusively developed and distributed by Mikrotik, and are available through their [download page](http://www.mikrotik.com/download).


**Bridge**

Your WiFi and ethernet ports are not, by default, part of the same local network.
But usually you want them to be.
A network [bridge](http://wiki.mikrotik.com/wiki/Manual:Interface/Bridge) is how that happens.

Bridging networks means devices can discover each other automatically, and your Mikrotik will optimise for fastest possible performance.

In a default config *bridge* tab has a single bridge, and the *ports* tab will list each interface that is bridged.
This will be all your ethernet ports, except #1 (your internet link).

If you remove a port from the bridge, you can begin to [isolate it from your LAN](/2016-07-28/Create-Another-Network-On-A-Mikrotik.html).

(Other ways of linking ports together on a local network include a [hardware ethernet switch](http://wiki.mikrotik.com/wiki/Manual:Switch_Chip_Features) (ethernet ports only), and [routing](http://wiki.mikrotik.com/wiki/Manual:Routing)).


**Console**

Many articles on the Internet about Mikrotik routers will give their configuration as text commands for a console.
This is a very concise way to record configuration unambiguously.

You can generate or replay these commands in a *New Terminal* in winbox.
Most console areas have a `print` command, which lists information / configuration:

```
[admin@MikroTik] > interface 
[admin@MikroTik] /interface> print
Flags: D - dynamic, X - disabled, R - running, S - slave 
 #     NAME                                TYPE       ACTUAL-MTU L2MTU  MAX-L2MTU
 0     ether1                              ether            1500  1600       4076
 1  RS ether2-master                       ether            1500  1598       2028
 2   S ether3                              ether            1500  1598       2028
 3  RS ether4                              ether            1500  1598       2028
 4   S ether5                              ether            1500  1598       2028
 5   S wlan1                               wlan             1500  1600       2290
 6   S wlan2                               wlan             1500  1600       2290
 7  R  ;;; defconf
       bridge                              bridge           1500  1598
 8  X  pppoe-out1                          pppoe-out 
[admin@MikroTik] /interface> 
```


### 5. Firewall

The firewall is the core business of any router.
And it's well worth [reading the documentation](http://wiki.mikrotik.com/wiki/Manual:IP/Firewall/Filter), as well as experimenting with various firewall rules (always being careful you don't end up locking yourself out of your own router, of course)!

But for now, let just make sure we have a safe default for home use.

The firewall is accessed in *IP -> Firewall -> Filter*.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/firewall-filter.png" class="" width=300 height=300 alt="Firewall" />

There are a list of default rules, created with *Quick Set*.
Which are a very good place to start.

(Something else worth doing is adding a comment after each rule, so make it easier to understand what's going on).


#### 5a - Drop All Rule

The last rule is the most important, it says we will deny access, by default.
So, unless another rule matches, the default is to block incoming connections.

#### 5b - ICMP "ping" Rule

Near the top is a rule to allow ICMP.

It is good practice to rate limit the number of ICMP packets, so nasty people don't overload your network.
You need to edit that rule and pop over to the *Extra* tab, and add a *limit* and a *dst. limit*.
30 packets each second is a reasonable place to start (not too big, not too small).

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/firewall-icmp-limit.png" class="" width=300 height=300 alt="Limit ICMP packets" />

#### 5c - Allow Rule for Local Network

Its good to explicitly allow connections to your router from your local network, to make sure you don't accidentally lock yourself out of your own router.

Add a rule for chain `input`, with `src-address=192.168.88.0/24`, and set the action to `accept`.
Then drag it up to near the top (after the ICMP rule is a good place).

#### 5d - Other Allow Rules

If you enabled VPN access, you may notice some other rules to allow your VPN to connect.

These are a good template if you want to allow other traffic.
But you more commonly will be port forwarding traffic to an internal device.
And you do not need an allow rule for port forwarded traffic (the very top rule allows port forwards).


#### 5e - Our Final Rules

Here's a dump of all our firewall rules.
Other than a few tweaks, the LAN access rule and some additional comments, they are the same as the default config.

```
[admin@MikroTik] /ip firewall filter> print
Flags: X - disabled, I - invalid, D - dynamic 
 0  D ;;; special dummy rule to show fasttrack counters
      chain=forward action=passthrough 

 1    ;;; defconf: fasttrack
      chain=forward action=fasttrack-connection 
      connection-state=established,related 

 2    ;;; defconf: accept established,related
      chain=forward action=accept connection-state=established,related 

 3    ;;; defconf: drop invalid
      chain=forward action=drop connection-state=invalid 

 4    ;;; defconf:  drop all from WAN not DSTNATed
      chain=forward action=drop connection-state=new 
      connection-nat-state=!dstnat in-interface=ether1 

 5    ;;; Allow ICMP (rate limited)
      chain=input action=accept protocol=icmp log=no log-prefix="" 

 6    ;;; Allow router access from LAN
      chain=input action=accept src-address=192.168.88.0/24 log=no 
      log-prefix="" 

 7    ;;; Allow established
      chain=input action=accept connection-state=established log=no 
      log-prefix="" 

 8    ;;; Allow related
      chain=input action=accept connection-state=related log=no log-prefix="" 

 9    ;;; allow l2tp
      chain=input action=accept protocol=udp dst-port=1701 

10    ;;; allow pptp
      chain=input action=accept protocol=tcp dst-port=1723 

11    ;;; allow sstp
      chain=input action=accept protocol=tcp dst-port=443 

12    ;;; Drop all external access
      chain=input action=drop in-interface=ether1 log=no log-prefix="" 

[admin@MikroTik] /ip firewall filter> 
```

#### 5f - Basic Firewall Concepts

This is a bit of conceptual information about the firewall.
You don't need to read or follow this unless you have a more complex network, or want to experiment further.

A firewall is a list of rules, each with a set of criteria (eg: port numbers, source or destination IP addresses, etc) and an action (eg: accept, drop, etc).
The rules are divided in *chains*, which are group of rules.
There are some core *chains* which have special meaning, but you can make your own if you you have sufficiently complex rules.

Every network packet passes from the top of the rules down to the bottom.
As soon as it matches any rule, it stops, applies the action for that rule, and exits the list.
So you tend to have more specific rules at the top, and then more general "catch-all" rules at the bottom.

I struggled to understand what a *chain* was, so I'll add a little more information.
There are three core *chains* (of which we're usually only interested in the first two):

1. **input** - traffic destined for the router itself
2. **forward** - traffic which crosses the router to other devices (usually to / from the Internet / your computer, depending on the src / dest addresses)
3. **output** - traffic from the router itself

There are many other rules you can add, which become more important if you want to block access to particular devices or networks (eg: guest WiFi).
And I've included a few links for additional rules by other Mikrotik users below.
Just remember that the defaults, while not perfect, are good enough (that is, these are for extra reading).

* http://wiki.mikrotik.com/wiki/How_to_Connect_your_Home_Network_to_xDSL_Line
* http://wiki.mikrotik.com/wiki/Securing_New_RouterOs_Router


### 6. IPv6

In 2017, [IPv6](https://en.wikipedia.org/wiki/IPv6) support is an essential requirement, in my mind.
The Internet has [run out of addresses](https://en.wikipedia.org/wiki/IPv4_address_exhaustion) and IPv6 is "Internet version 2", which supports more addresses than atoms in the Earth.
Many major website and companies are accessible via IPv6, and traffic is steadily rising.

As long as your ISP supports IPv6, its actually easier to get running than IPv4, because IPv6 auto-configures itself much better.

(An alternative guide to getting going with IPv6 can be found here: http://into6.com.au/?p=214)

#### 6a - Enable IPv6 on Mikrotik

[Mikrotik routers support IPv6](http://wiki.mikrotik.com/wiki/Manual:IPv6_Overview), but it is disabled by default: you need to enable it in *Packages* first.
Once enabled, you'll need to reboot your router.

You'll then have a new top level menu item *IPv6*.

#### 6b - Obtain an IPv6 Address Range

You never get a single [IPv6 address](https://en.wikipedia.org/wiki/IPv6_address).
All ISPs will issue you, at minimum, a `/64` subnet (which is the standard size of IPv6 subnets; that is, one local network).
(To give you some perspective of how be a `/64` is, it has enough addresses to fit the entire IPv4 Internet in it, millions of times over).
Most will issue a `/56` (which lets you create 256 sub-networks) or even a `/48` (65536 sub-networks).

Obtaining IPv6 addresses can be done via DHCP or router advertisements.
ISPs tend to use the former, and we will use the later to let our devices get addresses.

In *IPv6 -> DHCP Client*, create a new client.
Chose your ISP's network interface, set *Request* to `prefix` and enter a *Pool Name*.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/ipv6-dhcp-client.png" class="" width=300 height=300 alt="DHCP for IPv6" />

If all goes well, you should see an address range assigned to you in the *Status* tab.
And you should see a pool with this address range under *IPv6 -> Pools*.

#### 6c - IPv6 Router Addresses

Next step is to assign a public IPv6 address to your router.
(Note that your router will already have link local IPv6 addresses starting with `fe80`, that is normal).

In *IPv6 -> Addresses*, add a new address.
You can set the right-hand part of the address to be whatever you want, but I use the same address as the network mask (making my router device 0 on my network).
Select your LAN bridge as the interface to assign to.
And the *pool* you just created from DHCP.
Finally, make sure you enable *Advertise*, as that is the way your devices will get IPv6 addresses (via router advertisements).

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/ipv6-address.png" class="" width=300 height=300 alt="IPv6 Address" />

#### 6d - IPv6 Firewall

Something very important to remember about IPv6 is that every device can be directly contacted by anyone out there on the Internet.
That's by design.

Your devices and computers will have firewalls which stop traffic, but you can also block or allow traffic on your router's firewall.
That is, you could check each device is configured correctly, or you could make blanket rules on your router.

(It is worth doing an [IPv6 port scan](http://www.ipv6scanner.com/) of different devices on your network to see what is enabled by default.
I got a shock when I found that [remote desktop](https://en.wikipedia.org/wiki/Remote_Desktop_Protocol) was available on my computers; anyone on the IPv6 Internet with my address could connect - fortunately, I have a [strong password](https://makemeapassword.org)).

I'll leave it as an exercise for the reader to configure your IPv6 firewall, based on the IPv4 one.
Here is [another guide](http://into6.com.au/?p=244) if you get stuck.

I make a point to block incoming [VNC](https://en.wikipedia.org/wiki/Virtual_Network_Computing) connections and incoming and outgoing [SMB](https://en.wikipedia.org/wiki/Server_Message_Block) connections.
But everything else is allowed, at least for now.


#### 6e - IPv6 Addresses on devices

By the time you've finished mucking about with your firewall, it possible some of your devices may have obtained an IPv6 address already.
If not, disconnect and reconnect them, and they should pick up an address.

On a Windows command prompt, you can run the `ipconfig` command to show your current address.
Here's an example of mine:

```
Wireless LAN adapter Wi-Fi 2:

   Connection-specific DNS Suffix  . : ligos.local
   IPv6 Address. . . . . . . . . . . : 2001:44b8:3168:9b00:abcd:1234:5678:0001
   Temporary IPv6 Address. . . . . . : 2001:44b8:3168:9b00:5587:f3d3:3f92:36c5
   Link-local IPv6 Address . . . . . : fe80::abcd:1234:5678:0001%7
   IPv4 Address. . . . . . . . . . . : 10.46.1.31
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : fe80::4e5e:4d5d:4c5c:4b5b%7
                                       10.46.1.1
```

There are [websites which test if your computer is using IPv6](http://test-ipv6.com/).

And from here, you can enjoy IPv6 connections to [Facebook](https://www.facebook.com/notes/facebook-engineering/world-ipv6-day-solving-the-ip-address-chicken-and-egg-challenge/484445583919), [Google](https://www.google.com/intl/en/ipv6/), [Netflix](http://techblog.netflix.com/2012/07/enabling-support-for-ipv6.html) and [this blog](https://blog.ligos.net). 
Probably without noticing any difference at all.


#### 6f - Another Pool for Another Network

Finally, if you have a guest network configured with a separate IPv4 subnet, you can assign a second IPv6 subnet to it as well.

All you need to do is add a new pool, with the next IPv6 subnet (for me, that would be `2001:44b8:3168:9b01::/64`).
Then, just like you did before, add a new IPv6 address to your guest interface, and enable router advertisements from it.

<img src="/images/Use-A-Mikrotik-As-Your-Home-Router/ipv6-pool.png" class="" width=300 height=300 alt="IPv6 Pool" />



## Extra Functions

Mikrotik routers are full of functionality at a low cost.
If I go into all these in detail, I'll be here forever (and this article is already long enough).
So just a few basic pointers and reference Mikrotik documentation.


### Port Forwarding

Although port forwarding isn't on my list of "core router functions", the kind of people who might take the plunge with Mikrotik (nerds) are pretty likely to use it.

Mikrotik doesn't call it *port forwarding* but you can make special rules in *[Firewall -> NAT](http://wiki.mikrotik.com/wiki/Manual:IP/Firewall/NAT)*.
In here you add a `dst-nat` rule to the `dstnat` chain, which redirects traffic to an internal network address and port.

[Here's someone else's port forwarding guide](http://networkingforintegrators.com/2012/11/mikrotik-port-forwarding-example/)


A Mikrotik router can also do the opposite of port forwarding.
That is, making an internal connection to a public IP redirect to an internal server.
In my network, `home.ligos.net` resolves to my public IP address, but connections from my internal network get redirected to my server (instead of not working at all).
This is a very important feature if you are hosting HTTPS websites (like me), because the site DNS address must match the certificate.

This is not a normal feature of home routers.
I've heard it called *reflection* and *[hair pin NAT](http://wiki.mikrotik.com/wiki/Hairpin_NAT)*.
It's implemented as a special `srcnat` rule.


### Isolated Networks

I said above that Mikrotik's *guest WiFi* password is just a second password for your main network.
In my mind, guests are to be viewed with extreme suspicion (who knows what kind of [crypto ransomware](https://en.wikipedia.org/wiki/Ransomware) may be on their devices).
So they need to live on their own isolated network, without easy access to your main LAN.

You can make your own virtual WiFi interface, or use the *Quick Set* template.
Next steps are:

1. Make sure the guest WiFi interface is not part of your main LAN bridge.
2. Assign a new address to this interface for your router (eg: `192.168.89.1`).
3. Create a new DCHP server for the guest WiFi interface.
4. Create a new pool for your new subnet.
4. Create and configure a new DCHP scope for the new subnet.


Or for more [serious isolation, see my previous post](http://localhost:4000/2016-07-28/How-To-Make-An-Isolated-Network.html).


### IPSec VPN access

[IPSec](http://wiki.mikrotik.com/wiki/Manual:IP/IPsec) is a much stronger VPN than the ones created on the *Quick Set* page.
It's also mostly used for permanent VPN links between sites, rather than occasional "dial-in" style access.

And it's a real pain to configure correctly.
(I've struggled to get it working in the past, and simply don't touch the config any more - I fear I will break it).

If you feel brave, the link above will get you started.


### File Sharing

Some home routers let you connect a USB hard disk and share files.
A Mikrotik router can enable SMB network connections (also known as Windows networking), FTP and SSH for basic file sharing.

(Note that Mikrotik routers don't do this very well. Heck, most home routers do this pretty poorly too. It's really the domain of [NAS](https://en.wikipedia.org/wiki/Network-attached_storage) devices, so if you want to do it properly, go buy a NAS.)

Once you connect your USB you need to format it in *[System -> Disks](http://wiki.mikrotik.com/wiki/Manual:System/Disks)*.
It will then appear as a folder under the `Files` menu.
And you can enable network sharing under *[IP -> SMB](http://wiki.mikrotik.com/wiki/Manual:IP/SMB)*.


### Dynamic DNS

Mikrotik routers come with a free [dynamic DNS](https://en.wikipedia.org/wiki/Dynamic_DNS) service, which updates whenever your dynamic IP address changes.
If you enabled VPN in *Quick Set*, dynamic DNS is already enabled.

Otherwise it lives in *[IP -> Cloud](http://wiki.mikrotik.com/wiki/Manual:IP/Cloud) -> DDNS Enabled*.

Fun fact: if you own your own domain (eg: *ligos.net*), you can create a DNS `CNAME` record (say `home.ligos.net`) which points to the long dynamic DNS address for an easier to remember name.


### Queues / Shaping

[Queues](http://wiki.mikrotik.com/wiki/Manual:Queue) are how Mikrotik routers provide [quality of service](https://en.wikipedia.org/wiki/Quality_of_service).
That is, they can shape, prioritise and limit bandwidth to different networks or devices.
For example, you could restrict the bandwidth allowed by particular devices.

Configuring queues and QoS is really hard, and I've never managed to understand it properly.
In the end, I've just created a few simple queues which make sure no single network can use all my (terribly limited) Internet bandwidth.
I'm sure there are better solutions, but this is good enough for me.

~~One helpful tip though: create a new *queue type* with a larger queue size (I'm using 200, instead of the default of 10), this will not drop as many packets while still restricting bandwidth.~~

**Update (1/Apr/2017):** A more helpful tip is not to use *fifo* queues when you have limited bandwidth; that causes [buffer bloat](https://www.bufferbloat.net/projects/) and dramatically increases latency.
Instead, use the *sfq* or *pcq* kinds.
You'll need to create new queue types for these as they aren't configured out of the box.
The *sfq* and *pcq* algorithms still restrict bandwidth, but do it in a fairer way, so the latency of individual connections isn't completely terrible.


## Conclusion

Well, that is a lot of information!
But Mikrotik routers provide a lot of functionality!

You should be able to get on the Internet with a Mikrotik using the *Quick Set* screen.
Then navigate your way around the Winbox interface, to see current status and update basic configuration.
And you have plenty of options in terms of other functionality.

Enjoy your new Mikrotik router! 
Watch it run faster, do more and and be more reliable than your old home router.


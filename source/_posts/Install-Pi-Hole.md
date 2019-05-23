---
title: Install Pi-Hole
date: 2019-05-23
tags:
- Pi-Hole
- How-To
- DNS
- Ad-Blocker
- Step-By-Step
categories: Technical
---

Block ads. Browse faster.

<!-- more --> 

## Background

I have a [Pi-Hole](https://pi-hole.net/) installed on my network to block ads.
It works by building a list of DNS names that are used to serve ads, track you via cookies, or deliver malicious content (aka viruses), and when your devices request those servers, URLs or addresses, the Pi-Hole responds with a bogus IP addres (eg: `0.0.0.0`).

That is, blacklisted addresses end up in a block hole.
And your computer is unable to access them.
Which makes things safer and faster.

Actually, I have installed Pi-Hole on several computers, including my [hosting server... err... laptop](/2019-03-09/Migrating-From-IIS-to-Nginx.html), which (indirectly) [caused problems for Nginx](/2019-03-25/Fixing-Nginx-proxy_pass-DNS-errors.html), and a real [Raspberry PI](https://www.raspberrypi.org/).

Installing Pi-Hole on a dedicated Pi is pretty easy.
Installing it on a more general purpose server is a bit harder.
And the service it provides is so good, I want people know exactly what's involved so they can do it too!

There's plenty of other guides for installing Pi-Hole.
So if my one doesn't help, [check out another one](https://www.bing.com/search?q=how+to+install+pi-hole)!


## Goal

Install Pi-Hole onto a Debian 9 machine (x64, Stretch).

Because I'm running my DHCP from my router and a webserver on my Pi-Hole, I'll need a few custom config changes.


## Steps

You'll need a computer to run Pi-Hole on.
That can be anything from an old laptop or desktop, to a Raspberry Pi,to something more powerful (eg: a real server).

In all seriousness, I have another Pi-Hole installed on a [Raspberry Pi 1 Model B](https://en.wikipedia.org/wiki/Raspberry_Pi#Generations_of_released_models) (the one with 512MB RAM and 1 CPU), and it works just fine.
In this case, I'm installing on an old desktop PC, which I'll be using as a low end server.


### Step 1 - Installer

[Download and run the installer](https://github.com/pi-hole/pi-hole/#one-step-automated-install).


```
murray@k2so:~$ wget -O pi-hole-install.sh https://install.pi-hole.net
--2019-05-19 15:44:02--  https://install.pi-hole.net/
Resolving install.pi-hole.net (install.pi-hole.net)... 78.46.180.80
Connecting to install.pi-hole.net (install.pi-hole.net)|78.46.180.80|:443... connected.

2019-05-19 15:44:05 (347 KB/s) - ‘pi-hole-install.sh’ saved [113651/113651]

murray@k2so:~$ sudo bash ./pi-hole-install.sh
```

After this, it will kick into an [ncurses UI](https://en.wikipedia.org/wiki/Ncurses) and install any packages required, before showing the welcome screen.

<img src="/images/Install-Pi-Hole/welcome-screen.png" class="" width=300 height=300 alt="Welcome to Pi-Hole!" />

After a few screens, you get a warning about Pi-Hole requiring a static IP address.
We'll need to fix that up later, because server is already assigned a fixed IP address via my router.

<img src="/images/Install-Pi-Hole/static-ip-address-warning.png" class="" width=300 height=300 alt="You already have a static IP address, Pi-Hole" />


### Step 2 - Installer Walk Through

The first real choice you need to make during the install is your *Upstream DNS Provider*.
This will be the DNS servers your Pi-Hole calls out to.
I prefer *Quad9 (unfiltered, DNSSEC)* (https://www.quad9.net/), but you can change your selection after installation anyway.

<img src="/images/Install-Pi-Hole/upstream-dns.png" class="" width=300 height=300 alt="I Choose Quad9 (filters, DNSSEC)" />

Then you can pick the blocklists Pi-Hole will subscribe to.
I leave these all selected.

<img src="/images/Install-Pi-Hole/blocklist-list.png" class="" width=300 height=300 alt="All the Blocklists!" />

I have public IPv6 addresses, so I'll serve DNS over IPv4 and IPv6.
It is worth being careful what other servers can connect to your Pi-Hole if you select IPv6 - some firewall rules may be needed ([and tested](https://ipv6.chappell-family.com/ipv6tcptest/)).
If that kind of thing worries you, unselect IPv6.

<img src="/images/Install-Pi-Hole/ip-addresses.png" class="" width=300 height=300 alt="IPv4 and IPv6" />

The next question sets your server's IP address.
Unfortunately, there's no way to say "I don't want a static IP - my router will assign the same address all the time".
It's best to just accept the default and fix the config file up later.

<img src="/images/Install-Pi-Hole/static-ip-address-config.png" class="" width=300 height=300 alt="Err... Actually I don't want any static IP address." />

<img src="/images/Install-Pi-Hole/static-ip-address-conflict.png" class="" width=300 height=300 alt="Yep, I'll be going with the 'DHCP reservation' option thanks." />

You can choose to disable the web admin interface.
If you do that, you'll need to use the SSH / console based command line.
I prefer the GUI, so it stays on.

<img src="/images/Install-Pi-Hole/web-interface-option.png" class="" width=300 height=300 alt="Web Admin Interface? Yes, I take one of those." />

If you want, you can run the admin interface via Nginx or Apache.
I've no idea how easy or hard that is to configure, but its definitely harder than just letting Pi-Hole do its own thing.
We'll just need to change the port later on.

<img src="/images/Install-Pi-Hole/web-interface-lighttp.png" class="" width=300 height=300 alt="Using lighttp will Just Make it Work™!" />

Logging queries means you can get all kinds of stats out of Pi-Hole.
Like what addresses are most commonly queried, or blocked, or what device is making the queries, etc.
You can turn it off if you want to be more anonymous.
Given this is for my own family, anonymity isn't a concern.

<img src="/images/Install-Pi-Hole/config-log-queries.png" class="" width=300 height=300 alt="Log the queries." />

Then there's an actual privacy level.
I'm choosing the least private *Show Everything* option.
This can be changed later on in the Pi-Hole admin webpage.

<img src="/images/Install-Pi-Hole/config-privacy.png" class="" width=300 height=300 alt="No privacy. Show all the things." />

Then you get a few screens of progress and debug spew.

<img src="/images/Install-Pi-Hole/installation-1.png" class="" width=300 height=300 alt="Installer debug spew." />

<img src="/images/Install-Pi-Hole/installation-2.png" class="" width=300 height=300 alt="Installer progress." />

There's an option to add a firewall rule, but I found that it didn't work with `ufw`, and I had to add it manually anyway.
So I answered *No*.

<img src="/images/Install-Pi-Hole/firewall-rule.png" class="" width=300 height=300 alt="It wasn't compatible for some reason." />

More debug spew...

<img src="/images/Install-Pi-Hole/installation-3.png" class="" width=300 height=300 alt="More installer debug spew." />

And finally, we have *Installation Complete*!
Make a note of URLs, IP addresses and passwords (sorry, my password has changed since publication).

<img src="/images/Install-Pi-Hole/installation-complete.png" class="" width=300 height=300 alt="It's done!" />


### Step 3 - Firewall Rule

DNS queries are unauthenticated and unencrypted, so you don't want to allow anyone out the on the Internet to use your Pi-Hole.
If you're only using IPv4 then this isn't a problem, but an IPv6 firewall rule to block DNS queries is very wise.

I always forget the exact syntax for `ufw`, so I use [Ubuntu's cheat sheet](https://help.ubuntu.com/community/UFW).

The key part is `from YourIpAddress` part, which restricts access to port 53 to your local network.
The other common network is `192.168.0.0/16`.
By default, `ufw` blocks everything, so if I only allow an IPv4 address range then IPv6 remains blocked.

```
murray@k2so:~$ sudo ufw allow from 10.0.0.0/8 to any port 53
Rule added
murray@k2so:~$ sudo ufw status
Status: active

To                         Action      From
--                         ------      ----
22                         ALLOW       Anywhere
80                         ALLOW       Anywhere
443                        ALLOW       Anywhere
53                         ALLOW       10.0.0.0/8
22 (v6)                    ALLOW       Anywhere (v6)
80 (v6)                    ALLOW       Anywhere (v6)
443 (v6)                   ALLOW       Anywhere (v6)
```

You can test Pi-Hole is working from another computer.
On my Windows PC, I use the following PowerShell command (`-server` tells your computer to use your Pi-Hole instead of the default DNS server, which is usually your router):

```
PS> Resolve-DnsName -server 10.46.1.19 ligos.net
Name       Type   TTL   Section    IPAddress
----       ----   ---   -------    ---------
ligos.net  AAAA   3600  Answer     2001:44b8:3168:9b02:f24d:a2ff:fe7c:1614
ligos.net  A      3600  Answer     150.101.201.180
```

### Step 4 - Configure Devices

Pi-Hole provides some [documentation for how to configure devices](https://discourse.pi-hole.net/t/how-do-i-configure-my-devices-to-use-pi-hole-as-their-dns-server/245) to use it as a DNS server.
This boils down to changing your DHCP server (usually on your router) to point to the PI-Hole address instead of the router.
Some cheap routers might not let you do this, so see the documentation above for other options, but my Mikrotik lets you configure as many DNS servers as you like.

<img src="/images/Install-Pi-Hole/router-dhcp-dns-servers.png" class="" width=300 height=300 alt="Telling my devices to use Pi-Hole." />

DHCP changes may take up to 24 hours to be picked up by devices.
Although you can restart your phone or computer to force the issue.

Bare in mind that if your Pi-Hole isn't configured correctly, your devices will suddenly be unable to access the Internet.


### Step 5 - Fix Static IP Address

The static IP address, which was set in the installer, needs to be undone.
You need to edit `/etc/dhcpcd.conf` and remove (or comment out) the last few lines starting with *static*.
My experience is you only need to do this once, Pi-Hole doesn't try to re-do it when you upgrade.

```
murray@k2so:~$ sudo nano /etc/dhcpcd.conf
```

<img src="/images/Install-Pi-Hole/dhcpcd.conf.png" class="" width=300 height=300 alt="No more static IP address." />


### Step 5 - Fix Web Server

Pi-Hole installs [lighttpd](http://www.lighttpd.net/) on port 80 (the default web server port).
Unfortunately, I already have `nginx` running on port 80.
So tweak `lighttpd`'s config file so it runs on 81.

```
murray@k2so:~$ sudo nano /etc/lighttpd/lighttpd.conf
```

<img src="/images/Install-Pi-Hole/lighttpd.conf.png" class="" width=300 height=300 alt="Use port 81 instead of port 80." />

Update your firewall to allow access to port 81.

```
murray@k2so:~$ sudo ufw allow from 10.0.0.0/8 to any port 81
Rule added
murray@k2so:~$ sudo ufw status
Status: active

To                         Action      From
--                         ------      ----
22                         ALLOW       Anywhere
80                         ALLOW       Anywhere
443                        ALLOW       Anywhere
53                         ALLOW       10.0.0.0/8
81                         ALLOW       10.0.0.0/8
22 (v6)                    ALLOW       Anywhere (v6)
80 (v6)                    ALLOW       Anywhere (v6)
443 (v6)                   ALLOW       Anywhere (v6)
```

Then restart `lighttpd` for the change to take effect.

```
murray@k2so:~$ sudo systemctl restart lighttpd
```

**Note:** I've found upgrades to Pi-Hole put `lighttpd` back on port 80 and can also break `nginx`.
Be careful!


### Step 6 - Password Reset

You can set or reset the web admin password via the command line:

```
murray@k2so:/etc/lighttpd$ sudo pihole -a -p
Enter New Password (Blank for no password):
Confirm Password:
  [✓] New password set
```

<small>Sorry, you don't get to see my password!</small>



### Step 7 - Web Config

At this point, we're ready to visit the web GUI.
Point your browser to the URL noted at the end of the installation (eg: http://10.46.1.19/admin) and you'll see some basic statistics.

<img src="/images/Install-Pi-Hole/anon-dashboard.png" class="" width=300 height=300 alt="Web GUI dashboard." />

Pop over the login page, enter your password and you'll be able to see more details on the main dashboard.
And additional options down the left menu.

<img src="/images/Install-Pi-Hole/admin-dashboard.png" class="" width=300 height=300 alt="Web GUI dashboard - Admin version." />


### Step 8 - Whitelist

As we selected all the block lists, there are likely a few servers blocked that we actually need access to.
In particular, I found several Microsoft services didn't work, and needed to whitelist them.
If you prefer to block all things Microsoft, then leave this page blank.

<img src="/images/Install-Pi-Hole/admin-whitelist.png" class="" width=300 height=300 alt="Whitelisted Addresses." />

You can see from the *Dashboard* and *Query Log* pages what sites are being blocked, which may give you clues if something in particular isn't working.


### Step 9 - DNS

We selected Quad9 as our Upstream DNS Server during installation, but we can change that on *Settings -> DNS*.
Pick as many as you'd like, and choose whichever meet your needs.

<img src="/images/Install-Pi-Hole/admin-settings-dns.png" class="" width=300 height=300 alt="Upstream DNS selection." />

You can also switch on some advanced DNS settings if you scroll down.
The first two (*never forward non-FQDNs* and *never forward reverse lookups for private IP ranges*) try to avoid leaking information about your internal network to the rest of the world - I haven't found any problems turning them on.

*Use DNSSEC* enables... well... [DNSSEC](https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) which helps ensure [DNS queries are secure](https://www.icann.org/resources/pages/dnssec-what-is-it-why-important-2019-03-05-en) - additional security is a good thing, but there may be compatibility issues, so read the Pi-Hole blurb before enabling (hint: I enable DNSSEC and all is well).

*Use Conditional Forwarding* lets Pi-Hole pick up a more friendly name for your devices' IP addresses based on your router.
This assumes that your router records names of devices based on DHCP leases (my Mikrotik router doesn't, but I try to set static DNS entries for most of my devices anyway).
Basically, any DNS lookups for your internal network (`ligos.local` in my case), are forwarded to your router (on IP `10.46.1.1` for me).

<img src="/images/Install-Pi-Hole/admin-settings-dns-advanced.png" class="" width=300 height=300 alt="Advanced DNS Settings." />



### Step 10 - Add Other Block Lists

Pi-Hole's defaults are pretty good.
But I add one additional blocklist, which blocks sites that are known for serving [malware and ransomware](https://ransomwaretracker.abuse.ch/).

You can find this list in *Settings -> Blocklists*.

<img src="/images/Install-Pi-Hole/admin-settings-blocklists.png" class="" width=300 height=300 alt="Blocklists. The last one is added manually." />


### Step 11 - Block Youtube (optional)

One of the main consumers of bandwidth in my household is the infamous YouTube.
Blocking it so my kids can't occupy all of my meagre 4Mbps of downstream bandwidth is sometimes... necessary.

You can add a few regex rules to *Blacklist* and block [YouTube](https://youtube.com), like so:

```
Exact: youtube-ui.l.google.com
Exact: youtubei.googleapis.com
Regex: ^(.*|\.)youtube\.com
Regex: ^(.*|\.)googlevideo\.com
```

And [Netflix](https://netflix.com): 

```
Regex: ^(.*|\.)nflxso\.net
Regex: ^(.*|\.)netflix\.com
Regex: ^(.*|\.)nflxvideo\.net
```

And [iView](https://iview.abc.net.au):

```
Regex: ^(.*|\.)iview\.abc\.net\.au
```

<img src="/images/Install-Pi-Hole/admin-settings-blacklist.png" class="" width=300 height=300 alt="Blacklist: A special place for YouTube traffic." />


Unfortunately, when you remove the rules, they're gone.
There's no way for Pi-Hole to disable but remember them.
So, they're recorded here.


## Updates

Pi-Hole receives regular updates with bug fixes and new features.
It's usually a good idea to install updates, but because DNS is such a critical low level part of the Internet, it's worth being careful when upgrading your Pi-Hole - if things break, you may end up unable to access the Internet.

I prefer to upgrade from SSH rather than the web GUI, because I'm in a better position to fix anything broken.
I also aim to do upgrades when the rest of my family is away or asleep.
Finally, because I'm running multiple Pi-Holes, if one breaks, my devices will automatically switch to another.

```
murray@k2so:/etc/lighttpd$ sudo pihole -up
  [i] Checking for updates...
  [i] Pi-hole Core:     update available
  [i] Web Interface:    update available
  [i] FTL:              update available

  <insert debug spew here> ...

Update Complete!

  Current Pi-hole version is v4.3
  Current AdminLTE version is v4.3
  Current FTL version is v4.3
```

You also should check the updater doesn't overwrite configuration files you may have modified.
In particular, `lighttpd` seems to be broken every time I update.


## Conclusion

Pi-Hole is a fantastic tool to block ads, malware and other undesirable sites on the Internet.
With a $100 of Raspberry Pi, or a free old computer, and an hour or two, you can install it yourself!
And your browsing experience will be that much safer and faster.
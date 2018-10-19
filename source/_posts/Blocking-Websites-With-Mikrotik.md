---
title: Blocking Websites with Mikrotik
date: 2018-09-16
updated: 2018-10-19
tags:
- Mikrotik
- Firewall
- DNS
- Blocking
- Video
- YouTube
categories: Technical
---

How to stop people accessing YouTube (and other sites).

<!-- more --> 

## Background

My family is going on holiday shortly, and I'll be taking a [Mikrotik router with an Android phone and 4G Internet connection](/2017-08-16/Mikrotik-And-LTE-via-Android.html).
That will give us Internet access for laptops and a desktop.

However, my kids (and adults, if we're honest with ourselves) love watching YouTube videos.
But they have no sense of how much data these can consume, and there's no such thing as unlimited (or even "unlimited" [but-not-really-unlimited](https://www.whistleout.com/CellPhones/Guides/Fact-A-Truly-Unlimited-Data-Plan-Doesnt-Exist)) mobile data in Australia. 

**Update 2018-10-19:** I've added an *effectiveness* section to each technique I've described here, based on my experience over the last few months.

## Goal

I want my Mikrotik to block access to a small number of video websites.
The ones my kids gravitate towards: [YouTube](https://youtube.com), [Netflix](https://www.netflix.com), and [iView](https://iview.abc.net.au/).

It would be nice if *The Solution* can be brought home so I can kick kids off video sites, but still let them do homework hosted on other domains.

I have IPv6 at home, so *The Solution* will need to apply to IPv6 as well.

And, the vast majority of my video traffic is HTTPS, so *The Solution* mustn't be thwarted by encryption.


## What Happens When You Browse to YouTube.com?

Before I give any answers away, a little bit of thinking is in order.
If you know what happens when you browse to a website, then you can better understand different ways of identifying traffic going to them, and how you can block that traffic.

So, I punch `youtube.com` into my browser.
What happens to make cat videos come up on my screen?

<small>(For people who like drilling down to absurd amounts of detail, I'm only thinking about networking. Sorry if you were hoping for an [analysis of key presses](https://github.com/alex/what-happens-when).)</small>


1. My browser will do a [DNS lookup](https://en.wikipedia.org/wiki/Domain_Name_System) of `youtube.com` (and possibly `www.youtube.com`).
2. My browser is told the IP address of `youtube.com` is `216.58.199.78` (or maybe `2404:6800:4006:808::200e`).
3. My browser knows that `youtube.com` has enabled [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security), so it makes an HTTPS connection (if it had never visited `youtube.com` before, it *might* attempt an HTTP connection first, but that's getting [more and more unlikely](https://en.wikipedia.org/wiki/HTTP_Public_Key_Pinning) these days).
4. `youtube.com` responds with a webpage, which contains links to other assets (like javascript, images, videos, etc) which might be on other domains (eg: `soemthing.youtube.com`).
5. Goto #1 for each asset.

An important part of this process is that my Mikrotik router sits between my browser and `youtube.com`.
That is, your router will listen in on the whole conversation.
Which means we have lots of options for how we might interrupt it!



## Options to Block Websites

Because I control my own router, there are lots of ways I can subvert connections to `youtube.com`.
It's all about identifying traffic to `youtube.com` (as distinct from, say, `iview.com.au`).
And putting something in place to block that traffic.
Most of the rest of this article will be a discussion of these.

Options available:

* DNS Sinkhole
* Firewall + Address Lists
* Firewall + TLS Host + Transparent Proxy
* Firewall + Layer 7 Protocols

How I'll evaluate:

* Talk about the principals behind the technique.
* Show you how do do it within RouterOS.
* Actually do it on my network and see how well it works (with IPv6, HTTPS, small children, etc).

**The big VPN caveat:** if devices on your network make use of [VPNs](https://en.wikipedia.org/wiki/Virtual_private_network), none of these options will be effective.
You'll have to block VPN providers as well (and I'm not getting into that today)!
But that's kinda the point of VPNs - to create a secure tunnel from one place to another.

<hr />

### Block using a DNS Sinkhole

Most routers have a small DNS server embedded in them.
Devices on your network will ask your router to translate `youtube.com` into `216.58.199.78`, and your router can either a) go ask your ISP the same question, or b) send a result from an internal cache.

Because your router effectively controls what server `youtube.com` really is, you can create a [DNS Sinkhole](https://en.wikipedia.org/wiki/DNS_sinkhole) to block websites.

This works by lying.
Instead of saying `youtube.com` = `216.58.199.78`, your router says `youtube.com` = `127.0.0.1` or `192.168.0.1` or something else.
And so your browser can't get to the real `youtube.com`.

<img src="/images/Blocking-Websites-with-Mikrotik/router-dns-sinkhole.png" class="" width=300 height=300 alt="DNS Sinkhole" />

In fact, there's a thing called [Pi-Hole](https://pi-hole.net/) which uses this exact technique to block advertisements.

(Incidentally, the fact anyone can do this is one of the biggest security holes in the Internet! 
There are proposals like [DNSSEC](https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) to plug that hole with magic encryption, but their uptake is very slow.)



### How Do You Do It?

Most routers don't let you add arbitrary DNS entries, they will only cache what the ISP tells them.
Mikrotik does caching, and also lets you add static DNS records.

[IP -> DNS -> Static -> Add](https://wiki.mikrotik.com/wiki/Manual:IP/DNS#Static_DNS_Entries)

Name is the DNS name you want to block, and address is, well, the address you want to direct traffic to.
That is, the sinkhole.
If you're feeling smart, you can use a [Regex](https://en.wikipedia.org/wiki/Regular_expression) instead of a name (regexes confuse me at the best of times, so I'm sticking with names - but a regex is the only way to match all sub-domains).

<img src="/images/Blocking-Websites-with-Mikrotik/dns-add-static.png" class="" width=300 height=300 alt="Add DNS Entry" />

```
[admin@Mikrotik-gateway] /ip dns static> print
...
;;; DNS Sinkhole START
22    youtube.com       192.168.1.254
23    youtube.com       2001:44b8:3168:9b00::ffff
24    www.youtube.com   192.168.1.254
25    www.youtube.com   2001:44b8:3168:9b00::ffff
```

If you're using Pi-Hole, the sinkhole is a nice webserver which shows a "you can't see this message".
But for our purposes, we'll just add a new IP address to the router and reject any traffic that hits it.

[IP -> Firewall -> Filter](https://wiki.mikrotik.com/wiki/Manual:IP/Firewall/Filter)

```
[admin@Mikrotik-gateway] /ip firewall filter> print
...
39    ;;; Drop DNS Sinkhole Traffic
      chain=input
      action=reject 
      reject-with=tcp-reset 
      protocol=tcp 
      dst-address=192.168.1.254 
      dst-port=80,443 
```


#### Pros, Cons and Effectiveness

*Does it stop my kids?* - Mostly.

*Works with IPv6?* - Yes! Add an IPv6 address in DNS just like IPv4.

*Works with HTTPS* - Yes!

*Pros:*

* Quite simple - a couple of firewall rules and as many DNS entries as we need to block.
* Works - ticks all my boxes.
* Scales - any site you want to block just add it to the DNS.

*Cons:*

* All or nothing - either everyone is blocked, or no one. You can't allow one computer and block another.
* Pretty easy to bypass - just set your DNS servers on your computer to [Quad9](https://www.quad9.net/) or [Cloudflare DNS](https://cloudflare-dns.com/) or [Google's Public DNS](https://developers.google.com/speed/public-dns/) and you've bypassed the block.
* Double entry - you need to add an IPv4 and and and IPv6 address for anything you want to block.

*Effectiveness:*

This was the most effective of all blocking techniques.
Only problem is the DNS names used by the YouTube Android app are different to the ones used by [www.youtube.com](https://www.youtube.com).
So it was easy to block kids on PCs, but not so easy to block kids on phones and tablets.
Oh, and don't forget to change the TTL on your static DNS entries to 5 minutes, otherwise turning the rules on and off is problematic.
Otherwise, it worked really well.


<hr />

### Block Using Firewall Rules and Address Lists

This is more direct than DNS: we simply create some firewall rules which block traffic on ports 80 and 443 to `youtube.com`.
Anything which goes via the router and matches the firewall rules gets blocked.

Only problem is that firewalls block on IP addresses rather than domain names.
That is `216.58.199.78` instead of `youtube.com`.
And that's a pain.

Fortunately, we can add names to the firewall address list.
And this will automatically resolve the names to IP addresses for us.

<img src="/images/Blocking-Websites-with-Mikrotik/router-firewall.png" class="" width=300 height=300 alt="Rules to Block YouTube" />


#### How Do You Do It?

Add `youtube.com` to your firewall *Address Lists* section.
And then add a rule to block traffic.

At some point, Mikrotik added the ability for *dynamic* address lists - rather than just adding a list of IP addresses, you use DNS names and your router looks after things for you.
Even when there are multiple addresses behind the DNS name (as is the case with `youtube.com`).
I'm not sure how often these get updated, but it seems to work well enough for me.

[IP -> Firewall -> Address Lists](https://wiki.mikrotik.com/wiki/Manual:IP/Firewall/Address_list)

[IP -> Firewall -> Filter](https://wiki.mikrotik.com/wiki/Manual:IP/Firewall/Filter)

If you want to cover IPv6 (like me) just do the same in the IPv6 firewall as well.

<img src="/images/Blocking-Websites-with-Mikrotik/firewall-add-address-list.png" class="" width=300 height=300 alt="Firewall Address List with YouTube" />

```
[admin@Mikrotik-gateway] /ip firewall address-list> print
...
38   named_site_youtube     youtube.com    
39   named_site_youtube     www.youtube.com
40 D ;;; www.youtube.com
     named_site_youtube     172.217.167.78 
41 D ;;; www.youtube.com
     named_site_youtube     172.217.167.110
42 D ;;; www.youtube.com
     named_site_youtube     216.58.196.142 
43 D ;;; www.youtube.com
     named_site_youtube     216.58.203.110 
44 D ;;; www.youtube.com
     named_site_youtube     172.217.25.46  
45 D ;;; www.youtube.com
     named_site_youtube     216.58.200.110 


[admin@Mikrotik-gateway] /ip firewall filter> print
...
40    ;;; Drop Youtube
      chain=forward 
      action=reject 
      reject-with=tcp-reset 
      protocol=tcp 
      dst-address-list=named_site_youtube 
      dst-port=80,443 
```

#### Pros, Cons and Effectiveness

*Does it stop my kids?* - Not really. 

*Works with IPv6?* - Yes, but you need to add separate rules for the IPv6 firewall.

*Works with HTTPS* - Yes! Just block port 443 as well as 80.

*Pros:*

* Simple - a couple of firewall rules and as addresses as we need to block.
* Scales - add sites you want blocked to the Firewall Address List.
* Granular - can use firewall rules to allow some devices through and block others.
* Secure - any traffic which goes via the firewall gets blocked.
* Works - ticks all my boxes.

*Cons:*

* Address Lists don't support regexes, which means you have to list every site name you want blocked.
* No regexes means you can't block whole sub-domains, which makes this ineffective against advertising / tracking sites.

*Effectiveness:*

This didn't really work for YouTube, and had unintended side-effects for [iView](https://iview.abc.net.au).

The problem with YouTube is the dynamic firewall names never covered all IP addresses required.
Either the dynamic addresses expired too quickly and weren't refreshed, or not enough addresses were added to the firewall.
So it would block really well for around 5 minutes, and then about 50% of the time for the next 15 minutes, and less than 50% after that.

ABC iView didn't have this problem because it only had a few IP addresses, so the dynamic addresses worked and blocked effectively.
Unfortunately, the same IP that hosts iView also hosts content for the [ABC News](https://www.abc.net.au/news/) Android app.
So blocking iView by IP address also blocks my main news outlet.

<hr />

### Block Using Firewall Rules and TLS Host + Transparent Proxy

The TLS Host part is a variation on the previous option.
Instead of using the Address List, we specify a TLS Host to match encrypted HTTPS traffic.
And add a transparent proxy to block unencrypted HTTP traffic.

When you make an HTTPS connection almost everything is encrypted, except, in the initial connection, the name of the website you're connecting to.
This enables [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), which allows multiple HTTPS websites to share the same IP address.
And it's that website name, sent in the clear, which triggers the firewall rule.

One caveat: firewall is looking at individual network packets, if the TLS host name is broken across multiple packets, then this won't work.
(I don't know how likely that is - it doesn't seem very likely at first glance, but you never know).

The transparent proxy side means that all unencrypted HTTP requests go via the router's proxy server.
It receives each request, and replays it to the real webserver, and the same when replies come back.
No configuration is required by clients (hence the *transparent* part).
But it means the router can inspect, block and log any traffic.



#### How Do You Do It?

I'm not actually going to test this one.
I did run a transparent proxy for a month or so, on my router.
The hope was that it would reduce my usage by caching data for things like [Windows Updates](http://windowsupdate.microsoft.com/) and [Steam downloads](https://store.steampowered.com/).
Unfortunately, because so much of my traffic goes over HTTPS, very little got cached.
So I turned it off.

Anyway, here are a few pointers to get you started.

First, you need to activate a web proxy on your router (or host one on another computer).
And then there are some special firewall rules you need for the [transparent proxy part](https://wiki.mikrotik.com/wiki/How_to_make_transparent_web_proxy).
Once your proxy is in place, there's a firewall-rule like section under *Access*, which lets you allow / deny access to websites.

[IP -> Web Proxy](https://wiki.mikrotik.com/wiki/Manual:IP/Proxy)

`TLS Host` is a field sitting in *Firewall rules* -> *Advanced tab*.
You simply add the domain name you want the rule to match.
And you can enable regexes to match sub-domains.

[IP -> Firewall -> Filters -> Add -> TLS Host](https://wiki.mikrotik.com/wiki/Manual:IP/Firewall/Filter)

<img src="/images/Blocking-Websites-with-Mikrotik/firewall-tls-host.png" class="" width=300 height=300 alt="Firewall TLS Host" />


#### Pros, Cons and Effectiveness

*Does it stop my kids?* - Not reliably.

*Works with IPv6?* - Yes, but you need to add separate rules for the IPv6 firewall.

*Works with HTTPS* - Apparently, with caveats as explained above.

*Pros:*

* Scales - add sites you want blocked to the Firewall Address List or Web Proxy.
* Granular - can make rules to allow and deny based on IP address.
* Can leverage regex for TLS Hosts.

*Cons:*

* Quite complicated compared to other options.
* Have to add sites in two quite different parts of the router.
* Untested.

*Effectiveness:*

I tried the TLS Hosts based blocking for YouTube and found it is rather hit and miss.
The rule would be hit sometimes (based on statistics logged in the router) but not always (based on my kids still able to access YouTube).
This might be down to the TLS hostname limitation, but seems more likely to be due to [HTTP/2](https://en.wikipedia.org/wiki/HTTP/2) and [QUIC](https://en.wikipedia.org/wiki/QUIC).
QUIC is available in Chrome (although doesn't appear to be widely enabled by default) and uses a UDP based protocol, which completely bypasses the Mikrotik's TLS Host rule (which only applies to TCP connections) (thanks to the comment by *Jot Z* for bringing QUIC to my attention).
HTTP/2 still uses TCP, but seems to keep connections open for much longer.
As the firewall only attempts to block on the initial connection, once you establish a long HTTP/2 based connection to YouTube, you're basically home free.



<hr />

### Block Using Firewall Rules and Layer 7 Protocols

When I initially searched for "Mikrotik Block Website" I turned up [guides](http://www.binaryheartbeat.net/2015/03/layer-7-website-blocking-using-mikrotik.html) about [layer 7 protocols](http://rasleeholdings.com/how-to-block-any-website-in-mikrotik-using-layer-7-protocol/).
So I looked at the [Mirotik manual for Layer 7 Protocols](https://wiki.mikrotik.com/wiki/Manual:IP/Firewall/L7) (having never used them before).
And found this:

<img src="/images/Blocking-Websites-with-Mikrotik/layer-7-protocols-warning.png" class="" width=300 height=300 alt="Apparently I don't want to use Layer 7 Protocols" />

Apparently, Layer 7 Protocols are applying a [regex](https://en.wikipedia.org/wiki/Regular_expression) to the first 10 packets / 2kB of every network stream.
Which consumes a stack of CPU / memory on your router.

So, I'm not going to bother testing this because there are other guides out there if you want to go down this road.

And, I'll actually heed the warning saying "don't use this for blocking websites by URL".




## How Do You Know What Domains to Block?

One thing I've glossed over is how to identify what domains to block.
That is, YouTube isn't just hosted at `youtube.com`, but also accesses `gstatic.com`, `timg.com` and `googlevideo.com`.
How do you work out all the things to block?

### Developer Tools

You can use the [Browser Developer Tools](https://developer.mozilla.org/en-US/docs/Learn/Common_questions/What_are_browser_developer_tools), often activated by `F12`.

All browsers have a set of tools for web developers (like me!), which let you poke around behind the scenes.
Of particular interest to us is the **Network** tab, which lists all the assets loaded on a page.
These are things like images, videos, styles, javascript and so on.

<img src="/images/Blocking-Websites-with-Mikrotik/edge-browser-tools-network.png" class="" width=300 height=300 alt="Browser Developer Screen - Network tab" />

Unfortunately, its not always obvious what should be blocked and what shouldn't.
There will be some really obvious things to block, some strong possibilities, and then lots of question marks.

My policy is, start with the obvious and see if a motivated user (ie: my kids) can get past it.
If they can, pick a few more things to block.

A few tips:

1. Even though I typed in `youtube.com` into my browser, it redirected to `www.youtube.com`. So I'll need to block both of them.
2. As a web developer, there are some "shared library" sites I recognise, eg: `fonts.googleapis.com`. If you block these, it will probably break other sites, so leave them off.
3. I'm not sure about `ytimg.com`, my guess is its another "shared library" site, so I won't block it just yet.
4. `googlevideo.com` looks like where the raw video content comes from, but the crazy sub-domain means I'll need a regex to block it - so I'll use a TLS Host firewall rule.
5. Don't forget to check for country specific domains like `youtube.com.au`.


### Someone Else's List

Alternately, you could download / buy [someone else's list](https://www.squidblacklist.org/downloads.html), or [someone else's](https://github.com/StevenBlack/hosts), or [another one](https://disconnect.me/).
In fact, there's a [whole bunch](http://www.malwaredomains.com/) of sites [maintaining malware / advertising lists](https://hosts-file.net/) which could be blocked.

I'm only blocking for a short family holiday, so I'm not parting with money when I can spend 30 minutes working it out for myself.
And in the end, the I'm only blocking a handful os sites.


## Conclusion

<strike>I've ended up choosing the *Firewall Address Lists* option for blocking YouTube.
Plus, using TLS Host based firewall rules to block sub-domains with video content.
This should keep my holiday Internet usage to manageable levels.</strike>

After going on my holiday and testing the various techniques for a few months,
I ended up changing to DNS sinkhole for blocking.
This works really well and is quite easy to turn on and off quickly.

The DNS sinkhole option looks good for blocking ads and tracking sites.
And [Pi-Hole](https://pi-hole.net/) looks like the best way to manage that.

... at some point in the future.

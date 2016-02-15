---
title: Logging Metadata on Free WiFi
date: 2016-02-15 22:40:00  
updated: 
tags:
- WiFi
- Metadata
- Church
- Mikrotik
- Networking
- Privacy
- Netflow
- Nfdump
- Syslog
categories: Technical
---

When you run a free WiFi Access Point, you need to keep logs of network activity to protect your butt.  

<!-- more --> 

At church, we have installed a decent WiFi access point. 
The idea is to let members and guests access the internet during church meetings and to help leaders with their ministry.

But what happens if something goes horribly wrong.
Someone (either a member or guest or random passer-by) decides to use our internet for malicious, nefarious or generally illegal purposes.
And then the police come knocking, looking for someone to "assist them with ongoing enquiries" / arrest. 

In the Anglican church in Sydney, the Senior Minister and Wardens are the people who bare responsibilty for Bad Things™ happening.
People getting hurt, criminal negligence, that kind of thing.

And I'm a warden.

So if the worst happened, I'd be the one up against the wall.
 

## Metadata Logging

So we're going to collect [metadata](http://www.smh.com.au/digital-life/digital-life-news/what-is-metadata-and-should-you-worry-if-yours-is-stored-by-law-20140806-100zae.html) of everyone using our network.
That is, IP addresses, MAC and device addresses, website visited, dates and times of activity, amount of data transferred, and some other things.
So we can point the finger at the actual perpetrator when Bad Things™ happen one day.

And we're going play nice with privacy as well.
This metadata doesn't include the content or detail of what a person has downloaded, but you can figure out an [awful lot](http://www.abc.net.au/news/2015-08-16/metadata-retention-privacy-phone-will-ockenden/6694152) of [personal detail](http://www.abc.net.au/technology/articles/2015/02/19/4183553.htm) via their metadata.
So we assume all metadata is personally identifiable information and treat it as such. 


## What to Log?

At a high level, we want to log enough to say that a particular device accessed particular websites.
And, if they aren't accessing websites, the internet addresses of the other computer involved.
We could push this further and try to link devices to people, but that involves some kind of registration process, issuing access tokens and generally too much book-keeping for our liking.

What this means is we need to collect:

1. **IP Addresses** of all connections - that will give us the remote computer address
2. **MAC Addresses** of all devices - that ties IP addresses to devices

Along with dates and times of everything that happens.

It would be nice to record actual web addresses, but that's not always possible.
Not all traffic goes over HTTP (eg: FTP, DNS), not all traffic is unencrypted (eg: VPNs, HTTPS), not all traffic is even TCP (eg: UDP, ICMP).

 

## How to Log It?

Our access point is a [Mikrotik](http://www.mikrotik.com/) device ([BaseBox2](http://routerboard.com/RB912UAG-2HPnD-OUT)), so we have access to several powerful features:

* Arbitrary firewall rules - you can set firewall rules to simple count bytes / packets
* [Netflow](https://en.wikipedia.org/wiki/NetFlow) logging - this is a Cisco technology which logs details about IP connections
* Syslog - most interesting events on a Mikrotik router generate syslog messages, which we can log remotely
* Remote API - we can examine current access point state from an external computer (perhaps on a regular interval)

Firewall rules are not granular or dynamic enough, so we'll use [netflow](https://en.wikipedia.org/wiki/NetFlow) to log our metadata.
That will get us most of the way to our goal:

* IP Addresses of source and target devices
* Dates and times of activity, at a resolution of between 5 seconds and 5 minutes
* Port numbers of connections (from which we can make a guess at the type of service being used)
* Amount of traffic, in bytes

Netflow logs MAC addresses, but for whatever reason, it was only logging the access point's MAC, which isn't very helpful to our cause. 

Our WiFi access point assigns addresses in the `10.0.0.0/8` private network space randomly, and without a MAC from netflow, we'll need a way to connect a MAC with an IP.
So we turn to syslog to grab more details:
  
* Wireless activity (connections and disconnections) - this includes the device MAC, but not a connection to an IP
* DHCP logs - which ties IP Addresses to MAC addresses, we also get the hostname of the device as a small bonus
* Web proxy requests - if we use a transparent proxy server, we get web addresses

We have everything we need, so no need to use the API at this point.


## A Logging Server

Both syslog and netflow simply send data as UDP datagrams, so an external server for logging is in order.
We have Ubuntu server running on an old PC with a pair of hard disks, for redundancy.

For netflow, we use [nfdump](http://nfdump.sourceforge.net/) to receive and process data.
It consists of a receiver, which receives and saves the raw incoming data from the access point.
And a dump process, which post-processes the raw data into a nice comma separated format.

The receiver, `nfcapd`, runs all the time. It's invoked via a rc.d service during startup:

```
nfcapd -p 9995 -l /var/cache/nfdump/internet -T +10,+11 -t 300 -w -D -e 
```

option | meaning 
-------|--------
-p | listen on port 9995
-l | log raw data to /var/cache/nfdump/internet 
-T | log MAC addresses (didn't really work)
-t | rollover to new files every 300 seconds 
-w | align files to nearest 300 seconds
-D | run as background daemon
-e | expire old files (delete them after 14 days by default)

The `nfdump` dump process runs as a cron job every hour.
Nfdump normally does aggregation, but for our purposes, we're just dumping details.
This command is wrapped in a foreach loop over all the files in `/var/cache/nfdump/internet`.

```
nfdump -r /var/cache/nfdump/internet/datestamped.filename -o csv > /var/nfdump/internet/datestamped.filename.csv
```

For syslog we use the built-in [rsyslog](http://www.rsyslog.com/) used by Ubuntu server. 

I'll confess to not really understanding how rsyslog's config works for remote logging.
I rather shamelessly stole [someone else's config](http://www.thegeekstuff.com/2012/01/rsyslog-remote-logging/) with [some extra hints from here](http://wiki.rsyslog.com/index.php/LongTermLogRotatation).

```
/etc/rsyslog.d/60-remote.conf
 
$template RemoteDatedLogs,"/var/log/remote/%HOSTNAME%/%$YEAR%-%$MONTH%-%$DAY%.syslog.log"
```

This let us keep daily log files and, potentially, support multiple access points / routers.

## Normalising Data 

Syslog and nfdump log their data in rather different formats.
Syslog is human readable, but not easily machine readable (some debug level records span multiple lines).
The nfdump output is comma separated, one record per line.

A key part of the process is to normalise all the data to a known, easy to process format.
In my case, that's a tab separated file, with different record types, and data particular to each record type.
All records have a datestamp.

Record Type | Additional Data
------------|----------------
**WirelessConnection** | Network Interface, MAC Address
**WirelessDisconnection** | Network Interface, MAC Address
**DHCPAssigned** | MAC Address, Assigned IP, Hostname
**DHCPDeassigned** | MAC Address, Assigned IP
**ProxyRequest** | IP Address, URL Requested, HTTP Method / Verb
**NetFlowTraffic** | Connection Duration, Source and Destination IP and Ports, Incoming and Outgoing Packet and Byte counts 
 
This was a custom component written C# (not the best tool for the job I'll admit, but the one I'm most familiar with).
It reads the nfdump and syslog files, parses the records out that we're interested in, makes sure they're all sorted in order and writes them out as a nice tab delimited file.
This process runs each night, a little after midnight.

[Download RemoteTrafficAggregator.zip](/images/Logging-Metadata-on-Free-WiFi/RemoteTrafficAggregator.zip)

DHCP logs, in particular, involved multi-line parsing. Turning this:

```
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet WiFi-Ministry received discover with id 1154724707 from 0.0.0.0
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     ciaddr = 0.0.0.0
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     chaddr = D8:90:E8:34:DF:B8
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     Msg-Type = discover
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     Client-Id = 01-D8-90-E8-34-DF-B8
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     Max-DHCP-Message-Size = 1500
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     Class-Id = "dhcpcd-5.2.10"
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     Host-Name = "android-eb564100d6323453"
Feb 13 17:03:31 192.168.0.5 dhcp,debug,packet     Parameter-List = Subnet-Mask,Static-Route,Router,Domain-Server,Domain-Name,Broadcast-Address,Address-Time,Renewal-Time,Rebinding-Time
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet WiFi-Ministry sending offer with id 1154724707 to 192.168.10.250
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     ciaddr = 0.0.0.0
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     yiaddr = 192.168.10.250
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     siaddr = 192.168.10.1
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     chaddr = D8:90:E8:34:DF:B8
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     Msg-Type = offer
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     Server-Id = 192.168.10.1
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     Address-Time = 691200
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     Subnet-Mask = 255.255.255.0
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     Router = 192.168.10.1
Feb 13 17:03:32 192.168.0.5 dhcp,debug,packet     Domain-Server = 192.168.10.1
```

Into this: 

```
2016-02-13T17:03:32	DhcpAssigned	D8:90:E8:34:DF:B8	192.168.10.250	android-eb564100d6323453	dhcpcd-5.2.10
```


## Archiving and Encrypting

All the above logs are compressed with `bzip2`, ready for long-term archiving.
Each day's logs work out to between 10 and 20MB.
Which works out to around 7GB per year.
We make a copy of everything onto a second HDD in the computer (mounted under `/srv`). 

We keep the normalised logs, and all the raw syslogs and nfdump files. 
I'm pretty sure we've extracted everything useful from the raw logs to the normalised format, but I'm paranoid.
And what's a few more MB on a 200GB hard disk!  

Finally, we get to the privacy part: everything gets encrypted using [Gnu Privacy Guard](https://gnupg.org/) (also [available for Windows](https://www.gpg4win.org/index.html)).
Gnu Privacy Guard is an implementation of [PGP](https://en.wikipedia.org/wiki/Pretty_Good_Privacy) which has one very important property: asymmetic encryption.
That is, we can encrypt the files without any secret passwords on the server.
The decryption key is never stored or even entered on that server.
Which means, even if someone was to pick steal the PC (or download everything via SSH), they cannot read our metadata.

This is what encryption of [data at rest](https://en.wikipedia.org/wiki/Data_at_rest) is all about!    

Finally, these encrypted files are mirrored offsite via SCP/SFTP.
(The way you archive things over 10+ years is keep lots of redundent copies.)


## IPv6 

Although IPv6 is not in use by our church internet provider, it was available in my testing environment (my home network).
It brings a few unique challenges.

The main one is devices will commonly have several IPv6 addresses, and they can be [totally random](https://en.wikipedia.org/wiki/IPv6_address), they aren't assigned using DHCP in most cases, and its possible that every network connection could use a [unique IPv6 address](http://arstechnica.com/security/2016/02/using-ipv6-with-linux-youve-likely-been-visited-by-shodan-and-other-scanners/) for privacy reasons.
In short, connecting IPv6 addresses with MAC addresses is much harder.

Netflow and our Mikrotik access point support IPv6, so they are fine.
But the only way to even try to connect IPv6 address to a MAC is via neighbour discovery (ND).
We'd need to use the Mikrotik API to regularly inspect the access point's ND table.
Probably once per minute.
   

## Querying

The one thing not implemented yet is querying the normalised files.

I expect two basic types of query from a law enforcement agency (beyond "hand over all your metadata"; we'd prefer only give relevent details):

1. Give us all the data you have for `<insert mac address here>`.
2. Give us all the data you have for `<insert remote server ip address here>`.

Both should be easy enough to do for any given date range.

We may also what to get some usage stats.
That is, tell us who's hogging the bandwidth?


## Conclusion

And that's how you do metadata.

We receive raw data from net flow / nfdump and syslogs from wireless and DHCP information (and transparent proxy as a free bonus).
Raw data is normalised to an easy to process format.
All the logs are compressed, encrypted and then mirrored for redundancy.

We have sufficient information to point the finger at a particular device doing naughty things, but the logs are only accessible to people with the correct PGP certificate.
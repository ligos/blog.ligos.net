---
title: On Self-Hosting, Outages and Azure
date: 2017-07-16
tags:
- Hosting
- IIS
- Azure
- Outage
- Self-Hosting
categories: Technical
---

What to do when the power is off all day.

<!-- more --> 

Last week, this blog and [MakeMeAPassword.org](https://makemeapassword.org) were temporarily migrated to Azure due to a long term power outage at my house.

Hopefully, no one noticed (even if my day was highly disrupted).

<img src="/images/On-Self-Hosting-Outages-and-Azure/cause-of-power-outage.jpg" class="" width=300 height=300 alt="I certainly noticed this!" />

This article is how I prepared, migrated to Azure and then migrated back.


## On Self-Hosting

Self-hosting is not something I'd recommend for anyone else, but it works really well for me.

Professionally, I build and maintain websites like [MakeMeAPassword.org](https://makemeapassword.org) which are hosted on IIS.
I support sites hosted on Linux.
And I am often tasked with troubleshooting or migrating websites which involves making DNS or webserver changes.
So I have a considerable working knowledge of what's involved in hosting.

I have bought appropriate hardware for hosting (reliable server, [router](https://routerboard.com/RB2011UiAS-2HnD-IN) and a UPS).
Which lets me run the sites without great drama.
The UPS will let me survive a few minutes of power outage, but not much longer than that - it's mostly there to make sure the server will shut down cleanly.

The best part: self-hosting is extremely cheap.
As in, I pay a bit extra for a static IPv4 address (which I need for work anyway) and a bit more for electricity.
And even the cheapest hosting can't touch that.

(The main difference between my self-hosted setup and real hosting is my ADSL connection is much slower than a real hosting company's network link).


But, when I received a letter saying there would be a power outage for around 7 hours, I knew I'd either have to take considerable down-time, or migrate the sites temporarily.

<img src="/images/On-Self-Hosting-Outages-and-Azure/a-whole-day-of-outage.jpg" class="" width=300 height=300 alt="8am to 4:30pm is more than my UPS can handle!" />


I chose to migrate to Azure for around 24 hours.


## Prepare an Azure VM

Azure lets you rent [virtual machines](https://azure.microsoft.com/en-us/services/virtual-machines/), or [host your sites](https://azure.microsoft.com/en-us/services/app-service/).
The former is basically a computer you rent - called *infrustructure as a service* in the trade. 
The later is more user friendly and provides a better feature set - usually called *software as a service* - but often needs your website to be aware of Azure in some way.

Given *Make Me a Password* uses some low level code to generate random numbers and might not work as an Azure hosted website, I chose a VM.
It might have less features, but it's closest to what I run on my home server.

I also did this several days in advance so I was confident it would work.

The great thing about [Azure](https://azure.microsoft.com), [AWS](https://aws.amazon.com/) and other "cloud" providers is you only pay for servers when you're using them.
Turn them off and they cost nothing!
(Well, almost nothing - the idle disks cost a few dollars each month).
So planned to run the VM for a few hours while I get it working, and then for 24 hours of live hosting.


### 0. Create the VM in Azure

I chose a VM with *Windows Server 2016 Datacenter*.
And configured an **A2_V2** instance with standard storage.
This gives me 4GB of ram, 2 CPU cores and HDDs.
Which costs around $0.21 per hour when hosted in Azure's Australia East data center.
This is more than enough grunt to host the static content on this blog and [MakeMeAPassword.org](https://makemeapassword.org).

For serious Azure usage, you'd want to script all your actions so you can create and tear down virtual infrastructure automatically and in bulk.
But I'm doing this as a one off, so I just used the [Azure management portal](https://portal.azure.com), followed the wizards, accepted most defaults and turned off extras and "premium" features.

You'll need the following:

* An account with Azure.
* A name to give the new server (I used `benny-ligos`, named after [Benny](http://lego.wikia.com/wiki/Benny_(The_LEGO_Movie)).
* A username & password for it.

<img src="/images/On-Self-Hosting-Outages-and-Azure/new-vm-step-1.png" class="" width=300 height=300 alt="New VM - Step 1" />

<img src="/images/On-Self-Hosting-Outages-and-Azure/new-vm-step-2.png" class="" width=300 height=300 alt="New VM - Step 2" />

<img src="/images/On-Self-Hosting-Outages-and-Azure/new-vm-step-3.png" class="" width=300 height=300 alt="New VM - Step 3" />

<img src="/images/On-Self-Hosting-Outages-and-Azure/azure-vm-essentials.png" class="" width=300 height=300 alt="The virgin virtual machine" />


### 1. Some Basic Tools

A VM is just like a normal computer, you just connect to it using an [RDP Client](https://en.wikipedia.org/wiki/Remote_Desktop_Protocol).
I logged on an installed some core apps: [SysInternals](https://technet.microsoft.com/en-us/sysinternals/bb545021.aspx), [Chrome](https://www.google.com/intl/en/chrome/browser/), [Notepad++](https://notepad-plus-plus.org/) and [7-zip](http://www.7-zip.org/).

Oh, and it's always worth making sure any Windows Updates are installed.
(Which always takes longer than I expect).


### 2. Hosting Software

By default, an Azure Windows VM has very little installed.
So I needed to configure the server for hosting websites.
You can find the *Add Windows Features* section in Server Manager -> Local Server -> Manage -> Add Roles and Features.

* IIS and it's required modules for hosting ASP.NET and static content.
* [Web Platform Installer](https://www.microsoft.com/web/downloads/platform.aspx) and [Application Request Routing](https://www.iis.net/downloads/microsoft/application-request-routing) - used for redirects.
* And my [IIS 10 SSL best practices script](/images/On-Self-Hosting-Outages-and-Azure/iis10_tls_best_practices.ps1) - to get the HTTPS stack up to scratch (based on [Alexander Hass's script for IIS 8.5](http://www.hass.de/content/setup-your-iis-ssl-perfect-forward-secrecy-and-tls-12)).

<img src="/images/On-Self-Hosting-Outages-and-Azure/vm-add-iis-features.png" class="" width=300 height=300 alt="Add IIS Features" />


### 3. SSL Certificates

All my websites are encrypted using HTTPS and certificates issued by [LetEncrypt](https://letsencrypt.org).

This presents a small problem as LetsEncrypt requires you use their client app to acquire certs against publicly accessible websites.
However, I can't do this until I migrate the site and make it live.
And that means there will be maybe 10 minutes when the sites won't be accessible until I get new certs.

Fortunately, the raw certificates are saved by the LetsEncrypt app on my server.
So I copied them up to my VM and pre-installed them.

<img src="/images/On-Self-Hosting-Outages-and-Azure/lets-encrypt-certificates.png" class="" width=300 height=300 alt="All My Certificates" />


### 4. Copy the Websites

At this point, I have an environment ready to host some websites.
So time to copy my sites up.

Because I have a slow ADSL connection, I compressed each site with 7-zip and uploaded the compressed files.
Installing the sites is as easy as decompressing them into an appropriate folder.
I usually make a `c:\inetpub\sites` folder and make a folder for each sub-domain in there.


### 5. Configure IIS

I needed to tell IIS some basic details about my sites.
Where their files are, what the domain name(s) are, what certificate to use, and how to run app pools.

I go over this in more details describing [how to host Hexo on IIS](/2016-01-29/Hosting-Hexo-On-IIS.html).

For the most part, I just replicated the same configuration on my home server.


### 6. Test Locally

In theory, it should be working!
To test that I could browse to the sites, I needed to add some entries to the [hosts file](https://en.wikipedia.org/wiki/Hosts_(file)) so the browser can connect to the right site by name.

```
127.0.0.1     makemeapassword.org
127.0.0.1     blog.ligos.net
127.0.0.1     ligos.net
```

And I can browse to the sites!

<img src="/images/On-Self-Hosting-Outages-and-Azure/it-works-vm.png" class="" width=300 height=300 alt="It works! If you're on my VM." />


### 7. Open the VM for Public Access

By default, an Azure VM is not publicly visible as a web server.

I made sure the Windows Firewall allowed HTTP and HTTPS traffic from anywhere on the Internet.
And also used the Azure management console to allow ports 80 and 443 through to the VM.

The Azure Management Portal is a bit of a maze at times, but you're looking for the *Network Security group* -> *Inbound Security Rules*:

<img src="/images/On-Self-Hosting-Outages-and-Azure/azure-vm-network-interfaces.png" class="" width=300 height=300 alt="Firewalls are About Networks..." />

<img src="/images/On-Self-Hosting-Outages-and-Azure/azure-vm-network-security-group.png" class="" width=300 height=300 alt="Network Security Group..." />

<img src="/images/On-Self-Hosting-Outages-and-Azure/azure-vm-inbound-security-rules.png" class="" width=300 height=300 alt="Inbound Security Rules!" />



### 8. Test Remotely

Almost there! There are two remote tests I do before going live:

The easy one is simply trying to connect to the VM's public IP with a web browser.
You should get the IIS welcome page, or your own site if that's how you configured it.

The harder test needs the address in the browser to match the VM's public IP.
A quick change to the my [hosts file](https://en.wikipedia.org/wiki/Hosts_(file)) to manually override `blog.ligos.net` does the trick.

It's very difficult to tell if this is actually talking to the VM because the sites on each server are identical, so I add a server header via the `web.config` file on all my sites so I can tell:

```
<customHeaders>
    <add name="X-svr" value="benny-azure" />
</customHeaders>
```

At this point, I have my site working on an Azure VM and accessible to the world!
Only problem is the world is still looking at my home server.

<img src="/images/On-Self-Hosting-Outages-and-Azure/it-works-hosts-file.png" class="" width=300 height=300 alt="It works! If you're willing to edit an obscure file on your computer." />


### 9. DNS Prep

To tell the world about my new hosting arrangement, I needed to make some DNS changes.
This changed `blog.ligos.net` to point to the new VM.

But I don't want to do this yet, just lay the ground work for when I go live.

Normally, my DNS works like this:

1. `blog.ligos.net` CNAME to `web01.ligos.net`
2. `home.ligos.net` CNAME to `web01.ligos.net`
3. `makemeapassword.org` CNAME to `web01.ligos.net`
4. `web01.ligos.net` CNAME to `loki.ligos.net` 
5. `loki.ligos.net` has address **150.101.201.180**

This means I only need to change `web01.ligos.net` to point to Azure for this to work.

(As an aside, this setup is very deliberate. It's how I quickly switch from hosting on loki to my laptop while I do maintenance on loki).

So, in preparation, I set a DNS name for the public IP address of the VM: `benny-ligos.australiaeast.cloudapp.azure.com`.
You can make this change in the VM *Overview* page -> *Essentials* -> *Public IP Address*.


### 10. Go Live!

After working in IT, software development, and information systems for most of my life, I've learned the best go live plan is the simplest go live plan.
In this case, it's change one DNS record.

The night before the planned power outage, I changed the `web01.ligos.net` CNAME to point to `benny-ligos.australiaeast.cloudapp.azure.com`.

<img src="/images/On-Self-Hosting-Outages-and-Azure/dns-pointing-to-azure.png" class="" width=300 height=300 alt="Its LIVE!" />

I waited half an hour and tested all is working OK (and also tested from my work computer to be sure).

And I went to bed (knowing I'm not going to be awake at 8am on a Saturday morning when the power goes out).


### 11. Revert to Self-Hosted

Fast forward to the end of Saturday when the power came back on at my house, it was time to put things back the way they were.

All this involved was reverting the DNS change in step 10: `web01.ligos.net` CNAME points back to `loki.ligos.net`.
And waiting for an hour while the rest of the world notices the change.

<img src="/images/On-Self-Hosting-Outages-and-Azure/dns-normal.png" class="" width=300 height=300 alt="DNS configuration back to normal." />

Then I turned the Azure VM off, and deleted it.

Total Downtime: **zero**

Total Azure cost: **$8.22** (for around 48 hours of VM usage)


<img src="/images/On-Self-Hosting-Outages-and-Azure/azure-costs.png" class="" width=300 height=300 alt="Downtime avoided for under $10" />

## Conclusion

When you have time to plan for an outage, it's not too hard (or expensive) to lift and shift your services to the cloud.
And by running the two in parallel while DNS cuts over, you get zero downtime.



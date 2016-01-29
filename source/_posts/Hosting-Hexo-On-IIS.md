---
title: Hosting Hexo On IIS
date: 2016-01-29 21:00:00
tags:
- Hexo
- Hexo-Bootstrap-Series
- Blog
- Installation
categories: Technical
---

Part 3 in starting with Hexo: how to deploy to an IIS server for hosting

<!-- more --> 

For all posts in the series, check the **[Hexo-Bootstrap-Series](/tags/Hexo-Bootstrap-Series/)** tag.

As Hexo is entirely static content, hosting is streight forward.
There are no special server requirements to worry about.

I'm hosting on IIS because that's what I am used to and what I have available.
But any other web server will work just as well.
There may have been significant differences hosting static content between Apache, IIS, nginX and others back in the 90s, but those days are long gone.

## Folder Setup

First thing we need is a place to store the generated files.

Create a folder to store your public Hexo files: `blog.ligos.net`. I name my folders based on the domain of the site they host.

<img src="/images/Hosting-Hexo-On-IIS/site-folder.png" class="" width=200 height=200 alt="Site Folder" />

Set permissions on your folder. I only give IIS (via the `IIS_IUSRS` group) read permission, to reduce the impact of any security breach. But also gave ordinary users write access, so I can maintain the site. 

<img src="/images/Hosting-Hexo-On-IIS/folder-security.png" class="" width=200 height=200 alt="Set Your Permissions" />

Share the folder so I can update the site. This was via an SMB share on the `inetpub` folder, but on Linux would probably be via ssh / sftp / scp.

<img src="/images/Hosting-Hexo-On-IIS/inetpub-share.png" class="" width=200 height=200 alt="Allow SMB Access" />

## IIS Setup

Next part is to configure IIS to serve requests.

Create an IIS app pool. I already had one for static content, so I used it, but otherwise I name them the same as the domain its hosting. I've got a few more details on app pools below.

<img src="/images/Hosting-Hexo-On-IIS/app-pool.png" class="" width=200 height=200 alt="One Pool for All Static Content" />

Then create a new web site.
 
I name my sites based on their domain.
Make sure you choose the app pool you just created.
And the folder.
Finally, add an HTTP binding.

<img src="/images/Hosting-Hexo-On-IIS/new-site-settings.png" class="" width=200 height=200 alt="New Site Details" />


### App Pools, In Brief

If you're not familiar with [app pools](http://stackoverflow.com/questions/3868612/what-is-an-iis-application-pool), they determine a bunch of low level settings for your site
IIS hosts websites in a process called `w3wp.exe` (or *www worker process*), and your app pool drives some key attributes of that process.
Things like what user does the website run as (the w3wp.exe process runs as that user), or what bit-ness the process is (32 or 64).
Putting different websites in different app pools will isolate them from one another. 
There are also a bunch of IIS specific settings like when an app pool is recycled, what happens when its idle.    


A couple of useful changes to app pool defaults:

* **Enable 32-bit applications**: `true` -  causes the hosting process to be 32 bit, which keeps memory usage down (and you really don't need more than 2GB of RAM to serve static content). 
* **Start Mode**: `AlwaysRunning` - starts the hosting process when IIS starts, which makes things a bit faster for your first visitor.   
* **Idle Timeout**: `60 min` - time before IIS says the site is idle and kills it. 
* **Idle Timeout Action**: `Suspend` - pages the IIS process to disk on idle, which is faster than killing the process (only on IIS 8.5 and higher). 
* **Recycling Regular Time Interval**: `10000` - static content processes shouldn't need to be recycled, so make this number large.
* **Recycling Specific Times**: `none` - again, static content processes shouldn't need to be recycled.

<img src="/images/Hosting-Hexo-On-IIS/app-pool-details1.png" class="" width=200 height=200 alt="App Pool Settings For My StaticContent Pool" />

<img src="/images/Hosting-Hexo-On-IIS/app-pool-details1.png" class="" width=200 height=200 alt="More App Pool Settings" />

Setting ACLs on your folders based on an `ApplicationPoolIdentity` is a bit tricky, [ServerFault has a helpful answer](http://serverfault.com/questions/81165/how-to-assign-permissions-to-applicationpoolidentity-account). 


## Generation and Deployment

Now we have a site ready to go, but no files.

Hexo makes this process very easy.
We previously used `hexo generate` to create all the files needed in the `public` folder.
Now all we need is to copy that content to the folder we created.

With a simple batch file, I'm generating then using [robocopy](https://technet.microsoft.com/en-us/library/cc733145.aspx) to mirror the `public` folder to my `blog.ligos.net` folder on my server.

```
call hexo generate
robocopy public \\loki\inetpub\sites\blog.ligos.net /mir /r:1 /w:1 
```

Note that on Windows, you need to use the `call` command to run Hexo, as hexo is actually a batch file on Windows.
Yet another quirk of scripting on Windows (sigh). 

## DNS

You need to tell the internet that your blog's domain name points to an IP address before it will work.

This will vary between DNS hosting providers, but you'll either need to create an **A record** (which says blog.ligos.net points to my IP address; I also have a **AAAA record** which does the same for IPv6), or a **CNAME record** (which says blog.ligos.net points to some.server.ligos.net). 

I went for the **CNAME** option, because I have several domains all on the one server. 

If you don't have a DNS provider (or you're sick of your current one) I'll recommend [DNSimple](https://dnsimple.com/) as a simple, hassle free, reasonably priced DNS provider.

## It Works!

At this point, everything should be working.
You can point your web browser to your domain name and you should see your site!

<img src="/images/Hosting-Hexo-On-IIS/site-working.png" class="" width=300 height=300 alt="It Works!" />

At this point, we're almost finished.

## HTTPS

Next step is to serve the site over HTTPS.
You'll need an appropriate [certificate](https://en.wikipedia.org/wiki/Public_key_certificate) before you can do this.
I'm using [StartSSL](https://startssl.com), which will issue free SSL certificates for domains using email based validation.

Once you have your certificate installed on your server, you add another binding to your site.
I'm using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) so I can host multiple HTTPS based sites behind my one IP address.

Note that you need to be on IIS 8.5 or newer to use SNI (Windows 8.1 / Server 2012 R2).

<img src="/images/Hosting-Hexo-On-IIS/https-binding.png" class="" width=300 height=300 alt="HTTPS binding" />

Once saved, you can browse to your HTTPS site and get a nice padlock. 

<img src="/images/Hosting-Hexo-On-IIS/site-working-https.png" class="" width=300 height=300 alt="It Works! (Now with 100% more encryption)" />

And, even better than that, because I'm on Windows 10 and IIS 10, I get [HTTP/2](https://en.wikipedia.org/wiki/HTTP/2) support.
Yay for being on the cutting edge!

## Redirect HTTP to HTTPS

I want the site to be secure and encrypted by default, so we need to add a redirect from HTTP -> HTTPS.
You can do this in the IIS configuration, but the GUI isn't great. 
So I prefer to drop a web.config in.

The below `web.config` becomes part of my Hexo content, in the `source` folder.
As far as Hexo is concerned, its just a file to publish.
But IIS picks it up and issues an appropriate 301 permanent redirect whenever someone visits the site via unencrypted HTTP. 

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="Https redirect" stopProcessing="true">
                    <match url="(.*)" />
                    <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
                    <conditions>
                        <add input="{HTTP_HOST}" pattern="^blog.ligos.net$" />
                        <add input="{HTTPS}" pattern="^OFF$" />
                    </conditions>
                </rule>			
            </rules>
        </rewrite>
        <httpProtocol>
            <customHeaders>
                <remove name="X-Powered-By" />
            </customHeaders>
        </httpProtocol>
    </system.webServer>
</configuration>
```

You also need to install the [IIS URL Rewrite Module](http://www.iis.net/downloads/microsoft/url-rewrite) before this will work.

## Gotcha 1 - Insecure Content

The Hueman theme had a reference to load jQuery using HTTP, which browsers refused to load from my shiny HTTPS site.
Basically, if you have a secure site, everything needs to be loaded via the secure HTTPS url scheme.
If you generated code using PHP or ASP or whatever, you could dynamiclly generate the scheme.
But there's a better way, which works entirely in the browser:

* This only works on unencrypted sites (HTTP): `http://code.jquery....`
* This only works on secure sites (HTTPS): `https://code.jquery....`
* This works on either, which I what I want: `//code.jquery....`

``` html
<script src="//code.jquery.com/jquery-2.1.3.min.js"></script>
```

## Gotcha 2 - Google Site Auth File

Now the site was public, I registered it with Google and Bing's webmin tools.
They need you to add a magic file to prove you really own the site (otherwise you could just claim you owned Google itself and muck with things).

Bing gives you an XML file, which I added to the `source` folder and deployed without problem.

Google gives you an HTML file, which I added to the `source` folder and deployed.
Only, when I published my site, I found that Hexo thought the site auth file was content, and wrapped it in the usual header, sidebar and footer.

Needless to say, Google webmin wasn't impressed.

I needed to explicitly tell Hexo not to render Google's magic file: 

``` yaml
skip_render: 
- google0123456789abcdef.html
```

## Gotcha 3 - Case Sensitivity

OK, I'd actually noticed this much earlier in the process.

I'd test my site using the local `hexo server` command.
And images wouldn't load.

After much checking of HTML source, it turns out that Hexo's internal web server is case sensitive.
That is `my-image.png` and `My-Image.png` and `My-Image.PNG` are treated as different things. 

IIS (and pretty much every other web server I'm aware of) is case insensitive, so all three images would mean the same thing.

So now, all my snipping tool generated images need to have their all caps *PNG* changed to lower case

## Conclusion

Serving static content isn't hard.
So hosting Hexo is nice and easy too.
And once I've worked through a few gotchas, all was working well.

Next time: how authoring works in Hexo
 
  



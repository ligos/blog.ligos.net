---
title: Reverse Proxy With IIS and Lets Encrypt
date: 2016-11-14
updated: 2018-01-02
tags:
- IIS
- Reverse Proxy
- Lets Encrypt
- HTTPS
- web.config
- Certify 
categories: Technical
---

How to proxy another site through IIS with a Lets Encrypt certificate.

<!-- more --> 

## Background 

Setting up a [reverse proxy](https://en.wikipedia.org/wiki/Reverse_proxy) web server means you have one web server, that the world talks to.
And that server then talks to another one on the world's behalf.

<img src="/images/Reverse-Proxy-With-IIS-And-Lets-Encrypt/640px-Reverse_proxy_h2g2bob.svg.png" class="" width=300 height=300 alt="Diagram credit to H2g2bob, from Wikipedia" />


### Why Bother

This sounds like a whole lot of work. So what benefits do you get?

The main reasons I do this are:

* To allow public access to an otherwise unencrypted site or device (eg: my Raspberry Pi camera is HTTP only, but IIS lets me wrap it in HTTPS)
* To use Lets Encrypt for certificate management (eg: [PRTG Network Monitor](https://www.paessler.com/) supports HTTPS, but Lets Encrypt is 100 times easier to manage)  
* To control access more finely (eg: allow an internal only `ligos.local` domain to connect without a password, but require a login for a public `ligos.net` connection)
* To run multiple distinct web servers on different ports on the same computer, but access them without custom ports (eg: `site.ligos.net` instead of `server.ligos.net:8443`).

## How To

I'm using IIS because I have it available on my Windows server... errr... always on desktop.
However, [Nginx](http://nginx.org/) and [Apache](https://httpd.apache.org/) are equally capable of reverse proxy (and will perform better on a Linux box).

### Step 0 - Install IIS and prerequisites

Before we add a site, you need to enable IIS and install the **Application Request Routing** module to allow reverse proxy.
IIS is only available for Windows Pro SKUs, so if you only have Windows Home you'll need to use a different web server.  

In Windows 10 Pro, you enable IIS by searching for *Windows Features*, which will find the *turn Windows Features on or off* widget.
It's still an old Windows 7 style app (unless you're using Windows Server).

There are lots of components you can install for IIS. 
The following are a pretty minimal set which will allow you to reverse proxy, plus other useful features:

* Web Management Tools -> IIS Management (x3)
* World Wide Web Services -> Application Development Features -> ISAPI Extensions and Filters
* World Wide Web Services -> Common HTTP Features -> Default Document  
* World Wide Web Services -> Common HTTP Features -> HTTP Errors
* World Wide Web Services -> Common HTTP Features -> HTTP Redirection
* World Wide Web Services -> Common HTTP Features -> Static Content
* World Wide Web Services -> Health and Diagnostics -> HTTP Logging
* World Wide Web Services -> Performance Features -> Static and Dynamic Content Compression
* World Wide Web Services -> Security -> Basic Authentication
* World Wide Web Services -> Security -> IP Security
* World Wide Web Services -> Security -> Request Filtering

<img src="/images/Reverse-Proxy-With-IIS-And-Lets-Encrypt/install-iis.png" class="" width=300 height=300 alt="You have to turn IIS on before you can use it" />

Installing *Application Request Routing* is easiest via the [Web Platform Installer](https://www.microsoft.com/web/downloads/platform.aspx). 

**Updated 2018-01-02**

You also need to enable the *Application Request Routing* proxy to actually do the reverse proxy.
If this isn't enabled, you'll end up getting 404 errors with no obvious reason why.

Open *Application Request Routing* on your root web server -> *Proxy Server Settings* -> tick *Enable Proxy*.

<img src="/images/Reverse-Proxy-With-IIS-And-Lets-Encrypt/arr-proxy-enabled.png" class="" width=300 height=300 alt="This needs to be ticked before things work" />


### Step 1 - Create a folder for the site

Although the server isn't actually going to serve any content, IIS still needs a folder to store a web.config file.
Somewhere like `c:\inetpub\sites\site.ligos.net` or `x:\websites\site.ligos.net` works for me.
The folder should be readable by `IIS_IUSRS` group (or whatever user your Application Pool runs as).

### Step 2 - Create the site in IIS

Fire up the IIS management console and add a new site.

I always name sites based on their DNS name (if they have multiple DNS names or aliases, then I use the primary one).
And I have a heavily re-used [Application Pool](http://stackoverflow.com/questions/3868612/what-is-an-iis-application-pool) for static content, which does not have .NET enabled and is very light on resources.
At this point, only enable an HTTP endpoint.

Note: there are ways to [create IIS sites via Powershell](https://www.iis.net/learn/manage/powershell/powershell-snap-in-creating-web-sites-web-applications-virtual-directories-and-application-pools), but I don't create new sites often enough to warrant scripting.

<img src="/images/Reverse-Proxy-With-IIS-And-Lets-Encrypt/iis-site-config.png" class="" width=300 height=300 alt="A new IIS site" />

If you are using IIS for the first time, you should probably check all is working by dropping a basic `index.html` page in. 

### Step 3 - Add DNS records and network rules

You can't visit a website without a DNS record (OK, you can, but not the site we'll be creating).
Make sure you add an appropriate `A`, `AAAA`, or `CNAME` record for your new site.

You may also need to allow network access to your server through your router, usually by *port forwarding* ports 80 and 443 (HTTP and HTTPS respectively).
I've got my Mikrotik router configured to do *hairpin NAT* or *reflection*, which is like port forwarding but for my internal network (it makes the external IP address appear like its my internal server's IP address, so I can browse to `site.ligos.net` and it just works).

You may also need to contact your ISP as mine blocked common ports like 80 and 443 by default. 

### Step 4 - Add web.config with Reverse Proxy rules

You can add the reverse proxy rules through the management interface, but I find it easier to drop in a template `web.config` file and edit it directly.  

Start with the following (we'll enable the first couple of commented out rules soon):

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
		<staticContent>
			  <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="1.00:00:00" />
		</staticContent>		
        <rewrite>
            <rules>
            <!--
                <rule name="Https redirect" stopProcessing="true">
                    <match url="(.*)" />
                    <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
                    <conditions>
                        <add input="{HTTP_HOST}" pattern="^prtg.ligos.net$" />
                        <add input="{HTTPS}" pattern="^OFF$" />
                    </conditions>
                </rule>				
                <rule name="LetsEncrypt" stopProcessing="true">
                    <match url=".well-known/acme-challenge/*" />
                    <conditions logicalGrouping="MatchAll" trackAllCaptures="false" />
                    <action type="None" />
                </rule>
            -->
                <rule name="ReverseProxyInboundRule1" stopProcessing="true">
                    <match url="(.*)" />
                    <conditions logicalGrouping="MatchAll" trackAllCaptures="false">
                        <add input="{HTTP_HOST}" pattern="^prtg.ligos.net$" />
                    </conditions>
                    <action type="Rewrite" url="https://localhost:8443/{R:1}" />
                </rule>
			</rules>
        </rewrite>
        <httpProtocol>
            <customHeaders>
                <remove name="X-Powered-By" />
                <add name="strict-transport-security" value="max-age=16070400" />
            </customHeaders>
        </httpProtocol>
    </system.webServer>
</configuration>

```

The important part for *reverse proxy* is this part:

``` xml
<rule name="ReverseProxyInboundRule1" stopProcessing="true">
    <match url="(.*)" />
    <conditions logicalGrouping="MatchAll" trackAllCaptures="false">
        <add input="{HTTP_HOST}" pattern="^prtg.ligos.net$" />
    </conditions>
    <action type="Rewrite" url="https://localhost:8443/{R:1}" />
</rule>
```

This tells the IIS URL rewrite engine to match everything for the `prtg.ligos.net` host and proxy it through to localhost on port 8443, keeping the path and query string the same.
Essentially, it's translating between `prtg.ligos.net` and `https://localhost:8443`.

You'll need to use your site's address, of course.   

The web.config file also has support for static content caching, removing the *powered by IIS* site header, and adding a [HSTS header](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security) (which won't do anything until HTTPS is enabled).

<img src="/images/Reverse-Proxy-With-IIS-And-Lets-Encrypt/site-folder.png" class="" width=300 height=300 alt="The very minimal reverse proxy folder" />

### Step 6 - Add an exclusion rule for Lets Encrypt 

Before we can get a certificate from Lets Encrypt, we need to require one path to **not** reverse proxy.

Uncomment the rule below in your web.config file:

``` xml
<rule name="LetsEncrypt" stopProcessing="true">
    <match url=".well-known/acme-challenge/*" />
    <conditions logicalGrouping="MatchAll" trackAllCaptures="false" />
    <action type="None" />
</rule>
```

This disables the reverse proxy for the special [well known acme-challenge folder](https://letsencrypt.github.io/acme-spec/), which Lets Encrypt uses to check your site's ownership.  

### Step 7 - Use Certify to get a Lets Encrypt certificate

Before you can serve HTTPS requests you need a certificate, which we can get for free with minimal fuss with [Lets Encrypt](https://letsencrypt.org/).

Windows support for Lets Encrypt is not that great, but I've found [Certify](http://certify.webprofusion.com/) works pretty well, even though it is in alpha.
Rick Strahl has a [good summary of other Lets Encrypt clients](https://weblog.west-wind.com/posts/2016/Feb/22/Using-Lets-Encrypt-with-IIS-on-Windows) if Certify isn't to your liking.

Certify will look at the sites hosted on IIS and generate a certificate from Lets Encrypt.
Pretty much all you have to do is chose the right site, and click *Request Certificate*.

<img src="/images/Reverse-Proxy-With-IIS-And-Lets-Encrypt/certify-request.png" class="" width=300 height=300 alt="Getting an SSL certificate was never so easy!" />

### Step 8 - Check the site is using HTTPS and the right Certificate

If Certify does everything right, it will automatically add an HTTPS binding for your site with the certificate you just acquired.

Unfortunately, Certify isn't quite perfect and doesn't always get things right.
So it pays to check your IIS bindings for the site.

<img src="/images/Reverse-Proxy-With-IIS-And-Lets-Encrypt/iis-site-config-after-certify.png" class="" width=300 height=300 alt="HTTPS binding and certificate" />


### Step 9 - Add an HTTP to HTTPS redirect

HTTPS and encrypting everything is fast becoming the default, but most web browsers will still try connecting via unencrypted HTTP first.

Uncomment the top rule to add a redirect when there are any HTTP requests to the equivalent HTTPS page.

``` xml
<rule name="Https redirect" stopProcessing="true">
    <match url="(.*)" />
    <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
    <conditions>
        <add input="{HTTP_HOST}" pattern="^prtg.ligos.net$" />
        <add input="{HTTPS}" pattern="^OFF$" />
    </conditions>
</rule>				
```

## Conclusion

Running a reverse proxy enables additional levels of flexibility, security or functionality.

Configuring your site to be reverse proxied and use Lets Encrypt is a powerful combination. 
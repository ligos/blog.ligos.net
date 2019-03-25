---
title: Fixing Nginx proxy_pass DNS errors
date: 2019-03-25
tags:
- Linux
- Nginx
- Hosting
- DNS
- Pi-Hole
- Debian
- systemd
categories: Technical
---

Webservers that fail on startup make me sad.

<!-- more --> 

## Background

After [migrating all my hosting](/2019-03-09/Migrating-From-IIS-to-Nginx.html) to Debian 9 + Nginx on an old laptop, everything was going really nicely.

Until the weekly scheduled reboot failed.

And I got a message from Uptime Robot that all my hosting was down.
At 5am.

I fixed the immediate problem by doing a `sudo service nginx start`, but I don't like servers that won't reboot cleanly.
They're a recipe for disaster, and I don't like 5am disasters.


## The Problem

When Nginx started up, there was an error when parsing configuration which caused it to fail:

```
2019/03/15 04:37:36 [emerg] 658#658: host not found in upstream 
"loki.ligos.local" in /etc/nginx/sites-enabled/loki.ligos.net:38
```

The config for this line is:

```
server {
    location / {
        proxy_pass "http://loki.ligos.local";
    }
}
```

`loki.ligos.net` is a reverse proxy site of my old Windows based web server.
But Nginx couldn't do a host name lookup for it, and failed.
Where *failed* = crashed hard and stopped serving all web requests.


## The Solution

So how to solve this?

### Possible Solution #0: Host File

Before I did any research at all (that is, at 6am when I restarted Nginx as started getting ready for work) I naively thought I could just add `loki.ligos.net` to `/etc/hosts` and the problem would go away.

It didn't.

Because [Nginx doesn't look at the hosts file](https://stackoverflow.com/questions/29980884/proxy-pass-does-not-resolve-dns-using-etc-hosts), only a real DNS server.

### Possible Solution #1: A Custom Resolver & Variable

OK, if the really obvious didn't work, I'll try the collective knowledge of the Internet!

There were several posts on [blogs](https://www.jethrocarr.com/2013/11/02/nginx-reverse-proxies-and-dns-resolution/) and [Stack](https://unix.stackexchange.com/questions/397727/systemd-nginx-does-not-resolve-etc-hosts-entries-at-boot-time) [Exchange](https://serverfault.com/a/593003) that all proposed essentially the same solution:
Nginx doesn't cope with a failed DNS lookup when it parses its config, so make sure it has a valid DNS server!

That is, install dnsmasq (`apt install dnsmasq`) and change your config like so:

```
# Tell Nginx to use local dnsmasq server
resolver 127.0.0.1;         
# The variable forces Nginx to periodically refresh the address.
set $url "http://loki.ligos.local";      
# Finally, do the proxy_pass.
proxy_pass $url;
```

Unfortunately, my webserver is also my [pi-hole](https://pi-hole.net) server.
I can't run dnsmasq because pi-hole is already running a caching DNS server!

But why not just try the variable thing anyway.
So I modified my config.

And it didn't work: same error.


### Digression - Read the Log File

Darn.
If the Internet can't magically fix my problem, what's a man to do!?!?!

So I got out my old troubleshooting hat and started poking around in log files.
`/var/log/syslog` was my first (and last) place to look.


```
Mar 15 04:37:34 cadbane kernel: [   11.552726] Adding 3004412k swap on /dev/sda5.  Priority:-1 extents:1 across:3004412k FS
Mar 15 04:37:34 cadbane kernel: [   13.257599] intel ips 0000:00:1f.6: i915 driver attached, reenabling gpu turbo
Mar 15 04:37:34 cadbane systemd[1]: Starting LSB: pihole-FTL daemon...
Mar 15 04:37:34 cadbane systemd[1]: Starting Atop process accounting daemon...
Mar 15 04:37:34 cadbane systemd[1]: Started irqbalance daemon.
```

OK, that looks like systemd starting up the pi-hole DNS server (`pihole-FTL`).
I decided to confirm that really is the DNS server using `sudo netstat -n -p -l`, which gives me a list of addresses, ports and programs which are listening for network connections.

```
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:53              0.0.0.0:*               LISTEN      806/pihole-FTL
tcp6       0      0 :::53                   :::*                    LISTEN      806/pihole-FTL
udp        0      0 0.0.0.0:53              0.0.0.0:*                           806/pihole-FTL
udp6       0      0 :::53                   :::*                                806/pihole-FTL
```

Yep, `pihole-FTL` is definitely a DNS server.
Let's continue with `syslog`:


```
Mar 15 04:37:34 cadbane kernel: [   13.813397] Process accounting resumed
Mar 15 04:37:34 cadbane pihole-FTL[566]: Not running
Mar 15 04:37:34 cadbane cron[572]: (CRON) INFO (pidfile fd = 3)
```

A bit further down and `pihole-FTL` logs that it isn't running.
Well, that's not entirely helpful.

Keep looking:


```
Mar 15 04:37:35 cadbane systemd[1]: Starting Permit User Sessions...
Mar 15 04:37:35 cadbane systemd[1]: Starting A high performance web server and a reverse proxy server...
Mar 15 04:37:35 cadbane systemd[1]: Started LSB: IPv4 DHCP client with IPv4LL support.
Mar 15 04:37:35 cadbane systemd[1]: anacron.timer: Adding 3min 18.689713s random time.
Mar 15 04:37:35 cadbane systemd[1]: Started Permit User Sessions.
```

That line with *Starting A high performance web server and a reverse proxy server* is where Nginx starts.
Of course, whoever configured Nginx's systemd unit made really sure it wouldn't log "Nginx" anywhere on startup, because that would make troubleshooting too easy.
Sigh.

However, this started me thinking: pihole-FTL has started but isn't running yet (and presumably can't do DNS lookups) and Nginx is starting to load.
Perhaps Nginx really can't do DNS lookups because DNS isn't ready yet.

Keep looking:

```
Mar 15 04:37:40 cadbane systemd[1]: Started User Manager for UID 999.
Mar 15 04:37:41 cadbane nginx[658]: nginx: [emerg] host not found in upstream "loki.ligos.local" in /etc/ngi
nx/sites-enabled/loki.ligos.net:38
Mar 15 04:37:41 cadbane nginx[658]: nginx: configuration file /etc/nginx/nginx.conf test failed
Mar 15 04:37:41 cadbane systemd[1]: nginx.service: Control process exited, code=exited status=1
Mar 15 04:37:41 cadbane systemd[1]: Failed to start A high performance web server and a reverse proxy server.
Mar 15 04:37:41 cadbane systemd[1]: nginx.service: Unit entered failed state.
Mar 15 04:37:41 cadbane systemd[1]: nginx.service: Failed with result 'exit-code'.
```

Ahh! 
There's the Nginx failure, a few seconds further into the log.
And nothing more logged from `pihole-FTL`.

And the very next log message:

```
Mar 15 04:37:43 cadbane pihole-FTL[566]: FTL started!
Mar 15 04:37:43 cadbane systemd[1]: Started LSB: pihole-FTL daemon.
```

So, it appears my DNS server takes 2 seconds too long to start.
And Nginx can't cope.

On a hunch, I kept looking:

```
Mar 15 04:37:44 cadbane dhclient[543]: DHCPDISCOVER on enp19s0 to 255.255.255.255 port 67 interval 16
Mar 15 04:37:44 cadbane sh[507]: DHCPDISCOVER on enp19s0 to 255.255.255.255 port 67 interval 16
Mar 15 04:37:44 cadbane dhclient[543]: DHCPREQUEST of 10.46.130.31 on enp19s0 to 255.255.255.255 port 67
Mar 15 04:37:44 cadbane sh[507]: DHCPREQUEST of 10.46.130.31 on enp19s0 to 255.255.255.255 port 67
Mar 15 04:37:44 cadbane sh[507]: DHCPOFFER of 10.46.130.31 from 10.46.130.1
Mar 15 04:37:44 cadbane dhclient[543]: DHCPOFFER of 10.46.130.31 from 10.46.130.1
Mar 15 04:37:44 cadbane dhclient[543]: DHCPACK of 10.46.130.31 from 10.46.130.1
Mar 15 04:37:44 cadbane sh[507]: DHCPACK of 10.46.130.31 from 10.46.130.1
Mar 15 04:37:44 cadbane dhclient[543]: bound to 10.46.130.31 -- renewal in 1448 seconds.
Mar 15 04:37:44 cadbane sh[507]: bound to 10.46.130.31 -- renewal in 1448 seconds.
```

OK, my server doesn't even have an IP address until 3 seconds after Nginx fails.
Which explains why DNS isn't working - it has to do a real network call over to my router where my `*.ligos.local` entries are kept.
So even if I could magically make `pihole-FTL` load faster, it wouldn't help because I don't have a network yet.


### Possible Solution #2: Start Nginx After DNS

It looks like the root cause of my problems is the Nginx is starting too early.
If I can convince it to load a bit later (like after the network is up and after `pihole-FTL` is working) it might be happier.

Sigh.
Time to wrap my head around [systemd](https://en.wikipedia.org/wiki/Systemd).
Strangely, the [Arch Linux wiki page for systemd](https://wiki.archlinux.org/index.php/Systemd) gives a concise list of what systemd does and what commands you can give it (the list assumes you already know what half the commands do, but its a place to start).
[Digital Ocean](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files) had a reasonable reference as well.

After some digging, I found that `sudo systemctl status nginx` give me a hint of where to find the *unit* definition for Nginx.
Otherwise known as the *startup config file*.

```
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

The `After` directive under `[Unit]` determines when Nginx is started: after the network target.
That is, when the network is up.
Of course, "when the network is up" doesn't mean "when then network is ready to send & receive traffic" (aka "online"), just enough to bind to an IP address / port.

If I can convince Nginx to load after `pihole-FTL`, that might fix things.

After some digging, the "systemd" way to edit config files is: `sudo systemctl edit nginx`.
Which dumps you into `nano` with a blank unit file (not entirely obvious what needs to happen next).
But apparently you can "override" the stock definition with your own.
I gave it a go:

```
# Force Nginx to load after our DNS comes up, which can take a few seconds.
[Unit]
After=pihole-FTL.service
Requires=pihole-FTL.service
```

I couldn't tell the difference between `After` and `Requires`, but Arch Linux's example used both, so I did the same!


### Possible Solution #3: Restart Nginx if it Crashes

After a bit of reading about unit files, it seems you can tell *systemd* what to do if a service fails.
That makes sense, given a good part of *systemd's* job is managing system wide services (not too different from the [Windows Services](https://en.wikipedia.org/wiki/Windows_service) I'm familiar with).

Once again, `sudo systemctl edit nginx` and add the following:

```
# Restart Nginx if it crashes.
[Service]
Restart=on-failure
TimeoutSec=15
```

And, after all my changes, apparently I need to `sudo systemctl enable nginx`.

### Which Solution Did I Choose?

All of them!!

Why put all my eggs in one basket?
I switched to an Nginx variable, so the DNS name can change.
I fixed the service dependencies so Nginx starts after pihole-FTL.
And, I set the Nginx service to restart after 15 seconds if it crashes.

Hopefully, at least one of those will keep it running!

## Result

At this point I decided to reboot the server and see if its working.
Nginx loaded without a problem.
Content of `/var/log/syslog`:


```
Mar 17 22:28:33 cadbane pihole-FTL[567]: FTL started!
Mar 17 22:28:33 cadbane systemd[1]: Started LSB: pihole-FTL daemon.
Mar 17 22:28:33 cadbane systemd[1]: Starting A high performance web server and a reverse proxy server...
Mar 17 22:28:35 cadbane systemd[1]: Started A high performance web server and a reverse proxy server.
```

Perfect!
`pihole-FTL` completes its loading sequence, and Nginx start up right afterwards.

Most importantly, it doesn't crash!


## Conclusion

Any server I manage must restart cleanly and without any human intervention.
In the case of my new Debian web server, that means changing the start order of services so that DNS will be up and running before Nginx.
Now I have a basic understanding of systemd unit files, and have a more reliable server.
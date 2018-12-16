---
title: Debian 9.5 Stretch - Basic Installation
date: 2018-12-16
tags:
- Debian
- Basics
- Installation
categories: Technical
---

It's a bit more involved than Ubuntu.

<!-- more --> 

## Background

A project I'm working on needs a Linux server.
Previous, I've used [Ubuntu Server](https://www.ubuntu.com/download/server) for all my Linux server needs (mostly in a professional environment). 
But I'd read a few [Debian](https://www.debian.org/) recommendations, and because Ubuntu is "Debian plus", I felt reasonably comfortable taking the step away from my most familiar Linux environment.
Also [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about) has [Debian](https://www.microsoft.com/en-us/p/debian-gnu-linux/9msvkqc78pk6) as a distribution, so I'd actually been using it for 6 months before I tried a real Debian install.

So, for the next time I need to install Debian, here are my notes.

I'm installing [Debian 9.5 "Stretch"](https://www.debian.org/News/2018/20180714). 
Although a [9.6 version](https://www.debian.org/News/2018/20181110) is available now with various security rollups (regular `apt upgrade` keeps you up to date for point updates).


## Install

I chose the text mode installer, and the wizard stepped me through things well enough.
I didn't try very complex partitioning; just a `/` root partition plus a separate `/home` partition.

I enabled full disk encryption, which meant I needed LVM, and the installer just made it work.

And I removed all the "desktop environment" options, but added an SSH server.

## Something New: ip address

I've been typing `ifconfig` to get network information since the late '90s.
So when `ifconfig` was nowhere to be found, I small amount of panic started rising in me.

Apparently, there's a new `ip` command, which follows the recent convention of command + sub-commands.
So, `ip` lets you do all kinds of TCP/IP related network things.

But I care about `ip address`, to get my current IP address.
Or, the shortened form: `ip a`.

Crisis. Averted.


## Things You Really Need to Install

A bare Debian install doesn't have very much installed.
And for a server environment, that's a good thing - I can install just what I need and worry less about random (potentially dangerous) programs which were installed by default.

This does lead to a small amount of frustration when you realise that pretty much everything you want to do must be preceded with `apt install some-thing`.
But I'll live.

So here's a list of things not included in the base install, which are pretty essential.

### sudo

This really surprised me, `sudo` isn't installed by default!

So, you either need to do a console root login, or use `su` with your root password to get root access to install `sudo`.

And don't forget to add yourself to the *sudoers* group.

```
$ su
$ apt install sudo
$ adduser myuser sudoers
```

### ssh

OpenSSH server is an option during the install process (which I chose).
However, there are some important settings to change in `/etc/ssh/sshd_config`.

* **PasswordAuthentication**: change to `Off`, to disable any password based logins.
* **AllowTcpFowarding**: change to `Off`, to disable SSH tunnelling (unless you want to use SSH tunnelling as a poor-man's VPN).
* **X11Forwarding**: change to `Off`, as I'm not installing X.

Additional references for tightening up an OpenSSH installation:

* https://stribika.github.io/2015/01/04/secure-secure-shell.html
* https://sshcheck.com/

You may also want to consider regenerating host keys to be longer, or to disable *ecdsa* keys entirely.
See `ssh-keygen` and the links above.

Oh, and I always forget the spelling / location of `~/.ssh/authorized_keys`, where public authentication keys are installed.

### ufw

Servers exist to be accessed over a network.
And firewalls exist to allow or deny access to said network.

I've never really got my head around `ipchains`, so I install `ufw` (the uncomplicated firewall) to make my life a bit easier.

```
$ sudo apt install ufw
$ sudo ufw enable
```

By default, everything is blocked.
You use `ufw allow` to allow access per port, and `ufw status` to see the current state of the world.

```
$ sudo ufw allow 22
$ sudo ufw allow 80
$ sudo ufw allow 443

$ sudo ufw status
Status: active

To                         Action      From
--                         ------      ----
22                         ALLOW       Anywhere
80                         ALLOW       Anywhere
443                        ALLOW       Anywhere
22 (v6)                    ALLOW       Anywhere (v6)
80 (v6)                    ALLOW       Anywhere (v6)
443 (v6)                   ALLOW       Anywhere (v6)
```

### net-tools

This is where things like `netstat` hide.

```
$ sudo apt install net-tools
```

### curl

Yes, I like to be able to download stuff.

```
$ sudo apt install curl
```

### apt-transport-https

The standard Debian packages installed via `apt install` are served over http.
That's fine, because they're all signed by a PGP key, and their contents aren't exactly sensitive.
But some 3rd party `dpkg` repositories are hosted over https, and you need to teach `apt` how to talk https.

```
$ sudo apt install apt-transport-https
```

### fail2ban

Anything with publicly accessible services needs a rate limit for failed logins.
And `fail2ban` does just that: after some number of invalid logins, a firewall rule is added to ban the IP address.

I followed some [instructions at Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-debian-7) for getting my `fail2ban` up and going.

```
$ sudo apt install fail2ban
$ sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
$ sudo nano /etc/fail2ban/jail.local
```

I changed the config to ban after 10 failed logins, and to ban for 12 hours, and to include my local network IP addresses as exclusions.

```
# "ignoreip" can be an IP address, a CIDR mask or a DNS host. Fail2ban will not
# ban a host which matches an address in this list. Several addresses can be
# defined using space (and/or comma) separator.
ignoreip = 127.0.0.1/8, 192.168.1.0/24, 2001:1234:4321:ff00::/64

# "bantime" is the number of seconds that a host is banned.
# 12 hours
bantime  = 43200

# A host is banned if it has generated "maxretry" during the last "findtime"
# seconds.
findtime  = 600

# "maxretry" is the number of failures before a host get banned.
maxretry = 10
```


### rsync

`rsync` is useful for lots of things that involve moving data around efficiently.

```
$ sudo apt install rsync
```

### Unattended Upgrades

Automatically installing security updates is very, very important.
Anything publicly accessible absolutely must have security updates applied automatically.

Debian has a [documentation page for unattended upgrades](https://wiki.debian.org/UnattendedUpgrades).

```
$ sudo apt install unattended-upgrades
```

The doco page lists several config files you should review.
I didn't need to make significant changes to any of them; most items they highlighted were already set out of the box:

* /etc/apt/apt.conf.d/50unattended-upgrades
* /etc/apt/apt.conf.d/20auto-upgrades
* /etc/apt/apt.conf.d/02periodic

I'm from a Windows background and frequent reboots help all kinds of strange problems just disappear.
Habit is hard to break, so I added a weekly reboot in `/etc/crontab`.
Because I have full disk encryption enabled, I need to chose a time carefully when I'd be available to type the passphrase in: Sunday mornings around 8am are pretty safe.

```
3  8    * * 7   root    reboot now
```


### nginx

I like having a basic webserver and a static page to identify servers; just enough to know I'm talking to the right box.
Plus, most servers end up hosting some minimal amount of web content at some point.
If you're very concerned about security, don't do this, as it increases attack surface.

I'm making an effort to learn `nginx`, but you could use the venerable `apache` instead if you want (or one of the [thousand other web servers](https://en.wikipedia.org/wiki/Comparison_of_web_server_software) out there).

Debian has split `nginx` into 3 flavours: *light*, *full* and *extras*.
*Light* is enough for static content.
A summary of differences are at the [Debian nginx wiki page](https://wiki.debian.org/Nginx).

```
$ sudo apt install nginx-light 
```


## Things I Needed for my Project

My particular project involves hosting user content.
I've more briefly outlines additional packages I installed below.

Obviously, the whole point of the minimal install Debian does is you can pick and choose the things you need based on what you need your server to do.
So only install the minimum packages you need.

### Disk Quota

Disk quotas make sure users have a limited amount of disk space available to them.

Documentation from [Debian Handbook](https://debian-handbook.info/browse/stable/sect.quotas.html) and [How to Forge](https://www.howtoforge.com/tutorial/linux-quota-ubuntu-debian/).

Using disk quota involves:

* Install `quota` package.
* Edit `/etc/fstab` to enable quota for a particular file system; reboot.
* Run `quotacheck -cug /mount_point` to update the accounting info.
* Use `setquota` to actually set a quota for a user.
* Use `repquota /mount_point` to see current usage.

### Syncthing

[Syncthing](https://syncthing.net/) is a peer-to-peer file syncronisation app similar to [Resilio / BitTorrent Sync](https://www.resilio.com/).
It's a fantastic way to securely replicate content between devices.

My main use-case is for backups.

* There's an [apt repository](https://apt.syncthing.net/) for Debian based distributions.
* [Getting started documentation](https://docs.syncthing.net/intro/getting-started.html).
* [Firewall documentation](https://docs.syncthing.net/users/firewall.html).
* The trickiest bit is [installing Syncthing as a service / daemon](https://docs.syncthing.net/users/autostart.html#linux).

### .NET Core

My primary development environment is C# and .NET.
.NET Core is the best supported way to run .NET on Debian.

* Microsoft has [installation instructions](https://www.microsoft.com/net/download/linux-package-manager/debian9/runtime-2.1.2) from an apt repository.

The alternative to .NET Core is [Mono](https://www.mono-project.com/).

### ClamAV

Linux is not immune to malware.
And servers are an attractive target for any bad guy: unattended, often poorly monitored, high bandwidth, and beefy system resources.

[ClamAV](http://www.clamav.net/) is a malware scanner for Linux.

Documentation from [Debian Admin](http://www.debianadmin.com/clamav-installation-and-configuration.html) and [Debian Wiki](https://wiki.debian.org/ClamAV).

I found the ClamAV doco to assume you already know how ClamAV works.
My biggest hint is you want the daemon (although the doco says its optional).

Review the config file `/etc/clamav/clamd.conf`.

I added a crontab job for regular scans:

```
# Daily ClamAV scan
3  18   * * *   root    /usr/bin/clamscan -r /home >> /var/log/clamav/daily-scan.log 2>&1
```

### SELinux

I think I need [SELinux](selinuxproject.org/) to implement mandatory access controls, but the [Debian Wiki for SELinux](https://wiki.debian.org/SELinux/) look... complicated.
I'll make a note to revisit it later.

### Password Policy

Apparently you need to install `libpam-cracklib` to enforce a decent password policy.

And then edit `/etc/pam.d/common-password` and set some rather unintuitive properties.

Documentation from [Xmodulo](http://xmodulo.com/set-password-policy-linux.html) and [nixCraft](https://www.cyberciti.biz/faq/securing-passwords-libpam-cracklib-on-debian-ubuntu-linux/).


## Conclusion

Debian is quite similar to Ubuntu, after all, Ubuntu is built on top of Debian.
Generally, Debian is a much more bare bones environment, lots of tools I take for granted are not part of the default Debian install.

Fortunately, pretty much everything is an `apt install` away (optional: editing config files).

To borrow a terrible Lego illustration: Ubuntu gives you a pretty complete model car, and you can add things if you want but its quite OK out of the box. Debian gives you a chassis and wheels, and you get to build the car how you want.
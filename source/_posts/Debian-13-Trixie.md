---
title: Debian 13 Trixie
date: 2026-08-01
tags:
- Debian
- Basics
- Installation
- Server
- Desktop
- Virtual Machine
- QEMU
categories: Technical
---

A reference to install Debian for servers and desktops.

<!-- more --> 

## Background

I have been using [Debian Linux](https://www.debian.org/) for [some time on my home servers](/2018-12-16/Debian-9.5-Stretch-Basic-Installation.html), and more recently on my personal laptop. I tried [Linux Mate](https://www.linuxmint.com/) as a [desktop option](/2025-05-02/Moving-To-Linux-Mint-BluRay-Burner.html), but was disappointed in a few respects. So, I've switched to Debian as my standard Linux distribution.

This post is a bit of a personal reference guide for installing Debian as a server (headless computer) or desktop (interactive graphical environment).

## Goal

Install and configure Debian Trixie (v13) for a desktop and server environment.

## Initial Installation

You can read the [official documentation to install Debian](https://www.debian.org/releases/stable/installmanual), which is very detailed and mostly irrelevant. Or choose one of the [many online guides available](https://duckduckgo.com/?t=ffab&q=debian+install+guide&ia=web). I find the installation wizard (either text or graphical) easy enough to follow.

You will need to download Debian and copy to a USB memory stick for installation. I use [Ventoy](https://www.ventoy.net/en/index.html) as a way to load many ISOs for Linux distros onto a single USB.

All my devices are given names of [characters from Star Wars](https://en.wikipedia.org/wiki/Lists_of_Star_Wars_characters) - I choose a name before starting installation. I also create passphases for any users and assign an IP address on my network.

### Servers

<img src="/images/Debian-13-Trixie/examples-of-servers.jpg" class="" width=300 height=300 alt="Some of my servers. They might look like laptops or desktops, but they are most definitely servers!" />

A server installation has no graphical user interface, and usually no text interface (except when things go horribly wrong). I tend to use old laptops or workstations as "servers". Laptops have a nice built in UPS and screen, but often lack the IO I desire (can't install enough disks). Desktops have more powerful CPUs and allow for at least 3 disks. In all cases, initial installation requires a screen and keyboard. I don't use VMs because I don't have a beefy server - [physicalisation](https://en.wikipedia.org/wiki/Physicalization) for me, not virtualisation.

- I choose the text mode installation for servers (to avoid plugging in a mouse). 
- I install everything on a root partition `/`. Critical data ends up on separate disks (usually [zfs](https://en.wikipedia.org/wiki/OpenZFS)).
- I don't select a desktop environment, but I add the SSH server option. 
- And I create a separate `root` user, and then a user for myself (which will get `sudo` privileges later).

#### SSH Access

After installation, the first priority is to get SSH access via my public key working. That means I can disconnect the monitor and keyboard used during installation. I do a connection to whatever dynamic IP the server was assigned on first boot and install the public key in `~/.ssh/authorized_keys`. Once verified, I assign an IP via a DHCP reservation and remove the keyboard & monitor.

### Desktops

<img src="/images/Debian-13-Trixie/examples-of-desktops.jpg" class="" width=300 height=300 alt="Some laptops running Debian." />

Desktop installations have a graphical interface. In 2026 they are more likely to be laptops than desktops, but the graphical component means I consider them equivalent.

- I choose the graphical install.
- I create separate `/` and `/home` partitions. On my laptop, `/` is 200GB, which has ~50GB of data on it. And `/home` is 700GB. 50GB for `/` is pretty big, but I prefer to err on the side of bigger.
- If you create a separate `root` user, that means all users can be unprivileged and you need to use the root password for anything that requires admin rights. Otherwise, the initial user will have `sudo` permission with their own password.
- I install the desktop environment with **KDE**, but see below for some more discussion of which desktop environment might work best for you.

#### Which Desktop Environment?

If you are coming from Windows or Mac, you will be used to having one desktop environment and if you don't like it then bad luck (there are alternatives, but I have never seriously tried using them). With Debian (and most Linux distributions) you can choose your environment.

[GNOME](https://www.gnome.org/) seems to be affiliated with Debian and is the default choice. But you can also choose [KDE](https://kde.org/), [MATE](https://mate-desktop.org/), [Cinnamon](https://www.linuxmint.com/), [Xfce](https://xfce.org/) and others.

- **Gnome** is similar to Mac, so if you're coming from a Mac background, it should be familiar.
- **KDE** is similar to a Windows 10 environment, so if you're from a Windows background, it should be familiar.
- **MATE** is a bit of a cross between Windows and Mac.
- **Cinnamon** is closely associated with Linux Mint. No experience.
- **Xfce** is a light weight environment, which I prefer for USB rescue environments. Never tried it for day-to-day use though.

You can install each environment and try them out. I did that with Gnome and KDE, and found that KDE is quite close to what I was used to with Windows 10, and Gnome was different enough I didn't like it. Your experience might be different.


## Server Packages

Here's a full list of packages for servers (except for things marked as optional):

```sh
$ apt install htop ufw sudo net-tools rsync curl apt-transport-https fail2ban unattended-upgrades unzip
```

Note that many of these packages require some additional configuration.

### Sudo

In the Debian base install, `sudo` isn't installed by default!

Use `su` with your root password to get root access to install `sudo`.

And don't forget to add yourself to the *sudo* group.

```sh
$ su
$ apt install sudo
$ /sbin/usermod -aG sudo myuser
```

### Htop

Htop is a better version of `top`, which shows system resource usage and currently running processes.

```sh
$ apt install htop
```

I also configure the system widgets to show more compact CPU usage, GPU usage (if relevant), disk IO, network IO, zfs ARC (if relevant), the systemd status, and system label. Also, to use _Tree View_ by default, to hide kernel and user threads, and to show CPU frequency.

<img src="/images/Debian-13-Trixie/htop-config.png" class="" width=300 height=300 alt="Htop Configuration" />

### SSH Server

There are some important settings to change in `/etc/ssh/sshd_config` once public key logins are working:

- **PasswordAuthentication**: change to `Off`, to disable any password based logins.
- **AllowTcpFowarding**: change to `Off`, to disable SSH tunnelling (unless you want to use SSH tunnelling as a poor-man's VPN).
- **X11Forwarding**: change to `Off`, as I'm not installing X.

You may want to use [SSH Check](https://sshcheck.com/) to, well, check your SSH config via an external scan.

### Firewall

Servers exist to be accessed over a network.
And firewalls exist to allow or deny access to said network.
Even desktops and laptops need a firewall to keep the Big Bad Internet™️ from doing bad things.

I've never really got my head around `ipchains`, so I install `ufw` (the uncomplicated firewall) to make my life a bit easier.

```sh
$ apt install ufw
$ ufw enable
```

By default, everything is blocked.
You use `ufw allow` to allow access per port, and `ufw status` to see the current state of the world.

```sh
$ ufw allow 22
$ ufw allow 80
$ ufw allow 443

$ ufw status numbered
Status: active

To                         Action      From
--                         ------      ----
[ 1] 22                         ALLOW       Anywhere
[ 2] 80                         ALLOW       Anywhere
[ 3] 443                        ALLOW       Anywhere
[ 4] 22 (v6)                    ALLOW       Anywhere (v6)
[ 5] 80 (v6)                    ALLOW       Anywhere (v6)
[ 6] 443 (v6)                   ALLOW       Anywhere (v6)
```

For services I only access internally, I will remove any IPv6 rules to prevent access from the wider internet.

```sh
$ ufw delete 4

$ ufw status numbered
Status: active

To                         Action      From
--                         ------      ----
[ 1] 22                         ALLOW       Anywhere
[ 2] 80                         ALLOW       Anywhere
[ 3] 443                        ALLOW       Anywhere
[ 4] 80 (v6)                    ALLOW       Anywhere (v6)
[ 5] 443 (v6)                   ALLOW       Anywhere (v6)
```

You can block and allow based on source IPs, which is another way to only permit access from your internal network. The exact commands for this get tricky, so I refer to [DigitalOcean's guide to ufw](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands).

For desktops, I'll often block everything. Maybe with the exception of [syncthing](https://syncthing.net/) or [bittorrent](https://en.wikipedia.org/wiki/BitTorrent).

### Fail2ban

Anything with publicly accessible services needs a rate limit for failed logins, to avoid the bad guys brute forcing logins.
This is what `fail2ban` does: after some number of invalid logins, a firewall rule is added to ban the IP address.

I followed some [instructions at Digital Ocean](https://www.digitalocean.com/community/tutorial-collections/how-to-protect-ssh-with-fail2ban) for getting my `fail2ban` up and going.

```sh
$ apt install fail2ban
$ cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
$ nano /etc/fail2ban/jail.local
```

I changed the config to ban after 10 failed logins, and to ban for 12 hours, and to include my local network IP addresses as exclusions.

```txt
# "ignoreip" can be an IP address, a CIDR mask or a DNS host. Fail2ban will not
# ban a host which matches an address in this list. Several addresses can be
# defined using space (and/or comma) separator.
ignoreip = 127.0.0.1/8, 192.168.1.0/24, 2001:1234:4321:ff00::/64

# "bantime" is the number of seconds that a host is banned.
# 12 hours
bantime  = 12h

# A host is banned if it has generated "maxretry" during the last "findtime"
# seconds.
findtime  = 10m

# "maxretry" is the number of failures before a host get banned.
maxretry = 10
```

### Unattended Upgrades

Automatically installing security updates is very, very important.
Anything publicly accessible absolutely must have security updates applied automatically and promptly.

Debian has a [documentation page for unattended upgrades](https://wiki.debian.org/UnattendedUpgrades).

```sh
$ apt install unattended-upgrades
```

The doco page lists several config files you should review. I don't bother; everything seems to work.

### Regular Reboot

I'm from a Windows background and frequent reboots help all kinds of strange problems just disappear.
Habit is hard to break, so I added a weekly reboot in `/etc/cron.d/weekly-reboot`. I prefer Sunday morning reboots, as I'm usually available early on Sunday if something doesn't restart cleanly.

```
3  5    * * 7   root    reboot now
```

### Net Tools

This is where things like `netstat` hide.

```sh
$ apt install net-tools
```

### Curl

Yes, I like to be able to download stuff. Sometimes I don't want to use `wget` (which is part of the standard install).

```sh
$ apt install curl
```

### Rsync

`rsync` is useful for lots of things that involve moving data around efficiently, including backups.

```sh
$ apt install rsync
```

### Unzip

Tar, gz, bz2 and xz are more common forms of compression on Linux (and installed by default), but occasionally you need to deal with a zip file.

```sh
$ apt install unzip
```

### Aptitude and HTTPS

The standard Debian packages installed via `apt install` are served over http.
That's fine, because they're all signed by a PGP key, and their contents aren't exactly sensitive.
But some 3rd party `dpkg` repositories are hosted over https, and you need to teach `apt` how to talk https.

```sh
$ apt install apt-transport-https
```

### Things That Are Not Packages

Some useful tools are available as packages, but quite out of date. So I prefer a manual installation.

A good place to put these is in `/usr/local/bin/<folder>`.

- [RClone](https://rclone.org/) is like `rsync`, but can connect to pretty much every local or cloud filesystem imaginable (and several I couldn't imagine). Again, very handy for backups or moving files around.
- [FFMpeg](https://ffmpeg.org/) is available as a package, but if you want the fastest encoders then you should grab a more recent version.

### ZFS (optional)

I have a [much longer post about ZFS](/2019-08-24/Experimenting-With-ZFS.html), but here are the essentials. Note this is optional, but I care deeply about the data on my servers, so most servers end up with zfs. Also, I don't use zfs on root because its more complex (but seems to be better supported these days).

See the [OpenZFS guide](https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/index.html) for more details.

Debian 13 (Trixie) doesn't require `backports` to use zfs (but does allow access to a newer version). You do need `contrib` which is usually included by default - please check `/etc/apt/sources.list` has `contrib` in your package lists:

```txt
deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security trixie-security/updates main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security/updates main contrib non-free non-free-firmware
```

```sh
$ apt install dpkg-dev linux-headers-generic linux-image-generic
$ apt install zfs-dkms zfsutils-linux
$ /sbin/modprobe zfs
```

This should give you a working zfs kernel module.

Next, set your max ARC size (in bytes; below examples is 4GB) in `/etc/modprobe.d/zfs.conf`:

```sh
options zfs zfs_arc_max=4294967296
```

Create the pool with some reasonably sane defaults:

```sh
$ zpool create -o ashift=12 -m /mnt/zfsdata zfsdata mirror \
                   /dev/disk/by-id/... \ 
                   /dev/disk/by-id/...
$ zpool status -v
$ zpool list -v

$ zfs set relatime=on zfsdata
$ zfs set compression=on zfsdata
$ zfs set dedup=off zfsdata
```

Finally, create datasets for each application:

```sh
$ zfs create zfsdata/application_name
```

You will also need to configure a `systemd` maintenance scrub task:

```txt
$ cat /etc/systemd/system/zfs-scrub.timer

[Unit]
Description=Weeky zpool scrub

[Timer]
OnCalendar=weekly
AccuracySec=1h
Persistent=true

[Install]
WantedBy=multi-user.target


$ cat /etc/systemd/system/zfs-scrub.service

[Unit]
Description=Weekly zpool scrub

[Service]
Nice=19
IOSchedulingClass=idle
KillSignal=SIGINT
ExecStart=/sbin/zpool scrub zfsdata
```

And do the `systemctl` dance to turn them on:

```sh
$ systemctl daemon-reload
$ systemctl enable zfs-scrub.timer
$ systemctl start zfs-scrub.timer
$ systemctl start zfs-scrub.service
```


## Desktop Packages - Debian

Unlike servers, desktop environments have at least three sources for packages: first party Debian packages (part of the standard `aptitude` / `dpkg` system), third party Debian packages (via a package source for 3rd party repository), and flatpak packages. Generally, Debian packages are fine for services, libraries, and terminal apps. But for graphical apps, flatpak tends to provide newer versions and a better experience, except when the app is distributed via a 3rd party Debian package server.

Here's a full list of first party packages for desktops:

```sh
$ apt install htop ufw sudo net-tools rsync curl apt-transport-https unzip xrdp fonts-recommended ttf-mscorefonts-installer
```

Note that many of these packages require some additional configuration. If they aren't listed below, you can see details above in the server section.

### Xrdp

While ssh works for a console login, graphical logins require a different service. I tried VNC approaches on Linux in the past and they were all painful. [Xrdp](https://www.xrdp.org/) just worked. I find it ironic that a Microsoft protocol worked best on Linux, but the Windows Home SKU disabled RDP.

```sh
$ apt install xrdp
$ ufw allow 3389
```

You will need an RDP client to connect. I use [Remmina](https://remmina.org/), but you can also use [FreeRDP](https://www.freerdp.com/).

### Fonts

One of the major differences between Windows and Linux is fonts. You might have the same browser and equivalent office suite, but without the same fonts everything will look rather different.

Download key Windows fonts from [mscorefonts-extra repo](https://github.com/gustavomdsantos/mscorefonts-extra) as a `dpgk` file, and install using:

```sh
$ dpkg -i mscorefonts-extra_1.0_all.deb
```

Note that these fonts are licensed from Microsoft. You can also install the `fonts-recommended` package to pick up open licensed equivalent fonts:

```sh
$ apt install fonts-recommended
```

See also further details from [LinuxCapable](https://linuxcapable.com/how-to-install-microsoft-fonts-on-debian-linux/) and [Arch Wiki](https://wiki.archlinux.org/title/Microsoft_fonts).


## Desktop Packages - Third Party

Many apps are available via Aptitude if you install their custom repository. Generally, this involves adding a GPG key (to verify downloads) and a source file to include the 3rd party package repo. Optionally, you can pin the new source to prioritise it over the standard packages.

### Firefox

Firefox is my preferred browser. Debian includes the ESR release by default, but I prefer something that updates more frequently like `firefox-beta`. [Instructions to configure `/etc/apt` are provided](https://support.mozilla.org/en-US/kb/install-firefox-linux)

Firefox is also available via [flathub](https://flathub.org/en/apps/org.mozilla.firefox).

### Brave

Brave is a Chromium based browser. Unfortunately, some websites require a Chromium browser to work. This makes me sad, but it is the way of the Internet.

Brave provides [a magic install script and manual instructions to configure `/etc/apt`](https://brave.com/linux/).

Brave is also available via [flathub](https://flathub.org/en/apps/com.brave.Browser).

### Syncthing

[Syncthing](https://syncthing.net/) is important for me to sync files between devices.

An older version is provided in standard Debian packages, or [instructions to configure `/etc/apt` are provided](https://apt.syncthing.net/) if you want the latest version.

### VSCode

[Visual Studio Code](https://code.visualstudio.com/) is the most common IDE in a Linux environment. Also doubles as a powerful text editor!

[A magic deb file is provided to configure `/etc/apt`, or there are manual instructions](https://code.visualstudio.com/docs/setup/linux).

### Wine

Wine is not an emulator, but it does allow you to run many Windows apps directly on linux without a virtual machine. There is a whole rabbit hole of related apps ([Proton](https://github.com/ValveSoftware/Proton), [Bottles](https://usebottles.com/), and more), but for the handful of Windows apps I need, basic Wine works just fine.

[Instructions to configure `/etc/apt` are provided](https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu).

Once installed, you can use `winecfg` to configure wine, `wine control` to show the control panel, and invoke apps using `wine program.exe` or `wine setup.exe`.

```sh
$ winecfg
$ wine control
$ wine program.exe
$ wine setup.exe
```

More details are available on the [Wine User's Guide](https://gitlab.winehq.org/wine/wine/-/wikis/Wine-User's-Guide).


## Desktop Packages - Flatpak

[Flatpak](https://flatpak.org/) provides an app store like experience for Linux, particularly graphical apps. [Instructions are provided](https://flathub.org/en/setup/Debian), but it is available as a first party package, so nice and easy to install!

```sh
$ apt install flatpak plasma-discover-backend-flatpak
$ flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

Once installed, you can browse available applications at [Flathub](https://flathub.org/en).

### KeepassXC

The Linux equivalent of [KeePass](https://keepass.info/) is [KeepassXC](https://keepassxc.org/). [Available on flathub](https://flathub.org/en/apps/org.keepassxc.KeePassXC).

```sh
$ flatpak install flathub org.keepassxc.KeePassXC
```

### ONLYOFFICE Desktop Editors

[LibreOffice](https://www.libreoffice.org/) is installed by default, but I've realised how many quality of life improvements Microsoft has made since Office 2000: LibreOffice is functional, but not fantastic. 

The unfortunately named _ONLYOFFICE Desktop Editors_ is [available on flathub](https://flathub.org/en/apps/org.onlyoffice.desktopeditors). Its interface in much closer to modern MS Office, but I'm still evaluating its overall goodness.

```sh
$ flatpak install flathub org.onlyoffice.desktopeditors
```

### Discord

[Discord](https://discord.com/) is a chat platform used by a number of communities I'm involved in. [Available on flathub](https://flathub.org/en/apps/com.discordapp.Discord).

```sh
$ flatpak install flathub com.discordapp.Discord
```

### Chrome / Chromium

Google [Chrome](https://flathub.org/en/apps/com.google.Chrome) and [Chromium](https://flathub.org/en/apps/org.chromium.Chromium) are both available on flathub. I'm not a fan of Google's dominance of the browser market, but they are available if desired.


### VLC

[VLC](https://www.videolan.org/vlc/) is the all purpose media player. While there are plenty of pre-installed players with Debian, VLC is the one that will play anything. [Available on flathub](https://flathub.org/en/apps/org.videolan.VLC).

```sh
$ flatpak install flathub org.videolan.VLC
```

### Pinta

[Pinta](https://www.pinta-project.com/) seems to be a clone of my go-to image editor on Windows: [paint.net](https://paint.net/index.html). [Available on flathub](https://flathub.org/en/apps/com.github.PintaProject.Pinta).

```sh
$ flatpak install flathub com.github.PintaProject.Pinta
```

### Hugin

I have used Hugin for many years to create panoramas from photos. I've never had much luck with panoramas in native phone apps, so I just take photos and let Hugin make the panorama later. [Available on flathub](https://flathub.org/en/apps/net.sourceforge.Hugin).

```sh
$ flatpak install flathub net.sourceforge.Hugin
```

### Thunderbird

My preferred email client is [Thunderbird](https://www.thunderbird.net/). Old but reliable. [Available on flathub](https://flathub.org/en/apps/org.mozilla.thunderbird). 

```sh
$ flatpak install flathub org.mozilla.thunderbird
```

### FileZilla

For uploading files via SFTP, there is [FileZilla](https://filezilla-project.org/). [Available on flathub](https://flathub.org/en/apps/org.filezillaproject.Filezilla).

```sh
$ flatpak install flathub org.filezillaproject.Filezilla
```

### Remmina

For VNC and RDP graphical connections, [Remmina](https://remmina.org/) is a nice all-in-one package. [Available on flathub](https://flathub.org/en/apps/org.remmina.Remmina).

```sh 
$ flatpak install flathub org.remmina.Remmina
```

### WinBox

For management of my Mikrotik routers, WinBox is (ironically) available as a cross platform app. [Available on flathub](https://flathub.org/en/apps/com.mikrotik.WinBox).

```sh 
$ flatpak install flathub com.mikrotik.WinBox
```

### Things That Are Not Packages

As with the server environment, there are a few useful apps which aren't part of any package management system. I will install these in either `~/.local/bin` or `/usr/local/bin`, depending on if they auto-update on their own.

### yt-dlp

[YT-DLP](https://github.com/yt-dlp/yt-dlp) downloads media from YouTube and other platforms for offline viewing. This auto updates, so it goes in `~/.local/bin/yt-dlp`



## Virtual Machines

Even after native Linux apps and wine, there are some applications which really need a real copy Windows to function nicely - the big one is MS Office, which has no perfect substitute on Linux when you need the exact same behaviour as regular Windows users. 

We need a virtual machine to support this. I use [KVM](https://linux-kvm.org/page/Main_Page) and [QEMU](https://www.qemu.org/) because it is well supported out of the box, and works to get Windows 10 VMs up and running.

I'm using the [Debian KVM](https://wiki.debian.org/KVM) and [Computing for Geeks](https://computingforgeeks.com/how-to-install-kvm-virtualization-on-debian/) and the [Arch QEMU](https://wiki.archlinux.org/title/QEMU) pages as a reference.

```sh
$ apt install qemu-system libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager cpu-checker ovmf virtiofsd
$ adduser <youruser> libvirt
$ adduser <youruser> kvm
```

That should get the core software installed.

There is a lot of detail on the pages above about getting networking perfect. I originally tried for weeks to make it work, and eventually gave up and used the default NAT based configuration. Every other option I tried ended up messing with my laptop's WiFi or Ethernet connections. And I never had the need to run a public facing service on the VM. But that is just my usage.

You will need a Windows license and disk image (iso) to install your VM. I use [Tiny 10](https://archive.org/details/tiny-10-23-h2) and don't bother activating it given most computers I install Debian on have an OEM license already (technically, this is not 100% correct, but I doubt MSFT will care). This is sufficient for the handful of Windows apps I use.

You also need a usable [VirtIO iso for Windows](https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md) which contain drivers for para-virtualisation features of KVM. This improves network and disk performance, but also allows shared memory features to mount local folders and copy&paste integration (both very handy). I used the latest version rather than stable.

I use _Virtual Machine Manager_ as the GUI for managing my VMs. There are command line options available if that's more your thing.

<img src="/images/Debian-13-Trixie/virtual-machine-manager-no-vms.png" class="" width=300 height=300 alt="Virtual Machine Manager with no VMs" />

Be sure to customise the configuration of your new VM so you **mount both** the windows iso and VirtIO iso. During installation, you should load custom drivers, which will pick up the magic VirtIO driver from the iso, and will use that as part of the installation. From there you can add VirtIO based devices whenever required. But getting the boot driver correct up front will save **much** mucking about later. See also the [Arch page for Preparing a Windows Guest](https://wiki.archlinux.org/title/QEMU#Preparing_a_Windows_guest).

You may need to choose UEFI firmware when installing. It should be available in `/usr/share/OVMF`.

<img src="/images/Debian-13-Trixie/virtual-machine-config-two-cdroms.png" class="" width=300 height=300 alt="Virtual Machine Config Before Windows Install" />

Partial XML config is given below, where I have selected VirtIO for disk and network:

```xml
<domain type="kvm">
  <name>win10</name>
  <uuid>ecfc70b8-333a-4836-b7fd-22b2097e9ebf</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://microsoft.com/win/10"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory>3145728</memory>
  <currentMemory>3145728</currentMemory>
  <memoryBacking>
    <source type="memfd"/>
    <access mode="shared"/>
  </memoryBacking>
  <vcpu>2</vcpu>
  <os>
    <type arch="x86_64" machine="q35">hvm</type>
    <loader readonly="yes" type="pflash">/usr/share/OVMF/OVMF_CODE_4M.ms.fd</loader>
    <boot dev="hd"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv>
      ...
    </hyperv>
    <vmport state="off"/>
  </features>
  <cpu mode="host-passthrough"/>
  <clock offset="localtime">
    ...
  </clock>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2" discard="unmap"/>
      <source file="/var/lib/libvirt/images/win10.qcow2"/>
      <target dev="vda" bus="virtio"/>
    </disk>
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <source file="/mnt/data/isos/tiny10 x64 23h2.iso"/>
      <target dev="sdb" bus="sata"/>
      <readonly/>
    </disk>
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <source file="/mnt/data/isos/virtio-win-0.1.285.iso"/>
      <target dev="sdc" bus="sata"/>
      <readonly/>
    </disk>
    <controller type="usb" model="qemu-xhci" ports="15"/>
    <controller type="pci" model="pcie-root"/>
    <interface type="network">
      <source network="default"/>
      <mac address="52:54:00:ef:b7:f2"/>
      <model type="virtio"/>
    </interface>
    <console type="pty"/>
      <target type="virtio" name="com.redhat.spice.0"/>
    </channel>
    <input type="tablet" bus="usb"/>
    <tpm model="tpm-crb">
      <backend type="emulator" version="2.0"/>
    </tpm>
    <graphics type="spice" port="-1" tlsPort="-1" autoport="yes">
      <image compression="off"/>
    </graphics>
    <sound model="ich9"/>
    <video>
      <model type="qxl"/>
    </video>
    <redirdev bus="usb" type="spicevmc"/>
    <redirdev bus="usb" type="spicevmc"/>
  </devices>
</domain>
```

Here we tell Windows to use the VirtIO driver:

<img src="/images/Debian-13-Trixie/install-windows-10-select-viostor-driver.png" class="" width=300 height=300 alt="Installing Windows 10 - Selecting the viostor driver for VirtIO storage" />

Once Windows is installed, you should install all the other VirtIO drivers from the ISO via `virtio-win-gt-x64.msi` and `virtio-win-guest-tools.exe`. That should enable mouse & keyboard capture and clipboard sharing. You can then remove the CDROM devices from the VM configuration.

You can install the [virtiofs drivers / service](https://virtio-fs.gitlab.io/howto-windows.html) in Windows and share a folder from your Linux host directly on your Windows VM. You will need to add _Filesystem_ hardware to your VM. Your home folder works well for data exchange. Note that only one _Filesystem_ is supported in Windows. [More information if you get stuck](https://www.heiko-sieger.info/sharing-files-between-the-linux-host-and-a-windows-vm-using-virtiofs/).

<img src="/images/Debian-13-Trixie/virtual-machine-config-filesystem-home.png" class="" width=300 height=300 alt="Virtual Machine Configuration for a Filesystem Share" />

I also recommend using sysinternals [AutoLogin](https://learn.microsoft.com/en-us/sysinternals/downloads/autologon) to avoid tedious logins. This makes your Windows VM as close to an "application" as you can get.

After all that, you should have the core of a Windows VM with good IO, network and graphics performance, as well as clipboard and filesystem sharing. Time to install the Windows apps you need!

<img src="/images/Debian-13-Trixie/virtual-machine-windows-10.png" class="" width=300 height=300 alt="Windows 10 Virtual Machine Up and Running!" />

## Conclusion

There are plenty of things I like to install on Debian 13 Trixie. This is a big reference for me, and hopefully, some useful pointers for others.
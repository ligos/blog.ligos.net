---
title: NextPVR, Samba, Windows and Re-Encoding TV
date: 2019-06-07
tags:
- Linux
- Debian
- Samaba
- Windows
- CIFS
- Mount
- Video
- Transcoding
- Handbrake
- .NET Core
categories: Technical
---

Making Linux talk to Windows and encode videos.

<!-- more --> 

## Background

I run [NextPVR](http://www.nextpvr.com/
) on my Windows media computer / file server.
It replaced the old [Windows Media Centre](https://en.wikipedia.org/wiki/Windows_Media_Center) when it got depracated in Windows 10.
And it does a fine job of recording over the air broadcast digital TV ([OTA DTv](https://www.otadtv.com/)).

It records the raw, broadcasted video stream though, which results in a very large file on disk (even standard definition ends up being ~1GB / hour).
So, I created a basic [PowerShell](https://docs.microsoft.com/en-us/powershell/) script years ago to pick up the raw files and re-encode them with [Handbrake](https://handbrake.fr/) into MP4s with  aggressive compression.

A while back, I had to [replace my media computer's CPU and motherboard](/2017-12-02/Recovering-From-A-Dead-CPU.html) (due to my own incompetence).
It previously has 4 cores, but now only has 2.
Combine that with a few other CPU intensive tasks that run from time to time, and watching the recorded video in [VLC](https://www.videolan.org/vlc/) can drop frames!

## Goal

Run my video re-encoder on a new [Debian Linux](https://www.debian.org/) box with 4 cores against the raw video files on my media computer.

That means:

* Getting Debian talking to Windows via [Samba](https://samba.org).
* Porting my old Powershell script to .NET Core.
* Getting a recent version of Handbreak to run on Debian 9 Stretch.
* Making sure it Just Works™.


## Samba and Windows

My first goal was to get my Debian box talking to my existing Windows file share of all my recorded TV.
Ideally, this should be a permanent mount point via the [SMB/CIFS](https://en.wikipedia.org/wiki/Server_Message_Block) file system.

I though this would be quite trivial, however it was more involved than expected.
There were lots of resources available to configure Samba as a [file server](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server), [domain controller](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller), [domain member](https://wiki.samba.org/index.php/Joining_a_Linux_or_Unix_Host_to_a_Domain), etc.
But [Samba's own documentation](https://wiki.samba.org/index.php/User_Documentation) was strangely silent on the topic of connecting to a someone else's server.

Apparently, that was because I didn't need to install Samba, but `cifs-utils`.
Which is where the client part of Samba and SMB lives.
In the end, I installed both (because this computer would end up serving files via SMB anyway).

```
$ apt install samba cifs-utils
```

One important tool was `smbclient`.
This is like an ftp client, but for Windows file shares, ie: SMB.
And, rather than figuring out the right syntax for mounting a file share correctly, `smbclient` lets you quickly experiment and test.

Foolishly, I thought this would work:

```
$ apt install smbclient
$ smbclient //loki.ligos.local/recordedTv
Enter users's password:
protocol negotiation failed: NT_STATUS_INVALID_PARAMETER_MIX
```

I tried using different users, but there was little difference.

```
$ smbclient //loki.ligos.local/recordedTv -U murray
Enter murray's password:
protocol negotiation failed: NT_STATUS_INVALID_PARAMETER_MIX

$ smbclient //loki.ligos.local/recordedTv -U Administrator
Enter Administrator's password:
protocol negotiation failed: NT_STATUS_INVALID_PARAMETER_MIX
```

By now, I'd decided to get the Samba server working.
I hoped the [smb.conf](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html) file might resolve these problems, but no luck.
I knew that Windows 10 disabled older versions of SMB (the protocol was radically re-worked in Windows Vista, and again in Windows 8), so I'd set my `smb.conf` to contain the following:

```
[global]
workgroup = WORKGROUP
server string = k2so.ligos.net
netbiosname = k2so

dns proxy = no
server role = standalone server

map to guest = bad user
usershare allow guests = yes

client min protocol = SMB2_10
```

Apparently, `smbclient` doesn't look at `smb.conf`.
So my additional settings were making no difference.
Instead, I needed to do this:

```
$ smbclient //loki.ligos.local/recordedTv -U murray -m SMB3
Enter murray's password:
Domain=[LOKI] OS=[] Server=[]
smb: \>
```

Success!

## Mounting A Windows File Share

Now that I'd confirmed the details of connecting to Windows 10 from `smbclient`, I was ready to mount the share more permanently.
I created a new folder ready for purpose:

```
$ mkdir /mnt/loki_RecordedTv
```

And looked into what I needed to tell `mount` to actually make the mount happen.
Again, a little digging was needed in the [mount.cifs man page](https://manpages.debian.org/stretch/cifs-utils/mount.cifs.8.en.html
) to force the correct protocol version.
And I also wanted to save my credentials somewhere other than on a command line.
I ended up with something like this:

```
$ sudo mount -t cifs -o vers=3.0,credentials=/etc/samba/private/murray.credentials,sec=ntlmsspi //loki.ligos.local/RecordedTV /mnt/loki_RecordedTv
```

And the content of `/etc/samba/private/murray.credentials`:

```
username=murray
password=NotReallyMyPassword
domain=WORKGROUP
```

And again, I had success!

```
$ ls /mnt/loki_RecordedTv
total 1.1G
...
drwxr-xr-x 2 root root    0 Jun  5 08:42 Hey Duggee
drwxr-xr-x 2 root root    0 Jun  7 18:34 Horrible Histories
drwxr-xr-x 2 root root    0 Jun  5 22:35 House Rules
drwxr-xr-x 2 root root    0 Apr 28 02:21 Jurassic World (2015)
drwxr-xr-x 2 root root    0 May 13 23:30 LEGO Masters - New
drwxr-xr-x 2 root root    0 Apr 29 04:47 LEGO Masters - Premiere
drwxr-xr-x 2 root root    0 Jun  6 22:45 MasterChef Australia
drwxr-xr-x 2 root root    0 May  1 07:24 MasterChef Australia 2018
-rwxr-xr-x 1 root root 1.1G Dec  1  2018 Pokemon The Movie The Volcanion And The Mechanical Marvel (2016)_20181201_14301628.mp4

```

## Automounting with Systemd

Years and years ago, Linux's mount points were configured in `/etc/fstab` - the file system table.
However, some searching on the 'net showed me that `systemd` was now capable of mounting things.
Well, as much as systemd always scares me, I might as well learn the new way.

With the Internet helping me with some [systemd mount examples](https://michlstechblog.info/blog/systemd-mount-examples-for-cifs-shares/
) and a [man page for systemd.mount](https://manpages.debian.org/stretch/systemd/systemd.mount.5.en.html
), I was on the right track.

However, a strange gotcha is that systemd enforces a naming convention of the unit name with respect to your mount point.
So for me, `/mnt/loki_RecordedTv` must be a systemd unit called `mnt-loki_RecordedTv.mount`.
Anything else will fail when you `systemctl enable wongly_named_loki_RecordedTv.mount`.

I put my unit file in `/etc/systemd/system/mnt-loki_RecordedTv.mount`:

```
[Unit]
Description=cifs mount script for //loki/RecordedTv
Requires=network-online.target
After=network-online.service

[Mount]
What=//loki.ligos.local/RecordedTv
Where=/mnt/loki_RecordedTv
Options=vers=3.0,sec=ntlmsspi,noperm,credentials=/etc/samba/private/murray.credentials
Type=cifs

[Install]
WantedBy=multi-user.target
```

You'll notice the `noperm` option which snuck in.
That tells the `cifs` kernel module not to enforce unix permissions on the client side.
My mount point is owned by `root` and has permissions `755`, which ordinarily means only `root` is allowed to write to it, no other user can.
But `noperm` bypasses that.
Note, that this doesn't bypass your Windows ACLs - they still apply, and if the user you specify in `mount` doesn't have write permission, then you'll get errors.
All it means is you don't need to get your unix permissions right - effectively, you've delegated all permissions checks to the file server.

OK, it's time to make systemd do its thing:

```
$ systemctl daemon-reload
$ systemctl enable mnt-loki_RecordedTv.mount
$ systemctl start mnt-loki_RecordedTv.mount
$ systemctl status mnt-loki_RecordedTv.mount

● mnt-loki_RecordedTv.mount - cifs mount script for //loki/Recorded TV
   Loaded: loaded (/proc/self/mountinfo; enabled; vendor preset: enabled)
   Active: active (mounted) since Sun 2019-06-02 14:48:14 AEST; 5 days ago
    Where: /mnt/loki_RecordedTv
     What: //loki.ligos.local/RecordedTv
    Tasks: 0 (limit: 4915)
   CGroup: /system.slice/mnt-loki_RecordedTv.mount

Jun 02 14:48:14 k2so systemd[1]: Mounting cifs mount script for //loki/RecordedTv...
Jun 02 14:48:14 k2so systemd[1]: Mounted cifs mount script for //loki/RecordedTv.
```

Success!


## Auto-re-mounting When the Connection is Broken

Well, it was successful until the network dropped out for a moment and the connection failed.
Apparently, [other people have the same problem](https://unix.stackexchange.com/questions/358692/systemd-remount-cifs-drive-after-failure
).

Network failures happen even on wired ethernet networks from time to time.
But I've also got my media server configured to shutdown from time to time (when there isn't much to watch / record on TV).
So I need to be confident the CIFS mounts will re-appear after any outage.

As with mount points, my ancient Unix wisdom said *"use cron"* (that is, edit `/etc/crontab`). 
But remember, "`systemd` can do everything"!

Systemd *timers* provide an alternative to `cron` jobs.
[Arch Linux](https://wiki.archlinux.org/index.php/Systemd/Timers) and [Gentoo](https://wiki.gentoo.org/wiki/Systemd#Timer_services) provided enough documentation and examples to get me up and running.
A `systemd` timer service is more complex than a `cron` job, but does allow slightly more flexibility.

First up, I made a script which did a `systemctl start` for each of my mount points at `/usr/local/bin/smb.mounts.sh`.
 
Then, I created and enabled a service unit as `Type=oneshot`. 
This allows you to run the service on demand, without waiting for the timer. 
In `/etc/systemd/system/smb-mounts.service` I have:

```
[Unit]
Description=Ensure SMB Mounts Remain Mounted
RefuseManualStart=no
RefuseManualStop=yes

[Service]
Type=oneshot
ExecStart=/usr/local/bin/smb.mounts.sh
```

As always, you need to enable the service, but then you can test it aside from any scheduling or timers.
A `status` query will always show the service isn't running; but that's OK.

```
$ systemctl enable smb-mounts.service
$ systemctl start smb-mounts.service
$ systemctl status smb-mounts.service

● smb-mounts.service - Ensure SMB Mounts Remain Mounted
   Loaded: loaded (/etc/systemd/system/smb-mounts.service; static; vendor preset: enabled)
   Active: inactive (dead) since Fri 2019-06-07 19:10:22 AEST; 3min 35s ago
  Process: 1937 ExecStart=/usr/local/bin/smb.mounts.sh (code=exited, status=0/SUCCESS)
 Main PID: 1937 (code=exited, status=0/SUCCESS)

Jun 07 19:10:22 k2so systemd[1]: Starting Ensure SMB Mounts Remain Mounted...
Jun 07 19:10:22 k2so systemd[1]: Started Ensure SMB Mounts Remain Mounted.
```

Then I made a timer unit.
After my experience with systemd's naming conventions, and every example saying you should name the timer `serviceName.timer`, I went with `/etc/systemd/system/smb-mounts.timer`, and everything was happy:

```
[Unit]
Description=Ensure SMB mounts remain mounted
RefuseManualStart=no
RefuseManualStop=no

[Timer]
Persistent=false
Unit=smb-mounts.service
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
```

I've gone with a schedule of *every 15 minutes*.
But there are [additional options](http://man7.org/linux/man-pages/man5/systemd.timer.5.html) under the `[Timer]` section which let you define a particular time of the day / week / month, etc (similar to how `crontab` works).

I went through the usual enable, start, and status to make sure everything is OK.
You can also use the `list-timers` option to see all active systemd timers. 

```
$ systemctl enable smb-mounts.timer
$ systemctl start smb-mounts.timer
$ systemctl status smb-mounts.timer

● smb-mounts.timer - Ensure SMB mounts remain mounted
   Loaded: loaded (/etc/systemd/system/smb-mounts.timer; enabled; vendor preset: enabled)
   Active: active (waiting) since Sun 2019-06-02 14:10:57 AEST; 5 days ago

Jun 02 14:10:57 k2so systemd[1]: Started Ensure SMB mounts remain mounted.

$ systemctl list-timers
NEXT                          LEFT         LAST                          PASSED   UNIT
Fri 2019-06-07 19:20:30 AEST  4min 1s left Fri 2019-06-07 19:15:30 AEST  58s ago  smb-mounts.timer
Fri 2019-06-07 19:39:00 AEST  22min left   Fri 2019-06-07 19:09:03 AEST  7min ago phpsessionclean.timer
Sat 2019-06-08 01:43:44 AEST  6h left      Fri 2019-06-07 10:29:03 AEST  8h ago   apt-daily.timer
Sat 2019-06-08 05:08:12 AEST  9h left      Fri 2019-06-07 05:08:12 AEST  14h ago  systemd-tmpfiles-clean.timer
Sat 2019-06-08 06:23:17 AEST  11h left     Fri 2019-06-07 06:40:03 AEST  12h ago  apt-daily-upgrade.timer

```


## Re-Encode Videos with .NET Core

Finally, with a working network mount available, I can get down to my actual goal: re-encoding videos!
Although my existing PowerShell script was working OK on Windows, I wasn't quite ready to deploy it on [PowerShell for Linux](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-6).
Instead, I ported it to .NET Core.

I'd previously installed .NET Core, but the [instructions are available from Microsoft](https://www.microsoft.com/net/download/linux-package-manager/debian9/runtime-2.1.2).

The basic logic of this app is:

1. For each `*.ts` video file in my `RecordedTv` folder (recursive).
2. Check if the video has finished recording.
3. If so, attempt to re-encode with Handbrake.
4. If the re-encode was successful, delete the orginal `.ts` file.
5. Wait for a while.
6. Goto 1.

The most exciting things to highlight are a) how to check if the video has finished recording, and b) how to detect a CTRL+C cancellation signal and react to it in short order.

Checking if the video has finished recording is done by attempting to open the file for exclusive read & write access.
If the video is still recording, NextPVR will hold locks which prevent exclusive access and I get an exception.

```c#
private static (bool, string) CanOpenFile(string path)
{
    FileStream fs = null;
    try
    {
        fs = new FileStream(path, 
                    FileMode.Open, 
                    FileAccess.ReadWrite, 
                    FileShare.None
                );
        return (true, "");
    }
    catch (Exception ex)
    {
        return (
            false, 
            ex.GetType().Name + " - " + ex.Message
        );
    }
    finally
    {
        if (fs != null)
            fs.Dispose();
    }
}
```

Detecting cancellation is always a bit tricky.
I long ago learned that the only way to respond to cancellation requests is co-operatively; you can't just "kill" something and expect everything to be OK.
That is, in my loop, I need to check for a flag representing that cancellation request, and if its set, you exit the loop.

```c#
bool cancelRequested = false;
public void DoWithCancellation()
{
    while (cancelRequested)
    {
        LookForTsFiles();
        if (cancelRequested)
            break;

        EncodeWithHandbrake();
        if (cancelRequested)
            break;

        Thread.Sleep(TimeSpan.FromMinutes(15));
    }
}

void Console_CancelKeyPress(object sender, ConsoleCancelEventArgs e)
{
    cancelRequested = true;
    e.Cancel = true;
}

```

That works fine, except the `Thread.Sleep()` at the end.
If the cancellation event is received while I'm sleeping, I don't actually do anything with that signal until the sleep has completed.
Which could be up to 15 minutes later.

Fortunately, we can use [CancellationTokenSource](https://docs.microsoft.com/en-us/dotnet/api/system.threading.cancellationtokensource) to respond more quickly, while also maintaining the same `Thread.Sleep()` behaviour:

```c#
CancellationTokenSource cancelSignal = new CancellationTokenSource();

public void DoWithCancellation(CancellationToken ct)
{
    while (!ct.IsCancellationRequested)
    {
        LookForTsFiles();
        if (ct.IsCancellationRequested)
            break;

        EncodeWithHandbrake();
        if (ct.IsCancellationRequested)
            break;

        cancellationToken.WaitHandle
            .WaitOne(TimeSpan.FromMinutes(15));
    }
}

void Console_CancelKeyPress(object sender, ConsoleCancelEventArgs e)
{
    cancelSignal.Cancel();
    e.Cancel = true;
}
```

Using `CancellationToken.WaitHandle.WaitOne()` acts exactly the same as `Thread.Sleep()` when you give it a timeout.
But, if cancellation is requested (via `CancellationTokenSource.Cancel()`), it wakes up immediately.
Which gives the best of both worlds: waiting without burning CPU cycles, and responding promptly to a cancellation request.


If you're interested, you can [download the full source code](/images/NextPVR-Samba-Windows-and-ReEncodingTV/ReEncodeRecordedTV.zip) for my little app.

Once the code was all done, I did a `dotnet publish -c Release` deployed it into `/usr/local/bin/ReEncodeRecordedTv`, and created a `systemd` unit for it.
As this will run continually and poll the folder itself, I didn't need a timer unit.

I could have removed the polling / sleep part of the program and let `systemd` take care of that, but I've had issues in the past with task schedulers running multiple instances of the same task - and when your task consumes all available CPU for 5-60 minutes at a time, you really don't want multiple instances!


```
[Unit]
Description=ReEncodeRecordedTV

[Service]
WorkingDirectory=/usr/local/bin/ReEncodeRecordedTv
ExecStart=/usr/bin/dotnet /usr/local/bin/ReEncodeRecordedTv/ReEncodeRecordedTV.dll
Restart=always
# Restart service after 5 minutes if the dotnet service crashes:
RestartSec=300
KillSignal=SIGINT
SyslogIdentifier=reencoderecordedtv
User=media-worker

[Install]
WantedBy=multi-user.target
```

Oh, and I also created a new system user `media-worker` so it runs in a more isolated environment.
In particular, no `root` privileges - which should mitigate a whole stack of potential security dramas.


## Building Handbrake on Debian 9

My last problem was that the version of [Handbrake available for Debian 9 Stretch](https://packages.debian.org/stretch/handbrake) via `apt` was pretty old (0.10.2).
I'm a sucker for new and shiny, and you might as well install the newest version from the beginning (it will never magically get newer), so I wanted the current version (1.2.2).
[Debian 10 Buster](https://packages.debian.org/buster/handbrake) will have a more current version (1.2.2), but that doesn't help me right now.

There were a few options:

1. Try to use the version from Sid - that is, use a newer package than my version of Debian.
2. Try to use the Ubuntu version of Handbrake on Debian (which is 1.2.2).
2. Use the [Flatpak](https://flatpak.org/) version of Handbrake.
3. Try to build from source.

**Option 1** didn't appeal to me at all: I had no idea if it would work or not, and I don't have the skills with [Debian pdkg](https://en.wikipedia.org/wiki/Dpkg) to fix things when they break.

**Option 2** was pretty much the same as option 1: I don't know enough to be confident that it would work reliably.

**Option 3** sounded more promising. [Flatpak](https://flatpak.org/) is a "it-just-works-everywhere" package manager for all manner of Unix operating systems. 
Except it needed to install ~300MB of stuff to do its thing for Handbrake.
And, given Debian has the strongest array of packages of any Linux distribution (except perhaps Ubuntu), I didn't like the idea of installing a whole new package manager just for Handbrake.

**Option 4** had instructions to [build Handbrake from source](https://handbrake.fr/docs/en/1.2.0/developer/build-linux.html), plus a tarball for 1.2.2 available for download.
The [dependencies for Debian](https://handbrake.fr/docs/en/1.2.0/developer/install-dependencies-debian.html
) were mostly straight forward, except a newer version of [nasm](https://packages.debian.org/buster/nasm) was required.
Instructions were provided for getting `nasm` from Debian Sid, but they were out of date and I needed to pick a [newer package from here](http://ftp.debian.org/debian/pool/main/n/nasm/).
After that, a `./configure --launch-jobs=$(nproc) --launch --disable-gtk` worked without a problem, taking around 10 minutes to build Handbrake CLI from source.
The result was a 40MB statically linked binary, which I copied to `/usr/local/bin`.

```
$ ls /usr/local/bin/Hand* -alh
-rwxr-xr-x  1 root root  40M Jun  1 22:40 HandBrakeCLI
```

## Leave it to Bake

Once everything was in place, I watched one encoding run through (via `htop`).

And then I left it overnight, and checked the next day that it was still working.

And left it until after a reboot, and checked all was well.

Each time, some minor corrections were needed.

It's good to remind myself that whenever I implement something new, there will be teething issues which need to be resolved.
Usually they're pretty minor (eg: I forgot to set the `mount` systemd units to `enabled`), but zero effort maintenance is a must!
So check and double check and then leave to bake, and then check again.

Only then did I say, *it Just Works™*.


## Conclusion

That took much longer than I thought it should have!
Oh well, I guess part of it is learning new things.

I've now got a separate encoder computer which uses Samba / CIFS to connect to my Windows media recording computer, checks for new recordings, and then re-encodes them to an mp4 with aggressive compression.
Overall, the re-encoded files are between one third and one half smaller than the originals, so a pretty decent saving of disk space.

All that means, I can forget to delete stuff for twice as long before I get *low disk space* warnings!
Yay for laziness!
---
title: System Image Backups with WbAdmin
date:
tags:
- Backup
- Windows
- Wbadmin
- System-Image
- Disaster-Recovery
categories: Technical
---

How to automate a complete backup of your Windows system which you can restore via your Windows installation disk.

<!-- more --> 

Backups are important. 
Like insurance is important.
It's a pain until your really need them, then they're a life saver.

## System Images

Before we get into the details, here's the difference between a *system image* and a *normal backup*: 
 
1. A data backup (photos, finances, documents, and so on).
2. A system image (everything on your computer's system drive).

While there's some overlap (particularly on computers with only one disk; 99% of computers out there), the two backups serve different functions.

A **data backup** protects against data loss. 
That is, if your computer crashes, is lost, stolen or destroyed, you can get a copy of your family photos, financial records, important documents, university thesis, and so on from your backup.
Usually, you can pick-and-choose exactly what file(s) you want to restore, sometimes even the exact date and time of the file.

A **system image** protects against a system hard disk crash.
That is, if your computer's system disk crashes (most people's computers only have one disk, so your data and system files are all on the same disk) you can go buy another one, and use your system image to copy everything back just the way it was.
Usually, you restore your whole disk or nothing at all, though some backup programs let you choose files to restore from a system image.

If you had a *data backup* but not a *system image*, you wouldn't lose any data, but you'd need to re-install your system before you can use your data (which can take anywhere from 30 minutes to a 12 hours, depending on how you use your computer).
So a system image is primarily there to get you up and running really fast if your disk crashes, but the rest of your computer is still running.

System images will copy absolutely everything on your disk, while a data backup may miss some files.
Although this means a system image is quite large, while a data backup can be much smaller.

(Aside: Power users and servers often have physically separate disks for their system (Windows and programs) and data (documents, photos, and so on).
But almost all consumer PCs or laptops will only have one disk in them, so the distinction I'm making isn't that important.
Having any backup, even if it isn't perfect, is a thousand times better than no backup at all.)

This explains how to make an automated Windows system image using a scheduled task and a script. 

## Manual System Image

Doing a manual Windows Backup is pretty easy.

You'll need an external USB hard disk drive (which can be purchased from your local electronics retailer). Plug it into your computer. 

In Windows 8 and 10, creating a system image is tucked away in the old *Control Panel -> System and Security -> Back up and Restore (Windows 7) -> Create a System Image*.

<img src="/images/System-Image-Backups-With-WbAdmin/manual-windows-backup.png" class="" width=300 height=300 alt="System Image Backups are a bit Hidden in Windows 10" />

Click through the prompts, select anything marked *System* and select your USB disk.

<img src="/images/System-Image-Backups-With-WbAdmin/manual-windows-backup-what.png" class="" width=300 height=300 alt="What to Backup - Everything Marked 'System'" />

<img src="/images/System-Image-Backups-With-WbAdmin/manual-windows-backup-where.png" class="" width=300 height=300 alt="Where to Backup - An External USB Disk" />

Your backup will take anywhere from a few minutes to several hours, depending on how big your disk is and how fast your USB is.

You'll find your backup on your USB disk in a folder called `WindowsImageBackup`.

You will be unable to access your backup without admin rights.
That is a good thing, because it may save your backup from [CryptoLocker](https://en.wikipedia.org/wiki/CryptoLocker).
  
## Make it Automatic

Manual backups are fine, except when you forget to run them.

So, we'll automate the backup, and even compress the files it creates using the script below.

The [wbadmin](https://technet.microsoft.com/en-us/library/cc742083.aspx) program is a command line version of the same manual process outlined above. 
It is part of Windows since Vista, so you do not need to install this.

I use [7-zip](http://www.7-zip.org/) to compress the backup on its fastest compression level (anything higher is extremely slow).
This needs to be downloaded and installed. 

The whole backup process takes about 12 hours on my 2009 laptop (only USB2), so I run it overnight, once per week.

You'll need a scheduled task to run the backup (and I put a reminder on my phone so I remember to plug my USB disk in).
Your task must run as `administrator` with *highest privilages*, or it won't be allowed to run.

<img src="/images/System-Image-Backups-With-WbAdmin/scheduled-task-general.png" class="" width=300 height=300 alt="Scheduled Task - General Tab" />

<img src="/images/System-Image-Backups-With-WbAdmin/scheduled-task-trigger.png" class="" width=300 height=300 alt="Scheduled Task - Trigger Tab" />

<img src="/images/System-Image-Backups-With-WbAdmin/scheduled-task-action.png" class="" width=300 height=300 alt="Scheduled Task - Action Tab" />


### SystemImage.cmd 

[Download SystemImage.cmd](/images/System-Image-Backups-With-WbAdmin/SystemImage.cmd) or copy from below. 

```
rem Windows System Image script
rem (c) Murray Grant 2016

rem Configuration

rem The drive letter of your USB disk
SET BACKUPDRIVE=m:
rem A password to use on your backup (yes, you should have one).
SET BACKUPPASSWORD=somePassword
rem A network location to copy the backup to (optional). 
SET NETWORKBACKUP=\\COMPUTER\Backups

rem End configuration


rem Get the current date (http://stackoverflow.com/a/203116)
for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do set %%x
set today=%Year%-%Month%-%Day%

rem Run Windows Backup and create a system image to the USB disk.
wbadmin start backup -backuptarget:%BACKUPDRIVE% -include:c: -allCritical -quiet

rem Delete any old backups (which were compressed.
del /q "%BACKUPDRIVE%\WindowsImageBackup\%COMPUTERNAME%*.7z.*"

rem Start 7-zip to compress the backup.
START "7-Zip Backup" /B /I /LOW /WAIT "C:\Program Files\7-Zip\7z.exe" a -r -mx1 -v1g -p%BACKUPPASSWORD% "%BACKUPDRIVE%:\WindowsImageBackup\%COMPUTERNAME%-SystemImage-%today%.7z" "%BACKUPDRIVE%:\WindowsImageBackup\%COMPUTERNAME%\*"

rem Delete the uncompressed backup files, if 7-zip completed successfully.
if %ERRORLEVEL% NEQ 1 GOTO AfterDelete
del /s /q "%BACKUPDRIVE%\WindowsImageBackup\%COMPUTERNAME%"

:AfterDelete
robocopy /mir /j /z /r:5 /w:15 %BACKUPDRIVE%\WindowsImageBackup "%NETWORKBACKUP%\SystemImages\%COMPUTERNAME%" *.7z.*  
```  

## Network Backups?

I couldn't figure out how to get `wbadmin` to backup directly to a network location. 
Hence why I backup to an external disk first, then copy to a network location.

It is supposed to support network backups, but I couldn't get it working.

You may need to map a drive letter or only use the base `\\COMPUTER\backups` path rather than anything deeper.

## Restoring

You restore your system image backup using your Windows installation disk / USB.

You need to start your computer from your Windows disk, and the option to restore will be in the advanced area.

Details are left as an exercise.
 
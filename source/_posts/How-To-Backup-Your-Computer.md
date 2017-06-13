---
title: How to Backup Your Computer
date: 2017-06-13
tags: 
- Backup
- Restore
- Crashplan
- Dropbox
- Cloud
- File History
categories: Technical
---

3 ½ Ways to Backup Your Computer

<!-- more --> 

Doing good backups of your computer is very important.
Because so much of our lives are tied up on devices these days.
And sometimes those devices break.

This is a tie-in article for a presentation I did at [Wenty Anglican Church](http://wentyanglican.org.au).
If you saw the presentation, this goes over the same material, with more detail.
Otherwise, its a guide to how to setup some simple (but effective) backups, and pointers to find out other options available.


## Why Have Backups?

Because computers break. 
And bad things happen.

More often than we'd like to admit.

And we have some really valuable stuff on our computers and devices.
The most value for most individuals is a collection of family photos and videos - these are not worth much in dollar terms, but have extremely high intangible value to us.
For companies, their data is valuable because of [intellectual property](https://en.wikipedia.org/wiki/Intellectual_property), compliance (eg: keeping financial records for 7 years), analytics (trends in client usage), customer lists (for potential sale to a competitor), and the big one: [client downtime](https://en.wikipedia.org/wiki/High_availability).

Here are a few examples of bad things that can and do happen to computers (note that with a good backups, your data can survive all of these):

**Theft:** Laptops and phones are really easy for thieves to take. These days, they aren't motivated by the resale value of stolen computer gear, they're interested in how much personal information they can scrape off them. Unfortunately, the thief's motivation is irrelevant: if the only copy of our photos is on our stolen laptop, we're stuffed. I've known of IT professionals who've lost all their computer gear and got it all replaced under insurance, but their data was gone forever.

**Fire / Flood / Disaster:** Natural disasters happen. Not very much (at least in Sydney, Australia), but when they do, they can wreck IT equipment. I've known people who's houses have burned to the ground in [bush fires](https://en.wikipedia.org/wiki/Bushfires_in_Australia), or had computers fried in a lightning strike. Without an off-site backup, their data is gone.

**Virus / Malware / Ransomware:** There are viruses that make your computer run slow (so you need to wipe it and start from scratch), viruses that delete your computer, and viruses that [hold your files to ransom](https://en.wikipedia.org/wiki/WannaCry_ransomware_attack). In every case, a backup will make life much easier, and in some cases backups are the only recourse. [Far Edge Technology](https://faredge.com.au) deals with malware and ransomware on a semi-regular basis; each year there will be one major client which gets hit by a nasty virus and we have to restore backups to get them up and going again.

**Computer Crash (software or hardware):** Computers break. Sometimes its because Windows sucks, or because MacOS breaks, or Linux crashes. Sometimes your hard disk dies, or you drop your phone and it doesn't start again, or it just gets old and stops working. My work computer died in late 2016 with a [Blue Screen of Death](https://en.wikipedia.org/wiki/Blue_Screen_of_Death) on start up; I needed to wipe it and start again. I was glad I had backups that day!

**Kids mucking around:** Kids are a great way to break your computer. Whether its by random key mashing, or more deliberate maliciousness (not that I was guilty of ever breaking my school's computers... no... never ever). In our family, we've had several phones rendered inoperable by our kids throwing it at our tiled floor in a temper tantrum. Backups to the rescue again!

**User error:** Finally, never underestimate how stupid people can be (and that includes you and me). Accidentally deleting files, clicking *"Yes, I'm Really Sure"* without reading the message, whatever. In the moment when you realise you've done something really dumb, its fantastic to have a backup - the ultimate `CTRL+Z`.

That's enough examples of ways your precious company data or personal photos can be permanently and irreparably destroyed. 

The take home message is you can always buy new gear, put in an insurance claim, or hit factory restore, but **there is no insurance policy that will get your data back**.


## What's a Good Backup?

So what makes a good backup?
What is a really robust backup strategy to have?

Here's a 3-2-1 rule, for any data you really care about: 

**Three** - At least 3 copies of any data you don't want to lose.

**Two** - Backed up using 2 different backup methods (eg: Dropbox + USB Disks).

**One** - At least 1 off-site backup.

([Shamelessly stolen from Scott Hanselman](https://www.hanselman.com/blog/TheComputerBackupRuleOfThree.aspx))

Most people would think 3 copies is overkill, surely just one is enough?
And why complicate things with 2 backup methods, surely just a copy of everything on my USB Disk is OK?
And off-site is just too hard!

Well, **three** copies is a good thing, because USB disks don't always work, and a thief might take both your laptop and your backup disk.

**Two** different methods means you can use your USB disk backup, even though you can't remember your Dropbox password.

And **one** off-site backup is a requirement for your data to survive natural disasters (it's a real shame if your 8 USB disks go up in smoke with the rest of your house).

The only thing I'd add to Scott's list is some way of keeping **older versions** of your files. 
That is, your backup holds a copy of documents as they change over time (perhaps snapshots every hour or every day).
This is how your data can survive ransomware, or when you realise you deleted the wrong files 3 months down the track.


## Things That Aren't a Backup

There are things people think are a backup, but really aren't.

Beware! Lest you think your data is safe when its one computer crash away from being lost forever!

* *A [RAID array](https://en.wikipedia.org/wiki/RAID)* saves you if one hard disk dies (maybe two). It doesn't stop a thief taking both disks, or both copies of files being deleted, or both disks dieing at once (yes, it does happen).
* *A copy on another disk on the same computer*. This is the same as a RAID array, but with a short delay.
* *A copy in another folder on the same disk*. This isn't even a backup! If the disk or computer dies, your data is gone.
* *A copy on an SD card in your computer*. That thief isn't going to kindly leave your SD card behind and then take your laptop.


## When Have I Lost Data?

I have a robust backup strategy not because I work in IT and have witnessed people lose everything (although that helps), not because I'm anal retentive (though that's a contributing factor), and not because I like writing blog posts (although articulating this does force me to review and improve my own backups).

**I have good backups because I've lost data.
And it made me very sad.**

There have been several minor incidents where I lost data.
Losing emails and chat logs (when I was very attached to such things), 
losing the last day of work because I accidentally deleted the wrong file,
losing my backups because I kept dropping the USB disk (oh the irony).

But those are minor compared to my biggest data loss event.
The impact of which comes across best as a story:

Back in 2005 I was dating the woman I'd eventually marry, and getting close to moving out of home.
And I went on a road trip with my family (parents and teenage siblings) for a week.
I'd recently emerged from being a teenager myself and realised I shouldn't be hating my parents quite so much.
It was a really good time, seeing the [NSW Southen Highlands](http://www.highlandsnsw.com.au/) and [Snowy Mountains Scheme](https://en.wikipedia.org/wiki/Snowy_Mountains_Scheme).

This was the last family holiday I'd have with my family before I got married.

I had a digital camera (which was a bit of a novelty in 2005) and took heaps of photos.
I'd even managed to work out that it was more important to take photos of people than scenery, so there were lots of photos of people I actually care deeply about.

All was good.

I came home after the holiday, connected my USB backup disk and my usual backups ran.

3 months later, I decided to look over the photos, tag people and categorise them.

Except there were no longer any photos.
Just empty folders.

After I'd triple checked I was looking in the right folder, and suppressed the sinking feeling welling up inside me,
I knew I had to turn to my backups.

Only, my backups were identical.
The same empty folders.
Without any photos.

My backup strategy at that time was to `robocopy /mir` all my data to a USB disk.
Astute readers will know the `robocopy /mir` makes an exact mirror (that's what the `/mir` part means) of your files.
Including deleting things.
So my backup had done exactly what I told it to do - when the photos were deleted on my computer, it deleted them from my backup as well.

To this day, I have not recovered any of those photos.

Nor have I worked out exactly what caused the data loss.
Likely candidates are one of a) data corruption on my laptop, b) some kids mucking about with my laptop on a [beach mission](http://www.sunsw.org.au/missions), or c) Murray doing something stupid.



## 3 ½ Ways to Backup Your Computer

That's enough introductory gumpf out of the way.
Lets get to the list!


### Number ½ - Copy and Paste

This involves taking a USB disk, finding all your important documents, files, photos, etc, and copying them to said USB.

<img src="/images/How-To-Backup-Your-Computer/copy-and-paste.png" class="" width=300 height=300 alt="Most people already know about CTRL+C, CTRL+V" />

It's dead simple to backup (as I suspect most people copy & paste on a daily basis).
It's dead simple to restore (copy & paste again).

*And it's not really a backup.*

The biggest problem with a copy+paste backup is it's manual.
As in, unautomated.
As in, you have to remember to do it, find time to do it, be bothered to do it, find your important files, not forget the important files in a non-standard place, press `CTRL+C` and press `CTRL+V`, and make sure it finishes.

And that's just too many reasons for it not to happen.

Where copy+paste really shines is as an **occasional archive**, rather than a true backup.

Buy a new disk, copy all your files, stick it somewhere safe, and rinse and repeat for the next archive (and yes, that includes buying a new disk).
Bonus: If your safe place is at a friend's house, you have an off-site archive.

If you're going to do this, you should plan to make an archive on a regular basis (eg: every 6, 12 or 18 months).

**Cost:** starting from **AU $90** for a 1TB USB disk


### Number 1 - Cloud Data Sync

The first real backup is using a cloud data sync service.
This automatically makes a copy of any files in your special sync folder to the cloud.

(There are plenty of other benefits and uses for cloud data sync, but I'll just be considering it for backup purposes).

(Note: most of these providers will say in their terms and conditions that they aren't a backup service.
That is their way of covering their liability if they accidentally lose your files.
It's worth remembering that any of these providers will safeguard your data 1000 times better than what you or I could manage on our own.
Or, in other words, Dropbox's reputation depends on them not losing files; if they managed to lose all a large number of files (yours and / or other's) its quite possible they'd go out of business - even if they say they aren't a "backup service").


**Step 0:** Select a provider.

[Dropbox](https://www.dropbox.com/) is the classic example and industry leader, but there are others I list below.
Some are true cloud services (using someone else's computers), others require you to have your own cloud (using your own computer or a friend's computer).
Others target specific features (eg: SpiderOak is end-to-end encrypted, so they can't see your data).
And cost will vary from provider to provider.

* https://www.dropbox.com/
* https://onedrive.live.com/about/
* https://drive.google.com/
* https://www.icloud.com/
* https://spideroak.com/
* https://owncloud.org/
* https://www.resilio.com/home/


**Step 1:** Create an account

Once you've chosen your provider, you need register an account.
This will give you a small amount of free storage.
And you'll need your credit card to buy more.

For the sake of this example, we'll choose [Dropbox](https://www.dropbox.com/).


**Step 2:** Install their App

Dropbox has apps for all major platforms (PC, Mac, Linux, Android and iOS).

Once you install it, you sign in with your account details.

<img src="/images/How-To-Backup-Your-Computer/dropbox-signin.png" class="" width=300 height=300 alt="Sign in to Dropbox" />

Then it will create a special folder which is synchronised to the cloud (aka Dropbox's computers).


**Step 3:** Copy files to your sync folder

Copy all your documents, photos, videos, etc to your Dropbox folder.

(Yes, this is the same as our copy+paste backup)!


**Step 4:** Wait for the Internet

You don't actually need to do anything in step 4.
Just wait for Dropbox to upload all your stuff (this may take a while if your Internet isn't very fast).

<img src="/images/How-To-Backup-Your-Computer/dropbox-sync.png" class="" width=300 height=300 alt="When you see the green ticks, your data is backed up!" />


**Restore from the Cloud**

The best things about any of these sync apps, is to restore your files to a new device is exactly the same process as starting your first backup!
Simply install the app and put your account details in (and wait for the Internet again).

There are ways to get specific files, or an older version of a file.
But you'll need to log into their website for that.


**Pros and Cons**

* Pro: very simple
* Pro: many people already have a cloud sync service on their computer
* Pro: its automatic - as long as you keep your files in the special folder
* Pro: its an off-site backup - it will protect your data from natural disasters
* Pro: works with all major platforms (PC, Mac, iOS, Android, Linux)
* Pro: keeps older versions of files
* Con: it needs the Internet - if your ISP is slow or you have a quota, you may run into problems

**Cost:** Annual subscription fee of between $70 and $140 per year, depending on provider.



### Number 2 - Built In Backup

Windows and MacOS both have built in backup software which is quite functional.
Windows 8 and above has the rather boring [File History](https://support.microsoft.com/en-au/help/17128/windows-8-file-history), while Mac has the much funkier [Time Machine](https://support.apple.com/en-us/HT201250).

As I'm a Windows guy, I'll walk through *File History*.


**Step 0:** Get a USB Disk

You'll need at least one USB disk to do your backups on.
In Australia, [Office Works](https://www.officeworks.com.au/) and [JB Hi-Fi](https://www.jbhifi.com.au/) will sell you a 1TB 2.5" USB disk for around $90.
If you need more disks or larger disks, the cost goes up. 

Make sure you plug it in before the next step.


**Step 1:** Point File History at Your Disk

File History is configured in the new *Settings* area of Windows 10 (although there are some extra settings in the old *Control Panel*).

Search for *Backup*.
This will bring you to the right place.

Click *Add Drive*, and your USB disk should appear on the left.

Click your USB disk.

(Note, on my laptop, I don't attach a USB. Instead, another computer on my home network has the USB disk, and I can backup over the network).

<img src="/images/How-To-Backup-Your-Computer/filehistory-adddrive.png" class="" width=300 height=300 alt="Add a drive. Either a USB or a network location." />


**Step 2**: Wait

It will take some time before your files are copied.
Fortunately, a USB disk is much faster than the Internet, so this step will happen much faster than any cloud sync.

File History doesn't give much indication of progress though.
You'll just see the *its on* button as it copies your precious files.

<img src="/images/How-To-Backup-Your-Computer/filehistory-on.png" class="" width=300 height=300 alt="Yep, File History is on." />

However, this is a pretty good thing.
File History very rarely pops up annoying messages (unless things go horribly wrong), it just gets on with its business behind the scenes.


**Step 3 (optional)**: Change Settings

There are additional settings you can configure if you click *More Options*.

The options are limited to: what to include and exclude, how often to do backups and how long to keep them.
I set mine to backup every hour, and keep files for up to 2 years.
That way my backups won't keep growing forever.

<img src="/images/How-To-Backup-Your-Computer/filehistory-settings.png" class="" width=300 height=300 alt="What to include, what to exclude, how often, how long." />


**Step 4 (recommended)**: Rotate Different Disks

I've had several USB backup disks fail.
They tend to be rather cheap and nasty (and I have a bad habit of dropping them).
So, its highly recommended to buy 3 disks and swap them each day.

A good strategy is to keep one disk plugged into your computer,
have one disk in a safe place in your house,
and keep one at a friend or family member's house.

(This is a manual process, so entirely depends on how disaplined you are).


**Restore From Settings**

Having a backup is no good unless you can get your files back.

For File History, go to the same *Backup* section of the *Settings* app.
Click *More Options* and scroll right to the bottom and click *Restore files from a current backup*.

Or, search for *Restore your files with File History*.

You'll get a screen which shows your files.
Under the files is a big green button to restore them from your backup, and left / right arrows to go back and forward in time
(given I have over 1200 individual backups in my file history, I'd hate to go back to the start of time)!

<img src="/images/How-To-Backup-Your-Computer/filehistory-restore-fromsettings.png" class="" width=300 height=300 alt="The official way to restore from File history." />


**Restore From Explorer**

If you're just looking for an older version of a particular file, you can find it in Explorer, right click and then click *Previous Versions*. 
And you'll see a list of older copies of the file.

<img src="/images/How-To-Backup-Your-Computer/filehistory-restore-fromexplorer.png" class="" width=300 height=300 alt="Right Click -> Previous Versions." />


**Hacky Restore** 

The cool thing about File History is it just makes copies of files in a structured way.
There's no proprietary format, hidden metadata, or complex database your files get whisked away into.

This means, you can just dig into your USB disk and find the file you want with Explorer.
The date and time of each file is listed in its name.

<img src="/images/How-To-Backup-Your-Computer/filehistory-restore-fromdisk.png" class="" width=300 height=300 alt="There are the versions of my backup presentation!" />


**Pros and Cons**

* Pro: quite simple
* Pro: its automatic
* Pro: no Internet required (no quota to exceed, no slow ADSL to endure)
* Pro: keeps older versions of files
* Con: not an off-site backup, unless you buy extra disks and make the effort
* Con: doesn't work for all platforms

**Cost:** 1TB USB disks start from ~$90



### Number 3 - 3rd Party Backup Software

There are any number of 3rd party backup solutions out there.
These will cover every combination of DIY to externally managed, from cheap to overpriced, online vs offline, simple to highly complex.

It's not possible for me to actually walk you through any of these.
Instead, I'll recommend the product I use personally, and list other products I've used or interacted with.

Please do your own research before blindly following any of my suggestions here!
What works for me might be unsuitable for you.


**A List of Products**

From A to Z:

[Acronis](http://www.acronis.com/en-au/) - Their *True Image* product is used by my parents and my work. I've only seen it used with local disks, but apparently it has a cloud option. 

[Backblaze](https://www.backblaze.com) - Never personally used it, but it comes highly recommended and is the cheapest cloud backup out there.

[Crashplan](https://www.crashplan.com/) - My personal recommendation; see below for more information.

[Windows 7 Backup](https://www.howtogeek.com/howto/1838/using-backup-and-restore-in-windows-7/) - The old Windows 7 backup and restore function is alive and well in newer versions of Windows, and can be used for [full disk images](/2016-01-24/System-Image-Backups-With-Wbadmin.html).

[Shadow Protect](https://www.shadowprotect.com/) - Used extensively by my [work](http://faredge.com.au) and definitely pitched at IT professionals (and priced likewise). But very reliable and effective.

Lifewire has longer lists of [free backup tools](https://www.lifewire.com/free-backup-software-tools-2617964), [commercial backup tools](https://www.lifewire.com/best-commercial-backup-software-programs-2624711), and [online services](https://www.lifewire.com/online-backup-services-reviewed-2624712).
Go crazy and find something which suits you.


**Murray's Recommended Product**

I use [Crashplan](https://www.crashplan.com/) as my 3rd party backup solution.

It covers off all the key points of backup software:

* Reasonably priced (free for local backups and backups at a friend's house, their cloud costs money)
* Automatic
* Supports recovering older version of files
* Cloud, off-site and local backups
* Plenty of options (choose files to backup, restricting bandwidth used, choose active hours)

The second to last point is the main reason for choosing Crashplan over other products:
it can do backups to *local disks*, to other *friends using Crashplan* (aka private cloud), and to *Crashplan's cloud* (aka public cloud).
Or any combination of the above.

You can also host other friend's backups (which I do for some friends and family).

I won't go any further details, but if you want to investigate further their [support site](https://support.crashplan.com/) or their [getting started guide](https://support.crashplan.com/Getting_Started) are the places to start.


## Murray's Backup Strategy

So what are my backups?
I use all 3 ½ methods listed here (plus an additional [full system image](/2016-01-24/System-Image-Backups-With-Wbadmin.html) each week).

The two critical chunks of data I have are:

1. **Family photos and videos** - 76,000 files – 160GB: Primary copy on mirrored disks, local backup via File History, local backup via Crashplan, Crashplan cloud, occasional copy+paste archive, occasional copy on USB disk (for showing to family).
2. **Password Database** - 2 files - 3MB: Primary copy on every device in my family (at least 6 copies), File History (for 3 Windows devices), crashplan local, crashplan cloud, Dropbox, OneDrive, occasional copy+paste archive, system images (3 Windows devices).

There's plenty of other stuff in my backups (emails, documents, files, programming stuff, kids, wife), so the total size is closer to 300GB across all devices.


## Application: +1 Backup

Time to take action!

I want you to a) add one backup to whatever backup strategy you have now, and b) check your existing backups are working.

If you have zero backups, that means doing your first - Dropbox or equivalent is my recommendation. 
If you already have a backup, start another one - either an off-site or on-site backup, depending on what you already have.
If you have a more comprehensive backup strategy, look for any weaknesses in it that you can improve - pick one and fix it.

Checking your existing backups are easy: pick a photo, video, document, or file which is really important to you.
And restore it from your backups. 
If you can, all is well.
If you can't, well, time to fix your backups!


For me, even though I've got an insane number of backups, I've realised it would be good to have an off-site backup which is within driving distance. 
Because doing a full restore of ~160GB of photos from the cloud is going to take weeks on my ~3.5Mb/sec ADSL connection.
I can drive to my parent's house in 5 minutes, or my sister's in 30 minutes.
So, I'll see if someone is willing to host a Crashplan mirror.


## Conclusion

Backups are important in our digital lives.
As they safeguard are most important data.

Make sure you have one (or three).

Make sure it's working.
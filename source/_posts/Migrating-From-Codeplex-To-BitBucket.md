---
title: Migrating from Codeplex to BitBucket
date: 2017-04-18
tags:
- Codeplex
- BitBucket
- Migration
- .NET
- ReadablePassphraseGenerator
- Keepass
categories: Coding
---

From one host to another.

<!-- more --> 

## Background

[Codeplex is shutting down](https://blogs.msdn.microsoft.com/bharry/2017/03/31/shutting-down-codeplex/).
So I need to migrate my [Readable Passphrase Generator KeePass plugin](https://readablepassphrase.codeplex.com/) to a new host.

As a coder, I've never used [Git](https://git-scm.com/) very much, so I gave the popular option of [GitHub](https://github.com/) a miss.
I've hosted a few smaller projects on [BitBucket](https://bitbucket.org/) using [Mercurial](https://www.mercurial-scm.org/), so it was the easiest choice for me.
It also has a basic issue tracker, wiki for documentation and lets you host downloads for free.
Unfortunately, it does not have a discussion forum (which Codeplex did), but I can't complain about free hosting.

## Migrating

Migrating was pretty straight forward.
Code and issues were easy, documentation took time but wasn't very difficult.

### 1. Migrate Code

Migrating a mercurial repository was very easy.

After creating a new BitBucket site for hosting and selecting a Mercurial VCS, I added it as a new remote repository location for my local Mercurial repo in TortoiseHg.
(I've always found adding new remotes slightly confusing, mostly because I don't do it very often, so the image below is as much for my reference as anyone else's.)

<img src="/images/Migrating-From-Codeplex-To-BitBucket/tortoisehg-remote-repo.png" class="" width=300 height=300 alt="Adding a Remote Repository in TortoiseHg" />

Then I pushed the entire repo up to BitBucket.

And waited 30 minutes for my very mediocre ADSL connection to upload.
And it was done!


### 2. Migrate Wiki / Documentation

One of the important things I did with the Readable Passphrase Generator was make high quality documentation.
Well, high quality is in the eye of the beholder, but there was certainly a lot of it!

Codeplex lets you download all your documentation content as a zip.
You get two parts, a) a bulk copy of everything in Codeplex in their proprietary wiki format and b) a best effort conversion into [Markdown](https://en.wikipedia.org/wiki/Markdown), which BitBucket supports.

I found that BitBucket's wiki is a separate HG repository, so I cloned it locally and started committing and publishing the converted Markdown.
Working through page-by-page, starting with the `Home.md` entry point and working on other pages as I encountered links.

Gotchas I found:

* Codeplex's "best effort" missed quite a few things. Code markup didn't convert (either inline or block), images with links didn't convert.
* Codeplex documentation had spaces in every page file name, BitBucket didn't seem to cope with spaces (unless you converted them to `%20`, which is ugly). So everything was renamed to have underscores instead.
* Codeplex / Windows is not case sensitive, BitBucket is. Even URLs must match case exactly (that is `Home` and `home` are different pages). And as I migrated pages, I accidently broke. Personally, I found this rather annoying (and I'm pretty sure most websites aren't as picky with URLs).
* Bullet lists in Markdown need a new line before them, while Codeplex didn't

But, all my text was migrated without loss.
So I didn't need any copy-pasting of content.

The worst bit was finding pages I didn't realise existed, and had to bring my outdated documentation in line with reality.

And I needed to update the PayPal *donate* link to redirect to BitBucket instead of Codeplex.


All this took 6-8 hours of migrating, checking, updating and re-writing pages.


**Why so much documentation?**

It reflects my principal of **document everything really well**, at least for public facing projects.
Decent documentation is painful but greatly enhances the image and reputation of any project.
In other words, if the author spent time writing up the project, they probably have greater attention to detail and care about their code a bit more.
That and I like reading about something before trying it out.


### 3. Migrate Outstanding Issues

There was no export from Codeplex for their issue tracker, so I manually copied and pasted issues into BitBucket.
Which took a few minutes, given there were about 8 issues.

### 3a. Fix Some Long Standing Issues

Codeplex has never been very good at sending me emails when people raise issues.
(BitBucket has a setting that emails one or more email addresses whenever new issues are created.)
I'd often find that someone has reported a bug of feature request months ago, and I never noticed.

There were a few such issues hanging around in Codeplex, so it was time to give Readable Passphrase Generator some love and attention (after considerable neglect).

I spent a few hours working through the outstanding problems people have reported.
Which included some [strange behaviour when not using spaces in passphrases](https://bitbucket.org/ligos/readablepassphrasegenerator/issues/4/excluding-word-separator-still-adds-spaces), a report it [didn't work in Ubuntu 16.04](https://bitbucket.org/ligos/readablepassphrasegenerator/issues/1/rpg-017-fails-to-work-with-keepass-235-in) and even found that some of my [documentation was horribly out of date](https://bitbucket.org/ligos/readablepassphrasegenerator/issues/2/sequence-contains-no-elements-on-valid).


### 4. Make Sure Everything is Working

This is quality assurance 101.
Click all the links, read all the pages, check all the images.
Test the scenarios end users are likely to be going through (ie: I want to download this thing, I'm updating my existing version).

And when you're sure everything is OK, check it again!


### 5. Direct the World to the New Site

Codeplex has a basic "this site has moved" option in the settings.
Once I stuck the new [BitBucket site](https://bitbucket.org/ligos/readablepassphrasegenerator/) in, I got an appropriate message at the top of every page on Codeplex.

And a quick email to the author of KeePass to update the [plugins page](http://keepass.info/plugins.html), and I was all done!


## Conclusion

Migrating is annoying, but I can't complain as I'm moving from one free host to another.
My biggest problem was Codeplex's documentation wasn't completely converted to Markdown BitBucket could cope with.

For projects with more code and less documentation (and that are better maintained), it would be even easier.
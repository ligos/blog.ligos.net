---
title: A Brief Intro To Hexo
date: 2016-01-17 21:00:00
updated: 
tags:
- Hexo
- Hexo-Bootstrap-Series
- Blog
- Conceptual
categories: Technical
---

As part of getting this blog off the ground, I'll outline what's involved starting a new Hexo blog from scratch.

Part 1: understanding how Hexo thinks.

<!-- more --> 

This will be a multi-part series of posts about Bootstrapping [Hexo](https://hexo.io/) (I'm expecting 4 or 5 parts to it). 
I'm working in a Windows environment (both for authoring and hosting), but much will carry over to Mac and Linux. 

At the end, I'll have outlined how I went from deciding to use Hexo right through to having a live blog with several posts.

For all posts in the series, check the **[Hexo-Bootstrap-Series](/tags/Hexo-Bootstrap-Series/)** tag.

## Why Hexo?

And in particular, why not Wordpress (or Joomla). 
Afterall, Wordpress is the de-facto standard for blogs on the Internet.

The primary reason is that I'm self hosting.
That is, this blog is hosting on a server in my house (to be specific, my do-everything media server, which also plays games, hosts backups and a few other duties), so it must be very efficient. 
If it slows my son's [Lego games](http://videogames.lego.com/en-us/lego-batman-3/about/features) down, I'll be getting high priority helpdesk tickets!
(And before anyone asks, yes, Windows is more than capable of playing games and serving web content at the same time.)

[Hexo](https://hexo.io/) is one of the most popular static content blog platform according to [StaticGen](https://www.staticgen.com/), and I was familiar with node.js from my paid job, so it seemed a decent place to start. 

But the major secondary reason is: I don't want to deal with Wordpress (or Joomla). 
I do a lot of work in a professional capacity with Joomla and Wordpress. 
And there are three things which really bug me about them:

1. **Security updates** - They're required every week on Wordpress (and every other week in Joomla). Static content doesn't need security updates (well, much less frequently anyway).
2. **Rich editors** - I've never liked them because they take me from native, high quality text editors to terrible browser knock-offs. Hexo uses Markdown in plain text files in an editor of my choosing ([Visual Studio Code](https://code.visualstudio.com/) is doing a fine job). 
3. **Databases** - They don't version well, and I don't want to run one if I can help it. Plain text files are what Git and Mercurial are built to deal with.  

And look, I'm learning something new. Which is always a plus in the IT industry.


## Hexo Concepts

I'm a terrible sucker for good documentation. 
Which is part of the reason why most open source development environments have not appealed to me (and why I dived right into the Microsoft world 10 years ago).

But Hexo's documentation, while pretty decent, didn't really give an outline of how everything fits together.

This post is all about understanding how Hexo thinks, and explaining what several of its labels mean.


### Hexo Generates Static HTML

Hexo is a node.js framework which takes your content, and converts it to a bunch of HTML files (and associated CSS, JavaScript, etc) ready for hosting as static content.

Your content is stored as plain files. 
The words are in plain text files in [Markdown](https://en.wikipedia.org/wiki/Markdown) (or [Embedded Javascript](http://www.embeddedjs.com/)),
images and other assets are plain files on disk.     

There's a `source` folder generated as part of a Hexo site, which is where your content lives. 
Write Markdown files in `source`, and Hexo will generate a site based on them.

Because your content is all in files, you can leverage your version control system (Git or Mercurial or whatever) to branch, merge and tag as you see fit.
(A major issue I have with Wordpress and Joomla is versioning the database to allow for staging and production instances of a site - it's basically impossible - but with Hexo it's trivial).

It's also worth pointing out that if you want content in sub-folders on your site, simply create `source/folder` and add content to it.


### Themes / Templates 

Hexo uses [themes](https://hexo.io/themes/) (which seem to be written in [Embedded Javascript](http://www.embeddedjs.com/) by convention) to generate the other parts of the site.
Things like the header and footer, the list of recent posts, a nice front page, tag clouds, and so on.

Picking a theme is pretty important. Almost as important as chosing Hexo in the first place.
It will determine what the site looks like to readers and what features you have easy access to (comments, search, tag clouds, social media links, and so on).

The default Hexo theme *landscape* is functional, but otherwise rather basic.
Not unlike an out-of-the-box Wordpress site.

You should [choose your theme](https://hexo.io/themes/) right at the start of making your Hexo site.
And take your time to choose a good one.

A theme has its own conventions and documentation. 
It really drives both the appearance and functionality you'll have available. 
My choice of theme was driven by:

1. Appearance and Mobile Accessibility / Responsive HTML
2. Documentation provided by author
3. Out of the box features
  
Themes tend to be open source, so it's pretty easy to bend them to your will.
But you really want to use that as a last resort to tweak things. 
Not to implement entirely new features.   

![Theme vs Content](/images/A-Brief-Intro-To-Hexo/Theme-vs-Content.png "Your Content vs Theme Layout on a Post")


### Plugins

Hexo uses the node.js `npm` world to distribute [plugins](https://hexo.io/plugins/).
  
I'll state right up front: I'm not a huge fan of plugins.

I much prefer seeing a great big list of features available to me, and I can pick and choose from them.
Frameworks which use plugins for major parts of their functionality tend to do almost nothing out-of-the-box, and then you need to hunt down plugins to make them do anything useful.
This is almost certainly a product of living in the Microsoft C# world for so long.

Hexo isn't too bad in this respect.
It lists all official [plugins](https://hexo.io/plugins/) (and many contributed ones) in one place.
And most plugins have a GitHub page with at least basic documentation or configuration options listed.

There are a few plugins which are worth getting from the start:

* `hexo-server` - lets you host your Hexo site, good for local testing (not for production hosting)
* `hexo-generator-alias` - generates HTML / HTTP redirects
* `hexo-generator-feed` - generates an RSS feed
* `hexo-generator-sitemap` - generates a sitemap

But you can add others later, as you find needs.


### Configuration

Unlike Wordpress or Joomla, where the configuration file is just to bootstrap the site and connect to your database, 
all Hexo configuration lives in its `_config.yml` file.

`_config.yml` ties everything together.
Core configuration like site language(s), permalink format and folder structure are here.
As well as configuration for your theme.
And for every plugin.
You just keep adding more and more properties.

My recommendation is to include configuration properties for your theme and all plugins with clear headings, so you know what they're for.
And to include all possible options from all your plugins (again, that's my need to see all options in front of me).


### Generation and Deployment 
  
Hexo generates your site locally in the `public` folder.
It has various plugins to deploy that to your live hosting environment.

*Generating* creates all the static HTML files based on your content, themes and plugins.
I have not looked, but I assume [grunt](http://gruntjs.com/) or [gulp](http://gulpjs.com/) will sit somewhere under the hood to do this part of the process.

*Deploying* copies the static site to somewhere else (presumably a hosting environment).

This facilitates a nice split between staging and production sites (if you need such a thing).

And also allows great flexibility in deployment (via Git, rsync, or plain old xcopy).
In my Windows environment, I am using `robocopy` to deploy.  


### Posts vs Pages

*Posts* are the posts you make to your blog. 
Which is where almost all your content will go.

For example, [this webpage is a post](/2016-01-16/A-Brief-Intro-To-Hexo.html). 

*Pages* are things like [About](/about.html) and [Contact](/contact.html).

The main difference is that *Posts* appear on your front page, while *Pages* do not (you need to link to them explicitly).
They also don't usually have a category, comments, tags or summary text. 

Although you'll create many more posts than pages over the life time of your blog, 
you'll need to create a couple of pages before any posts (*about* and *contact* are the bare minimum, many sites will need *legal*, *terms of service* and *privacy* pages too) 

### Authoring Workflow

Hexo has a basic authorship workflow: *drafts* and *published*.

You can create *draft* posts, which are not generated and not included in the public site (by default).
And, once you have finished writing them, you can 'publish' them to your public site. 

See the Command Line section below for details.

They are controlled by files being in the `source/_drafts` folder, rather than the `source/_posts` folder.

Another benefit of everything being a file is you can use your version control system to manage workflow.
Branch, tag, merge and share as you see fit to manage your workflow.

I'm using a very simple system where the live site is in my *default* Mercurial branch, and I run a *drafts* branch where I author content.
I merge content to *default* as it gets published.  
This lets me see everything (including my drafts) when I'm using the local server, but only things actually published are seen by my readers.


### Command Line (or not)

Hexo has a bunch of [commands](https://hexo.io/docs/commands.html) to create new posts, publish them and so on.
They drive your authorship workflow.

Eg:

* `hexo new My-New-Post` - creates a new post
* `hexo new draft My-New-Draft-Post` - creates a new draft post 
* `hexo new page A-Page` - creates a new page
* `hexo publish My-New-Draft-Post` - publishes our previously draft post

But, because Hexo just generates HTML from files on disk, you can equally create new files manually and use copy & paste.

I'm not really using Hexo's commands for authorship (though you need to for other things like generating and starting the local server).  

  
### Scaffolds

The `scaffolds` folder has a small number of templates which are used when creating new posts or pages.
They are copied to your new file when you do a `hexo new My-New-Post`.

None of the scaffold names are special, they simply give you a way to create some boilerplate.

I prefer to copy & paste from older posts, so scaffolds aren't that important to me. 

(Note that while the *draft* scaffold isn't special (its just another scaffold), *draft* is special because it creates the post in the `source/_drafts` folder).


## Conclusion

I think that wraps up all the major Hexo concepts (and a few minor ones too).
This should provide a basic reference for new or prospective Hexo users to understand how Hexo operates, 
and how they can work with Hexo.

In my next post, I'll outline the actual process I went through to create my Hexo blog.

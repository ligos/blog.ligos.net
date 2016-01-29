---
title: Installing Hexo
date: 2016-01-18 22:30:00 
updated: 2016-01-19 20:00:00
tags:
- Hexo
- Hexo-Bootstrap-Series
- Blog
- Installation
categories: Technical
---

Part 2 of my Hexo Bootstrap Series: how to install Hexo and core configuration 

<!-- more --> 

In this post, we'll install everything needed to create a new Hexo blog:

* Install node.js and git
* Install the core Hexo commands
* Create a Hexo blog instance
* Install a theme
* Install some plugins
* Set your configuration
* Make small changes to the theme layout  

For all posts in the series, check the **[Hexo-Bootstrap-Series](/tags/Hexo-Bootstrap-Series/)** tag.

## Frameworks and Prerequisites

If you don't already have them installed, you'll need [Node.js](https://nodejs.org) and [Git](http://www.git-scm.com/) to use Hexo.

I grabbed the most current version of Git for Windows at the time (2.6.4).

Then spent half and hour trying to make sense of Node.js's [new semantic versioning](http://stackoverflow.com/a/34169319) (apparently, they adopted IoJS's versions), before downloading the most current 4.x LTS series for Windows (4.2.4).

Finally, install hexo itself via an admin command prompt `npm install -g hexo-cli`.

(Note that you don't need to install these on your server, just your own computer).

[Hexo doc reference](https://hexo.io/docs/)

## Basic installation

Create a new folder somewhere and open a command prompt there (admin not required any more).

Run `hexo init` and an `npm install` you'll get a bare bones Hexo instance.

<img src="/images/Installing-Hexo/hexo-init.png" class="" width=400 height=400 alt="hexo init; npm install" />

If you do a `hexo generate` at this point, you'll get a bunch of HTML files in a `public` folder.
Unfortunately, you can't open these with a web browser directly from disk, you need a web server (the basic HTML files will load, but CSS and JavaScript won't).
And Hexo's basic web server is now a separate plugin.

[Hexo doc reference](https://hexo.io/docs/setup.html)

## Install Web Server

In your Hexo folder, run `npm install hexo-server --save` to install the web server component.

Then do `hexo server --debug`, and you'll see a bunch of debug spew come up as it processes your files.
You can now browse to `http://localhost:4000` to load the default site.

[Hexo doc reference](https://hexo.io/docs/server.html)

<img src="/images/Installing-Hexo/hexo-server.png" class="" width=300 height=300 alt="hexo server --debug" />

## Find a theme 

At this point, it is easy to be seduced by diving into the configuration and installing heaps of plugins (as I was). 

**But you really want to choose a theme first. Really.**

Check out the [Hexo Theme List](https://hexo.io/themes/).

There are some simple themes, and much more complex and fleshed out themes available on the official theme list.
I'm sure there are more available somewhere else, but I didn't look.

I chose [Hueman](http://blog.zhangruipeng.me/hexo-theme-hueman/) as my theme, because:

1. It looked decent.
2. It had a responsive / mobile layout.
3. The author has good documentation.
4. The author updates the theme regularly.

[Installation](https://github.com/ppoffice/hexo-theme-hueman/wiki/Installation) is quite easy. 
Clone the git repository to download files required, then update `_config.yml` to select the correct theme.

And I added a chunk of config options as listed on the [Hueman documentation page](https://github.com/ppoffice/hexo-theme-hueman/wiki) to my `_config.yml` file.
Since I started my site, it seems the theme author has added a `_config.yml.example` which you can copy instead.

Restart your Hexo server and you should see your new theme. 

## Add plugins

OK, now you can go crazy with [plugins](https://hexo.io/plugins/)!

Hexo's plugins all use NodeJS's `npm` package manager. 
So installation is as easy as `npm install hexo-some-plugin --save`.

In addition to the defaults, I added some pretty core plugins, plus some nice to haves:
* `hexo-server` - for testing on a local server (alread installed above)
* `hexo-generator-alias` - for redirects
* `hexo-generator-feed` - for an rss feed
* `hexo-generator-sitemap` - to generate a sitemap.xml file
* `hexo-toc` - to allow for a table of contents on a post

After you add each plugin, you should check if it has any configuration and add it to your `_config.yml`.
Remember to comment the config for each plugin (I added web links).  

## Go Through the Config and Make it Do What You Want

At this point, you should have all the possible options in your `_config.yml`.
So, keep the [Hexo documentation](https://hexo.io/docs/configuration.html) handy (along with any plugin or theme doco) and start tweaking!

When editing your config, remember that the built-in server does not seem to notice changes to it.
It will regenerate content, but not when you update the config file.
So you'll need to restart the server pretty often.

The lesson I learned here was that the defaults are pretty good.
I thought the `post_asset_folder` and `relative_link` options should be switched on, but turned out it was better to leave them off.

You'll want to spent a bit of time thinking about your [permalink](https://hexo.io/docs/permalinks.html) format.
It is rather permanent, afterall.
Some variation on a date based structure will scale nicely.
I went with `YYYY-MM-DD/Article-Title.html`. 

Some other things to note:

* `skip_render` - You'll need to add your Google Site auth file here, or it will be processed as any other html content (not what you want) (Bing's XML auth file is not processed though, so you don't need to add it).
* `marked.breaks` - I prefer my Markdown not to insert line breaks unless I leave a blank line (makes version control work better). So I set this to false. 
* `highlight.line_number` - I'm not a fan of line numbers against source code. So I changed this to false. 


## Theme Changes in Code

Finally, there were a few things I wanted to change in the theme code.
Obviously, this is specific to the *hueman* theme, but I'm sure you'll find similar small things for whichever theme you chose too.

These changes are definitely not for someone who just wants to churn out content.
So no shame in ignoring this whole section.

But as a professional web developer, they're well within my capability. 

From easiest to hardest, here are the three changes I made.

### Add A License

Unfortunately, you need to [choose a license](http://blog.codinghorror.com/pick-a-license-any-license/) for any publicly released content.

So I added a Creative Commons license link in `hueman/layout/_partial/footer.ejs` file, which will appear at the bottom of all pages.  

There's also some copyright and license information on the [about](/about.html) page.

``` html
<a href="http://creativecommons.org/licenses/by/4.0/deed.en_GB">CC BY 4.0</a>
```

### Make Copyright Year a Range

I prefer "*© 1812 - 3812 Bloggs*" rather than "*© 3812 Bloggs*".
As it gives the reader an idea of how long the site has been running for.

So I added a config variable called `start_year`, which is the year this blog started (2016).

And tweaked the display of the copyright year in `hueman/layout/_partial/footer.ejs` to make use of the question mark colon operator (aka ternary operator) in Javascript so it would just work come next year.

```
    &copy; 
    <%= ((config.start_year == date(new Date(), 'YYYY')) ? config.start_year : config.start_year + " - " + date(new Date(), 'YYYY') ) %> 
    <%= config.author || config.title %>
```

Now I get "*© 2016*" in 2016, and "*© 2016 - 2017*" in 2017.

### Change the Logo to be Plain Text

Hueman assumes the site logo is an image.
That's fine, except when you don't have an image or want an image.

My main performance constraint when self-hosting is my network connection.
A very ordinary residential ADSL connection.
With less than 1 Mbps upstream capacity.
Every byte I need to serve really hurts me.
And one more image, one more HTTP connection, and a few more kB do make a difference.
 
So no logo.

In my config, I removed all the logo stuff, and added a flag to turn a text based logo on:

```
# Logo url and optional width, height. Remove to use default.
# MG: added use_text_logo to ignore all image based logo logic
logo:
  use_text_logo: true
#  url: /blah.png
#  width: 300px
#  height: 50px
```

Add a style for the text based logo in `hueman/source/css/_partial/header.styl` and `footer.styl`.

```
#header-title
  .logo-text
    line-height: logo-height + 10
    color: color-nav-foreground
    text-shadow: 0 1px rgba(0, 0, 0, 0.2)
    font-size: 40px
  a.logo-text
    color: color-nav-foreground
    text-decoration: none
    
...
    
#footer    
  .logo-text
    line-height: logo-height + 10
    color: color-nav-foreground
    text-shadow: 0 1px rgba(0, 0, 0, 0.2)
    font-size: 32px
  a.logo-text
    color: color-nav-foreground
    text-decoration: none
```  

Then in `hueman/layout/_partial/head.ejs` and `footer.ejs`, choose the style as approparite. 

``` html
<h1 class="logo-wrap">
  <a href="<%- url_for() %>" class="<%= theme.logo.use_text_logo ? "logo-text" : "logo" %>"><%= theme.logo.use_text_logo ? theme.title : "" %></a>
</h1>
```  

And I'm free of any images for my logo!
(And my ADSL connection can rest easy).

## Conclusion

As with all things in IT, if you want to do it properly, starting a Hexo blog is a bit more work that you'd think at first.
But not too much.
And if you don't care about little tweaks like logos and copyright, then the complicated bits are not relevent.

Now, you should have a Hexo blog up and running on your local computer.
It should look nice and just how you'd like it.

Next time: hosting it on an IIS server so the rest of the world can see it.
 
  



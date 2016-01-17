---
title: Installing Hexo
date: 
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
* Test everything is working OK  

For all posts in the series, check the **[Hexo-Bootstrap-Series](/tags/Hexo-Bootstrap-Series/)** tag.

## Frameworks and Prerequisites

If you don't already have them installed, you'll need [Node.js](https://nodejs.org) and [Git](http://www.git-scm.com/) to use Hexo.

I grabbed the most current version of Git for Windows at the time (2.6.4).

And, spent half and hour trying to make sense of Node.js's [new semantic versioning](http://stackoverflow.com/a/34169319) (apparently, they adopted IoJS's versions), before downloading the most current 4.x LTS series for Windows (4.2.4).

Finally, install hexo itself via an admin command prompt `npm install -g hexo-cli`.

[Hexo doc reference](https://hexo.io/docs/)

## Basic installation

Create a new folder somewhere and open a command prompt there (admin not required any more).

Run `hexo init` and an `npm install` you'll get a bare bones Hexo instance.

![Command line output from hexo init](/images/Installing-Hexo/hexo-init.png "hexo init; npm install")

If you do a `hexo generate` at this point, you'll get a bunch of HTML files in a `public` folder.
Unfortunately, you can't open these with a web browser directly from disk, you need a web server (the basic HTML files will load, but CSS and JavaScript won't).
And Hexo's basic web server is now a separate plugin.

[Hexo doc reference](https://hexo.io/docs/setup.html)

## Install Web Server

In your Hexo folder, run `npm install hexo-server --save` to install the web server component.

Then do `hexo server --debug`, and you'll see a bunch of debug spew come up as it processes your files.
You can now browse to `http://localhost:4000` to load the default site.

[Hexo doc reference](https://hexo.io/docs/server.html)

![Command line output from hexo server](/images/Installing-Hexo/hexo-server.png "hexo server --debug")

## Find a theme 

TODO

After looking through the themes decided on hueman as it looked pretty nice and is responsive.
 
Added its config to `_config.yml` for reference.

## Add plugins

In addition to the defaults:
* `hexo-server` - for testing on a local server
* `hexo-generator-alias` - for redirects
* `hexo-generator-feed` - for an rss feed
* `hexo-generator-sitemap` - to generate a sitemap.xml file
* `hexo-toc` - to allow for a table of contents on a post

Added config for each plugin to `_config.yml` for reference.

## Go through the config

Config changes were pretty easy, just go through doco and change as you see fit.  

* Register for Disquss to enable comments

## Theme Changes in Code

* Change the heading from an image to text
  * In `head.ejs` (to include the blog title) and `header.ejs` (to add a style for the text heading)
  * and `footer.ejs` (to include the blog title, same as in head.ejs)

```
<h1 class="logo-wrap">
  <a href="<%- url_for() %>" class="<%= theme.logo.use_text_logo ? "logo-text" : "logo" %>"><%= theme.logo.use_text_logo ? theme.title : "" %></a>
</h1>
```  
  
```
#header-title
  clearfix()
  text-align: center
  padding: 30px 30px
  .logo-wrap, .subtitle-wrap
    float: left
  .subtitle-wrap
    padding: 10px 0px 0px
    margin-left: 20px
  .subtitle
    font-size: 16px
    font-style: italic
    line-height: logo-height + 10
    color: color-nav-foreground
    text-shadow: 0 1px rgba(0, 0, 0, 0.2)
  .logo-text
    line-height: logo-height + 10
    color: color-nav-foreground
    text-shadow: 0 1px rgba(0, 0, 0, 0.2)
    font-size: 40px
  a.logo-text
    color: color-nav-foreground
    text-decoration: none
```  



---
title: Getting Started With Hexo
date: 
tags:
- Hexo
- Hexo-Bootstrap-Series
- Blog
- Installation
categories: Technical
---


## Basic installation

How do you get off the ground?


## Find a theme 

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

* Fix non-secure urls

* Ensure Google site auth file isn't rendered
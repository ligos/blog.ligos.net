---
title: Writing Content On Hexo
date: 2016-07-25
tags:
- Hexo
- Hexo-Bootstrap-Series
- Blog
- Content
- Authoring
categories: Technical
---

Part 4 in starting with Hexo: how you actually write content

<!-- more --> 

For all posts in the series, check the **[Hexo-Bootstrap-Series](/tags/Hexo-Bootstrap-Series/)** tag.

## Background

I've been using Hexo to post blog content for around six months, so it's time to lay out how I've ended up using Hexo to write that content.

## Workflow

### 1. Create a New Post

The first step for any blog is to create a new post.
Hexo is very command line orientated, so you'd normally make a post via `hexo new`.

While I'm more than competent with a command line, I prefer GUI tools and IDEs to write content and build things.

It didn't take me long to realise that Hexo is a big *for each* loop over all your files in `_posts`.
So, rather than `hexo new`, I copy and paste from older posts in Visual Studio Code. 

As long as your post starts with an underscore, Hexo sees it as a draft and won't process it.

### 2. Write Using Visual Studio Code

I've used the full Visual Studio for years at work and on personal projects.
I thought I'd give the cool new [Visual Studio Code](https://code.visualstudio.com/) a go for writing on Hexo.

It has some basic [Markdown](https://en.wikipedia.org/wiki/Markdown) syntax highlighting, and supports a spell checker.

On the subject of Markdown, I needed to learn it a bit better than I had in the past.
Mostly that involved getting some of [GitHub's reference](https://guides.github.com/features/mastering-markdown/) for the different styles.

My current draft posts tend to sit in VS Code's *Working Files* section.
And all previous posts just sprawl down on the left.
Leaving me with a decent amount of space for actual content on the right.

<img src="/images/Writing-Content-On-Hexo/VsCode-This-Post.PNG" class="" width=300 height=300 alt="VS Code When Writing This Post" />

VS Code is also quite web centric, so it works well to tweak my theme's HTML, CSS or javascript.

Many of my posts will start on a train trip (either to or from work), so having the above work offline is very important.
The [spell checker](https://marketplace.visualstudio.com/items?itemName=seanmcbreen.Spell) uses an online service, so I get none of that until I proof later.


### 3. Images

Hexo's [documentation recommended](https://hexo.io/docs/asset-folders.html) either a single folder for images (`source/images`) or one folder per post for images (`source/post-name`).
I very quickly settled on the one folder per post approach, as it's rare for the images I use to be shared between posts, and stops a single sprawling *images* folder. 

<img src="/images/Writing-Content-On-Hexo/VsCode-Images.PNG" class="" width=300 height=300 alt="VS Code - Image Folders" />

Most of my image are a bunch of screenshots.
Nice and simple. 

I tried using the [tag helpers](https://hexo.io/docs/tag-plugins.html) for these, but found it easer to just manually code the relative urls.

(Although the lack of tag helpers means manually linking to other pages on the blog can be rather hit and miss).


### 4. Test With hexo-server

Once I've written a post in VS Code, and proof-read it once, I will view it in a web browser to proof it again.

(Yes, I'm a perfectionist and will proof anything I write more than three lines several times over.
And I find that proofing in different formats helps me notice things which aren't quite right).

This involves opening a command line and typing `hexo server`.
I'm pretty sure its the only part of my workflow which involves a command line!

<img src="/images/Writing-Content-On-Hexo/hexo-server.PNG" class="" width=300 height=300 alt="Local Hexo Server" />

And from there I will browse to `localhost:4000` to proof and check layout.


### 5. Publish And Test Again

The publishing part closely follows how I'm [Hosting Hexo On IIS](/2016-01-29/Hosting-Hexo-On-IIS.html).

I run my two line `generate and deploy` script, which runs `hexo generate` and then `robocopy` to deploy to my server.

Then I'll browse to [blog.ligos.net](https://blog.ligos.net) to do a last minute proof and make sure all is working OK.
In particular, checking links within the blog work.


## Not So Great Things

Overall, the workflow, tooling and process works pretty well for me.
But there are a few minor quibbles and worries.

### 1. Images in Markdown (and maybe FancyBox)

I could never quite figure out how to convince the Markdown parser and tag helpers to set my `img` tags quite right with my theme.

The problem was how the title / alt tags are intepreted by [FancyBox](http://fancybox.net/).
It never set the title under the image based on the tag helper title. 

In any case, dropping to plain HTML was an acceptable work around.
Which is not great problem for me as a programmer, but I could see it being a problem for less technical users. 

``` html
<img src="/images/Writing-Content-On-Hexo/VsCode-Images.PNG" class="" width=300 height=300 alt="VS Code - Image Folders" />
``` 


### 2. Too Many Posts

I've got 24 posts so far, which isn't very many as far as blogs go.
But I work with database back ends, and I know an unbounded list when I see one!

My `_posts` folder will just keep on growing.
Forever.
And VS Code isn't going to help me find things.
And already has too many files listed on the left.

I'm not sure how this will work out, but I suspect I'll end up using Window's Search function to find older posts.
And having a small number of posts sitting as drafts in *Working Files* works pretty well.

It would be nice if you could sort content in `_posts` into folders somehow.


### 3. Not Using Version Control

I had high hopes of using [Mercurial](https://www.mercurial-scm.org/) to manage drafts and published posts.
I'd have branches for each post I was writing.
Then commit, test and merge to a published branch for publishing.

I managed to break that workflow after three posts.
And never bothered fixing it.

Woops.

In fairness to Hexo, this is a problem with me more than any part of Hexo. 

And the simple "if it starts with underscore, it's a draft" works well enough for me as a single author.
A more disciplined approach to publishing would be needed with multiple authors or a higher profile site. 


### 4. Rendering Crashes  

The ugliest thing is what happens when you get your Markdown wrong.
And the rendering engine crashes.
Particularly when you mix markdown, HTML and Hexo [helpers](https://hexo.io/docs/helpers.html) or [tag helpers](https://hexo.io/docs/tag-plugins.html).

<img src="/images/Writing-Content-On-Hexo/Ugly-Crash.PNG" class="" width=300 height=300 alt="When Hexo Goes Horribly Wrong" />

Now, I'm a programmer, so long, red error dumps with stack traces are an annoyance, not *throw your hands up and run away screaming* scary.

But, as a programmer, I expect a line number which broke things.
Because if I have many `link_to`s or `img`s on my post, I need to know which one needs fixing!

In the end, using very basic Markdown and no special Hexo helpers has meant I haven't seen one of these for a long time. 

## Conclusion

I've managed to get quite comfortable writing content with Hexo.

As a programmer who likes a text editor, a bunch of files and a few scripts, I really like it!

Certainly much more than I've ever liked javascript rich text editors in Wordpress and Joomla.




---
title: Getting Started With Keybase
date: 2018-04-28
updated: 2018-05-13
tags:
- Keybase
- PGP
- Cryptography
- How-To
- Slack
- Messaging
- Secure
- DeleteFacebook
categories: Technical
---

"Cryptography for everyone"

<!-- more --> 

## Background

[Keybase](https://Keybase.io/) is an app & platform which lets you communicate with friends, family, colleagues, etc (ie: send messages, pictures and files).
Its big point of difference to other social apps is it is [secure](https://Keybase.io/docs/crypto/overview).
"Secure" as in even Keybase can't read your stuff, and even if some bad guy managed to change your stuff, you could tell.

With the [many dramas](https://arstechnica.com/tech-policy/2018/03/facebooks-cambridge-analytica-scandal-explained/) [Facebook suffered in 2018](http://www.abc.net.au/news/2018-03-22/facebook-cambridge-analytica-digital-surveillance-data-privacy/9575160), a few of my technically minded friends and family have been hunting for a replacement.
Keybase is one part of that.

If you're in my family / friend network, I'm asking you to give Keybase a go.
Particularly to send messages and organise events within our personal network(s).
Facebook, while convenient, really doesn't need to know about our birthdays, holidays, photos, gatherings, etc.

If you're a random Internet person, you can use this guide to get a feel for Keybase (as it stands in April 2018).


<a name="keybase-concepts"></a>

## What Is Keybase?

If you don't really care what [Keybase](https://Keybase.io/) is, but just want to start using it (because I'm telling you to install it), [then click here to skip down](#install-windows).
If you're interested in some more details about Keybase, read on.

The iPhone tag line for Keybase is:

> Keybase - Crypto for Everyone

Their website's elevator pitch goes like so:

> Keybase is a new and free security app for mobile phones and computers. 
> For the geeks among us: it's open source and powered by public-key cryptography.

> Keybase is for anyone. 
> Imagine a Slack for the whole world, except end-to-end encrypted across all your devices.
> Or a Team Dropbox where the server can't leak your files or be hacked.

I like to think of Keybase as **managed PGP**.
That is, it's like [PGP](https://en.wikipedia.org/wiki/Pretty_Good_Privacy) in that you can encrypt and sign messages, but Keybase simplifies it and adds to it.
Keybase has quite similar goals to PGP, but has the benefit of 20 years of experience, and really are trying to put crypto in the hands of everyone.


## 4 Things Keybase Does For You

Here's what Keybase actually does for you.

### 1. Cryptography

This isn't a tangible feature you can point at in Keybase, because it pervades absolutely everything it does.
Everything is encrypted, such that bad guys and governments and advertisers can't read it.
Everything is signed, such that everyone who can read your messages knows it really came from you.
Indeed, you can even check your own messages are from you (so the bad guys can't forge messages in your name, and even Keybase can't modify them without your knowledge).

So, you can be confident that your stuff on Keybase is secure.
That is, only people you send messages to can read those messages (and no one else), and you know messages from other people really came from them (and not someone pretending to be them).

### 2. Identity

Figuring out who someone is on the Internet is really, really hard.
Someone you've never met before sends an email to you - how can you be sure they are who they say they are?
How can you be sure your friend / colleague's email is really from them?
Maybe its from some bad guy who wants to [hold your computer to ransom](https://en.wikipedia.org/wiki/Ransomware), or [steal all your contacts](https://en.wikipedia.org/wiki/Spyware), or just hijack your computer to sell as part of a [botnet](https://en.wikipedia.org/wiki/Botnet).

It's actually much easier to have [secret conversation with a random stranger on the Internet](https://en.wikipedia.org/wiki/Diffie–Hellman_key_exchange) (secret as in, no one else can ever read it for the next 100+ years), than it is to be confident of *who they are*.

Keybase proposes a novel way to establish your identity: it leverages existing social media platforms.
That is, Keybase generates a magic message to post on your Facebook, Twitter or website.
And, using the magic of cryptography, you can be confident the owner of that Facebook account or website is the same person as on Keybase.

That is, it creates your Keybase identity via your already established identity on other sites.
And, because you can have multiple "identity anchors", a hypothetical bad guy would need to hack **all** your linked identities to get your Keybase account.

This is the original reason I started using Keybase: it provides anyone on the Internet with a strong guarantee of my identity, and my link to [ligos.net](https://ligos.net), [makemeapassword.ligos.net](https://makemeapassword.ligos.net) or my [Facebook](https://www.facebook.com/ligos/posts/10155025056886775) account. 


### 3. Secure Messaging

Once you know who someone is, you can actually talk to them!

Keybase provides a basic chat app.
You can send messages and pictures to other individuals.
This isn't any different to what you can do with [PGP + email](https://www.symantec.com/products/desktop-email-encryption), or [Facebook Messenger](https://www.messenger.com/), or [Telegram](https://telegram.org/), or [What's App](https://www.whatsapp.com/), or [Signal](https://www.signal.org/), etc.

Except it's 100x easier than the PGP + email option (although [that's not a high bar to jump](https://arstechnica.com/information-technology/2016/12/op-ed-im-giving-up-on-pgp/)).
And at least as secure than all the other apps.
Because a) the identity thing above, b) no one, not even Keybase, can read your messages or feed them into an advertising profile for you.

Now talking to one other person isn't that exciting.
But Keybase lets you create [Teams](https://Keybase.io/blog/introducing-Keybase-teams) or groups of people.
This is basically [Slack](https://slack.com/), but only people in the team can read the messages.

So you can make a team for your family, social group, workplace, etc.
Then send group messages.
And create sub-channels for particular topics within those teams.
You can even securely distribute and store files to your team.


### 4. Secure File Storage

Finally, you can send files securely.

Keybase has a magic [network drive](https://Keybase.io/docs/kbfs), which lets you share files with others.
You upload files to the "K drive" (or `/keybase` folder for MacOS and Linux) and others can access them.
There's a public area, where anyone can access your things via [Keybase.pub](https://Keybase.pub/) (eg: mine is [keybase.pub/ligos](https://Keybase.pub/ligos/)).
A private area where only you (or a small number of people) can access things.
And the same for teams - anyone in your teams can access files.

Anyone who can read your files is confident you really uploaded those files (not someone pretending to be you).
Only the relevant people can see your files (ie: anyone in the public area, just you in the private area, just the team members) - no one else, not even Keybase, can read them.

This isn't quite [DropBox](https://www.dropbox.com/), [Google Drive](https://drive.google.com) or [OneDrive](https://account.microsoft.com/account/onedrive) (because it doesn't have an offline mode), but it's pretty close.
Oh, and Keybase are letting people use 250GB of space (I suspect that won't be the case forever, but its nice for now).


### What Keybase Doesn't Do

Keybase is like [Slack](https://slack.com/) and [DropBox](https://www.dropbox.com/) and [Signal](https://www.signal.org/).
It's for scenarios involving a closed group of people; where you need to be invited into a small group first.

Keybase is **not** like [Twitter](https://twitter.com/) and [Facebook](https://facebook.com/) and [Instagram](https://www.instagram.com/) where you broadcast your thoughts to the whole Internet (or a large chunk of it at least).

Just be aware of what Keybase is and isn't when you get on board.


### Some Negatives

Now, Keybase is still an alpha product (although, it's more than reliable enough for everyday use).
There are a few areas where that "alpha-ness" comes through.

The documentation isn't well maintained.
Not that you need much documentation to use Keybase, but it's never a good look when the doco talks about an "upcoming file sharing system" which has been part of the app as long as I can remember.

As much as Keybase talks about being "Cryptography for everyone", it's still pretty nerdy.
I don't mind that; I'm a nerd.
And it's 100x easier than PGP ever was.
But there are a whole bunch of already established "end-to-end encrypted" chat apps already on the market, which it isn't substantially better than yet.
So it's got a way to go before it really is "cryptography for everyone".

My biggest criticism of Keybase is its **centralised**.
That is, everything sits on Keybase's servers.
Which means there's a single point of failure.
If the servers get hacked / get [DoS-ed](https://en.wikipedia.org/wiki/Denial-of-service_attack) / fall off the network (whether [accidentally](https://www.theregister.co.uk/2003/11/06/microsoft_forgets_to_renew_hotmail/) or [on purpose](https://arstechnica.com/information-technology/2018/04/in-effort-to-shut-down-telegram-russia-blocks-amazon-google-network-addresses)) then it means I can't use Keybase any more.
And more practically, their servers are in America, and only in America.
So me in Australia need to pay a 250ms [latency tax](http://www.verizonenterprise.com/about/network/latency/); or in other words, its slow.

Now, it is an alpha product, so all the above makes total sense.
A truly distributed architecture is 10x harder to code than a centralised one; when you're trying to get something going, starting simple makes lots of sense.
And the way Keybase is built allows for [read-only mirrors](https://Keybase.io/docs/server_security) of their server, which does mitigate the above issues.
But good to be aware of its rough edges.

Overall, I think Keybase is a very solid product for an alpha.
It's certainly not perfect, but more than good enough for my family to give it a go.


<a name="install-windows"></a>

## Step-By-Step Installation: Windows 

Note: There's an [Android Install section below](#install-android).
Or, if you want to [read my commentary on Keybase, scroll up](#keybase-concepts).

The installation process boils down to:

1. Download and install the Keybase app.
2. Sign up for an account.
3. Fill in your profile.
4. Prove ownership of your Facebook account.
    1. Prove ownership of other supported accounts / websites.
5. Create a paper key.7

This might take 15 to 20 minutes for all steps.
You don't have to do it all at once though.


### 1. Download and Install

Go to the [Keybase Download Page](https://Keybase.io/download), download and run it.
Admin account not required.

<img src="/images/Getting-Started-With-KeyBase/windows-install-1-installer.png" class="" width=300 height=300 alt="Keybase Installer" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-2-installing.png" class="" width=300 height=300 alt="Keybase Installing" />

### 2. Sign Up

You need to click **Create** to make a Keybase account with a username and passphrase, then name your computer.
(That error message you see below is because I used a period / dot (`.`) in my username, you can't do that).

<img src="/images/Getting-Started-With-KeyBase/windows-install-3-first-screen.png" class="" width=300 height=300 alt="First Screen" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-4-account-details.png" class="" width=300 height=300 alt="Username (a period isn't a valid character)" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-5-passphrase.png" class="" width=300 height=300 alt="Passphrase - from my password manager" />

You should probably name your computer *"Blogg's Desktop"* or *"My Work Laptop"*, I'm in the 0.001% of people who give their computers public DNS names.
Remember, this name will be publicly visible.

<img src="/images/Getting-Started-With-KeyBase/windows-install-6-computer-name.png" class="" width=300 height=300 alt="Computer Name" />

You'll see the *people* tab after you've completed the sign up process.
This is also where Keybase will nag you about stuff you should do, new features, etc.

<img src="/images/Getting-Started-With-KeyBase/windows-install-7-people-screen.png" class="" width=300 height=300 alt="" />

Well done!
You're up and running!


### 3. Profile

Keybase is about finding real people.
So they ask for a minimal amount of info about you.

Click the **Edit Profile** button on the nag list (or your *Profile* icon in the bottom left).
There's only a few lines you need to enter (and they're all optional).
Note that this is publicly visible.

<img src="/images/Getting-Started-With-KeyBase/windows-install-8-profile.png" class="" width=300 height=300 alt="My Test Account's Profile Details" />

After you click **Save**, you'll see your profile details.
This is the same screen as the bottom left icon.

<img src="/images/Getting-Started-With-KeyBase/windows-install-8a-profile-entered.png" class="" width=300 height=300 alt="My Test Account's Profile" />


#### 3a. Profile Picture

The Windows Keybase app doesn't let you upload a picture of yourself (although it will pick one up from Twitter or Facebook, once you link one of those accounts).
If you want a different picture, you can follow these instructions.
(This all assumes you have a mug shot available on your computer; if not, you'll need to figure that out for yourself).

Browse to the [Keybase website](https://keybase.io) and login.

<img src="/images/Getting-Started-With-KeyBase/picture-1-web-login.png" class="" width=300 height=300 alt="Login to Keybase website" />

Click on your profile picture... well... where it will shortly be.
And upload it.

<img src="/images/Getting-Started-With-KeyBase/picture-2-edit-profile.png" class="" width=300 height=300 alt="Edit your Profile Picture" />

<img src="/images/Getting-Started-With-KeyBase/picture-3-upload.png" class="" width=300 height=300 alt="Upload a Picture from your Computer" />

<img src="/images/Getting-Started-With-KeyBase/picture-4-edit-and-send.png" class="" width=300 height=300 alt="You can Edit your Picture to fit in the Circle. Then click Send." />

And here's your profile with a picture!

<img src="/images/Getting-Started-With-KeyBase/picture-5-profile.png" class="" width=300 height=300 alt="Profile - now with picture!" />



### 4. Prove Ownership of Facebook Account

An important tenet of Keybase is to "prove" ownership of your other accounts on the Internet, to firmly establish your identity.
I'm going to walk through this "proving" process for a (fake) Facebook account (as that's the one my friends and family use the most), other accounts are left as an exercise for the reader.
The process is a bit long, but not particularly difficult.

Start with your *Profile* screen (bottom left).
And click on the *Prove your Facebook* grey link.
You'll need to enter your Facebook username and then make a magic Keybase post on Facebook.
Remember to make it a *public* post.

(If you're like me and you don't know your Facebook username you can find it under [Settings -> General -> Username](/images/Getting-Started-With-KeyBase/facebook-settings-username.png) - I couldn't find it in Facebook apps, so you might need to login with your browser.
Here's [some other instructions](https://support.spryfox.com/hc/en-us/articles/218505798-How-do-I-find-my-Facebook-username-) and some [help from Facebook themselves](https://www.facebook.com/help/211813265517027/)).


<img src="/images/Getting-Started-With-KeyBase/windows-install-9-prove-identity.png" class="" width=300 height=300 alt="Click on the 'Prove Your Facebook' link" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-10-prove-facebook.png" class="" width=300 height=300 alt="Facebook username" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-11-prove-facebook-public.png" class="" width=300 height=300 alt="Remember to make it Public!" />

Keybase flicks over to your browser to post its magic, you'll need to login to Facebook (if you haven't already) and approve Keybase's request to post on your behalf.

<img src="/images/Getting-Started-With-KeyBase/windows-install-12-prove-facebook-login.png" class="" width=300 height=300 alt="Facebook login" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-13-prove-facebook-permission.png" class="" width=300 height=300 alt="Approve Keybase" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-14-prove-facebook-post.png" class="" width=300 height=300 alt="And there's the magic post! (Don't forget to make it Public)" />

Jump back to Keybase and click the **OK posted! Check for it!** button; Keybase will then verify the post you just made.
If you find it doesn't work, double check your post is public - you might need to edit it.

<img src="/images/Getting-Started-With-KeyBase/windows-install-15-prove-facebook-check.png" class="" width=300 height=300 alt="Go check my post!" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-16-proven-facebook.png" class="" width=300 height=300 alt="Verified!" />

<img src="/images/Getting-Started-With-KeyBase/windows-install-17-profile-with-proof.png" class="" width=300 height=300 alt="My profile now says I've linked to my Facebook account" />

Whenever someone loads up your profile, Keybase will check all their "proven" accounts, websites, etc.
Effectively, this is an automatic identity check for anyone you want to talk to on Keybase.


### 4a. Prove Ownership of Other Supported Accounts

There are more accounts you can "prove" in Keybase.
*Twitter* is probably the next most common after Facebook (Keybase will pick up a profile picture from it).
And if you have a website, you can "prove" it as well.
Others are a bit nerdy, but "prove" away if you have a presence on them!

The process is largely the same as the Facebook "proving" - Keybase create a magic file to upload or post to err... post.
Other people can (and will) use that magic to verify your identity.

### 5. A Paper Key

Keybase links your account to your computer.
It stores all the magic keys needed to access your account and decrypt your messages on your computer.
If your computer is lost / stolen / crashes, you lose the data held in Keybase - your contacts, messages, files, etc.

The thing with strong crypto (the kind used in Keybase) is there is no [backdoor](https://en.wikipedia.org/wiki/Backdoor_&#40;computing&#41;).
If you lose or wipe your computer and don't have a paper key, you will lose your chat and files within Keybase. 

To prevent that you create a backup key, or in Keybase terminology, a *"paper key"*.
This is literally a random bunch of words you print out (on paper) as a backup.
(You can accomplish the same thing by installing Keybase on another device - like your phone - but [why have 2 backups when you can have 3](/2017-06-13/How-To-Backup-Your-Computer.html))!

You'll be nagged to create a *paper key* from the *People* tab, or you can click on *Devices* (about half way down the left side).
Then you click *Add New...* -> *New paper key*.
Keybase will think for a moment, then display your paper key.
Copy and paste it and print it out (or write it out by hand).
And then store it somewhere safe (eg: with your passport / in your wallet / in a bank deposit box / at a trusted friend's house).

<img src="/images/Getting-Started-With-KeyBase/paper-key-1-devices.png" class="" width=300 height=300 alt="Devices -> Add New -> Paper Key" />

<img src="/images/Getting-Started-With-KeyBase/paper-key-2-paper-key.png" class="" width=300 height=300 alt="Copy and print it. And write it down." />

<img src="/images/Getting-Started-With-KeyBase/paper-key-3-devices-with-paper-key.png" class="" width=300 height=300 alt="Devices, with a Paper Key" />

The first 2 words of your paper key are public, they're kind of like a username (in this example, `nasty coast`).
Everything else is secret (although I've shown a few words above so you have some idea of what to expect).


<a name="install-android"></a>

## Step-By-Step Installation: Android 

Note: I don't have an iOS device in my house. 
I assume the following instructions would be pretty similar for iOS, but I can't verify them.

I'm also assuming you've already created a Keybase account and installed the app on your desktop.
I'm sure you can swap the order around (phone first, then desktop) and all will be fine, but not in this post!

The installation process boils down to:

1. Download and install the Keybase app.
2. Sign in with your account.
3. Authorise your phone from another device.

### 1. Install From App Store

Go to Google Play and search for *Keybase*.
There's also links from the [Keybase Download Page](https://Keybase.io/download).

Then tap the Keybase icon to start the activation process.

<img src="/images/Getting-Started-With-KeyBase/android-1-first-screen.png" class="" width=200 height=300 alt="Keybase on your phone" />

### 2. Sign In

This is the same as every other service which requires you to sign in.
Punch in your username / email and password.

<img src="/images/Getting-Started-With-KeyBase/android-2-username.png" class="" width=200 height=300 alt="Username" />

<img src="/images/Getting-Started-With-KeyBase/android-3-password.png" class="" width=200 height=300 alt="Password" />

### 3. Authorise

The way Keybase works is that every device can encrypt and sign things (in crypto speak, each device has a unique public / private key pair).
Your first device creates its key pair based on your new account.
But every other device needs to be authorised or provisioned from an existing device.

What all that means is, before you can use Keybase on your phone, you need to punch in a magic code from your desktop.

<small>
(You'll also note that Keybase doesn't always like screenshots taken of it (something about security apparently). 
So some of these images are photos of one phone taken from another).
</small>

<img src="/images/Getting-Started-With-KeyBase/android-4-choose-device.png" class="" width=200 height=300 alt="Choose your device" />

<img src="/images/Getting-Started-With-KeyBase/android-5-scan-code.jpg" class="" width=200 height=300 alt="Scan a QR code (barcode)" />

<img src="/images/Getting-Started-With-KeyBase/android-6-enter-code.jpg" class="" width=200 height=300 alt="Enter your code" />

For whatever reason, the cheap phone I'm using for this demo couldn't scan a [QR code](https://en.wikipedia.org/wiki/QR_code), so I had to manually enter the code.
At this point, you should switch across to your desktop and go to *Devices* -> *Add New Device* -> *New Phone*.

<img src="/images/Getting-Started-With-KeyBase/android-7-new-device.png" class="" width=300 height=300 alt="Desktop - New Device" />

<img src="/images/Getting-Started-With-KeyBase/android-8-scan-code-on-computer.png" class="" width=300 height=300 alt="Scan this code! Or..." />

<img src="/images/Getting-Started-With-KeyBase/android-9-text-code-on-computer.png" class="" width=300 height=300 alt="... Type this one!" />

<img src="/images/Getting-Started-With-KeyBase/android-10-code-entered.jpg" class="" width=200 height=300 alt="Code entered" />

After this, your phone is ready to go!
(And you'll have a new device listed against your profile).

<img src="/images/Getting-Started-With-KeyBase/android-11-people.jpg" class="" width=200 height=300 alt="Keybase on your phone!" />

<img src="/images/Getting-Started-With-KeyBase/android-12-devices-on-computer.png" class="" width=300 height=300 alt="There's my new device" />


## Sample Usage

OK, now we've got Keybase on a few devices, lets actually use it!


### People

The first thing to do is add people you know (or possibly don't, but still need to talk to).
The **People** tab is the default one, at the top left of Keybase.
And at the top, there is a **search** box, type a name in there.

I'm `ligos` on Keybase.
If you're family or friends, go ahead and follow me.
Everyone else, unless you have good reason to chat with me, I'm well practised at ignoring spam!

(Reminder: The People tab is also where Keybase will nag you about new features, changes or best practices).

<img src="/images/Getting-Started-With-KeyBase/people-search.png" class="" width=300 height=300 alt="Searching for myself" />

Once you've found someone, you can see their profile.
Note that all the information here is public; even people without a Keybase account can see it.

<img src="/images/Getting-Started-With-KeyBase/people-profile.png" class="" width=300 height=300 alt="My own profile" />

And finally, you can *follow* people.
This changes the profile's colour (yay, I think).
It also creates a permanent and unchangeable snapshot of that person's profile, which helps further establish their identity.

<img src="/images/Getting-Started-With-KeyBase/people-followed.png" class="" width=300 height=300 alt="Following myself" />


### Chat

Once you've found someone to talk to, you can... well... chat to them.

1:1 chat is pretty straight forward: click the *Chat* button, then send messages back and forward.
There's some limited formatting you can use.
And you can send arbitrary files (not sure if there's a size limit).
And there are emojies (because every chat app needs emojies)!

<img src="/images/Getting-Started-With-KeyBase/chat-basics.png" class="" width=300 height=300 alt="The basics of chat. There's really not much to it." />

There's a small setting icon in the very top right, which lets you turn down the notifications you get as new messages arrive.

<img src="/images/Getting-Started-With-KeyBase/chat-settings.png" class="" width=300 height=300 alt="The basics of chat. There's really not much to it." />

There's also a folder icon which will create a secure shared folder for you and your chat partner.
This throws you out to Windows Explorer on the K Drive (but more on that below under *Files*).

#### Group Messages

You can add several people to one chat conversation, if you like.
In Chat, click the little *New Chat* button next to the search bar, then click the little *Add* icon next to people's names.

<img src="/images/Getting-Started-With-KeyBase/chat-group-message.png" class="" width=300 height=300 alt="Adding people to a conversation." />

But, if you have a group of people you want to talk to frequently, *Teams* are the way to go.


### Teams and Channels

*Teams* are the feature which make Keybase a platform for doing useful stuff.
Teams let you join a number of people together for some common reason - work, leisure, an event, etc.
There are some basic permissions you can assign to team members.
You can create *"channels"*, which allow for smaller groups within your team.
And you can share files between team members too.

<img src="/images/Getting-Started-With-KeyBase/teams.png" class="" width=300 height=300 alt="Teams. People, but in a group." />

Teams are based on a unique name (same as Keybase usernames), and can't be changed - so, in Keybase's own words *"choose carefully"*.
I've gone with `ligos_net`, based on my domain name.

#### Sub-Teams

Once you have a team, you can also create sub-teams for different purposes.
For example, your main team could be company wide, then sub-teams for branches, or divisions, or... well... whatever you want.
Sub-teams are totally separate teams (so different membership and permissions), but only the team admin can create sub-teams (so now I have `ligos_net`, only I can make sub-teams within it).

In my case, I haven't really decided what to do with my sub-teams, other than to have one with my immediate family, and another for wider family.

#### Team Channels 

Team channels are just chat sub-groups within a team.
Members can decide to join and leave channels of their own accord.
There are no special folders or roles which go with them.

Every group has a `#general` channel, but you can add more.

<img src="/images/Getting-Started-With-KeyBase/teams-channels.png" class="" width=300 height=300 alt="Add a #test channel." />

<img src="/images/Getting-Started-With-KeyBase/chat-channels.png" class="" width=300 height=300 alt="The #test channel in chat." />

#### Team Roles

Team admins can assign members one of 4 permissions.
Clicking on a group member lets you assign a role to them (or remove them from the group).
The descriptions in Keybase are pretty self-explanatory.

<img src="/images/Getting-Started-With-KeyBase/teams-roles.png" class="" width=300 height=300 alt="4 roles, to limit what people can break... err... do." />

#### Team Folders

Finally, a team gets a shared folder on Keybase (see below for more details about *Folders*).
This lets a team share files, documents, pictures, whatever between members.
All securely - everything is encrypted.

<img src="/images/Getting-Started-With-KeyBase/teams-folders.png" class="" width=300 height=300 alt="My rather empty ligos_net folder." />


### Files

If you own a Mac or are using a Linux computer, you won't need to activate Keybase's *Folders* feature.
But Windows needs an extra component to make things work.
Phones don't have support for files just yet, which is unfortunate.
(For the technically minded, this is the only part of Keybase which requires admin rights, as it's installing a [kernel driver](https://en.wikipedia.org/wiki/Kernel-Mode_Driver_Framework) to support a [user mode file system](https://en.wikipedia.org/wiki/Filesystem_in_Userspace)).

**UPDATE May 2018**

Since version 1.0.47 (released in May 2018), Keybase has an in-app files interface.
That is, you can browse and download files **without** a *K Drive* or `/keybase`.
This also applies to the mobile app: so you can access and download files on your mobile devices now!

Note that uploading files doesn't seem to be included just yet; perhaps in a future update.

**UPDATE May 2018**

Click over to the *Folders* tab, and there'll be a big red message at the top.
Click on *Display in Explorer*.

<img src="/images/Getting-Started-With-KeyBase/windows-files-1-folders.png" class="" width=300 height=300 alt="Keybase isn't showing in Explorer! Click there to fix it." />

[Dokan](https://dokan-dev.github.io/) is a 3rd party component which lets Keybase create its special "K drive".
You only need to install it once.

<img src="/images/Getting-Started-With-KeyBase/windows-files-2-dokan.png" class="" width=300 height=300 alt="Install Dokan" />

After Dokan is installed, Keybase can do its thing and you get a "K Drive" in Windows Explorer.
(If you're in Linux this will be `/keybase`, and on MacOS it appears on your desktop).

<img src="/images/Getting-Started-With-KeyBase/windows-files-3-k-drive.png" class="" width=300 height=300 alt="Then you have a K Drive." />

Keybase has given everyone 250GB of space on their K drive.
This isn't quite the same as Dropbox (because you have to have Internet access to use it, there's no file versions, etc), but its still pretty good value!
(Personally, I expect that will reduce to the original 10GB at some point in the future, and you'll need to pay money for more - but its big for now).

There are 3 "magic" folders in the K Drive.
You can't create anything in the top level; you have to drill in at least one level first.

#### 1. Private

The contents of **Private** folders are only accessible by you.
You can use this like Dropbox or a shared network drive; as long as you have Internet access, you (and only you) can access files in there.

Actually, that's not quite true, you can create a folder with your username plus someone else's username (with a comma in between), and that is private between just those two users.
Eg: `ligos_shared,ligos` would be shared between myself and my demo account.

(The easiest way to do this is click the folder icon in the top right of any chat, Keybase will sort out all the usernames and commas itself).

#### 2. Public

Whatever you put in your **Public** folders are accessible by anyone.
And not just people within Keybase, but anyone who can browse to [keybase.pub](https://keybase.pub).

While these files are the polar opposite of secret, they are signed.
That means they a) are connected to your Keybase account, and b) can't be changed without other people noticing.

So this is a great place to put public information about you, that people can be confident hasn't been tampered with.


#### 3. Team

The last folder is to share things within your **Teams**.
Each team you're a member of will have a sub-folder in here.
And files are available to any member of those teams.


### Other Things

The only other major feature Keybase supports at the moment is a [Git repository](https://en.wikipedia.org/wiki/Git).
If you're a programmer, you already know what that is.
And if you're not, then you don't need to worry.

I assume that, over time, Keybase will add more stuff.
The most obvious feature (at least in my mind) is voice and video support - that is, it supports chat and file sharing, the two other modes of communication are spoken and visual.


## Conclusion

Keybase is just getting started, but is usable by anyone out there (perhaps with a little help to get going).
It ensures everything is secure, secret and unchangable by default.
Then lets you identify yourself and others.
And finally lets you share things with people, whether in individuals or teams, large files or short messages.

Give it a go!

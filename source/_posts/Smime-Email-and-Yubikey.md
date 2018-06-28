---
title: S/MIME, Email and Yubikey
date: 2017-01-02
updated: 2018-06-28
tags:
- SMIME
- S/MIME
- Email
- eM Client
- Certificate
- X.509
- Yubikey
categories: Technical
---

Sign your emails and save your certificate on a Yubikey.

<!-- more --> 

**UPDATE 2018-06-28**

The [eM Client](https://www.emclient.com/) email program has been updated since original publication (I'm now using version 7.1.31849).
It's support for S/MIME has improved (supporting SHA256 and AES), but it now manages its own certificate store.
Which means my Yubikey isn't required to sign emails; eM Client does everything itself - which isn't as secure as using the Yubikey to protect the certificate.

**END UPDATE**


## Background

I got a pair of [Yubikey's](https://www.yubico.com/products/yubikey-hardware/yubikey4/) for Christmas.
I'd quickly used the [Universal 2 Factor](https://developers.yubico.com/U2F/) "security token" part to add a second factor to my Google and DropBox accounts.
But I was looking for some way I could use them beyond that "security token" style.

The Yubikey 4 is a [PIV compatible smart card](https://www.yubico.com/why-yubico/for-businesses/computer-login/yubikey-neo-and-piv/), which means it can store X.509 certificates and use them to encrypt, sign and authenticate.

(My [work](http://faredge.com.au) is currently evaluating using the smart-card feature as an alternative to Windows logins, so I had some idea of this feature before hand).

My personal computers are not part of a Windows domain, so I couldn't use smart-card based logins.
But I found you can encrypt / sign emails using [S/MIME](https://en.wikipedia.org/wiki/S/MIME), which struck me as a way to make use of the Yubikey.

## The Plan

I read a couple of recent articles from Ars Technica about PGP and email.
[One somewhat negative](http://arstechnica.com/security/2016/12/op-ed-im-giving-up-on-pgp/), the other a bit of a [rebuttal to the first](http://arstechnica.com/information-technology/2016/12/signal-does-not-replace-pgp/).
But the overall impression was that encrypting email was a recipe for disaster, there were too many things which could go wrong and render emails unreadable.
However, signing emails looked like a helpful "value add" which would degrade nicely for people who's email client didn't support S/MIME.
If people could see the mail was signed then that's nice, but otherwise they're no worse off than before.

S/MIME is supposedly well supported and "just works" (because it uses the same X.509 certificate authority hierarchy used by SSL/TLS, as opposed to the more labour intensive PGP).
However, I quickly found that not all email clients support it.
So I'd be looking for a new Windows email app. 

I'd also need to obtain a (preferably free) [X.509 certificate](https://en.wikipedia.org/wiki/X.509) which could be used for signing emails.

Finally, I'd load the cert into my Yubikey such that it is only accessible when it is plugged in.


## Steps 

### 1. Find a New Email Client

I have been using two email clients: Windows Mail (the new client which I'd been using since Windows 10) which I found nicer to compose emails, and Windows Live Mail (and older client which shipped as part of the [Windows Essentials](https://en.wikipedia.org/wiki/Windows_Essentials) suite) which I used to manage emails (mostly for the ability to copy emails between different email accounts).

Windows Mail [only supports S/MIME with an Exchange server](https://technet.microsoft.com/en-us/itpro/windows/keep-secure/configure-s-mime), so that wouldn't work.

I found [eM Client](https://www.emclient.com/), which promised S/MIME support.
It has a free license version which is restricted to two email accounts, which is enough for my purposes.
Installation and configuration was straight forward enough.
And it felt more modern than the aging Windows Live Mail.

I haven't yet found an appropriate app for Android devices.

### 2. Obtain a Certificate

X.509 certificates are a complicated beast.
I've used [StartSSL](https://www.startssl.com/) and [Lets Encrypt](https://letsencrypt.org/) in the past to obtain SSL/TLS certificates, but their purpose is to identify a **server**.
For S/MIME I needed a certificate to identify me as the owner of an **email address**.

(Although, as an important aside, no free S/MIME certificate that I'm aware of connects a real person to the email address. 
All validation is done by magic links in emails. 
So all the certificate is asserting is that *Murray Grant* can receive emails at his email address.
No attempt is made to check that *Murray Grant* is real, or has anything to do with the *ligos.net* domain, or any particular email address under that domain.
All of that requires money for real people to check real documents, and I wasn't going to spend real money on this exercise just yet.)

Lets Encrypt only offers server certs, not personal ones, so it was out of the question.

I've migrated all my websites to use Lets Encrypt instead of StartSSL, but remembered the later offer more certificate options.
I noticed they offered free 3 year **S/MIME Client** certificates, which looked promising.
So I dusted off a neglected StartSSL account and re-validated my email address in preparation for a shiny new certificate.

Until I noticed this:

<img src="/images/Smime-Email-and-Yubikey/startcom-distrusted.png" class="" width=300 height=300 alt="Mozilla and Chrome will Distrust StartSSL's certificates starting January 2017" />

Oh dear.

When certificate authorities get distrusted by browsers, [that usually is game over for them](https://en.wikipedia.org/wiki/DigiNotar).
Further research lead me to the [document the Mozilla Foundation issued](https://docs.google.com/document/d/1C6BlmbeQfn4a9zydVi2UvjBGv6szuSB4sMYUcVrR8vQ/preview#heading=h.39xcc9qyz431) as to why they've come to this decision.
The short version is that StartCom (the company behind StartSSL) got bought by WoSign.
WoSign broke some of the rules certificate authorities must abide by when they issue certificates.
And StartCom were using the same systems and processes as WoSign.

So no StartSSL certificate.
(At least for the next 12 months).


### 3. Obtain a Certificate - Attempt 2

I found that Comodo will issue [free certificates for email](https://www.comodo.com/home/email-security/free-email-certificate.php).
And embarked on their validation process.

The important thing, which doesn't seem to be well advertised, is **you need to use Internet Explorer**.
Chrome wouldn't generate the private key.

As soon as you visit the site, Internet Explorer pops up a message about digital certificates.
You need to say **Yes** to this.
On pretty much every page in the process.

<img src="/images/Smime-Email-and-Yubikey/comodo-certificate-confirmation.png" class="" width=300 height=300 alt="Yes, we are going to do digital certificate stuff. It's OK." />

Start by filling in your name, email to validate and country.
(Just to remind people, the email address is validated, but I could enter any name and county I felt like).

<img src="/images/Smime-Email-and-Yubikey/comodo-create-certificate.png" class="" width=300 height=300 alt="Issue the Certificate to... me!" />

After you enter a revocation password and agree to the terms and conditions, click submit.

<img src="/images/Smime-Email-and-Yubikey/comodo-create-success.png" class="" width=300 height=300 alt="Much Success! (Although we're only half way there)" />

You now have a certificate request pending.
Which means you have a private key on your computer, and you've submitted the public part of the key to Comodo for their stamp of approval.

(If you dig into the [Windows Certificate MMC Snap-in](https://msdn.microsoft.com/en-us/library/ms788967(v=vs.110).aspx), you'll see your half complete cert).

<img src="/images/Smime-Email-and-Yubikey/mmc-certificate-request.png" class="" width=300 height=300 alt="An unvalidated certificate request." />

You then get an email, with a magic link to validate that you do indeed control the email you just entered.
Click the big red button (or, because Internet Explorer is not my default browser, I copied the link and pasted into IE).

<img src="/images/Smime-Email-and-Yubikey/email-confirmation.png" class="" width=300 height=300 alt="Click to get your certificate." />

Comodo then trusts your email and signs your private key as being valid.
Which means the rest of the world now trusts your certificate.

<img src="/images/Smime-Email-and-Yubikey/comodo-install-success.png" class="" width=300 height=300 alt="Much More Success!" />

And if you look in the *Windows Certificate MMC Snap-in* again, you'll find your certificate all ready to go, issued to the email you entered and with a private key.

<img src="/images/Smime-Email-and-Yubikey/mmc-certificate-complete.png" class="" width=300 height=300 alt="The Completed Certificate." />

The last step is to create a backup of your certificate, and especially its private key.
Because if your computer dies, your certificate dies with it.
In the Certificate Snap-in, you can right click and export a certificate.
Just remember to include the private key and stick a password on it.

(Also, if you're going to load the cert into your Yubikey, you'll need that backup file).


## 4. Configure Email Client

Now we have a certificate, we need to tell eM Client to use it.
(Obviously, this step will be different for other email clients, but the overall process of choosing a certificate to use for an email account will be similar).

In the Menu -> Tools -> Settings -> Mail -> Certificates. 
You create a new *Security Profile*.

Create a profile for the email account, and select the certificate which was just created.
I wanted to sign all emails, so I ticked that box.
But left the encrypt by default box unticked.
(After I took the screenshot, I removed the *Encrypt By* certificate, so I can't accidentally encrypt emails).

<img src="/images/Smime-Email-and-Yubikey/eMClient-smime.png" class="" width=300 height=300 alt="Configure The Certificate." />

Unfortunately, eM Client only supports 3DES and SHA1 (rather than the more modern AES and SHA2 functions) at the time of writing (**UPDATE** version 7.1 of eM Client supports AES and SHA2).
Which is OK for my purposes, and it appears they are [planning to support other algorithms](https://forum.emclient.com/emclient/topics/s_mime_algorithms).

## 5. Send A Signed Email

Then I wrote a test email, and sent it to my other email account.
As I wanted to see what it looks like in other mail clients.

I soon found that S/MIME support isn't that wide spread.

### eM Client - Supported

eM Client supports S/MIME, and indicates it via a badge icon and *signed by email@address.com*.

<img src="/images/Smime-Email-and-Yubikey/eMClient-signed-email.png" class="" width=300 height=300 alt="Signed emails have a badge, and the certificate email address." />

### Windows Live Mail - Supported

I've actually once or twice received signed emails in Windows Live Mail, so I know it's supported.
Again, you get a little badge, but no email address next to it (in fairness, the email is a few lines above).

<img src="/images/Smime-Email-and-Yubikey/windows-live-signed-email.png" class="" width=300 height=300 alt="Signed emails have a coloured badge, but no email address." />

### Windows Mail - Not Supported

The new Windows Mail client doesn't seem to support S/MIME signed by public certificates.
I'm guessing it only works for internal Exchange Server certificates.
Instead, you see an unusual attachment, which I presume are attached certificates required to verify the email.
Fortunately, the content of the email is still readable.

<img src="/images/Smime-Email-and-Yubikey/windows-mail-email-signed.png" class="" width=300 height=300 alt="Signed emails have nothing." />

### GMail Web - Not Supported

Again, GMail has nothing special.
Just the unusual attachment.

<img src="/images/Smime-Email-and-Yubikey/gmail-signed-email.png" class="" width=300 height=300 alt="Nothing for GMail either." />

### GMail Android App - Not Supported

If the GMail web app doesn't support S/MIME, it's not surprising that the GMail Android app doesn't either.

<img src="/images/Smime-Email-and-Yubikey/gmail-app-signed-email.png" class="" width=300 height=300 alt="And nothing for the GMail App." />


It's possible that the email clients which don't show the message as signed are doing that because of the obsolete SHA1 hash algorithm.
Although, if that was the case, I'd expect nasty red banners saying the signature isn't valid.

Overall, this is the outcome I was aiming for: people with the right email client will see the signature and get a nice badge, and if your email client doesn't support S/MIME, you're no worse off.


## 6. Copy Certificate to Yubikey

So far, the certificate is stored in the Windows Certificate Store (which I happen to know is a [bunch of files buried deep in your user folder](https://msdn.microsoft.com/en-us/library/windows/desktop/aa388136.aspx)).

That's nice, but it doesn't make any use of the shiny new Yubikey I just got.
(Note: if you don't have a Yubikey, you can quite safely stop here and get all the benefits of S/MIME signatures).

**UPDATE:** version 7.1 of eM Client uses its own certificate store, so it doesn't use my YubiKey any more.


To copy the certificate to your Yubikey, download and install the [Yubikey PIV Manager](https://developers.yubico.com/yubikey-piv-manager/).
This will let you control your Yubikey's smart-card functionality (PIN and loading certificates).

Start the PIV Manager and insert your Yubikey.
You may be prompted to enter a PIN as part of the setup process.
Then click *Certificates*.

smart-cards let you install certificates in "slots".
For our purposes of signing emails, we use the *Digital Signature* slot.
(I'm not sure if there's any special significance to which slot you use).

<img src="/images/Smime-Email-and-Yubikey/yubikey-piv-certificates.png" class="" width=300 height=300 alt="Empty Digital Signature Slot." />

Click *Import from File* and select the `pfx` file you exported as a backup at the end of step 3.
You'll be required to enter the password you set on the `pfx` file.
Then the certificate and private key will be loaded into your Yubikey.

If all goes well, you'll see the following:

<img src="/images/Smime-Email-and-Yubikey/yubikey-piv-certificate-loaded.png" class="" width=300 height=300 alt="Certificate Loaded in the Digital Signature Slot." />

The PIV Manager asked me to remove and then insert the Yubikey before the certificate is usable.
Which I did.

After this, step 7 just magically worked.

### What Happens Behind the Scenes

I was slightly concerned that my private key was still stored with the certificate.
The Certificate Snap-in certainly said it was.

I was also puzzled about how Windows suddenly knew that it needed my Yubikey to use the certificate (and no other certificate in my system).

After adding and removing the certificate from both the Windows certificate store and my Yubikey, I worked out the following:

* The private key may or may not be stored in the normal certificate store, I can't really tell. But Windows knows the private key is *available*.
* The act of loading a certificate into your Yubikey via PIV Manager tags it in some way in your certificate store; Windows knows it needs to use a smart-card to use the private key for that cert.
* There's no obvious indicator in the certificate store that the certificate requires a smart-card. It looks identical to every other certificate with a private key.
* I think / hope (and this is pure speculation on my part) that loading the certificate into a Yubikey destroys the private key on disk such that Window *must* go to the smart-card to make use of the private key.
* You must not remove the certificate from the certificate store; doing so means eM Client can't find the cert and cannot sign email.
* You cannot just have the public key part of the certificate in your certificate store; eM Client is not able to sign because no private key is available.
* Removing the certificate from your Yubikey does not change what Windows knows about the cert; it will still prompt you for a smart-card (you just won't have one that works any more).
* Removing the certificate from the certificate store makes Windows forget it needs a smart-card; in effect, this resets the requirement for the Yubikey.


## 7. Sending an Email With Yubikey

Once the certificate is loading in your Yubikey, you need it present to send signed emails.

The process to send an email is exactly the same as before, but Windows asks for a smart-card and the PIN for it.
If your Yubikey is already plugged in, you are just prompted for the PIN.
Otherwise, you are asked for the smart-card as well (which Windows 10 seems to handle pretty well).

<img src="/images/Smime-Email-and-Yubikey/pin-requested-sending-signed-email.png" class="" width=300 height=300 alt="Certificate Loaded in the Digital Signature Slot." />



## Conclusion

Signing emails using S/MIME works nicely, if you have the right email client.

The main benefit is to prove that you really did write what you said you wrote.
That is, to assure your recipients that your emails don't have a forged `from` field (which usually indicates its spam or contains a malicious attachment / link).

And the Yubikey locks the certificate up, so, even if your computer does have malware, it's really hard for it to send emails signed by you.

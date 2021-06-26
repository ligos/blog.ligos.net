---
title: Be Your Own Certificate Authority
date: 2021-06-26
tags:
- SSL
- Certificate
- CA
- OpenSSL
categories: Technical
---

All the SSL certificates you want for free!! 

<!-- more --> 

## Background

I've used [LetsEncrypt](https://letsencrypt.org/) to generate publicly trusted certificates for any websites I'm running.
And used [InstantSSL](https://www.instantssl.com/ssl-certificate-products/free-email-certificate.html) to generate similar S/MIME certificates for my email.
These are all free services, which is fantastic.

But there are limitations to them: LetsEncrypt requires a level of automation for maintenance - you can't install a certificate and forget about it.
And it works best if you have shell / console access to the machine you want the certificate on, and that machine has public Internet access.

There are other places I'd like certificates, like internal only websites, or routers - they are using plain HTTP, and [browsers get irritated at this "non-HTTPS" thing these days](https://www.blog.google/products/chrome/milestone-chrome-security-marking-http-not-secure/).
And there's more you can use certificates for than just HTTPS: I'd like to have a go at [EAP WiFi](https://en.wikipedia.org/wiki/Extensible_Authentication_Protocol) using certificates, due to an increasing list of security gotchas and issues with WPA2 and WPA3 (EAP is the enterprise equivalent, and seems to have held up better security-wise).

For internal use, I could mint [Self Signed Certificates](https://en.wikipedia.org/wiki/Self-signed_certificate), but they aren't trusted by devices - they encrypt your data but don't provide any clear identity for the service you're connecting to.
And if you have to click through all the security warnings, you're teaching your users the wrong thing.
If I had one root certificate to sign the certs installed on my services, I could trust that one certificate to rule them all and my devices would be happy!

And this is exactly what a Certificate Authority (aka, the companies who sell you SSL certificates) does!
They have a root certificate, trusted by your browser, operating system or device, and then follow special rules to make sure they only mint certificates for the right people.

If I could be my own [Certificate Authority (CA)](https://en.wikipedia.org/wiki/Certificate_authority), I could make whatever certificates I wanted!
Of course, they'd only be trusted by my own computers and devices, but I can live with that.

Indeed, there's a sense in which creating my own certificates is more secure than paying someone else to.
After all, the magic certificates and keys never leave my network.

I'd always thought creating my own certificates would be just too hard.
Then there was a work project that... well... encouraged me to [just do it](https://www.youtube.com/watch?v=5-sfG8BV8wU).

Turns out a few Power Shell commands is all I need.


## Goal

Be my own Certificate Authority.
That is:

* Create a root signing certificate, suitable for signing.
* Mint at least one certificate and install it on an internal web server.
* Install the root CA so browsers trust my internal certificates.


## How Do These Certificate Things Work Anyway?

Before we get to certificates, we start with [asymmetric cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography).
This is a bunch of magic math which let you encrypt and decrypt data - but only in one direction.
"Asymmetric" comes because the key has two parts: public and private.
The public half is available to all and sundry, and lets you encrypt data or verify signatures.
The private half is secret to the owner only, and lets you decrypt data and create signatures.
The public half can never decrypt or sign, and the private half can never encrypt or verify, so they're a bit like one-way mirrors.

```
Data -> Public Key  -> Encrypted / Signature
Data <- Private Key <- Encrypted / Signature
```

Asymmetric Cryptography is used in a number of computing applications and contexts.
The best known is [SSL / TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security) and [HTTPS](https://en.wikipedia.org/wiki/HTTPS).
But it's also used by [SSH](https://en.wikipedia.org/wiki/Secure_Shell_Protocol), [PGP](https://en.wikipedia.org/wiki/Pretty_Good_Privacy) and the infamous [Bitcoin](https://en.wikipedia.org/wiki/Bitcoin).

While asymmetric cryptography is wonderful, but it's just maths.
And maths can be used for lots of things, not all of which are useful.
So, we need to impose rules on what different key pairs can do, when they are valid, what contexts they are valid in, and so on.

In particular, the maths allow us to be very confident of a secret conversation with another party - that's wonderful and a big part of what makes HTTPS "secure".
However, on it's own, it doesn't help identify the other party - so we might be having a very secure conversation with the Bad Guys™, because we couldn't confirm their identiy.


### X.509

Enter [X.509](https://en.wikipedia.org/wiki/X.509).

"SSL Certificates" are actually [X.509 certificates](https://en.wikipedia.org/wiki/X.509).
These are horribly complicated things which define a bunch of properties and rules on top of your public / private key pair.
In the context of HTTPS, they enable reasonably high confidence in the *identity* of the other computer.

One of the rules is "what servers is this certificate valid for" - which corresponds to the name you type into your browser's address bar.
My blog is `blog.ligos.net`, so the certificate must also be valid for `blog.ligos.net` for web browsers to accept it.

<img src="/images/Be-Your-Own-Certificate-Authority/blog.ligos.net-url-web-browser.png" class="" width=300 height=300 alt="blog.ligos.net URL in Web Browser" />

So, the question becomes: how do you get a certificate for `blog.ligos.net`?
Or more specifically, how can someone else validate Murray is really the owner of `blog.ligos.net`?
Or, in the negative, how does the validation process prevent the Bad Guys™ get a certificate for `blog.ligos.net`?

[There's a standard for that](https://en.wikipedia.org/wiki/Certificate_authority#Validation_standards).
If you want to be a Certificate Authority, there are processes you need to follow to check identities before issuing certificates.

There are two common ways, and a third complex one:

1. Send an email to a "special" email address (eg: postmaster@ligos.net) with a magic code. If I own `ligos.net` then I can get access to that code.
2. Let's Encrypt requires creation of the magic file in a well defined location on the web server. If I own `blog.ligos.net` then I can create that file.
3. Conduct one or more manual processes to verify identity, including a voice & video call, inspection of a passport, checking documents, call backs, etc.

The first two ways simply validate someone (or something) controls the domain name or web server.
The third way is a stricter validation of the actual person (or company) identity.

And in practice, all three ways can be faked if you try hard enough.
None are fool proof, but they present enough difficulty to the Bad Guys™ that the system works most of the time.


### Certificate Chaining

One thing I didn't explain is how the Certificate Authority communicates to end users that it successfully validated the `blog.ligos.net` certificate.
That is, if every person who visits `blog.ligos.net` needs to send me an email to verify I own that domain, the whole internet would break very quickly!

The Certificate Authority signs the `blog.ligos.net` certificate to say "yes, this is valid".
As long as you trust the CA, you trust anything the CA has signed, so you trust `blog.ligos.net`.

The Certificate Authority has a **root certificate**, which is the thing your web browser knows about.
That certificate might chain to zero or more **intermediate certificates**.
Before finally `blog.ligos.net` is signed at the very bottom.

This "chaining" allows a small number of trusted root certificates to scale out to the whole Internet.

<img src="/images/Be-Your-Own-Certificate-Authority/blog.ligos.net-certificate-chain.png" class="" width=300 height=300 alt="blog.ligos.net Certificate Chain (this certificate is valid for many ligos.net domains)" />


## PowerShell Commands

OK, enough theory, let's make certificates!

### Certificate Authority

First up, we need to create a root certificate.
This is what will pretend to our very own **Certificate Authority**.

```
PS> New-SelfSignedCertificate 
    -Subject "CN=Grant Root CA 2021,OU=certs@ligos.net,O=Murray Grant,DC=ligos,DC=net,S=NSW,C=AU" 
    -FriendlyName "Grant Root CA 2021" 
    -NotAfter (Get-Date).AddYears(50) 
    -KeyUsage CertSign,CRLSign,DigitalSignature 
    -TextExtension "2.5.29.19={text}CA=1&pathlength=1"
    -KeyAlgorithm "RSA" 
    -KeyLength 4096 
    -HashAlgorithm 'SHA384' 
    -KeyExportPolicy Exportable 
    -CertStoreLocation cert:\CurrentUser\My 
    -Type Custom 
```

There are many options here, let's walk through them all:

* `Subject`: the official name of the entity / person. It is a list of key-value pairs, where the most specific is the left, and least specific on the right. `C` = country, `S` = state, `DC` are parts of domain names (`ligos.net` in my case), `O` = organisation, `OU` = organisation unit, and `CN` = common name. Given we're inventing a CA, you can put whatever you like here!
* `FriendlyName`: is what most browsers display to the user. Best to make it the same as "common name" (`CN`).
* `NotAfter`: indicates when the certificate expires. I've set mine to expire in 50 years, because I only want to create one root certificate (and I'm not expecting to be issuing certs in 50 years time).
* `KeyUsage`: a list of things the certificate is allowed to do, all variations of "signing".
* `TextExtension`: some magic which says "this is a root certificate". This is **essential** for all browsers to trust your certificate as a true certificate authority.
* `KeyAlgorithm`: RSA is the most common, and oldest.
* `KeyLength`: the RSA key size. 4096 is the largest, which is best practise for the root certificate.
* `HashAlgorithm`: SHA384 is higher than the usual 256 bit version. Again, biggest is usually better for root certificates.
* `KeyExportPolicy`: tells Windows we are allowed to export (and backup) the private key. Yes, you need to backup your certificate key!
* `CertStoreLocation`: tells Windows to save the generated certificate in your "Personal" store. More about that below.
* `Type`: there are pre-defined types of certificates. Root certificates are not one of them.

After you run the command, Powershell will tell you the thumbprint for your brand new root certificate. Make a note of this, because you will need it when issuing certificates.

```
Thumbprint                                Subject
----------                                -------
BCCD1A6260025347F3302F10ED1A23CC2DAC75A4  CN=Grant Root CA 2021, OU=certs@ligos.net, O=Murray Grant,...
```

Your private key is currently accessible to any application you run.
Which means, if you get malware on your computer, the Bad Guys™ could create their own certificate that your computer trusts.
Potentially letting them impersonate any website (eg: your bank).

To stop this, you should export the certificate including the private key (which goes somewhere very safe as a backup).
Then re-import it with certificate protection.
This requires a password to be entered each time create a new certificate using your root.

**Steps to Export**

Search for "Manage User Certificates" to open [Certificate Manager](https://www.thewindowsclub.com/certmgr-msc-certificate-manager-windows).
Expand "Personal" > "Certificates".

Right click your new certificate > All Tasks > Export.
Make sure you "export the private key".
And tick "Export all extended properties".

<img src="/images/Be-Your-Own-Certificate-Authority/certificate-export-private-key.png" class="" width=300 height=300 alt="Export CA Certificate for Backup" />

Give you certificate a password and save it.

Finally, delete the certificate from Certificate Manager!

**Steps to Import**

Double click the file you saved.
Import for "Current User".

Ensure "Enable strong private key protection" is ticked. And "Mark this key as exportable" is unticked.

<img src="/images/Be-Your-Own-Certificate-Authority/certificate-import-secure.png" class="" width=300 height=300 alt="Import CA Certificate with Secure Settings" />

Each time you create a new certificate using your root CA, you will be prompted for it's password.
(And you should make 200% sure you have that certificate file backed up; because if you lose it, you have to start again).


### Trusting the Root Certificate

You need to load your root certificate into your operating system certificate store.
Only then will it trust it.

First, repeat the above process to export your certificate **without** the private key:

<img src="/images/Be-Your-Own-Certificate-Authority/certificate-export-public-only.png" class="" width=300 height=300 alt="Export CA Certificate" />

This file can (and should) be redistributed publically.
Anyone who installs it will trust certificates you create.
The onus is on them to verify your identity and decide to trust you (or not).

Import the root certificate into the "Trusted Root Certificate Authorities" store by double clicking and then "Install Certificate".
Be sure to place the certificate in the "Trusted Root Certificate Authorities" store:

<img src="/images/Be-Your-Own-Certificate-Authority/certificate-import-trusted-root.png" class="" width=300 height=300 alt="Import Certificate as Trusted Root" />

You will need to repeat this process on every device that you own.

You may also need to load the certificate into application specific stores, for example, Firefox has its own certificate store that you can find in *Settings*.

<img src="/images/Be-Your-Own-Certificate-Authority/firefox-certificate-manager.png" class="" width=300 height=300 alt="Firefox Certificate Manager (in Settings)" />


### HTTPS Certificate

Now, your device & applications should trust any certificates issued by your brand new Certificate Authority!
Let's make one:

```
PS> New-SelfSignedCertificate 
    -DnsName @("countdooku.ligos.local", "countdooku.ligos.net", "192.168.0.2") 
    -Type SSLServerAuthentication 
    -Signer Cert:\CurrentUser\My\BCCD1A6260025347F3302F10ED1A23CC2DAC75A4
    -NotAfter (Get-Date).AddYears(10) 
    -KeyAlgorithm "RSA" 
    -KeyLength 2048 
    -HashAlgorithm 'SHA256' 
    -KeyExportPolicy Exportable 
    -CertStoreLocation cert:\CurrentUser\My 
```

I'll outline the major differences:

* `DnsName`: this is a special case of "subject". We use a powershell array to list all DNS names we might access this server by. In this example, there's an internal DNS name, a public name, and an IP address. The first name becomes the "common name", others are known as "alternate names".
* `Type`: unlike root certificates, there's a well known type for HTTPS.
* `Signer`: this is the thumbprint of your root certificate.
* `NotAfter`: 10 year expiry. I expect my server will be replaced before then. Be careful setting a longer lifetime than your root certificate.

When you run this command, Windows prompts you for the root certificate password (hopefully, making it difficult for Bad Guys™ to get their hands on your precious root cert):

<img src="/images/Be-Your-Own-Certificate-Authority/windows-password-prompt-for-root-cert.png" class="" width=300 height=300 alt="Windows Password Prompt" />

```
Thumbprint                                Subject
----------                                -------
2368DCAD54D5043EFAF3D8179B843A2E53B436DF  CN=countdooku.ligos.local
```

Once again, your new certificate will be accessible in *Certificate Manager*.
I'm not as paranoid about backing up HTTPS certificates I create.
They cost me 10 minutes of my time - if I lose one or muck it up, I can just create another.

(But just to remind everyone, your root certificate MUST, without fail or exception be backed up)!

After deploying my new certificate, Firefox now trusts my connection to my [TrueNAS](https://www.truenas.com/) server! 
(Even if it has a small disclaimer).

<img src="/images/Be-Your-Own-Certificate-Authority/firefox-trusting-certificate.png" class="" width=300 height=300 alt="Firefox Trusting My Certificate" />


### Code Signing Certificate

The final type of certificate is a "code signing certificate".
Developers may be interested in this to do [code signing of executables and installers](https://en.wikipedia.org/wiki/Code_signing).

```
PS> New-SelfSignedCertificate 
    -Subject "CN=Murray Grant Code Signing,OU=murray.grant@ligos.net,ST=NSW,C=AU" 
    -FriendlyName "Murray Grant Code Signing 2021" 
    -Type CodeSigningCert 
    -Signer Cert:\CurrentUser\My\BCCD1A6260025347F3302F10ED1A23CC2DAC75A4
    -NotAfter (Get-Date).AddYears(10) 
    -KeyAlgorithm "RSA" 
    -KeyLength 2048 
    -HashAlgorithm 'SHA256' 
    -KeyExportPolicy Exportable 
    -CertStoreLocation cert:\CurrentUser\My 
```

There are not many differences:

* `Subject` and `FriendlyName`: we're back to the convention used in the root certificate.
* `Type`: there's a well known type for code signing.


### Export and Convert

I've outlined the process to export certificate using *Certificate Manager* from the Windows Certificate Store.
When you include the private key, you will get a `pfx` file.

<img src="/images/Be-Your-Own-Certificate-Authority/root-cert-icon.png" class="" width=80 height=105 alt="A Windows PFX file (certificate + private key)" />

Different servers use the key pairs and certificates in different formats.
Some can use `pfx` with a password, others require a `pem` file with no password.
They're all a bit different.

So we need to convert the `pfx` into other formats.
Unfortunately, I'm not aware of a powershell command for this, so we resort to using [openssl](https://www.openssl.org/):

```
openssl pkcs12 -in certificate.pfx -out private_key_with_password.key
openssl rsa -in private_key_with_password.pem -out private_key_without_password.key
```

The first command extracts the private key and certificate from a `pfx` file, and saves it in a password protected file.

The second command reads from an encrypted `pem` file, and saves the private key with no password.

You may need to open the files produced by openssl, and copy+paste the contents (to get the exact certificate / key you're interested in), but all the data is available.


## Why PowerShell And Not OpenSSL?

Because OpenSSL is too complicated!

I originally set out to write this article using OpenSSL on a Linux server.
And was confronted by [this document outlining how to do certificates using OpenSSL](https://jamielinux.com/docs/openssl-certificate-authority/index.html).

If you thought this post is long, that link has 7 chapters and about 4400 words of "how to configure openssl" (and very little about how certificates work)!

Quite simply, I don't need revocation servers and serial numbers and all the rest.
I want just enough certificate to make browsers happy when connecting to my TrueNAS server or SyncThing or Mikrotik router.


## Other Resources

The following resources were used to create this post:

* [Microsoft Reference for New-SelfSignedCertificate](https://docs.microsoft.com/en-us/powershell/module/pki/new-selfsignedcertificate?view=windowsserver2019-ps#examples) - this gives a number of useful examples.
* [Further Microsoft Examples for New-SelfSignedCertificate](https://docs.microsoft.com/en-us/dotnet/framework/wcf/feature-details/how-to-create-temporary-certificates-for-use-during-development) - this had the magic text required for a root CA.
* [Build Your own Public Key Infrastructure](https://github.com/HyperSine/Windows10-CustomKernelSigners/blob/master/asset/build-your-own-pki.md) - for kernel code signing, but has good diagrams and examples.
* [How to Create a Self Signed Certificate with Powershell](http://woshub.com/how-to-create-self-signed-certificate-with-powershell/) - simplified versions of this post.
* [How to Convert SSL Certificate to various formats](https://www.ryadel.com/en/openssl-convert-ssl-certificates-pem-crt-cer-pfx-p12-linux-windows/) - I don't pretend to understand `openssl`!


## Conclusion

You are now your very own Certificate Authority!
And can create certificates trusted by... well... whoever you can convince to install your root certificate.

For use within a household, family or small business, this is fine.
And a darn sight cheaper than "real" certificates.

Web browsers will stop nagging you about untrusted and unsecure connections.

(Have I mentioned you need to backup your root certificate enough yet)?
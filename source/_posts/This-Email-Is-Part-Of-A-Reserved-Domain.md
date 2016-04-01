---
title: This Email is Part of a Reserved Domain
date: 2016-04-01 22:00:00
tags:
- Windows 10
- User
- New User
- Microsoft Account
- Custom Domain
- Troubleshooting
categories: Technical
---

Windows 10 - Error when adding a new Microsoft Account with custom domain - This email is part of a reserved domain.

<!-- more --> 

Recently I had cause to delete and re-add my son's account from my computer.
And when I tried to re-add it, I got an error: **This email is part of a reserved domain**

<img src="/images/This-Email-Is-Part-Of-A-Reserved-Domain/error-for-msn-user.png" class="" width=300 height=300 alt="The error message (not my son's real email address)" />

As you can see, this email address isn't a standard `@outlook.com` or `@hotmail.com` account.
It's my own `ligos.net` domain.

Now, this is a completely valid Microsoft account.
I can log in OK at [account.live.com](https://account.live.com), OneDrive works fine with it, and logging in on another computer works OK as well. 

But you cannot add it as a new user on any computer.

(As an aside, this account was created when MSN messenger was a thing, and has been migrated into a Microsoft Live account and a Microsoft account.
And it's worked fine all along.
So three cheers for account migrations!)     



## Workaround

The easiest workaround I found was to go to the Microsoft account and add an email alias under one of the supported domains (eg: `your_email_your_domain_com@outlook.com`).

* Log into [account.microsoft.com](https://account.microsoft.com)
* Click *Your Info*
* Click *Manage your sign-in email or phone number*
* Re-enter your password
* Click *Add Email*
* Enter an email address (eg: `your_email_your_domain@outlook.com`)

<img src="/images/This-Email-Is-Part-Of-A-Reserved-Domain/add-email-alias.png" class="" width=300 height=300 alt="Yep, that's the email alias" />


Adding the user to the computer using the alias email now works fine.
And, as a bonus, once you login, the original (primary) email is picked up and it all looks just like it did before.
The primary email is even shown during login.
And the settings, OneDrive files, etc eventually sync down as well. 

The one very slight difference is that the native Windows user account create on the computer is slightly different.
The original was `msn`, the new one is `msn_l`. 
Which is annoying, because it means all other computers on my network need to be updated for network access, but certainly fixable.   


## Troubleshooting Saga

** Disclaimer **

Just to be clear, the fix above works fine.
Although it strikes me as a workaround, rather than a real solution.

And I still have not found a real solution.
So if you keep reading, you'll just all the things which don't work!

### Stranger and Stranger
  
Now, this whole problem was rather surprising for me, because I had added accounts under the `ligos.net` domain without drama in the past.

Also, if you try to add an account which doesn't exist, it gives a different error message.

<img src="/images/This-Email-Is-Part-Of-A-Reserved-Domain/not-an-account-error.png" class="" width=300 height=300 alt="That account doesn't exist, and has a different error." />

Much searching around the Internet found a few leads, but no solution. 
[This forum user](http://answers.microsoft.com/en-us/windows/forum/windows_10-security/unable-to-add-other-user-using-own-domaincom/27fbfd23-bc0c-4af9-8027-2d5b2f3016cc) had the precise problem, and no useful information at all.
[Another user](http://answers.microsoft.com/en-us/windows/forum/windows_10-security/possible-fix-this-email-is-part-of-a-reserved/a0de1626-c702-4bec-b806-488e8c67589b?auth=1) had the same problem, without a solution; but the same workaround.
[And this thread](http://answers.microsoft.com/en-us/outlook_com/forum/oadmincenter-ocustomdom/this-email-is-part-of-a-reserved-domain-please/bae66c18-98c4-4ed7-b296-ba5fe484065b?page=1) (5 pages long) seems to be the canonical source of information on the problem.
Again, the recommended workaround was to add an email alias. 

### What about domains.live.com  

There was some suggestion that you could authorise your custom domain using [domains.live.com](https://domains.live.com/).
Apparently you add a TXT DNS record to prove you own the domain and let Microsoft trust the domain.  

Now, I had recently migrated DNS providers for my `ligos.net` domain.
And had foolishly not copied all the records across.
So maybe this was the real solution.

<img src="/images/This-Email-Is-Part-Of-A-Reserved-Domain/domains-live-com.png" class="" width=300 height=300 alt="Not what you want to see - domains.live.com." />

Nope.
Domains.live.com has been deprecated for 18 months and was recently shuttered.
So that's no help.

### A missing TXT record

But the idea of a missing TXT record which meant Microsoft stopped trusting `ligos.net` makes sense.

The question is: how do I put it back without domains.live.com?

Well, I have an Azure account with an Azure Active Directory.
So I added and authorised `ligos.net` with a magic TXT DNS record.

But to no avail.

OK, the domains.live.com message talked about migrating email to Office 365.
So I registered a trial Office 365 Home account.
Only to find that Office 365 Home doesn't have any domain options.

So I registered a trial Office 365 Business account, which does have a way to register an external domain (like Azure AD).

<img src="/images/This-Email-Is-Part-Of-A-Reserved-Domain/office-365-domain.png" class="" width=300 height=300 alt="My ligos.net domain is officially registered with Office 365." />

But to no avail. 

### Contact Microsoft?

I was at the end of what I could do by myself.
The next option was to contact Microsoft.

And, I couldn't be bothered.
Because the workaround was 99.9% effective.

Although, I need to leave feedback when cancelling my Office 365 Business trial, so I'll link to this post and see what happens.

## Conclusion
 
If you get the **This email is part of a reserved domain** when adding a Microsft account to Windows 10 registered on a custom domain, add an alias for `@outlook.com` and use that instead.
 
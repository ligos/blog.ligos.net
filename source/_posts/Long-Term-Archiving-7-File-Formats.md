---
title: Long Term Archiving - Part 7 - File Formats
date: 2021-11-28
tags:
- Backup
- Archive
- Church
- Compliance
- Legal
- Archiving-Series
categories: Technical
---

Files to survive 100 years.

<!-- more --> 

You can [read the full series of Long Term Archiving posts](/tags/Archiving-Series/) which discusses the strategy for personal and church data archival for between 45 and 100 years.

## Background

So far, we have considered [the problem and overall strategy](/2021-04-11/Long-Term-Archiving-1-The-Problem.html), and got to [my chosen implementation](/2021-10-29/Long-Term-Archiving-6-Implementation.html).

One key point to consider is: what file formats will stand the test of time?

## Goal

Decide on preferred file formats when saving data onto long term archives.
Such formats should have a high likelihood of being read in 45-100 years.

## Concepts

The longevity of any given file format sits on a spectrum:

```
Short Term <------------------------> Long Term
```

**On the left**, there are propriety formats that require expensive applications (and even specific hardware) to work with.
These are undocumented (sometimes even within the creating company), involve restrictions to make public or open implementations difficult (patents, non-disclosure agreements), are only used in a narrow domains, and can be very complex.

Industrial and medical applications often fall in the category: highly specific, backed by expensive R&D (which means patents to protect that investment), and unavailable outside one product or company.

**On the right**, there are simple, open formats.
These have a public specification, no legal impediments to making sense of the data, and are in common use by millions or billions of people across many different domains.

UTF8 plain text, PDF documents, and PNG images are examples of highly open formats.

And there are plenty of formats in the middle.
Word documents, H.264 encoded videos, and even HTML have dangers as very long term formats.


### Criteria

Here's the criteria I see as important for long term file formats:

* **Open with a specification widely available**. In the end, all digital files and data are a sequence of bytes. If you know how to interpret those bytes, you can make sense of the data.
* **Current usage**. Generally, once applications can view a file, and many people make use of the format, application makers have an incentive to retain their implementation.
* **Age**. Older file formats that have stood the test of time and continue to be used are likely to remain available in the future (even if they one day become legacy).
* **Multiple Implementations**. If there's only one app that can view a file then you have a single point of failure. Two is better. And many is better again.
* **Open Implementations**. Open source apps are best for long term archiving, as they include the instructions for interpreting the file. Free apps are next best. Then commercial implementations from large companies. And finally, you really want to avoid a commercial app from a single, niche company.
* **An Export Function**. Commonly available apps which can translate from one format to another are highly valuable when a migration is required. Being able to export your data from the cloud is crucial.
* **Simplicity**. Simple formats are always easier to implement (or re-implement) than complex ones
* **Patents**. These are a hindrance to free / open implementations, so the fewer patents the better.
* **Security**. A file format that has had security vulnerabilities is dangerous. If there is no way to mitigate security problems, a file format may be removed from applications as a safety measure.

There's plenty of criteria to evaluate there, but I have a very simple rule of thumb:

**If web browsers can view the file format (without extra plugins), its likely to be safe.**

That is, if you can drag the file onto Chrome, Firefox or another web browser, and it Just Works™, its likely to be supported into the future.
Web browsers are about the most ubiquitous software available, and an excellent lowest common denominator.


## Specific File Formats

Now, let’s consider common file formats and how safe they are in the long term.
Only formats rated 4 or 5 will be used in my archives.

### Plain Text

Plain text files have no formatting.
They are about the simplest form of data you can store on a computer.

File Type                          | Rating | Comments
----------------------------------|---------|-----------
**ASCII Plain Text (txt)**   | 5/5 | There's nothing simpler than [ASCII text](https://en.wikipedia.org/wiki/ASCII), as long as you only speak English.
**UTF8 Plain Text (txt)**   | 5/5 | [UTF8](https://en.wikipedia.org/wiki/UTF-8) covers 98% of plain text data on the Internet. All languages are covered. This data should be easily readable in 45+ years. As long as you don't need formatting, all is well.
**Other encoding Plain Text (txt)**   | 2/5 | Yes, there are other text encodings. Best not to bother with unusual standards, they just make it harder to read. And, because plain text files are not self-describing, it can be difficult to know the correct endcoding.


### Structured Data

Structured data is designed to be readable by both computers and humans - although with a priority to computers.

File Type                          | Rating | Comments
----------------------------------|---------|-----------
**JSON**  | 5/5 | [JavaScript Object Notation](https://en.wikipedia.org/wiki/JSON) is mostly human readable in any text editor, and widely readable by computers. A schema is optional and rarely used (which means you usually need to reverse engineer an unfamiliar file). Most software development apps and advanced text editors can "pretty print" JSON.
**XML** | 5/5 | The [Extensible Markup Language](https://en.wikipedia.org/wiki/XML) is more complicated than JSON, but otherwise very similar in terms of outcomes. Schemas are more common. And apps are widely available too.
**CSV / TSV** | 5/5 | While JSON and XML are document orientated, [tab and comma separated files](https://en.wikipedia.org/wiki/Comma-separated_values) are tables of data. Again, they don't have a schema built in, but its usually pretty obvious what the data means. Most spreadsheet apps can read CSV or TSV files.

### Documents

When people think about storing "data" they are usually thinking of documents with text, formatting, images, etc.
I'm including spreadsheets and presentations here too - so the core office productivity apps.

File Type                          | Rating | Comments
----------------------------------|---------|-----------
**DOCX / XLSX / PPTX** | 4/5 | [Microsoft's core Office](https://en.wikipedia.org/wiki/Microsoft_Office) formats are open, have multiple implementations and widely used. Deduct one point because they can't be natively displayed in a web browser, and they do slowly evolve and change. While Microsoft has published a spec, I don't view these are truly open formats. On the other hand they are used pervasively.
**ODT / ODS / ODP** | 5/5 | [OpenDocument](https://en.wikipedia.org/wiki/OpenDocument) file formats are... well... open. Personally, I use Microsoft's formats, but would be perfectly happy keeping these ones instead. As they are explicitly open, they score one point more than Microsoft's formats, although it's worth noting they are much less widely used.
**PDF** | 5/5 | The [Portable Document Format](https://en.wikipedia.org/wiki/PDF) is the gold standard for printable documents. As they are (usually) read-only, they are a great way to keep snapshots at a point in time.
**HTML** | 4/5 | While the whole Internet is built on [HTML](https://en.wikipedia.org/wiki/HTML), it doesn't get used very much for offline or editable documents (minus 1 point). Web browsers speak HTML natively, of course. It also isn't well designed to save a document as a single file.
**RTF** | 4/5 | [Rich Text Format](https://en.wikipedia.org/wiki/Rich_Text_Format) is like DOCX and ODT, but simpler and it hasn't changed in years. Its slightly more likely to be readable in the far future. However, it is a proprietary Microsoft standard.

### Still Images

Family photos is the majority of my personal data.
Many businesses will scan documents as still images or PDFs.

File Type                          | Rating | Comments
----------------------------------|---------|-----------
**JPEG** | 5/5 | [JPEG](https://en.wikipedia.org/wiki/JPEG) images are the gold standard for lossy stills. While there are alternative [digital negative](https://en.wikipedia.org/wiki/Digital_Negative) formats that professional photographers may use, JPEG is readable pretty much everywhere, and has been since the mid 1990s.
**PNG** | 5/5 | [Portable Network Graphics](https://en.wikipedia.org/wiki/Portable_Network_Graphics) are loss-less images. They are ubiquitous on the Internet and viewable everywhere.
**TIFF** | 5/5 | [Tagged Image File Format](https://en.wikipedia.org/wiki/TIFF) is associated with scanners. It's a bit more obscure than the above formats, but been around longer. Its very stable and widely readable.
**WebP** | 4/5 | The [WebP](https://en.wikipedia.org/wiki/WebP) format is aiming to be a PNG successor. Version 1 was published in 2010, making it much younger than other formats (so minus one point). Modern web browsers support it, but it its usage is minimal compared to JPEG and PNG. 
**SVG** | 4/5 | [Scalable Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) is the most open vector format around. All the others listed are bitmaps. Vector graphics are great for icons, fonts and logos that need to grow and shrink. Web Browsers can view SVGs, but they are not as widely supported as the bitmap formats. Various Office apps can export graphics as SVGs, and it is a good long term format for computer aided design files.

### Audio

Music and recordings are important to keep into the far future.
Partly because we love music.
And also because recordings may be of important events (eg: office meetings, police recordings, etc).
At church, we keep audio recordings of each Sunday's Bible talk.

File Type                          | Rating | Comments
----------------------------------|---------|-----------
**MP3** | 5/5 | [MP3s](https://en.wikipedia.org/wiki/MP3) are the gold standard of lossy audio compression. They have been playable since the mid 1990s in many, many apps. A very safe choice for long term storage.
**WMA** | 3/5 | [Windows Media Audio](https://en.wikipedia.org/wiki/Windows_Media_Audio) was a Microsoft specific technology which improves on MP3. While its widely supported, its proprietary and not recommended for new recordings.
**OGG** | 4/5 | While less common than MP3, [Ogg](https://en.wikipedia.org/wiki/Ogg) allows storage of  lossy and loss-less audio, that is generally of higher quality for the same file size. Unlike WMA, it's an open standard. It's widely supported, but not as wide as MP3. No patents.
**AAC** | 4/5 | [Advanced Audio Coding](https://en.wikipedia.org/wiki/Advanced_Audio_Coding) has a similar intent to OGG - improvements over MP3. Although less popular, it is commonly used in mobile devices. No patents.
**WAV** | 5/5 | [Uncompressed audio](https://en.wikipedia.org/wiki/WAV) is wonderfully simple and easy to understand in the future. Unfortunately, WAV files are several times larger than the equivalent MP3. Definitely readable; but not practical, and loss-less alternatives exist.


### Video

Full motion video with audio is everywhere these days.
Family videos are important to keep.
And businesses care as well, as they may record teaching material, meetings, etc.
Since 2020 at church, we keep video recordings of each Sunday's Bible talk.

I'm dividing these into two sub-categories: containers and codecs.
*Containers* are usually the file extension, but they just say how the audio and video is packaged.
*Codecs* are the way you decode and display the video.

Container                          | Rating | Comments
----------------------------------|---------|-----------
**MP4** | 5/5 | [MP4s](https://en.wikipedia.org/wiki/MPEG-4_Part_14) are the most common video container at the moment. And are widely supported.
**AVI** | 5/5 | [AVIs](https://en.wikipedia.org/wiki/Audio_Video_Interleave) are more common on Windows and are an older container.
**MKV** | 4/5 | [Matroska](https://en.wikipedia.org/wiki/Matroska) files are a bit less common, and frequently found in live streaming applications because they file is still readable even if it is stopped unexpectedly (eg: crash or interruption).
**MOV** | 3/5 | [MOV](https://en.wikipedia.org/wiki/QuickTime_File_Format) files are common in the Apple world, based on QuickTime. While readable by many applications, it is not an open format (so minus points).

Note that modern video applications are capable of playing all the above containers.
This was not always the case in 1990s and 2000s.

Codec                          | Rating | Comments
----------------------------------|---------|-----------
**MPEG2** | 5/5 | [MPEG2](https://en.wikipedia.org/wiki/MPEG-2) is the codec used on DVDs and video CDs from the 1990s, and still used in lower quality over the air digital TV broadcasts. Due to its age, it is readable pretty much everywhere. While it was patented, those have now expired. Not recommended for new content as there are better options.
**H.264** | 5/5 | [Advanced Video Coding](https://en.wikipedia.org/wiki/Advanced_Video_Coding) (AVC) is a more advanced codec and used on Blu-Ray disks, OTA TV and streaming services. This produces smaller files than MPEG2, but at a higher quality. All modern devices can play H.264 encoded videos, and it's a great choise for long term archival. Royalties are not payable for non-commercial use.
**H.265** | 4/5 | [High Efficiency Video Coding](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding) (HVEC) is superior again. It's the codec for 4K and 8K broadcasts and many streaming services. It's relatively new and has patents that cause legal issues (minus one point).
**AV1**   | 4/5 | [AV1](https://en.wikipedia.org/wiki/AV1) is an open, patent free, codec that competes with H.265. Technically, the two are quite similar, AV1's big plus is you don't need to pay royalties to use it. However, it's not as widely supported as H.265 (minus one point).

It's worth noting that the video encoding space has evolved faster than still or audio files.
This is because the tech behind still images and audio files invented in the 1990s and 2000s is more than good enough - the quality is acceptable, and file sizes small.
Video, on the other hand, has gone from low definition to standard def, high def, 4K and 8K - and the tech has needed to improve to keep file sizes manageable.

What that means is its quite likely there will be a new (and superior) video codec invented in the next 10-20 years.
But there have been a number of new still image and audio formats invented over the last 20 years, but none were so much better than existing tech to take over - so much less likely for a newcomer.


### Email

There's a stack of data tied up in Email.
All kinds of communication happens via email and it's often important to capture for the long term.
Personally, I prefer to save important emails (or email chains) as a PDF if it needs to be kept for the long term.
And I don't tend to pay as much attention to the [file formats used by my email apps](https://en.wikipedia.org/wiki/Email).

File Format                          | Rating | Comments
----------------------------------|---------|-----------
**EML** | 5/5 | EML files are used by many apps for individual emails.
**MSG** | 4/5 | MSG files are a Microsoft thing used for individual emails by MS Outlook. Minus one point for proprietary, although most modern email apps will read them.
**PST** | 4/5 | A PST file is what MS Outlook uses to store a whole mail box (many emails). While there are various apps to read a PST file, it's still rather proprietary.
**MBOX** | 5/5 | MBOX files are how mail boxes were stored on older UNIX systems. They have carried on into various non-Microsoft email apps. The format is simple and open, so good for reading in 45+ years.


### Databases

There are a stack of database technologies out there.
And an even wider number of implementations such as [MySQL](https://en.wikipedia.org/wiki/MySQL), [SQLite](https://en.wikipedia.org/wiki/SQLite), [MongoDB](https://en.wikipedia.org/wiki/MongoDB), [LevelDB](https://en.wikipedia.org/wiki/LevelDB), and [many others](https://en.wikipedia.org/wiki/Database).

The data in these systems are used by all manner of apps in personal and business contexts.
Our church keeps some records relating to Safe Ministry in a MySQL backed web application.
So keeping this data available in the long term is really important.

Unfortunately, the only reliable way of doing this is to keep upgrading your database system every few years.
Because there's considerable research and development in the database field to improve performance and reduce storage requirements.
Basically, it's in the interests of large companies to improve their data processing.
And that means file formats are constantly evolving.

Generally, it's not too hard to upgrade from version 1 to version 2.
Things get more complicated to go from v2 to v5 though - many systems only support upgrades for one or two versions different (so v2 -> v3 or v4 would be OK, but not v2 -> v5).
Instead, you need to do a multi-step upgrade like v2 -> v4 -> v5.

For this reason, if you want to keep a snapshot of your database available into the far future, the best approach is to export to one of the structured formats above (JSON, XML, CSV or TSV).

While many database systems allow you to make backups, these backups are often very closely related to their main file formats, and come with similar restrictions to the upgrading process (eg: v5 can only restore v4 and v3, but not v2).

The only other option is to maintain your database system and keep it current.
While that's usually a desirable thing, it doesn't always work with compliance requirements like "what did you data look at on 34th Smarch 2312".


### Other Apps

The above lists cover off my requirements.
But many other apps are out there and used for mission critical business scenarios.
I'm not going to make recommendations here, there are simply too many options.

In general, the *database* recommendations of doing regular snapshots is the best approach.
And sometimes that means big exports, or lots of PDFs.


## References

The [National Archives of Australia have good file format recommendations](https://www.naa.gov.au/information-management/storing-and-preserving-information/preserving-information/born-digital-file-format-standards) for digital formats.
They also have details about analogue formats, which isn't my focus here, but may be of interest.


## Conclusion

It's no good to keep your data for 45-100 years, only to find there is no app to read and process it.
Wisely choosing file formats is an important part of your archiving strategy.

Fortunately, the ubiquity of audio, video, still image and documents in our digital lives mean that common files are very likely to be readable in the far future.


**Next up**: In the last part to this series, I will discuss how to organise files on archival disks so they are easy (well, less difficult) to find.

[Read the full series of Long Term Archiving posts](/tags/Archiving-Series/).


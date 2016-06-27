# Contribute content to the AAPB!

**Last Modified: June 14, 2016**

The AAPB seeks to become a centralized web portal of discovery where researchers, educators, students – really anyone – can find 
relevant public broadcasting programs existing either on our own site or on sites belonging to other archives and stations. 
With approximately 1,250 public radio and television stations in existence, one access point will aid scholars interested in 
researching how national or even international topics have been covered in divergent localities over the past 60+ years. AAPB has 
made a start at becoming that portal. 

To this end, the AAPB encourages organizations submitting digitization grant proposals to contribute copies of their 
item-level metadata records, and potentially digitized media, to the AAPB.

If you have any questions, please contact Casey Davis, AAPB Project Manager at [casey_davis@wgbh.org](mailto:casey_davis@wgbh.org). 

### Organizations have several options for contributing to the AAPB:

- Sent us metadata records for content that is not digitized *(in this scenario, skip to #3 below)*
-	Send us metadata records with links to the content accessible on your own digital archive website 
	  - only recommended for organizations committed to preserving their content *(in this scenario, skip to #3 below)*
-	Send us metadata records and proxy files 
    -	only recommended for organizations committed to preserving their content *(in this scenario, the entire document applies to you; simply disregard information about preservation files)*
-	Send us metadata records and digital files for preservation and access *(in this scenario, this entire document applies to you)*

**If your organization is submitting a grant proposal and is interested in contributing content to the AAPB, we ask that 
you [contact us](/contact-us) well in advance of submitting your proposal.**

Once you have initiated communications with the AAPB regarding your proposal, you may use these guidelines to refer the AAPB's 
preferred and acceptable specifications for contributions from donors to the AAPB. This includes file format specifications, 
metadata, and delivery. 

**Our vendor specifications are somewhat different. If you are working with a vendor to digitize your collection, please [contact us](/contact-us) for our vendor specifications.**

Our goal is to make the process of contributing to the AAPB as simple as possible, and we are happy to work with you to 
answer questions and arrange your submission according to your needs and available resources.  

### 1. Collection Acquisitions Form

Organizations seeking to contribute video and audio collections to the AAPB are asked to fill out our [Collection Acquisitions Form](https://s3.amazonaws.com/americanarchive.org/resources/AAPB_collection_acquisitions_form.pdf). Send your completed form to Casey Davis, AAPB Project Manager at casey_davis@wgbh.org. 

### 2. Deed of Gift

The [AAPB Deed of Gift](https://s3.amazonaws.com/americanarchive.org/resources/AAPB_model-deed-of-gift.docx) is an agreement between the collection donor and WGBH and the Library Congress. It is a model deed of gift, which we are open to negotiating with donors, but a version of this agreement must be signed by all donors before contributing video and audio files. 

### 3. Metadata

You do not have to send video and audio files to contribute metadata records to the AAPB catalog. Organizations may submit new and/or updated records to be added to the AAPB catalog in the following ways:

-	[PBCore XML](http://pbcore.org)
-	Send us a spreadsheet export from your database system
-	Use this [spreadsheet template](https://s3.amazonaws.com/americanarchive.org/resources/pbcore_excel_template.xls) if you're just getting started with your inventory. Definitions of each field can be found on the [PBCore website](http://pbcore.org).

Your spreadsheet or PBCore XML should includes as much descriptive and technical information (metadata) about the materials as possible. The metadata should include at the very least, the unique identifier (file name), title, date (if known), format, and duration. But the more information you can provide, the better!

**For organizations contributing vidoe and audio files to AAPB:**
We need you to deliver the metadata prior to the start of digitization.

**For organizations contributing records with URLs to content available on your own website:**
Each record should include a URL to the content. The metadata can be delivered once the digitization is completed.

### 4. Media Files

If your plan to contribute files for preservation in the AAPB, we would prefer that you deliver preservation-quality files and access-quality files. If that is not possible, we are able to accept the original files and make the necessary conversions on our end. 
#### a. Video preservation file

- **Preferred:**  10-bit JPEG2000 reversible 5/3 in a .MXF Op1a wrapper with all audio channels captured and encoded (see below for details)
- **Acceptable:** Original file format

**Video preservation file specification details**
Image essence coding: 10 bit JPEG2000 reversible 5/3 (aka “mathematically lossless”)<br/>
Interlace frame coding: 2 fields per frame, 1 KLV per frame<br/> 
JPEG2000 Tile: single tile<br/>
Color space: YCbCr (If source is analog NTSC (YIQ), PAL or SECAM (YUV), it shall be converted to YPbPr for digitization, which converts to YCbCr in digital)<br/>
Video color channel bit depth: 10 bits per channel<br/>
Native raster: archive file shall match analog original, which maps to 486 x 720 for 525-line (NTSC) sourced material, and 576 x 720 for 625 line (PAL & SECAM) sourced material.<br/>
Aspect ratio: AFD (Automatic Format Description) values shall be provided. 4:3 material shall use the AFD 4:3 code; 16:9 materials shall use the 16:9 code.<br/>
Native frame rate: the frame rate of the original shall be preserved in the file with no conversion (29.97 shall remain 29.97, 25 as 25, etc.)<br/>
Native color space: If the material is analog sourced, YIQ shall be converted to YPbPr before digitization, YUV (PAL & SECAM) to YPbPr before digitization. YPbPr material shall be maintained. RGB analog material shall be maintained as RGB.

#### b. Audio preservation file

- **Preferred:**  BWF (Broadcast WAV) RF64 format (see below for details)
- **Acceptable:** Original file format

**Audio preservation file specification details**
PCM coding, BWF (Broadcast WAV) RF64 format<br/>
48 kHz, 24 bit sampling

#### c. Video proxy file

Video Codec: h.264/AVC<br/>
Codec ID: avcl<br/>
Alternate Name: Advanced Video Codec<br/>
Format profile: Main@L3.0<br/>
Format settings, GOP: M=1, N=30 Bit rate: 711 Kbps<br/>
Width: 480 pixels<br/>
Height: 360 pixels<br/>
Display aspect ratio: 4:3 Color: YUV, 4:2:0, 8 bits Scan type: Progressive<br/>
Audio Codec: AAC 48.0 KHz / 128 Kbps<br/>
Codec ID: 40<br/>
Other Name: Advanced Audio Codec Format profile: LC<br/>
Channel(s): 2 channels<br/>
Wrapper: MPEG-4 (.mp4) wrapper<br/>

#### d. Audio proxy file

192 kbps MPEG-1<br/>
Audio Layer 3 (48 kHz / 16 bits)<br/>
Codec ID: 0x55<br/>
Channels: 2<br/>
Wrapper: mp3<br/>

### 4. Delivery method

Ideally, preservation files would be delivered to the Library of Congress and access files would be delivered separately to WGBH; however, we are open to simplifying the process when possible, such as having the donor deliver only one copy of the files (preservation and proxy or preservation only) to WGBH, which WGBH would then process and deliver on to the Library of Congress.

#### a. to the Library of Congress

- **Preferred:** USB3 drive, exFAT, NTFS, ext3 or ext4 formatted
- **Acceptable:** LTO tape, TAR formatted; Provide blocking factor (over 1024 preferred)

If possible, all files should be written to the chosen media using the [BagIt specification](http://blogs.loc.gov/digitalpreservation/2012/01/from-there-to-here-from-here-to-there-digital-content-is-everywhere/). While this method is preferred, we can accept files written to the USB3 drive(s) in a single directory when received directly from the donor.

#### b. to WGBH

WGBH can provide a USB3 drive(s) to the donor. The donor would then place files into a single directory.

### 5. Intellectual Unit List

Upon delivery of media files, the donor or vendor will need to provide a complete list of filenames. We call this the "Intellectual Unit List." Please provide this list via email when you ship the files.

The list of file names should be in CSV format, semicolon delimited and must have at least one unique Key (index) field. The content of the list depends on the chosen media. 

*For delivery on Hard drive:* A list of filenames and the name of the hard drive. If you are not using the BagIt specification, please also include the md5 checksums (if available).

*For delivery on LTO tape:* A comprehensive list of each GUID on the tape with tape label and filemark (the location of the file on the tape). If you do plan to deliver your files to the Library on LTO tape, please contact us to discuss this requirement.

### 6. File naming conventions

The only requirement is that the file names are unique, are included in the metadata spreadsheet delivered to WGBH, and the file names do not include any spaces or special characters other than underscores and hyphens.

### 7. Checksums

A checksum is used to verify that the files were copied to the storage media without any errors or loss of data. AAPB would like to receive md5 checksums when possible. If you are providing  checksums, we would prefer you include it on both the hard drive and in the intellectual file unit list. At the very least, checksums should be provided on the intellectual file unit list.

### 8. Transcripts

If you have transcripts of the material you are contributing to the AAPB, we would love to have copies. We would prefer to have time-stamped transcripts in .txt, JSON, XML, SRT or WEBVTT, but if you don't have these formats, plain text without timestamps or PDFs would also be useful to have.

Please send copies of the transcripts to WGBH on the hard drive using the same file name as the video/audio files with "_transcript" appended to the filename. The transcripts can be placed in the same directory as the files or in a separate "Transcripts" folder.

### 9. Contracts/Releases

If you have production contracts or appearance releases for the material you are contributing to the AAPB, we would love to have copies to help us determine what we can make available online. Please send copies to WGBH on the hard drive using the same file name as the video/audio files themselves with "_contract" appended to the filename. The contracts can be placed in the same directory as the files or in a separate "Contracts" folder.

### 10. Summary

- **Preservation file:**	to WGBH and the Library of Congress
- **Original file:** to	WGBH and the Library, if no preservation file is available
- **Proxy file:** toWGBH only
- **Transcripts:**	to WGBH, if available
- **Contracts/Releases:**	to WGBH, if available
- **Checksums:**	strongly preferred (md5) by both WGBH and the Library
- **QC Report:**	to WGBH and the Library, if available
- **Technical metadata:**	to WGBH and the Library, if available
- **Preservation metadata:** to WGBH and the Library, if available

If you have any questions, please contact Casey Davis, AAPB Project Manager at [casey_davis@wgbh.org](mailto:casey_davis@wgbh.org). 

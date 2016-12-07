These kickstart files are a bit of a shitshow.  The imgcreator-based ami-creator
doesn't recognize all of the %pre and %post sections the way that Anaconda does
when running from a CD.

Anaconda (used by virtualbox.cfg) runs the %post scripts in both common.cfg and
virtualbox.cfg, but ami-creator only runs the one from common.cfg.  ami-creator
doesn't seem to run *any* %pre scripts.

%pre scripts don't get executed by ami-creator


https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/sect-kickstart-syntax.html

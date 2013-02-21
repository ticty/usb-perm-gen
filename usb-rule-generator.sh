#!/bin/sh
##
## Script help to gain the R/W permission of usb device for some proc
## Bug or suggestion please report to dev.guofeng@gmail.com
##


# temp file name
tmpfile=`mktemp`
rulepath="/etc/udev/rules.d/51-customer.rules"


# permission check
if [ `id -u` -ne 0 ]
then
	echo "please run with root permission"
	exit 1
fi


# system check
if [ -z "`uname -v | grep -i 'ubuntu'`" ]
then
	echo -n "Your system is not a ubuntu system, "
	echo "you may not need to configure usb permission rule"
	echo "But you can continue do this anyway"
	echo ""
	echo -n "Press Enter to continue, or Ctrl+C to quit..."
	read tmp
	echo ""
fi


trap "rm -f $tmpfile" EXIT
trap "echo ""; exit 1" INT QUIT HUP


# get xiaomi usb id info
echo -n "Please plug in xiaomi, then press enter..."
read tmp

lsusb > $tmpfile

echo -n "Please plug out xiaomi, then press enter..."
read tmp


DevInfo=`lsusb | diff - $tmpfile`

if [ `echo $DevInfo | wc -l` -ne 1 ]
then
	echo "Error: you may have plug in/out more than one usb device"
	echo "Please be sure only xiaomi is plug in/out, and try again"
	exit 1
fi


#(5d6 > ) Bus 001 Device 005: ID 18d1:d00d
idVendor=`echo $DevInfo | cut -d ':' -f 2 | cut -d ' ' -f 3`

if [ -z "$idVendor" ]
then
	echo "get device idVendor fail"
	exit 1
fi


# just APPEND to rule file
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"$idVendor\", MDOE=\"0666\", OWNER=\"`logname`\"" >> "$rulepath" 2>/dev/null

if [ $? -ne 0 ]
then
	echo "generate rule file fail"
	exit 1
fi


# restart udev to make new rule effect
service udev restart 1>/dev/null

if [ $? -eq 0 ]
then
	echo "Done !"
else
	echo "restart udev service fail"
	exit 1
fi

exit 0


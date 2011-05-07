#!/bin/bash

#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <mj@casalogic.dk> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Martin Juhl
# ----------------------------------------------------------------------------
#


echo "Welcome to the prime-ng installation v.2.0"
echo "Licensed under BEER-WARE License"
echo
echo "This will enable you to utilize both your Intel and nVidia card"
echo
echo "Please note that this script will only work with 64-bit Debian Based machines"
echo "and has only been tested on Ubuntu Natty 11.04 but should work on others as well"
echo "I will add support for RPM-based and 32-bit later.. or somebody else might..."
echo "Remember... This is OpenSource :D"
echo
echo "THIS SCRIPT MUST BE RUN AS THE ROOT USER OR SUDO"
echo
echo "Are you sure you want to proceed?? (Y/N)"
echo

read answer

case "$answer" in

y | Y )
;;

*)
exit 0
;;
esac

clear
echo "Installing needed packages"
aptitude -y install nvidia-current xdm

echo
echo "Copying nVidia Libraries and drivers"
mkdir -p /opt/prime-ng/lib64
mkdir -p /opt/prime-ng/lib32
mkdir -p /opt/prime-ng/driver

cp -a /usr/lib/nvidia-current/* /opt/prime-ng/lib64/
cp -a /usr/lib32/nvidia-current/* /opt/prime-ng/lib32/

cp /lib/modules/`uname -r`/updates/dkms/nvidia-current.ko /opt/prime-ng/driver

echo
echo "Removing conflicting nVidia files"
echo

aptitude -y --purge remove nvidia-current

echo
echo "Backing up Configuration"
cp -n /etc/bash.bashrc /etc/bash.bashrc.optiorig
cp -n /etc/modprobe.d/blacklist.conf /etc/modprobe.d/blacklist.conf.optiorig
cp -n /etc/modules /etc/modules.optiorig
cp -n /etc/X11/xdm/Xservers /etc/X11/xdm/Xservers.optiorig
cp -n /etc/X11/xorg.conf /etc/X11/xorg.conf.optiorig

echo
echo "Installing Optimus Configuration and files"
cp install-files/optimusXserver /usr/local/bin/
chmod +x /usr/local/bin/optimusXserver
cp install-files/xorg.conf.intel /etc/X11/xorg.conf
cp install-files/xorg.conf.nvidia /etc/X11/
cp install-files/Xservers /etc/X11/xdm/
cp install-files/xdm-optimus /etc/init.d/
cp install-files/virtualgl.conf /etc/modprobe.d/
dpkg -i install-files/VirtualGL_amd64.deb
chmod +x /etc/init.d/xdm-optimus

cp /opt/prime-ng/driver/nvidia-current.ko /lib/modules/`uname -r`/updates/dkms/
depmod -a
if [ "`cat /etc/modprobe.d/blacklist.conf |grep "blacklist nouveau" |wc -l`" -eq "0" ]; then
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
fi

if [ "`cat /etc/modules |grep "nvidia" |wc -l`" -eq "0" ]; then
echo "nvidia" >> /etc/modules
fi

modprobe -r nouveau
modprobe nvidia-current

INTELBUSID=`echo "PCI:"\`lspci |grep VGA |grep Intel |cut -f1 -d:\`":"\`lspci |grep VGA |grep Intel |cut -f2 -d: |cut -f1 -d.\`":"\`lspci |grep VGA |grep Intel |cut -f2 -d. |cut -f1 -d" "\``
NVIDIABUSID=`echo "PCI:"\`lspci |grep VGA |grep nVidia |cut -f1 -d:\`":"\`lspci |grep VGA |grep nVidia |cut -f2 -d: |cut -f1 -d.\`":"\`lspci |grep VGA |grep nVidia |cut -f2 -d. |cut -f1 -d" "\``
echo
echo "Changing Configuration to match your Machine"
echo 

sed -i 's/REPLACEWITHBUSID/'$INTELBUSID'/g' /etc/X11/xorg.conf
sed -i 's/REPLACEWITHBUSID/'$NVIDIABUSID'/g' /etc/X11/xorg.conf.nvidia

CONNECTEDMONITOR="UNDEFINED"

while [ "$CONNECTEDMONITOR" = "UNDEFINED" ]; do

clear

echo
echo "Select your Laptop:"
echo "1) Alienware M11X"
echo "2) Dell XPS 15"
echo "3) Asus N61Jv (X64Jv)"
echo "4) Asus EeePC 1215N"
echo "5) Acer Aspire 5745PG"
echo "6) Dell Vostro 3300"
echo
echo "97) Manually Set Output to CRT-0"
echo "98) Manually Set Output to DFP-0"
echo "99) Manually Enter Output"

echo
read machine
echo

case "$machine" in

1)
CONNECTEDMONITOR="CRT-0"
;;

2)
CONNECTEDMONITOR="CRT-0"
;;

3)  
CONNECTEDMONITOR="CRT-0"
;;

4)  
CONNECTEDMONITOR="DFP-0"
;;
  
5)  
CONNECTEDMONITOR="DFP-0"
;;
  
6)  
CONNECTEDMONITOR="DFP-0"
;;
    
97)
CONNECTEDMONITOR="CRT-0"
;;

98)
CONNECTEDMONITOR="DFP-0"
;;

99)
echo
echo "Enter output device for nVidia Card"
echo
read manualinput
CONNECTEDMONITOR=`echo $manualinput`
;;


*)
echo
echo "Please choose a valid option, Press any key to try again"
read
clear

;;

esac

done

echo
echo "Setting output device to: $CONNECTEDMONITOR"
echo

sed -i 's/REPLACEWITHCONNECTEDMONITOR/'$CONNECTEDMONITOR'/g' /etc/X11/xorg.conf.nvidia

echo
echo "Enabling Optimus Service"
update-rc.d xdm-optimus defaults

echo
echo "Setting up Enviroment variables"
echo

echo "VGL_DISPLAY=:1
export VGL_DISPLAY
VGL_COMPRESS=jpeg
export VGL_COMPRESS
VGL_READBACK=fbo
export VGL_READBACK

alias optirun32='vglrun -ld /opt/prime-ng/lib32'
alias optirun64='vglrun -ld /opt/prime-ng/lib64'" >> /etc/bash.bashrc

echo "Ok... Installation complete..."
echo
echo "Now you need to make sure that the command \"vglclient -gl\" is run after your Desktop Enviroment is started"
echo
echo "In KDE this is done by placing a shortcut in ~/.kde/Autostart or in ~/.kde/share/autostart"
echo
echo "In GNOME this is done by placing a shortcut in ~/.config/autostart/ or using the Adminstration->Sessions GUI"
echo
echo "After that you should be able to start applications with \"optirun32 <application>\" or \"optirun64 <application>\""
echo "optirun32 can be used for legacy 32-bit applications and Wine Games.. Everything else should work on optirun64"
echo "But... if one doesn't work... try the other"
echo
echo "Good luck... MrMEEE / Martin Juhl"
echo
echo "http://www.martin-juhl.dk, http://twitter.com/martinjuhl, https://github.com/MrMEEE/prime-ng"


exit 0

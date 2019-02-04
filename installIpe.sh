#!/bin/bash
# Install Ipe vector drawing software to LaTEX.
# Written by Hildo Guillardi Júnior.
# Licensed under GNU General Propose License 3.0.

#sudo -s
# if not root, run as root.
if (( $EUID != 0 )); then
	#sudo installSoftwares.sh
	echo 'Execute as Super User'
	exit 1
fi
ACTUAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_USER=$(basename ~)
APPLICATIONS='/usr/share/applications'
APPLICATIONS_LOCAL="$HOME/.local/share/applications"
INSTALLERS_FOLDER=$(bash "$ACTUAL_DIR"/getInstallerFolder.sh) ||
	INSTALLERS_FOLDER="$HOME/Downloads"

# Check by any Wine installation. If don't found install the last developed version.
echo 'Checking by LaTEX installation...'
#(dpkg -l | grep -q 'texlive' && echo 'LATEX detected.') || (echo 'Installing LaTEX (texlive)...' sudo apt-get -y install texlive-full)
(dpkg -l | grep -q 'texlive' && echo 'LATEX detected.') || (echo 'Installing LaTEX (texlive)...' sudo apt-get -y install texlive)

echo 'Installing (and compiling) Ipe...'

#sudo apt-get --yes --force-yes install ipe

#sudo apt-get purge ipe # Uninstall.

echo 'Identifying the last version in the server...'

link=https://dl.bintray.com/otfried/generic/ipe/
link=$(bash "$ACTUAL_DIR"/getLastVersionLink.sh $link '[0-9]+\.[0-9]+') &&
link=$(bash "$ACTUAL_DIR"/getLastVersionLink.sh $link 'ipe\-[0-9]+\.[0-9]+\.[0-9]+\-src\.tar\.gz')||
	( echo "Installing default version 7.2.7" &&
	link="https://dl.bintray.com/otfried/generic/ipe/7.2/ipe-7.2.7-src.tar.gz" # Default link.
	)

link="https://dl.bintray.com/otfried/generic/ipe/7.2/ipe-7.2.10-src.tar.gz"
#link="https://dl.bintray.com/otfried/generic/ipe/7.2/ipe-7.2.7-src.tar.gz" #TODO 7.2.8 have a zoom error on Ubuntu 16.04.

version=$(echo $link | grep -ioP '[0-9]+\.[0-9]+\.[0-9]+')
#IPE_DIR_INSTALL=/usr/local/share/ipe/$version/ #/usr/local

IPE_DIR_INSTALL=/usr/local # Default installation directory.
IPE_LIB_FOLDER=/usr/local/share/ipe/$version

#TODO Remove previous version if `/usr/local/share/ipe/$version` exist and does match.
echo 'Removing previous installtions...'
sudo rm $IPE_DIR_INSTALL/ipe* -f # Remove.
sudo rm $APPLICATIONS/*Ipe*.desktop -f # Remove launch shortcuts.
sudo rm $IPE_LIB_FOLDER/../ -fR # Remove installtion.

# Download the selected version.
echo 'Download source code...'
wget $link -O ~/Downloads/ipe-$version-src.tar.gz

# Unzip the source.
echo 'Unpacking files...'
tar -xvzf ~/Downloads/ipe-$version-src.tar.gz -C ~/Downloads/
rm ~/Downloads/ipe-$version-src.tar.gz

# Install necessary libraries and tools.
echo 'Installing dependences...'
sudo apt-get -y install checkinstall qtbase5-dev qtbase5-dev-tools
sudo apt-get -y install libfreetype6-dev libcairo2-dev libjpeg8-dev
sudo apt-get -y install libpng12-dev liblua5.3-dev zlib1g-dev

# Compile the source code.
echo 'Compiling the code...'
cd ~/Downloads/ipe-$version/src
export QT_SELECT=5
make IPEPREFIX=$IPE_DIR_INSTALL # To keep the executable files on the software folder.
sudo checkinstall --pkgname=ipe --pkgversion=$version --backup=no \
	--fstrans=no --default make install IPEPREFIX=$IPE_DIR_INSTALL
sudo ldconfig

# Delete temporary files
echo 'Deleting temporary files...'
#TODO dpkg -r ipe
cd ~/Downloads/
sudo rm -R ~/Downloads/ipe-$version/

# Create a link if necessary
#if [[ $IPE_DIR_INSTALL!="/usr/local" ]]
#then
#	echo 'Creating symbolic link...'
#	sudo ln -s "$IPE_DIR_INSTALL/bin/ipe" /usr/local/bin
#fi

# Copy the library template.
fileTemplate=$(find "$INSTALLERS_FOLDER" -maxdepth 1 -name *Ipe*.pdf)
if [[ -z $fileTemplate ]]; then
	# If not find in the installations folder, try the current folder.
	fileTemplate=$(find "$ACTUAL_DIR" -maxdepth 1 -name *Ipe*.pdf)
fi

test -f "$fileTemplate" &&
	echo 'Creating templates and libraries...' &&
	sudo -u $_USER cp "$fileTemplate" ~/Templates/

# Create the launch desktop link adding to "Open File With..." context menu.
echo 'Creating launch in desktop...'
shortcutFileName='Ipe.desktop'
sudo bash -c "cat >$APPLICATIONS/$shortcutFileName <<EOF
[Desktop Entry]
Type=Application
Name=Ipe
Comment=Ipe extensible drawing editor
Categories=Graphics;2DGraphics
Keywords=latex;tex;pdf
Exec=$IPE_DIR_INSTALL/bin/ipe %F
Path=$IPE_DIR_INSTALL/bin/
Icon=$IPE_LIB_FOLDER/icons/ipe512.png
EOF"

# Add the Ipe shortcut to the list of "Open With"
echo 'Adding Ipe to the "Open With" list...'
association="application/pdf=$shortcutFileName;"
grep -q "$association" $HOME/.config/mimeapps.list ||
	echo "$association" >> $HOME/.config/mimeapps.list # Just local user.

#TODO Change the mouse configuration.
echo 'Returning the mouse configuration to normal (firsts appear at v7.2.9)...'

#if config.platform == "unix" then\n  prefs.scroll.vertical_sign = -1\n end
#/usr/local/share/ipe/7.2.9/lua/prefs.lua


#I change the prefs.scroll.vertical_sign = 1 to prefs.scroll.vertical_sign = -1 (7.2.9)

#prefs.scroll.direction.x
#prefs.scroll.direction.y


#prefs.grid_size = 16     -- points
#prefs.grid_size = 4     -- points


#TODO Install the Ipelets, IPE plugins to expand the functionalities.
#https://github.com/otfried/ipe-wiki/wiki/Ipelets
#https://github.com/otfried/ipelets/tree/master/graphdrawing
echo "Installing Ipelets from \'https://github.com/otfried/ipe-wiki/wiki/Ipelets\'..."

#TODO remover a pasta vazia `scr` colocada em `/usr/local`


echo "Ipe v$version installation success."
exit 0

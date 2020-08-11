#!/bin/bash
# Install Ipe vector drawing software to LaTEX.
# Source: http://ipe.otfried.org/
# Written by Hildo Guillardi Júnior.
# Licensed under GNU General Propose License 3.0.

ACTUAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_USER=$(basename ~)
APPLICATIONS='/usr/share/applications'
APPLICATIONS_LOCAL="$HOME/.local/share/applications"
INSTALLERS_FOLDER=$(bash "$ACTUAL_DIR"/getInstallerFolder.sh) ||
	INSTALLERS_FOLDER="$HOME/Downloads"

#echo 'Installing Ipe by built-in packages...'
#
#echo 'Installing pre-requirements...'
#sudo apt install libqt5gui5 libqtcore5a libqt5widgets5
#sudo apt install libqt5network5 libqt5svg5 libqt5dbus5
#
#echo 'Installing Ipe library...'
#https://download.opensuse.org/repositories/home:/otfried13/xUbuntu_20.04/amd64/libipe_7.2.20-1_amd64.deb
#echo 'Installing Ipe software...'
#https://download.opensuse.org/repositories/home:/otfried13/xUbuntu_20.04/amd64/ipe_7.2.20-1_amd64.deb


# Check by any Wine installation. If don't found install the last developed version.
#echo 'Checking by LaTEX installation...'
#(dpkg -l | grep -q 'texlive' && echo 'LATEX detected.') || (echo 'Installing LaTEX (texlive)...' sudo apt-get -y install texlive-full)
#(dpkg -l | grep -q 'texlive' && echo 'LATEX detected.') || (echo 'Installing LaTEX (texlive)...' sudo apt-get -y install texlive)




echo 'Identifying the last version in the server...'

link=https://dl.bintray.com/otfried/generic/ipe/
link=$(bash "$ACTUAL_DIR"/getLastVersionLink.sh $link '[0-9]+\.[0-9]+') &&
link=$(bash "$ACTUAL_DIR"/getLastVersionLink.sh $link 'ipe\-[0-9]+\.[0-9]+\.[0-9]+\-src\.tar\.gz')||
	( echo "Installing default version 7.2.7" &&
	link="https://dl.bintray.com/otfried/generic/ipe/7.2/ipe-7.2.7-src.tar.gz" # Default link.
	)
#link="https://dl.bintray.com/otfried/generic/ipe/7.2/ipe-7.2.14-src.tar.gz" #TODO 7.2.8 have a zoom error on Ubuntu 16.04.
last_version=$(echo $link | grep -ioP '[0-9]+\.[0-9]+\.[0-9]+')
#IPE_DIR_INSTALL=/usr/local/share/ipe/$last_version/ #/usr/local


IPE_DIR_INSTALL=/usr/local # Default installation directory.
IPE_LIB_FOLDER=/usr/local/share/ipe/$last_version

uninstallSoftware(){
	sudo apt-get purge ipe # Uninstall.
	# Remove previous version if `/usr/local/share/ipe/$last_version` exist and does match.
	echo Forcing removing previous installations...
	sudo rm $IPE_DIR_INSTALL/bin/ipe* -f # Remove application.
	sudo rm $APPLICATIONS/*Ipe*.desktop -f # Remove launch shortcuts.
	sudo rm $APPLICATIONS/*ipe*.desktop -f # Remove launch shortcuts.
	sudo rm /usr/local/share/ipe/ -fR # Remove plugins and configuration folder installtion.
	
	exit 0
}


installSoftware(){
	arch="`uname -m`"
	case $arch in
	  x86_64|amd64)
	    arch='amd64'
	    ;;
	  i?86|x86)
	    arch='386'
	    ;;
	  arm*)
	    arch='arm'
	    ;;
	  aarch64)
	    arch='arm64'
	    ;;
	  *)
	    echo 'OS type not supported'
	    exit 2
	    ;;
	esac

	os_type="`uname -v`"

	os_type=xUbuntu
	os_version=20.04
	link=https://download.opensuse.org/repositories/home:/otfried13/${os_type}_${os_version}/${arch}
	wget $link/libipe_$last_version-1_amd64.deb ~/Download/libeipe.deb
	wget $link/ipe_$last_version-1_amd64.deb ~/Download/ipe.deb

	sudo dpkg -i libipe_* ||
		sudo apt --fix-broken install &&
		sudo dpkg -i libipe_* 
	sudo dpkg -i ipe_*
	
	exit 0
}


downloadCode(){
	# Download the selected version.
	echo Download source code...
	wget $link -O ~/Downloads/ipe-$last_version-src.tar.gz

	# Unzip the source.
	echo Unpacking files...
	tar -xvzf ~/Downloads/ipe-$last_version-src.tar.gz -C ~/Downloads/
	rm ~/Downloads/ipe-$last_version-src.tar.gz
	
	exit 0
}


buildSoftware(){
	# Install necessary libraries and tools.
	echo 'Installing dependences...'
	sudo apt -y install checkinstall zlib1g-dev libgsl-dev
	sudo apt -y install qtbase5-dev qtbase5-dev-tools
	sudo apt -y install libfreetype6-dev libcairo-dev liblua5.3-dev
	sudo apt -y install libjpeg-dev libpng-dev
	sudo apt -y install libcurl4-openssl-dev

	# Compile the source code.
	echo 'Building the application...'
	cd ~/Downloads/ipe-$last_version/src
	export QT_SELECT=5
	make IPEPREFIX=$IPE_DIR_INSTALL # To keep the executable files on the software folder.
	sudo checkinstall --pkgname=ipe --pkgversion=$last_version --backup=no \
		--fstrans=no --default make install IPEPREFIX=$IPE_DIR_INSTALL
	sudo ldconfig

	# Delete temporary files
	echo 'Deleting temporary files...'
	#TODO dpkg -r ipe
	cd ~/Downloads/
	sudo rm -R ~/Downloads/ipe-$last_version/
	
	exit 0
}


copyLibrary(){
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
	
	exit 0
}


createShortcut(){
	IPE_LIB_FOLDER=/usr/share/ipe/$last_version

	# Create the launch desktop link adding to "Open File With..." context menu.
	echo 'Creating launch in desktop...'
	shortcutFileName='ipe.desktop'
	shortcutIcon=`find $IPE_LIB_FOLDER/icons/*.png`
	sudo bash -c "cat >$APPLICATIONS/$shortcutFileName <<EOF
[Desktop Entry]
Type=Application
Name=Ipe
Comment=Ipe extensible drawing editor
Categories=Graphics;2DGraphics;
Keywords=latex;tex;pdf;
Exec=ipe %F
Path=$IPE_DIR_INSTALL/bin/
Icon=$shortcutIcon
EOF"

	# Add the Ipe shortcut to the list of "Open With"
	echo 'Adding Ipe to the "Open With" list...'
	association="application/pdf=$shortcutFileName;"
	grep -q "$association" $HOME/.config/mimeapps.list ||
		echo "$association" >> $HOME/.config/mimeapps.list # Just local user.
}


setConfigs(){
	#TODO Change the mouse configuration.
	echo 'Setting default configurations...'

	#if config.platform == "unix" then\n  prefs.scroll.vertical_sign = -1\n end
	file="/usr/local/share/ipe/$last_version/lua/prefs.lua"
	echo '-- My personal configurations' >> $file
	echo 'prefs.scroll.direction.x = -1' >> $file # Change X direction on the scroll.
	#echo 'prefs.scroll.direction.y = 1' >> $file
	echo 'prefs.initial.grid_size = 4' >> $file # Small grid align.
	echo 'prefs.initial_attributes.pen = "heavier"' >> $file # Heavier trace line.
	echo 'prefs.initial_attributes.farrowsize = "small"' >> $file # Small arrow size back and forward.
	echo 'prefs.initial_attributes.rarrowsize = "small"' >> $file
	#echo 'prefs.initial_attributes.stroke = "darkblue"' >> $file

	#file="/usr/local/share/ipe/$last_version/lua/model.lua"
	#echo 'self.attributes = {
	#    pathmode = "stroked",
	#    stroke = "black",
	#    fill = "white",
	#    pen = "heavier",
	#    dashstyle = "normal",
	#    farrowshape = "arrow/normal(spx)",
	#    rarrowshape = "arrow/normal(spx)",
	#    farrowsize = "small",
	#    rarrowsize = "small",
	#    farrow = false,
	#    rarrow = false,
	#    symbolsize = "normal",
	#    textsize = "normal",
	#    textstyle = "normal",
	#    transformabletext = prefs.transformable_text,
	#    horizontalalignment = "left",
	#    verticalalignment = "baseline",
	#    pinned = "none",
	#    transformations = "affine",
	#    linejoin = "normal",
	#    linecap = "normal",
	#    fillrule = "normal",
	#    markshape = "mark/disk(sx)",
	#    tiling = "normal",
	#    gradient = "normal",
	#    opacity = "opaque", 
	#  }' >> $file

	# /usr/local/share/ipe/7.2.11/styles/basic


	#TODO Install the Ipelets, IPE plugins to expand the functionalities.
	#https://github.com/otfried/ipe-wiki/wiki/Ipelets
	#https://github.com/otfried/ipelets/tree/master/graphdrawing
	#echo "Installing Ipelets from \'https://github.com/otfried/ipe-wiki/wiki/Ipelets\'..."

	#TODO remover a pasta vazia `scr` colocada em `/usr/local`

	exit 0
}

# =================== Entry point ===================

if [[ $# -eq 0 ]] && [[ -z $@ ]]; then
	# if not root, run as root.
	if (( $EUID != 0 )); then
		echo Execute as Super User
		exit 1
	fi
	echo Installing software from built-in packages...
	uninstallSoftware
	installSoftware
	copyLibrary
	createShortcut
	setConfigs
	exit 0
fi

if [[ $@ == '--config' ]]; then
	# if not root, run as root.
	if (( $EUID != 0 )); then
		echo Execute as Super User
		exit 1
	fi
	echo Creating shortcuts...
	createShortcut
	setConfigs
	copyLibrary
	exit 0
fi

if [[ $@ == '--shortcut' ]]; then
	# if not root, run as root.
	if (( $EUID != 0 )); then
		echo Execute as Super User
		exit 1
	fi
	echo Creating shortcuts...
	createShortcut
	exit 0
fi

if [[ $@ == '--lib' ]] || [[ $@ == '--library' ]]; then
	echo Installing libraries...
	copyLibrary
	exit 0
fi

if [[ $@ == '--build' ]]; then
	echo Download and building software from source...
	uninstallSoftware
	downloadCode
	buildSoftware
	copyLibrary
	createShortcut
	setConfigs
	exit 0
fi

if [[ $@ == '--code' ]]; then
	echo Download last source code...
	downloadCode
	exit 0
fi

echo Command not recognized &&
exit 1

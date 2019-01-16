#!/bin/bash
# Find the download link in an web page. Usually used to download the lat version of package or files with the version in the name.
# Inputs: main page (that contains the download link), standard to look for and match (insensitive case).
#  Example: `getLastVersionLink.sh https://dl.bintray.com/otfried/generic/ipe/ '[0-9]\.[0-9]'`
# Output: the full link to download (recognized the last version) or error if don't found.
# Written by Hildo Guillardi Júnior.
# Licensed under GNU General Propose License 3.0.

link=$(wget -qO- $1 | grep -oiP "\<a.+href\s*=\s*[\"\']*([^\>\"\']*$2[^\>\"\']*?\/*)[\"\']*[^\>]*\s*\>" | sed -n "s/<a.*href *=[ \"\']*\([^\"\'> ]*\)[\"\' >]*.*/\1/p") # Read the page, get the link that match (may have many configurations inside the tag) and remove the tag parts (and configurations.
numberLinks=$(echo "$link" | wc -l)
if (( $numberLinks > 1)); then
	echo "Got more the one site match to $2 in $1." >&2
	link=$(echo "$link" | sort -n | tail -1) # Alphabetic-ascii reverse order to recognize the last version in the case of presence of more than one link that match.
	echo "Selected '$link'." >&2
fi
#	# Some site have a wrong pattern in some link (case of the IPE repository site, the sub folders and files link, that have to use the site dominion, start with wrong ":").
#	link=${link##:}
if [[ $link == '' ]]; then
	exit 1
fi
# Test if is a valid link or miss the dominion of part of the link (own site).
regex='((https?|ftp|file)://?|www.)[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
if [[ $link =~ $regex ]]; then
	echo $link
	exit 0
else
	# Check if the partial link start if "./" (add this actual page) or "/" (add just the main dominion).
	if [[ $link == :* ]]; then
		echo ${1%%/}/${link##:} # Put the actual sub page.
	elif [[ $link == /* ]]; then
		echo $(echo $1 | sed -e 's|http://||g' -e 's|https://||g' -e 's|ftp://||g' -e 's|/.*$||g')/${link##/} # Put the dominion.
	else
		echo ${1%%/}/$link # Put the actual sub page.
	fi
	exit 0
fi
exit 1 # Return ERROR.

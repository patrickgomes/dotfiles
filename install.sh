#!/bin/bash

# ------------------------ CONSTANTS -------------------------

# Terminal colors
readonly BLUE='\e[1;34m'
readonly RED='\e[1;31m'
readonly WHITE='\e[0;37m'

# Directories & Files
readonly SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
readonly BACKUP_DIR="$SCRIPT_DIR/backups"
readonly CONFIG_DIR="$SCRIPT_DIR/config"
readonly SOURCE_DIR="$SCRIPT_DIR/source"
readonly USER_CONFIGS="$SCRIPT_DIR/user_configs_$$.tmp"

# Tool & dependencies
DEV_TOOLS="git stow make wget cmake autoreconf"

#i3BuildDeps="libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf libxcb-xrm-dev"
#i3RuntimeDeps="zsh termite vim xuberant-ctags ranger qutebrowser htop fonts-font-awesome i3lock-fancy feh dmenu compton"

# ------------------------ FUNCTIONS  -------------------------

printUsage() {
    script=$(basename "$0")
    echo "Usage: sudo $script [-option]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "    --help    Print this message" >&2
}

commandIsAvailable()
{
	which "$1" > /dev/null 2>&1
	return $?
}

scanUserConfigFiles()
{

	echo "$BLUE Scanning for preexisting user configuration files... $WHITE";
	truncate -s0 $USER_CONFIGS

	IFS=$'\0'
	for appDir in $(find "$CONFIG_DIR" -type d -maxdepth 1 -print0)
	do
		for newConfig in $(find "$appDir" -type f -print0)
		do
		   oldConfig=~${newConfig#$appDir}
		   if [[ -e "$oldConfig" ]] 
		   then
		   		resolvedPath="$(readlink -e "$oldConfig")"
		    	[[ "$resolvedPath" != "$newConfig"]] && (echo "$oldConfig" >> "$USER_CONFIGS")
		   fi
		done
	done
	unset $IFS

	nbrConfigs=$(wc -l $USER_CONFIGS)
	echo "There are $nbrConfigs preexisting files in your home directory that will be overwritten."
	read -p "View files? (y/n)" -n 1 -r view && echo

	[[ $view =~ ^[Yy]$ ]] && sort $USER_CONFIGS | less 

	echo "Scan done."
}

backupCurrentUserConfig() 
{
	# No need to bother if there are no pre-existing configurations files
	if ! [[ -d ~/.config ]]
	then
		return
	fi

	echo "There are pre-existing configuration files in ~/.config."
	read -p "Perform backup? (y/n)" -n 1 -r performBackup && echo

	if [[ $performBackup =~ ^[Yy]$ ]]
	then
		backupArchive=$~/.user_config_backup_$(date +%FT%H%M%S).tar.gz

		while true
		do 
			read -p "Enter backup archive (default $backupArchive):" -r userChoice

			if [[ -z $userChoice ]] || [[ -w dirname "$userChoice" ]] && ! [[ -e "$userChoice" ]]
			then
				[[ -n $userChoice ]] &&  backupArchive=$userChoice
				break
			else
				echo "$RED $backArchive: file exists or insufficient permissions on parent directory $WHITE"
			fi
		done
	fi
}

stowConfig()
{
	echo "$BLUE Stowing configuration files in user home... $WHITE"
	IFS=$'\0'
	for appDir in $(find "$CONFIG_DIR" -type d -maxdepth 1 -print0)
	do
		for newConfig in $(find "$appDir" -type f -print0)
		do
		   oldConfig=~${newConfig#$appDir}
		   [[ -e "$oldConfig" ]] && echo "Removing  $oldConfig" && rm -r "$oldConfig"
		done
	done
	unset $IFS

	cd $CONFIG_DIR
	stow -t ~ * 
	
	if $? 
	then
		echo "Done."
	else
		echo "$RED Stowing of configuration files failed. Remove the problematic files (see above) and run \"$0 --stow\" to retry."
	fi
	cd -
}


installI3() 
{
		echo "$BLUE Building and installing i3 environment $WHITE"
		sudo apt install $i3BuildDeps $i3RuntimeDeps

		cd "$sourceDir/i3-gaps"

		# compile & install
		autoreconf --force --install
		rm -rf build/
		mkdir -p build && cd build/

		# Disabling sanitizers is important for release versions!
		# The prefix and sysconfdir are, obviously, dependent on the distribution.
		../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
		make
		sudo make install

		commandIsAvailable i3 && echo "$RED i3 installation suceeded $WHITE." || echo "$RED i3 installation failed $WHITE."
}

# ------------------------ MAIN -------------------------

missingTools="false";
echo "$BLUE Checking availability of development tools... $WHITE"

for tool in $DEV_TOOLS
do
	commandIsAvailable $tool && echo "$tool Ok" || echo "$RED $tool NOK $WHITE" && $missingTools="true"
done

[[ $missingTools == "true" ]] || echo "Aborting. Some tool(s) are missing on your system. Please install them and rerun this script." && exit 1;

scanUserConfigFiles

#if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; || [[ $(whoami) !== "root" ]] then
#    printUsage
#    exit 0
#fi



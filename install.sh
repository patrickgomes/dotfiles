#!/bin/bash

# ----------------------- PRECAUTIONS ------------------------

set -o nounset
# set -o errexit

# ------------------------ CONSTANTS -------------------------

# Error codes
readonly E_MISSING_TOOLS=1
readonly E_PARALLEL_INSTALL=2

# Temporary directories & files
readonly TMP_DIR="/tmp/install_$(whoami)_env"
readonly LOCKFILE="$TMP_DIR/lockfile"
readonly OLD_CONFIG_PATHS="$TMP_DIR/old_config_paths"

# Non-temporary directories & files
readonly SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
readonly BACKUP_DIR="$SCRIPT_DIR/backups"
readonly CONFIG_DIR="$SCRIPT_DIR/config"
readonly SOURCE_DIR="$SCRIPT_DIR/sources"
readonly USER_HOME=$(echo ~)

# Dependencies
readonly DEV_TOOLS="git stow make wget cmake autoreconf"
readonly FONTS="fonts-font-awesome fonts-powerline"
readonly VTE_NG_BUILD_DEPS="g++ libgtk-3-dev gtk-doc-tools gnutls-bin valac intltool libpcre2-dev libglib3.0-cil-dev libgnutls28-dev libgirepository1.0-dev libxml2-utils gperf"
readonly I3_BUILD_DEPS="libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf libxcb-xrm-dev"
readonly I3_RUNTIME_DEPS="zsh vim exuberant-ctags ranger qutebrowser htop i3lock-fancy feh compton suckless-tools"

# Terminal colors
readonly BLUE='\e[1;34m'
readonly RED='\e[1;31m'
readonly WHITE='\e[0;37m'

# -------------------------- ALIASES ----------------------------
alias pushd=>/dev/null pushd
alias popd=>/dev/null popd

# ------------------------ FUNCTIONS --------------------------

# print_usage -- TODO: Work in progress
function print_usage()
{
    script=$(basename "$0")
    echo "Usage: sudo $script [-option]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "    --help    Print this message" >&2
}

# cmd_avl() -- Checks whether the command passed as argument is installed on the system and is somewhere in $PATH
function cmd_avl()
{
	which "$1" > /dev/null 2>&1
	return $?
}

# scan_old_configs -- Searches the home directory for configurations files that will be replaced by this script
#					  and keeps track of their locations in $OLD_CONFIG_PATHS for future reference.
function scan_old_configs()
{
	local old_config resolved_path

	echo "$BLUE Scanning for preexisting user configuration files... $WHITE";
	
	truncate -s0 $OLD_CONFIG_PATHS
	for new_config_dir in $(find "$CONFIG_DIR" -maxdepth 1 -type d)
	do
		for new_config in $(find "$new_config_dir" -type f)
		do

		   old_config="$USER_HOME"${new_config#$new_config_dir}
		   if [[ -e $old_config ]] 
		   then
		   		resolved_path="$(readlink -e "$old_config")"
		    	[[ $resolved_path != $new_config ]] && echo "$old_config" >> "$OLD_CONFIG_PATHS"
		   fi
		done
	done
}

# bkp_old_configs -- Performs a backup of the configuration files listed in $OLD_CONFIG_PATHS according to user wishes.
function bkp_old_configs() 
{
	local nbr_old_configs view perform_bkp bkp_archive user_choice 

	scan_old_configs
	nbr_old_configs=$(wc -l < "$OLD_CONFIG_PATHS")
	[[ $nbr_old_configs -eq 0 ]] && echo "No configuration files in home directory to backup." && return

	echo "There are $nbr_old_configs configuration files in your home directory that will be replaced."

	echo -n "View files (y/n)?"
	while read -n 1 -r -s view;
	do
		[[ $view =~ ^[Yy]$ ]] && { sort "$OLD_CONFIG_PATHS" | less; break; }
		[[ $view =~ ^[Nn]$ ]] && break
	done

	echo -n -e "\nPerform backup? (y/n)"
	while read -n 1 -r -s perform_bkp
	do
		[[ $view =~ ^[YyNn]$ ]] && break 
	done
	echo

	if [[ $perform_bkp =~ ^[Yy]$ ]]
	then
		bkp_archive=$USER_HOME/config_backup_$(date +%FT%H%M%S).tar.gz

		while read -e -p "Backup archive:" -i $bkp_archive -r user_choice
		do 
			[[ -w $(dirname "$user_choice") && ! -e "$user_choice" ]] && break
			echo "$RED $backArchive: file exists or insufficient permissions on parent directory $WHITE"
		done
		
		tar -cvzf "$bkp_archive" --verbatim-files-from -T "$OLD_CONFIG_PATHS" > /dev/null  2>&1 || echo "Could not backup $bkp_archive"
		echo "Backup done."
	fi
}

# install_configs -- Replaces the configuration files listed in $OLD_CONFIG_PATHS with symlinks to those in $CONFIG_DIR
function install_configs()
{
	cat $OLD_CONFIG_PATHS | xargs -0 rm -f && stow -d "$CONFIG_DIR" -t ~ * 
	return $? 
}

# install_termite -- Builds the termite terminal-emulator (including dependencies) and installs it.
# 		     See https://github.com/Corwind/
function install_termite()
{
	local ret_val

	pushd "$SOURCE_DIR/vte-ng"
	sudo apt install $VTE_NG_BUILD_DEPS
	./autogen.sh && make && sudo make install

	cd "$SOURCE_DIR/termite" && make && sudo make install
	sudo ldconfig 
	sudo mkdir -p /lib/terminfo/x; sudo ln -s /usr/local/share/terminfo/x/xterm-termite /lib/terminfo/x/xterm-termite
	sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/termite 60

	cmd_avl termite
	ret_val=$?
	
	popd && return $ret_val
}

# install_i3 -- Installs i3-gaps build and runtime dependencies and subsequently builds the i3-gaps window manager project
function install_i3() 
{
		local ret_val

		sudo apt install $I3_BUILD_DEPS $I3_RUNTIME_DEPS

		pushd "$SOURCE_DIR/i3-gaps"
		# compile & install
		autoreconf --force --install
		rm -rf build/
		mkdir -p build && cd build/

		# Disabling sanitizers is important for release versions!
		# The prefix and sysconfdir are, obviously, dependent on the distribution.
		../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
		make
		sudo make install

		cmd_avl i3
		ret_val=$?
		popd

		return $ret_val
}

# ------------------------ MAIN -------------------------

# main -- Launches the installation procedure.
# 		  Checks for required commands and other running instances of this script.
function main()
{
	local missing_tools

	echo "$BLUE Checking availability of development tools... $WHITE"

	missing_tools=;
	for tool in $DEV_TOOLS
	do
		cmd_avl $tool || missing_tools="$missing_tools $tool"
	done

	if	[[ -n $missing_tools ]]
	then
		echo "Aborting. The following commands are missing on your system: $missing_tools";
		echo "Please install them on your system and rerun $0.";
		exit $E_MISSING_TOOLS; 
	fi

	mkdir -p "$TMP_DIR"
	if ( set -o noclobber; echo "$$" > "$LOCKFILE") 2> /dev/null;
	then
		trap 'rm -fr "$TMP_DIR"; exit $?' INT TERM EXIT

		# Start critical section
		install_termite
		# install_i3
		# bkp_old_configs
		# End critical section

		rm -fr "$TMP_DIR"
		trap - INT TERM EXIT
	else
		echo "Failed to acquire lockfile: $LOCKFILE"
		echo "Parallel installation process (pid $(cat $LOCKFILE)) is running."
		exit $E_PARALLEL_INSTALL
	fi
}


main

# TODO: Extend script with arguments
#if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; || [[ $(whoami) !== "root" ]] then
#    print_usage
#    exit 0
#fi



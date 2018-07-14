#!/bin/bash

#TODO: Check if dependencies are installed (git, stow, make, wget, cmake, autoreconf, ...?)

blue='\e[1;34m'
red='\e[1;31m'
white='\e[0;37m'

CMD="$1"
dotfilesdir=$(pwd)
backupdir=~/.dotfiles.orig
dotfiles=(.i3 .zsh .aliases .bash_profile .bash_prompt .bashrc .dircolors .editorconfig .exports .functions .gemrc .tmux.conf .wgetrc .Xresources .zshrc)
dotfiles_config=(.alacritty .compton .dunst .htop .i3blocks .rofi)

scriptDir=$(readlink -f  "$(dirname $0)")
backupDir=$scriptDir/backups
configDir=$scriptDir/config
srcDir=$scriptDir/source
backupArchive=$backupsDir/user_config_backup_$(date +%FT%H%M%S).tar.gz
appPackages=zsh termite vim xuberant-ctags ranger qutebrowser htop
i3BuildDeps=libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf libxcb-xrm-dev
i3RuntimeDeps=fonts-font-awesome i3lock-fancy feh dmenu compton
# linux-confiddg
Experimental linux work setup configuration with i3-gaps, zsh, ...

gnome-session vanilla-gnome-desktop vanilla-gnome-default-settings 
termite vim ranger git make tree htop zsh stow 
arc-theme papirus-icon-theme lxappearance fonts-font-awesome 
i3 i3blocks i3lock-fancy feh dmenu compton 
pkg-config xuberant-ctags 
qutebrowser


/*** Manual installations ***/

--- i3-gaps ---
git clone https://github.com/Airblader/i3blocks-gaps.git

-- i3blocks-gaps ---

git clone https://github.com/Airblader/i3blocks-gaps.git

--- Oh-My-Zsh ---
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"


printUsage() {
    script=$(basename "$0")
    echo "Usage: sudo $script [-option]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "    --help    Print this message" >&2
}

install() {

		echo "###############################################################################"
		echo "	1)  Backing up user configuration files to $backupArchive"
		echo "###############################################################################"

		# TODO: Do I need to set the IFS to?
		IFS=$'\0'

		for appDir in $(find "$configDir" -type d -maxdepth 1 -print0)
		do
			for $newConfig in $(find "$appDir" -type f -print0)
			do
				oldConfig=~${newConfig#$appDir}
				echo "Backing up $oldConfig"

				if [ -f "$oldConfig" ]
					tar -rvf "$backupArchive" "$oldConfig"
					rm "$oldConfig"
				fi
				#TODO: Handle the case where $oldConfig is not a regular file
				#TODO: Compress archive
			done
		done

		unset $IFS


		echo "Backup done."

		echo "###############################################################################"
		echo "	2)  Installing packages"
		echo "###############################################################################"
		apt install $appPackages 

		echo "###############################################################################"
		echo "	3)  Installing i3"
		echo "###############################################################################"
		apt install $i3BuildDeps $i3RuntimeDeps

		if ! [[ -e "$sourceDir/i3-gaps" ]] 
		then
			cd "$sourceDir"
			# clone the repository
			git clone https://www.github.com/Airblader/i3 i3-gaps
			cd i3-gaps

			# compile & install
			autoreconf --force --install
			rm -rf build/
			mkdir -p build && cd build/

			# Disabling sanitizers is important for release versions!
			# The prefix and sysconfdir are, obviously, dependent on the distribution.
			../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
			make
			make install
		fi

		echo "###############################################################################"
		echo "	4)  Installing "
		echo "###############################################################################"
		/usr/bin/apt install $i3Deps

		if ! [[ -e "$sourceDir/i3-gaps" ]] 
		then
			cd "$sourceDir"
			# clone the repository
			git clone https://www.github.com/Airblader/i3 i3-gaps
		fi
			cd i3-gaps
			git pull

			# compile & install
			autoreconf --force --install
			rm -rf build/
			mkdir -p build && cd build/

			# Disabling sanitizers is important for release versions!
			# The prefix and sysconfdir are, obviously, dependent on the distribution.
			../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
			make
			make install
		fi
		
		
#
##        # Backup to ~/.dotfiles.orig
##        for dots in "${dotfiles[@]}"
#        do
#            /bin/cp -rf ~/${dots} $backupdir &> /dev/null
#        done
#
#        # Backup some folder in ~/.config to ~/.dotfiles.orig/.config
#        for dots_conf in "${dotfiles_config[@]//./}"
#        do
#            /bin/cp -rf ~/.config/${dots_conf} $backupdir/.config &> /dev/null
#        done
#
#        # Backup again with Git.
#        git init &> /dev/null
#        git add -u &> /dev/null
#        git add . &> /dev/null
#        git commit -m "Backup original config on `date '+%Y-%m-%d %H:%M'`" &> /dev/null
#
#        # Output.
#        echo -e $blue"Your config is backed up in "$backupdir"\n" >&2
#        echo -e $red"Please do not delete check-backup.txt in .dotfiles.orig folder."$white >&2
#        echo -e "It's used to backup and restore your old config.\n" >&2
#    fi
#
#    # Install config.
#    for dots in "${dotfiles[@]}"
#    do
#        /bin/rm -rf ~/${dots}
#        /bin/ln -fs "$dotfilesdir/${dots}" ~/
#    done
#
#    # Install config to ~/.config.
#    mkdir -p ~/.config
#    for dots_conf in "${dotfiles_config[@]}"
#    do
#        /bin/rm -rf ~/.config/${dots_conf[@]//./}
#        /bin/ln -fs "$dotfilesdir/${dots_conf}" ~/.config/${dots_conf[@]//./}
#    done
#
#    echo -e $blue"New dotfiles is installed!\n"$white >&2
#    echo "There may be some errors when Terminal is restarted." >&2
#    echo "Please read carefully the error messages and make sure all packages are installed. See more info in README.md." >&2
#    echo "Note that the author of this dotfiles uses dev branch in some packages." >&2
#    echo -e "If you want to restore your old config, you can use "$red"./install.sh -r"$white" command." >&2
}

uninstall() {
    if [ -f $backupdir/check-backup.txt ]; then
        for dots in "${dotfiles[@]}"
        do
            /bin/rm -rf ~/${dots}
            /bin/cp -rf $backupdir/${dots} ~/ &> /dev/null
            /bin/rm -rf $backupdir/${dots}
        done

        for dots_conf in "${dotfiles_config[@]//./}"
        do
            /bin/rm -rf ~/.config/$dots_conf
            /bin/cp -rf $backupdir/.config/${dots_conf} ~/.config &> /dev/null
            /bin/rm -rf $backupdir/.config/${dots_conf}
        done

        # Save old config in backup directory with Git.
        cd $backupdir &> /dev/null
        git add -u &> /dev/null
        git add . &> /dev/null
        git commit -m "Restore original config on `date '+%Y-%m-%d %H:%M'`" &> /dev/null
    fi

    if ! [ -f $backupdir/check-backup.txt ]; then
        echo -e $red"You have not installed this dotfiles yet."$white >&2
    else
        echo -e $blue"Your old config has been restored!\n"$white >&2
        echo "Thanks for using my dotfiles." >&2

        echo "Enjoy your next journey!" >&2
    fi

    /bin/rm -rf $backupdir/check-backup.txt
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; || [[ $(whoami) !== "root" ]] then
    printUsage
    exit 0
fi

install

#case "$CMD" in
#    -i)
#        install
#        ;;
#    -r)
#        uninstall
#        ;;
#    *)
#        echo "Command not found" >&2
#        exit 1
#esac

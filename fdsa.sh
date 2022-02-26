#!/bin/bash
set -eu

APP=$1

if [[ ! -f '.ssh-config' ]]; then
	echo ".ssh-config not found, configuring:"
	read -p "remote user: " USER
	read -p "remote host: " HOST

	echo $HOST > .ssh-host
	cat <<- EOF > .ssh-config
		HostName $HOST
		User $USER
		ControlMaster auto
		ControlPath .ssh-control-%C
	EOF
	echo "saved ssh configs."
fi

host=$(cat .ssh-host)
sssh='ssh -F .ssh-config'

# set up the shared ssh connection
$sssh -MNf $host

echo sync code...
rsync -ahe "$sssh" $APP/ $host:$APP

echo build...
$sssh $host "cd $APP; ~/bin/alr build"

echo fetch binary...
rsync -ahe "$sssh" $host:$APP/bin/$APP $APP.elf

echo flash...
openocd -f interface/picoprobe.cfg -f target/rp2040.cfg -c "program $APP.elf verify reset exit"

$sssh -O exit $host

#!/bin/bash
. $PWD/nice.sh

APP=$1

if [[ ! -f '.ssh-config' ]]; then
	msg Setup .ssh-config:
	read -p "remote user: " USER
	read -p "remote host: " HOST

	echo $HOST > .ssh-host
	cat <<- EOF > .ssh-config
		HostName $HOST
		User $USER
		ControlMaster auto
		ControlPath .ssh-control-%C
	EOF
	msg Ok saved ssh configs
fi

host=$(cat .ssh-host)
sssh='ssh -F .ssh-config'

# set up the shared ssh connection
msg Connect via ssh
$sssh -MNf $host

# and tear it down after
ssh_exit() {
	msg Close ssh connection
	$sssh -O exit $host 2>&1 | etab
}
trap ssh_exit EXIT

msg Upload code
rsync -ahe "$sssh" $APP/ $host:$APP | etab

msg Build
run $sssh $host "cd $APP; ~/bin/alr build"

msg Download binary
rsync -ahe "$sssh" $host:$APP/bin/$APP $APP.elf | etab

if [ -z ${2+x} ]; then
	msg Flash binary
	run openocd -f interface/picoprobe.cfg -f target/rp2040.cfg -c "program $APP.elf verify reset exit"
else
	msg Skip flashing. Omit second arg to flash.
fi

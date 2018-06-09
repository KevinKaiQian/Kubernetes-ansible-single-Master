#!/bin/bash
#用于分发hosts文件
set -e
[ `id -u` != '0' ] && \
    { echo -e '\e[32;1m Please run the script as root!!! \e[0m';exit 1; }

[[ `rpm -qa` =~ expect ]] || yum install -y expect

chmod u+x AutoSsh AutoScp
#filename是存储IP和密码的文件
while getopts ':f:p:' args;do
	case $args in
	    f)
			[ ! -f "$OPTARG" ] && { echo 'file not exist!';exit 6; }
	        filename=$OPTARG
	        ;;
	    p)
			[[ "$OPTARG" =~ ^[1-9][0-9]*$ ]] && { echo 'port must be a number!';exit 67; }
	        port=$BASH_REMATCH
	        ;;
    	?)
			exit 1;
			;;
	esac
done

[ -n "$filename" ] && {
	while read ip password;do
		./AutoScp $password ${port:=22} {,$ip:}/etc/hosts
	done < "$filename"
	echo 'All done'
	exit 0
}

passwd=`grep -Po 'ansible_ssh_pass: \K.+\s*$' group_vars/all.yml`
while read ip ;do
	./AutoScp "$passwd" ${port:=22} {,$ip:}/etc/hosts
done < <(ansible all -m shell -a 'echo {{ inventory_hostname }}' | awk '$1 !~/localhost/ && $2~/\|/{print $1}')


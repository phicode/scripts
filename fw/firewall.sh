#!/bin/sh

### BEGIN INIT INFO
# Provides:          firewall
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:     S
# Default-Stop:      0 6
# Short-Description: workstation/server iptables firewall
### END INIT INFO

[ $(id -u) -eq 0 ] || (echo "must be run as root" ; exit 1)

[ -x "$(which iptables)" ] || (echo "iptables not found or executable" ; exit 1)

start () {
	ipt_policy filter INPUT   ACCEPT
	ipt_policy filter FORWARD DROP
	ipt_policy filter OUTPUT  ACCEPT

	set_net_options

	ipt_lo_accept

	ipt_state_rule filter INPUT all all ACCEPT "ESTABLISHED,RELATED"
}

stop () {
	ipt_policy filter INPUT   ACCEPT
	ipt_policy filter FORWARD ACCEPT
	ipt_policy filter OUTPUT  ACCEPT

	ipt_flush
}

set_net_options () {
	# enable reverse-path filtering
	# -> filter out traffic from spoofed source addresses
	echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter

	# disable packet forwarding
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo 0 > /proc/sys/net/ipv4/conf/all/forwarding
	echo 0 > /proc/sys/net/ipv6/conf/all/forwarding

	# enable syn-cookies
	echo 1 > /proc/sys/net/ipv4/tcp_syncookies

	echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

	# do not send or accept icmp redirects
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
	echo 0 > /proc/sys/net/ipv6/conf/all/accept_redirects
	echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
	#echo 0 > /proc/sys/net/ipv6/conf/all/send_redirects

	# do not accept packets which have a return route predefined
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
	echo 0 > /proc/sys/net/ipv6/conf/all/accept_source_route
}

# syntax: ipt_policy <table> <chain> <target>
ipt_policy () {
	iptables -t $1 -P $2 $3
}

# TODO: chains as parameters
ipt_flush () {
	iptables --flush
	iptables --delete-chain
	iptables --zero
}

ipt_lo_accept () {
	ipt_simple_in_rule  filter INPUT  lo all ACCEPT
	ipt_simple_out_rule filter OUTPUT lo all ACCEPT
}

# syntax: ipt_simple_rule <table> <chain> <interface> <protocol> <target>
ipt_simple_in_rule () {
	(
		[ $# -eq 5 ] && \
		iptables -t $1 -A $2 -i $3 -p $4 -j $5
	) \
	|| (echo "ipt_simple_in_rule error: $@" ; return 1)
	return 0
}

# syntax: ipt_simple_rule <table> <chain> <interface> <protocol> <target>
ipt_simple_out_rule () {
	(
		[ $# -eq 5 ] && \
		iptables -t $1 -A $2 -o $3 -p $4 -j $5
	) \
	|| (echo "ipt_simple_out_rule error: $@" ; return 1)
	return 0
}

status () {
	echo "==============MANGLE===================="
	iptables -t mangle -L -nv
	echo "==============FILTER ==================="
	iptables -t filter -L -nv
	echo "==============NAT======================="
	iptables -t nat -L -nv
	echo "========================================"
}

echo "==============START====================="
start
echo "==============STARTED==================="
status
echo "==============STOP======================"
stop
echo "==============STOPPED==================="
status
echo "========================================"

exit 0

case "$1" in 
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status
		;;
	restart|reload|force-reload)
		stop
		start
		;;
	*)
		echo "usage: $0 (start|stop|restart)"
		exit 1
		;;
esac

exit 0

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

# TODO: config file

start () {
	set_net_options

	ipt_policy filter INPUT   DROP
	ipt_policy filter FORWARD DROP
	ipt_policy filter OUTPUT  ACCEPT

	ipt_allow_lo

	ipt_state_rule filter INPUT tcp  ACCEPT "ESTABLISHED,RELATED"
	ipt_state_rule filter INPUT udp  ACCEPT "ESTABLISHED,RELATED"
	ipt_state_rule filter INPUT icmp ACCEPT "ESTABLISHED,RELATED"
	ipt_state_rule filter INPUT all  ACCEPT "UNTRACKED"
	ipt_state_rule filter INPUT all  DROP   "INVALID"

	# stateless services
	ipt_notrack_port udp 123
	
	# statefull services
	ipt_allow_port tcp 22

	ipt_allow_ping

	# keep some counters about which types of packets we are dropping 
	ipt_rule filter INPUT all DROP -m pkttype --pkt-type broadcast
	ipt_rule filter INPUT all DROP -m pkttype --pkt-type multicast

	# track outgoing connections by protocol
	ipt_state_rule filter OUTPUT tcp  ACCEPT "ESTABLISHED,NEW"
	ipt_state_rule filter OUTPUT udp  ACCEPT "ESTABLISHED,NEW"
	ipt_state_rule filter OUTPUT icmp ACCEPT "ESTABLISHED,NEW"
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
	[ $# -ne 3 ] && "ipt_policy error: $@" && return 1
	iptables -t $1 -P $2 $3
	return 0
}

ipt_flush () {
	for tbl in filter mangle nat raw; do
		iptables -t $tbl --flush
		iptables -t $tbl --delete-chain
		iptables -t $tbl --zero
	done
}

ipt_allow_lo () {
	ipt_rule filter INPUT  all ACCEPT -i lo
	ipt_rule filter OUTPUT all ACCEPT -o lo
}

ipt_allow_ping () {
	ipt_rule filter INPUT icmp ACCEPT -m icmp --icmp-type echo-request
}

# syntax: ipt_rule <table> <chain> <protocol> <target> [extra-stuff]
ipt_rule () {
	[ $# -lt 4 ] && "ipt_rule error: $@" && return 1
	local t=$1
	local c=$2
	local p=$3
	local j=$4
	shift 4
	iptables -t $t -A $c -p $p -j $j "$@"
	echo iptables -t $t -A $c -p $p -j $j "$@"
	return 0
}

# syntax: ipt_state_rule <table> <chain> <protocol> <target> <states> [extra-stuff]
ipt_state_rule () {
	[ $# -lt 5 ] && "ipt_state_rule error: $@" && return 1
	local t=$1
	local c=$2
	local p=$3
	local j=$4
	local s=$5
	shift 5
	ipt_rule $t $c $p $j -m conntrack --ctstate $s "$@"
	return 0
}

# syntax: ipt_allow_port <protocol> <port>
ipt_allow_port () {
	[ $# -ne 2 ] && "ipt_allow_port error: $@" && return 1
	ipt_state_rule filter INPUT  $1 ACCEPT NEW --dport $2
	ipt_rule       filter OUTPUT $1 ACCEPT     --sport $2
	return 0
}

# syntax: ipt_notrack_service <protocol> <port>
ipt_notrack_port () {
	[ $# -ne 2 ] && "ipt_notrack_port error: $@" && return 1
	iptables -t raw -A PREROUTING -p $1 --dport $2 -j CT --notrack
	iptables -t raw -A OUTPUT     -p $1 --sport $2 -j CT --notrack
	return 0
}

status () {
	echo "==============NAT======================="
	iptables -t nat -L -nv
	echo "==============RAW======================="
	iptables -t raw -L -nv
	echo "==============MANGLE===================="
	iptables -t mangle -L -nv
	echo "==============FILTER ==================="
	iptables -t filter -L -nv
	echo "========================================"
}

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

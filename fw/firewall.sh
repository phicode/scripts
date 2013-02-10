#!/bin/sh

### BEGIN INIT INFO
# Provides:          firewall
# Required-Start:    $network $local_fs
# Required-Stop:     $network $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 6
# Short-Description: workstation/server iptables firewall
### END INIT INFO

# TODO: config file & install command
# TODO: make sure that localhost-net is only reachable through dev lo

IPV6=y
VERBOSE=y

[ $(id -u) -eq 0 ]          || { echo "must be run as root" ; exit 1 ; }
[ -x "$(which iptables)" ]  || { echo "iptables not found"  ; exit 1 ; }
[ -x "$(which ip6tables)" ] || { echo "no ip6tables found"  ; IPV6=n ; }


CONF_FILE=/etc/firewall.conf
[ -f $CONF_FILE ] && . $CONF_FILE

start () {
	set_net_options

	ipt_policy filter INPUT   DROP
	ipt_policy filter FORWARD DROP
	ipt_policy filter OUTPUT  ACCEPT

	# allow localhost
	ipt_rule filter INPUT  all ACCEPT -i lo
	ipt_rule filter OUTPUT all ACCEPT -o lo

	ipt_state_rule  filter INPUT all    ACCEPT "UNTRACKED"
	ipt_state_rule  filter INPUT tcp    ACCEPT "ESTABLISHED,RELATED"
	ipt_state_rule  filter INPUT udp    ACCEPT "ESTABLISHED,RELATED"
	ipt4_state_rule filter INPUT icmp   ACCEPT "ESTABLISHED,RELATED"
	ipt6_state_rule filter INPUT icmpv6 ACCEPT "ESTABLISHED,RELATED"
	ipt_state_rule  filter INPUT all    DROP   "INVALID"

	# stateless services
	ipt_notrack_port udp 123
	
	# statefull services
	ipt_allow_port tcp 22

	# allow icmp4 ping and all icmp6 except redirect
	ipt4_rule filter INPUT icmp   ACCEPT -m icmp  --icmp-type   echo-request
	ipt6_rule filter INPUT icmpv6 DROP   -m icmp6 --icmpv6-type redirect
	ipt6_rule filter INPUT icmpv6 ACCEPT

	# keep some counters about which types of packets we are dropping 
	ipt_rule filter INPUT all DROP -m pkttype --pkt-type broadcast
	ipt_rule filter INPUT all DROP -m pkttype --pkt-type multicast

	# track outgoing connections by protocol
	ipt_rule  filter OUTPUT tcp    ACCEPT
	ipt_rule  filter OUTPUT udp    ACCEPT
	ipt4_rule filter OUTPUT icmp   ACCEPT
	ipt6_rule filter OUTPUT icmpv6 ACCEPT
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

# iptables rule for ipv4
ipt4 () {
	[ $VERBOSE = "y" ] && echo iptables "$@"
	iptables "$@"
}

# iptables rule for ipv6
ipt6 () {
	[ $IPV6 = "y" ] || return 0
	[ $VERBOSE = "y" ] && echo ip6tables "$@"
	ip6tables "$@"
}

# iptables rule for ipv4 and ipv6
ipt () {
	ipt4 "$@"
	ipt6 "$@"
}

# syntax: ipt_policy <table> <chain> <target>
ipt_policy () {
	[ $# -ne 3 ] && { echo "ipt_policy error: $@" ; return 1 ; }
	ipt -t $1 -P $2 $3
	return 0
}

ipt_flush () {
	for tbl in filter mangle raw; do
		ipt -t $tbl --flush
		ipt -t $tbl --delete-chain
		ipt -t $tbl --zero
	done
	# nat is ipv4 only
	ipt4 -t nat --flush
	ipt4 -t nat --delete-chain
	ipt4 -t nat --zero
}

# syntax: ipt4_rule <table> <chain> <protocol> <target> [extra-params]
ipt4_rule () {
	ipt_rule 4 "$@"
}

# syntax: ipt6_rule <table> <chain> <protocol> <target> [extra-params]
ipt6_rule () {
	ipt_rule 6 "$@"
}

# syntax: ipt4_state_rule <table> <chain> <protocol> <target> <states> [extra-params]
ipt4_state_rule () {
	ipt_state_rule 4 "$@"
}

# syntax: ipt6_state_rule <table> <chain> <protocol> <target> <states> [extra-params]
ipt6_state_rule () {
	ipt_state_rule 6 "$@"
}

# syntax: ipt_rule [4|6] <table> <chain> <protocol> <target> [extra-params]
ipt_rule () {
	local cmd=ipt
	[ $# -lt 4 ] && { echo "ipt_rule error: $@" ; return 1 ; }
	if [ "$1" = "4" -o "$1" = "6" ]; then
		[ $# -lt 5 ] && { echo "ipt_rule error: $@" ; return 1 ; }
		cmd=ipt${1}
		shift
	fi
	local t=$1 ; local c=$2 ; local p=$3 ; local j=$4
	shift 4
	$cmd -t $t -A $c -p $p -j $j "$@"
	return 0
}

# syntax: ipt_state_rule [4|6] <table> <chain> <protocol> <target> <states> [extra-params]
ipt_state_rule () {
	local proto=""
	[ $# -lt 5 ] && { echo "ipt_state_rule error: $@" ; return 1 ; }
	if [ "$1" = "4" -o "$1" = "6" ]; then
		[ $# -lt 6 ] && { echo "ipt_state_rule error: $@" ; return 1 ; }
		proto=$1
		shift
	fi
	local t=$1 ; local c=$2 ; local p=$3 ; local j=$4 ; local s=$5
	shift 5
	ipt_rule $proto $t $c $p $j -m conntrack --ctstate $s "$@"
	return 0
}

# syntax: ipt_allow_port <protocol> <port>
ipt_allow_port () {
	[ $# -ne 2 ] && { echo "ipt_allow_port error: $@" ; return 1 ; }
	ipt_state_rule filter INPUT  $1 ACCEPT NEW --dport $2
	ipt_rule       filter OUTPUT $1 ACCEPT     --sport $2
	return 0
}

# syntax: ipt_notrack_service <protocol> <port>
ipt_notrack_port () {
	[ $# -ne 2 ] && { echo "ipt_notrack_port error: $@" ; return 1 ; }
	ipt -t raw -A PREROUTING -p $1 --dport $2 -j CT --notrack
	ipt -t raw -A OUTPUT     -p $1 --sport $2 -j CT --notrack
	return 0
}

status () {
	echo "====================== NAT ======================"
	ipt4 -t nat -L -nv
	echo "====================== RAW ======================"
	ipt -t raw -L -nv
	echo "====================== MANGLE ==================="
	ipt -t mangle -L -nv
	echo "====================== FILTER ==================="
	ipt -t filter -L -nv
	echo "================================================="
}

#DEFAULT_CONFIG="
## set to 'y' in order to have the firewall script output what it does
#VERBOSE=n
#
## set to 'n' if no IPv6 rules should be generated
#IPV6=y
#
## custom
#"
#echo $DEFAULT_CONFIG

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

#!/bin/sh

### BEGIN INIT INFO
# Provides:          firewall
# Required-Start:    $network $local_fs
# Required-Stop:     $network $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 6
# Short-Description: workstation/server iptables firewall
### END INIT INFO

IPV6=y
VERBOSE=y
CONF_FILE=/etc/firewall.conf
RULES_FILE=/etc/firewall.rules

[ -f $CONF_FILE ] && . $CONF_FILE

[ $(id -u) -eq 0 ]          || { echo "must be run as root" ; exit 1 ; }
[ -x "$(which iptables)" ]  || { echo "iptables not found"  ; exit 1 ; }
[ -x "$(which ip6tables)" ] || { echo "no ip6tables found"  ; IPV6=n ; }

start () {
	set_net_options

	ipt_policy filter INPUT   ACCEPT
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

	[ -f $RULES_FILE ] && . $RULES_FILE

	# allow icmp4 ping and all icmp6 except redirect
	ipt4_rule filter INPUT icmp   ACCEPT -m icmp  --icmp-type   echo-request
	ipt6_rule filter INPUT icmpv6 DROP   -m icmp6 --icmpv6-type redirect
	ipt6_rule filter INPUT icmpv6 ACCEPT

	# keep some counters about which types of packets we are dropping 
	ipt_rule filter INPUT all DROP -m pkttype --pkt-type broadcast
	ipt_rule filter INPUT all DROP -m pkttype --pkt-type multicast

	# reject the rest of the input traffic
	ipt_rule filter INPUT all REJECT

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

# syntax: ipt_notrack_port <protocol> <port>
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

DEFAULT_CONFIG="
# set to 'y' in order to have the firewall script output what it does
VERBOSE=n

# set to 'n' if no IPv6 rules should be generated
IPV6=y
"
DEFAULT_RULES="
# custom firewall rules
#
# available methods:
#  ipt_rule [4|6] <table> <chain> <protocol> <target> [extra-params]
#  ipt_state_rule [4|6] <table> <chain> <protocol> <target> <states> [extra-params]
#  ipt_allow_port <protocol> <port>
#  ipt_notrack_port <protocol> <port>
#
# examples:
#  # statefull services
#  ipt_allow_port tcp 22
#
#  # stateless services (no connection tracking)
#  ipt_notrack_port udp 123
#
#  # ipv4
#  ipt_state_rule 4 filter INPUT tcp ACCEPT NEW --dport 1234
#  # ipv6 only
#  ipt_state_rule 6 filter INPUT udp ACCEPT NEW --dport 1234

ipt_allow_port tcp 22 # ssh
"

install () {
	if [ ! -e "$(which chkconfig)" ]; then
		echo "program chkconfig not found"
		exit 1
	fi

	if [ ! -f $CONF_FILE ]; then
		echo "creating default config file $CONF_FILE"
		echo "$DEFAULT_CONFIG" > $CONF_FILE
		chmod 640 $CONF_FILE
	fi

	if [ ! -f $RULES_FILE ]; then
		echo "creating default rules file $RULES_FILE"
		echo "$DEFAULT_RULES" > $RULES_FILE
		chmod 640 $RULES_FILE
	fi

	dst=/etc/init.d/firewall
	inst=n
	if [ ! -f $dst ]; then
		inst=y
	else
		if [ "$(md5sum - < $0)" != "$(md5sum - < $dst)" ]; then
			inst=y
		fi
	fi
	if [ $inst = 'y' ]; then
		echo "installing firewall to $dst"
		cp $0 $dst
		chmod 750 $dst
		chkconfig --add firewall
		$dst start
	fi
}

list () {
	if [ ! -f $RULES_FILE ]; then
		echo "config file not found: $RULES_FILE"
		echo "run \"$0 install\" first"
		exit 1
	fi
	echo "rules in $RULES_FILE"
	echo
	grep "^ipt" $RULES_FILE
}

add () {
	if [ ! -f $RULES_FILE ]; then
		echo "config file not found: $RULES_FILE"
		echo "run \"$0 install\" first"
		exit 1
	fi
	merged="$@"
	grep "^${merged}$" $RULES_FILE > /dev/null
	if [ $? -eq 0 ]; then
		echo "rule already in $RULES_FILE"
		exit 0
	fi

	echo "$merged" >> $RULES_FILE
	echo "restarting firewall"
	stop ; start
}

# TODO: rules in $RULES_FILE through custom chains

case "$1" in 
	start|restart|reload|force-reload)
		stop
		start
		;;
	stop)
		stop
		;;
	status)
		status
		;;
	install)
		install
		;;
	list)
		list
		;;
	add)
		shift
		add "$@"
		;;
	*)
		echo "usage: $0 (start|stop|restart|status|install|list|add)"
		echo ""
		echo "available methods for add:"
		echo "  ipt_rule [4|6] <table> <chain> <protocol> <target> [extra-params]"
		echo "  ipt_state_rule [4|6] <table> <chain> <protocol> <target> <states> [extra-params]"
		echo "  ipt_allow_port <protocol> <port>"
		echo "  ipt_notrack_port <protocol> <port>"
		exit 1
		;;
esac

exit 0

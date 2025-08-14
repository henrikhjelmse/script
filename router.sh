#!/usr/bin/env bash
set -euo pipefail


# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

######################################################################
#
#                         ROUTING
#
######################################################################
# Use variables instead of hardcoded interface names.
# Default values (can be overridden via environment variables or arguments):
#   VPN_IF (previously boris)  -> VPN interface
#   LAN_IF (previously eno1)   -> LAN interface

VPN_IF="boris"   # Change this value if your VPN interface has a different name
LAN_IF="eno1"    # Change this value if your LAN interface has a different name

# Allow specifying via command line arguments: ./router.sh <vpn_if> <lan_if>
if [[ ${1-} != "" ]]; then
  VPN_IF="$1"
fi
if [[ ${2-} != "" ]]; then
  LAN_IF="$2"
fi

echo "Using VPN_IF=$VPN_IF LAN_IF=$LAN_IF"

# Enable IP forwarding (overwrite, not append)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Always accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow traffic from the VPN side
iptables -A INPUT -i "$VPN_IF" -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT (masquerade) out via LAN interface
iptables -t nat -A POSTROUTING -o "$LAN_IF" -j MASQUERADE

# Forward rules
iptables -A FORWARD -i "$LAN_IF" -o "$VPN_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "$VPN_IF" -o "$LAN_IF" -j ACCEPT

echo "Done."
#!/usr/bin/env bash
set -euo pipefail

######################################################################
#
#                         ROUTING
#
######################################################################
# Använd variabler istället för hårdkodade interface-namn.
# Standardvärden (kan överstyras via miljövariabler eller argument):
#   VPN_IF (tidigare boris)  -> VPN-interface
#   LAN_IF (tidigare eno1)   -> LAN-interface

VPN_IF="boris"   # Ändra detta värde om ditt VPN-interface heter något annat
LAN_IF="eno1"    # Ändra detta värde om ditt LAN-interface heter något annat

# Tillåt även att ange via kommandoradsargument: ./router.sh <vpn_if> <lan_if>
if [[ ${1-} != "" ]]; then
  VPN_IF="$1"
fi
if [[ ${2-} != "" ]]; then
  LAN_IF="$2"
fi

echo "Använder VPN_IF=$VPN_IF LAN_IF=$LAN_IF"

# Slå på IP forwarding (skriv, inte append)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Alltid acceptera loopback-trafik
iptables -A INPUT -i lo -j ACCEPT

# Tillåt trafik från VPN-sidan
iptables -A INPUT -i "$VPN_IF" -j ACCEPT

# Tillåt etablerade anslutningar
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT (masquerade) ut via LAN-interface
iptables -t nat -A POSTROUTING -o "$LAN_IF" -j MASQUERADE

# Forward regler
iptables -A FORWARD -i "$LAN_IF" -o "$VPN_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "$VPN_IF" -o "$LAN_IF" -j ACCEPT

echo "Klar."
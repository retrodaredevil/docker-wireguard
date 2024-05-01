#!/bin/sh

# similar to https://github.com/cmulk/wireguard-docker/blob/main/run

interfaces=$(find /etc/wireguard -type f)
if [ -z "$interfaces" ]; then
    echo "Interface not found in /etc/wireguard" >&2
    exit 1
fi

start_interfaces() {
    for interface in $interfaces; do
        echo "Starting WireGuard $interface"
        wg-quick up "$interface"
    done
}

stop_interfaces() {
    for interface in $interfaces; do
        wg-quick down "$interface"
    done
}

start_interfaces

# Add masquerade rule for NAT'ing VPN traffic bound for the Internet

if [ "$IPTABLES_MASQ" -eq 1 ]; then
    echo "Adding iptables NAT rule"
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
fi

# Handle shutdown behavior
finish () {
    echo "Shutting down WireGuard"
    stop_interfaces
    if [ "$IPTABLES_MASQ" -eq 1 ]; then
        iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
        ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
    fi

    exit 0
}

trap finish TERM INT QUIT


dig +short "$MONITOR_DOMAIN"  # Give the DNS server a chance to make sure it has this cached

initial_ip=$(dig +short "$MONITOR_DOMAIN")

while true; do
    current_ip=$(dig +short "$MONITOR_DOMAIN")

    if [ "$current_ip" != "$initial_ip" ]; then
        echo "DNS resolution changed! New IP: $current_ip"
        break
    fi

    sleep 60
done
# We choose 5 as our "failure" exit code when the DNS changes
exit 5

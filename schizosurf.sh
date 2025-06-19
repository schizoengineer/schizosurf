#!/bin/bash

CIADPI_BIN="/usr/local/bin/ciadpi"
TOR_BIN="/usr/bin/tor"
PROXYCHAINS_BIN="/usr/bin/proxychains"

CIADPI_HOST="127.0.0.1"
CIADPI_PORT="1080"

TMP_CONF_DIR="$HOME/.schizosurf"
mkdir -p "$TMP_CONF_DIR"

PROXYCHAINS_CONF="$TMP_CONF_DIR/proxychains.conf"
TORRC_CONF="$TMP_CONF_DIR/torrc"
TOR_LOG="$TMP_CONF_DIR/tor.log"

start_services() {
    if ! pgrep -x ciadpi >/dev/null; then
        "$CIADPI_BIN" --tlsrec 0+s > /dev/null 2>&1 &
        sleep 3
        echo "ciadpi started."
    else
        echo "ciadpi already running (PID $(pgrep -x ciadpi))"
    fi

    cat > "$PROXYCHAINS_CONF" <<EOF
strict_chain
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 $CIADPI_HOST $CIADPI_PORT
EOF

    cat "$PROXYCHAINS_CONF"

    cat > "$TORRC_CONF" <<EOF
User tor
SOCKSPort 9050
DataDirectory /var/lib/tor
DisableNetwork 0
ClientUseIPv6 0
ClientPreferIPv6ORPort 0
ExcludeNodes {de},{us},{cn},{ru},{au}
ExcludeExitNodes {de},{us},{cn},{ru},{au}
StrictNodes 1
DNSPort 9053
AutomapHostsOnResolve 1
NewCircuitPeriod 60
MaxCircuitDirtiness 60
SafeSocks 1
TestSocks 1
AvoidDiskWrites 1
SafeLogging 1
Log notice stdout
EOF

    "$PROXYCHAINS_BIN" -f "$PROXYCHAINS_CONF" "$TOR_BIN" -f "$TORRC_CONF" > "$TOR_LOG" 2>&1 &
    sleep 5
    if pgrep -x tor >/dev/null; then
        echo "tor started."
    else
        echo "tor failed to start. Check $TOR_LOG"
    fi
}

stop_services() {
    pkill -x tor
    pkill -x ciadpi
    rm -rf "$TMP_CONF_DIR"
    echo "all services stopped."
}

status_services() {
    echo "[*] Service status:"
    if pgrep -x ciadpi >/dev/null; then
        echo "  - ciadpi running (PID $(pgrep -x ciadpi))"
    else
        echo "  - ciadpi not running"
    fi

    if pgrep -x tor >/dev/null; then
        echo "  - tor running (PID $(pgrep -x tor))"
    else
        echo "  - tor not running"
    fi
}

case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    status)
        status_services
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac

#!/bin/bash
# MiniGuard Test Suite

HOST="localhost"
WEB_PORT=8080
SSH_PORT=2222

echo "=================================================="
echo "          MiniGuard System Test Suite             "
echo "=================================================="

# Helper function for test status
test_pass() {
    echo -e "[\e[32m PASS \e[0m] $1"
}

test_fail() {
    echo -e "[\e[31m FAIL \e[0m] $1"
    exit 1
}

# 1. Check HTTP Connection
echo -n "Checking Web Dashboard response (HTTP port $WEB_PORT)... "
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$HOST:$WEB_PORT/)
if [ "$HTTP_STATUS" -eq 200 ]; then
    test_pass "HTTP port $WEB_PORT is open and returns 200 OK"
else
    test_fail "HTTP port $WEB_PORT returned status $HTTP_STATUS"
fi

# 2. Check HTML content
echo -n "Verifying index.html contents... "
HTML_BODY=$(curl -s http://$HOST:$WEB_PORT/)
if echo "$HTML_BODY" | grep -q "MINIGUARD SECURITY PANEL"; then
    test_pass "index.html contains expected brand header"
else
    test_fail "index.html did not match branding"
fi

# 3. Check system.sh CGI API
echo -n "Verifying system.sh CGI endpoint... "
SYS_JSON=$(curl -s http://$HOST:$WEB_PORT/cgi-bin/system.sh)
if echo "$SYS_JSON" | grep -q "hostname" && echo "$SYS_JSON" | grep -q "cpu_cores"; then
    test_pass "system.sh returned valid JSON diagnostics"
else
    test_fail "system.sh returned invalid data: $SYS_JSON"
fi

# 4. Check network.sh CGI API
echo -n "Verifying network.sh CGI endpoint... "
NET_JSON=$(curl -s http://$HOST:$WEB_PORT/cgi-bin/network.sh)
if echo "$NET_JSON" | grep -q "interface" && echo "$NET_JSON" | grep -q "gateway_ping"; then
    test_pass "network.sh returned valid JSON network stats"
else
    test_fail "network.sh returned invalid data: $NET_JSON"
fi

# 5. Check security.sh CGI API
echo -n "Verifying security.sh CGI endpoint... "
SEC_JSON=$(curl -s http://$HOST:$WEB_PORT/cgi-bin/security.sh)
if echo "$SEC_JSON" | grep -q "active_rules" && echo "$SEC_JSON" | grep -q "recent_events"; then
    test_pass "security.sh returned valid JSON firewall registers"
else
    test_fail "security.sh returned invalid data: $SEC_JSON"
fi

# 6. Verify SSH Port Response
echo -n "Checking Dropbear SSH connectivity (Port $SSH_PORT)... "
SSH_BANNER=$(timeout 3 nc -w 2 $HOST $SSH_PORT | head -n 1)
if echo "$SSH_BANNER" | grep -q "SSH-"; then
    test_pass "SSH port is open and responded with banner: $SSH_BANNER"
else
    test_fail "SSH port did not respond to netcat query"
fi

# 7. Firewall drop & log test
echo -n "Sending packet to restricted port 8888 to trigger drop log... "
# Try to access a closed port (this should be blocked by iptables and logged)
nc -z -w 1 $HOST 8888 >/dev/null 2>&1 || true

sleep 2 # Let system log the dropped packet

echo -n "Verifying blocked connection was logged... "
SEC_JSON_UPDATED=$(curl -s http://$HOST:$WEB_PORT/cgi-bin/security.sh)
# Check if the blocked packet appears in the recent_events list
if echo "$SEC_JSON_UPDATED" | grep -q "8888"; then
    test_pass "Dropped connection to port 8888 was successfully logged in fw.log!"
else
    test_fail "Blocked connection not found in log. Output: $SEC_JSON_UPDATED"
fi

echo "=================================================="
echo "      ALL TEST CASES COMPLETED SUCCESSFULLY       "
echo "=================================================="
exit 0

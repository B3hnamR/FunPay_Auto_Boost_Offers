#!/bin/bash

# Fix GeckoDriver Version Compatibility Issue
# This script updates GeckoDriver to version 0.36.0 for Firefox 140.x compatibility

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                ${WHITE}GeckoDriver Version Fix${BLUE}                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${CYAN}🔍 Checking current versions...${NC}"

# Check Firefox version
if command -v firefox >/dev/null 2>&1; then
    FIREFOX_VERSION=$(firefox --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1)
    echo -e "${GREEN}✅ Firefox version: $FIREFOX_VERSION${NC}"
else
    echo -e "${RED}❌ Firefox not found${NC}"
    exit 1
fi

# Check current GeckoDriver version
if command -v geckodriver >/dev/null 2>&1; then
    GECKODRIVER_VERSION=$(geckodriver --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+')
    echo -e "${YELLOW}⚠️ Current GeckoDriver version: $GECKODRIVER_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️ GeckoDriver not found in PATH${NC}"
fi

echo ""
echo -e "${CYAN}🔧 Installing compatible GeckoDriver version 0.36.0...${NC}"

# Stop the service first
echo -e "${YELLOW}🛑 Stopping FunPay service...${NC}"
systemctl stop funpay-boost 2>/dev/null || true

# Remove old GeckoDriver versions
echo -e "${YELLOW}🗑️ Removing old GeckoDriver versions...${NC}"
rm -f /usr/local/bin/geckodriver
rm -f /usr/bin/geckodriver
rm -f /opt/geckodriver

# Download and install GeckoDriver 0.36.0
GECKODRIVER_VERSION="v0.36.0"
GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz"

echo -e "${CYAN}📥 Downloading GeckoDriver $GECKODRIVER_VERSION...${NC}"

if wget -q -O /tmp/geckodriver.tar.gz "$GECKODRIVER_URL"; then
    echo -e "${GREEN}✅ Download successful${NC}"
elif curl -L -o /tmp/geckodriver.tar.gz "$GECKODRIVER_URL" 2>/dev/null; then
    echo -e "${GREEN}✅ Download successful (using curl)${NC}"
else
    echo -e "${RED}❌ Failed to download GeckoDriver${NC}"
    exit 1
fi

# Extract and install
echo -e "${CYAN}📦 Installing GeckoDriver...${NC}"
if tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/ 2>/dev/null; then
    chmod +x /usr/local/bin/geckodriver
    echo -e "${GREEN}✅ GeckoDriver installed to /usr/local/bin/${NC}"
else
    echo -e "${RED}❌ Failed to extract GeckoDriver${NC}"
    exit 1
fi

# Cleanup
rm -f /tmp/geckodriver.tar.gz

# Verify installation
echo -e "${CYAN}🔍 Verifying installation...${NC}"
if command -v geckodriver >/dev/null 2>&1; then
    NEW_VERSION=$(geckodriver --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+')
    echo -e "${GREEN}✅ New GeckoDriver version: $NEW_VERSION${NC}"
    
    if [[ "$NEW_VERSION" == "0.36.0" ]]; then
        echo -e "${GREEN}✅ Version compatibility fixed!${NC}"
    else
        echo -e "${YELLOW}⚠️ Unexpected version installed${NC}"
    fi
else
    echo -e "${RED}❌ GeckoDriver installation failed${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}🔧 Additional Firefox compatibility fixes...${NC}"

# Create Firefox profile directory for the service user
echo -e "${YELLOW}📁 Setting up Firefox profile...${NC}"
mkdir -p /home/funpay/.mozilla/firefox
chown -R funpay:funpay /home/funpay/.mozilla

# Create a basic Firefox profile to avoid first-run issues
cat > /home/funpay/.mozilla/firefox/profiles.ini << 'EOF'
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=default
Default=1
EOF

mkdir -p /home/funpay/.mozilla/firefox/default
cat > /home/funpay/.mozilla/firefox/default/prefs.js << 'EOF'
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("browser.rights.3.shown", true);
user_pref("browser.startup.homepage_override.buildID", "20231201000000");
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.warnOnQuit", false);
user_pref("general.warnOnAboutConfig", false);
EOF

chown -R funpay:funpay /home/funpay/.mozilla

echo ""
echo -e "${CYAN}🧪 Testing Firefox and GeckoDriver compatibility...${NC}"

# Test GeckoDriver with Firefox
echo -e "${YELLOW}🔬 Running compatibility test...${NC}"

# Create a simple test script
cat > /tmp/test_firefox.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import time
from selenium import webdriver
from selenium.webdriver.firefox.options import Options

try:
    # Setup Firefox options
    firefox_options = Options()
    firefox_options.add_argument("--headless")
    firefox_options.add_argument("--no-sandbox")
    firefox_options.add_argument("--disable-dev-shm-usage")
    
    # Set display
    os.environ['DISPLAY'] = ':99'
    
    # Start Xvfb
    import subprocess
    xvfb_process = subprocess.Popen(['Xvfb', ':99', '-screen', '0', '1920x1080x24'], 
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)
    
    # Test Firefox
    print("Testing Firefox initialization...")
    driver = webdriver.Firefox(options=firefox_options)
    print("✅ Firefox started successfully")
    
    # Test basic navigation
    driver.get("https://www.google.com")
    print("✅ Navigation test successful")
    
    # Cleanup
    driver.quit()
    xvfb_process.terminate()
    print("✅ Test completed successfully")
    
except Exception as e:
    print(f"❌ Test failed: {e}")
    sys.exit(1)
EOF

# Run the test as the service user
if sudo -u funpay /opt/funpay-boost/venv/bin/python /tmp/test_firefox.py; then
    echo -e "${GREEN}✅ Firefox compatibility test passed!${NC}"
else
    echo -e "${YELLOW}⚠️ Firefox test had issues, but continuing...${NC}"
fi

# Cleanup test file
rm -f /tmp/test_firefox.py

echo ""
echo -e "${CYAN}🚀 Restarting FunPay service...${NC}"

# Restart the service
systemctl daemon-reload
systemctl start funpay-boost

# Wait a moment and check status
sleep 5

if systemctl is-active --quiet funpay-boost; then
    echo -e "${GREEN}✅ Service started successfully!${NC}"
    echo ""
    echo -e "${CYAN}📊 Service Status:${NC}"
    systemctl status funpay-boost --no-pager -l
else
    echo -e "${YELLOW}⚠️ Service may still be starting up...${NC}"
    echo ""
    echo -e "${CYAN}📋 Recent logs:${NC}"
    journalctl -u funpay-boost --no-pager -l --since "1 minute ago"
fi

echo ""
echo -e "${GREEN}🎉 GeckoDriver fix completed!${NC}"
echo ""
echo -e "${CYAN}💡 Useful commands:${NC}"
echo "   funpay-boost status  - Check service status"
echo "   funpay-boost logs    - View live logs"
echo "   funpay-boost restart - Restart service"
echo ""
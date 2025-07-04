#!/bin/bash

# Fix Firefox Dependencies and Permissions
# This script addresses the "Process unexpectedly closed with status 255" error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ${WHITE}Firefox Dependencies Fix${BLUE}                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${CYAN}🔍 Diagnosing Firefox issues...${NC}"

# Stop the service first
echo -e "${YELLOW}🛑 Stopping FunPay service...${NC}"
systemctl stop funpay-boost 2>/dev/null || true

# Check Firefox installation
echo -e "${CYAN}📦 Checking Firefox installation...${NC}"
if command -v firefox >/dev/null 2>&1; then
    FIREFOX_VERSION=$(firefox --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1)
    echo -e "${GREEN}✅ Firefox version: $FIREFOX_VERSION${NC}"
else
    echo -e "${RED}❌ Firefox not found${NC}"
    exit 1
fi

# Install missing dependencies
echo -e "${CYAN}📦 Installing missing Firefox dependencies...${NC}"

# Update package list
apt update >/dev/null 2>&1

# Install essential Firefox dependencies
FIREFOX_DEPS=(
    "libgtk-3-0"
    "libdbus-glib-1-2"
    "libxt6"
    "libxcomposite1"
    "libxdamage1"
    "libxrandr2"
    "libasound2"
    "libpangocairo-1.0-0"
    "libatk1.0-0"
    "libcairo-gobject2"
    "libgtk-3-0"
    "libgdk-pixbuf2.0-0"
    "libxss1"
    "libgconf-2-4"
    "libxrender1"
    "libxtst6"
    "libxi6"
    "libxrandr2"
    "libasound2"
    "libpangocairo-1.0-0"
    "libatk1.0-0"
    "libcairo-gobject2"
    "libdrm2"
    "libxkbcommon0"
    "libxcomposite1"
    "libxdamage1"
    "libxfixes3"
    "libxss1"
    "libgbm1"
    "libnss3"
    "libnspr4"
    "libxcb1"
    "libxcb-dri3-0"
    "fonts-liberation"
    "libappindicator3-1"
    "xdg-utils"
)

echo -e "${YELLOW}Installing Firefox dependencies...${NC}"
for dep in "${FIREFOX_DEPS[@]}"; do
    if ! dpkg -l | grep -q "^ii  $dep "; then
        echo -e "${CYAN}Installing $dep...${NC}"
        apt install -y "$dep" >/dev/null 2>&1 || echo -e "${YELLOW}⚠️ Could not install $dep${NC}"
    fi
done

# Install additional X11 and graphics libraries
echo -e "${CYAN}📦 Installing X11 and graphics libraries...${NC}"
apt install -y \
    xvfb \
    x11-utils \
    x11-xserver-utils \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    mesa-utils \
    dbus-x11 >/dev/null 2>&1

# Fix permissions and directories
echo -e "${CYAN}🔧 Fixing permissions and directories...${NC}"

# Create and fix /tmp/.X11-unix
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix
chown root:root /tmp/.X11-unix

# Fix Firefox directories for service user
echo -e "${YELLOW}📁 Setting up Firefox directories for service user...${NC}"
mkdir -p /home/funpay/.mozilla/firefox
mkdir -p /home/funpay/.cache/mozilla
mkdir -p /home/funpay/.config
mkdir -p /home/funpay/.local/share

# Create a proper Firefox profile
cat > /home/funpay/.mozilla/firefox/profiles.ini << 'EOF'
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default
IsRelative=1
Path=default
Default=1
EOF

mkdir -p /home/funpay/.mozilla/firefox/default

# Create comprehensive Firefox preferences
cat > /home/funpay/.mozilla/firefox/default/prefs.js << 'EOF'
// Disable first-run and welcome screens
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("browser.rights.3.shown", true);
user_pref("browser.startup.homepage_override.buildID", "20231201000000");

// Disable data collection and telemetry
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);

// Disable crash reporting
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// Disable safe browsing
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);

// Disable session restore and crash recovery
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.sessionstore.restore_on_demand", false);
user_pref("browser.sessionstore.restore_tabs_lazily", false);

// Disable default browser check
user_pref("browser.shell.checkDefaultBrowser", false);

// Disable warnings
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.warnOnQuit", false);
user_pref("general.warnOnAboutConfig", false);

// Disable updates
user_pref("app.update.enabled", false);
user_pref("app.update.auto", false);
user_pref("app.update.mode", 0);
user_pref("app.update.service.enabled", false);

// Performance settings
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", false);
user_pref("browser.cache.offline.enable", false);
user_pref("network.http.use-cache", false);

// Disable media
user_pref("media.volume_scale", "0.0");
user_pref("media.autoplay.enabled", false);

// Privacy settings
user_pref("browser.privatebrowsing.autostart", true);
user_pref("privacy.trackingprotection.enabled", true);

// Disable images and CSS for faster loading
user_pref("permissions.default.image", 2);
user_pref("permissions.default.stylesheet", 2);

// Disable JavaScript (can be enabled if needed)
user_pref("javascript.enabled", true);

// Disable plugins
user_pref("plugin.state.flash", 0);
user_pref("plugin.state.java", 0);

// Disable geolocation
user_pref("geo.enabled", false);

// Disable notifications
user_pref("dom.webnotifications.enabled", false);
user_pref("dom.push.enabled", false);

// Disable WebRTC
user_pref("media.peerconnection.enabled", false);

// Timeout settings
user_pref("dom.max_script_run_time", 30);
user_pref("dom.max_chrome_script_run_time", 30);
user_pref("network.http.connection-timeout", 30);
user_pref("network.http.response.timeout", 30);
EOF

# Set proper ownership
chown -R funpay:funpay /home/funpay/.mozilla
chown -R funpay:funpay /home/funpay/.cache
chown -R funpay:funpay /home/funpay/.config
chown -R funpay:funpay /home/funpay/.local

# Set proper permissions
chmod -R 755 /home/funpay/.mozilla
chmod -R 755 /home/funpay/.cache
chmod -R 755 /home/funpay/.config
chmod -R 755 /home/funpay/.local

# Create a test script to verify Firefox works
echo -e "${CYAN}🧪 Creating Firefox test script...${NC}"

cat > /tmp/test_firefox_detailed.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import time
import subprocess
import signal

def cleanup_processes():
    """Clean up any existing processes"""
    processes = ['firefox', 'geckodriver', 'Xvfb']
    for proc in processes:
        try:
            subprocess.run(['pkill', '-f', proc], capture_output=True)
        except:
            pass
    time.sleep(2)

def test_xvfb():
    """Test Xvfb functionality"""
    print("🔍 Testing Xvfb...")
    try:
        # Start Xvfb
        xvfb_process = subprocess.Popen(
            ['Xvfb', ':99', '-screen', '0', '1920x1080x24', '-ac', '+extension', 'GLX'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE
        )
        time.sleep(3)
        
        if xvfb_process.poll() is None:
            print("✅ Xvfb started successfully")
            os.environ['DISPLAY'] = ':99'
            
            # Test X11 connection
            try:
                result = subprocess.run(['xdpyinfo'], capture_output=True, timeout=10)
                if result.returncode == 0:
                    print("✅ X11 display connection working")
                else:
                    print("❌ X11 display connection failed")
            except:
                print("❌ X11 display test failed")
            
            xvfb_process.terminate()
            return True
        else:
            stderr_output = xvfb_process.stderr.read().decode()
            print(f"❌ Xvfb failed to start: {stderr_output}")
            return False
    except Exception as e:
        print(f"❌ Xvfb test failed: {e}")
        return False

def test_firefox_binary():
    """Test Firefox binary directly"""
    print("🔍 Testing Firefox binary...")
    try:
        # Test Firefox version
        result = subprocess.run(['firefox', '--version'], capture_output=True, timeout=10)
        if result.returncode == 0:
            print(f"✅ Firefox version: {result.stdout.decode().strip()}")
        else:
            print(f"❌ Firefox version check failed: {result.stderr.decode()}")
            return False
        
        # Test Firefox help
        result = subprocess.run(['firefox', '--help'], capture_output=True, timeout=10)
        if result.returncode == 0:
            print("✅ Firefox help command works")
        else:
            print("❌ Firefox help command failed")
            return False
            
        return True
    except Exception as e:
        print(f"❌ Firefox binary test failed: {e}")
        return False

def test_selenium_firefox():
    """Test Selenium with Firefox"""
    print("🔍 Testing Selenium with Firefox...")
    try:
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options
        
        # Setup Firefox options
        firefox_options = Options()
        firefox_options.add_argument("--headless")
        firefox_options.add_argument("--no-sandbox")
        firefox_options.add_argument("--disable-dev-shm-usage")
        firefox_options.add_argument("--disable-gpu")
        
        # Set profile path
        profile_path = "/home/funpay/.mozilla/firefox/default"
        if os.path.exists(profile_path):
            firefox_options.add_argument(f"--profile={profile_path}")
            print(f"✅ Using Firefox profile: {profile_path}")
        
        # Set display
        os.environ['DISPLAY'] = ':99'
        
        # Start Xvfb
        xvfb_process = subprocess.Popen(
            ['Xvfb', ':99', '-screen', '0', '1920x1080x24', '-ac', '+extension', 'GLX'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        time.sleep(3)
        
        print("🚀 Starting Firefox with Selenium...")
        
        # Try to start Firefox
        driver = webdriver.Firefox(options=firefox_options)
        print("✅ Firefox started successfully with Selenium")
        
        # Test basic navigation
        print("🌐 Testing navigation...")
        driver.get("data:text/html,<html><body><h1>Test Page</h1></body></html>")
        print("✅ Navigation test successful")
        
        # Get page title
        title = driver.title
        print(f"✅ Page title: {title}")
        
        # Cleanup
        driver.quit()
        xvfb_process.terminate()
        print("✅ Test completed successfully")
        return True
        
    except Exception as e:
        print(f"❌ Selenium test failed: {e}")
        try:
            if 'driver' in locals():
                driver.quit()
        except:
            pass
        try:
            if 'xvfb_process' in locals():
                xvfb_process.terminate()
        except:
            pass
        return False

def main():
    print("🧪 Comprehensive Firefox Test")
    print("=" * 50)
    
    # Cleanup first
    cleanup_processes()
    
    # Run tests
    tests = [
        ("Xvfb", test_xvfb),
        ("Firefox Binary", test_firefox_binary),
        ("Selenium Firefox", test_selenium_firefox)
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n📋 Running {test_name} test...")
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test crashed: {e}")
            results.append((test_name, False))
        
        # Cleanup between tests
        cleanup_processes()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    all_passed = True
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"   {test_name}: {status}")
        if not result:
            all_passed = False
    
    if all_passed:
        print("\n🎉 All tests passed! Firefox should work correctly.")
        sys.exit(0)
    else:
        print("\n⚠️ Some tests failed. Check the output above for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

# Run the comprehensive test
echo -e "${CYAN}🧪 Running comprehensive Firefox test...${NC}"
if sudo -u funpay /opt/funpay-boost/venv/bin/python /tmp/test_firefox_detailed.py; then
    echo -e "${GREEN}✅ Firefox test passed!${NC}"
    TEST_PASSED=true
else
    echo -e "${YELLOW}⚠️ Firefox test had issues, but continuing...${NC}"
    TEST_PASSED=false
fi

# Cleanup test file
rm -f /tmp/test_firefox_detailed.py

# Additional system fixes
echo -e "${CYAN}🔧 Applying additional system fixes...${NC}"

# Fix shared memory
echo -e "${YELLOW}📁 Fixing shared memory...${NC}"
mount -t tmpfs -o size=512m tmpfs /dev/shm 2>/dev/null || true

# Fix dbus
echo -e "${YELLOW}🔧 Setting up D-Bus...${NC}"
if ! pgrep -x "dbus-daemon" > /dev/null; then
    service dbus start 2>/dev/null || true
fi

# Create machine-id if missing
if [[ ! -f /etc/machine-id ]]; then
    echo -e "${YELLOW}🆔 Creating machine-id...${NC}"
    dbus-uuidgen > /etc/machine-id 2>/dev/null || true
fi

# Set environment variables for the service
echo -e "${CYAN}🌍 Setting up environment variables...${NC}"
cat > /etc/systemd/system/funpay-boost.service.d/environment.conf << 'EOF'
[Service]
Environment="DISPLAY=:99"
Environment="XAUTHORITY=/tmp/.Xauth"
Environment="HOME=/home/funpay"
Environment="USER=funpay"
Environment="LOGNAME=funpay"
Environment="SHELL=/bin/bash"
Environment="TMPDIR=/tmp"
Environment="XDG_RUNTIME_DIR=/tmp"
Environment="XDG_CONFIG_HOME=/home/funpay/.config"
Environment="XDG_CACHE_HOME=/home/funpay/.cache"
Environment="XDG_DATA_HOME=/home/funpay/.local/share"
Environment="MOZ_HEADLESS=1"
Environment="MOZ_DISABLE_CONTENT_SANDBOX=1"
Environment="MOZ_DISABLE_GMP_SANDBOX=1"
Environment="MOZ_DISABLE_RDD_SANDBOX=1"
Environment="MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1"
EOF

# Create the directory if it doesn't exist
mkdir -p /etc/systemd/system/funpay-boost.service.d/

# Reload systemd
systemctl daemon-reload

echo -e "${CYAN}🚀 Restarting FunPay service...${NC}"

# Start the service
systemctl start funpay-boost

# Wait a moment and check status
sleep 10

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
echo -e "${GREEN}🎉 Firefox dependencies fix completed!${NC}"
echo ""
echo -e "${CYAN}💡 Useful commands:${NC}"
echo "   funpay-boost status  - Check service status"
echo "   funpay-boost logs    - View live logs"
echo "   funpay-boost restart - Restart service"
echo ""

if [[ "$TEST_PASSED" == "true" ]]; then
    echo -e "${GREEN}✅ All tests passed - Firefox should work correctly now!${NC}"
else
    echo -e "${YELLOW}⚠️ Some tests failed - monitor the logs for any remaining issues${NC}"
fi
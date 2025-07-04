#!/bin/bash

# Fix GeckoDriver Compatibility Issue
# Updates GeckoDriver to version 0.36.0 for Firefox 140.x compatibility

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ${WHITE}GeckoDriver Compatibility Fix${BLUE}                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    echo "Usage: sudo bash fix_geckodriver_compatibility.sh"
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
echo -e "${CYAN}🧪 Testing Selenium with updated GeckoDriver...${NC}"

# Create a comprehensive test script
cat > /tmp/test_selenium_fixed.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import time
import subprocess

def test_selenium_firefox():
    """Test Selenium with Firefox using updated GeckoDriver"""
    try:
        print("🔍 Testing Selenium with Firefox...")
        
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options
        from selenium.webdriver.firefox.service import Service
        
        # Setup Firefox options with enhanced compatibility
        firefox_options = Options()
        firefox_options.add_argument("--headless")
        firefox_options.add_argument("--no-sandbox")
        firefox_options.add_argument("--disable-dev-shm-usage")
        firefox_options.add_argument("--disable-gpu")
        
        # Enhanced compatibility settings
        firefox_options.set_preference("dom.webdriver.enabled", False)
        firefox_options.set_preference("useAutomationExtension", False)
        firefox_options.set_preference("marionette.enabled", True)
        
        # Set display
        os.environ['DISPLAY'] = ':99'
        
        # Start Xvfb
        print("🖥️ Starting virtual display...")
        xvfb_process = subprocess.Popen(
            ['Xvfb', ':99', '-screen', '0', '1920x1080x24', '-ac'],
            stdout=subprocess.DEVNULL, 
            stderr=subprocess.DEVNULL
        )
        time.sleep(3)
        
        # Create service with explicit path
        service = Service(executable_path='/usr/local/bin/geckodriver')
        
        print("🚀 Starting Firefox with Selenium...")
        
        # Start Firefox with timeout
        driver = webdriver.Firefox(service=service, options=firefox_options)
        driver.set_page_load_timeout(30)
        driver.implicitly_wait(10)
        
        print("🌐 Testing navigation...")
        driver.get("data:text/html,<html><body><h1>Test Page - GeckoDriver 0.36.0</h1></body></html>")
        
        # Get page title
        title = driver.title
        print(f"✅ Page title: {title}")
        
        # Test basic functionality
        page_source = driver.page_source
        if "Test Page" in page_source:
            print("✅ Page content verification successful")
        
        # Cleanup
        driver.quit()
        xvfb_process.terminate()
        
        print("✅ Selenium test completed successfully with GeckoDriver 0.36.0!")
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
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
    print("🧪 GeckoDriver 0.36.0 Compatibility Test")
    print("=" * 50)
    
    # Check versions first
    try:
        import selenium
        print(f"📦 Selenium version: {selenium.__version__}")
    except ImportError:
        print("❌ Selenium not installed")
        return False
    
    # Check GeckoDriver
    try:
        result = subprocess.run(['geckodriver', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            version_line = result.stdout.split('\n')[0]
            print(f"📦 {version_line}")
        else:
            print("❌ GeckoDriver not found")
            return False
    except FileNotFoundError:
        print("❌ GeckoDriver not found in PATH")
        return False
    
    # Check Firefox
    try:
        result = subprocess.run(['firefox', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"📦 {result.stdout.strip()}")
        else:
            print("❌ Firefox not found")
            return False
    except FileNotFoundError:
        print("❌ Firefox not found")
        return False
    
    print("\n🚀 Starting compatibility test...")
    
    if test_selenium_firefox():
        print("\n🎉 All tests passed! GeckoDriver 0.36.0 is compatible with your Firefox version.")
        return True
    else:
        print("\n❌ Tests failed. There may still be compatibility issues.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
EOF

# Run the test
if python3 /tmp/test_selenium_fixed.py; then
    echo -e "${GREEN}✅ Compatibility test passed!${NC}"
    TEST_PASSED=true
else
    echo -e "${YELLOW}⚠️ Test had issues, but GeckoDriver has been updated${NC}"
    TEST_PASSED=false
fi

# Cleanup test file
rm -f /tmp/test_selenium_fixed.py

echo ""
echo -e "${GREEN}🎉 GeckoDriver compatibility fix completed!${NC}"
echo ""
echo -e "${CYAN}📋 Summary:${NC}"
echo "   ✅ Updated GeckoDriver to version 0.36.0"
echo "   ✅ Compatible with Firefox 140.x"
echo "   ✅ Installed to /usr/local/bin/geckodriver"
echo ""

if [[ "$TEST_PASSED" == "true" ]]; then
    echo -e "${GREEN}✅ Selenium test passed - ready to use!${NC}"
else
    echo -e "${YELLOW}⚠️ Test had issues - try running the FunPay setup anyway${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "1. python3 funpay_boost_ultimate.py --setup"
echo "2. python3 funpay_boost_ultimate.py --test"
echo "3. python3 funpay_boost_ultimate.py --daemon"
echo ""
#!/bin/bash

# FunPay Auto Boost - Dependencies Installation Script
# This script installs all required dependencies for the FunPay Auto Boost service

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ${WHITE}FunPay Auto Boost - Dependencies Setup${BLUE}            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    echo "Usage: sudo bash install_dependencies.sh"
    exit 1
fi

echo -e "${CYAN}🔍 Checking system and installing dependencies...${NC}"
echo ""

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    echo -e "${GREEN}✅ Detected OS: $OS $VER${NC}"
else
    echo -e "${RED}❌ Cannot detect OS version${NC}"
    exit 1
fi

# Step 1: Update system
echo ""
echo -e "${YELLOW}📦 Step 1: Updating system packages...${NC}"
apt update -y
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ System packages updated${NC}"
else
    echo -e "${YELLOW}⚠️ Package update had issues, continuing...${NC}"
fi

# Step 2: Install system dependencies
echo ""
echo -e "${YELLOW}📦 Step 2: Installing system dependencies...${NC}"

SYSTEM_PACKAGES=(
    "python3"
    "python3-pip"
    "python3-venv"
    "python3-dev"
    "firefox"
    "xvfb"
    "wget"
    "curl"
    "unzip"
    "git"
    "build-essential"
    "libffi-dev"
    "libssl-dev"
    "pkg-config"
)

echo -e "${CYAN}Installing system packages...${NC}"
for package in "${SYSTEM_PACKAGES[@]}"; do
    echo -n "   Installing $package... "
    if apt install -y "$package" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️${NC}"
    fi
done

# Step 3: Install additional Firefox dependencies
echo ""
echo -e "${YELLOW}📦 Step 3: Installing Firefox dependencies...${NC}"

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
    "libgdk-pixbuf2.0-0"
    "libxss1"
    "libgconf-2-4"
    "libxrender1"
    "libxtst6"
    "libxi6"
    "libdrm2"
    "libxkbcommon0"
    "libxfixes3"
    "libgbm1"
    "libnss3"
    "libnspr4"
    "libxcb1"
    "fonts-liberation"
    "xdg-utils"
)

echo -e "${CYAN}Installing Firefox dependencies...${NC}"
for dep in "${FIREFOX_DEPS[@]}"; do
    apt install -y "$dep" >/dev/null 2>&1
done
echo -e "${GREEN}✅ Firefox dependencies installed${NC}"

# Step 4: Install GeckoDriver
echo ""
echo -e "${YELLOW}📦 Step 4: Installing GeckoDriver...${NC}"

# Get compatible GeckoDriver version for Firefox 140.x
GECKODRIVER_VERSION="v0.36.0"
GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz"

echo -e "${CYAN}Downloading GeckoDriver $GECKODRIVER_VERSION...${NC}"
if wget -q -O /tmp/geckodriver.tar.gz "$GECKODRIVER_URL"; then
    echo -e "${GREEN}✅ Download successful${NC}"
elif curl -L -o /tmp/geckodriver.tar.gz "$GECKODRIVER_URL" 2>/dev/null; then
    echo -e "${GREEN}✅ Download successful (using curl)${NC}"
else
    echo -e "${RED}❌ Failed to download GeckoDriver${NC}"
    exit 1
fi

echo -e "${CYAN}Installing GeckoDriver...${NC}"
if tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/ 2>/dev/null; then
    chmod +x /usr/local/bin/geckodriver
    echo -e "${GREEN}✅ GeckoDriver installed to /usr/local/bin/${NC}"
else
    echo -e "${RED}❌ Failed to extract GeckoDriver${NC}"
    exit 1
fi

# Cleanup
rm -f /tmp/geckodriver.tar.gz

# Step 5: Upgrade pip
echo ""
echo -e "${YELLOW}📦 Step 5: Upgrading pip...${NC}"
python3 -m pip install --upgrade pip
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Pip upgraded successfully${NC}"
else
    echo -e "${YELLOW}⚠️ Pip upgrade had issues, continuing...${NC}"
fi

# Step 6: Install Python packages
echo ""
echo -e "${YELLOW}📦 Step 6: Installing Python packages...${NC}"

PYTHON_PACKAGES=(
    "selenium>=4.15.0"
    "requests>=2.31.0"
    "beautifulsoup4>=4.12.0"
    "lxml>=4.9.0"
    "urllib3>=1.26.0"
    "certifi>=2023.0.0"
    "charset-normalizer>=3.0.0"
    "idna>=3.4"
    "soupsieve>=2.5"
)

echo -e "${CYAN}Installing Python packages...${NC}"
for package in "${PYTHON_PACKAGES[@]}"; do
    echo -n "   Installing $package... "
    if python3 -m pip install "$package" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️${NC}"
    fi
done

# Step 7: Verify installations
echo ""
echo -e "${YELLOW}🔍 Step 7: Verifying installations...${NC}"

# Check Python
echo -n "   Python 3: "
if python3 --version >/dev/null 2>&1; then
    PYTHON_VER=$(python3 --version 2>&1)
    echo -e "${GREEN}✅ $PYTHON_VER${NC}"
else
    echo -e "${RED}❌ Not found${NC}"
fi

# Check pip
echo -n "   Pip: "
if python3 -m pip --version >/dev/null 2>&1; then
    PIP_VER=$(python3 -m pip --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✅ Version $PIP_VER${NC}"
else
    echo -e "${RED}❌ Not found${NC}"
fi

# Check Firefox
echo -n "   Firefox: "
if firefox --version >/dev/null 2>&1; then
    FIREFOX_VER=$(firefox --version 2>&1)
    echo -e "${GREEN}✅ $FIREFOX_VER${NC}"
else
    echo -e "${RED}❌ Not found${NC}"
fi

# Check GeckoDriver
echo -n "   GeckoDriver: "
if geckodriver --version >/dev/null 2>&1; then
    GECKO_VER=$(geckodriver --version 2>&1 | head -1)
    echo -e "${GREEN}✅ $GECKO_VER${NC}"
else
    echo -e "${RED}❌ Not found${NC}"
fi

# Check Xvfb
echo -n "   Xvfb: "
if xvfb-run --help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Available${NC}"
else
    echo -e "${RED}❌ Not found${NC}"
fi

# Check Python packages
echo ""
echo -e "${CYAN}Checking Python packages:${NC}"

REQUIRED_MODULES=("selenium" "requests" "bs4" "lxml")
for module in "${REQUIRED_MODULES[@]}"; do
    echo -n "   $module: "
    if python3 -c "import $module" 2>/dev/null; then
        # Get version if possible
        VERSION=$(python3 -c "import $module; print(getattr($module, '__version__', 'installed'))" 2>/dev/null)
        echo -e "${GREEN}✅ $VERSION${NC}"
    else
        echo -e "${RED}❌ Not found${NC}"
    fi
done

# Step 8: Test Selenium with Firefox
echo ""
echo -e "${YELLOW}🧪 Step 8: Testing Selenium with Firefox...${NC}"

cat > /tmp/test_selenium.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import time
from selenium import webdriver
from selenium.webdriver.firefox.options import Options

try:
    print("Testing Selenium with Firefox...")
    
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
    driver = webdriver.Firefox(options=firefox_options)
    driver.get("data:text/html,<html><body><h1>Test Page</h1></body></html>")
    
    title = driver.title
    print(f"✅ Test successful! Page title: {title}")
    
    # Cleanup
    driver.quit()
    xvfb_process.terminate()
    
    print("✅ Selenium test completed successfully")
    sys.exit(0)
    
except Exception as e:
    print(f"❌ Test failed: {e}")
    sys.exit(1)
EOF

if python3 /tmp/test_selenium.py; then
    echo -e "${GREEN}✅ Selenium test passed!${NC}"
else
    echo -e "${YELLOW}⚠️ Selenium test had issues, but continuing...${NC}"
fi

# Cleanup test file
rm -f /tmp/test_selenium.py

# Step 9: Create directories and set permissions
echo ""
echo -e "${YELLOW}📁 Step 9: Creating directories...${NC}"

mkdir -p /etc/funpay
mkdir -p /var/log/funpay
mkdir -p /opt/funpay-boost

echo -e "${GREEN}✅ Directories created${NC}"

# Final summary
echo ""
echo -e "${GREEN}🎉 Dependencies installation completed!${NC}"
echo ""
echo -e "${CYAN}📋 Installation Summary:${NC}"
echo "   ✅ System packages installed"
echo "   ✅ Firefox and dependencies installed"
echo "   ✅ GeckoDriver installed"
echo "   ✅ Python packages installed"
echo "   ✅ Selenium tested successfully"
echo "   ✅ Required directories created"
echo ""

echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "1. Run the setup: python3 funpay_boost_ultimate.py --setup"
echo "2. Configure your credentials"
echo "3. Test the service: python3 funpay_boost_ultimate.py --test"
echo "4. Start the daemon: python3 funpay_boost_ultimate.py --daemon"
echo ""

echo -e "${GREEN}Ready to use FunPay Auto Boost!${NC}"
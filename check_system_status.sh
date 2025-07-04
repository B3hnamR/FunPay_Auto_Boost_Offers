#!/bin/bash

# System Status Check for FunPay Auto Boost
# This script checks all components and their compatibility

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ${WHITE}FunPay Auto Boost - System Status${BLUE}              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}🔍 Checking system components...${NC}"
echo ""

# Check OS
echo -e "${YELLOW}📋 Operating System:${NC}"
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo -e "   ${GREEN}✅ $NAME $VERSION_ID${NC}"
else
    echo -e "   ${RED}❌ Cannot detect OS${NC}"
fi

echo ""

# Check Python
echo -e "${YELLOW}🐍 Python Environment:${NC}"
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VER=$(python3 --version 2>&1)
    echo -e "   ${GREEN}✅ $PYTHON_VER${NC}"
else
    echo -e "   ${RED}❌ Python 3 not found${NC}"
fi

if command -v pip3 >/dev/null 2>&1 || python3 -m pip --version >/dev/null 2>&1; then
    PIP_VER=$(python3 -m pip --version 2>&1 | cut -d' ' -f2)
    echo -e "   ${GREEN}✅ Pip version $PIP_VER${NC}"
else
    echo -e "   ${RED}❌ Pip not found${NC}"
fi

echo ""

# Check Firefox
echo -e "${YELLOW}🦊 Firefox Browser:${NC}"
if command -v firefox >/dev/null 2>&1; then
    FIREFOX_VER=$(firefox --version 2>&1)
    FIREFOX_NUM=$(echo "$FIREFOX_VER" | grep -oP '\d+\.\d+' | head -1)
    echo -e "   ${GREEN}✅ $FIREFOX_VER${NC}"
    
    # Check Firefox compatibility
    if [[ $(echo "$FIREFOX_NUM" | cut -d. -f1) -ge 140 ]]; then
        echo -e "   ${CYAN}ℹ️ Firefox 140+ detected - requires GeckoDriver 0.36.0+${NC}"
    fi
else
    echo -e "   ${RED}❌ Firefox not found${NC}"
fi

echo ""

# Check GeckoDriver
echo -e "${YELLOW}🔧 GeckoDriver:${NC}"
if command -v geckodriver >/dev/null 2>&1; then
    GECKO_VER=$(geckodriver --version 2>&1 | head -1)
    GECKO_NUM=$(echo "$GECKO_VER" | grep -oP '\d+\.\d+\.\d+')
    echo -e "   ${GREEN}✅ $GECKO_VER${NC}"
    
    # Check compatibility
    if [[ -n "$FIREFOX_NUM" && -n "$GECKO_NUM" ]]; then
        FIREFOX_MAJOR=$(echo "$FIREFOX_NUM" | cut -d. -f1)
        GECKO_MAJOR=$(echo "$GECKO_NUM" | cut -d. -f1)
        GECKO_MINOR=$(echo "$GECKO_NUM" | cut -d. -f2)
        
        if [[ $FIREFOX_MAJOR -ge 140 && ($GECKO_MAJOR -lt 1 && $GECKO_MINOR -lt 36) ]]; then
            echo -e "   ${RED}❌ Compatibility issue: Firefox $FIREFOX_NUM requires GeckoDriver 0.36.0+${NC}"
            echo -e "   ${YELLOW}💡 Run: sudo bash fix_geckodriver_compatibility.sh${NC}"
        else
            echo -e "   ${GREEN}✅ Version compatibility OK${NC}"
        fi
    fi
else
    echo -e "   ${RED}❌ GeckoDriver not found${NC}"
fi

echo ""

# Check Xvfb
echo -e "${YELLOW}🖥️ Virtual Display (Xvfb):${NC}"
if command -v xvfb-run >/dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Xvfb available${NC}"
else
    echo -e "   ${RED}❌ Xvfb not found${NC}"
fi

echo ""

# Check Python packages
echo -e "${YELLOW}📦 Python Packages:${NC}"
REQUIRED_MODULES=("selenium" "requests" "bs4" "lxml")
for module in "${REQUIRED_MODULES[@]}"; do
    if python3 -c "import $module" 2>/dev/null; then
        VERSION=$(python3 -c "import $module; print(getattr($module, '__version__', 'installed'))" 2>/dev/null)
        echo -e "   ${GREEN}✅ $module: $VERSION${NC}"
    else
        echo -e "   ${RED}❌ $module: Not installed${NC}"
    fi
done

echo ""

# Check directories
echo -e "${YELLOW}📁 Project Directories:${NC}"
DIRS=("/etc/funpay" "/var/log/funpay" "/opt/funpay-boost")
for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "   ${GREEN}✅ $dir exists${NC}"
    else
        echo -e "   ${YELLOW}⚠️ $dir not found${NC}"
    fi
done

echo ""

# Check processes
echo -e "${YELLOW}🔄 Running Processes:${NC}"
if pgrep -f "funpay" >/dev/null; then
    echo -e "   ${GREEN}✅ FunPay processes running${NC}"
    ps aux | grep -E "(funpay|firefox|geckodriver)" | grep -v grep | while read line; do
        echo -e "   ${CYAN}   $line${NC}"
    done
else
    echo -e "   ${CYAN}ℹ️ No FunPay processes running${NC}"
fi

echo ""

# Quick test
echo -e "${YELLOW}🧪 Quick Selenium Test:${NC}"
cat > /tmp/quick_test.py << 'EOF'
try:
    from selenium import webdriver
    from selenium.webdriver.firefox.options import Options
    
    options = Options()
    options.add_argument("--headless")
    
    # Quick test without starting browser
    print("✅ Selenium import successful")
    print("✅ Firefox options created")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
except Exception as e:
    print(f"❌ Error: {e}")
EOF

python3 /tmp/quick_test.py 2>/dev/null | while read line; do
    if [[ "$line" == *"✅"* ]]; then
        echo -e "   ${GREEN}$line${NC}"
    else
        echo -e "   ${RED}$line${NC}"
    fi
done

rm -f /tmp/quick_test.py

echo ""

# Summary and recommendations
echo -e "${CYAN}📋 Summary and Recommendations:${NC}"
echo ""

# Check if main components are available
PYTHON_OK=$(command -v python3 >/dev/null 2>&1 && echo "true" || echo "false")
FIREFOX_OK=$(command -v firefox >/dev/null 2>&1 && echo "true" || echo "false")
GECKO_OK=$(command -v geckodriver >/dev/null 2>&1 && echo "true" || echo "false")
XVFB_OK=$(command -v xvfb-run >/dev/null 2>&1 && echo "true" || echo "false")
SELENIUM_OK=$(python3 -c "import selenium" 2>/dev/null && echo "true" || echo "false")

if [[ "$PYTHON_OK" == "true" && "$FIREFOX_OK" == "true" && "$GECKO_OK" == "true" && "$XVFB_OK" == "true" && "$SELENIUM_OK" == "true" ]]; then
    echo -e "${GREEN}🎉 All components are installed and ready!${NC}"
    echo ""
    echo -e "${BLUE}🚀 Next steps:${NC}"
    echo "   1. python3 funpay_boost_ultimate.py --setup"
    echo "   2. python3 funpay_boost_ultimate.py --test"
    echo "   3. python3 funpay_boost_ultimate.py --daemon"
else
    echo -e "${YELLOW}⚠️ Some components need attention:${NC}"
    echo ""
    
    if [[ "$PYTHON_OK" == "false" ]]; then
        echo -e "${RED}❌ Python 3 missing${NC} - Run: sudo apt install python3 python3-pip"
    fi
    
    if [[ "$FIREFOX_OK" == "false" ]]; then
        echo -e "${RED}❌ Firefox missing${NC} - Run: sudo apt install firefox"
    fi
    
    if [[ "$GECKO_OK" == "false" ]]; then
        echo -e "${RED}❌ GeckoDriver missing${NC} - Run: sudo bash quick_fix.sh"
    fi
    
    if [[ "$XVFB_OK" == "false" ]]; then
        echo -e "${RED}❌ Xvfb missing${NC} - Run: sudo apt install xvfb"
    fi
    
    if [[ "$SELENIUM_OK" == "false" ]]; then
        echo -e "${RED}❌ Selenium missing${NC} - Run: sudo python3 -m pip install selenium"
    fi
    
    echo ""
    echo -e "${BLUE}💡 Quick fix:${NC} sudo bash install_dependencies.sh"
fi

echo ""
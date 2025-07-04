#!/bin/bash

# FunPay Auto Boost - Complete Cleanup Script
# This script removes all components of the FunPay Auto Boost service

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ${WHITE}FunPay Auto Boost - Complete Cleanup${BLUE}           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    echo "Usage: sudo bash cleanup_funpay.sh"
    exit 1
fi

echo -e "${YELLOW}⚠️ WARNING: This will completely remove FunPay Auto Boost service!${NC}"
echo -e "${YELLOW}This includes:${NC}"
echo "   • Systemd service"
echo "   • All configuration files"
echo "   • Log files"
echo "   • Installation directory"
echo "   • Service user account"
echo "   • Management scripts"
echo ""

read -p "Are you sure you want to continue? (type 'YES' to confirm): " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}🧹 Starting complete cleanup...${NC}"
echo ""

# Step 1: Stop and disable service
echo -e "${YELLOW}1. Stopping and disabling systemd service...${NC}"
systemctl stop funpay-boost 2>/dev/null || echo "   Service not running"
systemctl disable funpay-boost 2>/dev/null || echo "   Service not enabled"
echo -e "${GREEN}   ✅ Service stopped and disabled${NC}"

# Step 2: Remove systemd service file
echo -e "${YELLOW}2. Removing systemd service file...${NC}"
if [[ -f /etc/systemd/system/funpay-boost.service ]]; then
    rm -f /etc/systemd/system/funpay-boost.service
    echo -e "${GREEN}   ✅ Service file removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Service file not found${NC}"
fi

# Step 3: Remove service override directory
echo -e "${YELLOW}3. Removing service override directory...${NC}"
if [[ -d /etc/systemd/system/funpay-boost.service.d ]]; then
    rm -rf /etc/systemd/system/funpay-boost.service.d
    echo -e "${GREEN}   ✅ Service override directory removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Service override directory not found${NC}"
fi

# Step 4: Reload systemd
echo -e "${YELLOW}4. Reloading systemd daemon...${NC}"
systemctl daemon-reload
echo -e "${GREEN}   ✅ Systemd daemon reloaded${NC}"

# Step 5: Remove management script
echo -e "${YELLOW}5. Removing management script...${NC}"
if [[ -f /usr/local/bin/funpay-boost ]]; then
    rm -f /usr/local/bin/funpay-boost
    echo -e "${GREEN}   ✅ Management script removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Management script not found${NC}"
fi

# Step 6: Kill any running processes
echo -e "${YELLOW}6. Killing any running FunPay processes...${NC}"
pkill -f "funpay" 2>/dev/null || echo "   No FunPay processes found"
pkill -f "firefox.*funpay" 2>/dev/null || echo "   No Firefox processes found"
pkill -f "geckodriver" 2>/dev/null || echo "   No geckodriver processes found"
pkill -f "Xvfb.*99" 2>/dev/null || echo "   No Xvfb :99 processes found"
pkill -f "Xvfb.*111" 2>/dev/null || echo "   No Xvfb :111 processes found"
pkill -f "funpay_boost_ultimate" 2>/dev/null || echo "   No ultimate script processes found"
echo -e "${GREEN}   ✅ Processes terminated${NC}"

# Step 7: Remove installation directory
echo -e "${YELLOW}7. Removing installation directory...${NC}"
if [[ -d /opt/funpay-boost ]]; then
    rm -rf /opt/funpay-boost
    echo -e "${GREEN}   ✅ Installation directory removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Installation directory not found${NC}"
fi

# Step 8: Remove configuration directory
echo -e "${YELLOW}8. Removing configuration directory...${NC}"
if [[ -d /etc/funpay ]]; then
    rm -rf /etc/funpay
    echo -e "${GREEN}   ✅ Configuration directory removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Configuration directory not found${NC}"
fi

# Step 9: Remove log directory
echo -e "${YELLOW}9. Removing log directory...${NC}"
if [[ -d /var/log/funpay ]]; then
    rm -rf /var/log/funpay
    echo -e "${GREEN}   ✅ Log directory removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Log directory not found${NC}"
fi

# Step 10: Remove service user
echo -e "${YELLOW}10. Removing service user...${NC}"
if id "funpay" &>/dev/null; then
    # Remove user home directory if it exists
    if [[ -d /home/funpay ]]; then
        rm -rf /home/funpay
        echo -e "${GREEN}   ✅ User home directory removed${NC}"
    fi
    
    # Delete user account
    userdel funpay 2>/dev/null
    echo -e "${GREEN}   ✅ Service user 'funpay' removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Service user 'funpay' not found${NC}"
fi

# Step 11: Clean up temporary files
echo -e "${YELLOW}11. Cleaning up temporary files...${NC}"
rm -f /tmp/.X99-lock 2>/dev/null || true
rm -f /tmp/.X111-lock 2>/dev/null || true
rm -f /tmp/.X*-lock 2>/dev/null || true
rm -f /tmp/geckodriver* 2>/dev/null || true
rm -f /tmp/funpay* 2>/dev/null || true
rm -f /tmp/test_* 2>/dev/null || true
rm -f /tmp/simple_test* 2>/dev/null || true
rm -f /tmp/quick_test* 2>/dev/null || true
echo -e "${GREEN}   ✅ Temporary files cleaned${NC}"

# Step 12: Remove any remaining Firefox profiles
echo -e "${YELLOW}12. Cleaning Firefox profiles...${NC}"
if [[ -d /home/funpay/.mozilla ]]; then
    rm -rf /home/funpay/.mozilla
    echo -e "${GREEN}   ✅ Firefox profiles removed${NC}"
else
    echo -e "${CYAN}   ℹ️ Firefox profiles not found${NC}"
fi

# Step 13: Clean up any remaining processes
echo -e "${YELLOW}13. Final process cleanup...${NC}"
# Kill any remaining processes more aggressively
for proc in firefox geckodriver Xvfb python3.*funpay; do
    if pgrep -f "$proc" >/dev/null; then
        pkill -9 -f "$proc" 2>/dev/null || true
        echo -e "${GREEN}   ✅ Killed remaining $proc processes${NC}"
    fi
done

# Additional cleanup for enhanced features
pkill -9 -f "funpay_boost_ultimate" 2>/dev/null || true
pkill -9 -f "simple_test" 2>/dev/null || true
pkill -9 -f "test_enhanced" 2>/dev/null || true

# Step 14: Clean up project directory files (optional)
echo -e "${YELLOW}14. Cleaning up project directory files...${NC}"
read -p "Do you want to remove test files from project directory? (y/N): " CLEAN_PROJECT
if [[ "$CLEAN_PROJECT" =~ ^[Yy]$ ]]; then
    # Find and remove test files
    find /root -name "simple_test.py" -delete 2>/dev/null || true
    find /root -name "test_enhanced_compatibility.py" -delete 2>/dev/null || true
    find /root -name "check_system_status.sh" -delete 2>/dev/null || true
    echo -e "${GREEN}   ✅ Project test files cleaned${NC}"
else
    echo -e "${CYAN}   ℹ️ Project files left unchanged${NC}"
fi

# Step 15: Remove any cron jobs (if any were created)
echo -e "${YELLOW}15. Checking for cron jobs...${NC}"
if crontab -l 2>/dev/null | grep -q "funpay"; then
    echo -e "${YELLOW}   Found FunPay cron jobs, removing...${NC}"
    crontab -l 2>/dev/null | grep -v "funpay" | crontab -
    echo -e "${GREEN}   ✅ Cron jobs removed${NC}"
else
    echo -e "${CYAN}   ℹ️ No FunPay cron jobs found${NC}"
fi

# Step 15: Verify cleanup
echo ""
echo -e "${CYAN}🔍 Verifying cleanup...${NC}"

CLEANUP_ISSUES=0

# Check service
if systemctl list-unit-files | grep -q "funpay-boost"; then
    echo -e "${RED}   ❌ Service still exists${NC}"
    ((CLEANUP_ISSUES++))
else
    echo -e "${GREEN}   ✅ Service completely removed${NC}"
fi

# Check directories
for dir in "/opt/funpay-boost" "/etc/funpay" "/var/log/funpay"; do
    if [[ -d "$dir" ]]; then
        echo -e "${RED}   ❌ Directory still exists: $dir${NC}"
        ((CLEANUP_ISSUES++))
    else
        echo -e "${GREEN}   ✅ Directory removed: $dir${NC}"
    fi
done

# Check user
if id "funpay" &>/dev/null; then
    echo -e "${RED}   ❌ User 'funpay' still exists${NC}"
    ((CLEANUP_ISSUES++))
else
    echo -e "${GREEN}   ✅ User 'funpay' removed${NC}"
fi

# Check processes
if pgrep -f "funpay" >/dev/null; then
    echo -e "${RED}   ❌ FunPay processes still running${NC}"
    ((CLEANUP_ISSUES++))
else
    echo -e "${GREEN}   ✅ No FunPay processes running${NC}"
fi

echo ""
if [[ $CLEANUP_ISSUES -eq 0 ]]; then
    echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
    echo -e "${GREEN}All FunPay Auto Boost components have been removed.${NC}"
else
    echo -e "${YELLOW}⚠️ Cleanup completed with $CLEANUP_ISSUES issues${NC}"
    echo -e "${YELLOW}You may need to manually remove remaining components.${NC}"
fi

echo ""
echo -e "${CYAN}📋 Summary of removed components:${NC}"
echo "   • Systemd service (funpay-boost)"
echo "   • Installation directory (/opt/funpay-boost)"
echo "   • Configuration directory (/etc/funpay)"
echo "   • Log directory (/var/log/funpay)"
echo "   • Service user (funpay)"
echo "   • Management script (/usr/local/bin/funpay-boost)"
echo "   • All running processes"
echo "   • Temporary files"
echo ""

echo -e "${BLUE}Cleanup script completed.${NC}"
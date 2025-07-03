#!/bin/bash

# FunPay Auto Boost - Complete Installation with Setup
# Everything in one script - no additional setup needed

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/funpay-boost"
SERVICE_USER="funpay"
LOG_DIR="/var/log/funpay"
CONFIG_DIR="/etc/funpay"

echo -e "${BLUE}🚀 FunPay Auto Boost - Complete Installation${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo -e "${RED}❌ Cannot detect OS version${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Detected OS: $OS $VER${NC}"

# Get user credentials at the beginning
echo ""
echo -e "${PURPLE}🔐 FUNPAY CREDENTIALS SETUP${NC}"
echo -e "${PURPLE}============================${NC}"
echo -e "${YELLOW}Please enter your FunPay account details:${NC}"
echo ""

read -p "📧 FunPay Username/Email: " FUNPAY_USERNAME
while [[ -z "$FUNPAY_USERNAME" ]]; do
    echo -e "${RED}❌ Username cannot be empty${NC}"
    read -p "📧 FunPay Username/Email: " FUNPAY_USERNAME
done

read -s -p "🔒 FunPay Password: " FUNPAY_PASSWORD
echo ""
while [[ -z "$FUNPAY_PASSWORD" ]]; do
    echo -e "${RED}❌ Password cannot be empty${NC}"
    read -s -p "🔒 FunPay Password: " FUNPAY_PASSWORD
    echo ""
done

echo ""
read -p "🔗 Your offers page URL (default: https://funpay.com/en/lots/1355/trade): " OFFERS_URL
if [[ -z "$OFFERS_URL" ]]; then
    OFFERS_URL="https://funpay.com/en/lots/1355/trade"
fi

echo ""
read -p "⏰ Boost interval in hours (default: 3): " BOOST_INTERVAL
if [[ -z "$BOOST_INTERVAL" ]]; then
    BOOST_INTERVAL=3
fi

# Validate boost interval is a number
if ! [[ "$BOOST_INTERVAL" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Boost interval must be a number${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Configuration collected:${NC}"
echo -e "   Username: $FUNPAY_USERNAME"
echo -e "   Password: [HIDDEN]"
echo -e "   Offers URL: $OFFERS_URL"
echo -e "   Boost Interval: $BOOST_INTERVAL hours"
echo ""

read -p "Continue with installation? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔧 Starting installation...${NC}"

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    apt update && apt upgrade -y
    PACKAGE_MANAGER="apt"
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Rocky"* ]]; then
    yum update -y
    PACKAGE_MANAGER="yum"
else
    echo -e "${RED}❌ Unsupported OS${NC}"
    exit 1
fi

# Install system dependencies
echo -e "${YELLOW}📚 Installing system dependencies...${NC}"
if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
    apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        firefox \
        wget \
        curl \
        unzip \
        git \
        supervisor \
        ufw \
        htop \
        screen \
        tmux \
        jq
elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
    yum install -y \
        python3 \
        python3-pip \
        firefox \
        wget \
        curl \
        unzip \
        git \
        supervisor \
        firewalld \
        htop \
        screen \
        tmux \
        jq
fi

# Create service user
echo -e "${YELLOW}👤 Creating service user...${NC}"
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
    echo -e "${GREEN}✅ User $SERVICE_USER created${NC}"
else
    echo -e "${GREEN}✅ User $SERVICE_USER already exists${NC}"
fi

# Create directories
echo -e "${YELLOW}📁 Creating directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "/home/$SERVICE_USER/.mozilla"

# Set permissions
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "/home/$SERVICE_USER"
chmod 755 "$INSTALL_DIR"
chmod 755 "$LOG_DIR"
chmod 750 "$CONFIG_DIR"

# Install Python virtual environment
echo -e "${YELLOW}🐍 Setting up Python virtual environment...${NC}"
cd "$INSTALL_DIR"
python3 -m venv venv
source venv/bin/activate

# Install Python packages
echo -e "${YELLOW}📦 Installing Python packages...${NC}"
pip install --upgrade pip
pip install selenium schedule requests beautifulsoup4 lxml

# Download and install GeckoDriver
echo -e "${YELLOW}🔽 Installing GeckoDriver...${NC}"
GECKODRIVER_VERSION="v0.33.0"
GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz"

wget -O /tmp/geckodriver.tar.gz "$GECKODRIVER_URL"
tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/
chmod +x /usr/local/bin/geckodriver
rm /tmp/geckodriver.tar.gz

echo -e "${GREEN}✅ GeckoDriver installed${NC}"

# Create configuration file with user input
echo -e "${YELLOW}📝 Creating configuration file...${NC}"
cat > "$CONFIG_DIR/config.json" << EOF
{
  "username": "$FUNPAY_USERNAME",
  "password": "$FUNPAY_PASSWORD",
  "target_url": "$OFFERS_URL",
  "boost_interval": $BOOST_INTERVAL,
  "last_boost": null,
  "created_at": "$(date -Iseconds)",
  "auto_restart": true,
  "max_retries": 5,
  "retry_delay": 1800
}
EOF

# Secure config file
chmod 600 "$CONFIG_DIR/config.json"
chown "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR/config.json"

echo -e "${GREEN}✅ Configuration saved securely${NC}"

# Create main application file
echo -e "${YELLOW}📝 Creating application file...${NC}"
cat > "$INSTALL_DIR/funpay_boost.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Production Linux Version
Complete automated solution
"""

import time
import os
import sys
import re
import json
import signal
import argparse
import tempfile
import subprocess
import logging
from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, WebDriverException

class FunPayBooster:
    def __init__(self, config_file='/etc/funpay/config.json'):
        self.driver = None
        self.config_file = config_file
        self.config = {}
        self.profile_dir = None
        self.consecutive_errors = 0
        self.max_errors = 5
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/funpay/boost.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Load configuration
        self.load_config()
        
    def load_config(self):
        """Load configuration"""
        try:
            with open(self.config_file, 'r') as f:
                self.config = json.load(f)
            self.logger.info("✅ Configuration loaded")
            return True
        except Exception as e:
            self.logger.error(f"❌ Failed to load config: {e}")
            return False
    
    def save_config(self):
        """Save configuration"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
            return True
        except Exception as e:
            self.logger.error(f"Failed to save config: {e}")
            return False
    
    def setup_firefox(self):
        """Setup Firefox driver"""
        try:
            # Clean up old profile if exists
            if self.profile_dir and os.path.exists(self.profile_dir):
                import shutil
                shutil.rmtree(self.profile_dir)
            
            self.profile_dir = tempfile.mkdtemp(prefix="firefox_profile_")
            
            firefox_options = Options()
            firefox_options.add_argument("--headless")
            firefox_options.add_argument("--no-sandbox")
            firefox_options.add_argument("--disable-dev-shm-usage")
            firefox_options.add_argument("--disable-gpu")
            firefox_options.add_argument("--disable-software-rasterizer")
            firefox_options.add_argument(f"--profile={self.profile_dir}")
            
            # Anti-detection preferences
            firefox_options.set_preference("general.useragent.override", 
                "Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0")
            firefox_options.set_preference("dom.webdriver.enabled", False)
            firefox_options.set_preference("useAutomationExtension", False)
            
            # Performance optimizations
            firefox_options.set_preference("browser.cache.disk.enable", False)
            firefox_options.set_preference("browser.cache.memory.enable", False)
            firefox_options.set_preference("network.http.use-cache", False)
            firefox_options.set_preference("media.volume_scale", "0.0")
            
            self.driver = webdriver.Firefox(options=firefox_options)
            self.driver.implicitly_wait(10)
            self.driver.set_page_load_timeout(30)
            
            self.logger.info("🦊 Firefox driver initialized")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Failed to setup Firefox: {e}")
            return False
    
    def login(self):
        """Automatic login"""
        try:
            username = self.config.get('username')
            password = self.config.get('password')
            login_url = "https://funpay.com/en/account/login"
            
            if not username or not password:
                self.logger.error("❌ No credentials in config")
                return False
            
            self.logger.info("🔐 Attempting login...")
            self.driver.get(login_url)
            
            wait = WebDriverWait(self.driver, 15)
            
            # Fill username
            username_field = wait.until(EC.presence_of_element_located((By.NAME, "login")))
            username_field.clear()
            username_field.send_keys(username)
            
            # Fill password
            password_field = self.driver.find_element(By.NAME, "password")
            password_field.clear()
            password_field.send_keys(password)
            
            # Submit
            login_button = self.driver.find_element(By.XPATH, "//button[@type='submit']")
            login_button.click()
            
            # Wait for redirect
            time.sleep(5)
            
            # Check success
            if "login" not in self.driver.current_url.lower():
                self.logger.info("✅ Login successful")
                return True
            else:
                self.logger.error("❌ Login failed - check credentials")
                return False
                
        except Exception as e:
            self.logger.error(f"❌ Login error: {e}")
            return False
    
    def check_boost_status(self):
        """Check boost availability"""
        try:
            target_url = self.config.get('target_url', 'https://funpay.com/en/lots/1355/trade')
            self.driver.get(target_url)
            
            # Wait for page load
            wait = WebDriverWait(self.driver, 15)
            wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
            time.sleep(3)
            
            page_source = self.driver.page_source.lower()
            
            # Check for wait messages
            wait_patterns = [
                r'please wait (\d+) hour',
                r'wait (\d+) hour',
                r'подождите (\d+) час',
                r'(\d+) hour.*wait'
            ]
            
            for pattern in wait_patterns:
                match = re.search(pattern, page_source)
                if match:
                    hours = int(match.group(1))
                    self.logger.info(f"⏰ Must wait {hours} hours")
                    return "wait", hours
            
            # Generic wait detection
            if any(word in page_source for word in ["please wait", "подождите", "wait"]):
                self.logger.info("⏰ Must wait (assuming 3 hours)")
                return "wait", 3
            
            # Look for boost buttons
            boost_selectors = [
                "//button[contains(text(), 'Boost offers')]",
                "//a[contains(text(), 'Boost offers')]",
                "//button[contains(text(), 'Boost')]",
                "//a[contains(text(), 'Boost')]",
                "//button[contains(text(), 'Поднять')]",
                "//a[contains(text(), 'Поднять')]",
                "//*[contains(@class, 'boost')]"
            ]
            
            for selector in boost_selectors:
                try:
                    elements = self.driver.find_elements(By.XPATH, selector)
                    for element in elements:
                        if element.is_displayed() and element.is_enabled():
                            self.logger.info("🚀 Boost button found")
                            return "available", element
                except:
                    continue
            
            self.logger.info("❓ Boost status unclear")
            return "unknown", None
            
        except Exception as e:
            self.logger.error(f"❌ Error checking boost: {e}")
            return "error", None
    
    def click_boost(self, element):
        """Click boost button"""
        try:
            # Scroll to element
            self.driver.execute_script("arguments[0].scrollIntoView(true);", element)
            time.sleep(1)
            
            # Click
            element.click()
            self.logger.info("✅ Boost button clicked")
            
            time.sleep(3)
            
            # Check for success
            page_source = self.driver.page_source.lower()
            success_keywords = ["boosted", "success", "поднят", "успешно"]
            
            success = any(keyword in page_source for keyword in success_keywords)
            if success:
                self.logger.info("🎉 SUCCESS: Offers boosted!")
            
            # Update last boost time
            self.config['last_boost'] = datetime.now().isoformat()
            self.save_config()
            
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Error clicking boost: {e}")
            return False
    
    def restart_driver(self):
        """Restart Firefox driver"""
        try:
            self.logger.info("🔄 Restarting driver...")
            if self.driver:
                self.driver.quit()
            time.sleep(5)
            
            if self.setup_firefox() and self.login():
                self.logger.info("✅ Driver restarted successfully")
                return True
            else:
                self.logger.error("❌ Failed to restart driver")
                return False
        except Exception as e:
            self.logger.error(f"❌ Error restarting driver: {e}")
            return False
    
    def run_daemon(self):
        """Main daemon loop"""
        self.logger.info("🚀 Starting FunPay Auto Boost Daemon")
        self.logger.info(f"📊 Target URL: {self.config.get('target_url')}")
        self.logger.info(f"⏰ Boost Interval: {self.config.get('boost_interval')} hours")
        
        if not self.setup_firefox():
            self.logger.error("❌ Failed to setup Firefox")
            return False
        
        if not self.login():
            self.logger.error("❌ Failed to login")
            return False
        
        self.logger.info("🎯 Boost monitoring started")
        
        while True:
            try:
                status, data = self.check_boost_status()
                
                if status == "available":
                    if self.click_boost(data):
                        wait_hours = self.config.get('boost_interval', 3)
                        next_time = datetime.now() + timedelta(hours=wait_hours)
                        self.logger.info(f"⏰ Next boost: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                        self.consecutive_errors = 0
                        
                        # Sleep with periodic updates
                        for i in range(wait_hours):
                            time.sleep(3600)  # 1 hour
                            remaining = wait_hours - i - 1
                            if remaining > 0:
                                self.logger.info(f"⏳ {remaining} hours until next boost")
                    else:
                        self.logger.info("🔄 Boost failed, retrying in 30 minutes")
                        time.sleep(1800)
                        
                elif status == "wait":
                    hours = data
                    next_time = datetime.now() + timedelta(hours=hours)
                    self.logger.info(f"⏰ Next check: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.consecutive_errors = 0
                    
                    # Sleep with updates
                    for i in range(hours):
                        time.sleep(3600)
                        remaining = hours - i - 1
                        if remaining > 0:
                            self.logger.info(f"⏳ {remaining} hours remaining")
                    
                elif status == "unknown":
                    self.logger.info("🔄 Status unclear, checking again in 1 hour")
                    self.consecutive_errors = 0
                    time.sleep(3600)
                    
                else:  # error
                    self.consecutive_errors += 1
                    if self.consecutive_errors >= self.max_errors:
                        self.logger.warning(f"⚠️ Too many errors ({self.max_errors}), restarting driver...")
                        if self.restart_driver():
                            self.consecutive_errors = 0
                        else:
                            self.logger.error("❌ Failed to restart, waiting 1 hour...")
                            time.sleep(3600)
                    else:
                        retry_delay = self.config.get('retry_delay', 1800)
                        self.logger.info(f"🔄 Error {self.consecutive_errors}/{self.max_errors}, retrying in {retry_delay//60} minutes")
                        time.sleep(retry_delay)
                
            except KeyboardInterrupt:
                self.logger.info("🛑 Daemon stopped by user")
                break
            except Exception as e:
                self.logger.error(f"❌ Unexpected error: {e}")
                self.consecutive_errors += 1
                time.sleep(1800)
        
        return True
    
    def get_status(self):
        """Get current status"""
        try:
            last_boost = self.config.get('last_boost')
            if last_boost:
                last_boost_time = datetime.fromisoformat(last_boost)
                next_boost = last_boost_time + timedelta(hours=self.config.get('boost_interval', 3))
                
                print(f"📊 FunPay Boost Status")
                print(f"=====================")
                print(f"Last boost: {last_boost_time.strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"Next boost: {next_boost.strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"Target URL: {self.config.get('target_url')}")
                print(f"Interval: {self.config.get('boost_interval')} hours")
            else:
                print("📊 No boost recorded yet")
        except Exception as e:
            print(f"❌ Error getting status: {e}")
    
    def cleanup(self):
        """Cleanup resources"""
        if self.driver:
            try:
                self.driver.quit()
            except:
                pass
        
        if self.profile_dir and os.path.exists(self.profile_dir):
            try:
                import shutil
                shutil.rmtree(self.profile_dir)
            except:
                pass

def signal_handler(signum, frame):
    """Handle system signals"""
    logging.info(f"Received signal {signum}, shutting down gracefully...")
    sys.exit(0)

def main():
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    parser = argparse.ArgumentParser(description='FunPay Auto Boost')
    parser.add_argument('--daemon', action='store_true', help='Run as daemon')
    parser.add_argument('--status', action='store_true', help='Show status')
    args = parser.parse_args()
    
    booster = FunPayBooster()
    
    if args.status:
        booster.get_status()
        return
    
    try:
        booster.run_daemon()
    except KeyboardInterrupt:
        print("\n🛑 Stopped by user")
    except Exception as e:
        logging.error(f"❌ Fatal error: {e}")
    finally:
        booster.cleanup()

if __name__ == "__main__":
    main()
EOF

# Make executable
chmod +x "$INSTALL_DIR/funpay_boost.py"
chown "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR/funpay_boost.py"

# Create systemd service
echo -e "${YELLOW}⚙️ Creating systemd service...${NC}"
cat > /etc/systemd/system/funpay-boost.service << EOF
[Unit]
Description=FunPay Auto Boost Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/funpay_boost.py --daemon
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$LOG_DIR $CONFIG_DIR $INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

# Create management script
echo -e "${YELLOW}🔧 Creating management script...${NC}"
cat > /usr/local/bin/funpay-boost << EOF
#!/bin/bash

INSTALL_DIR="$INSTALL_DIR"
SERVICE_USER="$SERVICE_USER"

case "\$1" in
    start)
        echo "🚀 Starting FunPay Boost..."
        systemctl start funpay-boost
        ;;
    stop)
        echo "🛑 Stopping FunPay Boost..."
        systemctl stop funpay-boost
        ;;
    restart)
        echo "🔄 Restarting FunPay Boost..."
        systemctl restart funpay-boost
        ;;
    status)
        systemctl status funpay-boost
        ;;
    logs)
        journalctl -u funpay-boost -f
        ;;
    info)
        echo "📊 Getting boost status..."
        sudo -u \$SERVICE_USER \$INSTALL_DIR/venv/bin/python \$INSTALL_DIR/funpay_boost.py --status
        ;;
    config)
        echo "📝 Current configuration:"
        sudo cat $CONFIG_DIR/config.json | jq .
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status|logs|info|config}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the service"
        echo "  stop     - Stop the service"
        echo "  restart  - Restart the service"
        echo "  status   - Show service status"
        echo "  logs     - Show live logs"
        echo "  info     - Show boost information"
        echo "  config   - Show configuration"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/funpay-boost

# Setup firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
elif command -v firewalld &> /dev/null; then
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --reload
fi

# Setup log rotation
echo -e "${YELLOW}📜 Setting up log rotation...${NC}"
cat > /etc/logrotate.d/funpay-boost << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_USER
    postrotate
        systemctl reload funpay-boost
    endscript
}
EOF

# Enable and start service
echo -e "${YELLOW}🔄 Enabling and starting service...${NC}"
systemctl daemon-reload
systemctl enable funpay-boost
systemctl start funpay-boost

# Wait a moment and check status
sleep 3
SERVICE_STATUS=$(systemctl is-active funpay-boost)

echo ""
echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
echo ""

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ Service is running successfully!${NC}"
else
    echo -e "${YELLOW}⚠️ Service status: $SERVICE_STATUS${NC}"
    echo -e "${YELLOW}Check logs with: funpay-boost logs${NC}"
fi

echo ""
echo -e "${BLUE}📋 Your FunPay Auto Boost is now running!${NC}"
echo ""
echo -e "${BLUE}🔧 Management Commands:${NC}"
echo "   funpay-boost start     - Start the service"
echo "   funpay-boost stop      - Stop the service"
echo "   funpay-boost restart   - Restart the service"
echo "   funpay-boost status    - Show service status"
echo "   funpay-boost logs      - Show live logs"
echo "   funpay-boost info      - Show boost information"
echo "   funpay-boost config    - Show configuration"
echo ""
echo -e "${BLUE}📁 Important Paths:${NC}"
echo "   Application: $INSTALL_DIR"
echo "   Logs: $LOG_DIR"
echo "   Config: $CONFIG_DIR"
echo ""
echo -e "${GREEN}🚀 Your offers will be automatically boosted every $BOOST_INTERVAL hours!${NC}"
echo -e "${GREEN}📊 Check status anytime with: funpay-boost info${NC}"
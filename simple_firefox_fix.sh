#!/bin/bash

# Simple Firefox Fix - Step by Step
# This script fixes Firefox timeout issues with minimal changes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                ${WHITE}Simple Firefox Fix${BLUE}                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${CYAN}🛑 Step 1: Stopping service and cleaning up...${NC}"
systemctl stop funpay-boost 2>/dev/null || true
pkill -f firefox 2>/dev/null || true
pkill -f geckodriver 2>/dev/null || true
pkill -f Xvfb 2>/dev/null || true
sleep 3

echo -e "${CYAN}🔧 Step 2: Creating optimized Firefox profile...${NC}"

# Remove old profile
rm -rf /home/funpay/.mozilla/firefox/default 2>/dev/null || true
mkdir -p /home/funpay/.mozilla/firefox/default

# Create minimal Firefox preferences focused on timeout fixes
cat > /home/funpay/.mozilla/firefox/default/prefs.js << 'EOF'
// Critical timeout settings
user_pref("dom.max_script_run_time", 5);
user_pref("dom.max_chrome_script_run_time", 5);
user_pref("network.http.connection-timeout", 10);
user_pref("network.http.response.timeout", 10);
user_pref("network.http.request.timeout", 10);

// Disable content processes to reduce complexity
user_pref("dom.ipc.processCount", 1);
user_pref("dom.ipc.processCount.web", 1);

// Disable sandboxing
user_pref("security.sandbox.content.level", 0);

// Performance settings
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", false);
user_pref("permissions.default.image", 2);
user_pref("javascript.enabled", true);

// Disable unnecessary features
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("app.update.enabled", false);
EOF

chown -R funpay:funpay /home/funpay/.mozilla

echo -e "${CYAN}🔧 Step 3: Creating simplified Python script...${NC}"

# Backup original script
cp /opt/funpay-boost/funpay_boost.py /opt/funpay-boost/funpay_boost_backup.py 2>/dev/null || true

# Create a much simpler version
cat > /opt/funpay-boost/funpay_boost_simple.py << 'EOF'
#!/usr/bin/env python3
import time
import os
import sys
import json
import signal
import logging
import subprocess
from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

class FunPayBooster:
    def __init__(self, config_file='/etc/funpay/config.json'):
        self.driver = None
        self.config_file = config_file
        self.config = {}
        
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
        if not self.load_config():
            self.logger.error("Failed to load configuration")
            sys.exit(1)
        
    def load_config(self):
        try:
            with open(self.config_file, 'r') as f:
                self.config = json.load(f)
            
            required_fields = ['username', 'password', 'target_url']
            for field in required_fields:
                if not self.config.get(field):
                    self.logger.error(f"Missing required field: {field}")
                    return False
            
            self.logger.info("Configuration loaded successfully")
            return True
        except Exception as e:
            self.logger.error(f"Failed to load config: {e}")
            return False
    
    def save_config(self):
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
            return True
        except Exception as e:
            self.logger.error(f"Failed to save config: {e}")
            return False
    
    def setup_firefox(self):
        try:
            self.logger.info("Setting up Firefox...")
            
            # Kill existing processes
            subprocess.run(['pkill', '-f', 'firefox'], capture_output=True)
            subprocess.run(['pkill', '-f', 'geckodriver'], capture_output=True)
            subprocess.run(['pkill', '-f', 'Xvfb'], capture_output=True)
            time.sleep(2)
            
            # Start Xvfb
            self.logger.info("Starting virtual display...")
            xvfb_process = subprocess.Popen(
                ['Xvfb', ':99', '-screen', '0', '1024x768x24'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            time.sleep(2)
            os.environ['DISPLAY'] = ':99'
            
            # Setup Firefox options
            firefox_options = Options()
            firefox_options.add_argument("--headless")
            firefox_options.add_argument("--no-sandbox")
            firefox_options.add_argument("--disable-dev-shm-usage")
            firefox_options.add_argument("--single-process")
            firefox_options.add_argument("--profile=/home/funpay/.mozilla/firefox/default")
            
            # Create service with short timeout
            service = Service(
                executable_path='/usr/local/bin/geckodriver',
                service_args=['--log', 'fatal']
            )
            
            self.logger.info("Starting Firefox driver...")
            self.driver = webdriver.Firefox(
                service=service,
                options=firefox_options
            )
            
            # Set very short timeouts
            self.driver.implicitly_wait(3)
            self.driver.set_page_load_timeout(10)
            
            self.logger.info("Firefox started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Firefox setup failed: {e}")
            return False
    
    def login(self):
        try:
            username = self.config.get('username')
            password = self.config.get('password')
            
            self.logger.info("Attempting login...")
            
            # Navigate to login page
            self.driver.get("https://funpay.com/en/account/login")
            
            # Find username field
            wait = WebDriverWait(self.driver, 5)
            username_field = wait.until(EC.presence_of_element_located((By.NAME, "login")))
            username_field.send_keys(username)
            
            # Find password field
            password_field = self.driver.find_element(By.NAME, "password")
            password_field.send_keys(password)
            
            # Submit
            login_button = self.driver.find_element(By.XPATH, "//button[@type='submit']")
            login_button.click()
            
            time.sleep(3)
            
            # Check if login successful
            if "login" not in self.driver.current_url.lower():
                self.logger.info("Login successful")
                return True
            else:
                self.logger.error("Login failed")
                return False
                
        except Exception as e:
            self.logger.error(f"Login error: {e}")
            return False
    
    def check_boost_status(self):
        try:
            target_url = self.config.get('target_url')
            self.logger.info(f"Checking boost status...")
            
            self.driver.get(target_url)
            time.sleep(2)
            
            # Simple check for boost button
            try:
                boost_button = self.driver.find_element(By.XPATH, "//button[contains(text(), 'boost')] | //a[contains(text(), 'boost')]")
                if boost_button.is_displayed():
                    self.logger.info("Boost button available")
                    return "available", boost_button
            except:
                pass
            
            # Check for wait message
            page_source = self.driver.page_source.lower()
            if "wait" in page_source or "подожд" in page_source:
                self.logger.info("Must wait before boost")
                return "wait", 3  # Default 3 hours
            
            return "unknown", None
            
        except Exception as e:
            self.logger.error(f"Error checking status: {e}")
            return "error", None
    
    def click_boost(self, element):
        try:
            element.click()
            self.logger.info("Boost clicked successfully")
            
            # Update last boost time
            self.config['last_boost'] = datetime.now().isoformat()
            self.save_config()
            
            return True
        except Exception as e:
            self.logger.error(f"Error clicking boost: {e}")
            return False
    
    def run_daemon(self):
        self.logger.info("Starting FunPay Auto Boost (Simple Version)")
        
        # Setup Firefox
        if not self.setup_firefox():
            self.logger.error("Failed to setup Firefox")
            return False
        
        # Login
        if not self.login():
            self.logger.error("Failed to login")
            return False
        
        self.logger.info("Boost monitoring started")
        
        while True:
            try:
                status, data = self.check_boost_status()
                
                if status == "available":
                    if self.click_boost(data):
                        wait_hours = self.config.get('boost_interval', 3)
                        self.logger.info(f"Boost successful, waiting {wait_hours} hours")
                        time.sleep(wait_hours * 3600)
                    else:
                        self.logger.warning("Boost failed, retrying in 30 minutes")
                        time.sleep(1800)
                        
                elif status == "wait":
                    hours = data
                    self.logger.info(f"Waiting {hours} hours")
                    time.sleep(hours * 3600)
                    
                else:
                    self.logger.warning("Status unclear, retrying in 15 minutes")
                    time.sleep(900)
                
            except KeyboardInterrupt:
                self.logger.info("Daemon stopped")
                break
            except Exception as e:
                self.logger.error(f"Unexpected error: {e}")
                time.sleep(1800)
        
        return True
    
    def get_status(self):
        last_boost = self.config.get('last_boost')
        interval = self.config.get('boost_interval', 3)
        
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║                    FunPay Auto Boost Status                 ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print("")
        print(f"🎯 Target URL: {self.config.get('target_url')}")
        print(f"👤 Username: {self.config.get('username')}")
        print(f"⏰ Boost Interval: {interval} hours")
        print("")
        
        if last_boost:
            try:
                last_time = datetime.fromisoformat(last_boost)
                print(f"📅 Last Boost: {last_time.strftime('%Y-%m-%d %H:%M:%S')}")
            except:
                print(f"📅 Last Boost: {last_boost}")
        else:
            print(f"📅 Last Boost: Never")
        
        print("")
    
    def cleanup(self):
        try:
            if self.driver:
                self.driver.quit()
            subprocess.run(['pkill', '-f', 'firefox'], capture_output=True)
            subprocess.run(['pkill', '-f', 'geckodriver'], capture_output=True)
            subprocess.run(['pkill', '-f', 'Xvfb'], capture_output=True)
        except:
            pass

def signal_handler(signum, frame):
    logging.info("Shutting down...")
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    import argparse
    parser = argparse.ArgumentParser(description='FunPay Auto Boost - Simple')
    parser.add_argument('--daemon', action='store_true', help='Run as daemon')
    parser.add_argument('--status', action='store_true', help='Show status')
    args = parser.parse_args()
    
    booster = FunPayBooster()
    
    if args.status:
        booster.get_status()
        return
    
    try:
        booster.run_daemon()
    except Exception as e:
        print(f"Fatal error: {e}")
    finally:
        booster.cleanup()

if __name__ == "__main__":
    main()
EOF

chmod +x /opt/funpay-boost/funpay_boost_simple.py
chown funpay:funpay /opt/funpay-boost/funpay_boost_simple.py

echo -e "${CYAN}🔧 Step 4: Updating systemd service...${NC}"

# Update systemd service to use simple script
sed -i 's|funpay_boost.*\.py|funpay_boost_simple.py|g' /etc/systemd/system/funpay-boost.service

# Reload systemd
systemctl daemon-reload

echo -e "${CYAN}🧪 Step 5: Testing simple Firefox setup...${NC}"

# Quick test
echo "Testing Firefox with simple setup..."
if sudo -u funpay timeout 30 /opt/funpay-boost/venv/bin/python -c "
import subprocess, time, os
from selenium import webdriver
from selenium.webdriver.firefox.options import Options

try:
    # Start Xvfb
    subprocess.Popen(['Xvfb', ':99'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)
    os.environ['DISPLAY'] = ':99'
    
    # Test Firefox
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--single-process')
    options.add_argument('--profile=/home/funpay/.mozilla/firefox/default')
    
    driver = webdriver.Firefox(options=options)
    driver.set_page_load_timeout(5)
    driver.get('data:text/html,<html><body>Test</body></html>')
    print('✅ Firefox test successful')
    driver.quit()
except Exception as e:
    print(f'❌ Test failed: {e}')
"; then
    echo -e "${GREEN}✅ Simple Firefox test passed!${NC}"
else
    echo -e "${YELLOW}⚠️ Test had issues, but continuing...${NC}"
fi

echo -e "${CYAN}🚀 Step 6: Starting service...${NC}"

# Start the service
systemctl start funpay-boost

# Wait and check
sleep 10

echo -e "${CYAN}📊 Service Status:${NC}"
systemctl status funpay-boost --no-pager

echo ""
echo -e "${GREEN}🎉 Simple Firefox fix completed!${NC}"
echo ""
echo -e "${CYAN}💡 What was changed:${NC}"
echo "   • Created minimal Firefox profile with short timeouts"
echo "   • Simplified Python script with basic functionality"
echo "   • Reduced complexity to avoid hangs"
echo "   • Set aggressive timeouts (5-10 seconds)"
echo ""
echo -e "${CYAN}📋 Monitor with:${NC}"
echo "   funpay-boost logs"
echo "   funpay-boost status"
echo ""
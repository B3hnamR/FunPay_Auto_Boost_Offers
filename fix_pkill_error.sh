#!/bin/bash

# FunPay Auto Boost - Fix pkill Error
# This script fixes the "No such file or directory: 'pkill'" error

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 FunPay Auto Boost - pkill Error Fix${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Stop the service first
echo -e "${YELLOW}🛑 Stopping FunPay service...${NC}"
systemctl stop funpay-boost || true

# Install missing packages
echo -e "${YELLOW}📦 Installing missing packages...${NC}"
apt update
apt install -y procps psmisc

echo -e "${GREEN}✅ Packages installed${NC}"

# Update the Python script with better error handling
echo -e "${YELLOW}📝 Updating Python script...${NC}"
cat > /opt/funpay-boost/funpay_boost.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Ubuntu Optimized Version with pkill fix
"""

import time
import os
import sys
import re
import json
import signal
import logging
import tempfile
import subprocess
from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, WebDriverException

class FunPayBooster:
    def __init__(self, config_file='/etc/funpay/config.json'):
        self.driver = None
        self.config_file = config_file
        self.config = {}
        self.consecutive_errors = 0
        self.max_errors = 3
        
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
        """Load configuration"""
        try:
            if not os.path.exists(self.config_file):
                self.logger.error(f"Config file not found: {self.config_file}")
                return False
                
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
        """Save configuration"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
            return True
        except Exception as e:
            self.logger.error(f"Failed to save config: {e}")
            return False
    
    def kill_processes(self, process_name):
        """Kill processes with fallback methods"""
        try:
            # Try pkill first
            result = subprocess.run(['pkill', '-f', process_name], 
                                  capture_output=True, check=False)
            if result.returncode == 0:
                return True
        except FileNotFoundError:
            pass
        
        try:
            # Try killall as fallback
            result = subprocess.run(['killall', process_name], 
                                  capture_output=True, check=False)
            if result.returncode == 0:
                return True
        except FileNotFoundError:
            pass
        
        try:
            # Try ps + grep + kill as last resort
            ps_result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
            if ps_result.returncode == 0:
                lines = ps_result.stdout.split('\n')
                for line in lines:
                    if process_name in line and 'grep' not in line:
                        parts = line.split()
                        if len(parts) > 1:
                            pid = parts[1]
                            try:
                                subprocess.run(['kill', pid], check=False)
                            except:
                                pass
                return True
        except:
            pass
        
        self.logger.warning(f"Could not kill {process_name} processes")
        return False
    
    def setup_display(self):
        """Setup virtual display"""
        try:
            # Kill existing Xvfb processes
            self.kill_processes('Xvfb')
            time.sleep(2)
            
            # Start Xvfb
            subprocess.Popen(['Xvfb', ':99', '-screen', '0', '1920x1080x24'], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(3)
            
            os.environ['DISPLAY'] = ':99'
            self.logger.info("Virtual display started")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to setup display: {e}")
            return False
    
    def setup_firefox(self):
        """Setup Firefox driver"""
        try:
            if not self.setup_display():
                return False
            
            firefox_options = Options()
            firefox_options.add_argument("--headless")
            firefox_options.add_argument("--no-sandbox")
            firefox_options.add_argument("--disable-dev-shm-usage")
            firefox_options.add_argument("--width=1920")
            firefox_options.add_argument("--height=1080")
            
            # Anti-detection settings
            firefox_options.set_preference("general.useragent.override", 
                "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0")
            firefox_options.set_preference("dom.webdriver.enabled", False)
            firefox_options.set_preference("useAutomationExtension", False)
            
            # Performance settings
            firefox_options.set_preference("browser.cache.disk.enable", False)
            firefox_options.set_preference("browser.cache.memory.enable", False)
            firefox_options.set_preference("media.volume_scale", "0.0")
            firefox_options.set_preference("browser.privatebrowsing.autostart", True)
            
            self.driver = webdriver.Firefox(options=firefox_options)
            self.driver.implicitly_wait(10)
            self.driver.set_page_load_timeout(30)
            
            self.logger.info("Firefox driver initialized")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to setup Firefox: {e}")
            return False
    
    def login(self):
        """Login to FunPay"""
        try:
            username = self.config.get('username')
            password = self.config.get('password')
            
            self.logger.info("Attempting login...")
            self.driver.get("https://funpay.com/en/account/login")
            
            wait = WebDriverWait(self.driver, 15)
            
            # Fill credentials
            username_field = wait.until(EC.presence_of_element_located((By.NAME, "login")))
            username_field.clear()
            username_field.send_keys(username)
            
            password_field = self.driver.find_element(By.NAME, "password")
            password_field.clear()
            password_field.send_keys(password)
            
            # Submit
            login_button = self.driver.find_element(By.XPATH, "//button[@type='submit']")
            login_button.click()
            
            time.sleep(5)
            
            # Check success
            if "login" not in self.driver.current_url.lower():
                self.logger.info("Login successful!")
                return True
            else:
                page_source = self.driver.page_source.lower()
                if "captcha" in page_source or "recaptcha" in page_source:
                    self.logger.error("CAPTCHA detected - manual intervention needed")
                else:
                    self.logger.error("Login failed - check credentials")
                return False
                
        except Exception as e:
            self.logger.error(f"Login error: {e}")
            return False
    
    def check_boost_status(self):
        """Check boost availability"""
        try:
            target_url = self.config.get('target_url')
            self.driver.get(target_url)
            
            wait = WebDriverWait(self.driver, 15)
            wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
            time.sleep(3)
            
            page_source = self.driver.page_source.lower()
            
            # Check for wait messages
            wait_patterns = [
                r'please wait (\d+) hour',
                r'wait (\d+) hour',
                r'подождите (\d+) час'
            ]
            
            for pattern in wait_patterns:
                match = re.search(pattern, page_source)
                if match:
                    hours = int(match.group(1))
                    self.logger.info(f"Must wait {hours} hours")
                    return "wait", hours
            
            # Generic wait detection
            if any(word in page_source for word in ["please wait", "подождите", "wait"]):
                self.logger.info("Must wait (assuming 3 hours)")
                return "wait", 3
            
            # Look for boost buttons
            boost_selectors = [
                "//button[contains(text(), 'Boost offers')]",
                "//a[contains(text(), 'Boost offers')]",
                "//button[contains(text(), 'Boost')]",
                "//a[contains(text(), 'Boost')]",
                "//button[contains(text(), 'Поднять')]",
                "//*[contains(@class, 'boost')]"
            ]
            
            for selector in boost_selectors:
                try:
                    elements = self.driver.find_elements(By.XPATH, selector)
                    for element in elements:
                        if element.is_displayed() and element.is_enabled():
                            self.logger.info("Boost button found!")
                            return "available", element
                except:
                    continue
            
            self.logger.info("Boost status unclear")
            return "unknown", None
            
        except Exception as e:
            self.logger.error(f"Error checking boost: {e}")
            return "error", None
    
    def click_boost(self, element):
        """Click boost button"""
        try:
            self.driver.execute_script("arguments[0].scrollIntoView(true);", element)
            time.sleep(1)
            element.click()
            self.logger.info("Boost button clicked!")
            
            time.sleep(3)
            
            # Check for success
            page_source = self.driver.page_source.lower()
            if any(word in page_source for word in ["boosted", "success", "поднят"]):
                self.logger.info("SUCCESS: Offers boosted!")
            
            # Update config
            self.config['last_boost'] = datetime.now().isoformat()
            self.save_config()
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error clicking boost: {e}")
            return False
    
    def restart_driver(self):
        """Restart Firefox"""
        try:
            self.logger.info("Restarting Firefox...")
            
            if self.driver:
                self.driver.quit()
            
            # Kill processes
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            time.sleep(5)
            
            # Restart
            if self.setup_firefox() and self.login():
                self.logger.info("Driver restarted successfully")
                return True
            else:
                return False
                
        except Exception as e:
            self.logger.error(f"Error restarting: {e}")
            return False
    
    def run_daemon(self):
        """Main daemon loop"""
        self.logger.info("Starting FunPay Auto Boost Daemon")
        self.logger.info(f"Target: {self.config.get('target_url')}")
        self.logger.info(f"Interval: {self.config.get('boost_interval', 3)} hours")
        
        if not self.setup_firefox():
            return False
        
        if not self.login():
            return False
        
        self.logger.info("Boost monitoring started")
        
        while True:
            try:
                status, data = self.check_boost_status()
                
                if status == "available":
                    if self.click_boost(data):
                        wait_hours = self.config.get('boost_interval', 3)
                        next_time = datetime.now() + timedelta(hours=wait_hours)
                        self.logger.info(f"Next boost: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                        self.consecutive_errors = 0
                        
                        # Sleep with updates
                        for i in range(wait_hours):
                            time.sleep(3600)
                            remaining = wait_hours - i - 1
                            if remaining > 0:
                                self.logger.info(f"{remaining} hours until next boost")
                    else:
                        time.sleep(1800)
                        
                elif status == "wait":
                    hours = data
                    next_time = datetime.now() + timedelta(hours=hours)
                    self.logger.info(f"Next check: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.consecutive_errors = 0
                    
                    for i in range(hours):
                        time.sleep(3600)
                        remaining = hours - i - 1
                        if remaining > 0:
                            self.logger.info(f"{remaining} hours remaining")
                    
                else:
                    self.consecutive_errors += 1
                    if self.consecutive_errors >= self.max_errors:
                        self.logger.warning("Too many errors, restarting...")
                        if self.restart_driver():
                            self.consecutive_errors = 0
                        else:
                            time.sleep(3600)
                    else:
                        self.logger.info(f"Error {self.consecutive_errors}/{self.max_errors}, retrying in 30 min")
                        time.sleep(1800)
                
            except KeyboardInterrupt:
                self.logger.info("Daemon stopped")
                break
            except Exception as e:
                self.logger.error(f"Error: {e}")
                time.sleep(1800)
        
        return True
    
    def get_status(self):
        """Show status"""
        try:
            last_boost = self.config.get('last_boost')
            interval = self.config.get('boost_interval', 3)
            
            print(f"FunPay Auto Boost Status")
            print(f"========================")
            print(f"Target: {self.config.get('target_url')}")
            print(f"Username: {self.config.get('username')}")
            print(f"Interval: {interval} hours")
            
            if last_boost:
                last_time = datetime.fromisoformat(last_boost)
                next_time = last_time + timedelta(hours=interval)
                print(f"Last Boost: {last_time.strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"Next Boost: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                
                now = datetime.now()
                if next_time > now:
                    remaining = next_time - now
                    hours = int(remaining.total_seconds() // 3600)
                    minutes = int((remaining.total_seconds() % 3600) // 60)
                    print(f"Time Remaining: {hours}h {minutes}m")
                else:
                    print("Status: Ready for boost!")
            else:
                print("Last Boost: Never")
                
        except Exception as e:
            print(f"Error: {e}")
    
    def cleanup(self):
        """Cleanup"""
        try:
            if self.driver:
                self.driver.quit()
            
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            self.kill_processes('Xvfb')
        except:
            pass

def signal_handler(signum, frame):
    logging.info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--daemon', action='store_true')
    parser.add_argument('--status', action='store_true')
    args = parser.parse_args()
    
    booster = FunPayBooster()
    
    if args.status:
        booster.get_status()
        return
    
    try:
        booster.run_daemon()
    except KeyboardInterrupt:
        print("\nStopped")
    finally:
        booster.cleanup()

if __name__ == "__main__":
    main()
EOF

# Set permissions
chown funpay:funpay /opt/funpay-boost/funpay_boost.py
chmod +x /opt/funpay-boost/funpay_boost.py

echo -e "${GREEN}✅ Python script updated${NC}"

# Restart the service
echo -e "${YELLOW}🔄 Starting FunPay service...${NC}"
systemctl daemon-reload
systemctl start funpay-boost

sleep 5
SERVICE_STATUS=$(systemctl is-active funpay-boost)

echo ""
echo -e "${GREEN}🎉 Fix completed!${NC}"
echo ""

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ Service is now running!${NC}"
else
    echo -e "${YELLOW}⚠️ Service status: $SERVICE_STATUS${NC}"
    echo -e "${YELLOW}Check logs with: funpay-boost logs${NC}"
fi

echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  funpay-boost status  - Show service status"
echo "  funpay-boost logs    - Show logs"
echo "  funpay-boost info    - Show boost info"
echo ""
echo -e "${GREEN}The pkill error should now be fixed!${NC}"
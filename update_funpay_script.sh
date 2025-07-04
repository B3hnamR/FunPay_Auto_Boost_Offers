#!/bin/bash

# Update FunPay script with better error handling and GeckoDriver compatibility

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ${WHITE}Updating FunPay Script${BLUE}                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${CYAN}🔄 Updating FunPay boost script with improved error handling...${NC}"

# Stop the service
systemctl stop funpay-boost 2>/dev/null || true

# Backup existing script
if [[ -f /opt/funpay-boost/funpay_boost.py ]]; then
    cp /opt/funpay-boost/funpay_boost.py /opt/funpay-boost/funpay_boost.py.backup
    echo -e "${GREEN}✅ Backup created${NC}"
fi

# Create updated script
cat > /opt/funpay-boost/funpay_boost.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Enhanced Version with Better Error Handling
"""

import time
import os
import sys
import re
import json
import signal
import logging
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
        self.xvfb_process = None
        
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
        """Kill processes with multiple fallback methods"""
        killed = False
        
        # Method 1: pkill
        try:
            result = subprocess.run(['pkill', '-f', process_name], 
                                  capture_output=True, check=False)
            if result.returncode == 0:
                killed = True
                self.logger.debug(f"Killed {process_name} processes with pkill")
        except FileNotFoundError:
            pass
        
        # Method 2: killall
        if not killed:
            try:
                result = subprocess.run(['killall', process_name], 
                                      capture_output=True, check=False)
                if result.returncode == 0:
                    killed = True
                    self.logger.debug(f"Killed {process_name} processes with killall")
            except FileNotFoundError:
                pass
        
        # Method 3: ps + grep + kill
        if not killed:
            try:
                ps_result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
                if ps_result.returncode == 0:
                    lines = ps_result.stdout.split('\n')
                    for line in lines:
                        if process_name in line and 'grep' not in line and 'ps aux' not in line:
                            parts = line.split()
                            if len(parts) > 1:
                                pid = parts[1]
                                try:
                                    subprocess.run(['kill', '-9', pid], check=False)
                                    killed = True
                                    self.logger.debug(f"Killed {process_name} process {pid}")
                                except:
                                    pass
            except:
                pass
        
        return killed
    
    def check_geckodriver_compatibility(self):
        """Check GeckoDriver and Firefox compatibility"""
        try:
            # Check Firefox version
            firefox_result = subprocess.run(['firefox', '--version'], 
                                          capture_output=True, text=True, check=False)
            if firefox_result.returncode == 0:
                firefox_version = firefox_result.stdout.strip()
                self.logger.info(f"Firefox version: {firefox_version}")
            
            # Check GeckoDriver version
            geckodriver_result = subprocess.run(['geckodriver', '--version'], 
                                              capture_output=True, text=True, check=False)
            if geckodriver_result.returncode == 0:
                geckodriver_version = geckodriver_result.stdout.split('\n')[0]
                self.logger.info(f"GeckoDriver version: {geckodriver_version}")
                
                # Check for known compatibility issues
                if "0.33.0" in geckodriver_version and "140." in firefox_version:
                    self.logger.warning("GeckoDriver 0.33.0 may not be compatible with Firefox 140.x")
                    self.logger.warning("Consider updating to GeckoDriver 0.36.0")
            
            return True
        except Exception as e:
            self.logger.error(f"Error checking compatibility: {e}")
            return False
    
    def setup_display(self):
        """Setup virtual display with enhanced error handling"""
        try:
            # Kill existing Xvfb processes
            self.kill_processes('Xvfb')
            time.sleep(2)
            
            # Check if Xvfb is available
            try:
                subprocess.run(['which', 'Xvfb'], check=True, capture_output=True)
            except subprocess.CalledProcessError:
                self.logger.error("Xvfb not found. Please install: sudo apt install xvfb")
                return False
            
            # Start Xvfb with error handling
            try:
                self.xvfb_process = subprocess.Popen(
                    ['Xvfb', ':99', '-screen', '0', '1920x1080x24', '-ac', '+extension', 'GLX'],
                    stdout=subprocess.DEVNULL, 
                    stderr=subprocess.PIPE
                )
                time.sleep(3)
                
                # Check if process is still running
                if self.xvfb_process.poll() is not None:
                    stderr_output = self.xvfb_process.stderr.read().decode()
                    self.logger.error(f"Xvfb failed to start: {stderr_output}")
                    return False
                
            except Exception as e:
                self.logger.error(f"Failed to start Xvfb: {e}")
                return False
            
            os.environ['DISPLAY'] = ':99'
            self.logger.info("Virtual display started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to setup display: {e}")
            return False
    
    def setup_firefox(self):
        """Setup Firefox driver with enhanced options and error handling"""
        try:
            # Check compatibility first
            self.check_geckodriver_compatibility()
            
            if not self.setup_display():
                return False
            
            firefox_options = Options()
            
            # Basic headless options
            firefox_options.add_argument("--headless")
            firefox_options.add_argument("--no-sandbox")
            firefox_options.add_argument("--disable-dev-shm-usage")
            firefox_options.add_argument("--disable-gpu")
            firefox_options.add_argument("--width=1920")
            firefox_options.add_argument("--height=1080")
            
            # Additional stability options
            firefox_options.add_argument("--disable-extensions")
            firefox_options.add_argument("--disable-plugins")
            firefox_options.add_argument("--disable-images")
            firefox_options.add_argument("--disable-javascript")
            firefox_options.add_argument("--disable-flash")
            firefox_options.add_argument("--disable-java")
            
            # Enhanced anti-detection
            firefox_options.set_preference("general.useragent.override", 
                "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0")
            firefox_options.set_preference("dom.webdriver.enabled", False)
            firefox_options.set_preference("useAutomationExtension", False)
            firefox_options.set_preference("marionette.enabled", False)
            
            # Performance optimizations
            firefox_options.set_preference("browser.cache.disk.enable", False)
            firefox_options.set_preference("browser.cache.memory.enable", False)
            firefox_options.set_preference("browser.cache.offline.enable", False)
            firefox_options.set_preference("network.http.use-cache", False)
            firefox_options.set_preference("media.volume_scale", "0.0")
            firefox_options.set_preference("browser.privatebrowsing.autostart", True)
            
            # Disable images and CSS for faster loading
            firefox_options.set_preference("permissions.default.image", 2)
            firefox_options.set_preference("permissions.default.stylesheet", 2)
            
            # Timeout settings
            firefox_options.set_preference("dom.max_script_run_time", 30)
            firefox_options.set_preference("dom.max_chrome_script_run_time", 30)
            
            # Disable first-run and update checks
            firefox_options.set_preference("browser.startup.homepage_override.mstone", "ignore")
            firefox_options.set_preference("startup.homepage_welcome_url", "")
            firefox_options.set_preference("startup.homepage_welcome_url.additional", "")
            firefox_options.set_preference("browser.rights.3.shown", True)
            firefox_options.set_preference("datareporting.policy.dataSubmissionEnabled", False)
            firefox_options.set_preference("datareporting.healthreport.uploadEnabled", False)
            firefox_options.set_preference("toolkit.telemetry.enabled", False)
            
            # Set profile path
            profile_path = "/home/funpay/.mozilla/firefox/default"
            if os.path.exists(profile_path):
                firefox_options.add_argument(f"--profile={profile_path}")
            
            try:
                self.driver = webdriver.Firefox(options=firefox_options)
                self.driver.implicitly_wait(10)
                self.driver.set_page_load_timeout(30)
                
                self.logger.info("Firefox driver initialized successfully")
                return True
                
            except Exception as e:
                self.logger.error(f"Failed to initialize Firefox driver: {e}")
                
                # Try alternative approach with service
                try:
                    from selenium.webdriver.firefox.service import Service
                    service = Service(executable_path='/usr/local/bin/geckodriver')
                    self.driver = webdriver.Firefox(service=service, options=firefox_options)
                    self.driver.implicitly_wait(10)
                    self.driver.set_page_load_timeout(30)
                    self.logger.info("Firefox driver initialized with explicit service")
                    return True
                except Exception as e2:
                    self.logger.error(f"Alternative Firefox initialization also failed: {e2}")
                    return False
            
        except Exception as e:
            self.logger.error(f"Failed to setup Firefox: {e}")
            return False
    
    def login(self):
        """Enhanced login with better error handling"""
        try:
            username = self.config.get('username')
            password = self.config.get('password')
            
            self.logger.info("Attempting login to FunPay...")
            
            # Navigate to login page
            self.driver.get("https://funpay.com/en/account/login")
            
            wait = WebDriverWait(self.driver, 20)
            
            # Wait for page to load
            wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
            time.sleep(2)
            
            # Find and fill username
            try:
                username_field = wait.until(EC.presence_of_element_located((By.NAME, "login")))
                username_field.clear()
                username_field.send_keys(username)
                self.logger.info("Username entered")
            except TimeoutException:
                self.logger.error("Could not find username field")
                return False
            
            # Find and fill password
            try:
                password_field = self.driver.find_element(By.NAME, "password")
                password_field.clear()
                password_field.send_keys(password)
                self.logger.info("Password entered")
            except Exception as e:
                self.logger.error(f"Could not find password field: {e}")
                return False
            
            # Submit form
            try:
                login_button = self.driver.find_element(By.XPATH, "//button[@type='submit']")
                login_button.click()
                self.logger.info("Login form submitted")
            except Exception as e:
                self.logger.error(f"Could not find or click login button: {e}")
                return False
            
            # Wait for redirect
            time.sleep(5)
            
            # Check login success
            current_url = self.driver.current_url.lower()
            page_source = self.driver.page_source.lower()
            
            if "login" not in current_url:
                self.logger.info("Login successful!")
                return True
            elif "captcha" in page_source or "recaptcha" in page_source:
                self.logger.error("CAPTCHA detected - manual intervention required")
                return False
            elif "error" in page_source or "invalid" in page_source:
                self.logger.error("Login failed - check credentials")
                return False
            else:
                self.logger.warning("Login status unclear, continuing...")
                return True
                
        except Exception as e:
            self.logger.error(f"Login error: {e}")
            return False
    
    def check_boost_status(self):
        """Enhanced boost status checking"""
        try:
            target_url = self.config.get('target_url')
            self.logger.info(f"Checking boost status at: {target_url}")
            
            self.driver.get(target_url)
            
            wait = WebDriverWait(self.driver, 20)
            wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
            time.sleep(3)
            
            page_source = self.driver.page_source.lower()
            
            # Enhanced wait time detection
            wait_patterns = [
                r'please wait (\d+) hour',
                r'wait (\d+) hour',
                r'подождите (\d+) час',
                r'wait.*?(\d+).*?hour',
                r'(\d+).*?hour.*?wait'
            ]
            
            for pattern in wait_patterns:
                match = re.search(pattern, page_source)
                if match:
                    hours = int(match.group(1))
                    self.logger.info(f"Must wait {hours} hours before next boost")
                    return "wait", hours
            
            # Generic wait detection
            wait_keywords = ["please wait", "подождите", "wait", "cooldown", "timeout"]
            if any(keyword in page_source for keyword in wait_keywords):
                self.logger.info("Wait detected (assuming 3 hours)")
                return "wait", 3
            
            # Enhanced boost button detection
            boost_selectors = [
                "//button[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'boost')]",
                "//a[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'boost')]",
                "//button[contains(translate(text(), 'А��ВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ', 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'), 'поднять')]",
                "//a[contains(translate(text(), 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ', 'абвгд��ёжзийклмнопрстуфхцчшщъыьэюя'), 'поднять')]",
                "//*[contains(@class, 'boost')]",
                "//*[contains(@id, 'boost')]",
                "//input[@type='submit' and contains(@value, 'boost')]"
            ]
            
            for selector in boost_selectors:
                try:
                    elements = self.driver.find_elements(By.XPATH, selector)
                    for element in elements:
                        if element.is_displayed() and element.is_enabled():
                            self.logger.info("Boost button found and available!")
                            return "available", element
                except Exception as e:
                    self.logger.debug(f"Selector {selector} failed: {e}")
                    continue
            
            self.logger.info("No boost button found - status unclear")
            return "unknown", None
            
        except Exception as e:
            self.logger.error(f"Error checking boost status: {e}")
            return "error", None
    
    def click_boost(self, element):
        """Enhanced boost clicking with verification"""
        try:
            # Scroll to element
            self.driver.execute_script("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", element)
            time.sleep(2)
            
            # Highlight element for debugging
            self.driver.execute_script("arguments[0].style.border='3px solid red'", element)
            time.sleep(1)
            
            # Click element
            try:
                element.click()
                self.logger.info("Boost button clicked successfully!")
            except Exception:
                # Try JavaScript click as fallback
                self.driver.execute_script("arguments[0].click();", element)
                self.logger.info("Boost button clicked via JavaScript!")
            
            time.sleep(5)
            
            # Verify boost success
            page_source = self.driver.page_source.lower()
            success_keywords = ["boosted", "success", "поднят", "успешно", "completed"]
            
            if any(keyword in page_source for keyword in success_keywords):
                self.logger.info("SUCCESS: Offers boosted successfully!")
                success = True
            else:
                self.logger.info("Boost clicked - verification unclear")
                success = True  # Assume success if no error
            
            # Update configuration
            self.config['last_boost'] = datetime.now().isoformat()
            self.save_config()
            
            return success
            
        except Exception as e:
            self.logger.error(f"Error clicking boost button: {e}")
            return False
    
    def restart_driver(self):
        """Enhanced driver restart with cleanup"""
        try:
            self.logger.info("Restarting Firefox driver...")
            
            # Close current driver
            if self.driver:
                try:
                    self.driver.quit()
                except:
                    pass
            
            # Kill Xvfb process if we started it
            if self.xvfb_process:
                try:
                    self.xvfb_process.terminate()
                    self.xvfb_process.wait(timeout=5)
                except:
                    try:
                        self.xvfb_process.kill()
                    except:
                        pass
                self.xvfb_process = None
            
            # Kill all related processes
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            self.kill_processes('Xvfb')
            
            time.sleep(5)
            
            # Restart everything
            if self.setup_firefox() and self.login():
                self.logger.info("Driver restarted successfully")
                return True
            else:
                self.logger.error("Failed to restart driver")
                return False
                
        except Exception as e:
            self.logger.error(f"Error during driver restart: {e}")
            return False
    
    def run_daemon(self):
        """Enhanced main daemon loop"""
        self.logger.info("Starting FunPay Auto Boost Daemon")
        self.logger.info(f"Target URL: {self.config.get('target_url')}")
        self.logger.info(f"Boost Interval: {self.config.get('boost_interval', 3)} hours")
        self.logger.info(f"Username: {self.config.get('username')}")
        
        # Initial setup with retries
        max_setup_retries = 3
        for attempt in range(max_setup_retries):
            self.logger.info(f"Setup attempt {attempt + 1}/{max_setup_retries}")
            
            if self.setup_firefox():
                if self.login():
                    self.logger.info("Initial setup completed successfully")
                    break
                else:
                    self.logger.warning("Login failed, retrying setup...")
            else:
                self.logger.warning("Firefox setup failed, retrying...")
            
            if attempt < max_setup_retries - 1:
                self.logger.info("Waiting 30 seconds before retry...")
                time.sleep(30)
        else:
            self.logger.error("Failed to complete initial setup after all retries")
            return False
        
        self.logger.info("Boost monitoring started successfully")
        
        while True:
            try:
                status, data = self.check_boost_status()
                
                if status == "available":
                    if self.click_boost(data):
                        wait_hours = self.config.get('boost_interval', 3)
                        next_time = datetime.now() + timedelta(hours=wait_hours)
                        self.logger.info(f"Next boost scheduled: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                        self.consecutive_errors = 0
                        
                        # Sleep with periodic updates
                        for i in range(wait_hours):
                            time.sleep(3600)  # 1 hour
                            remaining = wait_hours - i - 1
                            if remaining > 0:
                                self.logger.info(f"⏰ {remaining} hours until next boost attempt")
                    else:
                        self.logger.warning("Boost click failed, retrying in 30 minutes")
                        time.sleep(1800)
                        
                elif status == "wait":
                    hours = data
                    next_time = datetime.now() + timedelta(hours=hours)
                    self.logger.info(f"Waiting period detected. Next check: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.consecutive_errors = 0
                    
                    # Sleep with periodic updates
                    for i in range(hours):
                        time.sleep(3600)  # 1 hour
                        remaining = hours - i - 1
                        if remaining > 0:
                            self.logger.info(f"⏳ {remaining} hours remaining in wait period")
                    
                else:
                    self.consecutive_errors += 1
                    self.logger.warning(f"Status unclear or error occurred (attempt {self.consecutive_errors}/{self.max_errors})")
                    
                    if self.consecutive_errors >= self.max_errors:
                        self.logger.warning("Too many consecutive errors, restarting driver...")
                        if self.restart_driver():
                            self.consecutive_errors = 0
                        else:
                            self.logger.error("Driver restart failed, waiting 1 hour before retry")
                            time.sleep(3600)
                    else:
                        self.logger.info("Retrying in 30 minutes...")
                        time.sleep(1800)
                
            except KeyboardInterrupt:
                self.logger.info("Daemon stopped by user")
                break
            except Exception as e:
                self.logger.error(f"Unexpected error in main loop: {e}")
                time.sleep(1800)  # Wait 30 minutes before retry
        
        return True
    
    def get_status(self):
        """Enhanced status display"""
        try:
            last_boost = self.config.get('last_boost')
            interval = self.config.get('boost_interval', 3)
            
            print("╔══════════════════════════════════════════════════════════════╗")
            print("║                    FunPay Auto Boost Status                 ║")
            print("╚═════��════════════════════════════════════════════════════════╝")
            print("")
            print(f"🎯 Target URL: {self.config.get('target_url')}")
            print(f"👤 Username: {self.config.get('username')}")
            print(f"⏰ Boost Interval: {interval} hours")
            print("")
            
            if last_boost:
                try:
                    last_time = datetime.fromisoformat(last_boost)
                    next_time = last_time + timedelta(hours=interval)
                    
                    print(f"📅 Last Boost: {last_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    print(f"📅 Next Boost: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    
                    now = datetime.now()
                    if next_time > now:
                        remaining = next_time - now
                        hours = int(remaining.total_seconds() // 3600)
                        minutes = int((remaining.total_seconds() % 3600) // 60)
                        print(f"⏳ Time Remaining: {hours}h {minutes}m")
                        print(f"🔄 Status: Waiting for next boost")
                    else:
                        print(f"✅ Status: Ready for boost!")
                        
                except Exception as e:
                    print(f"❌ Error parsing last boost time: {e}")
            else:
                print(f"📅 Last Boost: Never")
                print(f"🔄 Status: Ready for first boost")
            
            print("")
            
        except Exception as e:
            print(f"❌ Error displaying status: {e}")
    
    def cleanup(self):
        """Enhanced cleanup"""
        try:
            self.logger.info("Cleaning up resources...")
            
            if self.driver:
                try:
                    self.driver.quit()
                except:
                    pass
            
            # Kill Xvfb process if we started it
            if self.xvfb_process:
                try:
                    self.xvfb_process.terminate()
                    self.xvfb_process.wait(timeout=5)
                except:
                    try:
                        self.xvfb_process.kill()
                    except:
                        pass
            
            # Kill all related processes
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            self.kill_processes('Xvfb')
            
            self.logger.info("Cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Error during cleanup: {e}")

def signal_handler(signum, frame):
    logging.info(f"Received signal {signum}, shutting down gracefully...")
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    import argparse
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
        print("\n🛑 Daemon stopped by user")
    except Exception as e:
        print(f"❌ Fatal error: {e}")
    finally:
        booster.cleanup()

if __name__ == "__main__":
    main()
EOF

# Set permissions
chmod +x /opt/funpay-boost/funpay_boost.py
chown funpay:funpay /opt/funpay-boost/funpay_boost.py

echo -e "${GREEN}✅ Script updated successfully${NC}"
echo ""
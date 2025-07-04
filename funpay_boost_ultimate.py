#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Ultimate Version
نسخه نهایی با تمام مشکلات حل شده
"""

import os
import subprocess
import time
import json
import logging
import signal
import sys
from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, WebDriverException

class FunPayBooster:
    def __init__(self, config_file='/etc/funpay/config.json'):
        self.driver = None
        self.config_file = config_file
        self.config = {}
        self.xvfb_process = None
        self.display_num = 111
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
        
        # Load or create configuration
        self.load_or_create_config()
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        self.logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.cleanup()
        sys.exit(0)
    
    def load_or_create_config(self):
        """Load existing config or create new one"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r') as f:
                    self.config = json.load(f)
                self.logger.info("Configuration loaded successfully")
            else:
                self.logger.info("No configuration found, will create new one")
                self.config = {}
        except Exception as e:
            self.logger.error(f"Failed to load config: {e}")
            self.config = {}
    
    def save_config(self):
        """Save configuration to file"""
        try:
            os.makedirs(os.path.dirname(self.config_file), exist_ok=True)
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
            return True
        except Exception as e:
            self.logger.error(f"Failed to save config: {e}")
            return False
    
    def get_user_credentials(self):
        """Get user credentials interactively"""
        print("\n" + "="*60)
        print("🔐 FunPay Auto Boost - Initial Setup")
        print("="*60)
        
        username = input("📧 Enter your FunPay username/email: ").strip()
        
        import getpass
        password = getpass.getpass("🔒 Enter your FunPay password: ").strip()
        
        target_url = input("🔗 Enter your boost offers URL: ").strip()
        if not target_url.startswith('http'):
            target_url = f"https://funpay.com/en/lots/{target_url}/trade"
        
        try:
            interval = int(input("⏰ Enter boost interval in hours (default 3): ") or "3")
        except ValueError:
            interval = 3
        
        self.config.update({
            'username': username,
            'password': password,
            'target_url': target_url,
            'boost_interval': interval,
            'cookies': None,
            'last_boost': None,
            'created_at': datetime.now().isoformat()
        })
        
        self.save_config()
        print("✅ Configuration saved!")
        return True
    
    def get_cookies_from_user(self):
        """Get cookies from user when needed"""
        print("\n" + "="*60)
        print("🍪 Cookie Setup Required")
        print("="*60)
        print("Please provide the following cookies from your browser:")
        print("1. Login to FunPay in your browser")
        print("2. Press F12 > Application > Cookies > https://funpay.com")
        print("3. Find these cookies and provide their values:")
        print("")
        
        cookies = []
        
        # Get required cookies
        cookie_names = ['PHPSESSID', 'golden_key', 'fav_games']
        
        for cookie_name in cookie_names:
            while True:
                value = input(f"🍪 Enter {cookie_name} value: ").strip()
                if value:
                    cookies.append({
                        'name': cookie_name,
                        'value': value,
                        'domain': '.funpay.com',
                        'path': '/'
                    })
                    break
                else:
                    print("❌ Value cannot be empty!")
        
        self.config['cookies'] = cookies
        self.save_config()
        print("✅ Cookies saved!")
        return cookies
    
    def kill_processes(self, process_name):
        """Kill processes efficiently"""
        try:
            subprocess.run(['pkill', '-f', process_name], capture_output=True, check=False)
            time.sleep(1)
            return True
        except:
            return False
    
    def setup_display(self):
        """Setup virtual display with enhanced error handling"""
        try:
            # Kill existing processes
            self.kill_processes('Xvfb')
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            
            # Remove lock files
            subprocess.run(['rm', '-f', f'/tmp/.X{self.display_num}-lock'], capture_output=True)
            
            # Start Xvfb
            self.xvfb_process = subprocess.Popen(
                ['Xvfb', f':{self.display_num}', '-screen', '0', '1024x768x24', '-nolisten', 'tcp'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            time.sleep(3)
            
            # Check if Xvfb started
            if self.xvfb_process.poll() is not None:
                self.logger.error("Xvfb failed to start")
                return False
            
            os.environ['DISPLAY'] = f':{self.display_num}'
            self.logger.info("Virtual display started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to setup display: {e}")
            return False
    
    def setup_firefox(self):
        """Setup Firefox with all optimizations and fixes"""
        try:
            if not self.setup_display():
                return False
            
            # Firefox options with all fixes applied
            firefox_options = Options()
            
            # Basic headless options
            firefox_options.add_argument("--headless")
            firefox_options.add_argument("--no-sandbox")
            firefox_options.add_argument("--disable-dev-shm-usage")
            firefox_options.add_argument("--disable-gpu")
            firefox_options.add_argument("--single-process")
            firefox_options.add_argument("--disable-extensions")
            firefox_options.add_argument("--disable-plugins")
            
            # Anti-detection preferences
            firefox_options.set_preference("dom.webdriver.enabled", False)
            firefox_options.set_preference("useAutomationExtension", False)
            firefox_options.set_preference("marionette.enabled", False)
            firefox_options.set_preference("general.useragent.override", 
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0")
            
            # Performance optimizations
            firefox_options.set_preference("dom.ipc.processCount", 1)
            firefox_options.set_preference("security.sandbox.content.level", 0)
            firefox_options.set_preference("browser.cache.disk.enable", False)
            firefox_options.set_preference("browser.cache.memory.enable", False)
            firefox_options.set_preference("permissions.default.image", 2)
            firefox_options.set_preference("javascript.enabled", True)
            
            # Timeout settings
            firefox_options.set_preference("dom.max_script_run_time", 10)
            firefox_options.set_preference("network.http.connection-timeout", 15)
            firefox_options.set_preference("network.http.response.timeout", 15)
            
            # Disable unnecessary features
            firefox_options.set_preference("browser.startup.homepage_override.mstone", "ignore")
            firefox_options.set_preference("datareporting.policy.dataSubmissionEnabled", False)
            firefox_options.set_preference("toolkit.telemetry.enabled", False)
            firefox_options.set_preference("browser.crashReports.unsubmittedCheck.enabled", False)
            firefox_options.set_preference("app.update.enabled", False)
            
            # Create service
            service = Service(
                executable_path='/usr/local/bin/geckodriver',
                service_args=['--log', 'fatal']
            )
            
            # Start Firefox
            self.driver = webdriver.Firefox(service=service, options=firefox_options)
            self.driver.set_page_load_timeout(20)
            self.driver.implicitly_wait(5)
            
            # Hide webdriver property
            self.driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
            
            self.logger.info("Firefox driver initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to setup Firefox: {e}")
            return False
    
    def try_login_with_credentials(self):
        """Try to login with username/password"""
        try:
            self.logger.info("Attempting login with credentials...")
            
            # Navigate to login page
            self.driver.get("https://funpay.com/en/account/login")
            time.sleep(3)
            
            # Check for CAPTCHA
            page_source = self.driver.page_source.lower()
            if "captcha" in page_source or "recaptcha" in page_source:
                self.logger.warning("CAPTCHA detected on login page")
                return False
            
            # Fill login form
            wait = WebDriverWait(self.driver, 10)
            
            username_field = wait.until(EC.presence_of_element_located((By.NAME, "login")))
            username_field.clear()
            username_field.send_keys(self.config['username'])
            
            password_field = self.driver.find_element(By.NAME, "password")
            password_field.clear()
            password_field.send_keys(self.config['password'])
            
            # Submit form
            login_button = self.driver.find_element(By.XPATH, "//button[@type='submit']")
            login_button.click()
            
            time.sleep(5)
            
            # Check login success
            if "login" not in self.driver.current_url.lower():
                self.logger.info("✅ Login successful with credentials!")
                return True
            else:
                page_source = self.driver.page_source.lower()
                if "captcha" in page_source:
                    self.logger.warning("CAPTCHA appeared after login attempt")
                else:
                    self.logger.warning("Login failed - credentials may be incorrect")
                return False
                
        except Exception as e:
            self.logger.error(f"Login with credentials failed: {e}")
            return False
    
    def add_cookies(self, cookies):
        """Add cookies to browser session"""
        try:
            self.logger.info("Adding cookies to session...")
            
            # Visit domain first
            self.driver.get("https://funpay.com")
            time.sleep(2)
            
            # Clear existing cookies
            self.driver.delete_all_cookies()
            time.sleep(1)
            
            # Add our cookies
            for cookie in cookies:
                try:
                    self.driver.add_cookie(cookie)
                    self.logger.info(f"✅ Added cookie: {cookie['name']}")
                except Exception as e:
                    self.logger.warning(f"❌ Failed to add cookie {cookie['name']}: {e}")
            
            # Refresh to apply cookies
            self.driver.refresh()
            time.sleep(3)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to add cookies: {e}")
            return False
    
    def test_access(self):
        """Test access to boost page"""
        try:
            self.logger.info("Testing access to boost page...")
            
            self.driver.get(self.config['target_url'])
            time.sleep(5)
            
            current_url = self.driver.current_url
            
            if "login" in current_url.lower():
                self.logger.warning("Redirected to login page - authentication failed")
                return False
            
            self.logger.info("✅ Successfully accessed boost page!")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to test access: {e}")
            return False
    
    def setup_authentication(self):
        """Setup authentication - try credentials first, then cookies"""
        self.logger.info("Setting up authentication...")
        
        # First try with credentials
        if self.try_login_with_credentials():
            if self.test_access():
                self.logger.info("✅ Authentication successful with credentials!")
                return True
        
        # If credentials failed, try existing cookies
        if self.config.get('cookies'):
            self.logger.info("Trying with existing cookies...")
            if self.add_cookies(self.config['cookies']):
                if self.test_access():
                    self.logger.info("✅ Authentication successful with existing cookies!")
                    return True
        
        # If both failed, request new cookies
        self.logger.info("Authentication failed, requesting new cookies...")
        cookies = self.get_cookies_from_user()
        
        if self.add_cookies(cookies):
            if self.test_access():
                self.logger.info("✅ Authentication successful with new cookies!")
                return True
        
        self.logger.error("❌ All authentication methods failed!")
        return False
    
    def find_boost_button(self):
        """Find boost button with multiple methods"""
        selectors = [
            "//button[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'boost')]",
            "//a[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'boost')]",
            "//button[contains(translate(text(), 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ', 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'), 'поднять')]",
            "//a[contains(translate(text(), 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ', 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'), 'поднять')]",
            "//*[contains(@class, 'boost')]",
            "//*[contains(@id, 'boost')]"
        ]
        
        for selector in selectors:
            try:
                elements = self.driver.find_elements(By.XPATH, selector)
                for element in elements:
                    if element.is_displayed() and element.is_enabled():
                        return element
            except:
                continue
        
        return None
    
    def check_boost_status(self):
        """Check boost status and perform boost if available"""
        try:
            self.logger.info("Checking boost status...")
            
            # Navigate to boost page
            self.driver.get(self.config['target_url'])
            time.sleep(5)
            
            # Check if redirected to login
            if "login" in self.driver.current_url.lower():
                self.logger.warning("Redirected to login - cookies may have expired")
                return "auth_failed"
            
            # Look for boost button
            boost_button = self.find_boost_button()
            
            if boost_button:
                self.logger.info("🎯 Boost button found!")
                
                # Click boost button
                try:
                    self.driver.execute_script("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", boost_button)
                    time.sleep(1)
                    boost_button.click()
                    self.logger.info("🎉 Boost button clicked!")
                    
                    time.sleep(5)
                    
                    # Update last boost time
                    self.config['last_boost'] = datetime.now().isoformat()
                    self.save_config()
                    
                    return "success"
                    
                except Exception as e:
                    self.logger.error(f"Failed to click boost button: {e}")
                    return "click_failed"
            else:
                # Check for wait message
                page_source = self.driver.page_source.lower()
                if "wait" in page_source or "подожд" in page_source:
                    self.logger.info("⏳ Must wait before next boost")
                    return "wait"
                else:
                    self.logger.info("❌ No boost button found")
                    return "no_button"
            
        except Exception as e:
            self.logger.error(f"Error checking boost status: {e}")
            return "error"
    
    def handle_auth_failure(self):
        """Handle authentication failure by requesting new cookies"""
        self.logger.warning("Authentication failed, requesting new cookies...")
        
        try:
            cookies = self.get_cookies_from_user()
            if self.add_cookies(cookies):
                if self.test_access():
                    self.logger.info("✅ Re-authentication successful!")
                    return True
        except KeyboardInterrupt:
            self.logger.info("Cookie update cancelled by user")
            return False
        except Exception as e:
            self.logger.error(f"Re-authentication failed: {e}")
        
        return False
    
    def run_daemon(self):
        """Main daemon loop"""
        self.logger.info("🚀 Starting FunPay Auto Boost Ultimate")
        self.logger.info(f"🎯 Target URL: {self.config.get('target_url', 'Not set')}")
        self.logger.info(f"👤 Username: {self.config.get('username', 'Not set')}")
        self.logger.info(f"⏰ Boost Interval: {self.config.get('boost_interval', 3)} hours")
        
        # Check if we have required configuration
        if not all(key in self.config for key in ['username', 'password', 'target_url']):
            self.logger.info("Missing configuration, starting setup...")
            if not self.get_user_credentials():
                self.logger.error("Failed to get user credentials")
                return False
        
        # Setup Firefox
        if not self.setup_firefox():
            self.logger.error("Failed to setup Firefox")
            return False
        
        # Setup authentication
        if not self.setup_authentication():
            self.logger.error("Failed to setup authentication")
            return False
        
        self.logger.info("✅ Boost monitoring started successfully!")
        
        # Main monitoring loop
        while True:
            try:
                result = self.check_boost_status()
                
                if result == "success":
                    wait_hours = self.config.get('boost_interval', 3)
                    next_time = datetime.now() + timedelta(hours=wait_hours)
                    self.logger.info(f"✅ Boost successful! Next boost at: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.consecutive_errors = 0
                    
                    # Sleep with periodic status updates
                    for i in range(wait_hours):
                        time.sleep(3600)  # 1 hour
                        remaining = wait_hours - i - 1
                        if remaining > 0:
                            self.logger.info(f"⏰ {remaining} hours until next boost attempt")
                
                elif result == "auth_failed":
                    if self.handle_auth_failure():
                        continue  # Try again immediately
                    else:
                        self.logger.error("Re-authentication failed, waiting 1 hour...")
                        time.sleep(3600)
                
                elif result == "wait":
                    self.logger.info("⏳ Waiting 1 hour before next check...")
                    time.sleep(3600)
                
                else:
                    self.consecutive_errors += 1
                    if self.consecutive_errors >= self.max_errors:
                        self.logger.warning("Too many consecutive errors, restarting Firefox...")
                        self.restart_firefox()
                        self.consecutive_errors = 0
                    else:
                        self.logger.info(f"⏰ No action needed, checking again in 30 minutes... (error {self.consecutive_errors}/{self.max_errors})")
                        time.sleep(1800)
                
            except KeyboardInterrupt:
                self.logger.info("🛑 Daemon stopped by user")
                break
            except Exception as e:
                self.logger.error(f"Unexpected error in main loop: {e}")
                time.sleep(1800)
        
        return True
    
    def restart_firefox(self):
        """Restart Firefox driver"""
        try:
            self.logger.info("Restarting Firefox...")
            self.cleanup()
            time.sleep(5)
            
            if self.setup_firefox():
                if self.setup_authentication():
                    self.logger.info("✅ Firefox restarted successfully")
                    return True
            
            self.logger.error("❌ Failed to restart Firefox")
            return False
            
        except Exception as e:
            self.logger.error(f"Error restarting Firefox: {e}")
            return False
    
    def get_status(self):
        """Get current status"""
        last_boost = self.config.get('last_boost')
        interval = self.config.get('boost_interval', 3)
        
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║                 FunPay Auto Boost Ultimate                  ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print("")
        print(f"🎯 Target URL: {self.config.get('target_url', 'Not configured')}")
        print(f"👤 Username: {self.config.get('username', 'Not configured')}")
        print(f"⏰ Boost Interval: {interval} hours")
        print(f"🍪 Cookies: {'Configured' if self.config.get('cookies') else 'Not configured'}")
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
                print(f"📅 Last Boost: {last_boost}")
                print(f"❌ Error parsing time: {e}")
        else:
            print(f"📅 Last Boost: Never")
            print(f"🔄 Status: Ready for first boost")
        
        print("")
    
    def cleanup(self):
        """Clean up resources"""
        try:
            self.logger.info("Cleaning up resources...")
            
            if self.driver:
                try:
                    self.driver.quit()
                except:
                    pass
                self.driver = None
            
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
            
            # Kill remaining processes
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            self.kill_processes('Xvfb')
            
            self.logger.info("Cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Error during cleanup: {e}")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='FunPay Auto Boost Ultimate')
    parser.add_argument('--daemon', action='store_true', help='Run as daemon')
    parser.add_argument('--status', action='store_true', help='Show status')
    parser.add_argument('--setup', action='store_true', help='Run initial setup')
    parser.add_argument('--test', action='store_true', help='Test boost once')
    args = parser.parse_args()
    
    booster = FunPayBooster()
    
    try:
        if args.status:
            booster.get_status()
        elif args.setup:
            booster.get_user_credentials()
        elif args.test:
            if booster.setup_firefox():
                if booster.setup_authentication():
                    result = booster.check_boost_status()
                    print(f"Test result: {result}")
                booster.cleanup()
        else:
            booster.run_daemon()
    except KeyboardInterrupt:
        print("\n🛑 Stopped by user")
    except Exception as e:
        print(f"❌ Fatal error: {e}")
    finally:
        booster.cleanup()

if __name__ == "__main__":
    main()
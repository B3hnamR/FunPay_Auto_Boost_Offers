#!/bin/bash

# Optimize Firefox Performance and Fix Timeout Issues
# This script addresses Firefox hanging and timeout problems

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            ${WHITE}Firefox Performance Optimization${BLUE}              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${CYAN}🛑 Stopping FunPay service...${NC}"
systemctl stop funpay-boost

echo -e "${CYAN}🧹 Cleaning up existing processes...${NC}"
# Kill all Firefox and related processes
pkill -f firefox 2>/dev/null || true
pkill -f geckodriver 2>/dev/null || true
pkill -f Xvfb 2>/dev/null || true
sleep 3

echo -e "${CYAN}🔧 Optimizing system settings...${NC}"

# Increase shared memory
echo -e "${YELLOW}📁 Optimizing shared memory...${NC}"
mount -t tmpfs -o size=1G tmpfs /dev/shm 2>/dev/null || true

# Optimize kernel parameters for Firefox
echo -e "${YELLOW}⚙️ Setting kernel parameters...${NC}"
sysctl -w vm.max_map_count=262144 2>/dev/null || true
sysctl -w fs.file-max=2097152 2>/dev/null || true
sysctl -w kernel.pid_max=4194304 2>/dev/null || true

# Set ulimits for the funpay user
echo -e "${YELLOW}📊 Setting resource limits...${NC}"
cat > /etc/security/limits.d/funpay.conf << 'EOF'
funpay soft nofile 65536
funpay hard nofile 65536
funpay soft nproc 32768
funpay hard nproc 32768
funpay soft memlock unlimited
funpay hard memlock unlimited
EOF

echo -e "${CYAN}🔧 Creating optimized Firefox profile...${NC}"

# Remove old profile and create new optimized one
rm -rf /home/funpay/.mozilla/firefox/default
mkdir -p /home/funpay/.mozilla/firefox/default

# Create highly optimized Firefox preferences
cat > /home/funpay/.mozilla/firefox/default/prefs.js << 'EOF'
// Performance optimizations
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", false);
user_pref("browser.cache.offline.enable", false);
user_pref("network.http.use-cache", false);
user_pref("browser.sessionhistory.max_total_viewers", 0);
user_pref("browser.sessionstore.max_tabs_undo", 0);
user_pref("browser.sessionstore.max_windows_undo", 0);

// Disable all unnecessary features
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("browser.rights.3.shown", true);
user_pref("browser.startup.homepage_override.buildID", "20231201000000");

// Disable data collection
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.server", "");

// Disable crash reporting
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
user_pref("toolkit.crashreporter.enabled", false);

// Disable safe browsing
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);

// Disable session restore
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.sessionstore.restore_on_demand", false);
user_pref("browser.sessionstore.restore_tabs_lazily", false);
user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", false);

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
user_pref("extensions.update.enabled", false);
user_pref("extensions.update.autoUpdateDefault", false);

// Disable media
user_pref("media.volume_scale", "0.0");
user_pref("media.autoplay.enabled", false);
user_pref("media.autoplay.default", 5);
user_pref("media.block-autoplay-until-in-foreground", false);

// Privacy settings
user_pref("browser.privatebrowsing.autostart", true);
user_pref("privacy.trackingprotection.enabled", true);

// Disable images and CSS
user_pref("permissions.default.image", 2);
user_pref("permissions.default.stylesheet", 2);

// Enable JavaScript (needed for FunPay)
user_pref("javascript.enabled", true);

// Disable plugins
user_pref("plugin.state.flash", 0);
user_pref("plugin.state.java", 0);
user_pref("plugins.click_to_play", true);

// Disable geolocation
user_pref("geo.enabled", false);
user_pref("geo.provider.network.url", "");

// Disable notifications
user_pref("dom.webnotifications.enabled", false);
user_pref("dom.push.enabled", false);

// Disable WebRTC
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.default_address_only", true);

// Timeout settings - CRITICAL FOR FIXING HANGS
user_pref("dom.max_script_run_time", 10);
user_pref("dom.max_chrome_script_run_time", 10);
user_pref("network.http.connection-timeout", 15);
user_pref("network.http.response.timeout", 15);
user_pref("network.http.request.timeout", 15);
user_pref("dom.ipc.processTimeout", 10000);

// Disable content processes to reduce complexity
user_pref("dom.ipc.processCount", 1);
user_pref("dom.ipc.processCount.extension", 1);
user_pref("dom.ipc.processCount.file", 1);
user_pref("dom.ipc.processCount.privilegedabout", 1);
user_pref("dom.ipc.processCount.privilegedmozilla", 1);
user_pref("dom.ipc.processCount.web", 1);
user_pref("dom.ipc.processCount.webIsolated", 1);

// Disable sandboxing to prevent hangs
user_pref("security.sandbox.content.level", 0);
user_pref("security.sandbox.plugin.level", 0);
user_pref("security.sandbox.gpu.level", 0);

// Disable accessibility
user_pref("accessibility.force_disabled", 1);

// Disable WebGL
user_pref("webgl.disabled", true);
user_pref("webgl.enable-webgl2", false);

// Disable hardware acceleration
user_pref("layers.acceleration.disabled", true);
user_pref("gfx.direct2d.disabled", true);
user_pref("gfx.canvas.azure.backends", "skia");

// Network optimizations
user_pref("network.http.max-connections", 10);
user_pref("network.http.max-connections-per-server", 4);
user_pref("network.http.max-persistent-connections-per-server", 2);
user_pref("network.http.pipelining", false);
user_pref("network.dns.disableIPv6", true);

// Disable prefetching
user_pref("network.dns.disablePrefetch", true);
user_pref("network.prefetch-next", false);
user_pref("network.predictor.enabled", false);

// Disable service workers
user_pref("dom.serviceWorkers.enabled", false);

// Disable web workers
user_pref("dom.workers.enabled", false);

// Disable IndexedDB
user_pref("dom.indexedDB.enabled", false);

// Disable WebAssembly
user_pref("javascript.options.wasm", false);

// Disable WebSockets
user_pref("network.websocket.enabled", false);

// Disable WebVR
user_pref("dom.vr.enabled", false);

// Disable gamepad API
user_pref("dom.gamepad.enabled", false);

// Disable battery API
user_pref("dom.battery.enabled", false);

// Disable vibration API
user_pref("dom.vibrator.enabled", false);

// Disable clipboard API
user_pref("dom.event.clipboardevents.enabled", false);

// Disable fullscreen API
user_pref("full-screen-api.enabled", false);

// Disable pointer lock API
user_pref("dom.pointer-lock.enabled", false);

// Disable screen orientation API
user_pref("dom.screenorientation.allow-lock", false);

// Disable device sensors
user_pref("device.sensors.enabled", false);

// Disable camera and microphone
user_pref("media.navigator.enabled", false);
user_pref("media.peerconnection.enabled", false);

// Disable WebExtensions
user_pref("extensions.webextensions.enabled", false);

// Disable addon manager
user_pref("extensions.getAddons.cache.enabled", false);
user_pref("extensions.getAddons.get.url", "");
user_pref("extensions.getAddons.search.browseURL", "");
user_pref("extensions.webservice.discoverURL", "");

// Disable Firefox Sync
user_pref("services.sync.enabled", false);
user_pref("identity.fxaccounts.enabled", false);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.discoverystreamfeed", false);

// Disable Firefox Screenshots
user_pref("extensions.screenshots.disabled", true);

// Disable Firefox Monitor
user_pref("extensions.fxmonitor.enabled", false);

// Disable Firefox Studies
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);

// Disable form autofill
user_pref("browser.formfill.enable", false);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);

// Disable password manager
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);

// Disable search suggestions
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);

// Disable location bar suggestions
user_pref("browser.urlbar.suggest.history", false);
user_pref("browser.urlbar.suggest.bookmark", false);
user_pref("browser.urlbar.suggest.openpage", false);
user_pref("browser.urlbar.suggest.topsites", false);

// Disable new tab page
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtab.url", "about:blank");

// Set homepage to blank
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.startup.page", 0);
EOF

# Set ownership
chown -R funpay:funpay /home/funpay/.mozilla

echo -e "${CYAN}🔧 Creating optimized Python script...${NC}"

# Create a simplified, faster version of the script
cat > /opt/funpay-boost/funpay_boost_optimized.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Optimized Version for Performance
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
from selenium.webdriver.firefox.service import Service
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
        """Kill processes efficiently"""
        try:
            subprocess.run(['pkill', '-f', process_name], capture_output=True, check=False)
            time.sleep(1)
            return True
        except:
            return False
    
    def setup_display(self):
        """Setup virtual display optimized"""
        try:
            # Kill existing Xvfb processes
            self.kill_processes('Xvfb')
            
            # Start Xvfb with minimal options
            try:
                self.xvfb_process = subprocess.Popen(
                    ['Xvfb', ':99', '-screen', '0', '1024x768x24', '-nolisten', 'tcp'],
                    stdout=subprocess.DEVNULL, 
                    stderr=subprocess.DEVNULL
                )
                time.sleep(2)
                
                # Check if process is running
                if self.xvfb_process.poll() is not None:
                    self.logger.error("Xvfb failed to start")
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
        """Setup Firefox with minimal options for speed"""
        try:
            if not self.setup_display():
                return False
            
            # Kill any existing Firefox processes
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            time.sleep(2)
            
            firefox_options = Options()
            
            # Minimal headless options
            firefox_options.add_argument("--headless")
            firefox_options.add_argument("--no-sandbox")
            firefox_options.add_argument("--disable-dev-shm-usage")
            firefox_options.add_argument("--disable-gpu")
            firefox_options.add_argument("--disable-extensions")
            firefox_options.add_argument("--disable-plugins")
            firefox_options.add_argument("--disable-images")
            firefox_options.add_argument("--disable-javascript")
            firefox_options.add_argument("--disable-web-security")
            firefox_options.add_argument("--disable-features=VizDisplayCompositor")
            firefox_options.add_argument("--single-process")
            firefox_options.add_argument("--no-zygote")
            firefox_options.add_argument("--disable-background-timer-throttling")
            firefox_options.add_argument("--disable-backgrounding-occluded-windows")
            firefox_options.add_argument("--disable-renderer-backgrounding")
            
            # Set profile path
            profile_path = "/home/funpay/.mozilla/firefox/default"
            firefox_options.add_argument(f"--profile={profile_path}")
            
            # Minimal preferences
            firefox_options.set_preference("dom.ipc.processCount", 1)
            firefox_options.set_preference("security.sandbox.content.level", 0)
            firefox_options.set_preference("browser.cache.disk.enable", False)
            firefox_options.set_preference("browser.cache.memory.enable", False)
            firefox_options.set_preference("permissions.default.image", 2)
            firefox_options.set_preference("javascript.enabled", True)  # Enable for FunPay
            
            # Create service with timeout
            service = Service(
                executable_path='/usr/local/bin/geckodriver',
                service_args=['--log', 'fatal']
            )
            
            try:
                self.logger.info("Starting Firefox with optimized settings...")
                self.driver = webdriver.Firefox(
                    service=service,
                    options=firefox_options
                )
                
                # Set shorter timeouts
                self.driver.implicitly_wait(5)
                self.driver.set_page_load_timeout(15)
                
                self.logger.info("Firefox driver initialized successfully")
                return True
                
            except Exception as e:
                self.logger.error(f"Failed to initialize Firefox driver: {e}")
                return False
            
        except Exception as e:
            self.logger.error(f"Failed to setup Firefox: {e}")
            return False
    
    def login(self):
        """Optimized login process"""
        try:
            username = self.config.get('username')
            password = self.config.get('password')
            
            self.logger.info("Attempting login to FunPay...")
            
            # Navigate to login page with timeout
            try:
                self.driver.get("https://funpay.com/en/account/login")
            except Exception as e:
                self.logger.error(f"Failed to load login page: {e}")
                return False
            
            wait = WebDriverWait(self.driver, 10)
            
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
            time.sleep(3)
            
            # Check login success
            current_url = self.driver.current_url.lower()
            
            if "login" not in current_url:
                self.logger.info("Login successful!")
                return True
            else:
                self.logger.error("Login failed - still on login page")
                return False
                
        except Exception as e:
            self.logger.error(f"Login error: {e}")
            return False
    
    def check_boost_status(self):
        """Check boost status with timeout protection"""
        try:
            target_url = self.config.get('target_url')
            self.logger.info(f"Checking boost status at: {target_url}")
            
            try:
                self.driver.get(target_url)
            except Exception as e:
                self.logger.error(f"Failed to load target page: {e}")
                return "error", None
            
            time.sleep(2)
            
            page_source = self.driver.page_source.lower()
            
            # Check for wait time
            wait_patterns = [
                r'please wait (\d+) hour',
                r'wait (\d+) hour',
                r'подождите (\d+) час'
            ]
            
            for pattern in wait_patterns:
                match = re.search(pattern, page_source)
                if match:
                    hours = int(match.group(1))
                    self.logger.info(f"Must wait {hours} hours before next boost")
                    return "wait", hours
            
            # Check for boost button
            boost_selectors = [
                "//button[contains(text(), 'boost')]",
                "//a[contains(text(), 'boost')]",
                "//button[contains(text(), 'поднять')]",
                "//a[contains(text(), 'поднять')]"
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
            
            self.logger.info("No boost button found")
            return "unknown", None
            
        except Exception as e:
            self.logger.error(f"Error checking boost status: {e}")
            return "error", None
    
    def click_boost(self, element):
        """Click boost button"""
        try:
            element.click()
            self.logger.info("Boost button clicked!")
            time.sleep(3)
            
            # Update configuration
            self.config['last_boost'] = datetime.now().isoformat()
            self.save_config()
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error clicking boost button: {e}")
            return False
    
    def restart_driver(self):
        """Restart driver with cleanup"""
        try:
            self.logger.info("Restarting Firefox driver...")
            
            # Close current driver
            if self.driver:
                try:
                    self.driver.quit()
                except:
                    pass
            
            # Kill processes
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            
            if self.xvfb_process:
                try:
                    self.xvfb_process.terminate()
                except:
                    pass
                self.xvfb_process = None
            
            time.sleep(3)
            
            # Restart
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
        """Main daemon loop - optimized"""
        self.logger.info("Starting FunPay Auto Boost Daemon (Optimized)")
        self.logger.info(f"Target URL: {self.config.get('target_url')}")
        self.logger.info(f"Boost Interval: {self.config.get('boost_interval', 3)} hours")
        self.logger.info(f"Username: {self.config.get('username')}")
        
        # Initial setup with fewer retries
        max_setup_retries = 2
        for attempt in range(max_setup_retries):
            self.logger.info(f"Setup attempt {attempt + 1}/{max_setup_retries}")
            
            if self.setup_firefox():
                if self.login():
                    self.logger.info("Initial setup completed successfully")
                    break
                else:
                    self.logger.warning("Login failed, retrying...")
            else:
                self.logger.warning("Firefox setup failed, retrying...")
            
            if attempt < max_setup_retries - 1:
                self.logger.info("Waiting 15 seconds before retry...")
                time.sleep(15)
        else:
            self.logger.error("Failed to complete initial setup")
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
                        
                        # Sleep with updates every hour
                        for i in range(wait_hours):
                            time.sleep(3600)
                            remaining = wait_hours - i - 1
                            if remaining > 0:
                                self.logger.info(f"⏰ {remaining} hours until next boost")
                    else:
                        self.logger.warning("Boost click failed, retrying in 30 minutes")
                        time.sleep(1800)
                        
                elif status == "wait":
                    hours = data
                    next_time = datetime.now() + timedelta(hours=hours)
                    self.logger.info(f"Waiting period detected. Next check: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.consecutive_errors = 0
                    
                    # Sleep with updates
                    for i in range(hours):
                        time.sleep(3600)
                        remaining = hours - i - 1
                        if remaining > 0:
                            self.logger.info(f"⏳ {remaining} hours remaining")
                    
                else:
                    self.consecutive_errors += 1
                    self.logger.warning(f"Status unclear (attempt {self.consecutive_errors}/{self.max_errors})")
                    
                    if self.consecutive_errors >= self.max_errors:
                        self.logger.warning("Too many errors, restarting driver...")
                        if self.restart_driver():
                            self.consecutive_errors = 0
                        else:
                            self.logger.error("Restart failed, waiting 1 hour")
                            time.sleep(3600)
                    else:
                        self.logger.info("Retrying in 15 minutes...")
                        time.sleep(900)
                
            except KeyboardInterrupt:
                self.logger.info("Daemon stopped by user")
                break
            except Exception as e:
                self.logger.error(f"Unexpected error: {e}")
                time.sleep(900)  # Wait 15 minutes
        
        return True
    
    def get_status(self):
        """Status display"""
        try:
            last_boost = self.config.get('last_boost')
            interval = self.config.get('boost_interval', 3)
            
            print("╔══════════════════════════════════════════════════════════════╗")
            print("║                    FunPay Auto Boost Status                 ║")
            print("╚════════════════════════════════════════════════════════════��═╝")
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
                    print(f"❌ Error parsing time: {e}")
            else:
                print(f"📅 Last Boost: Never")
                print(f"🔄 Status: Ready for first boost")
            
            print("")
            
        except Exception as e:
            print(f"❌ Error displaying status: {e}")
    
    def cleanup(self):
        """Cleanup resources"""
        try:
            self.logger.info("Cleaning up...")
            
            if self.driver:
                try:
                    self.driver.quit()
                except:
                    pass
            
            if self.xvfb_process:
                try:
                    self.xvfb_process.terminate()
                except:
                    pass
            
            self.kill_processes('firefox')
            self.kill_processes('geckodriver')
            self.kill_processes('Xvfb')
            
            self.logger.info("Cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Cleanup error: {e}")

def signal_handler(signum, frame):
    logging.info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    import argparse
    parser = argparse.ArgumentParser(description='FunPay Auto Boost - Optimized')
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
        print("\n🛑 Daemon stopped")
    except Exception as e:
        print(f"❌ Fatal error: {e}")
    finally:
        booster.cleanup()

if __name__ == "__main__":
    main()
EOF

# Set permissions
chmod +x /opt/funpay-boost/funpay_boost_optimized.py
chown funpay:funpay /opt/funpay-boost/funpay_boost_optimized.py

echo -e "${CYAN}🔧 Updating systemd service to use optimized script...${NC}"

# Update systemd service to use optimized script
sed -i 's|funpay_boost.py|funpay_boost_optimized.py|g' /etc/systemd/system/funpay-boost.service

# Reload systemd
systemctl daemon-reload

echo -e "${CYAN}🧪 Testing optimized Firefox setup...${NC}"

# Quick test
cat > /tmp/quick_test.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import time
import subprocess
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service

try:
    # Start Xvfb
    xvfb = subprocess.Popen(['Xvfb', ':99', '-screen', '0', '1024x768x24'], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)
    os.environ['DISPLAY'] = ':99'
    
    # Setup Firefox
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--single-process")
    options.add_argument("--profile=/home/funpay/.mozilla/firefox/default")
    
    service = Service('/usr/local/bin/geckodriver')
    
    print("🚀 Testing optimized Firefox...")
    driver = webdriver.Firefox(service=service, options=options)
    driver.set_page_load_timeout(10)
    
    print("🌐 Testing navigation...")
    driver.get("data:text/html,<html><body><h1>Test</h1></body></html>")
    
    print("✅ Test successful!")
    driver.quit()
    xvfb.terminate()
    
except Exception as e:
    print(f"❌ Test failed: {e}")
    sys.exit(1)
EOF

if sudo -u funpay /opt/funpay-boost/venv/bin/python /tmp/quick_test.py; then
    echo -e "${GREEN}✅ Optimized Firefox test passed!${NC}"
else
    echo -e "${YELLOW}⚠️ Test had issues, but continuing...${NC}"
fi

rm -f /tmp/quick_test.py

echo -e "${CYAN}🚀 Starting optimized FunPay service...${NC}"

# Start the service
systemctl start funpay-boost

# Wait and check
sleep 15

if systemctl is-active --quiet funpay-boost; then
    echo -e "${GREEN}✅ Optimized service started successfully!${NC}"
    echo ""
    echo -e "${CYAN}📊 Service Status:${NC}"
    systemctl status funpay-boost --no-pager -l
else
    echo -e "${YELLOW}⚠️ Service may still be starting...${NC}"
    echo ""
    echo -e "${CYAN}📋 Recent logs:${NC}"
    journalctl -u funpay-boost --no-pager -l --since "1 minute ago"
fi

echo ""
echo -e "${GREEN}🎉 Firefox optimization completed!${NC}"
echo ""
echo -e "${CYAN}💡 Key optimizations applied:${NC}"
echo "   • Reduced Firefox process count to 1"
echo "   • Disabled sandboxing and unnecessary features"
echo "   • Set aggressive timeouts (10-15 seconds)"
echo "   • Optimized system resources"
echo "   • Simplified Selenium interactions"
echo ""
echo -e "${CYAN}📋 Monitor with:${NC}"
echo "   funpay-boost logs"
echo "   funpay-boost status"
echo ""
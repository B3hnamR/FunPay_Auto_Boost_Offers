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
import random
import hashlib
import base64
from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, WebDriverException
from selenium.webdriver.common.action_chains import ActionChains

class RateLimiter:
    """Advanced Rate Limiting with adaptive delays"""
    
    def __init__(self):
        self.request_history = []
        self.base_delay = 2.0
        self.max_delay = 30.0
        self.burst_threshold = 3
        self.cooldown_period = 300  # 5 minutes
        self.adaptive_factor = 1.0
        
    def wait_if_needed(self, action_type="general"):
        """Apply intelligent rate limiting based on recent activity"""
        now = time.time()
        
        # Clean old entries
        self.request_history = [t for t in self.request_history if now - t < self.cooldown_period]
        
        # Calculate adaptive delay
        recent_requests = len(self.request_history)
        
        if recent_requests >= self.burst_threshold:
            # Exponential backoff for burst protection
            delay = min(self.base_delay * (2 ** (recent_requests - self.burst_threshold)), self.max_delay)
            delay *= self.adaptive_factor
            
            # Add randomization to avoid detection patterns
            jitter = random.uniform(0.5, 1.5)
            final_delay = delay * jitter
            
            logging.info(f"Rate limiting: waiting {final_delay:.2f}s (recent requests: {recent_requests})")
            time.sleep(final_delay)
            
            # Increase adaptive factor if we're hitting limits frequently
            self.adaptive_factor = min(self.adaptive_factor * 1.1, 3.0)
        else:
            # Normal operation - small random delay
            delay = random.uniform(1.0, 3.0)
            time.sleep(delay)
            
            # Gradually reduce adaptive factor during normal operation
            self.adaptive_factor = max(self.adaptive_factor * 0.95, 1.0)
        
        # Record this request
        self.request_history.append(now)
    
    def add_human_delay(self, min_delay=0.5, max_delay=2.0):
        """Add human-like random delays"""
        delay = random.uniform(min_delay, max_delay)
        time.sleep(delay)
    
    def reset_adaptive_factor(self):
        """Reset adaptive factor after successful operations"""
        self.adaptive_factor = 1.0

class BrowserStealth:
    """Advanced browser detection avoidance"""
    
    def __init__(self):
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ]
        
        self.screen_resolutions = [
            (1920, 1080), (1366, 768), (1440, 900), (1536, 864), (1280, 720)
        ]
        
        self.languages = ["en-US,en;q=0.9", "en-GB,en;q=0.9", "en;q=0.9"]
        
    def get_random_user_agent(self):
        """Get a random user agent"""
        return random.choice(self.user_agents)
    
    def get_random_resolution(self):
        """Get a random screen resolution"""
        return random.choice(self.screen_resolutions)
    
    def get_random_language(self):
        """Get a random language preference"""
        return random.choice(self.languages)
    
    def apply_stealth_settings(self, chrome_options):
        """Apply comprehensive stealth settings to Chrome"""
        width, height = self.get_random_resolution()
        user_agent = self.get_random_user_agent()
        language = self.get_random_language()
        
        # Basic stealth settings
        chrome_options.add_argument(f"--user-agent={user_agent}")
        chrome_options.add_argument(f"--window-size={width},{height}")
        chrome_options.add_argument(f"--lang={language.split(',')[0]}")
        
        # Simple anti-detection
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)
        
        return chrome_options
    
    def add_stealth_scripts(self, driver):
        """Add JavaScript to further hide automation"""
        stealth_scripts = [
            # Hide webdriver property
            "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})",
            
            # Spoof plugins
            """
            Object.defineProperty(navigator, 'plugins', {
                get: () => [1, 2, 3, 4, 5].map(() => ({
                    0: {type: "application/x-google-chrome-pdf", suffixes: "pdf", description: "Portable Document Format", enabledPlugin: Plugin},
                    description: "Portable Document Format",
                    filename: "internal-pdf-viewer",
                    length: 1,
                    name: "Chrome PDF Plugin"
                }))
            });
            """,
            
            # Spoof languages
            f"Object.defineProperty(navigator, 'languages', {{get: () => ['{self.get_random_language().split(',')[0]}']}})",
            
            # Hide automation indicators
            "window.chrome = { runtime: {} };",
            "Object.defineProperty(navigator, 'permissions', { get: () => undefined });",
            "Object.defineProperty(navigator, 'serviceWorker', { get: () => undefined });",
        ]
        
        for script in stealth_scripts:
            try:
                driver.execute_script(script)
            except Exception as e:
                logging.debug(f"Failed to execute stealth script: {e}")
    
    def simulate_human_behavior(self, driver, element=None):
        """Simulate human-like mouse movements and interactions"""
        try:
            actions = ActionChains(driver)
            
            if element:
                # Move to element with human-like curve
                actions.move_to_element_with_offset(element, 
                    random.randint(-5, 5), random.randint(-5, 5))
                
                # Add small random movements
                for _ in range(random.randint(1, 3)):
                    actions.move_by_offset(random.randint(-2, 2), random.randint(-2, 2))
                    actions.pause(random.uniform(0.1, 0.3))
                
                actions.pause(random.uniform(0.2, 0.8))
                actions.click()
            else:
                # Random mouse movements
                for _ in range(random.randint(2, 5)):
                    x = random.randint(100, 800)
                    y = random.randint(100, 600)
                    actions.move_by_offset(x, y)
                    actions.pause(random.uniform(0.5, 1.5))
            
            actions.perform()
            
        except Exception as e:
            logging.debug(f"Human behavior simulation failed: {e}")

class CircuitBreaker:
    """Circuit breaker pattern for error recovery"""
    
    def __init__(self, failure_threshold=5, recovery_timeout=300, expected_exception=Exception):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        self.failure_count = 0
        self.last_failure_time = None
        self.state = 'CLOSED'  # CLOSED, OPEN, HALF_OPEN
        
    def call(self, func, *args, **kwargs):
        """Execute function with circuit breaker protection"""
        if self.state == 'OPEN':
            if self._should_attempt_reset():
                self.state = 'HALF_OPEN'
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        except self.expected_exception as e:
            self._on_failure()
            raise e
    
    def _should_attempt_reset(self):
        """Check if enough time has passed to attempt reset"""
        return (time.time() - self.last_failure_time) >= self.recovery_timeout
    
    def _on_success(self):
        """Handle successful execution"""
        self.failure_count = 0
        self.state = 'CLOSED'
    
    def _on_failure(self):
        """Handle failed execution"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = 'OPEN'
            logging.warning(f"Circuit breaker opened after {self.failure_count} failures")

class ErrorRecovery:
    """Advanced error recovery with exponential backoff"""
    
    def __init__(self):
        self.retry_counts = {}
        self.max_retries = 5
        self.base_delay = 1.0
        self.max_delay = 300.0  # 5 minutes
        self.backoff_factor = 2.0
        
    def execute_with_retry(self, func, operation_name, *args, **kwargs):
        """Execute function with intelligent retry logic"""
        retry_count = self.retry_counts.get(operation_name, 0)
        
        for attempt in range(self.max_retries):
            try:
                result = func(*args, **kwargs)
                # Reset retry count on success
                self.retry_counts[operation_name] = 0
                return result
                
            except Exception as e:
                retry_count += 1
                self.retry_counts[operation_name] = retry_count
                
                if attempt == self.max_retries - 1:
                    logging.error(f"Operation '{operation_name}' failed after {self.max_retries} attempts: {e}")
                    raise e
                
                # Calculate delay with exponential backoff
                delay = min(
                    self.base_delay * (self.backoff_factor ** attempt),
                    self.max_delay
                )
                
                # Add jitter to prevent thundering herd
                jitter = random.uniform(0.5, 1.5)
                final_delay = delay * jitter
                
                logging.warning(f"Operation '{operation_name}' failed (attempt {attempt + 1}/{self.max_retries}): {e}")
                logging.info(f"Retrying in {final_delay:.2f} seconds...")
                
                time.sleep(final_delay)
        
        return None
    
    def get_retry_count(self, operation_name):
        """Get current retry count for an operation"""
        return self.retry_counts.get(operation_name, 0)
    
    def reset_retry_count(self, operation_name):
        """Reset retry count for an operation"""
        self.retry_counts[operation_name] = 0

class FunPayBooster:
    def __init__(self, config_file='/etc/funpay/config.json'):
        self.driver = None
        self.config_file = config_file
        self.config = {}
        self.xvfb_process = None
        self.display_num = 111
        self.consecutive_errors = 0
        self.max_errors = 3
        self.pid_file = '/tmp/funpay_boost.pid'
        
        # Rate Limiting & Error Recovery
        self.rate_limiter = RateLimiter()
        self.error_recovery = ErrorRecovery()
        self.browser_stealth = BrowserStealth()
        
        # Circuit breaker for error recovery
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=5,
            recovery_timeout=1800,  # 30 minutes
            expected_exception=Exception
        )
        
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
            self.kill_processes('chrome')
            self.kill_processes('chromedriver')
            
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
    
    def setup_chrome(self):
        """Setup Chrome with enhanced Selenium 4.x compatibility"""
        try:
            if not self.setup_display():
                return False
            
            # Chrome options with enhanced compatibility
            chrome_options = Options()
            
            # Apply stealth settings first
            chrome_options = self.browser_stealth.apply_stealth_settings(chrome_options)
            
            # Simple headless options
            chrome_options.add_argument("--headless")
            chrome_options.add_argument("--no-sandbox")
            chrome_options.add_argument("--disable-dev-shm-usage")
            chrome_options.add_argument("--disable-gpu")
            
            # Enhanced service configuration for ChromeDriver
            service_args = [
                '--log-level=3',  # Reduced logging
                '--silent'
            ]
            
            # Try multiple ChromeDriver paths
            chromedriver_paths = [
                '/usr/local/bin/chromedriver',
                '/usr/bin/chromedriver',
                'chromedriver'
            ]
            
            service = None
            for path in chromedriver_paths:
                try:
                    if os.path.exists(path) or path == 'chromedriver':
                        service = Service(executable_path=path, service_args=service_args)
                        self.logger.info(f"Using ChromeDriver at: {path}")
                        break
                except Exception as e:
                    self.logger.debug(f"Failed to create service with {path}: {e}")
                    continue
            
            if not service:
                self.logger.error("ChromeDriver not found in any expected location")
                return False
            
            # Simple Chrome startup
            def _start_chrome():
                try:
                    self.logger.info("Starting Chrome with simple settings...")
                    
                    # Create driver with minimal configuration
                    options = Options()
                    options.add_argument('--headless')
                    options.add_argument('--no-sandbox')
                    options.add_argument('--disable-dev-shm-usage')
                    options.add_argument('--disable-gpu')
                    
                    driver = webdriver.Chrome(options=options)
                    
                    # Set basic timeouts
                    driver.set_page_load_timeout(60)
                    driver.implicitly_wait(10)
                    
                    self.logger.info("Chrome driver created successfully")
                    return driver
                    
                except Exception as e:
                    self.logger.error(f"Chrome startup failed: {e}")
                    raise e
            
            # Use error recovery with increased retries
            self.driver = self.error_recovery.execute_with_retry(
                _start_chrome, "chrome_startup"
            )
            
            if not self.driver:
                self.logger.error("Failed to start Chrome after all retries")
                return False
            
            # Apply stealth scripts after successful startup
            try:
                self.browser_stealth.add_stealth_scripts(self.driver)
                self.logger.info("Stealth scripts applied successfully")
            except Exception as e:
                self.logger.warning(f"Failed to apply stealth scripts: {e}")
            
            # Verify Chrome is working with a simple test
            try:
                self.logger.info("Verifying Chrome functionality...")
                test_html = "data:text/html,<html><body><h1>Chrome Compatibility Test</h1><p>Selenium 4.x + Chrome</p></body></html>"
                self.driver.get(test_html)
                
                if "Chrome Compatibility Test" in self.driver.page_source:
                    self.logger.info("✅ Chrome verification successful")
                else:
                    self.logger.warning("⚠️ Chrome verification unclear")
                    
            except Exception as e:
                self.logger.warning(f"Chrome verification error: {e}")
            
            # Add human-like delay after startup
            self.rate_limiter.add_human_delay(3.0, 6.0)
            
            self.logger.info("✅ Chrome driver initialized successfully with enhanced compatibility")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to setup Chrome: {e}")
            return False
    
    def try_login_with_credentials(self):
        """Try to login with username/password using enhanced stealth"""
        try:
            self.logger.info("Attempting login with credentials...")
            
            # Apply rate limiting before login attempt
            self.rate_limiter.wait_if_needed("login_attempt")
            
            # Navigate to login page with human-like behavior
            def _navigate_to_login():
                self.driver.get("https://funpay.com/en/account/login")
                self.rate_limiter.add_human_delay(2.0, 4.0)
                return True
            
            if not self.error_recovery.execute_with_retry(_navigate_to_login, "navigate_login"):
                return False
            
            # Check for CAPTCHA
            page_source = self.driver.page_source.lower()
            if "captcha" in page_source or "recaptcha" in page_source:
                self.logger.warning("CAPTCHA detected on login page")
                return False
            
            # Fill login form with human-like behavior
            wait = WebDriverWait(self.driver, random.randint(10, 15))
            
            # Find and fill username with human simulation
            username_field = wait.until(EC.presence_of_element_located((By.NAME, "login")))
            self.browser_stealth.simulate_human_behavior(self.driver, username_field)
            self.rate_limiter.add_human_delay(0.5, 1.5)
            
            username_field.clear()
            # Type username character by character with random delays
            for char in self.config['username']:
                username_field.send_keys(char)
                time.sleep(random.uniform(0.05, 0.15))
            
            self.rate_limiter.add_human_delay(1.0, 2.0)
            
            # Find and fill password
            password_field = self.driver.find_element(By.NAME, "password")
            self.browser_stealth.simulate_human_behavior(self.driver, password_field)
            self.rate_limiter.add_human_delay(0.5, 1.5)
            
            password_field.clear()
            # Type password with random delays
            for char in self.config['password']:
                password_field.send_keys(char)
                time.sleep(random.uniform(0.05, 0.15))
            
            self.rate_limiter.add_human_delay(1.0, 3.0)
            
            # Submit form with human-like behavior
            login_button = self.driver.find_element(By.XPATH, "//button[@type='submit']")
            self.browser_stealth.simulate_human_behavior(self.driver, login_button)
            
            # Wait for response with random delay
            response_delay = random.uniform(3.0, 7.0)
            time.sleep(response_delay)
            
            # Check login success
            if "login" not in self.driver.current_url.lower():
                self.logger.info("✅ Login successful with credentials!")
                self.rate_limiter.reset_adaptive_factor()
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
    
    def parse_wait_time_from_page(self):
        """Parse wait time from page content and update config accordingly"""
        try:
            page_source = self.driver.page_source
            
            # Look for "Please wait X minutes" or similar patterns
            import re
            
            # Patterns to match wait times
            wait_patterns = [
                r'please wait (\d+) minutes?',
                r'wait (\d+) minutes?',
                r'подожди (\d+) минут',
                r'через (\d+) минут',
                r'cooldown.*?(\d+).*?minutes?',
                r'try again.*?(\d+).*?minutes?'
            ]
            
            for pattern in wait_patterns:
                match = re.search(pattern, page_source, re.IGNORECASE)
                if match:
                    wait_minutes = int(match.group(1))
                    self.logger.info(f"🕐 Site says: Please wait {wait_minutes} minutes")
                    
                    # Calculate next boost time based on site's message
                    next_boost_time = datetime.now() + timedelta(minutes=wait_minutes)
                    
                    # Update config with accurate timing
                    # Calculate when the last boost actually happened
                    last_boost_time = next_boost_time - timedelta(hours=self.config.get('boost_interval', 3))
                    
                    self.config['last_boost'] = last_boost_time.isoformat()
                    self.save_config()
                    
                    self.logger.info(f"📅 Updated last boost time to: {last_boost_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.logger.info(f"📅 Next boost will be at: {next_boost_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    
                    return wait_minutes
            
            # Look for "hours" patterns
            hour_patterns = [
                r'please wait (\d+) hours?',
                r'wait (\d+) hours?',
                r'подожди (\d+) час',
                r'через (\d+) час'
            ]
            
            for pattern in hour_patterns:
                match = re.search(pattern, page_source, re.IGNORECASE)
                if match:
                    wait_hours = int(match.group(1))
                    wait_minutes = wait_hours * 60
                    self.logger.info(f"🕐 Site says: Please wait {wait_hours} hours ({wait_minutes} minutes)")
                    
                    # Calculate next boost time based on site's message
                    next_boost_time = datetime.now() + timedelta(hours=wait_hours)
                    
                    # Update config with accurate timing
                    last_boost_time = next_boost_time - timedelta(hours=self.config.get('boost_interval', 3))
                    
                    self.config['last_boost'] = last_boost_time.isoformat()
                    self.save_config()
                    
                    self.logger.info(f"📅 Updated last boost time to: {last_boost_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.logger.info(f"📅 Next boost will be at: {next_boost_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    
                    return wait_minutes
            
            return None
            
        except Exception as e:
            self.logger.error(f"Error parsing wait time from page: {e}")
            return None

    def check_boost_status(self):
        """Check boost status and perform boost if available with enhanced stealth and accurate timing"""
        try:
            self.logger.info("Checking boost status...")
            
            # Apply rate limiting before boost check
            self.rate_limiter.wait_if_needed("boost_check")
            
            # Navigate to boost page with error recovery
            def _navigate_to_boost():
                self.driver.get(self.config['target_url'])
                self.rate_limiter.add_human_delay(3.0, 6.0)
                return True
            
            if not self.error_recovery.execute_with_retry(_navigate_to_boost, "navigate_boost"):
                return "error"
            
            # Check if redirected to login
            if "login" in self.driver.current_url.lower():
                self.logger.warning("Redirected to login - cookies may have expired")
                return "auth_failed"
            
            # Simulate human browsing behavior
            self.browser_stealth.simulate_human_behavior(self.driver)
            self.rate_limiter.add_human_delay(1.0, 3.0)
            
            # First, check if there's a wait message and parse the time
            wait_minutes = self.parse_wait_time_from_page()
            if wait_minutes is not None:
                self.logger.info(f"⏳ Must wait {wait_minutes} minutes before next boost")
                return "wait"
            
            # Look for boost button with circuit breaker protection
            def _find_and_click_boost():
                boost_button = self.find_boost_button()
                
                if boost_button:
                    self.logger.info("🎯 Boost button found!")
                    
                    # Scroll to button with human-like behavior
                    self.driver.execute_script(
                        "arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", 
                        boost_button
                    )
                    self.rate_limiter.add_human_delay(1.0, 2.0)
                    
                    # Simulate human interaction before clicking
                    self.browser_stealth.simulate_human_behavior(self.driver, boost_button)
                    
                    self.logger.info("🎉 Boost button clicked!")
                    
                    # Wait for response with random delay
                    response_delay = random.uniform(3.0, 8.0)
                    time.sleep(response_delay)
                    
                    # Check if boost was actually successful by looking for success/wait messages
                    post_click_wait = self.parse_wait_time_from_page()
                    if post_click_wait is not None:
                        # Boost was clicked but site says wait - this means it was successful
                        next_boost_time = datetime.now() + timedelta(minutes=post_click_wait)
                        self.logger.info(f"✅ Boost successful! Next boost at: {next_boost_time.strftime('%Y-%m-%d %H:%M:%S')}")
                        
                        # Update config with current time as last boost
                        self.config['last_boost'] = datetime.now().isoformat()
                        self.save_config()
                        
                        return "success"
                    else:
                        # Update last boost time anyway
                        self.config['last_boost'] = datetime.now().isoformat()
                        self.save_config()
                        return "success"
                else:
                    return None
            
            try:
                result = self.circuit_breaker.call(_find_and_click_boost)
                if result:
                    self.rate_limiter.reset_adaptive_factor()
                    return result
            except Exception as e:
                self.logger.warning(f"Circuit breaker prevented boost attempt: {e}")
                return "circuit_open"
            
            # If no boost button and no wait message, something else is wrong
            self.logger.info("❌ No boost button found and no wait message detected")
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
        
        # Setup Chrome
        if not self.setup_chrome():
            self.logger.error("Failed to setup Chrome")
            return False
        
        # Setup authentication
        if not self.setup_authentication():
            self.logger.error("Failed to setup authentication")
            return False
        
        self.logger.info("✅ Boost monitoring started successfully!")
        
        # Main monitoring loop with enhanced error handling
        while True:
            try:
                # Apply rate limiting before each boost check cycle
                self.rate_limiter.wait_if_needed("main_loop")
                
                result = self.check_boost_status()
                
                if result == "success":
                    wait_hours = self.config.get('boost_interval', 3)
                    # Add randomization to boost interval to avoid detection patterns
                    jitter_minutes = random.randint(-30, 30)
                    wait_seconds = (wait_hours * 3600) + (jitter_minutes * 60)
                    next_time = datetime.now() + timedelta(seconds=wait_seconds)
                    
                    self.logger.info(f"✅ Boost successful! Next boost at: {next_time.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.consecutive_errors = 0
                    self.error_recovery.reset_retry_count("boost_operation")
                    
                    # Sleep with periodic status updates and random micro-breaks
                    hours_to_wait = int(wait_seconds // 3600)
                    remaining_seconds = wait_seconds % 3600
                    
                    for i in range(hours_to_wait):
                        # Add random micro-breaks during waiting
                        hour_sleep = 3600 + random.randint(-300, 300)  # ±5 minutes
                        time.sleep(hour_sleep)
                        
                        remaining_hours = hours_to_wait - i - 1
                        if remaining_hours > 0:
                            self.logger.info(f"⏰ {remaining_hours} hours until next boost attempt")
                    
                    # Sleep remaining time
                    if remaining_seconds > 0:
                        time.sleep(remaining_seconds)
                
                elif result == "auth_failed":
                    auth_retry_result = self.error_recovery.execute_with_retry(
                        self.handle_auth_failure, "auth_recovery"
                    )
                    
                    if auth_retry_result:
                        continue  # Try again immediately
                    else:
                        self.logger.error("Re-authentication failed after retries, waiting 1 hour...")
                        time.sleep(3600)
                
                elif result == "wait":
                    # Add randomization to wait time
                    base_wait = 3600  # 1 hour
                    jitter = random.randint(-600, 600)  # ±10 minutes
                    wait_time = base_wait + jitter
                    
                    self.logger.info(f"⏳ Waiting {wait_time//60} minutes before next check...")
                    time.sleep(wait_time)
                
                elif result == "circuit_open":
                    self.logger.warning("Circuit breaker is open, waiting for recovery...")
                    time.sleep(self.circuit_breaker.recovery_timeout)
                
                else:
                    self.consecutive_errors += 1
                    
                    if self.consecutive_errors >= self.max_errors:
                        self.logger.warning("Too many consecutive errors, attempting recovery...")
                        
                        recovery_result = self.error_recovery.execute_with_retry(
                            self.restart_chrome, "chrome_recovery"
                        )
                        
                        if recovery_result:
                            self.consecutive_errors = 0
                            self.logger.info("Recovery successful, continuing...")
                        else:
                            self.logger.error("Recovery failed, entering extended wait...")
                            time.sleep(7200)  # 2 hours
                    else:
                        # Progressive backoff for errors
                        wait_time = 1800 * (2 ** (self.consecutive_errors - 1))  # Exponential backoff
                        wait_time = min(wait_time, 7200)  # Max 2 hours
                        wait_time += random.randint(-300, 300)  # Add jitter
                        
                        self.logger.info(f"⏰ Error {self.consecutive_errors}/{self.max_errors}, waiting {wait_time//60} minutes...")
                        time.sleep(wait_time)
                
            except KeyboardInterrupt:
                self.logger.info("🛑 Daemon stopped by user")
                break
            except Exception as e:
                self.logger.error(f"Unexpected error in main loop: {e}")
                
                # Use error recovery for unexpected errors
                recovery_wait = self.error_recovery.execute_with_retry(
                    lambda: random.randint(1800, 3600), "unexpected_error_recovery"
                )
                time.sleep(recovery_wait or 1800)
        
        return True
    
    def restart_chrome(self):
        """Restart Chrome driver with enhanced recovery"""
        try:
            self.logger.info("Restarting Chrome with enhanced recovery...")
            
            # Cleanup with error recovery
            def _cleanup():
                self.cleanup()
                # Add random delay to avoid detection patterns
                cleanup_delay = random.uniform(5.0, 15.0)
                time.sleep(cleanup_delay)
                return True
            
            self.error_recovery.execute_with_retry(_cleanup, "cleanup_operation")
            
            # Setup Chrome with circuit breaker protection
            def _setup_and_auth():
                if self.setup_chrome():
                    if self.setup_authentication():
                        return True
                return False
            
            result = self.circuit_breaker.call(_setup_and_auth)
            
            if result:
                self.logger.info("✅ Chrome restarted successfully with enhanced recovery")
                # Reset error counters on successful restart
                self.consecutive_errors = 0
                self.error_recovery.reset_retry_count("chrome_restart")
                self.rate_limiter.reset_adaptive_factor()
                return True
            else:
                self.logger.error("❌ Failed to restart Chrome")
                return False
            
        except Exception as e:
            self.logger.error(f"Error restarting Chrome: {e}")
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
    
    def start_background(self):
        """Start daemon in background"""
        try:
            # Check if already running
            if self.is_running():
                print("❌ FunPay Auto Boost is already running in background!")
                print(f"PID: {self.get_running_pid()}")
                return False
            
            print("🚀 Starting FunPay Auto Boost in background...")
            
            # Fork process to background
            pid = os.fork()
            
            if pid > 0:
                # Parent process
                print(f"✅ FunPay Auto Boost started in background with PID: {pid}")
                print("📋 Use --stop to stop the background process")
                print("📋 Use --status to check status")
                return True
            
            # Child process - run in background
            os.setsid()  # Create new session
            
            # Redirect stdout/stderr to log file
            log_file = '/var/log/funpay/background.log'
            os.makedirs(os.path.dirname(log_file), exist_ok=True)
            
            with open(log_file, 'a') as f:
                os.dup2(f.fileno(), sys.stdout.fileno())
                os.dup2(f.fileno(), sys.stderr.fileno())
            
            # Save PID
            with open(self.pid_file, 'w') as f:
                f.write(str(os.getpid()))
            
            # Run daemon
            self.run_daemon()
            
        except OSError as e:
            print(f"❌ Failed to start background process: {e}")
            return False
        except Exception as e:
            print(f"❌ Error starting background: {e}")
            return False
    
    def stop_background(self):
        """Stop background daemon"""
        try:
            if not self.is_running():
                print("ℹ️ FunPay Auto Boost is not running in background")
                return True
            
            pid = self.get_running_pid()
            print(f"🛑 Stopping FunPay Auto Boost (PID: {pid})...")
            
            # Send SIGTERM first
            os.kill(pid, signal.SIGTERM)
            time.sleep(2)
            
            # Check if still running
            if self.is_running():
                print("⚠️ Process didn't stop gracefully, forcing...")
                os.kill(pid, signal.SIGKILL)
                time.sleep(1)
            
            # Remove PID file
            if os.path.exists(self.pid_file):
                os.remove(self.pid_file)
            
            print("✅ FunPay Auto Boost stopped successfully")
            return True
            
        except ProcessLookupError:
            print("ℹ️ Process was already stopped")
            if os.path.exists(self.pid_file):
                os.remove(self.pid_file)
            return True
        except PermissionError:
            print("❌ Permission denied. Try running with sudo")
            return False
        except Exception as e:
            print(f"❌ Error stopping background process: {e}")
            return False
    
    def is_running(self):
        """Check if daemon is running in background"""
        try:
            if not os.path.exists(self.pid_file):
                return False
            
            with open(self.pid_file, 'r') as f:
                pid = int(f.read().strip())
            
            # Check if process exists
            os.kill(pid, 0)  # Signal 0 just checks if process exists
            return True
            
        except (FileNotFoundError, ValueError, ProcessLookupError):
            # Clean up stale PID file
            if os.path.exists(self.pid_file):
                os.remove(self.pid_file)
            return False
        except Exception:
            return False
    
    def get_running_pid(self):
        """Get PID of running background process"""
        try:
            if os.path.exists(self.pid_file):
                with open(self.pid_file, 'r') as f:
                    return int(f.read().strip())
        except:
            pass
        return None
    
    def get_background_status(self):
        """Get detailed background status"""
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║              FunPay Auto Boost - Background Status          ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print("")
        
        if self.is_running():
            pid = self.get_running_pid()
            print(f"🟢 Status: Running in background")
            print(f"🆔 PID: {pid}")
            
            # Get process info
            try:
                result = subprocess.run(['ps', '-p', str(pid), '-o', 'pid,ppid,etime,cmd'], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')
                    if len(lines) > 1:
                        print(f"📊 Process Info:")
                        print(f"   {lines[0]}")  # Header
                        print(f"   {lines[1]}")  # Process info
            except:
                pass
            
            # Show log file location
            print(f"📄 Log File: /var/log/funpay/background.log")
            print(f"📄 Boost Log: /var/log/funpay/boost.log")
            
            # Show recent activity
            try:
                result = subprocess.run(['tail', '-3', '/var/log/funpay/boost.log'], 
                                      capture_output=True, text=True)
                if result.returncode == 0 and result.stdout.strip():
                    print(f"📋 Recent Activity:")
                    for line in result.stdout.strip().split('\n'):
                        print(f"   {line}")
            except:
                pass
                
        else:
            print(f"🔴 Status: Not running")
            print(f"💡 Use --start to start in background")
        
        print("")
        
        # Show configuration status
        self.get_status()
    
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
            self.kill_processes('chrome')
            self.kill_processes('chromedriver')
            self.kill_processes('Xvfb')
            
            # Remove PID file if we're the background process
            if os.path.exists(self.pid_file):
                try:
                    with open(self.pid_file, 'r') as f:
                        pid = int(f.read().strip())
                    if pid == os.getpid():
                        os.remove(self.pid_file)
                except:
                    pass
            
            self.logger.info("Cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Error during cleanup: {e}")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='FunPay Auto Boost Ultimate - Background Management')
    parser.add_argument('--daemon', action='store_true', help='Run as daemon (foreground)')
    parser.add_argument('--start', action='store_true', help='Start daemon in background')
    parser.add_argument('--stop', action='store_true', help='Stop background daemon')
    parser.add_argument('--restart', action='store_true', help='Restart background daemon')
    parser.add_argument('--status', action='store_true', help='Show status (including background)')
    parser.add_argument('--setup', action='store_true', help='Run initial setup')
    parser.add_argument('--test', action='store_true', help='Test boost once')
    args = parser.parse_args()
    
    booster = FunPayBooster()
    
    try:
        if args.start:
            # Ask user if they want to run in background
            if not booster.is_running():
                print("🚀 FunPay Auto Boost - Background Mode")
                print("="*50)
                choice = input("Do you want to start in background? (Y/n): ").strip().lower()
                if choice in ['', 'y', 'yes']:
                    booster.start_background()
                else:
                    print("Starting in foreground mode...")
                    booster.run_daemon()
            else:
                print("❌ Already running in background!")
                
        elif args.stop:
            booster.stop_background()
            
        elif args.restart:
            print("🔄 Restarting FunPay Auto Boost...")
            booster.stop_background()
            time.sleep(2)
            booster.start_background()
            
        elif args.status:
            booster.get_background_status()
            
        elif args.setup:
            booster.get_user_credentials()
            
        elif args.test:
            if booster.setup_chrome():
                if booster.setup_authentication():
                    result = booster.check_boost_status()
                    print(f"Test result: {result}")
                booster.cleanup()
                
        elif args.daemon:
            # Traditional daemon mode (foreground)
            print("⚠️ Running in foreground mode. Use --start for background mode.")
            booster.run_daemon()
            
        else:
            # Default behavior - ask user what they want
            print("╔══════════════════════════════════════════════════════════════╗")
            print("║                 FunPay Auto Boost Ultimate                  ║")
            print("╚══════════════════════════════════════════════════════════════╝")
            print("")
            print("Choose an option:")
            print("1. 🚀 Start in background (recommended)")
            print("2. 🖥️  Start in foreground")
            print("3. 📊 Show status")
            print("4. 🛑 Stop background process")
            print("5. ⚙️  Setup configuration")
            print("6. 🧪 Test boost")
            print("")
            
            choice = input("Enter your choice (1-6): ").strip()
            
            if choice == '1':
                booster.start_background()
            elif choice == '2':
                booster.run_daemon()
            elif choice == '3':
                booster.get_background_status()
            elif choice == '4':
                booster.stop_background()
            elif choice == '5':
                booster.get_user_credentials()
            elif choice == '6':
                if booster.setup_chrome():
                    if booster.setup_authentication():
                        result = booster.check_boost_status()
                        print(f"Test result: {result}")
                    booster.cleanup()
            else:
                print("❌ Invalid choice")
                
    except KeyboardInterrupt:
        print("\n🛑 Stopped by user")
    except Exception as e:
        print(f"❌ Fatal error: {e}")
    finally:
        if not args.start:  # Don't cleanup if we're starting background
            booster.cleanup()

if __name__ == "__main__":
    main()
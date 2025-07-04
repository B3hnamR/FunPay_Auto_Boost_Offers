#!/bin/bash

# FunPay Auto Boost - Complete Interactive Installation
# Enhanced with interactive menu and all fixes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/opt/funpay-boost"
SERVICE_USER="funpay"
LOG_DIR="/var/log/funpay"
CONFIG_DIR="/etc/funpay"
SCRIPT_DIR="$(pwd)"

# Function to display header
show_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    ${WHITE}FunPay Auto Boost${BLUE}                        ║${NC}"
    echo -e "${BLUE}║                ${WHITE}Interactive Installation${BLUE}                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to validate URL
validate_url() {
    local url="$1"
    if [[ $url =~ ^https://funpay\.com/.*/lots/.*/trade$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate email
validate_email() {
    local email="$1"
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get user input with validation
get_user_input() {
    show_header
    echo -e "${CYAN}🔐 FunPay Account Configuration${NC}"
    echo -e "${CYAN}═══════════════════════════════${NC}"
    echo ""
    
    # Get username/email
    while true; do
        read -p "📧 Enter your FunPay username/email: " FUNPAY_USERNAME
        if [[ -z "$FUNPAY_USERNAME" ]]; then
            echo -e "${RED}❌ Username cannot be empty!${NC}"
            continue
        fi
        
        if validate_email "$FUNPAY_USERNAME"; then
            echo -e "${GREEN}✅ Valid email format${NC}"
            break
        else
            echo -e "${YELLOW}⚠️ This doesn't look like an email, but continuing...${NC}"
            break
        fi
    done
    
    # Get password
    while true; do
        read -s -p "🔒 Enter your FunPay password: " FUNPAY_PASSWORD
        echo ""
        if [[ -z "$FUNPAY_PASSWORD" ]]; then
            echo -e "${RED}❌ Password cannot be empty!${NC}"
            continue
        fi
        
        read -s -p "🔒 Confirm your password: " CONFIRM_PASSWORD
        echo ""
        if [[ "$FUNPAY_PASSWORD" != "$CONFIRM_PASSWORD" ]]; then
            echo -e "${RED}❌ Passwords don't match!${NC}"
            continue
        fi
        
        echo -e "${GREEN}✅ Password confirmed${NC}"
        break
    done
    
    echo ""
    echo -e "${CYAN}🔗 Boost Offers URL Configuration${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📝 Instructions:${NC}"
    echo "   1. Go to FunPay.com and login"
    echo "   2. Navigate to your offers page"
    echo "   3. Look for 'Boost offers' or similar button"
    echo "   4. Copy the URL from your browser"
    echo ""
    echo -e "${YELLOW}📋 URL Format Example:${NC}"
    echo "   https://funpay.com/en/lots/1355/trade"
    echo "   https://funpay.com/ru/lots/1234/trade"
    echo ""
    
    # Get offers URL
    while true; do
        read -p "🔗 Enter your boost offers URL: " OFFERS_URL
        if [[ -z "$OFFERS_URL" ]]; then
            echo -e "${RED}❌ URL cannot be empty!${NC}"
            continue
        fi
        
        if validate_url "$OFFERS_URL"; then
            echo -e "${GREEN}✅ Valid FunPay URL format${NC}"
            break
        else
            echo -e "${YELLOW}⚠️ URL format doesn't match expected pattern${NC}"
            echo -e "${YELLOW}Expected: https://funpay.com/.../lots/.../trade${NC}"
            read -p "Continue anyway? (y/N): " CONTINUE
            if [[ "$CONTINUE" =~ ^[Yy]$ ]]; then
                break
            fi
        fi
    done
    
    echo ""
    echo -e "${CYAN}⏰ Boost Interval Configuration${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📝 Recommended intervals:${NC}"
    echo "   • 3 hours (default) - Standard boost frequency"
    echo "   • 6 hours - Conservative approach"
    echo "   • 1 hour - Aggressive (may trigger rate limits)"
    echo ""
    
    # Get boost interval
    while true; do
        read -p "⏰ Enter boost interval in hours (default: 3): " BOOST_INTERVAL
        if [[ -z "$BOOST_INTERVAL" ]]; then
            BOOST_INTERVAL=3
            break
        fi
        
        if [[ "$BOOST_INTERVAL" =~ ^[0-9]+$ ]] && [[ "$BOOST_INTERVAL" -gt 0 ]]; then
            if [[ "$BOOST_INTERVAL" -lt 1 ]]; then
                echo -e "${RED}❌ Interval too short! Minimum is 1 hour${NC}"
                continue
            fi
            break
        else
            echo -e "${RED}❌ Please enter a valid number of hours${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Configuration completed!${NC}"
    echo ""
    echo -e "${CYAN}📋 Summary:${NC}"
    echo "   Username: $FUNPAY_USERNAME"
    echo "   URL: $OFFERS_URL"
    echo "   Interval: $BOOST_INTERVAL hours"
    echo ""
    
    read -p "Continue with installation? (Y/n): " CONFIRM_INSTALL
    if [[ "$CONFIRM_INSTALL" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi
}

# Function to show installation progress
show_progress() {
    local step="$1"
    local total="$2"
    local description="$3"
    
    local percent=$((step * 100 / total))
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    
    printf "\r${BLUE}[${NC}"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "${BLUE}] ${percent}%% - ${description}${NC}"
    
    if [[ $step -eq $total ]]; then
        echo ""
    fi
}

# Main installation function
main_installation() {
    show_header
    echo -e "${BLUE}🚀 Starting Installation Process${NC}"
    echo ""
    
    local total_steps=12
    local current_step=0
    
    # Step 1: System check
    ((current_step++))
    show_progress $current_step $total_steps "Checking system requirements"
    sleep 1
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo ""
        echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
        exit 1
    fi
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo ""
        echo -e "${RED}❌ Cannot detect OS version${NC}"
        exit 1
    fi
    
    # Step 2: Update system
    ((current_step++))
    show_progress $current_step $total_steps "Updating system packages"
    apt update >/dev/null 2>&1 && apt upgrade -y >/dev/null 2>&1
    
    # Step 3: Install dependencies
    ((current_step++))
    show_progress $current_step $total_steps "Installing system dependencies"
    apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        firefox \
        xvfb \
        wget \
        curl \
        unzip \
        git \
        supervisor \
        ufw \
        htop \
        screen \
        tmux \
        jq \
        software-properties-common \
        procps \
        psmisc >/dev/null 2>&1
    
    # Step 4: Create user
    ((current_step++))
    show_progress $current_step $total_steps "Setting up service user"
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
    fi
    
    # Step 5: Create directories
    ((current_step++))
    show_progress $current_step $total_steps "Creating directories"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "/home/$SERVICE_USER/.mozilla"
    
    # Step 6: Setup Python environment
    ((current_step++))
    show_progress $current_step $total_steps "Setting up Python environment"
    cd "$INSTALL_DIR"
    python3 -m venv venv >/dev/null 2>&1
    source venv/bin/activate
    pip install --upgrade pip >/dev/null 2>&1
    pip install selenium schedule requests beautifulsoup4 lxml >/dev/null 2>&1
    
    # Step 7: Install GeckoDriver
    ((current_step++))
    show_progress $current_step $total_steps "Installing GeckoDriver"
    GECKODRIVER_VERSION="v0.33.0"
    GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz"
    wget -q -O /tmp/geckodriver.tar.gz "$GECKODRIVER_URL"
    tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/
    chmod +x /usr/local/bin/geckodriver
    rm /tmp/geckodriver.tar.gz
    
    # Step 8: Create configuration
    ((current_step++))
    show_progress $current_step $total_steps "Creating configuration file"
    mkdir -p "$CONFIG_DIR"
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
    
    # Step 9: Create application
    ((current_step++))
    show_progress $current_step $total_steps "Creating application file"
    create_application_file
    
    # Step 10: Set permissions
    ((current_step++))
    show_progress $current_step $total_steps "Setting permissions"
    chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
    chown -R "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"
    chown -R "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR"
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$LOG_DIR"
    chmod 750 "$CONFIG_DIR"
    chmod 600 "$CONFIG_DIR/config.json"
    chmod +x "$INSTALL_DIR/funpay_boost.py"
    
    # Step 11: Create service
    ((current_step++))
    show_progress $current_step $total_steps "Creating systemd service"
    create_systemd_service
    create_management_script
    
    # Step 12: Start service
    ((current_step++))
    show_progress $current_step $total_steps "Starting service"
    systemctl daemon-reload
    systemctl enable funpay-boost >/dev/null 2>&1
    systemctl start funpay-boost
    
    echo ""
    echo ""
}

# Function to create the main application file
create_application_file() {
    cat > "$INSTALL_DIR/funpay_boost.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Enhanced Interactive Version
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
        except FileNotFoundError:
            pass
        
        # Method 2: killall
        if not killed:
            try:
                result = subprocess.run(['killall', process_name], 
                                      capture_output=True, check=False)
                if result.returncode == 0:
                    killed = True
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
                                except:
                                    pass
            except:
                pass
        
        if not killed:
            self.logger.warning(f"Could not kill {process_name} processes")
        
        return killed
    
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
                xvfb_process = subprocess.Popen(
                    ['Xvfb', ':99', '-screen', '0', '1920x1080x24', '-ac', '+extension', 'GLX'],
                    stdout=subprocess.DEVNULL, 
                    stderr=subprocess.PIPE
                )
                time.sleep(3)
                
                # Check if process is still running
                if xvfb_process.poll() is not None:
                    stderr_output = xvfb_process.stderr.read().decode()
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
        """Setup Firefox driver with enhanced options"""
        try:
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
            
            try:
                self.driver = webdriver.Firefox(options=firefox_options)
                self.driver.implicitly_wait(10)
                self.driver.set_page_load_timeout(30)
                
                self.logger.info("Firefox driver initialized successfully")
                return True
                
            except Exception as e:
                self.logger.error(f"Failed to initialize Firefox driver: {e}")
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
                "//button[contains(translate(text(), 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ', 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'), 'поднять')]",
                "//a[contains(translate(text(), 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ', 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'), 'поднять')]",
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
        
        # Initial setup
        if not self.setup_firefox():
            self.logger.error("Failed to setup Firefox")
            return False
        
        if not self.login():
            self.logger.error("Failed to login")
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
            print("╚═════════════════════════════════════════════��════════════════╝")
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
}

# Function to create systemd service
create_systemd_service() {
    cat > /etc/systemd/system/funpay-boost.service << EOF
[Unit]
Description=FunPay Auto Boost Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=DISPLAY=:99
Environment=PYTHONUNBUFFERED=1
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/funpay_boost.py --daemon
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
}

# Function to create management script
create_management_script() {
    cat > /usr/local/bin/funpay-boost << 'EOF'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    ${WHITE}FunPay Auto Boost${BLUE}                        ║${NC}"
    echo -e "${BLUE}║                   ${WHITE}Management Console${BLUE}                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    show_header
    echo -e "${CYAN}📋 Available Commands:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} start     - Start the boost service"
    echo -e "  ${GREEN}2.${NC} stop      - Stop the boost service"
    echo -e "  ${GREEN}3.${NC} restart   - Restart the boost service"
    echo -e "  ${GREEN}4.${NC} status    - Show service status"
    echo -e "  ${GREEN}5.${NC} logs      - Show live logs"
    echo -e "  ${GREEN}6.${NC} info      - Show boost information"
    echo -e "  ${GREEN}7.${NC} config    - Edit configuration"
    echo -e "  ${GREEN}8.${NC} test      - Test boost functionality"
    echo ""
    echo -e "${YELLOW}Usage: funpay-boost [command]${NC}"
    echo ""
}

edit_config() {
    echo -e "${CYAN}📝 Configuration Editor${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    if [[ ! -f /etc/funpay/config.json ]]; then
        echo -e "${RED}❌ Configuration file not found!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Current configuration:${NC}"
    echo ""
    jq . /etc/funpay/config.json 2>/dev/null || cat /etc/funpay/config.json
    echo ""
    
    read -p "Edit configuration? (y/N): " EDIT_CONFIRM
    if [[ "$EDIT_CONFIRM" =~ ^[Yy]$ ]]; then
        if command -v nano >/dev/null; then
            nano /etc/funpay/config.json
        elif command -v vi >/dev/null; then
            vi /etc/funpay/config.json
        else
            echo -e "${RED}❌ No text editor found!${NC}"
            return 1
        fi
        
        echo -e "${GREEN}✅ Configuration updated${NC}"
        echo -e "${YELLOW}Restart service to apply changes: funpay-boost restart${NC}"
    fi
}

test_boost() {
    echo -e "${CYAN}🧪 Testing Boost Functionality${NC}"
    echo -e "${CYAN}═══════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Running test boost (dry run)...${NC}"
    sudo -u funpay /opt/funpay-boost/venv/bin/python -c "
import sys
sys.path.append('/opt/funpay-boost')
from funpay_boost import FunPayBooster

try:
    booster = FunPayBooster()
    print('✅ Configuration loaded successfully')
    
    if booster.setup_firefox():
        print('✅ Firefox setup successful')
        
        if booster.login():
            print('✅ Login successful')
            
            status, data = booster.check_boost_status()
            print(f'✅ Boost status check: {status}')
            
        else:
            print('❌ Login failed')
    else:
        print('❌ Firefox setup failed')
        
    booster.cleanup()
    print('✅ Test completed')
    
except Exception as e:
    print(f'❌ Test failed: {e}')
"
}

case "$1" in
    start)
        echo -e "${YELLOW}🚀 Starting FunPay Boost service...${NC}"
        systemctl start funpay-boost
        sleep 2
        if systemctl is-active --quiet funpay-boost; then
            echo -e "${GREEN}✅ Service started successfully${NC}"
        else
            echo -e "${RED}❌ Failed to start service${NC}"
            echo -e "${YELLOW}Check logs: funpay-boost logs${NC}"
        fi
        ;;
    stop)
        echo -e "${YELLOW}🛑 Stopping FunPay Boost service...${NC}"
        systemctl stop funpay-boost
        echo -e "${GREEN}✅ Service stopped${NC}"
        ;;
    restart)
        echo -e "${YELLOW}🔄 Restarting FunPay Boost service...${NC}"
        systemctl restart funpay-boost
        sleep 2
        if systemctl is-active --quiet funpay-boost; then
            echo -e "${GREEN}✅ Service restarted successfully${NC}"
        else
            echo -e "${RED}❌ Failed to restart service${NC}"
            echo -e "${YELLOW}Check logs: funpay-boost logs${NC}"
        fi
        ;;
    status)
        echo -e "${CYAN}📊 Service Status:${NC}"
        echo ""
        systemctl status funpay-boost --no-pager
        ;;
    logs)
        echo -e "${CYAN}📋 Live Logs (Press Ctrl+C to exit):${NC}"
        echo ""
        journalctl -u funpay-boost -f --no-pager
        ;;
    info)
        sudo -u funpay /opt/funpay-boost/venv/bin/python /opt/funpay-boost/funpay_boost.py --status
        ;;
    config)
        edit_config
        ;;
    test)
        test_boost
        ;;
    menu)
        show_menu
        ;;
    *)
        show_menu
        echo -e "${RED}❌ Invalid command: $1${NC}"
        echo ""
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/funpay-boost
}

# Function to show final results
show_results() {
    show_header
    
    sleep 3
    SERVICE_STATUS=$(systemctl is-active funpay-boost)
    
    echo -e "${GREEN}🎉 Installation Completed Successfully!${NC}"
    echo ""
    
    if [[ "$SERVICE_STATUS" == "active" ]]; then
        echo -e "${GREEN}✅ Service Status: Running${NC}"
    else
        echo -e "${YELLOW}⚠️ Service Status: $SERVICE_STATUS${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📋 Configuration Summary:${NC}"
    echo "   👤 Username: $FUNPAY_USERNAME"
    echo "   🔗 Target URL: $OFFERS_URL"
    echo "   ⏰ Boost Interval: $BOOST_INTERVAL hours"
    echo ""
    
    echo -e "${CYAN}🎮 Available Commands:${NC}"
    echo "   funpay-boost start    - Start the service"
    echo "   funpay-boost stop     - Stop the service"
    echo "   funpay-boost restart  - Restart the service"
    echo "   funpay-boost status   - Show service status"
    echo "   funpay-boost logs     - Show live logs"
    echo "   funpay-boost info     - Show boost information"
    echo "   funpay-boost config   - Edit configuration"
    echo "   funpay-boost test     - Test functionality"
    echo "   funpay-boost menu     - Show interactive menu"
    echo ""
    
    echo -e "${GREEN}🚀 Your FunPay offers will be automatically boosted every $BOOST_INTERVAL hours!${NC}"
    echo ""
    
    if [[ "$SERVICE_STATUS" != "active" ]]; then
        echo -e "${YELLOW}💡 Tip: Check logs if service is not running: funpay-boost logs${NC}"
    fi
    
    echo -e "${BLUE}📖 For help and troubleshooting, run: funpay-boost menu${NC}"
    echo ""
}

# Main execution
main() {
    # Check if configuration exists
    if [[ -f /etc/funpay/config.json ]]; then
        show_header
        echo -e "${GREEN}✅ Existing installation detected${NC}"
        echo ""
        
        # Show current config
        echo -e "${CYAN}Current Configuration:${NC}"
        if command -v jq >/dev/null 2>&1; then
            jq -r '"Username: " + .username, "URL: " + .target_url, "Interval: " + (.boost_interval|tostring) + " hours"' /etc/funpay/config.json
        else
            echo "   Username: $(grep -o '"username":"[^"]*"' /etc/funpay/config.json | cut -d'"' -f4)"
            echo "   URL: $(grep -o '"target_url":"[^"]*"' /etc/funpay/config.json | cut -d'"' -f4)"
            echo "   Interval: $(grep -o '"boost_interval":[0-9]*' /etc/funpay/config.json | cut -d':' -f2) hours"
        fi
        echo ""
        
        read -p "Reinstall with new configuration? (y/N): " REINSTALL
        if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled${NC}"
            echo -e "${BLUE}Use 'funpay-boost menu' for management options${NC}"
            exit 0
        fi
        
        # Stop existing service
        systemctl stop funpay-boost 2>/dev/null || true
    fi
    
    # Get user input
    get_user_input
    
    # Run installation
    main_installation
    
    # Show results
    show_results
}

# Run main function
main "$@"
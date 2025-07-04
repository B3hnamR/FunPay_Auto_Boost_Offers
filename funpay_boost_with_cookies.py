#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - با استفاده از Cookies
"""

import os
import subprocess
import time
import json
import logging
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/funpay/boost.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Cookies شما
COOKIES = [
    {"name": "fav_games", "value": "334", "domain": ".funpay.com"},
    {"name": "golden_key", "value": "o5kga3zclpvrtqp9l1r7uk2uoed93my7", "domain": ".funpay.com"},
    {"name": "PHPSESSID", "value": "RcGDonY9aW3fvDy-qoi2lzS0f1iZBQRo", "domain": ".funpay.com"},
]

def load_config():
    with open('/etc/funpay/config.json', 'r') as f:
        return json.load(f)

def save_config(config):
    with open('/etc/funpay/config.json', 'w') as f:
        json.dump(config, f, indent=2)

def setup_firefox():
    logger.info("Setting up Firefox...")
    
    # Use unique display
    display_num = 107
    os.environ['DISPLAY'] = f':{display_num}'
    
    # Start Xvfb
    subprocess.Popen([f'Xvfb', f':{display_num}', '-screen', '0', '1024x768x24'], 
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(3)
    
    # Setup Firefox options
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    
    # Anti-detection
    options.set_preference("dom.webdriver.enabled", False)
    options.set_preference("useAutomationExtension", False)
    options.set_preference("general.useragent.override", 
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0")
    
    # Start Firefox
    driver = webdriver.Firefox(options=options)
    driver.set_page_load_timeout(15)
    
    logger.info("Firefox started successfully")
    return driver

def add_cookies(driver):
    logger.info("Adding cookies...")
    
    # First visit the domain
    driver.get("https://funpay.com")
    time.sleep(2)
    
    # Add cookies
    for cookie in COOKIES:
        try:
            driver.add_cookie(cookie)
            logger.info(f"Added cookie: {cookie['name']}")
        except Exception as e:
            logger.warning(f"Failed to add cookie {cookie['name']}: {e}")
    
    logger.info("Cookies added successfully")

def check_boost(driver, config):
    logger.info("Checking boost status...")
    
    try:
        # Go to boost page
        driver.get(config['target_url'])
        time.sleep(3)
        
        # Check if we're logged in
        if "login" in driver.current_url.lower():
            logger.error("Still redirected to login - cookies may be expired")
            return False
        
        logger.info("✅ Successfully accessed boost page!")
        
        # Look for boost button
        try:
            boost_button = driver.find_element(By.XPATH, 
                "//button[contains(text(), 'boost')] | //a[contains(text(), 'boost')] | " +
                "//button[contains(text(), 'Boost')] | //a[contains(text(), 'Boost')] | " +
                "//button[contains(text(), 'поднять')] | //a[contains(text(), 'поднять')]")
            
            if boost_button.is_displayed():
                logger.info("🎯 Boost button found!")
                boost_button.click()
                logger.info("🎉 Boost clicked successfully!")
                
                time.sleep(3)
                
                # Check for success message
                page_source = driver.page_source.lower()
                if "success" in page_source or "successful" in page_source or "boosted" in page_source:
                    logger.info("✅ Boost confirmed successful!")
                else:
                    logger.info("✅ Boost clicked (confirmation unclear)")
                
                # Update config
                config['last_boost'] = datetime.now().isoformat()
                save_config(config)
                
                return True
        except Exception as e:
            logger.debug(f"Boost button search failed: {e}")
        
        # Check for wait message
        page_source = driver.page_source.lower()
        if "wait" in page_source or "подожд" in page_source:
            logger.info("⏳ Must wait before next boost")
        else:
            logger.info("❌ No boost button found")
        
        return False
        
    except Exception as e:
        logger.error(f"Error checking boost: {e}")
        return False

def main():
    logger.info("Starting FunPay Auto Boost (Cookie Version)")
    
    # Load config
    config = load_config()
    logger.info(f"🎯 Target URL: {config['target_url']}")
    logger.info(f"👤 Username: {config['username']}")
    
    # Setup Firefox
    driver = setup_firefox()
    
    # Add cookies
    add_cookies(driver)
    
    logger.info("🚀 Boost monitoring started")
    
    # Main loop
    while True:
        try:
            if check_boost(driver, config):
                wait_hours = config.get('boost_interval', 3)
                logger.info(f"✅ Boost successful! Waiting {wait_hours} hours...")
                time.sleep(wait_hours * 3600)
            else:
                logger.info("⏰ No boost needed, checking again in 1 hour...")
                time.sleep(3600)
                
        except KeyboardInterrupt:
            logger.info("🛑 Stopping...")
            break
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            time.sleep(1800)  # Wait 30 minutes
    
    driver.quit()
    logger.info("Stopped")

def get_status():
    config = load_config()
    last_boost = config.get('last_boost')
    interval = config.get('boost_interval', 3)
    
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║                    FunPay Auto Boost Status                 ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print("")
    print(f"🎯 Target URL: {config['target_url']}")
    print(f"👤 Username: {config['username']}")
    print(f"⏰ Boost Interval: {interval} hours")
    print("")
    
    if last_boost:
        try:
            last_time = datetime.fromisoformat(last_boost)
            next_time = last_time.replace(hour=last_time.hour + interval)
            
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
        except:
            print(f"📅 Last Boost: {last_boost}")
    else:
        print(f"📅 Last Boost: Never")
        print(f"🔄 Status: Ready for first boost")
    
    print("")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--daemon', action='store_true', help='Run as daemon')
    parser.add_argument('--status', action='store_true', help='Show status')
    parser.add_argument('--test', action='store_true', help='Test once')
    args = parser.parse_args()
    
    if args.status:
        get_status()
    elif args.test:
        config = load_config()
        driver = setup_firefox()
        add_cookies(driver)
        result = check_boost(driver, config)
        driver.quit()
        print(f"Test result: {'Success' if result else 'Failed'}")
    else:
        main()
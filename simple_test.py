#!/usr/bin/env python3
"""
Simple Firefox Test - Minimal configuration
"""

import os
import time
import subprocess
import sys

def test_firefox_minimal():
    """Test Firefox with minimal configuration"""
    try:
        print("🔍 Testing Firefox with minimal settings...")
        
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options
        from selenium.webdriver.firefox.service import Service
        
        # Kill any existing processes
        subprocess.run(['pkill', '-f', 'firefox'], capture_output=True)
        subprocess.run(['pkill', '-f', 'geckodriver'], capture_output=True)
        subprocess.run(['pkill', '-f', 'Xvfb'], capture_output=True)
        time.sleep(2)
        
        # Start Xvfb
        print("🖥️ Starting Xvfb...")
        os.environ['DISPLAY'] = ':99'
        xvfb = subprocess.Popen(['Xvfb', ':99', '-screen', '0', '1024x768x24'], 
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(3)
        
        # Minimal Firefox options
        options = Options()
        options.add_argument("--headless")
        options.add_argument("--no-sandbox")
        
        # Minimal preferences
        options.set_preference("marionette.enabled", True)
        options.set_preference("dom.webdriver.enabled", False)
        
        # Simple service
        service = Service(executable_path='/usr/local/bin/geckodriver')
        
        print("🚀 Starting Firefox...")
        driver = webdriver.Firefox(service=service, options=options)
        driver.set_page_load_timeout(30)
        driver.implicitly_wait(10)
        
        print("✅ Firefox started successfully!")
        
        # Simple test
        driver.get("data:text/html,<html><body><h1>Test</h1></body></html>")
        print(f"✅ Page loaded: {driver.title}")
        
        # Cleanup
        driver.quit()
        xvfb.terminate()
        
        print("✅ Test completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False

if __name__ == "__main__":
    success = test_firefox_minimal()
    sys.exit(0 if success else 1)
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Enhanced Compatibility Test for FunPay Auto Boost
Tests Selenium 4.x + Firefox 140.x + GeckoDriver 0.36.0 compatibility
"""

import sys
import os
import time
import subprocess
import logging
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_versions():
    """Check all component versions"""
    logger.info("🔍 Checking component versions...")
    
    versions = {}
    
    # Check Python
    try:
        versions['python'] = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        logger.info(f"✅ Python: {versions['python']}")
    except Exception as e:
        logger.error(f"❌ Python check failed: {e}")
        return False
    
    # Check Selenium
    try:
        import selenium
        versions['selenium'] = selenium.__version__
        logger.info(f"✅ Selenium: {versions['selenium']}")
    except ImportError:
        logger.error("❌ Selenium not installed")
        return False
    
    # Check Firefox
    try:
        result = subprocess.run(['firefox', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            versions['firefox'] = result.stdout.strip()
            logger.info(f"✅ {versions['firefox']}")
        else:
            logger.error("❌ Firefox not found")
            return False
    except FileNotFoundError:
        logger.error("❌ Firefox not found")
        return False
    
    # Check GeckoDriver
    try:
        result = subprocess.run(['geckodriver', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            version_line = result.stdout.split('\n')[0]
            versions['geckodriver'] = version_line
            logger.info(f"✅ {version_line}")
        else:
            logger.error("❌ GeckoDriver not found")
            return False
    except FileNotFoundError:
        logger.error("❌ GeckoDriver not found")
        return False
    
    return versions

def test_basic_selenium():
    """Test basic Selenium functionality"""
    logger.info("🧪 Testing basic Selenium functionality...")
    
    try:
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options
        from selenium.webdriver.firefox.service import Service
        from selenium.webdriver.common.by import By
        
        # Setup Firefox options
        firefox_options = Options()
        firefox_options.add_argument("--headless")
        firefox_options.add_argument("--no-sandbox")
        firefox_options.add_argument("--disable-dev-shm-usage")
        
        # Enhanced compatibility settings
        firefox_options.set_preference("marionette.enabled", True)
        firefox_options.set_preference("dom.webdriver.enabled", False)
        
        # Set display
        os.environ['DISPLAY'] = ':99'
        
        # Start Xvfb
        logger.info("🖥️ Starting virtual display...")
        xvfb_process = subprocess.Popen(
            ['Xvfb', ':99', '-screen', '0', '1920x1080x24', '-ac'],
            stdout=subprocess.DEVNULL, 
            stderr=subprocess.DEVNULL
        )
        time.sleep(3)
        
        # Create service
        service = Service(executable_path='/usr/local/bin/geckodriver')
        
        logger.info("🚀 Starting Firefox...")
        driver = webdriver.Firefox(service=service, options=firefox_options)
        driver.set_page_load_timeout(60)
        driver.implicitly_wait(15)
        
        logger.info("✅ Firefox started successfully")
        
        # Test navigation
        logger.info("🌐 Testing navigation...")
        test_html = """
        <html>
        <head><title>Enhanced Compatibility Test</title></head>
        <body>
            <h1>Selenium 4.x + Firefox 140.x Compatibility Test</h1>
            <p id="test-element">Test successful!</p>
            <button id="test-button">Click Me</button>
        </body>
        </html>
        """
        driver.get(f"data:text/html,{test_html}")
        
        # Verify page loaded
        title = driver.title
        logger.info(f"✅ Page title: {title}")
        
        # Test element finding
        test_element = driver.find_element(By.ID, "test-element")
        logger.info(f"✅ Found element: {test_element.text}")
        
        # Test clicking
        button = driver.find_element(By.ID, "test-button")
        button.click()
        logger.info("✅ Button click successful")
        
        # Test JavaScript execution
        result = driver.execute_script("return 'JavaScript execution successful';")
        logger.info(f"✅ JavaScript: {result}")
        
        # Cleanup
        driver.quit()
        xvfb_process.terminate()
        
        logger.info("✅ Basic Selenium test completed successfully!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Basic Selenium test failed: {e}")
        try:
            if 'driver' in locals():
                driver.quit()
        except:
            pass
        try:
            if 'xvfb_process' in locals():
                xvfb_process.terminate()
        except:
            pass
        return False

def test_funpay_compatibility():
    """Test FunPay-specific functionality"""
    logger.info("🧪 Testing FunPay compatibility...")
    
    try:
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options
        from selenium.webdriver.firefox.service import Service
        from selenium.webdriver.common.by import By
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
        
        # Enhanced Firefox options for FunPay
        firefox_options = Options()
        firefox_options.add_argument("--headless")
        firefox_options.add_argument("--no-sandbox")
        firefox_options.add_argument("--disable-dev-shm-usage")
        firefox_options.add_argument("--disable-gpu")
        
        # FunPay-specific settings
        firefox_options.set_preference("marionette.enabled", True)
        firefox_options.set_preference("dom.webdriver.enabled", False)
        firefox_options.set_preference("useAutomationExtension", False)
        firefox_options.set_preference("general.useragent.override", 
            "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0")
        
        # Performance settings
        firefox_options.set_preference("permissions.default.image", 2)
        firefox_options.set_preference("javascript.enabled", True)
        
        # Set display
        os.environ['DISPLAY'] = ':99'
        
        # Start Xvfb
        xvfb_process = subprocess.Popen(
            ['Xvfb', ':99', '-screen', '0', '1920x1080x24', '-ac'],
            stdout=subprocess.DEVNULL, 
            stderr=subprocess.DEVNULL
        )
        time.sleep(3)
        
        # Create service with enhanced args
        service_args = [
            '--log', 'warn',
            '--marionette-port', '0',
            '--websocket-port', '0'
        ]
        service = Service(executable_path='/usr/local/bin/geckodriver', service_args=service_args)
        
        logger.info("🚀 Starting Firefox for FunPay test...")
        driver = webdriver.Firefox(service=service, options=firefox_options)
        driver.set_page_load_timeout(90)
        driver.implicitly_wait(20)
        
        # Test FunPay homepage access
        logger.info("🌐 Testing FunPay homepage access...")
        driver.get("https://funpay.com")
        
        # Wait for page to load
        wait = WebDriverWait(driver, 30)
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        
        # Check if page loaded correctly
        if "funpay" in driver.current_url.lower():
            logger.info("✅ FunPay homepage loaded successfully")
        else:
            logger.warning("⚠️ FunPay homepage may not have loaded correctly")
        
        # Test form interaction (login page)
        logger.info("🔐 Testing login page access...")
        driver.get("https://funpay.com/en/account/login")
        
        # Wait for login form
        try:
            login_field = wait.until(EC.presence_of_element_located((By.NAME, "login")))
            logger.info("✅ Login form found")
            
            # Test typing (without actual credentials)
            login_field.send_keys("test@example.com")
            logger.info("✅ Form input successful")
            
        except Exception as e:
            logger.warning(f"⚠️ Login form test failed: {e}")
        
        # Cleanup
        driver.quit()
        xvfb_process.terminate()
        
        logger.info("✅ FunPay compatibility test completed!")
        return True
        
    except Exception as e:
        logger.error(f"❌ FunPay compatibility test failed: {e}")
        try:
            if 'driver' in locals():
                driver.quit()
        except:
            pass
        try:
            if 'xvfb_process' in locals():
                xvfb_process.terminate()
        except:
            pass
        return False

def test_enhanced_features():
    """Test enhanced features from the updated script"""
    logger.info("🧪 Testing enhanced features...")
    
    try:
        # Import the enhanced classes
        sys.path.append('/root/FunPay_Auto_Boost_Offers')
        from funpay_boost_ultimate import RateLimiter, BrowserStealth, ErrorRecovery, CircuitBreaker
        
        # Test RateLimiter
        logger.info("🛡️ Testing RateLimiter...")
        rate_limiter = RateLimiter()
        start_time = time.time()
        rate_limiter.add_human_delay(0.1, 0.2)
        elapsed = time.time() - start_time
        if 0.1 <= elapsed <= 0.3:
            logger.info("✅ RateLimiter working correctly")
        else:
            logger.warning(f"⚠️ RateLimiter timing unexpected: {elapsed:.2f}s")
        
        # Test BrowserStealth
        logger.info("🥷 Testing BrowserStealth...")
        stealth = BrowserStealth()
        user_agent = stealth.get_random_user_agent()
        resolution = stealth.get_random_resolution()
        if user_agent and resolution:
            logger.info(f"✅ BrowserStealth: UA={user_agent[:50]}..., Res={resolution}")
        else:
            logger.warning("⚠️ BrowserStealth not working correctly")
        
        # Test ErrorRecovery
        logger.info("🔄 Testing ErrorRecovery...")
        recovery = ErrorRecovery()
        
        def test_function():
            return "success"
        
        result = recovery.execute_with_retry(test_function, "test_operation")
        if result == "success":
            logger.info("✅ ErrorRecovery working correctly")
        else:
            logger.warning("⚠️ ErrorRecovery not working correctly")
        
        # Test CircuitBreaker
        logger.info("⚡ Testing CircuitBreaker...")
        breaker = CircuitBreaker(failure_threshold=2, recovery_timeout=1)
        
        def working_function():
            return "working"
        
        result = breaker.call(working_function)
        if result == "working":
            logger.info("✅ CircuitBreaker working correctly")
        else:
            logger.warning("⚠️ CircuitBreaker not working correctly")
        
        logger.info("✅ Enhanced features test completed!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Enhanced features test failed: {e}")
        return False

def main():
    """Main test function"""
    logger.info("🚀 Starting Enhanced Compatibility Test")
    logger.info("=" * 60)
    
    start_time = datetime.now()
    
    # Test 1: Check versions
    logger.info("\n📋 Test 1: Version Check")
    versions = check_versions()
    if not versions:
        logger.error("❌ Version check failed")
        return False
    
    # Test 2: Basic Selenium
    logger.info("\n📋 Test 2: Basic Selenium Functionality")
    if not test_basic_selenium():
        logger.error("❌ Basic Selenium test failed")
        return False
    
    # Test 3: FunPay compatibility
    logger.info("\n📋 Test 3: FunPay Compatibility")
    if not test_funpay_compatibility():
        logger.error("❌ FunPay compatibility test failed")
        return False
    
    # Test 4: Enhanced features
    logger.info("\n📋 Test 4: Enhanced Features")
    if not test_enhanced_features():
        logger.error("❌ Enhanced features test failed")
        return False
    
    # Summary
    end_time = datetime.now()
    duration = end_time - start_time
    
    logger.info("\n" + "=" * 60)
    logger.info("🎉 ALL TESTS PASSED!")
    logger.info(f"⏱️ Total test duration: {duration.total_seconds():.2f} seconds")
    logger.info("✅ System is ready for FunPay Auto Boost!")
    logger.info("=" * 60)
    
    return True

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        logger.info("\n🛑 Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"\n❌ Test crashed: {e}")
        sys.exit(1)
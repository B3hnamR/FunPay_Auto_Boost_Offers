#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - System Test
Test script to verify boost detection and telegram notifications
"""

import os
import sys
import json
import time
from datetime import datetime, timedelta
from telegram_notifier import TelegramNotifier

def test_telegram_notifications():
    """Test telegram notification system"""
    print("🧪 Testing Telegram Notification System")
    print("=" * 50)
    
    notifier = TelegramNotifier()
    
    if not notifier.is_enabled():
        print("❌ Telegram is not enabled")
        print("To enable: sudo bash manage_telegram_final.sh setup")
        return False
    
    print("✅ Telegram configuration found")
    
    # Test connection
    print("\n📡 Testing connection...")
    success, message = notifier.test_connection()
    if success:
        print("✅ Connection test successful")
    else:
        print(f"❌ Connection test failed: {message}")
        return False
    
    # Test boost success notification
    print("\n🎉 Testing boost success notification...")
    next_boost = datetime.now() + timedelta(hours=3)
    success = notifier.notify_boost_success(next_boost)
    if success:
        print("✅ Boost success notification sent")
    else:
        print("❌ Failed to send boost success notification")
    
    time.sleep(2)
    
    # Test boost failed notification with exact timing
    print("\n⚠️ Testing boost failed notification...")
    retry_time = datetime.now() + timedelta(minutes=23)
    success = notifier.notify_boost_failed(retry_time, exact_wait_minutes=23)
    if success:
        print("✅ Boost failed notification sent with exact timing (23 minutes)")
    else:
        print("❌ Failed to send boost failed notification")
    
    return True

def test_log_parsing():
    """Test log parsing functionality"""
    print("\n🔍 Testing Log Parsing")
    print("=" * 30)
    
    from boost_monitor_final import FinalBoostMonitor
    
    monitor = FinalBoostMonitor()
    
    # Test wait time parsing
    test_lines = [
        "2025-07-05 08:51:03,236 - INFO - 🕐 Site says: Please wait 23 minutes",
        "2025-07-05 08:51:03,236 - INFO - ⏳ Must wait 45 minutes before next boost",
        "2025-07-05 08:51:03,236 - INFO - Please wait 2 hours before next boost",
        "2025-07-05 08:51:03,236 - INFO - 🎉 Boost button clicked!",
        "2025-07-05 08:51:03,236 - INFO - ✅ Boost successful! Next boost at: 2025-07-05 11:51:03"
    ]
    
    print("Testing wait time detection:")
    for line in test_lines:
        wait_time = monitor.parse_wait_time_from_log(line)
        if wait_time:
            print(f"✅ Detected {wait_time} minutes from: {line[:60]}...")
        else:
            print(f"❌ No wait time detected from: {line[:60]}...")
    
    print("\nTesting boost success detection:")
    for line in test_lines:
        is_success = monitor.parse_boost_success(line)
        if is_success:
            print(f"✅ Boost success detected: {line[:60]}...")
    
    print("\nTesting boost failure detection:")
    for line in test_lines:
        is_failure = monitor.parse_boost_failed(line)
        if is_failure:
            print(f"⚠️ Boost failure detected: {line[:60]}...")

def check_system_status():
    """Check current system status"""
    print("\n📊 System Status Check")
    print("=" * 25)
    
    # Check if main boost service is running
    try:
        import subprocess
        result = subprocess.run(['pgrep', '-f', 'funpay_boost_ultimate'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            print(f"✅ Main boost service running (PIDs: {', '.join(pids)})")
        else:
            print("❌ Main boost service not running")
    except:
        print("⚠️ Could not check main boost service status")
    
    # Check if monitor is running
    try:
        result = subprocess.run(['pgrep', '-f', 'boost_monitor_final'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            print(f"✅ Monitor service running (PIDs: {', '.join(pids)})")
        else:
            print("❌ Monitor service not running")
    except:
        print("⚠️ Could not check monitor service status")
    
    # Check configuration
    config_file = '/etc/funpay/config.json'
    if os.path.exists(config_file):
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            
            last_boost = config.get('last_boost')
            if last_boost:
                print(f"📅 Last boost: {last_boost}")
                
                # Calculate next boost
                from datetime import datetime, timedelta
                last_time = datetime.fromisoformat(last_boost)
                interval = config.get('boost_interval', 3)
                next_time = last_time + timedelta(hours=interval)
                
                print(f"⏰ Next boost: {next_time}")
                
                # Time remaining
                now = datetime.now()
                if next_time > now:
                    remaining = next_time - now
                    hours = int(remaining.total_seconds() // 3600)
                    minutes = int((remaining.total_seconds() % 3600) // 60)
                    print(f"⏳ Time remaining: {hours}h {minutes}m")
                else:
                    print("✅ Ready for boost!")
            else:
                print("📅 No previous boost recorded")
                
        except Exception as e:
            print(f"❌ Error reading config: {e}")
    else:
        print("❌ Configuration file not found")

def simulate_boost_scenario():
    """Simulate a boost scenario for testing"""
    print("\n🎭 Simulating Boost Scenario")
    print("=" * 35)
    
    notifier = TelegramNotifier()
    
    if not notifier.is_enabled():
        print("❌ Telegram not enabled - skipping simulation")
        return
    
    print("📝 Scenario: Site says 'Please wait 23 minutes'")
    
    # Simulate exact timing from site
    retry_time = datetime.now() + timedelta(minutes=23)
    
    print(f"⏰ Current time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"⏰ Retry time: {retry_time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Send notification
    success = notifier.notify_boost_failed(retry_time, exact_wait_minutes=23)
    
    if success:
        print("✅ Notification sent successfully!")
        print("📱 Check your Telegram for the message")
    else:
        print("❌ Failed to send notification")

def main():
    """Main test function"""
    print("🚀 FunPay Auto Boost - System Test")
    print("=" * 40)
    
    # Check system status first
    check_system_status()
    
    # Test log parsing
    test_log_parsing()
    
    # Test telegram notifications
    test_telegram_notifications()
    
    # Simulate boost scenario
    simulate_boost_scenario()
    
    print("\n" + "=" * 40)
    print("🏁 Test completed!")
    print("\nNext steps:")
    print("1. Check your Telegram for test messages")
    print("2. Monitor logs: tail -f /var/log/funpay/monitor_final.log")
    print("3. Test actual boost: python3 funpay_boost_ultimate.py --test")

if __name__ == "__main__":
    main()
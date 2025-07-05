#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fix Timing Issues - Correct boost timing and configuration
"""

import json
import os
from datetime import datetime, timedelta

def check_and_fix_config():
    """Check and fix configuration timing issues"""
    config_file = '/etc/funpay/config.json'
    
    print("🔧 Checking and fixing timing configuration...")
    print("=" * 50)
    
    if not os.path.exists(config_file):
        print("❌ Configuration file not found!")
        return False
    
    try:
        # Read current config
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        print("📋 Current configuration:")
        print(f"   Last boost: {config.get('last_boost', 'Not set')}")
        print(f"   Boost interval: {config.get('boost_interval', 3)} hours")
        
        # Check if last_boost is in the past and needs updating
        last_boost = config.get('last_boost')
        if last_boost:
            last_time = datetime.fromisoformat(last_boost)
            now = datetime.now()
            interval_hours = config.get('boost_interval', 3)
            next_boost = last_time + timedelta(hours=interval_hours)
            
            print(f"\n📅 Time analysis:")
            print(f"   Current time: {now.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"   Last boost: {last_time.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"   Next boost: {next_boost.strftime('%Y-%m-%d %H:%M:%S')}")
            
            time_diff = (next_boost - now).total_seconds()
            
            if time_diff <= 0:
                print(f"✅ Ready for boost! (overdue by {abs(time_diff/60):.0f} minutes)")
            else:
                hours = int(time_diff // 3600)
                minutes = int((time_diff % 3600) // 60)
                print(f"⏳ Time remaining: {hours}h {minutes}m")
            
            # Ask if user wants to update timing
            print(f"\n🤔 Do you want to:")
            print(f"1. Keep current timing")
            print(f"2. Reset last boost to now (will wait {interval_hours} hours)")
            print(f"3. Set custom last boost time")
            
            choice = input("Choose option (1-3): ").strip()
            
            if choice == "2":
                # Reset to now
                config['last_boost'] = now.isoformat()
                print(f"✅ Updated last boost to current time")
                
            elif choice == "3":
                # Custom time
                print(f"Enter last boost time (format: YYYY-MM-DD HH:MM:SS)")
                print(f"Example: 2025-07-05 09:00:00")
                custom_time = input("Time: ").strip()
                
                try:
                    custom_datetime = datetime.strptime(custom_time, '%Y-%m-%d %H:%M:%S')
                    config['last_boost'] = custom_datetime.isoformat()
                    print(f"✅ Updated last boost to: {custom_time}")
                except ValueError:
                    print(f"❌ Invalid time format!")
                    return False
            
            # Save updated config
            if choice in ["2", "3"]:
                with open(config_file, 'w') as f:
                    json.dump(config, f, indent=2)
                
                # Recalculate
                last_time = datetime.fromisoformat(config['last_boost'])
                next_boost = last_time + timedelta(hours=interval_hours)
                
                print(f"\n📅 Updated timing:")
                print(f"   Last boost: {last_time.strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"   Next boost: {next_boost.strftime('%Y-%m-%d %H:%M:%S')}")
                
                time_diff = (next_boost - now).total_seconds()
                if time_diff <= 0:
                    print(f"✅ Ready for boost!")
                else:
                    hours = int(time_diff // 3600)
                    minutes = int((time_diff % 3600) // 60)
                    print(f"⏳ Time remaining: {hours}h {minutes}m")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_telegram_timing():
    """Test telegram notification with current timing"""
    print(f"\n📱 Testing Telegram notification with current timing...")
    
    try:
        from telegram_notifier import TelegramNotifier
        
        notifier = TelegramNotifier()
        
        if not notifier.is_enabled():
            print("❌ Telegram not enabled")
            return False
        
        # Test with a near-future time (4 minutes from now)
        test_time = datetime.now() + timedelta(minutes=4)
        
        print(f"🧪 Testing with time: {test_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"   (4 minutes from now)")
        
        # Test time remaining calculation
        time_remaining = notifier.calculate_time_remaining(test_time)
        print(f"⏳ Calculated remaining time: {time_remaining}")
        
        # Send test notification
        success = notifier.notify_boost_failed(test_time, exact_wait_minutes=4)
        
        if success:
            print("✅ Test notification sent successfully!")
            print("📱 Check your Telegram for the message")
        else:
            print("❌ Failed to send test notification")
        
        return success
        
    except Exception as e:
        print(f"❌ Error testing telegram: {e}")
        return False

def show_current_status():
    """Show detailed current status"""
    print(f"\n📊 Current System Status")
    print("=" * 30)
    
    # Check processes
    import subprocess
    
    try:
        # Check main boost service
        result = subprocess.run(['pgrep', '-f', 'funpay_boost_ultimate'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            print(f"🚀 Main boost service: Running (PIDs: {', '.join(pids)})")
        else:
            print(f"🚀 Main boost service: Not running")
        
        # Check monitor service
        result = subprocess.run(['pgrep', '-f', 'boost_monitor_final'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            print(f"📡 Monitor service: Running (PIDs: {', '.join(pids)})")
        else:
            print(f"📡 Monitor service: Not running")
            
    except Exception as e:
        print(f"⚠️ Could not check process status: {e}")
    
    # Check recent logs
    log_file = '/var/log/funpay/boost.log'
    if os.path.exists(log_file):
        print(f"\n📄 Recent boost log (last 3 lines):")
        try:
            with open(log_file, 'r') as f:
                lines = f.readlines()
                for line in lines[-3:]:
                    print(f"   {line.strip()}")
        except Exception as e:
            print(f"   Error reading log: {e}")
    
    monitor_log = '/var/log/funpay/monitor_final.log'
    if os.path.exists(monitor_log):
        print(f"\n📡 Recent monitor log (last 3 lines):")
        try:
            with open(monitor_log, 'r') as f:
                lines = f.readlines()
                for line in lines[-3:]:
                    print(f"   {line.strip()}")
        except Exception as e:
            print(f"   Error reading monitor log: {e}")

def main():
    """Main function"""
    print("🔧 FunPay Auto Boost - Timing Fix Tool")
    print("=" * 45)
    
    # Show current status
    show_current_status()
    
    # Check and fix config
    check_and_fix_config()
    
    # Test telegram timing
    test_telegram_timing()
    
    print(f"\n🏁 Timing fix completed!")
    print(f"\n💡 Recommendations:")
    print(f"   1. Restart monitor service: sudo bash manage_telegram_final.sh restart")
    print(f"   2. Check status: bash manage_system.sh status")
    print(f"   3. Monitor logs: tail -f /var/log/funpay/monitor_final.log")

if __name__ == "__main__":
    main()
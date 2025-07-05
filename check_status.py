#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Quick Status Check - Check current system status and timing
"""

import json
import os
from datetime import datetime, timedelta

def main():
    """Quick status check"""
    print("📊 Quick Status Check")
    print("=" * 25)
    
    # Check config
    config_file = '/etc/funpay/config.json'
    if os.path.exists(config_file):
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            
            last_boost = config.get('last_boost')
            interval = config.get('boost_interval', 3)
            
            print(f"⚙️ Configuration:")
            print(f"   Last boost: {last_boost}")
            print(f"   Interval: {interval} hours")
            
            if last_boost:
                last_time = datetime.fromisoformat(last_boost)
                now = datetime.now()
                next_boost = last_time + timedelta(hours=interval)
                
                print(f"\n🕐 Timing:")
                print(f"   Current time: {now.strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"   Last boost: {last_time.strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"   Next boost: {next_boost.strftime('%Y-%m-%d %H:%M:%S')}")
                
                diff = (next_boost - now).total_seconds()
                if diff <= 0:
                    print(f"   Status: ✅ Ready for boost! (overdue by {abs(diff/60):.0f} minutes)")
                else:
                    hours = int(diff // 3600)
                    minutes = int((diff % 3600) // 60)
                    print(f"   Status: ⏳ Waiting ({hours}h {minutes}m remaining)")
                    
        except Exception as e:
            print(f"❌ Error reading config: {e}")
    else:
        print("❌ Config file not found")
    
    # Test telegram timing calculation
    print(f"\n📱 Telegram Test:")
    try:
        from telegram_notifier import TelegramNotifier
        notifier = TelegramNotifier()
        
        if notifier.is_enabled():
            # Test with 4 minutes from now
            test_time = datetime.now() + timedelta(minutes=4)
            remaining = notifier.calculate_time_remaining(test_time)
            print(f"   Test (4 min future): {remaining}")
            
            # Test with past time
            past_time = datetime.now() - timedelta(minutes=5)
            remaining_past = notifier.calculate_time_remaining(past_time)
            print(f"   Test (5 min past): {remaining_past}")
        else:
            print("   ❌ Telegram not enabled")
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    print(f"\n💡 To fix timing issues, run:")
    print(f"   python3 fix_timing.py")

if __name__ == "__main__":
    main()
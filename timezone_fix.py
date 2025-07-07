#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Timezone Fix
اصلاح مشکل timezone و زمان‌بندی
"""

import json
import os
from datetime import datetime, timedelta
import pytz

def fix_timezone_config():
    """اصلاح مشکل timezone در کانفیگ"""
    config_file = '/etc/funpay/config.json'
    
    try:
        # خواندن کانفیگ فعلی
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        print("🔍 بررسی کانفیگ فعلی...")
        print(f"Last boost: {config.get('last_boost')}")
        
        # اطلاعات زمان فعلی
        utc_now = datetime.utcnow()
        iran_tz = pytz.timezone('Asia/Tehran')
        iran_now = utc_now.replace(tzinfo=pytz.UTC).astimezone(iran_tz)
        
        print(f"UTC time: {utc_now}")
        print(f"Iran time: {iran_now}")
        
        # اصلاح last_boost اگر نیاز باشد
        last_boost = config.get('last_boost')
        if last_boost:
            # تبدیل ��ه datetime
            if isinstance(last_boost, str):
                if 'T' in last_boost and '+' not in last_boost and 'Z' not in last_boost:
                    # فرض می‌کنیم این زمان UTC است
                    last_boost_dt = datetime.fromisoformat(last_boost)
                    # تبدیل به UTC timezone-aware
                    last_boost_utc = last_boost_dt.replace(tzinfo=pytz.UTC)
                    
                    print(f"🔧 اصلاح last_boost از: {last_boost}")
                    print(f"   به UTC: {last_boost_utc.isoformat()}")
                    
                    # ذخیره با timezone
                    config['last_boost'] = last_boost_utc.isoformat()
                    
                    # محاسبه next boost
                    interval = config.get('boost_interval', 3)
                    next_boost_utc = last_boost_utc + timedelta(hours=interval)
                    next_boost_iran = next_boost_utc.astimezone(iran_tz)
                    
                    print(f"   Next boost UTC: {next_boost_utc}")
                    print(f"   Next boost Iran: {next_boost_iran}")
        
        # ذخیره کانفیگ اصلاح شده
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        print("✅ کانفیگ اصلاح شد!")
        return True
        
    except Exception as e:
        print(f"❌ خطا در اصلاح کانفیگ: {e}")
        return False

def test_timezone_conversion():
    """تست تبدیل timezone"""
    print("\n🧪 تست تبدیل timezone...")
    
    # زمان فعلی
    utc_now = datetime.utcnow()
    iran_tz = pytz.timezone('Asia/Tehran')
    
    # تبدیل UTC به ایران
    utc_aware = utc_now.replace(tzinfo=pytz.UTC)
    iran_time = utc_aware.astimezone(iran_tz)
    
    print(f"UTC: {utc_now}")
    print(f"Iran: {iran_time}")
    print(f"Difference: {iran_time.utcoffset()}")
    
    # تست با زمان ذخیره شده
    test_time = "2025-07-07T05:05:22"
    test_dt = datetime.fromisoformat(test_time)
    test_utc = test_dt.replace(tzinfo=pytz.UTC)
    test_iran = test_utc.astimezone(iran_tz)
    
    print(f"\nتست با زمان ذخیره شده:")
    print(f"Original: {test_time}")
    print(f"As UTC: {test_utc}")
    print(f"As Iran: {test_iran}")

def fix_current_timing():
    """اصلاح زمان‌بندی فعلی بر اساس 'Please wait 2 hours'"""
    config_file = '/etc/funpay/config.json'
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        print("\n🔧 اصلاح زمان‌بندی بر اساس 'Please wait 2 hours'...")
        
        # زمان فعلی UTC
        utc_now = datetime.utcnow().replace(tzinfo=pytz.UTC)
        iran_tz = pytz.timezone('Asia/Tehran')
        iran_now = utc_now.astimezone(iran_tz)
        
        print(f"زمان فعلی UTC: {utc_now}")
        print(f"زمان فعلی ایران: {iran_now}")
        
        # اگر سایت گفته 2 ساعت صبر کن، یعنی boost 2 ساعت پیش انجام شده
        # پس last_boost باید 2 ساعت پیش باشد
        actual_boost_time_utc = utc_now - timedelta(hours=2)
        
        print(f"زمان واقعی boost (2 ساعت پیش): {actual_boost_time_utc}")
        print(f"زمان واقعی boost (ایران): {actual_boost_time_utc.astimezone(iran_tz)}")
        
        # محاسبه next boost (3 ساعت بعد از actual boost)
        interval = config.get('boost_interval', 3)
        next_boost_utc = actual_boost_time_utc + timedelta(hours=interval)
        next_boost_iran = next_boost_utc.astimezone(iran_tz)
        
        print(f"Next boost UTC: {next_boost_utc}")
        print(f"Next boost Iran: {next_boost_iran}")
        
        # زمان باقی‌مانده
        remaining = next_boost_utc - utc_now
        hours = int(remaining.total_seconds() // 3600)
        minutes = int((remaining.total_seconds() % 3600) // 60)
        
        print(f"زمان باقی‌مانده: {hours}h {minutes}m")
        
        # به‌روزرسانی کانفیگ
        config['last_boost'] = actual_boost_time_utc.isoformat()
        
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        print("✅ زمان‌بندی اصلاح شد!")
        
        return {
            'last_boost_utc': actual_boost_time_utc,
            'next_boost_utc': next_boost_utc,
            'next_boost_iran': next_boost_iran,
            'remaining_hours': hours,
            'remaining_minutes': minutes
        }
        
    except Exception as e:
        print(f"❌ خطا در اصلاح زمان‌بندی: {e}")
        return None

def main():
    """تابع اصلی"""
    print("╔═══════════════════════════════════���══════════════════════════╗")
    print("║                    FunPay Timezone Fix                      ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    # تست timezone
    test_timezone_conversion()
    
    # اصلاح کانفیگ
    fix_timezone_config()
    
    # اصلاح زمان‌بندی فعلی
    result = fix_current_timing()
    
    if result:
        print(f"\n📊 خلاصه اصلاحات:")
        print(f"   Last boost: {result['last_boost_utc'].strftime('%Y-%m-%d %H:%M:%S')} UTC")
        print(f"   Next boost: {result['next_boost_iran'].strftime('%Y-%m-%d %H:%M:%S')} Iran")
        print(f"   Remaining: {result['remaining_hours']}h {result['remaining_minutes']}m")

if __name__ == "__main__":
    main()
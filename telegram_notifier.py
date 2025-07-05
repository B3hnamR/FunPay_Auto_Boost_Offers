#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Telegram Notifier
Telegram notification module for boost alerts
"""

import json
import requests
import logging
from datetime import datetime, timedelta
import pytz
import os

class TelegramNotifier:
    def __init__(self, config_file='telegram_config.json'):
        self.config_file = config_file
        self.config = {}
        self.logger = logging.getLogger(__name__)
        self.load_config()
    
    def load_config(self):
        """Load telegram configuration"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    self.config = json.load(f)
                self.logger.info("Telegram configuration loaded")
            else:
                self.logger.warning("Telegram configuration file not found")
                self.config = {"enabled": False}
        except Exception as e:
            self.logger.error(f"Error loading telegram configuration: {e}")
            self.config = {"enabled": False}
    
    def save_config(self):
        """Save telegram configuration"""
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            self.logger.error(f"Error saving telegram configuration: {e}")
            return False
    
    def is_enabled(self):
        """Check if notification is enabled"""
        return self.config.get('enabled', False) and \
               self.config.get('bot_token') and \
               self.config.get('chat_id')
    
    def convert_to_iran_time(self, utc_time):
        """Convert time to Iran timezone with detailed formatting"""
        try:
            if isinstance(utc_time, str):
                utc_time = datetime.fromisoformat(utc_time)
            
            # If no timezone, assume local time
            if utc_time.tzinfo is None:
                # Assume it's already local time (Iran time)
                iran_tz = pytz.timezone('Asia/Tehran')
                utc_time = iran_tz.localize(utc_time)
            
            # Convert to Iran time
            iran_tz = pytz.timezone('Asia/Tehran')
            iran_time = utc_time.astimezone(iran_tz)
            
            return iran_time.strftime('%Y-%m-%d %H:%M:%S')
        except Exception as e:
            self.logger.error(f"Error converting time: {e}")
            return str(utc_time)
    
    def calculate_time_remaining(self, target_time):
        """Calculate remaining time until target"""
        try:
            if isinstance(target_time, str):
                target_time = datetime.fromisoformat(target_time)
            
            # If no timezone, assume local time
            if target_time.tzinfo is None:
                iran_tz = pytz.timezone('Asia/Tehran')
                target_time = iran_tz.localize(target_time)
            
            # Current time in Iran
            iran_tz = pytz.timezone('Asia/Tehran')
            now = datetime.now(iran_tz)
            
            # Calculate difference
            diff = target_time - now
            
            if diff.total_seconds() <= 0:
                return "آماده برای boost"
            
            total_minutes = int(diff.total_seconds() / 60)
            hours = total_minutes // 60
            minutes = total_minutes % 60
            
            if hours > 0:
                return f"{hours} ساعت و {minutes} دقیقه"
            else:
                return f"{minutes} دقیقه"
                
        except Exception as e:
            self.logger.error(f"Error calculating time remaining: {e}")
            return "نامشخص"
    
    def send_message(self, message):
        """Send message to telegram"""
        if not self.is_enabled():
            self.logger.debug("Telegram notification is disabled")
            return False
        
        try:
            bot_token = self.config['bot_token']
            chat_id = self.config['chat_id']
            
            url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            
            data = {
                'chat_id': chat_id,
                'text': message,
                'parse_mode': 'HTML'
            }
            
            response = requests.post(url, data=data, timeout=10)
            
            if response.status_code == 200:
                self.logger.info("Telegram message sent successfully")
                return True
            else:
                self.logger.error(f"Error sending telegram message: {response.status_code}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error sending telegram message: {e}")
            return False
    
    def notify_boost_success(self, next_boost_time):
        """Notify successful boost with detailed timing"""
        try:
            # Convert next boost time to Iran time
            iran_time = self.convert_to_iran_time(next_boost_time)
            time_remaining = self.calculate_time_remaining(next_boost_time)
            current_time = self.convert_to_iran_time(datetime.now())
            
            # Enhanced message with more details
            message = f"🎉 <b>Boost موفقیت‌آمیز انجام شد!</b>\n\n"
            message += f"📅 <b>زمان فعلی:</b> {current_time}\n"
            message += f"⏰ <b>Boost بعدی:</b> {iran_time}\n"
            message += f"⏳ <b>زمان باقی‌مانده:</b> {time_remaining}\n\n"
            message += f"✅ سیستم به طور خودکار در زمان مقرر boost بعدی را انجام خواهد داد"
            
            return self.send_message(message)
            
        except Exception as e:
            self.logger.error(f"Error notifying boost success: {e}")
            return False
    
    def notify_boost_failed(self, retry_time, exact_wait_minutes=None):
        """Notify boost failure with exact timing"""
        try:
            iran_time = self.convert_to_iran_time(retry_time)
            time_remaining = self.calculate_time_remaining(retry_time)
            current_time = self.convert_to_iran_time(datetime.now())
            
            # Enhanced message with exact timing
            message = f"⚠️ <b>Boost در انتظار است</b>\n\n"
            message += f"📅 <b>زمان فعلی:</b> {current_time}\n"
            
            if exact_wait_minutes:
                message += f"🕐 <b>سایت گفته:</b> {exact_wait_minutes} دقیقه صبر کنید\n"
            
            message += f"⏰ <b>تلاش مجدد:</b> {iran_time}\n"
            message += f"⏳ <b>زمان باقی‌مانده:</b> {time_remaining}\n\n"
            
            if exact_wait_minutes and exact_wait_minutes <= 30:
                message += f"🎯 زمان انتظار کوتاه است - به زودی boost انجام می‌شود"
            else:
                message += f"💤 سیستم منتظر می‌ماند و در زمان مقرر تلاش خواهد کرد"
            
            return self.send_message(message)
            
        except Exception as e:
            self.logger.error(f"Error notifying boost failure: {e}")
            return False
    
    def notify_service_started(self):
        """Notify service started"""
        try:
            message = self.config.get('messages', {}).get(
                'service_started',
                "🚀 FunPay Auto Boost service started"
            )
            
            # Add current time
            current_time = self.convert_to_iran_time(datetime.now())
            message += f"\n🕐 Time: {current_time}"
            
            return self.send_message(message)
            
        except Exception as e:
            self.logger.error(f"Error notifying service started: {e}")
            return False
    
    def notify_service_stopped(self):
        """Notify service stopped"""
        try:
            message = self.config.get('messages', {}).get(
                'service_stopped',
                "🛑 FunPay Auto Boost service stopped"
            )
            
            # Add current time
            current_time = self.convert_to_iran_time(datetime.now())
            message += f"\n🕐 Time: {current_time}"
            
            return self.send_message(message)
            
        except Exception as e:
            self.logger.error(f"Error notifying service stopped: {e}")
            return False
    
    def test_connection(self):
        """Test telegram connection"""
        if not self.is_enabled():
            return False, "Telegram configuration is incomplete"
        
        try:
            test_message = f"🧪 Telegram connection test\n🕐 Time: {self.convert_to_iran_time(datetime.now())}"
            
            if self.send_message(test_message):
                return True, "Connection successful"
            else:
                return False, "Error sending message"
                
        except Exception as e:
            return False, f"Error: {e}"

def main():
    """Test module"""
    notifier = TelegramNotifier()
    
    print("🧪 Testing Telegram notification module")
    print("=" * 40)
    
    if notifier.is_enabled():
        print("✅ Telegram configuration is active")
        
        # Test connection
        success, message = notifier.test_connection()
        if success:
            print("✅ Connection test successful")
        else:
            print(f"❌ Connection test failed: {message}")
    else:
        print("❌ Telegram configuration is disabled or incomplete")
        print("To enable, use setup command:")
        print("python3 telegram_setup.py")

if __name__ == "__main__":
    main()
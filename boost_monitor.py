#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Monitor
Log monitoring and telegram notification sender
"""

import os
import time
import json
import re
from datetime import datetime, timedelta
from telegram_notifier import TelegramNotifier
import logging

class BoostMonitor:
    def __init__(self):
        self.notifier = TelegramNotifier()
        self.log_file = '/var/log/funpay/boost.log'
        self.last_position = 0
        self.last_boost_time = None
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/funpay/monitor.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def get_file_size(self):
        """Get log file size"""
        try:
            return os.path.getsize(self.log_file)
        except:
            return 0
    
    def read_new_lines(self):
        """Read new lines from log file"""
        try:
            current_size = self.get_file_size()
            
            if current_size < self.last_position:
                # Log file was reset
                self.last_position = 0
            
            if current_size == self.last_position:
                return []
            
            with open(self.log_file, 'r', encoding='utf-8') as f:
                f.seek(self.last_position)
                new_lines = f.readlines()
                self.last_position = f.tell()
            
            return new_lines
            
        except Exception as e:
            self.logger.error(f"Error reading log file: {e}")
            return []
    
    def parse_boost_success(self, line):
        """Detect successful boost from log"""
        patterns = [
            r'Boost successful',
            r'🎉 Boost button clicked',
            r'✅ Boost successful'
        ]
        
        for pattern in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def parse_boost_failed(self, line):
        """Detect boost failure from log"""
        patterns = [
            r'Boost.*failed',
            r'Error.*boost',
            r'❌.*boost',
            r'Authentication failed'
        ]
        
        for pattern in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def get_next_boost_time(self):
        """Calculate next boost time"""
        try:
            # Read configuration
            with open('/etc/funpay/config.json', 'r') as f:
                config = json.load(f)
            
            last_boost = config.get('last_boost')
            interval = config.get('boost_interval', 3)
            
            if last_boost:
                last_time = datetime.fromisoformat(last_boost)
                next_time = last_time + timedelta(hours=interval)
                return next_time
            else:
                return datetime.now() + timedelta(hours=interval)
                
        except Exception as e:
            self.logger.error(f"Error calculating next boost time: {e}")
            return datetime.now() + timedelta(hours=3)
    
    def process_log_lines(self, lines):
        """Process new log lines"""
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Check for successful boost
            if self.parse_boost_success(line):
                self.logger.info("Successful boost detected")
                
                # Calculate next boost time
                next_boost = self.get_next_boost_time()
                
                # Send notification
                if self.notifier.is_enabled():
                    success = self.notifier.notify_boost_success(next_boost)
                    if success:
                        self.logger.info("Boost success notification sent")
                    else:
                        self.logger.error("Error sending boost success notification")
                
                self.last_boost_time = datetime.now()
            
            # Check for boost failure
            elif self.parse_boost_failed(line):
                self.logger.warning("Boost failure detected")
                
                # Calculate retry time (usually 1 hour later)
                retry_time = datetime.now() + timedelta(hours=1)
                
                # Send notification
                if self.notifier.is_enabled():
                    success = self.notifier.notify_boost_failed(retry_time)
                    if success:
                        self.logger.info("Boost failure notification sent")
                    else:
                        self.logger.error("Error sending boost failure notification")
    
    def monitor_loop(self):
        """Main monitoring loop"""
        self.logger.info("Starting boost log monitoring")
        
        # Send monitoring start notification
        if self.notifier.is_enabled():
            self.notifier.notify_service_started()
        
        try:
            while True:
                # Read new lines
                new_lines = self.read_new_lines()
                
                if new_lines:
                    self.process_log_lines(new_lines)
                
                # Wait 30 seconds
                time.sleep(30)
                
        except KeyboardInterrupt:
            self.logger.info("Monitoring stopped by user")
            
            # Send stop notification
            if self.notifier.is_enabled():
                self.notifier.notify_service_stopped()
        
        except Exception as e:
            self.logger.error(f"Error in monitoring loop: {e}")

def main():
    """Main function"""
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--daemon":
        # Run in background
        import daemon
        
        with daemon.DaemonContext():
            monitor = BoostMonitor()
            monitor.monitor_loop()
    else:
        # Run in foreground
        monitor = BoostMonitor()
        monitor.monitor_loop()

if __name__ == "__main__":
    main()
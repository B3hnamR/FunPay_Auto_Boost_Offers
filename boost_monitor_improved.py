#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Improved Monitor
Enhanced log monitoring with duplicate prevention and accurate timing
"""

import os
import time
import json
import re
from datetime import datetime, timedelta
from telegram_notifier import TelegramNotifier
import logging

class ImprovedBoostMonitor:
    def __init__(self):
        self.notifier = TelegramNotifier()
        self.log_file = '/var/log/funpay/boost.log'
        self.last_position = 0
        self.last_boost_time = None
        self.last_notification_time = None
        self.processed_lines = set()  # Track processed log lines
        self.notification_cooldown = 300  # 5 minutes cooldown between notifications
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/funpay/monitor_improved.log'),
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
                self.processed_lines.clear()
            
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
    
    def extract_timestamp_from_line(self, line):
        """Extract timestamp from log line"""
        try:
            # Pattern: 2025-07-04 19:44:00,743
            timestamp_pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})'
            match = re.search(timestamp_pattern, line)
            if match:
                timestamp_str = match.group(1)
                return datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
            return None
        except Exception as e:
            self.logger.debug(f"Error extracting timestamp: {e}")
            return None
    
    def parse_boost_success(self, line):
        """Detect successful boost from log with improved patterns"""
        success_patterns = [
            r'Boost successful',
            r'🎉 Boost button clicked',
            r'✅ Boost successful',
            r'Boost.*success',
            r'button.*clicked.*success'
        ]
        
        # Also check for specific failure indicators to avoid false positives
        failure_indicators = [
            r'wait.*before',
            r'cooldown',
            r'try.*again',
            r'failed',
            r'error'
        ]
        
        # Check for failure first
        for pattern in failure_indicators:
            if re.search(pattern, line, re.IGNORECASE):
                return False
        
        # Then check for success
        for pattern in success_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        
        return False
    
    def parse_boost_failed(self, line):
        """Detect boost failure from log"""
        failure_patterns = [
            r'wait.*before',
            r'cooldown',
            r'try.*again.*later',
            r'Authentication failed',
            r'Error.*boost',
            r'❌.*boost',
            r'must.*wait',
            r'please.*wait'
        ]
        
        for pattern in failure_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def get_accurate_next_boost_time(self, boost_timestamp=None):
        """Calculate accurate next boost time"""
        try:
            # Read configuration
            with open('/etc/funpay/config.json', 'r') as f:
                config = json.load(f)
            
            interval_hours = config.get('boost_interval', 3)
            
            # Use provided timestamp or current time
            if boost_timestamp:
                base_time = boost_timestamp
            else:
                last_boost = config.get('last_boost')
                if last_boost:
                    base_time = datetime.fromisoformat(last_boost)
                else:
                    base_time = datetime.now()
            
            # Calculate next boost time
            next_time = base_time + timedelta(hours=interval_hours)
            
            self.logger.info(f"Calculated next boost: {next_time} (base: {base_time}, interval: {interval_hours}h)")
            return next_time
                
        except Exception as e:
            self.logger.error(f"Error calculating next boost time: {e}")
            return datetime.now() + timedelta(hours=3)
    
    def should_send_notification(self, line_content, line_timestamp):
        """Check if notification should be sent (prevent duplicates)"""
        try:
            # Create unique identifier for this log entry
            line_hash = hash(line_content.strip())
            
            # Check if we've already processed this exact line
            if line_hash in self.processed_lines:
                self.logger.debug("Skipping duplicate log line")
                return False
            
            # Check cooldown period
            if self.last_notification_time:
                time_since_last = (datetime.now() - self.last_notification_time).total_seconds()
                if time_since_last < self.notification_cooldown:
                    self.logger.debug(f"Notification cooldown active ({time_since_last:.0f}s < {self.notification_cooldown}s)")
                    return False
            
            # Check if this boost is too close to the last one (prevent rapid-fire notifications)
            if line_timestamp and self.last_boost_time:
                time_diff = (line_timestamp - self.last_boost_time).total_seconds()
                if time_diff < 60:  # Less than 1 minute apart
                    self.logger.debug(f"Boost too close to previous one ({time_diff:.0f}s)")
                    return False
            
            # Add to processed lines
            self.processed_lines.add(line_hash)
            
            # Clean old processed lines (keep only last 1000)
            if len(self.processed_lines) > 1000:
                # Remove oldest 200 entries
                old_lines = list(self.processed_lines)[:200]
                for old_line in old_lines:
                    self.processed_lines.discard(old_line)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error checking notification eligibility: {e}")
            return True  # Default to sending if unsure
    
    def update_config_last_boost(self, boost_time):
        """Update last boost time in config"""
        try:
            with open('/etc/funpay/config.json', 'r') as f:
                config = json.load(f)
            
            config['last_boost'] = boost_time.isoformat()
            
            with open('/etc/funpay/config.json', 'w') as f:
                json.dump(config, f, indent=2)
            
            self.logger.info(f"Updated config last_boost to: {boost_time}")
            
        except Exception as e:
            self.logger.error(f"Error updating config: {e}")
    
    def process_log_lines(self, lines):
        """Process new log lines with improved logic"""
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Extract timestamp from line
            line_timestamp = self.extract_timestamp_from_line(line)
            
            # Check for successful boost
            if self.parse_boost_success(line):
                self.logger.info(f"Potential boost success detected: {line[:100]}...")
                
                # Check if we should send notification
                if self.should_send_notification(line, line_timestamp):
                    self.logger.info("Sending boost success notification")
                    
                    # Use line timestamp if available, otherwise current time
                    boost_time = line_timestamp if line_timestamp else datetime.now()
                    
                    # Calculate accurate next boost time
                    next_boost = self.get_accurate_next_boost_time(boost_time)
                    
                    # Update config
                    self.update_config_last_boost(boost_time)
                    
                    # Send notification
                    if self.notifier.is_enabled():
                        success = self.notifier.notify_boost_success(next_boost)
                        if success:
                            self.logger.info("Boost success notification sent successfully")
                            self.last_notification_time = datetime.now()
                            self.last_boost_time = boost_time
                        else:
                            self.logger.error("Failed to send boost success notification")
                else:
                    self.logger.debug("Notification skipped (duplicate or cooldown)")
            
            # Check for boost failure
            elif self.parse_boost_failed(line):
                self.logger.warning(f"Boost failure detected: {line[:100]}...")
                
                # Check if we should send notification (with shorter cooldown for failures)
                if self.should_send_notification(line, line_timestamp):
                    # Calculate retry time (usually 3 hours based on site message)
                    retry_time = datetime.now() + timedelta(hours=3)
                    
                    # Send notification
                    if self.notifier.is_enabled():
                        success = self.notifier.notify_boost_failed(retry_time)
                        if success:
                            self.logger.info("Boost failure notification sent")
                            self.last_notification_time = datetime.now()
                        else:
                            self.logger.error("Failed to send boost failure notification")
    
    def monitor_loop(self):
        """Main monitoring loop"""
        self.logger.info("Starting improved boost log monitoring")
        
        # Send monitoring start notification
        if self.notifier.is_enabled():
            self.notifier.notify_service_started()
        
        try:
            while True:
                # Read new lines
                new_lines = self.read_new_lines()
                
                if new_lines:
                    self.logger.debug(f"Processing {len(new_lines)} new log lines")
                    self.process_log_lines(new_lines)
                
                # Wait 15 seconds (more frequent checking)
                time.sleep(15)
                
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
        try:
            import daemon
            with daemon.DaemonContext():
                monitor = ImprovedBoostMonitor()
                monitor.monitor_loop()
        except ImportError:
            # Fallback if daemon module not available
            monitor = ImprovedBoostMonitor()
            monitor.monitor_loop()
    else:
        # Run in foreground
        monitor = ImprovedBoostMonitor()
        monitor.monitor_loop()

if __name__ == "__main__":
    main()
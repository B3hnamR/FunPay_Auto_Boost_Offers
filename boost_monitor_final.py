#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Final Monitor
Ultimate log monitoring with advanced duplicate prevention and network error handling
"""

import os
import time
import json
import re
import hashlib
from datetime import datetime, timedelta
from telegram_notifier import TelegramNotifier
import logging

class FinalBoostMonitor:
    def __init__(self):
        self.notifier = TelegramNotifier()
        self.log_file = '/var/log/funpay/boost.log'
        self.last_position = 0
        self.last_boost_time = None
        self.last_notification_time = None
        self.processed_events = {}  # Track processed events with timestamps
        self.notification_cooldown = 180  # 3 minutes cooldown between notifications
        self.event_window = 300  # 5 minutes window for grouping similar events
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/funpay/monitor_final.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Load state
        self.load_state()
    
    def load_state(self):
        """Load previous state to prevent duplicates after restart"""
        try:
            state_file = '/tmp/boost_monitor_state.json'
            if os.path.exists(state_file):
                with open(state_file, 'r') as f:
                    state = json.load(f)
                    self.last_notification_time = datetime.fromisoformat(state.get('last_notification_time', '2000-01-01T00:00:00'))
                    self.last_boost_time = datetime.fromisoformat(state.get('last_boost_time', '2000-01-01T00:00:00')) if state.get('last_boost_time') else None
                    self.logger.info(f"State loaded: last notification at {self.last_notification_time}")
        except Exception as e:
            self.logger.warning(f"Could not load state: {e}")
            self.last_notification_time = datetime.now() - timedelta(hours=1)
    
    def save_state(self):
        """Save current state"""
        try:
            state_file = '/tmp/boost_monitor_state.json'
            state = {
                'last_notification_time': self.last_notification_time.isoformat() if self.last_notification_time else None,
                'last_boost_time': self.last_boost_time.isoformat() if self.last_boost_time else None
            }
            with open(state_file, 'w') as f:
                json.dump(state, f)
        except Exception as e:
            self.logger.warning(f"Could not save state: {e}")
    
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
                self.processed_events.clear()
                self.logger.info("Log file reset detected, clearing processed events")
            
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
            # Pattern: 2025-07-05 08:05:23,909
            timestamp_pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})'
            match = re.search(timestamp_pattern, line)
            if match:
                timestamp_str = match.group(1)
                return datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
            return None
        except Exception as e:
            self.logger.debug(f"Error extracting timestamp: {e}")
            return None
    
    def is_network_error(self, line):
        """Check if line contains network error"""
        network_error_patterns = [
            r'HTTPConnectionPool',
            r'Connection.*refused',
            r'Network.*error',
            r'Timeout.*error',
            r'DNS.*error'
        ]
        
        for pattern in network_error_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def parse_boost_success(self, line):
        """Detect successful boost from log with strict filtering"""
        # Skip network errors
        if self.is_network_error(line):
            return False
        
        # Only look for very specific success patterns
        success_patterns = [
            r'🎉 Boost button clicked!',
            r'✅ Boost successful! Next boost at:'
        ]
        
        # Exclude false positives
        false_positive_patterns = [
            r'Potential boost success detected',  # Our own detection messages
            r'wait.*before',
            r'cooldown',
            r'try.*again',
            r'failed',
            r'error'
        ]
        
        # Check for false positives first
        for pattern in false_positive_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return False
        
        # Then check for success
        for pattern in success_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        
        return False
    
    def parse_boost_failed(self, line):
        """Detect boost failure from log and extract exact wait time"""
        # Skip network errors (they're not boost failures)
        if self.is_network_error(line):
            return False
        
        failure_patterns = [
            r'wait.*before.*boost',
            r'cooldown.*boost',
            r'try.*again.*later',
            r'must.*wait.*hours',
            r'please.*wait.*hours',
            r'⏳.*wait.*before',
            r'please wait (\d+) minutes?',
            r'wait (\d+) minutes?'
        ]
        
        for pattern in failure_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def parse_wait_time_from_log(self, line):
        """Parse exact wait time from log line with enhanced patterns"""
        try:
            import re
            
            # Enhanced patterns to match exact wait times from site
            wait_patterns = [
                # English patterns - exact matches
                r'please wait (\d+) minutes?',
                r'wait (\d+) minutes?',
                r'try again in (\d+) minutes?',
                r'cooldown.*?(\d+).*?minutes?',
                r'boost.*?available.*?(\d+).*?minutes?',
                r'next.*?boost.*?(\d+).*?minutes?',
                
                # Persian/Russian patterns
                r'подожди (\d+) минут',
                r'через (\d+) минут',
                
                # Generic patterns
                r'(\d+)\s*minutes?\s*remaining',
                r'(\d+)\s*min\s*left',
                r'available.*?(\d+).*?minutes?'
            ]
            
            # Look for minute patterns first
            for pattern in wait_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    wait_minutes = int(match.group(1))
                    self.logger.info(f"🕐 Detected exact wait time: {wait_minutes} minutes from: {line[:100]}...")
                    return wait_minutes
            
            # Look for hour patterns
            hour_patterns = [
                r'please wait (\d+) hours?',
                r'wait (\d+) hours?',
                r'try again in (\d+) hours?',
                r'подожди (\d+) час',
                r'через (\d+) час',
                r'(\d+)\s*hours?\s*remaining',
                r'(\d+)\s*hr\s*left'
            ]
            
            for pattern in hour_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    wait_hours = int(match.group(1))
                    wait_minutes = wait_hours * 60
                    self.logger.info(f"🕐 Detected exact wait time: {wait_hours} hours ({wait_minutes} minutes) from: {line[:100]}...")
                    return wait_minutes
            
            return None
            
        except Exception as e:
            self.logger.error(f"Error parsing wait time from log: {e}")
            return None
    
    def create_event_signature(self, event_type, line_content):
        """Create unique signature for event to prevent duplicates"""
        # Use event type and a hash of relevant content
        content_hash = hashlib.md5(line_content.encode()).hexdigest()[:8]
        return f"{event_type}_{content_hash}"
    
    def should_process_event(self, event_signature, event_time):
        """Check if event should be processed (advanced duplicate prevention)"""
        now = datetime.now()
        
        # Clean old events (older than event window)
        cutoff_time = now - timedelta(seconds=self.event_window)
        old_events = [sig for sig, time in self.processed_events.items() if time < cutoff_time]
        for old_event in old_events:
            del self.processed_events[old_event]
        
        # Check if we've seen this exact event recently
        if event_signature in self.processed_events:
            self.logger.debug(f"Skipping duplicate event: {event_signature}")
            return False
        
        # Check global cooldown
        if self.last_notification_time:
            time_since_last = (now - self.last_notification_time).total_seconds()
            if time_since_last < self.notification_cooldown:
                self.logger.info(f"Global cooldown active: {time_since_last:.0f}s < {self.notification_cooldown}s")
                return False
        
        # Record this event
        self.processed_events[event_signature] = now
        return True
    
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
            
            self.logger.info(f"Next boost calculated: {next_time} (base: {base_time}, interval: {interval_hours}h)")
            return next_time
                
        except Exception as e:
            self.logger.error(f"Error calculating next boost time: {e}")
            return datetime.now() + timedelta(hours=3)
    
    def update_config_last_boost(self, boost_time):
        """Update last boost time in config"""
        try:
            with open('/etc/funpay/config.json', 'r') as f:
                config = json.load(f)
            
            config['last_boost'] = boost_time.isoformat()
            
            with open('/etc/funpay/config.json', 'w') as f:
                json.dump(config, f, indent=2)
            
            self.logger.info(f"Config updated: last_boost = {boost_time}")
            
        except Exception as e:
            self.logger.error(f"Error updating config: {e}")
    
    def process_log_lines(self, lines):
        """Process new log lines with ultimate filtering"""
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Skip our own monitoring messages
            if 'monitor' in line.lower() and ('detected' in line.lower() or 'notification' in line.lower()):
                continue
            
            # Extract timestamp from line
            line_timestamp = self.extract_timestamp_from_line(line)
            
            # Check for successful boost
            if self.parse_boost_success(line):
                event_signature = self.create_event_signature("boost_success", line)
                
                if self.should_process_event(event_signature, line_timestamp):
                    self.logger.info(f"Processing boost success: {line[:80]}...")
                    
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
                            self.logger.info("✅ Boost success notification sent")
                            self.last_notification_time = datetime.now()
                            self.last_boost_time = boost_time
                            self.save_state()
                        else:
                            self.logger.error("❌ Failed to send boost success notification")
            
            # Check for boost failure
            elif self.parse_boost_failed(line):
                event_signature = self.create_event_signature("boost_failed", line)
                
                if self.should_process_event(event_signature, line_timestamp):
                    self.logger.warning(f"Processing boost failure: {line[:80]}...")
                    
                    # Try to extract exact wait time from the log line
                    exact_wait_minutes = self.parse_wait_time_from_log(line)
                    
                    if exact_wait_minutes:
                        # Use exact time from site
                        retry_time = datetime.now() + timedelta(minutes=exact_wait_minutes)
                        self.logger.info(f"🎯 Using exact wait time from site: {exact_wait_minutes} minutes")
                    else:
                        # Fallback to default 3 hours
                        retry_time = datetime.now() + timedelta(hours=3)
                        self.logger.info("⚠️ No exact wait time found, using default 3 hours")
                    
                    # Send notification with exact timing
                    if self.notifier.is_enabled():
                        success = self.notifier.notify_boost_failed(retry_time, exact_wait_minutes)
                        if success:
                            self.logger.info("⚠️ Boost failure notification sent with exact timing")
                            self.last_notification_time = datetime.now()
                            self.save_state()
                        else:
                            self.logger.error("❌ Failed to send boost failure notification")
    
    def monitor_loop(self):
        """Main monitoring loop"""
        self.logger.info("🚀 Starting final boost log monitoring with ultimate filtering")
        
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
                
                # Wait 20 seconds
                time.sleep(20)
                
        except KeyboardInterrupt:
            self.logger.info("Monitoring stopped by user")
            
            # Send stop notification
            if self.notifier.is_enabled():
                self.notifier.notify_service_stopped()
        
        except Exception as e:
            self.logger.error(f"Error in monitoring loop: {e}")
            time.sleep(60)  # Wait before retrying

def main():
    """Main function"""
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--daemon":
        # Run in background
        try:
            import daemon
            with daemon.DaemonContext():
                monitor = FinalBoostMonitor()
                monitor.monitor_loop()
        except ImportError:
            # Fallback if daemon module not available
            monitor = FinalBoostMonitor()
            monitor.monitor_loop()
    else:
        # Run in foreground
        monitor = FinalBoostMonitor()
        monitor.monitor_loop()

if __name__ == "__main__":
    main()
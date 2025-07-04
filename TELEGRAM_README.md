# 📱 FunPay Auto Boost Telegram Notification Guide

## 🚀 Quick Setup

### Step 1: Create Telegram Bot
1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` command
3. Choose a bot name (example: `FunPay Boost Bot`)
4. Choose a bot username (example: `funpay_boost_bot`)
5. Copy the received token

### Step 2: Get Chat ID
**Method 1 (Simple):**
1. Message [@userinfobot](https://t.me/userinfobot)
2. Send `/start` command
3. Copy your ID

**Method 2 (Manual):**
1. Send a message to your bot
2. Go to this link:
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
3. Replace `<TOKEN>` with your bot token
4. Find `chat.id` in the result

### Step 3: Setup
```bash
cd ~/FunPay_Auto_Boost_Offers
chmod +x manage_telegram.sh
sudo bash manage_telegram.sh setup
```

## 📋 Management Commands

### Initial Setup
```bash
sudo bash manage_telegram.sh setup
```

### Show Status
```bash
sudo bash manage_telegram.sh status
```

### Test Connection
```bash
sudo bash manage_telegram.sh test
```

### Start Monitoring
```bash
sudo bash manage_telegram.sh start
```

### Stop Monitoring
```bash
sudo bash manage_telegram.sh stop
```

### View Log
```bash
sudo bash manage_telegram.sh log
```

### Interactive Menu
```bash
sudo bash manage_telegram.sh
```

## 🔧 System Files

### Main Files
- `telegram_config.json` - Telegram configuration
- `telegram_notifier.py` - Message sending module
- `telegram_setup.py` - Configuration setup
- `boost_monitor.py` - Log monitoring
- `manage_telegram.sh` - Complete management script

### Log Files
- `/var/log/funpay/monitor.log` - Monitoring log
- `/var/log/funpay/monitor_output.log` - Monitor output
- `/tmp/boost_monitor.pid` - Monitor PID file

## 📱 Sample Messages

### Successful Boost
```
✅ Offers have been boosted!
📅 Next boost: 2025-07-04 22:42:44
```

### Boost Error
```
❌ Boost failed!
🔄 Retry at: 2025-07-04 20:42:44
```

### Service Started
```
🚀 FunPay Auto Boost service started
🕐 Time: 2025-07-04 19:43:01
```

## ⚙️ Advanced Configuration

### Edit Messages
Edit `telegram_config.json` file:

```json
{
  "enabled": true,
  "bot_token": "YOUR_BOT_TOKEN",
  "chat_id": "YOUR_CHAT_ID",
  "timezone": "Asia/Tehran",
  "language": "en",
  "messages": {
    "boost_success": "✅ Offers have been boosted!\n📅 Next boost: {next_boost_time}",
    "boost_failed": "❌ Boost failed!\n🔄 Retry at: {retry_time}",
    "service_started": "🚀 FunPay Auto Boost service started",
    "service_stopped": "🛑 FunPay Auto Boost service stopped"
  }
}
```

### Change Timezone
```json
"timezone": "Asia/Tehran"
```

Other timezones:
- `UTC`
- `Europe/London`
- `America/New_York`
- `Asia/Dubai`

## 🔍 Troubleshooting

### Common Issues

#### 1. Message Not Sending
```bash
# Check configuration
sudo bash manage_telegram.sh status

# Test connection
sudo bash manage_telegram.sh test
```

#### 2. Monitoring Not Working
```bash
# Check status
sudo bash manage_telegram.sh status

# Restart
sudo bash manage_telegram.sh restart
```

#### 3. Token Error
- Check bot token
- Make sure bot is active
- Verify Chat ID

#### 4. Permission Error
```bash
# Run with root access
sudo bash manage_telegram.sh
```

### View Detailed Logs
```bash
# Monitor log
tail -f /var/log/funpay/monitor.log

# Output log
tail -f /var/log/funpay/monitor_output.log

# Main boost log
tail -f /var/log/funpay/boost.log
```

## 🔒 Security

### Security Notes
1. **Keep bot token confidential**
2. **Use only your Chat ID**
3. **Limit access to configuration files**

### Restrict Access
```bash
chmod 600 telegram_config.json
chown root:root telegram_config.json
```

## 🆘 Support

### Useful Commands
```bash
# Show complete status
sudo bash manage_telegram.sh status

# Test complete system
python3 telegram_notifier.py

# Check dependencies
python3 -c "import pytz, requests; print('OK')"
```

### Important Files for Support
- `telegram_config.json`
- `/var/log/funpay/monitor.log`
- `/var/log/funpay/boost.log`

---

## 📞 Contact

If you have issues:
1. First check the troubleshooting section
2. Review the logs
3. Reconfigure the settings

**Good luck!** 🚀
# FunPay Auto Boost - Ultimate Enhanced Version

🚀 **Advanced automation tool for FunPay offer boosting with enhanced stealth, rate limiting, and error recovery**

[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://linux.org)
[![Status](https://img.shields.io/badge/Status-Active-brightgreen.svg)](https://github.com/B3hnamR/FunPay_Auto_Boost_Offers)

## ✨ Key Features

### 🛡️ Advanced Rate Limiting
- **Adaptive delays** based on activity patterns
- **Burst protection** to prevent rapid requests
- **Human-like timing** with randomization
- **Exponential backoff** for rate limit detection

### 🥷 Browser Detection Avoidance
- **Dynamic user agents** and screen resolutions
- **Fingerprint protection** against detection
- **Human behavior simulation** with realistic mouse movements
- **Anti-detection scripts** to hide automation

### 🔄 Advanced Error Recovery
- **Circuit breaker pattern** to prevent cascading failures
- **Intelligent retry logic** with exponential backoff
- **Automatic browser restart** on critical failures
- **Operation-specific recovery** strategies

### 🎯 Core Functionality
- **Automatic login** with credentials or cookies
- **Smart boost detection** with multiple selectors
- **Configurable intervals** with randomization
- **Comprehensive logging** and monitoring
- **Complete cleanup tools** for easy removal

## 🚀 Quick Start

### Prerequisites
- **OS**: Linux (Ubuntu 20.04+ recommended)
- **Python**: 3.8 or higher
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 1GB free space

### 📦 Automatic Installation

#### Method 1: Quick Setup (Recommended)
```bash
# Clone the repository
git clone https://github.com/B3hnamR/FunPay_Auto_Boost_Offers.git
cd FunPay_Auto_Boost_Offers

# Install dependencies automatically
sudo bash quick_fix.sh

# Setup and run
python3 funpay_boost_ultimate.py --setup
```

#### Method 2: Complete Installation
```bash
# For full installation with all features
sudo bash install_dependencies.sh

# Setup the service
python3 funpay_boost_ultimate.py --setup
```

#### Method 3: Manual Installation
```bash
# Install system dependencies
sudo apt update -y
sudo apt install -y python3 python3-pip firefox xvfb

# Install Python packages
sudo python3 -m pip install selenium requests beautifulsoup4 lxml

# Install GeckoDriver
sudo wget -O /tmp/geckodriver.tar.gz "https://github.com/mozilla/geckodriver/releases/download/v0.34.0/geckodriver-v0.34.0-linux64.tar.gz"
sudo tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/
sudo chmod +x /usr/local/bin/geckodriver

# Setup the service
python3 funpay_boost_ultimate.py --setup
```

### ⚙️ Configuration
```bash
# Interactive setup (first time)
python3 funpay_boost_ultimate.py --setup

# Check current status
python3 funpay_boost_ultimate.py --status

# Test functionality
python3 funpay_boost_ultimate.py --test

# Run as daemon
python3 funpay_boost_ultimate.py --daemon
```

## 📊 Enhanced Features

### Rate Limiting
- Prevents detection by controlling request frequency
- Adapts to website responses automatically
- Adds human-like randomization to all delays
- Protects against burst request patterns

### Browser Stealth
- Rotates user agents and screen resolutions
- Blocks fingerprinting techniques
- Simulates realistic human interactions
- Hides common automation indicators

### Error Recovery
- Automatically recovers from network failures
- Implements circuit breaker for stability
- Uses exponential backoff for retries
- Maintains operation state across restarts

## 🔧 Configuration Options

### Basic Configuration
```json
{
  "username": "your_email@example.com",
  "password": "your_password",
  "target_url": "https://funpay.com/en/lots/1234/trade",
  "boost_interval": 3,
  "auto_restart": true,
  "max_retries": 5
}
```

### Advanced Settings
- **Rate Limiting**: Customize delays and thresholds
- **Circuit Breaker**: Configure failure tolerance
- **Browser Stealth**: Adjust anti-detection features
- **Error Recovery**: Set retry policies

## 📈 Monitoring and Logging

### Log Levels
- **INFO**: Normal operations and status updates
- **WARNING**: Rate limiting and minor issues
- **ERROR**: Failures and recovery attempts
- **DEBUG**: Detailed stealth and timing information

### Key Metrics
- Boost success rate
- Rate limiting frequency
- Error recovery attempts
- Circuit breaker activations

## 🛠️ Advanced Usage

### Command Line Options
```bash
# Setup configuration
python3 funpay_boost_ultimate.py --setup

# Show current status
python3 funpay_boost_ultimate.py --status

# Test boost functionality
python3 funpay_boost_ultimate.py --test

# Run as daemon
python3 funpay_boost_ultimate.py --daemon
```

### 🧹 Complete Cleanup

#### Quick Cleanup
```bash
# Remove all components automatically
sudo bash cleanup_funpay.sh
```

#### Manual Cleanup
```bash
# Stop and remove service
sudo systemctl stop funpay-boost
sudo systemctl disable funpay-boost
sudo rm -f /etc/systemd/system/funpay-boost.service

# Remove directories and user
sudo rm -rf /opt/funpay-boost /etc/funpay /var/log/funpay
sudo userdel funpay

# Kill processes
sudo pkill -f "funpay\|firefox\|geckodriver\|Xvfb"
```

#### One-Line Cleanup
```bash
# Complete removal in one command
sudo systemctl stop funpay-boost && sudo systemctl disable funpay-boost && sudo rm -f /etc/systemd/system/funpay-boost.service && sudo rm -rf /opt/funpay-boost /etc/funpay /var/log/funpay /home/funpay && sudo userdel funpay 2>/dev/null && sudo pkill -9 -f "funpay\|firefox\|geckodriver\|Xvfb" && echo "✅ FunPay Auto Boost completely removed!"
```

### 📊 Monitoring and Management

#### Log Monitoring
```bash
# View live logs
tail -f /var/log/funpay/boost.log

# Check recent activity
grep "Boost successful" /var/log/funpay/boost.log | tail -10

# Monitor errors
grep "ERROR" /var/log/funpay/boost.log | tail -5
```

#### Performance Monitoring
```bash
# Check process status
ps aux | grep funpay

# Monitor resource usage
top -p $(pgrep -f funpay_boost)

# Check network connections
netstat -tulpn | grep python
```

## 🔒 Security Features

- **Credential encryption** support
- **Proxy rotation** capability
- **Log sanitization** for sensitive data
- **Rate limit compliance** with website policies

## 📋 Requirements

### System Requirements
- **OS**: Linux (Ubuntu 20.04+ recommended)
- **RAM**: 2GB minimum, 4GB recommended
- **CPU**: 1 core minimum, 2 cores recommended
- **Storage**: 1GB free space

### Software Dependencies
- **Python**: 3.8 or higher
- **Firefox**: Latest stable version
- **Geckodriver**: Compatible with Firefox version
- **Xvfb**: For headless operation

### Python Packages
- selenium
- requests
- beautifulsoup4
- lxml

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. **ModuleNotFoundError: No module named 'selenium'**
```bash
# Quick fix
sudo bash quick_fix.sh

# Or install manually
sudo python3 -m pip install selenium requests beautifulsoup4 lxml
```

#### 2. **GeckoDriver not found**
```bash
# Install GeckoDriver
sudo wget -O /tmp/geckodriver.tar.gz "https://github.com/mozilla/geckodriver/releases/download/v0.34.0/geckodriver-v0.34.0-linux64.tar.gz"
sudo tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/
sudo chmod +x /usr/local/bin/geckodriver
```

#### 3. **Firefox not starting**
```bash
# Install Firefox dependencies
sudo apt install -y firefox xvfb libgtk-3-0 libdbus-glib-1-2

# Test Firefox
xvfb-run firefox --version
```

#### 4. **Permission denied errors**
```bash
# Fix permissions
sudo chown -R $USER:$USER /path/to/FunPay_Auto_Boost_Offers
chmod +x *.sh
```

#### 5. **Rate Limiting Too Aggressive**
```python
# Edit funpay_boost_ultimate.py
# In RateLimiter class, adjust:
self.base_delay = 1.0  # Reduce base delay
self.burst_threshold = 5  # Increase threshold
```

#### 6. **Browser Detection Issues**
```bash
# Check stealth features are working
grep "stealth" /var/log/funpay/boost.log

# Verify user agent rotation
grep "user agent" /var/log/funpay/boost.log
```

#### 7. **Service won't start**
```bash
# Check service status
sudo systemctl status funpay-boost

# View detailed logs
sudo journalctl -u funpay-boost -f

# Reset service
sudo systemctl daemon-reload
sudo systemctl restart funpay-boost
```

### 🔧 Debug and Testing

#### Debug Mode
```bash
# Run with verbose logging
python3 funpay_boost_ultimate.py --daemon --debug
```

#### Test Components
```bash
# Test Selenium
python3 -c "from selenium import webdriver; print('Selenium OK')"

# Test Firefox
firefox --version

# Test GeckoDriver
geckodriver --version

# Test Xvfb
xvfb-run --help
```

#### Dependency Check
```bash
# Run dependency installer to verify
sudo bash install_dependencies.sh
```

## 📚 Documentation and Files

### 📁 Project Files
- `funpay_boost_ultimate.py` - Main application with enhanced features
- `install_dependencies.sh` - Complete dependency installation script
- `quick_fix.sh` - Quick dependency fix for common issues
- `cleanup_funpay.sh` - Complete cleanup and removal script
- `ENHANCED_FEATURES.md` - Detailed guide for new features
- `CLEANUP_COMMANDS.md` - Manual cleanup instructions

### 📖 Documentation
- [Enhanced Features Guide](ENHANCED_FEATURES.md) - Rate limiting, stealth, and error recovery
- [Cleanup Guide](CLEANUP_COMMANDS.md) - Complete removal instructions
- [Installation Troubleshooting](#-troubleshooting) - Common issues and solutions

## 🔄 Version History

### v2.0.0 - Enhanced Ultimate Version
- ✅ Advanced Rate Limiting with adaptive delays
- ✅ Browser Detection Avoidance with stealth features
- ✅ Advanced Error Recovery with circuit breaker
- ✅ Complete installation and cleanup scripts
- ✅ Enhanced logging and monitoring
- ✅ Human behavior simulation
- ✅ Automatic dependency management

### v1.0.0 - Basic Version
- ✅ Basic boost functionality
- ✅ Simple configuration
- ✅ Basic error handling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### 🐛 Bug Reports
Please include:
- OS version and Python version
- Error messages and logs
- Steps to reproduce
- Expected vs actual behavior

### 💡 Feature Requests
- Describe the feature clearly
- Explain the use case
- Consider implementation complexity

## ⚠️ Disclaimer

This tool is for **educational purposes only**. Users are responsible for:
- Complying with FunPay's terms of service
- Following applicable laws and regulations
- Using the tool responsibly and ethically

**Use at your own risk.** The developers are not responsible for any consequences of using this tool.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Selenium WebDriver team** - For the excellent automation framework
- **Firefox and GeckoDriver developers** - For reliable browser automation
- **Python community** - For amazing libraries and tools
- **Contributors and testers** - For feedback and improvements
- **Open source community** - For inspiration and best practices

## 📞 Support

### 🆘 Getting Help
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review [Enhanced Features Guide](ENHANCED_FEATURES.md)
3. Search existing [Issues](https://github.com/B3hnamR/FunPay_Auto_Boost_Offers/issues)
4. Create a new issue with detailed information

### 📈 Project Stats
- **Language**: Python 3.8+
- **Platform**: Linux (Ubuntu/Debian)
- **Dependencies**: Selenium, Firefox, GeckoDriver
- **License**: MIT
- **Status**: Active Development

---

**⭐ If this project helps you, please give it a star!**

**🔗 Share with others who might find it useful!**
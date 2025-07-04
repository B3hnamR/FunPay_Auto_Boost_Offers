# FunPay Auto Boost - Ultimate Enhanced Version

🚀 **Advanced automation tool for FunPay offer boosting with enhanced stealth, rate limiting, and error recovery**

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
- **Systemd service** integration for production use

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Firefox browser
- Geckodriver
- Linux environment (Ubuntu/Debian recommended)

### Installation
```bash
# Clone the repository
git clone https://github.com/B3hnamR/FunPay_Auto_Boost_Offers.git
cd FunPay_Auto_Boost_Offers

# Run the enhanced version
python3 funpay_boost_ultimate.py --setup
```

### Configuration
```bash
# Interactive setup
python3 funpay_boost_ultimate.py --setup

# Check status
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

### Service Management
```bash
# Install as systemd service
sudo ./install_funpay.sh

# Service commands
sudo systemctl start funpay-boost
sudo systemctl stop funpay-boost
sudo systemctl status funpay-boost

# View logs
sudo journalctl -u funpay-boost -f
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

### Common Issues

1. **Rate Limiting Too Aggressive**
   ```python
   # Adjust in RateLimiter class
   self.base_delay = 1.0  # Reduce base delay
   self.burst_threshold = 5  # Increase threshold
   ```

2. **Browser Detection**
   ```python
   # Check stealth features
   self.browser_stealth.add_stealth_scripts(driver)
   ```

3. **Recovery Failures**
   ```bash
   # Check logs for specific errors
   tail -f /var/log/funpay/boost.log
   ```

### Debug Mode
```bash
# Run with debug logging
python3 funpay_boost_ultimate.py --daemon --debug
```

## 📚 Documentation

- [Enhanced Features Guide](ENHANCED_FEATURES.md)
- [Configuration Reference](docs/configuration.md)
- [API Documentation](docs/api.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## ⚠️ Disclaimer

This tool is for educational purposes only. Users are responsible for complying with FunPay's terms of service and applicable laws. Use at your own risk.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Selenium WebDriver team
- Firefox and Geckodriver developers
- Python community for excellent libraries
- Contributors and testers

---

**⭐ If this project helps you, please give it a star!**
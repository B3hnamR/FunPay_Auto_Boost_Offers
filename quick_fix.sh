#!/bin/bash

# Quick Fix for Missing Dependencies
# This script quickly installs the essential packages needed

echo "🔧 Quick Fix: Installing essential dependencies..."

# Update package list
apt update -y

# Install Python and pip
echo "📦 Installing Python and pip..."
apt install -y python3 python3-pip python3-venv

# Install Firefox
echo "📦 Installing Firefox..."
apt install -y firefox

# Install Xvfb
echo "📦 Installing Xvfb..."
apt install -y xvfb

# Install essential Firefox dependencies
echo "📦 Installing Firefox dependencies..."
apt install -y libgtk-3-0 libdbus-glib-1-2 libxt6 libxcomposite1 libxdamage1 libxrandr2 libasound2

# Upgrade pip
echo "📦 Upgrading pip..."
python3 -m pip install --upgrade pip

# Install Python packages
echo "📦 Installing Python packages..."
python3 -m pip install selenium requests beautifulsoup4 lxml

# Install GeckoDriver
echo "📦 Installing GeckoDriver..."
wget -q -O /tmp/geckodriver.tar.gz "https://github.com/mozilla/geckodriver/releases/download/v0.34.0/geckodriver-v0.34.0-linux64.tar.gz"
tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/
chmod +x /usr/local/bin/geckodriver
rm -f /tmp/geckodriver.tar.gz

echo "✅ Quick fix completed!"
echo "Now try: python3 funpay_boost_ultimate.py --setup"
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FunPay Auto Boost - Telegram Setup
Telegram configuration setup
"""

import json
import os
from telegram_notifier import TelegramNotifier

def get_bot_token():
    """Get bot token from user"""
    print("\n" + "="*60)
    print("🤖 Telegram Bot Setup")
    print("="*60)
    print()
    print("To create a Telegram bot:")
    print("1. Message @BotFather on Telegram")
    print("2. Send /newbot command")
    print("3. Choose a bot name")
    print("4. Choose a bot username (must end with 'bot')")
    print("5. Copy the received token")
    print()
    
    while True:
        token = input("🔑 Enter Telegram bot token: ").strip()
        if token and len(token) > 20 and ':' in token:
            return token
        else:
            print("❌ Invalid token! Example: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz")

def get_chat_id():
    """Get Chat ID from user"""
    print("\n" + "="*60)
    print("💬 Get Chat ID")
    print("="*60)
    print()
    print("To get Chat ID:")
    print("1. Send a message to your bot (any message)")
    print("2. Go to this link:")
    print("   https://api.telegram.org/bot<TOKEN>/getUpdates")
    print("   (Replace <TOKEN> with your bot token)")
    print("3. Find chat.id in the result")
    print()
    print("Or:")
    print("1. Find @userinfobot on Telegram")
    print("2. Send /start")
    print("3. Copy your ID")
    print()
    
    while True:
        chat_id = input("💬 Enter Chat ID: ").strip()
        if chat_id and (chat_id.isdigit() or (chat_id.startswith('-') and chat_id[1:].isdigit())):
            return chat_id
        else:
            print("❌ Invalid Chat ID! Must be a number (example: 123456789 or -123456789)")

def setup_telegram():
    """Complete telegram setup"""
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║                Telegram Notification Setup                  ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    # Load current configuration
    notifier = TelegramNotifier()
    
    # Get bot token
    bot_token = get_bot_token()
    
    # Get Chat ID
    chat_id = get_chat_id()
    
    # Update configuration
    notifier.config.update({
        "enabled": True,
        "bot_token": bot_token,
        "chat_id": chat_id,
        "timezone": "Asia/Tehran",
        "language": "en",
        "messages": {
            "boost_success": "✅ Offers have been boosted!\n📅 Next boost: {next_boost_time}",
            "boost_failed": "❌ Boost failed!\n🔄 Retry at: {retry_time}",
            "service_started": "🚀 FunPay Auto Boost service started",
            "service_stopped": "🛑 FunPay Auto Boost service stopped"
        }
    })
    
    # Save configuration
    if notifier.save_config():
        print("\n✅ Configuration saved!")
        
        # Test connection
        print("\n🧪 Testing connection...")
        success, message = notifier.test_connection()
        
        if success:
            print("✅ Test successful! Telegram notification is now active.")
            print("\n📋 From now on:")
            print("• You will receive a message every time boost is performed")
            print("• Times are displayed in Iran timezone")
            print("• To disable: python3 telegram_setup.py --disable")
        else:
            print(f"❌ Test failed: {message}")
            print("Please check your configuration")
    else:
        print("❌ Error saving configuration!")

def disable_telegram():
    """Disable telegram notification"""
    notifier = TelegramNotifier()
    notifier.config["enabled"] = False
    
    if notifier.save_config():
        print("✅ Telegram notification disabled")
    else:
        print("❌ Error disabling notification")

def show_status():
    """Show configuration status"""
    notifier = TelegramNotifier()
    
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║                Telegram Notification Status                 ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print()
    
    if notifier.is_enabled():
        print("🟢 Status: Active")
        print(f"🤖 Bot: {notifier.config.get('bot_token', 'Unknown')[:20]}...")
        print(f"💬 Chat ID: {notifier.config.get('chat_id', 'Unknown')}")
        print(f"🌍 Timezone: {notifier.config.get('timezone', 'Unknown')}")
        
        # Test connection
        print("\n🧪 Testing connection...")
        success, message = notifier.test_connection()
        if success:
            print("✅ Connection is working")
        else:
            print(f"❌ Connection problem: {message}")
    else:
        print("🔴 Status: Disabled")
        print("💡 To enable: python3 telegram_setup.py")

def main():
    """Main function"""
    import sys
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "--disable":
            disable_telegram()
        elif sys.argv[1] == "--status":
            show_status()
        elif sys.argv[1] == "--test":
            notifier = TelegramNotifier()
            success, message = notifier.test_connection()
            print(f"Test: {'Success' if success else 'Failed'} - {message}")
        else:
            print("Usage:")
            print("  python3 telegram_setup.py           # Setup")
            print("  python3 telegram_setup.py --status  # Show status")
            print("  python3 telegram_setup.py --disable # Disable")
            print("  python3 telegram_setup.py --test    # Test connection")
    else:
        setup_telegram()

if __name__ == "__main__":
    main()
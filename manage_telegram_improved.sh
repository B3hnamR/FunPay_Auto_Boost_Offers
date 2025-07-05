#!/bin/bash

# FunPay Auto Boost Telegram Notification Management Script - Improved Version

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_PID_FILE="/tmp/boost_monitor_improved.pid"
OLD_MONITOR_PID_FILE="/tmp/boost_monitor.pid"

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Show main menu
show_menu() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}          FunPay Telegram Notification Manager (Improved)    ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Choose an option:"
    echo "1. 🔧 Setup Telegram"
    echo "2. 📊 Show Status"
    echo "3. 🧪 Test Connection"
    echo "4. 🚀 Start Improved Monitoring"
    echo "5. 🛑 Stop Monitoring"
    echo "6. 🔄 Upgrade to Improved Monitor"
    echo "7. 📄 View Monitor Log"
    echo "8. 🧹 Clean Duplicate Notifications"
    echo "9. ❌ Disable Telegram"
    echo "10. 🚪 Exit"
    echo ""
}

# Setup telegram
setup_telegram() {
    log_info "Setting up Telegram notification..."
    cd "$SCRIPT_DIR"
    python3 telegram_setup.py
}

# Show status
show_status() {
    log_info "Checking status..."
    cd "$SCRIPT_DIR"
    
    echo ""
    echo "🔍 Telegram Configuration Status:"
    python3 telegram_setup.py --status
    
    echo ""
    echo "🔍 Monitoring Status:"
    
    # Check improved monitor
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_success "Improved monitoring is running (PID: $PID)"
        else
            log_warning "Improved monitor PID file exists but process is stopped"
            rm -f "$MONITOR_PID_FILE"
        fi
    fi
    
    # Check old monitor
    if [ -f "$OLD_MONITOR_PID_FILE" ]; then
        PID=$(cat "$OLD_MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_warning "Old monitoring is still running (PID: $PID) - consider upgrading"
        else
            log_info "Cleaning up old monitor PID file"
            rm -f "$OLD_MONITOR_PID_FILE"
        fi
    fi
    
    if [ ! -f "$MONITOR_PID_FILE" ] && [ ! -f "$OLD_MONITOR_PID_FILE" ]; then
        log_warning "No monitoring is running"
    fi
    
    echo ""
    echo "📊 Recent Activity:"
    if [ -f /var/log/funpay/monitor_improved.log ]; then
        echo "Last 3 improved monitor entries:"
        tail -3 /var/log/funpay/monitor_improved.log | while read line; do
            echo "  $line"
        done
    fi
}

# Test connection
test_connection() {
    log_info "Testing Telegram connection..."
    cd "$SCRIPT_DIR"
    python3 telegram_setup.py --test
}

# Stop all monitoring
stop_all_monitoring() {
    log_info "Stopping all monitoring processes..."
    
    # Stop improved monitor
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -TERM "$PID" 2>/dev/null
            sleep 2
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -KILL "$PID" 2>/dev/null
            fi
            log_success "Improved monitoring stopped"
        fi
        rm -f "$MONITOR_PID_FILE"
    fi
    
    # Stop old monitor
    if [ -f "$OLD_MONITOR_PID_FILE" ]; then
        PID=$(cat "$OLD_MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -TERM "$PID" 2>/dev/null
            sleep 2
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -KILL "$PID" 2>/dev/null
            fi
            log_success "Old monitoring stopped"
        fi
        rm -f "$OLD_MONITOR_PID_FILE"
    fi
    
    # Kill any remaining monitor processes
    pkill -f "boost_monitor" 2>/dev/null || true
    
    log_success "All monitoring processes stopped"
}

# Start improved monitoring
start_improved_monitor() {
    log_info "Starting improved log monitoring..."
    
    # Stop any existing monitoring first
    stop_all_monitoring
    sleep 2
    
    # Create log directory
    mkdir -p /var/log/funpay
    
    cd "$SCRIPT_DIR"
    
    # Start improved monitoring in background
    nohup python3 boost_monitor_improved.py > /var/log/funpay/monitor_improved_output.log 2>&1 &
    MONITOR_PID=$!
    
    # Save PID
    echo "$MONITOR_PID" > "$MONITOR_PID_FILE"
    
    log_success "Improved monitoring started (PID: $MONITOR_PID)"
    log_info "Features:"
    echo "  • Duplicate notification prevention"
    echo "  • Accurate timing calculation"
    echo "  • Enhanced boost detection"
    echo "  • 5-minute notification cooldown"
    log_info "To view log: tail -f /var/log/funpay/monitor_improved.log"
}

# Upgrade to improved monitor
upgrade_monitor() {
    log_info "Upgrading to improved monitoring system..."
    
    echo "🔄 This will:"
    echo "  • Stop old monitoring system"
    echo "  • Start improved monitoring with:"
    echo "    - Duplicate prevention"
    echo "    - Accurate timing"
    echo "    - Better boost detection"
    echo ""
    
    read -p "Continue with upgrade? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log_info "Upgrade cancelled"
        return
    fi
    
    start_improved_monitor
    
    log_success "Upgrade completed!"
    echo ""
    echo "📋 What's improved:"
    echo "  ✅ No more duplicate notifications"
    echo "  ✅ Accurate next boost time calculation"
    echo "  ✅ Better detection of boost success/failure"
    echo "  ✅ 5-minute cooldown between notifications"
    echo "  ✅ Enhanced logging"
}

# View log
view_log() {
    log_info "Viewing monitor logs..."
    
    echo ""
    echo "📄 Improved Monitor Log (last 15 lines):"
    echo "========================================"
    if [ -f /var/log/funpay/monitor_improved.log ]; then
        tail -15 /var/log/funpay/monitor_improved.log
        echo ""
        echo "💡 For live view: tail -f /var/log/funpay/monitor_improved.log"
    else
        log_warning "Improved monitor log not found"
    fi
    
    echo ""
    echo "📄 Old Monitor Log (last 10 lines):"
    echo "===================================="
    if [ -f /var/log/funpay/monitor.log ]; then
        tail -10 /var/log/funpay/monitor.log
    else
        log_info "Old monitor log not found"
    fi
}

# Clean duplicate notifications
clean_duplicates() {
    log_info "Cleaning up duplicate notification tracking..."
    
    # Restart monitoring to clear processed lines cache
    if [ -f "$MONITOR_PID_FILE" ]; then
        log_info "Restarting improved monitor to clear cache..."
        stop_all_monitoring
        sleep 2
        start_improved_monitor
        log_success "Monitor restarted with clean cache"
    else
        log_info "No active monitor to restart"
    fi
}

# Disable telegram
disable_telegram() {
    log_warning "Disabling Telegram notification..."
    
    read -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "$SCRIPT_DIR"
        python3 telegram_setup.py --disable
        stop_all_monitoring
        log_success "Telegram notification disabled and monitoring stopped"
    else
        log_info "Operation cancelled"
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing required dependencies..."
    
    # Install pytz for timezone conversion
    python3 -c "import pytz" 2>/dev/null
    if [ $? -ne 0 ]; then
        log_info "Installing pytz..."
        pip3 install pytz
    fi
    
    # Install requests
    python3 -c "import requests" 2>/dev/null
    if [ $? -ne 0 ]; then
        log_info "Installing requests..."
        pip3 install requests
    fi
    
    log_success "Dependencies checked"
}

# Main function
main() {
    # Check root access
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with root access"
        echo "Usage: sudo bash $0"
        exit 1
    fi
    
    # Install dependencies
    install_dependencies
    
    # Process command line arguments
    case "${1:-menu}" in
        "setup")
            setup_telegram
            ;;
        "status")
            show_status
            ;;
        "test")
            test_connection
            ;;
        "start")
            start_improved_monitor
            ;;
        "stop")
            stop_all_monitoring
            ;;
        "restart")
            stop_all_monitoring
            sleep 2
            start_improved_monitor
            ;;
        "upgrade")
            upgrade_monitor
            ;;
        "log")
            view_log
            ;;
        "clean")
            clean_duplicates
            ;;
        "disable")
            disable_telegram
            ;;
        "menu")
            while true; do
                show_menu
                read -p "Your choice (1-10): " choice
                
                case $choice in
                    1) setup_telegram ;;
                    2) show_status ;;
                    3) test_connection ;;
                    4) start_improved_monitor ;;
                    5) stop_all_monitoring ;;
                    6) upgrade_monitor ;;
                    7) view_log ;;
                    8) clean_duplicates ;;
                    9) disable_telegram ;;
                    10) 
                        log_info "Exiting..."
                        exit 0
                        ;;
                    *)
                        log_error "Invalid choice!"
                        ;;
                esac
                
                echo ""
                read -p "Press Enter to continue..."
                clear
            done
            ;;
        *)
            echo "Usage:"
            echo "  $0 setup     # Setup Telegram"
            echo "  $0 status    # Show status"
            echo "  $0 test      # Test connection"
            echo "  $0 start     # Start improved monitoring"
            echo "  $0 stop      # Stop all monitoring"
            echo "  $0 restart   # Restart improved monitoring"
            echo "  $0 upgrade   # Upgrade to improved monitor"
            echo "  $0 log       # View logs"
            echo "  $0 clean     # Clean duplicate cache"
            echo "  $0 disable   # Disable Telegram"
            echo "  $0 menu      # Interactive menu (default)"
            ;;
    esac
}

# Run main function
main "$@"
#!/bin/bash

# FunPay Auto Boost Telegram Notification Management Script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_PID_FILE="/tmp/boost_monitor.pid"

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
    echo -e "${BLUE}║${WHITE}              FunPay Telegram Notification Manager           ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Choose an option:"
    echo "1. 🔧 Setup Telegram"
    echo "2. 📊 Show Status"
    echo "3. 🧪 Test Connection"
    echo "4. 🚀 Start Monitoring"
    echo "5. 🛑 Stop Monitoring"
    echo "6. 📄 View Monitor Log"
    echo "7. ❌ Disable Telegram"
    echo "8. 🚪 Exit"
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
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_success "Monitoring is running (PID: $PID)"
        else
            log_warning "PID file exists but process is stopped"
            rm -f "$MONITOR_PID_FILE"
        fi
    else
        log_warning "Monitoring is not running"
    fi
}

# Test connection
test_connection() {
    log_info "Testing Telegram connection..."
    cd "$SCRIPT_DIR"
    python3 telegram_setup.py --test
}

# Start monitoring
start_monitor() {
    log_info "Starting log monitoring..."
    
    # Check if already running
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_warning "Monitoring is already running (PID: $PID)"
            return
        else
            rm -f "$MONITOR_PID_FILE"
        fi
    fi
    
    # Create log directory
    mkdir -p /var/log/funpay
    
    cd "$SCRIPT_DIR"
    
    # Start monitoring in background
    nohup python3 boost_monitor.py > /var/log/funpay/monitor_output.log 2>&1 &
    MONITOR_PID=$!
    
    # Save PID
    echo "$MONITOR_PID" > "$MONITOR_PID_FILE"
    
    log_success "Monitoring started (PID: $MONITOR_PID)"
    log_info "To view log: tail -f /var/log/funpay/monitor.log"
}

# Stop monitoring
stop_monitor() {
    log_info "Stopping monitoring..."
    
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -TERM "$PID" 2>/dev/null
            sleep 2
            
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -KILL "$PID" 2>/dev/null
            fi
            
            log_success "Monitoring stopped"
        else
            log_warning "Monitoring process not found"
        fi
        
        rm -f "$MONITOR_PID_FILE"
    else
        log_warning "Monitoring is not running"
    fi
}

# View log
view_log() {
    log_info "Viewing monitor log..."
    
    if [ -f /var/log/funpay/monitor.log ]; then
        echo ""
        echo "📄 Last 20 lines of monitor log:"
        echo "================================"
        tail -20 /var/log/funpay/monitor.log
        echo ""
        echo "💡 For live view: tail -f /var/log/funpay/monitor.log"
    else
        log_warning "Monitor log file not found"
    fi
}

# Disable telegram
disable_telegram() {
    log_warning "Disabling Telegram notification..."
    
    read -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "$SCRIPT_DIR"
        python3 telegram_setup.py --disable
        log_success "Telegram notification disabled"
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
            start_monitor
            ;;
        "stop")
            stop_monitor
            ;;
        "restart")
            stop_monitor
            sleep 2
            start_monitor
            ;;
        "log")
            view_log
            ;;
        "disable")
            disable_telegram
            ;;
        "menu")
            while true; do
                show_menu
                read -p "Your choice (1-8): " choice
                
                case $choice in
                    1) setup_telegram ;;
                    2) show_status ;;
                    3) test_connection ;;
                    4) start_monitor ;;
                    5) stop_monitor ;;
                    6) view_log ;;
                    7) disable_telegram ;;
                    8) 
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
            echo "  $0 start     # Start monitoring"
            echo "  $0 stop      # Stop monitoring"
            echo "  $0 restart   # Restart monitoring"
            echo "  $0 log       # View log"
            echo "  $0 disable   # Disable Telegram"
            echo "  $0 menu      # Interactive menu (default)"
            ;;
    esac
}

# Run main function
main "$@"
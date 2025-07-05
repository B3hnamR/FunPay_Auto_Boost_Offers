#!/bin/bash

# FunPay Auto Boost - Complete System Management
# Enhanced version with testing and monitoring

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    echo -e "${BLUE}║${WHITE}              FunPay Auto Boost - System Manager             ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Choose an option:"
    echo "1. 📊 System Status"
    echo "2. 🧪 Quick Test"
    echo "3. 🔧 Setup Telegram"
    echo "4. 🚀 Start All Services"
    echo "5. 🛑 Stop All Services"
    echo "6. 🔄 Restart All Services"
    echo "7. 📄 View Logs"
    echo "8. 🎯 Test Boost Function"
    echo "9. 📱 Test Telegram"
    echo "10. 🧹 Complete Cleanup"
    echo "11. 🚪 Exit"
    echo ""
}

# System status
show_system_status() {
    log_info "Checking complete system status..."
    echo ""
    
    # Main boost service
    echo "🚀 Main Boost Service:"
    if pgrep -f "funpay_boost_ultimate" > /dev/null; then
        PID=$(pgrep -f "funpay_boost_ultimate")
        log_success "Running (PID: $PID)"
        
        # Show process info
        echo "   Process info:"
        for p in $PID; do
            ps -p "$p" -o pid,ppid,etime,cmd --no-headers 2>/dev/null | while read line; do
                echo "   $line"
            done
        done
    else
        log_warning "Not running"
    fi
    
    echo ""
    
    # Monitor service
    echo "📡 Monitor Service:"
    if pgrep -f "boost_monitor_final" > /dev/null; then
        PID=$(pgrep -f "boost_monitor_final")
        log_success "Running (PID: $PID)"
    else
        log_warning "Not running"
    fi
    
    echo ""
    
    # Telegram status
    echo "📱 Telegram Configuration:"
    cd "$SCRIPT_DIR"
    python3 -c "
from telegram_notifier import TelegramNotifier
notifier = TelegramNotifier()
if notifier.is_enabled():
    print('✅ Enabled and configured')
else:
    print('❌ Disabled or not configured')
"
    
    echo ""
    
    # Configuration status
    echo "⚙️ Configuration:"
    if [ -f "/etc/funpay/config.json" ]; then
        log_success "Main config found"
        
        # Show last boost
        LAST_BOOST=$(cat /etc/funpay/config.json | grep -o '"last_boost": "[^"]*"' | cut -d'"' -f4)
        if [ -n "$LAST_BOOST" ]; then
            echo "   📅 Last boost: $LAST_BOOST"
        else
            echo "   📅 No previous boost recorded"
        fi
    else
        log_warning "Main config not found"
    fi
    
    echo ""
    
    # Recent activity
    echo "📋 Recent Activity:"
    if [ -f "/var/log/funpay/boost.log" ]; then
        echo "   Last 3 boost log entries:"
        tail -3 /var/log/funpay/boost.log | while read line; do
            echo "   $line"
        done
    else
        log_warning "No boost log found"
    fi
    
    if [ -f "/var/log/funpay/monitor_final.log" ]; then
        echo ""
        echo "   Last 3 monitor log entries:"
        tail -3 /var/log/funpay/monitor_final.log | while read line; do
            echo "   $line"
        done
    fi
}

# Quick test
run_quick_test() {
    log_info "Running quick system test..."
    cd "$SCRIPT_DIR"
    python3 quick_test.py
}

# Setup telegram
setup_telegram() {
    log_info "Setting up Telegram notifications..."
    cd "$SCRIPT_DIR"
    sudo bash manage_telegram_final.sh setup
}

# Start all services
start_all_services() {
    log_info "Starting all services..."
    cd "$SCRIPT_DIR"
    
    # Start main boost service
    echo "🚀 Starting main boost service..."
    python3 funpay_boost_ultimate.py --start
    
    sleep 3
    
    # Start telegram monitoring
    echo "📡 Starting telegram monitoring..."
    sudo bash manage_telegram_final.sh start
    
    log_success "All services started"
}

# Stop all services
stop_all_services() {
    log_info "Stopping all services..."
    cd "$SCRIPT_DIR"
    
    # Stop main boost service
    echo "🛑 Stopping main boost service..."
    python3 funpay_boost_ultimate.py --stop
    
    # Stop telegram monitoring
    echo "📡 Stopping telegram monitoring..."
    sudo bash manage_telegram_final.sh stop
    
    log_success "All services stopped"
}

# Restart all services
restart_all_services() {
    log_info "Restarting all services..."
    stop_all_services
    sleep 5
    start_all_services
}

# View logs
view_logs() {
    echo "📄 Available logs:"
    echo "1. Main boost log"
    echo "2. Monitor log"
    echo "3. Background log"
    echo "4. Live monitor log"
    echo ""
    
    read -p "Choose log to view (1-4): " choice
    
    case $choice in
        1)
            if [ -f "/var/log/funpay/boost.log" ]; then
                log_info "Showing last 20 lines of boost log..."
                tail -20 /var/log/funpay/boost.log
            else
                log_error "Boost log not found"
            fi
            ;;
        2)
            if [ -f "/var/log/funpay/monitor_final.log" ]; then
                log_info "Showing last 20 lines of monitor log..."
                tail -20 /var/log/funpay/monitor_final.log
            else
                log_error "Monitor log not found"
            fi
            ;;
        3)
            if [ -f "/var/log/funpay/background.log" ]; then
                log_info "Showing last 20 lines of background log..."
                tail -20 /var/log/funpay/background.log
            else
                log_error "Background log not found"
            fi
            ;;
        4)
            if [ -f "/var/log/funpay/monitor_final.log" ]; then
                log_info "Starting live monitor log (Ctrl+C to exit)..."
                tail -f /var/log/funpay/monitor_final.log
            else
                log_error "Monitor log not found"
            fi
            ;;
        *)
            log_error "Invalid choice"
            ;;
    esac
}

# Test boost function
test_boost_function() {
    log_info "Testing boost function..."
    cd "$SCRIPT_DIR"
    python3 funpay_boost_ultimate.py --test
}

# Test telegram
test_telegram() {
    log_info "Testing Telegram notifications..."
    cd "$SCRIPT_DIR"
    python3 test_system.py
}

# Complete cleanup
complete_cleanup() {
    log_warning "This will completely remove all FunPay Auto Boost components"
    echo ""
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Performing complete cleanup..."
        
        # Stop services
        stop_all_services
        
        # Run cleanup script
        if [ -f "$SCRIPT_DIR/cleanup_funpay.sh" ]; then
            sudo bash "$SCRIPT_DIR/cleanup_funpay.sh"
        fi
        
        log_success "Complete cleanup finished"
    else
        log_info "Cleanup cancelled"
    fi
}

# Main function
main() {
    # Check if running as root for some operations
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root - some operations may not work correctly"
    fi
    
    # Process command line arguments
    case "${1:-menu}" in
        "status")
            show_system_status
            ;;
        "test")
            run_quick_test
            ;;
        "setup")
            setup_telegram
            ;;
        "start")
            start_all_services
            ;;
        "stop")
            stop_all_services
            ;;
        "restart")
            restart_all_services
            ;;
        "logs")
            view_logs
            ;;
        "test-boost")
            test_boost_function
            ;;
        "test-telegram")
            test_telegram
            ;;
        "cleanup")
            complete_cleanup
            ;;
        "menu")
            while true; do
                show_menu
                read -p "Your choice (1-11): " choice
                
                case $choice in
                    1) show_system_status ;;
                    2) run_quick_test ;;
                    3) setup_telegram ;;
                    4) start_all_services ;;
                    5) stop_all_services ;;
                    6) restart_all_services ;;
                    7) view_logs ;;
                    8) test_boost_function ;;
                    9) test_telegram ;;
                    10) complete_cleanup ;;
                    11) 
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
            echo "  $0 status        # Show system status"
            echo "  $0 test          # Run quick test"
            echo "  $0 setup         # Setup Telegram"
            echo "  $0 start         # Start all services"
            echo "  $0 stop          # Stop all services"
            echo "  $0 restart       # Restart all services"
            echo "  $0 logs          # View logs"
            echo "  $0 test-boost    # Test boost function"
            echo "  $0 test-telegram # Test Telegram"
            echo "  $0 cleanup       # Complete cleanup"
            echo "  $0 menu          # Interactive menu (default)"
            ;;
    esac
}

# Run main function
main "$@"
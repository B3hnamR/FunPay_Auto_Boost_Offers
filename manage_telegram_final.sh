#!/bin/bash

# FunPay Auto Boost Telegram Notification Management Script - Final Version

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_PID_FILE="/tmp/boost_monitor_final.pid"

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
    echo -e "${BLUE}║${WHITE}          FunPay Telegram Notification Manager (FINAL)       ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Choose an option:"
    echo "1. 🔧 Setup Telegram"
    echo "2. 📊 Show Status"
    echo "3. 🧪 Test Connection"
    echo "4. 🚀 Start Final Monitoring"
    echo "5. 🛑 Stop All Monitoring"
    echo "6. 🔄 Upgrade to Final Monitor"
    echo "7. 📄 View Monitor Log"
    echo "8. 🧹 Complete Cleanup"
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

# Stop all monitoring processes
stop_all_monitoring() {
    log_info "Stopping ALL monitoring processes..."
    
    # Stop final monitor
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -TERM "$PID" 2>/dev/null
            sleep 2
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -KILL "$PID" 2>/dev/null
            fi
            log_success "Final monitoring stopped"
        fi
        rm -f "$MONITOR_PID_FILE"
    fi
    
    # Stop all other monitors
    for pid_file in /tmp/boost_monitor*.pid; do
        if [ -f "$pid_file" ]; then
            PID=$(cat "$pid_file" 2>/dev/null)
            if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
                kill -TERM "$PID" 2>/dev/null
                sleep 1
                kill -KILL "$PID" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done
    
    # Kill any remaining monitor processes
    pkill -f "boost_monitor" 2>/dev/null || true
    
    # Clean state files
    rm -f /tmp/boost_monitor_state.json
    
    log_success "All monitoring processes stopped and cleaned"
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
    
    # Check final monitor
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_success "Final monitoring is running (PID: $PID)"
            
            # Show process info
            echo "📊 Process Info:"
            ps -p "$PID" -o pid,ppid,etime,cmd --no-headers | while read line; do
                echo "   $line"
            done
        else
            log_warning "Final monitor PID file exists but process is stopped"
            rm -f "$MONITOR_PID_FILE"
        fi
    else
        log_warning "Final monitoring is not running"
    fi
    
    # Check for other monitors
    OTHER_MONITORS=$(ps aux | grep -E "boost_monitor" | grep -v grep | grep -v "final" | wc -l)
    if [ "$OTHER_MONITORS" -gt 0 ]; then
        log_warning "Found $OTHER_MONITORS other monitoring processes running"
        echo "Consider running cleanup to remove them"
    fi
    
    echo ""
    echo "📊 Recent Activity:"
    if [ -f /var/log/funpay/monitor_final.log ]; then
        echo "Last 3 final monitor entries:"
        tail -3 /var/log/funpay/monitor_final.log | while read line; do
            echo "  $line"
        done
    else
        log_info "No final monitor log found yet"
    fi
}

# Test connection
test_connection() {
    log_info "Testing Telegram connection..."
    cd "$SCRIPT_DIR"
    python3 telegram_setup.py --test
}

# Start final monitoring
start_final_monitor() {
    log_info "Starting final monitoring system..."
    
    # Stop any existing monitoring first
    stop_all_monitoring
    sleep 3
    
    # Create log directory
    mkdir -p /var/log/funpay
    
    cd "$SCRIPT_DIR"
    
    # Start final monitoring in background
    nohup python3 boost_monitor_final.py > /var/log/funpay/monitor_final_output.log 2>&1 &
    MONITOR_PID=$!
    
    # Save PID
    echo "$MONITOR_PID" > "$MONITOR_PID_FILE"
    
    log_success "Final monitoring started (PID: $MONITOR_PID)"
    echo ""
    echo "🎯 Final System Features:"
    echo "  ✅ Ultimate duplicate prevention"
    echo "  ✅ Network error filtering"
    echo "  ✅ 10-minute notification cooldown"
    echo "  ✅ Event signature tracking"
    echo "  ✅ State persistence across restarts"
    echo "  ✅ Advanced pattern matching"
    echo ""
    log_info "To view log: tail -f /var/log/funpay/monitor_final.log"
}

# Upgrade to final monitor
upgrade_to_final() {
    log_info "Upgrading to FINAL monitoring system..."
    
    echo "🚀 This will:"
    echo "  • Stop ALL existing monitoring systems"
    echo "  • Clean all duplicate tracking"
    echo "  • Start ultimate monitoring with:"
    echo "    - Network error filtering"
    echo "    - Advanced duplicate prevention"
    echo "    - State persistence"
    echo "    - 10-minute cooldown"
    echo ""
    
    read -p "Continue with final upgrade? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log_info "Upgrade cancelled"
        return
    fi
    
    start_final_monitor
    
    log_success "🎉 FINAL UPGRADE COMPLETED!"
    echo ""
    echo "📋 What's new in FINAL version:"
    echo "  🔥 Network error filtering (no more HTTPConnection errors)"
    echo "  🔥 Ultimate duplicate prevention with event signatures"
    echo "  🔥 State persistence (survives restarts)"
    echo "  🔥 10-minute notification cooldown"
    echo "  🔥 Advanced pattern matching"
    echo "  🔥 Event grouping and filtering"
}

# View log
view_log() {
    log_info "Viewing monitor logs..."
    
    echo ""
    echo "📄 Final Monitor Log (last 20 lines):"
    echo "======================================"
    if [ -f /var/log/funpay/monitor_final.log ]; then
        tail -20 /var/log/funpay/monitor_final.log
        echo ""
        echo "💡 For live view: tail -f /var/log/funpay/monitor_final.log"
    else
        log_warning "Final monitor log not found"
    fi
    
    echo ""
    echo "📊 System Status:"
    echo "================="
    if [ -f /var/log/funpay/boost.log ]; then
        echo "Main boost log size: $(du -h /var/log/funpay/boost.log | cut -f1)"
        echo "Last boost activity:"
        tail -3 /var/log/funpay/boost.log | grep -E "(Boost|boost)" | tail -1
    fi
}

# Complete cleanup
complete_cleanup() {
    log_warning "Performing complete cleanup..."
    
    echo "🧹 This will:"
    echo "  • Stop all monitoring processes"
    echo "  • Remove all PID files"
    echo "  • Clear all state files"
    echo "  • Clean duplicate tracking"
    echo ""
    
    read -p "Continue with complete cleanup? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Stop everything
        stop_all_monitoring
        
        # Remove all state files
        rm -f /tmp/boost_monitor*.json
        rm -f /tmp/boost_monitor*.pid
        
        # Clean old logs (optional)
        read -p "Also clean old log files? (y/N): " clean_logs
        if [[ "$clean_logs" =~ ^[Yy]$ ]]; then
            rm -f /var/log/funpay/monitor.log
            rm -f /var/log/funpay/monitor_improved.log
            rm -f /var/log/funpay/monitor_output.log
            rm -f /var/log/funpay/monitor_improved_output.log
            log_success "Old log files cleaned"
        fi
        
        log_success "Complete cleanup finished"
        echo "You can now start fresh with: sudo bash $0 start"
    else
        log_info "Cleanup cancelled"
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
        log_success "Telegram notification disabled and all monitoring stopped"
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
            start_final_monitor
            ;;
        "stop")
            stop_all_monitoring
            ;;
        "restart")
            stop_all_monitoring
            sleep 3
            start_final_monitor
            ;;
        "upgrade")
            upgrade_to_final
            ;;
        "log")
            view_log
            ;;
        "cleanup")
            complete_cleanup
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
                    4) start_final_monitor ;;
                    5) stop_all_monitoring ;;
                    6) upgrade_to_final ;;
                    7) view_log ;;
                    8) complete_cleanup ;;
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
            echo "  $0 start     # Start final monitoring"
            echo "  $0 stop      # Stop all monitoring"
            echo "  $0 restart   # Restart final monitoring"
            echo "  $0 upgrade   # Upgrade to final monitor"
            echo "  $0 log       # View logs"
            echo "  $0 cleanup   # Complete cleanup"
            echo "  $0 disable   # Disable Telegram"
            echo "  $0 menu      # Interactive menu (default)"
            ;;
    esac
}

# Run main function
main "$@"
#!/bin/bash

# FunPay Auto Boost - Interactive Management Console
# Enhanced management interface with all features

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Configuration
CONFIG_FILE="/etc/funpay/config.json"
LOG_FILE="/var/log/funpay/boost.log"
SERVICE_NAME="funpay-boost"

# Function to display animated header
show_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                    FunPay Auto Boost                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}                 Interactive Management Console              ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════��══════════════════╝${NC}"
    echo ""
}

# Function to show loading animation
show_loading() {
    local message="$1"
    local duration="${2:-2}"
    
    echo -n -e "${YELLOW}$message${NC}"
    for i in $(seq 1 $duration); do
        for char in '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'; do
            echo -n -e "\r${YELLOW}$message $char${NC}"
            sleep 0.1
        done
    done
    echo -e "\r${GREEN}$message ✓${NC}"
}

# Function to get service status with color
get_service_status() {
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}●${NC} Running"
    elif systemctl is-enabled --quiet $SERVICE_NAME; then
        echo -e "${RED}●${NC} Stopped"
    else
        echo -e "${GRAY}●${NC} Disabled"
    fi
}

# Function to get boost info
get_boost_info() {
    if [[ -f "$CONFIG_FILE" ]]; then
        local last_boost=$(jq -r '.last_boost // "Never"' "$CONFIG_FILE" 2>/dev/null || echo "Never")
        local interval=$(jq -r '.boost_interval // 3' "$CONFIG_FILE" 2>/dev/null || echo "3")
        
        if [[ "$last_boost" != "Never" && "$last_boost" != "null" ]]; then
            local last_time=$(date -d "$last_boost" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Invalid")
            local next_time=$(date -d "$last_boost + $interval hours" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Invalid")
            echo "Last: $last_time | Next: $next_time"
        else
            echo "Last: Never | Next: Ready"
        fi
    else
        echo "Configuration not found"
    fi
}

# Function to show main menu
show_main_menu() {
    show_header
    
    # Service status
    local status=$(get_service_status)
    local boost_info=$(get_boost_info)
    
    echo -e "${CYAN}📊 System Status${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo -e "Service: $status"
    echo -e "Boost Info: $boost_info"
    echo ""
    
    echo -e "${CYAN}🎮 Main Menu${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo -e "  ${GREEN}1.${NC} 🚀 Service Management"
    echo -e "  ${GREEN}2.${NC} 📊 Monitoring & Logs"
    echo -e "  ${GREEN}3.${NC} ⚙️  Configuration"
    echo -e "  ${GREEN}4.${NC} 🧪 Testing & Diagnostics"
    echo -e "  ${GREEN}5.${NC} 📖 Help & Information"
    echo -e "  ${GREEN}6.${NC} 🔧 Advanced Options"
    echo -e "  ${RED}0.${NC} 🚪 Exit"
    echo ""
    
    read -p "Select option [0-6]: " choice
    
    case $choice in
        1) service_management_menu ;;
        2) monitoring_menu ;;
        3) configuration_menu ;;
        4) testing_menu ;;
        5) help_menu ;;
        6) advanced_menu ;;
        0) exit 0 ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            sleep 1
            show_main_menu
            ;;
    esac
}

# Service Management Menu
service_management_menu() {
    show_header
    echo -e "${CYAN}🚀 Service Management${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    local status=$(get_service_status)
    echo -e "Current Status: $status"
    echo ""
    
    echo -e "  ${GREEN}1.${NC} ▶️  Start Service"
    echo -e "  ${GREEN}2.${NC} ⏹️  Stop Service"
    echo -e "  ${GREEN}3.${NC} 🔄 Restart Service"
    echo -e "  ${GREEN}4.${NC} 🔄 Reload Configuration"
    echo -e "  ${GREEN}5.${NC} 📊 Detailed Status"
    echo -e "  ${GREEN}6.${NC} 🔧 Enable/Disable Auto-start"
    echo -e "  ${YELLOW}9.${NC} 🔙 Back to Main Menu"
    echo ""
    
    read -p "Select option [1-6,9]: " choice
    
    case $choice in
        1) start_service ;;
        2) stop_service ;;
        3) restart_service ;;
        4) reload_service ;;
        5) detailed_status ;;
        6) toggle_autostart ;;
        9) show_main_menu ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            sleep 1
            service_management_menu
            ;;
    esac
}

# Monitoring Menu
monitoring_menu() {
    show_header
    echo -e "${CYAN}📊 Monitoring & Logs${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    echo -e "  ${GREEN}1.${NC} 📋 Live Logs (Follow)"
    echo -e "  ${GREEN}2.${NC} 📄 Recent Logs (Last 50 lines)"
    echo -e "  ${GREEN}3.${NC} 🔍 Search Logs"
    echo -e "  ${GREEN}4.${NC} 📊 Boost Statistics"
    echo -e "  ${GREEN}5.${NC} 💾 Export Logs"
    echo -e "  ${GREEN}6.${NC} 🗑️  Clear Logs"
    echo -e "  ${YELLOW}9.${NC} 🔙 Back to Main Menu"
    echo ""
    
    read -p "Select option [1-6,9]: " choice
    
    case $choice in
        1) live_logs ;;
        2) recent_logs ;;
        3) search_logs ;;
        4) boost_statistics ;;
        5) export_logs ;;
        6) clear_logs ;;
        9) show_main_menu ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            sleep 1
            monitoring_menu
            ;;
    esac
}

# Configuration Menu
configuration_menu() {
    show_header
    echo -e "${CYAN}⚙️ Configuration${NC}"
    echo -e "${CYAN}═══════════════════${NC}"
    echo ""
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${CYAN}Current Configuration:${NC}"
        echo -e "Username: $(jq -r '.username' "$CONFIG_FILE" 2>/dev/null || echo "N/A")"
        echo -e "URL: $(jq -r '.target_url' "$CONFIG_FILE" 2>/dev/null || echo "N/A")"
        echo -e "Interval: $(jq -r '.boost_interval' "$CONFIG_FILE" 2>/dev/null || echo "N/A") hours"
        echo ""
    fi
    
    echo -e "  ${GREEN}1.${NC} 📝 Edit Configuration File"
    echo -e "  ${GREEN}2.${NC} 🔄 Update Username/Password"
    echo -e "  ${GREEN}3.${NC} 🔗 Update Target URL"
    echo -e "  ${GREEN}4.${NC} ⏰ Update Boost Interval"
    echo -e "  ${GREEN}5.${NC} 📋 View Full Configuration"
    echo -e "  ${GREEN}6.${NC} 💾 Backup Configuration"
    echo -e "  ${GREEN}7.${NC} 📥 Restore Configuration"
    echo -e "  ${YELLOW}9.${NC} 🔙 Back to Main Menu"
    echo ""
    
    read -p "Select option [1-7,9]: " choice
    
    case $choice in
        1) edit_config ;;
        2) update_credentials ;;
        3) update_url ;;
        4) update_interval ;;
        5) view_config ;;
        6) backup_config ;;
        7) restore_config ;;
        9) show_main_menu ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            sleep 1
            configuration_menu
            ;;
    esac
}

# Testing Menu
testing_menu() {
    show_header
    echo -e "${CYAN}🧪 Testing & Diagnostics${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    echo -e "  ${GREEN}1.${NC} 🔍 System Requirements Check"
    echo -e "  ${GREEN}2.${NC} 🌐 Network Connectivity Test"
    echo -e "  ${GREEN}3.${NC} 🔐 Login Test"
    echo -e "  ${GREEN}4.${NC} 🎯 Boost Page Access Test"
    echo -e "  ${GREEN}5.${NC} 🧪 Full Functionality Test"
    echo -e "  ${GREEN}6.${NC} 🔧 Firefox/Selenium Test"
    echo -e "  ${GREEN}7.${NC} 📊 Performance Test"
    echo -e "  ${YELLOW}9.${NC} 🔙 Back to Main Menu"
    echo ""
    
    read -p "Select option [1-7,9]: " choice
    
    case $choice in
        1) system_check ;;
        2) network_test ;;
        3) login_test ;;
        4) boost_page_test ;;
        5) full_test ;;
        6) selenium_test ;;
        7) performance_test ;;
        9) show_main_menu ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            sleep 1
            testing_menu
            ;;
    esac
}

# Help Menu
help_menu() {
    show_header
    echo -e "${CYAN}📖 Help & Information${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    echo -e "  ${GREEN}1.${NC} 📚 User Guide"
    echo -e "  ${GREEN}2.${NC} ❓ FAQ"
    echo -e "  ${GREEN}3.${NC} 🐛 Troubleshooting"
    echo -e "  ${GREEN}4.${NC} 📋 Command Reference"
    echo -e "  ${GREEN}5.${NC} ℹ️  System Information"
    echo -e "  ${GREEN}6.${NC} 📞 Support Information"
    echo -e "  ${YELLOW}9.${NC} 🔙 Back to Main Menu"
    echo ""
    
    read -p "Select option [1-6,9]: " choice
    
    case $choice in
        1) user_guide ;;
        2) faq ;;
        3) troubleshooting ;;
        4) command_reference ;;
        5) system_info ;;
        6) support_info ;;
        9) show_main_menu ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            sleep 1
            help_menu
            ;;
    esac
}

# Advanced Menu
advanced_menu() {
    show_header
    echo -e "${CYAN}🔧 Advanced Options${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    echo -e "${RED}⚠️ Warning: These options are for advanced users only!${NC}"
    echo ""
    
    echo -e "  ${GREEN}1.${NC} 🔄 Reinstall Service"
    echo -e "  ${GREEN}2.${NC} 🗑️  Uninstall Completely"
    echo -e "  ${GREEN}3.${NC} 🔧 Reset to Defaults"
    echo -e "  ${GREEN}4.${NC} 📦 Update Components"
    echo -e "  ${GREEN}5.${NC} 🔍 Debug Mode"
    echo -e "  ${GREEN}6.${NC} 💾 System Cleanup"
    echo -e "  ${YELLOW}9.${NC} 🔙 Back to Main Menu"
    echo ""
    
    read -p "Select option [1-6,9]: " choice
    
    case $choice in
        1) reinstall_service ;;
        2) uninstall_service ;;
        3) reset_defaults ;;
        4) update_components ;;
        5) debug_mode ;;
        6) system_cleanup ;;
        9) show_main_menu ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            sleep 1
            advanced_menu
            ;;
    esac
}

# Service Management Functions
start_service() {
    show_loading "Starting FunPay Boost service"
    systemctl start $SERVICE_NAME
    
    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Service started successfully${NC}"
    else
        echo -e "${RED}❌ Failed to start service${NC}"
        echo -e "${YELLOW}Check logs for details${NC}"
    fi
    
    read -p "Press Enter to continue..."
    service_management_menu
}

stop_service() {
    show_loading "Stopping FunPay Boost service"
    systemctl stop $SERVICE_NAME
    echo -e "${GREEN}✅ Service stopped${NC}"
    
    read -p "Press Enter to continue..."
    service_management_menu
}

restart_service() {
    show_loading "Restarting FunPay Boost service"
    systemctl restart $SERVICE_NAME
    
    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Service restarted successfully${NC}"
    else
        echo -e "${RED}❌ Failed to restart service${NC}"
        echo -e "${YELLOW}Check logs for details${NC}"
    fi
    
    read -p "Press Enter to continue..."
    service_management_menu
}

reload_service() {
    show_loading "Reloading configuration"
    systemctl reload-or-restart $SERVICE_NAME
    echo -e "${GREEN}✅ Configuration reloaded${NC}"
    
    read -p "Press Enter to continue..."
    service_management_menu
}

detailed_status() {
    echo -e "${CYAN}📊 Detailed Service Status${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    systemctl status $SERVICE_NAME --no-pager -l
    echo ""
    
    read -p "Press Enter to continue..."
    service_management_menu
}

toggle_autostart() {
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        echo -e "${YELLOW}Disabling auto-start...${NC}"
        systemctl disable $SERVICE_NAME
        echo -e "${GREEN}✅ Auto-start disabled${NC}"
    else
        echo -e "${YELLOW}Enabling auto-start...${NC}"
        systemctl enable $SERVICE_NAME
        echo -e "${GREEN}✅ Auto-start enabled${NC}"
    fi
    
    read -p "Press Enter to continue..."
    service_management_menu
}

# Monitoring Functions
live_logs() {
    echo -e "${CYAN}📋 Live Logs (Press Ctrl+C to exit)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    journalctl -u $SERVICE_NAME -f --no-pager
    monitoring_menu
}

recent_logs() {
    echo -e "${CYAN}📄 Recent Logs (Last 50 lines)${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo ""
    
    journalctl -u $SERVICE_NAME -n 50 --no-pager
    echo ""
    
    read -p "Press Enter to continue..."
    monitoring_menu
}

search_logs() {
    echo -e "${CYAN}🔍 Search Logs${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo ""
    
    read -p "Enter search term: " search_term
    if [[ -n "$search_term" ]]; then
        echo ""
        echo -e "${YELLOW}Searching for: $search_term${NC}"
        echo ""
        journalctl -u $SERVICE_NAME --no-pager | grep -i "$search_term" --color=always
    fi
    echo ""
    
    read -p "Press Enter to continue..."
    monitoring_menu
}

boost_statistics() {
    echo -e "${CYAN}📊 Boost Statistics${NC}"
    echo -e "${CYAN}═══════════════════${NC}"
    echo ""
    
    if [[ -f "$LOG_FILE" ]]; then
        local total_boosts=$(grep -c "SUCCESS.*boosted" "$LOG_FILE" 2>/dev/null || echo "0")
        local total_errors=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
        local last_boost=$(grep "SUCCESS.*boosted" "$LOG_FILE" | tail -1 | cut -d' ' -f1-2 2>/dev/null || echo "Never")
        
        echo -e "Total Successful Boosts: ${GREEN}$total_boosts${NC}"
        echo -e "Total Errors: ${RED}$total_errors${NC}"
        echo -e "Last Successful Boost: ${YELLOW}$last_boost${NC}"
    else
        echo -e "${YELLOW}No log file found${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    monitoring_menu
}

export_logs() {
    echo -e "${CYAN}💾 Export Logs${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo ""
    
    local export_file="/tmp/funpay_logs_$(date +%Y%m%d_%H%M%S).txt"
    
    echo -e "${YELLOW}Exporting logs to: $export_file${NC}"
    journalctl -u $SERVICE_NAME --no-pager > "$export_file"
    
    if [[ -f "$export_file" ]]; then
        echo -e "${GREEN}✅ Logs exported successfully${NC}"
        echo -e "File size: $(du -h "$export_file" | cut -f1)"
    else
        echo -e "${RED}❌ Failed to export logs${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    monitoring_menu
}

clear_logs() {
    echo -e "${CYAN}🗑️ Clear Logs${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo ""
    echo -e "${RED}⚠️ This will permanently delete all logs!${NC}"
    echo ""
    
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    if [[ "$confirm" == "yes" ]]; then
        journalctl --rotate
        journalctl --vacuum-time=1s
        
        if [[ -f "$LOG_FILE" ]]; then
            > "$LOG_FILE"
        fi
        
        echo -e "${GREEN}✅ Logs cleared${NC}"
    else
        echo -e "${YELLOW}Operation cancelled${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    monitoring_menu
}

# Configuration Functions
edit_config() {
    echo -e "${CYAN}📝 Edit Configuration${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Configuration file not found!${NC}"
        read -p "Press Enter to continue..."
        configuration_menu
        return
    fi
    
    echo -e "${YELLOW}Opening configuration file...${NC}"
    
    if command -v nano >/dev/null; then
        nano "$CONFIG_FILE"
    elif command -v vi >/dev/null; then
        vi "$CONFIG_FILE"
    else
        echo -e "${RED}❌ No text editor found!${NC}"
        read -p "Press Enter to continue..."
        configuration_menu
        return
    fi
    
    echo -e "${GREEN}✅ Configuration updated${NC}"
    echo -e "${YELLOW}Restart service to apply changes${NC}"
    
    read -p "Press Enter to continue..."
    configuration_menu
}

update_credentials() {
    echo -e "${CYAN}🔄 Update Username/Password${NC}"
    echo -e "${CYAN}═══════════════════════════════${NC}"
    echo ""
    
    read -p "Enter new username/email: " new_username
    read -s -p "Enter new password: " new_password
    echo ""
    
    if [[ -n "$new_username" && -n "$new_password" ]]; then
        jq --arg user "$new_username" --arg pass "$new_password" \
           '.username = $user | .password = $pass' \
           "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        
        echo -e "${GREEN}✅ Credentials updated${NC}"
        echo -e "${YELLOW}Restart service to apply changes${NC}"
    else
        echo -e "${RED}❌ Invalid input${NC}"
    fi
    
    read -p "Press Enter to continue..."
    configuration_menu
}

update_url() {
    echo -e "${CYAN}🔗 Update Target URL${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Current URL:${NC}"
    jq -r '.target_url' "$CONFIG_FILE" 2>/dev/null || echo "N/A"
    echo ""
    
    read -p "Enter new target URL: " new_url
    
    if [[ -n "$new_url" ]]; then
        jq --arg url "$new_url" '.target_url = $url' \
           "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        
        echo -e "${GREEN}✅ URL updated${NC}"
        echo -e "${YELLOW}Restart service to apply changes${NC}"
    else
        echo -e "${RED}❌ Invalid URL${NC}"
    fi
    
    read -p "Press Enter to continue..."
    configuration_menu
}

update_interval() {
    echo -e "${CYAN}⏰ Update Boost Interval${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Current interval:${NC}"
    jq -r '.boost_interval' "$CONFIG_FILE" 2>/dev/null || echo "N/A"
    echo ""
    
    read -p "Enter new interval (hours): " new_interval
    
    if [[ "$new_interval" =~ ^[0-9]+$ ]] && [[ "$new_interval" -gt 0 ]]; then
        jq --arg interval "$new_interval" '.boost_interval = ($interval | tonumber)' \
           "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        
        echo -e "${GREEN}✅ Interval updated${NC}"
        echo -e "${YELLOW}Restart service to apply changes${NC}"
    else
        echo -e "${RED}❌ Invalid interval${NC}"
    fi
    
    read -p "Press Enter to continue..."
    configuration_menu
}

view_config() {
    echo -e "${CYAN}📋 Full Configuration${NC}"
    echo -e "${CYAN}══════════════════════���${NC}"
    echo ""
    
    if [[ -f "$CONFIG_FILE" ]]; then
        jq . "$CONFIG_FILE" 2>/dev/null || cat "$CONFIG_FILE"
    else
        echo -e "${RED}❌ Configuration file not found${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    configuration_menu
}

backup_config() {
    echo -e "${CYAN}💾 Backup Configuration${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    local backup_file="/tmp/funpay_config_backup_$(date +%Y%m%d_%H%M%S).json"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        echo -e "${GREEN}✅ Configuration backed up to: $backup_file${NC}"
    else
        echo -e "${RED}❌ Configuration file not found${NC}"
    fi
    
    read -p "Press Enter to continue..."
    configuration_menu
}

restore_config() {
    echo -e "${CYAN}📥 Restore Configuration${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    read -p "Enter backup file path: " backup_path
    
    if [[ -f "$backup_path" ]]; then
        cp "$backup_path" "$CONFIG_FILE"
        echo -e "${GREEN}✅ Configuration restored${NC}"
        echo -e "${YELLOW}Restart service to apply changes${NC}"
    else
        echo -e "${RED}❌ Backup file not found${NC}"
    fi
    
    read -p "Press Enter to continue..."
    configuration_menu
}

# Testing Functions
system_check() {
    echo -e "${CYAN}🔍 System Requirements Check${NC}"
    echo -e "${CYAN}═══════════════════════════════${NC}"
    echo ""
    
    # Check Python
    if command -v python3 >/dev/null; then
        echo -e "${GREEN}✅ Python3: $(python3 --version)${NC}"
    else
        echo -e "${RED}❌ Python3: Not found${NC}"
    fi
    
    # Check Firefox
    if command -v firefox >/dev/null; then
        echo -e "${GREEN}✅ Firefox: Available${NC}"
    else
        echo -e "${RED}❌ Firefox: Not found${NC}"
    fi
    
    # Check Xvfb
    if command -v Xvfb >/dev/null; then
        echo -e "${GREEN}✅ Xvfb: Available${NC}"
    else
        echo -e "${RED}❌ Xvfb: Not found${NC}"
    fi
    
    # Check GeckoDriver
    if command -v geckodriver >/dev/null; then
        echo -e "${GREEN}✅ GeckoDriver: Available${NC}"
    else
        echo -e "${RED}❌ GeckoDriver: Not found${NC}"
    fi
    
    # Check required packages
    local packages=("procps" "psmisc" "jq")
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$pkg"; then
            echo -e "${GREEN}✅ $pkg: Installed${NC}"
        else
            echo -e "${RED}❌ $pkg: Not installed${NC}"
        fi
    done
    
    echo ""
    read -p "Press Enter to continue..."
    testing_menu
}

network_test() {
    echo -e "${CYAN}🌐 Network Connectivity Test${NC}"
    echo -e "${CYAN}═══════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing connection to FunPay...${NC}"
    
    if ping -c 3 funpay.com >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Ping to funpay.com: Success${NC}"
    else
        echo -e "${RED}❌ Ping to funpay.com: Failed${NC}"
    fi
    
    if curl -s --head https://funpay.com >/dev/null; then
        echo -e "${GREEN}✅ HTTPS connection: Success${NC}"
    else
        echo -e "${RED}❌ HTTPS connection: Failed${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    testing_menu
}

login_test() {
    echo -e "${CYAN}🔐 Login Test${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing login functionality...${NC}"
    
    sudo -u funpay /opt/funpay-boost/venv/bin/python -c "
import sys
sys.path.append('/opt/funpay-boost')
from funpay_boost import FunPayBooster

try:
    booster = FunPayBooster()
    print('✅ Configuration loaded')
    
    if booster.setup_firefox():
        print('✅ Firefox setup successful')
        
        if booster.login():
            print('✅ Login successful')
        else:
            print('❌ Login failed')
    else:
        print('❌ Firefox setup failed')
        
    booster.cleanup()
    
except Exception as e:
    print(f'❌ Test failed: {e}')
"
    
    echo ""
    read -p "Press Enter to continue..."
    testing_menu
}

boost_page_test() {
    echo -e "${CYAN}🎯 Boost Page Access Test${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing boost page access...${NC}"
    
    sudo -u funpay /opt/funpay-boost/venv/bin/python -c "
import sys
sys.path.append('/opt/funpay-boost')
from funpay_boost import FunPayBooster

try:
    booster = FunPayBooster()
    print('✅ Configuration loaded')
    
    if booster.setup_firefox():
        print('✅ Firefox setup successful')
        
        if booster.login():
            print('✅ Login successful')
            
            status, data = booster.check_boost_status()
            print(f'✅ Boost status check: {status}')
            
            if status == 'available':
                print('✅ Boost button found and available')
            elif status == 'wait':
                print(f'ℹ️ Must wait {data} hours')
            else:
                print('⚠️ Status unclear or error occurred')
        else:
            print('❌ Login failed')
    else:
        print('❌ Firefox setup failed')
        
    booster.cleanup()
    
except Exception as e:
    print(f'❌ Test failed: {e}')
"
    
    echo ""
    read -p "Press Enter to continue..."
    testing_menu
}

full_test() {
    echo -e "${CYAN}🧪 Full Functionality Test${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Running comprehensive test...${NC}"
    echo ""
    
    system_check
    echo ""
    network_test
    echo ""
    login_test
    echo ""
    boost_page_test
    
    echo ""
    echo -e "${GREEN}✅ Full test completed${NC}"
    
    read -p "Press Enter to continue..."
    testing_menu
}

selenium_test() {
    echo -e "${CYAN}🔧 Firefox/Selenium Test${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing Selenium WebDriver...${NC}"
    
    sudo -u funpay /opt/funpay-boost/venv/bin/python -c "
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
import os
import subprocess
import time

try:
    # Setup display
    subprocess.run(['pkill', '-f', 'Xvfb'], capture_output=True, check=False)
    time.sleep(1)
    subprocess.Popen(['Xvfb', ':99', '-screen', '0', '1920x1080x24'], 
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)
    os.environ['DISPLAY'] = ':99'
    print('✅ Virtual display started')
    
    # Setup Firefox
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    
    driver = webdriver.Firefox(options=options)
    print('✅ Firefox WebDriver initialized')
    
    # Test navigation
    driver.get('https://www.google.com')
    print('✅ Navigation test successful')
    
    driver.quit()
    print('✅ WebDriver cleanup successful')
    
    # Cleanup
    subprocess.run(['pkill', '-f', 'firefox'], capture_output=True, check=False)
    subprocess.run(['pkill', '-f', 'Xvfb'], capture_output=True, check=False)
    print('✅ Process cleanup successful')
    
except Exception as e:
    print(f'❌ Selenium test failed: {e}')
"
    
    echo ""
    read -p "Press Enter to continue..."
    testing_menu
}

performance_test() {
    echo -e "${CYAN}📊 Performance Test${NC}"
    echo -e "${CYAN}═══════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Checking system performance...${NC}"
    echo ""
    
    # CPU usage
    echo -e "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    
    # Memory usage
    echo -e "Memory Usage:"
    free -h | grep "Mem:" | awk '{print $3 "/" $2}'
    
    # Disk usage
    echo -e "Disk Usage:"
    df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}'
    
    # Load average
    echo -e "Load Average:"
    uptime | awk -F'load average:' '{print $2}'
    
    echo ""
    read -p "Press Enter to continue..."
    testing_menu
}

# Help Functions
user_guide() {
    show_header
    echo -e "${CYAN}📚 User Guide${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo ""
    
    cat << 'EOF'
🎯 FunPay Auto Boost - User Guide

📋 Overview:
This tool automatically boosts your FunPay offers at specified intervals.

🚀 Getting Started:
1. Ensure your FunPay credentials are configured
2. Set your target boost URL
3. Configure boost interval (recommended: 3 hours)
4. Start the service

⚙️ Configuration:
- Username: Your FunPay login email
- Password: Your FunPay password
- Target URL: Your offers page URL
- Interval: Hours between boost attempts

🔄 Operation:
- The service runs continuously in the background
- It logs in to FunPay automatically
- Checks for boost availability
- Clicks boost button when available
- Waits for the specified interval

📊 Monitoring:
- Use 'logs' to see real-time activity
- Check 'status' for current state
- View 'info' for boost statistics

🛠️ Troubleshooting:
- Check logs for error messages
- Verify credentials are correct
- Ensure target URL is valid
- Test network connectivity
EOF
    
    echo ""
    read -p "Press Enter to continue..."
    help_menu
}

faq() {
    show_header
    echo -e "${CYAN}❓ Frequently Asked Questions${NC}"
    echo -e "${CYAN}═══════════════════════════════${NC}"
    echo ""
    
    cat << 'EOF'
❓ Q: How often should I boost my offers?
💡 A: Every 3 hours is recommended. Too frequent may trigger rate limits.

❓ Q: What if I get a CAPTCHA?
💡 A: The service will detect CAPTCHAs and log an error. Manual intervention required.

❓ Q: Can I run multiple instances?
💡 A: Not recommended. Use one instance per FunPay account.

❓ Q: What if my password changes?
💡 A: Update the configuration using the config menu.

❓ Q: Is this safe to use?
💡 A: The tool simulates normal browser behavior, but use at your own risk.

❓ Q: What if the service stops working?
💡 A: Check logs, verify credentials, and ensure FunPay hasn't changed their interface.

❓ Q: Can I customize the boost interval?
💡 A: Yes, use the configuration menu to change the interval.

❓ Q: What happens if my internet disconnects?
💡 A: The service will retry automatically when connection is restored.
EOF
    
    echo ""
    read -p "Press Enter to continue..."
    help_menu
}

troubleshooting() {
    show_header
    echo -e "${CYAN}🐛 Troubleshooting Guide${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    cat << 'EOF'
🔧 Common Issues and Solutions:

❌ Service won't start:
   • Check system requirements
   • Verify configuration file exists
   • Check logs for specific errors

❌ Login fails:
   • Verify username/password
   • Check for CAPTCHA requirements
   • Test network connectivity

❌ Boost button not found:
   • Verify target URL is correct
   • Check if FunPay interface changed
   • Ensure you're logged in properly

❌ Firefox/Selenium errors:
   • Check if Xvfb is running
   • Verify GeckoDriver installation
   • Test with selenium test function

❌ Permission errors:
   • Check file permissions
   • Verify service user exists
   • Run with appropriate privileges

❌ High CPU/Memory usage:
   • Monitor with performance test
   • Consider increasing intervals
   • Check for memory leaks

🔍 Debugging Steps:
1. Check service status
2. Review recent logs
3. Run system requirements check
4. Test individual components
5. Check configuration validity
EOF
    
    echo ""
    read -p "Press Enter to continue..."
    help_menu
}

command_reference() {
    show_header
    echo -e "${CYAN}📋 Command Reference${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    cat << 'EOF'
🎮 Management Commands:

Service Control:
  systemctl start funpay-boost     - Start service
  systemctl stop funpay-boost      - Stop service
  systemctl restart funpay-boost   - Restart service
  systemctl status funpay-boost    - Show status

Logs and Monitoring:
  journalctl -u funpay-boost -f    - Follow logs
  journalctl -u funpay-boost -n 50 - Recent logs

Configuration:
  /etc/funpay/config.json          - Main config file
  /var/log/funpay/boost.log        - Application log

Direct Commands:
  funpay-boost start               - Start service
  funpay-boost stop                - Stop service
  funpay-boost restart             - Restart service
  funpay-boost status              - Show status
  funpay-boost logs                - Show logs
  funpay-boost info                - Show boost info
  funpay-boost menu                - Interactive menu

File Locations:
  /opt/funpay-boost/               - Installation directory
  /etc/funpay/                     - Configuration directory
  /var/log/funpay/                 - Log directory
EOF
    
    echo ""
    read -p "Press Enter to continue..."
    help_menu
}

system_info() {
    show_header
    echo -e "${CYAN}ℹ️ System Information${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Operating System:${NC}"
    cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2
    echo ""
    
    echo -e "${YELLOW}System Resources:${NC}"
    echo -e "CPU: $(nproc) cores"
    echo -e "Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo -e "Disk: $(df -h / | tail -1 | awk '{print $4}') available"
    echo ""
    
    echo -e "${YELLOW}Service Information:${NC}"
    echo -e "Status: $(get_service_status)"
    echo -e "Auto-start: $(systemctl is-enabled $SERVICE_NAME 2>/dev/null || echo 'disabled')"
    echo ""
    
    echo -e "${YELLOW}Installation Paths:${NC}"
    echo -e "Application: /opt/funpay-boost/"
    echo -e "Configuration: /etc/funpay/"
    echo -e "Logs: /var/log/funpay/"
    echo ""
    
    read -p "Press Enter to continue..."
    help_menu
}

support_info() {
    show_header
    echo -e "${CYAN}📞 Support Information${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    echo ""
    
    cat << 'EOF'
🆘 Getting Help:

📋 Before Seeking Support:
1. Check the troubleshooting guide
2. Review recent logs for errors
3. Run system requirements check
4. Try restarting the service

📊 Information to Provide:
- Operating system version
- Error messages from logs
- Configuration (without passwords)
- Steps to reproduce the issue

🔧 Self-Help Resources:
- Built-in diagnostics and tests
- Comprehensive logging system
- Interactive troubleshooting guide
- System requirements checker

⚠️ Important Notes:
- Never share your FunPay credentials
- This tool is provided as-is
- Use at your own risk
- Keep backups of your configuration

📝 Log Collection:
Use the "Export Logs" feature to collect
diagnostic information for support requests.
EOF
    
    echo ""
    read -p "Press Enter to continue..."
    help_menu
}

# Advanced Functions
reinstall_service() {
    echo -e "${CYAN}🔄 Reinstall Service${NC}"
    echo -e "${CYAN}══════════════��════════${NC}"
    echo ""
    echo -e "${RED}⚠️ This will reinstall the entire service!${NC}"
    echo ""
    
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    if [[ "$confirm" == "yes" ]]; then
        echo -e "${YELLOW}Reinstalling service...${NC}"
        
        # Stop service
        systemctl stop $SERVICE_NAME 2>/dev/null || true
        
        # Backup config
        if [[ -f "$CONFIG_FILE" ]]; then
            cp "$CONFIG_FILE" "/tmp/config_backup.json"
            echo -e "${GREEN}✅ Configuration backed up${NC}"
        fi
        
        # Download and run installer
        if command -v wget >/dev/null; then
            wget -O /tmp/install_funpay_complete.sh https://raw.githubusercontent.com/your-repo/FunPay_Auto_Boost_Offers/main/install_funpay_complete.sh
            chmod +x /tmp/install_funpay_complete.sh
            /tmp/install_funpay_complete.sh
        else
            echo -e "${RED}❌ wget not available for download${NC}"
        fi
        
        # Restore config if backup exists
        if [[ -f "/tmp/config_backup.json" ]]; then
            cp "/tmp/config_backup.json" "$CONFIG_FILE"
            echo -e "${GREEN}✅ Configuration restored${NC}"
        fi
        
        echo -e "${GREEN}✅ Reinstallation completed${NC}"
    else
        echo -e "${YELLOW}Operation cancelled${NC}"
    fi
    
    read -p "Press Enter to continue..."
    advanced_menu
}

uninstall_service() {
    echo -e "${CYAN}🗑️ Uninstall Service${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    echo -e "${RED}⚠️ This will completely remove FunPay Auto Boost!${NC}"
    echo -e "${RED}⚠️ All data and configuration will be lost!${NC}"
    echo ""
    
    read -p "Are you sure? (type 'UNINSTALL' to confirm): " confirm
    if [[ "$confirm" == "UNINSTALL" ]]; then
        echo -e "${YELLOW}Uninstalling...${NC}"
        
        # Stop and disable service
        systemctl stop $SERVICE_NAME 2>/dev/null || true
        systemctl disable $SERVICE_NAME 2>/dev/null || true
        
        # Remove service file
        rm -f "/etc/systemd/system/$SERVICE_NAME.service"
        systemctl daemon-reload
        
        # Remove files
        rm -rf /opt/funpay-boost
        rm -rf /etc/funpay
        rm -rf /var/log/funpay
        rm -f /usr/local/bin/funpay-boost
        
        # Remove user
        userdel funpay 2>/dev/null || true
        
        echo -e "${GREEN}✅ Uninstallation completed${NC}"
        echo -e "${YELLOW}You can now exit this script${NC}"
    else
        echo -e "${YELLOW}Operation cancelled${NC}"
    fi
    
    read -p "Press Enter to continue..."
    advanced_menu
}

reset_defaults() {
    echo -e "${CYAN}🔧 Reset to Defaults${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    echo -e "${RED}⚠️ This will reset configuration to defaults!${NC}"
    echo ""
    
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    if [[ "$confirm" == "yes" ]]; then
        # Backup current config
        if [[ -f "$CONFIG_FILE" ]]; then
            cp "$CONFIG_FILE" "/tmp/config_backup_$(date +%Y%m%d_%H%M%S).json"
        fi
        
        # Create default config
        cat > "$CONFIG_FILE" << 'EOF'
{
  "username": "",
  "password": "",
  "target_url": "",
  "boost_interval": 3,
  "last_boost": null,
  "auto_restart": true,
  "max_retries": 5,
  "retry_delay": 1800
}
EOF
        
        echo -e "${GREEN}✅ Configuration reset to defaults${NC}"
        echo -e "${YELLOW}Please update your credentials and URL${NC}"
    else
        echo -e "${YELLOW}Operation cancelled${NC}"
    fi
    
    read -p "Press Enter to continue..."
    advanced_menu
}

update_components() {
    echo -e "${CYAN}📦 Update Components${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Updating system packages...${NC}"
    apt update && apt upgrade -y
    
    echo -e "${YELLOW}Updating Python packages...${NC}"
    /opt/funpay-boost/venv/bin/pip install --upgrade pip
    /opt/funpay-boost/venv/bin/pip install --upgrade selenium requests beautifulsoup4 lxml
    
    echo -e "${GREEN}✅ Components updated${NC}"
    echo -e "${YELLOW}Restart service to apply changes${NC}"
    
    read -p "Press Enter to continue..."
    advanced_menu
}

debug_mode() {
    echo -e "${CYAN}🔍 Debug Mode${NC}"
    echo -e "${CYAN}═══════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Running in debug mode...${NC}"
    echo -e "${YELLOW}This will show detailed output${NC}"
    echo ""
    
    # Stop service
    systemctl stop $SERVICE_NAME 2>/dev/null || true
    
    # Run in foreground with debug
    sudo -u funpay /opt/funpay-boost/venv/bin/python /opt/funpay-boost/funpay_boost.py --daemon
    
    read -p "Press Enter to continue..."
    advanced_menu
}

system_cleanup() {
    echo -e "${CYAN}💾 System Cleanup${NC}"
    echo -e "${CYAN}═════════���═════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Cleaning up system...${NC}"
    
    # Clean logs
    journalctl --vacuum-time=7d
    
    # Clean temp files
    rm -f /tmp/funpay_*
    rm -f /tmp/geckodriver*
    
    # Kill orphaned processes
    pkill -f firefox 2>/dev/null || true
    pkill -f geckodriver 2>/dev/null || true
    pkill -f Xvfb 2>/dev/null || true
    
    # Clean package cache
    apt autoremove -y
    apt autoclean
    
    echo -e "${GREEN}✅ System cleanup completed${NC}"
    
    read -p "Press Enter to continue..."
    advanced_menu
}

# Check if running as root for certain operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This operation requires root privileges${NC}"
        echo -e "${YELLOW}Please run with sudo${NC}"
        exit 1
    fi
}

# Main execution
main() {
    # Check if service exists
    if [[ ! -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
        show_header
        echo -e "${RED}❌ FunPay Auto Boost service not found!${NC}"
        echo -e "${YELLOW}Please run the installation script first${NC}"
        exit 1
    fi
    
    # Start main menu loop
    while true; do
        show_main_menu
    done
}

# Run main function
main "$@"
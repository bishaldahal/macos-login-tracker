#!/bin/bash

# Login/Logout Time Tracker for macOS
# Generates a CSV report of daily login sessions with working hours calculation
# Author: GitHub Copilot
# Date: $(date +"%Y-%m-%d")

# Configuration
WORK_START_HOUR=9    # 9:00 AM
WORK_END_HOUR=18     # 6:00 PM
OUTPUT_FILE="login_report_$(date +%Y%m%d).csv"
TEMP_FILE="/tmp/last_output_$$"
DEBUG=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to log debug messages
debug_log() {
    if [ "$DEBUG" = true ]; then
        print_color $YELLOW "DEBUG: $1" >&2
    fi
}

# Function to convert time to minutes since midnight
time_to_minutes() {
    local time_str="$1"
    local hour minute
    
    # Handle different time formats (HH:MM, H:MM, etc.)
    if [[ $time_str =~ ^([0-9]{1,2}):([0-9]{2})$ ]]; then
        hour=${BASH_REMATCH[1]}
        minute=${BASH_REMATCH[2]}
    else
        echo "0"
        return
    fi
    
    # Remove leading zeros
    hour=$((10#$hour))
    minute=$((10#$minute))
    
    echo $((hour * 60 + minute))
}

# Function to convert minutes to HH:MM format
minutes_to_time() {
    local total_minutes=$1
    local hours=$((total_minutes / 60))
    local minutes=$((total_minutes % 60))
    printf "%02d:%02d" $hours $minutes
}

# Function to calculate duration between two times in minutes
calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    local start_minutes=$(time_to_minutes "$start_time")
    local end_minutes=$(time_to_minutes "$end_time")
    
    # Handle overnight sessions (end time next day)
    if [ $end_minutes -lt $start_minutes ]; then
        end_minutes=$((end_minutes + 1440)) # Add 24 hours
    fi
    
    echo $((end_minutes - start_minutes))
}

# Function to parse date from last command output
parse_date() {
    local line="$1"
    local date_part=""
    
    # Extract date from various last command formats
    # Format: "user console Tue Aug 26 09:30 - 17:45 (08:15)"
    # Format: "user ttys000 Mon Aug 25 09:30 still logged in"
    # Format: "user console Fri Aug 22 16:42 - crash (00:51)"
    
    # Look for pattern: DayOfWeek Month Day
    if [[ $line =~ [[:space:]]+([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2})[[:space:]]+ ]]; then
        date_part="${BASH_REMATCH[1]}"
    fi
    
    # Convert to YYYY-MM-DD format
    if [ -n "$date_part" ]; then
        local year=$(date +%Y)
        
        # Extract month and day from "Mon Aug 26" format
        if [[ $date_part =~ [A-Za-z]{3}[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{1,2}) ]]; then
            local month="${BASH_REMATCH[1]}"
            local day="${BASH_REMATCH[2]}"
            
            # Convert using just month and day
            local formatted_date=$(date -j -f "%b %d" "$month $day" "+%Y-%m-%d" 2>/dev/null || echo "")
            
            # Handle year boundary issues
            if [ -n "$formatted_date" ]; then
                local current_date=$(date +%Y-%m-%d)
                if [[ "$formatted_date" > "$current_date" ]]; then
                    # Date is in the future, probably last year
                    year=$((year - 1))
                    formatted_date=$(date -j -f "%b %d" "$month $day" "+$year-%m-%d" 2>/dev/null || echo "")
                fi
            fi
            
            echo "$formatted_date"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# Function to extract login/logout times from a line
extract_times() {
    local line="$1"
    local login_time=""
    local logout_time=""
    local status=""
    
    # Pattern for completed sessions: "Tue Aug 26 09:30 - 17:45 (08:15)"
    if [[ $line =~ [0-9]{1,2}:[0-9]{2}[[:space:]]*-[[:space:]]*([0-9]{1,2}:[0-9]{2})[[:space:]]*\(([0-9]{2}:[0-9]{2})\) ]]; then
        # Extract both login and logout times
        if [[ $line =~ ([0-9]{1,2}:[0-9]{2})[[:space:]]*-[[:space:]]*([0-9]{1,2}:[0-9]{2}) ]]; then
            login_time="${BASH_REMATCH[1]}"
            logout_time="${BASH_REMATCH[2]}"
            status="completed"
        fi
    # Pattern for ongoing sessions: "Tue Aug 26 09:30 still logged in"
    elif [[ $line =~ ([0-9]{1,2}:[0-9]{2})[[:space:]]+still[[:space:]]+logged[[:space:]]+in ]]; then
        login_time="${BASH_REMATCH[1]}"
        logout_time=""
        status="ongoing"
    # Pattern for crashed sessions: "Tue Aug 26 09:30 - crash (01:00)"
    elif [[ $line =~ ([0-9]{1,2}:[0-9]{2})[[:space:]]*-[[:space:]]*crash ]]; then
        login_time="${BASH_REMATCH[1]}"
        logout_time=""
        status="crashed"
    # Pattern for zero-duration sessions: "Tue Aug 26 09:30 - 09:30 (00:00)"
    elif [[ $line =~ ([0-9]{1,2}:[0-9]{2})[[:space:]]*-[[:space:]]*([0-9]{1,2}:[0-9]{2})[[:space:]]*\(00:00\) ]]; then
        login_time="${BASH_REMATCH[1]}"
        logout_time="${BASH_REMATCH[2]}"
        status="zero_duration"
    # Pattern for simple time entry: "Tue Aug 26 09:30"
    elif [[ $line =~ ([0-9]{1,2}:[0-9]{2}) ]]; then
        login_time="${BASH_REMATCH[1]}"
        logout_time=""
        status="simple"
    fi
    
    echo "$login_time|$logout_time|$status"
}

# Function to process sessions for a single date
process_date_sessions() {
    local date="$1"
    local sessions_file="$2"
    
    local first_login=""
    local last_logout=""
    local intermediate_sessions=""
    local session_count=0
    local last_logout_time=""
    local actual_last_logout=""
    
    debug_log "Processing sessions for date: $date"
    
    # Read all sessions for this date and sort by time
    local sorted_sessions=$(grep "^$date" "$sessions_file" | sort -k2)
    
    while IFS='|' read -r sess_date login_time logout_time status; do
        if [ -z "$sess_date" ]; then continue; fi
        
        session_count=$((session_count + 1))
        debug_log "Session $session_count: $login_time -> $logout_time ($status)"
        
        # Set first login (earliest time)
        if [ -z "$first_login" ]; then
            first_login="$login_time"
        else
            # Compare times and keep the earliest
            local first_minutes=$(time_to_minutes "$first_login")
            local current_minutes=$(time_to_minutes "$login_time")
            if [ $current_minutes -lt $first_minutes ]; then
                first_login="$login_time"
            fi
        fi
        
        # Determine the last logout time
        case "$status" in
            "completed")
                last_logout_time="$logout_time"
                actual_last_logout="$logout_time"
                ;;
            "ongoing")
                last_logout_time=$(date +%H:%M)
                actual_last_logout="ongoing"
                ;;
            "crashed"|"simple")
                # For crashed sessions, estimate end time as 1 hour after login
                local crash_end_minutes=$(time_to_minutes "$login_time")
                crash_end_minutes=$((crash_end_minutes + 60))
                last_logout_time=$(minutes_to_time $crash_end_minutes)
                if [ -z "$actual_last_logout" ] || [ "$actual_last_logout" = "ongoing" ]; then
                    actual_last_logout="$login_time(est)"
                fi
                ;;
        esac
        
        # Update the last logout if this session ends later
        if [ -n "$last_logout_time" ]; then
            if [ -z "$last_logout" ]; then
                last_logout="$last_logout_time"
            else
                local last_minutes=$(time_to_minutes "$last_logout")
                local current_end_minutes=$(time_to_minutes "$last_logout_time")
                if [ $current_end_minutes -gt $last_minutes ]; then
                    last_logout="$last_logout_time"
                fi
            fi
        fi
        
        # Build intermediate sessions string
        local session_str="$login_time"
        if [ -n "$logout_time" ]; then
            session_str="$session_str-$logout_time"
        elif [ "$status" = "ongoing" ]; then
            session_str="$session_str-ongoing"
        else
            session_str="$session_str-crashed"
        fi
        
        if [ -n "$intermediate_sessions" ]; then
            intermediate_sessions="$intermediate_sessions; $session_str"
        else
            intermediate_sessions="$session_str"
        fi
        
    done <<< "$sorted_sessions"
    
    # If no sessions found, return empty values
    if [ $session_count -eq 0 ]; then
        echo "$date,No Activity,No Activity,,0:00"
        return
    fi
    
    # Calculate total working hours from first login to last logout
    local total_minutes=0
    local total_hours_str="0:00"
    
    if [ -n "$first_login" ] && [ -n "$last_logout" ]; then
        if [ "$actual_last_logout" = "ongoing" ]; then
            # Calculate from first login to current time
            local current_time=$(date +%H:%M)
            total_minutes=$(calculate_duration "$first_login" "$current_time")
            total_hours_str=$(minutes_to_time $total_minutes)
        elif [[ "$actual_last_logout" =~ \(est\) ]]; then
            # Handle estimated end times
            local est_time=$(echo "$actual_last_logout" | sed 's/(est)//')
            total_minutes=$(calculate_duration "$first_login" "$est_time")
            # Add 1 hour for estimated crash duration
            total_minutes=$((total_minutes + 60))
            total_hours_str=$(minutes_to_time $total_minutes)
        else
            # Normal case: calculate from first login to last logout
            total_minutes=$(calculate_duration "$first_login" "$last_logout")
            total_hours_str=$(minutes_to_time $total_minutes)
        fi
    fi
    
    # Clean up intermediate sessions for single session days
    if [ $session_count -eq 1 ] && [[ ! "$intermediate_sessions" =~ (ongoing|crashed) ]]; then
        intermediate_sessions="None"
    fi
    
    # Ensure we have values for first login and last logout
    if [ -z "$first_login" ]; then first_login="N/A"; fi
    if [ -z "$actual_last_logout" ]; then 
        actual_last_logout="N/A"
    fi
    if [ -z "$intermediate_sessions" ]; then intermediate_sessions="None"; fi
    
    echo "$date,$first_login,$actual_last_logout,$intermediate_sessions,$total_hours_str"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --days DAYS     Number of days to analyze (default: 30)"
    echo "  -o, --output FILE   Output CSV file (default: login_report_YYYYMMDD.csv)"
    echo "  -w, --work-hours START:END  Work hours range (default: 9:18)"
    echo "  -u, --user USER     Specific user to analyze (default: current user)"
    echo "  --debug             Enable debug output"
    echo "  --update            Update to the latest version"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -d 7                    # Analyze last 7 days"
    echo "  $0 -o weekly_report.csv    # Custom output file"
    echo "  $0 -w 8:17                 # Work hours 8 AM to 5 PM"
    echo "  $0 --debug                 # Enable debug mode"
    echo "  $0 --update                # Update to latest version"
}

# Function to update the script
update_script() {
    print_color $BLUE "macOS Login Tracker - Self Update"
    print_color $BLUE "================================="
    echo ""
    
    local script_path="$(realpath "$0")"
    local temp_file="/tmp/login_tracker_update_$$"
    local backup_file="${script_path}.backup"
    local repo_url="https://raw.githubusercontent.com/bishaldahal/macos-login-tracker/main/login_tracker.sh"
    
    print_color $YELLOW "Downloading latest version..."
    
    # Download the latest version
    if curl -fsSL "$repo_url" -o "$temp_file"; then
        print_color $GREEN "✓ Successfully downloaded latest version"
    else
        print_color $RED "✗ Failed to download update"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Backup current version
    if cp "$script_path" "$backup_file"; then
        print_color $GREEN "✓ Current version backed up"
    else
        print_color $RED "✗ Failed to create backup"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Replace current script with new version
    if mv "$temp_file" "$script_path" 2>/dev/null; then
        chmod +x "$script_path"
        print_color $GREEN "✓ Script updated successfully"
        rm -f "$backup_file"
    else
        print_color $RED "✗ Failed to update script"
        # Restore backup
        mv "$backup_file" "$script_path" 2>/dev/null
        rm -f "$temp_file"
        exit 1
    fi
    
    echo ""
    print_color $GREEN "🎉 Update Complete!"
    echo ""
    print_color $BLUE "Your login tracker has been updated to the latest version."
    print_color $BLUE "You can now use the updated script with the same commands."
    echo ""
    exit 0
}

# Main function
main() {
    local days=30
    local target_user=$(whoami)
    local work_hours="9:18"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--days)
                days="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -w|--work-hours)
                work_hours="$2"
                IFS=':' read -r WORK_START_HOUR WORK_END_HOUR <<< "$work_hours"
                shift 2
                ;;
            -u|--user)
                target_user="$2"
                shift 2
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --update)
                update_script
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_color $BLUE "Login/Logout Time Tracker for macOS"
    print_color $BLUE "===================================="
    echo ""
    print_color $GREEN "Configuration:"
    echo "  Target User: $target_user"
    echo "  Analysis Period: Last $days days"
    echo "  Work Hours: $WORK_START_HOUR:00 - $WORK_END_HOUR:00"
    echo "  Output File: $OUTPUT_FILE"
    echo ""
    
    # Get last command output
    print_color $YELLOW "Gathering login data..."
    
    # Use last command with specific user - get more lines to ensure we capture the time range
    # The last command doesn't have a direct "days" filter, so we get more data and filter by date later
    local max_lines=$((days * 20))  # Estimate 20 sessions per day max
    last -$max_lines "$target_user" > "$TEMP_FILE" 2>/dev/null
    
    # If that doesn't work or gives too little data, try without line limit
    if [ ! -s "$TEMP_FILE" ] || [ $(wc -l < "$TEMP_FILE") -lt 5 ]; then
        print_color $YELLOW "Getting more comprehensive login data..."
        last "$target_user" > "$TEMP_FILE" 2>/dev/null
    fi
    
    if [ ! -s "$TEMP_FILE" ]; then
        print_color $RED "Error: No login data found for user '$target_user'"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    debug_log "Raw last command output saved to $TEMP_FILE"
    
    # Create temporary sessions file
    local sessions_file="/tmp/sessions_$$"
    
    # Parse last command output
    print_color $YELLOW "Parsing login sessions..."
    
    while IFS= read -r line; do
        # Skip empty lines and headers
        if [[ -z "$line" || "$line" =~ ^wtmp || "$line" =~ ^$ ]]; then
            continue
        fi
        
        # Skip very short terminal sessions (ttys*) that are (00:00) duration
        # But keep console sessions and longer terminal sessions
        if [[ "$line" =~ ttys[0-9]+ ]] && [[ "$line" =~ \(00:00\) ]]; then
            debug_log "Skipping short terminal session: $line"
            continue
        fi
        
        debug_log "Processing line: $line"
        
        # Extract date
        local session_date=$(parse_date "$line")
        if [ -z "$session_date" ]; then
            debug_log "Could not parse date from: $line"
            continue
        fi
        
        # Extract times
        local time_info=$(extract_times "$line")
        IFS='|' read -r login_time logout_time status <<< "$time_info"
        
        if [ -n "$login_time" ]; then
            echo "$session_date|$login_time|$logout_time|$status" >> "$sessions_file"
            debug_log "Added session: $session_date $login_time -> $logout_time ($status)"
        fi
        
    done < "$TEMP_FILE"
    
    # Create CSV header
    print_color $YELLOW "Generating CSV report..."
    
    echo "Date,First Login,Last Logout,Intermediate Sessions,Total Working Hours" > "$OUTPUT_FILE"
    
    # Calculate the cutoff date (days ago)
    local cutoff_date
    if command -v gdate &> /dev/null; then
        # Use GNU date if available (from coreutils)
        cutoff_date=$(gdate -d "$days days ago" +%Y-%m-%d)
    else
        # Use BSD date (macOS default)
        cutoff_date=$(date -j -v-${days}d +%Y-%m-%d)
    fi
    
    debug_log "Cutoff date for analysis: $cutoff_date"
    
    # Get unique dates and process each one, filtering by cutoff date
    local unique_dates=$(cut -d'|' -f1 "$sessions_file" | sort -u | sort -r)
    
    while IFS= read -r date; do
        if [ -n "$date" ]; then
            # Compare dates using lexicographic comparison (works for YYYY-MM-DD format)
            if [ "$date" \> "$cutoff_date" ] || [ "$date" = "$cutoff_date" ]; then
                debug_log "Processing date: $date (within range)"
                local csv_line=$(process_date_sessions "$date" "$sessions_file")
                echo "$csv_line" >> "$OUTPUT_FILE"
            else
                debug_log "Skipping date: $date (outside range)"
            fi
        else
            debug_log "Skipping empty date"
        fi
    done <<< "$unique_dates"
    
    # Clean up temporary files
    rm -f "$TEMP_FILE" "$sessions_file"
    
    # Display summary
    local total_days=$(wc -l < "$OUTPUT_FILE")
    total_days=$((total_days - 1)) # Subtract header
    
    print_color $GREEN "Report generated successfully!"
    echo ""
    print_color $BLUE "Summary:"
    echo "  Total days analyzed: $total_days"
    echo "  Output file: $OUTPUT_FILE"
    echo "  File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    
    # Show first few lines of the report
    print_color $BLUE "Preview of generated report:"
    echo "==============================="
    head -6 "$OUTPUT_FILE"
    
    if [ $total_days -gt 5 ]; then
        echo "... (showing first 5 days)"
    fi
    
    echo ""
    print_color $GREEN "Report saved to: $OUTPUT_FILE"
}

# Error handling
set -euo pipefail
trap 'print_color $RED "Error occurred on line $LINENO"; exit 1' ERR

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_color $RED "Error: This script is designed for macOS only"
    exit 1
fi

# Check if last command is available
if ! command -v last &> /dev/null; then
    print_color $RED "Error: 'last' command not found"
    exit 1
fi

# Run main function
main "$@"
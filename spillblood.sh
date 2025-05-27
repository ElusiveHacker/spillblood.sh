#!/usr/bin/env bash

# ========================================================================================
# spillblood.sh - Starts BloodHound and Neo4j for Active Directory Analysis
# GNU Bash 5.2.37(1)-release compatible
# ========================================================================================

# ------------------------------------
# Global Variables and Defaults
# ------------------------------------
export SCRIPT_DIR="$(dirname "$0")"
export OUTPUT_DIR="$SCRIPT_DIR/bloodhound_outputs"
mkdir -p "$OUTPUT_DIR"

LOG_FILE="$SCRIPT_DIR/bloodhound.log"
DATE_TIME="$(date +%Y%m%d_%H%M)"
REPORT_FILE="$SCRIPT_DIR/${DATE_TIME}_blood_report.txt"

export QUIET_MODE=false  # Define QUIET_MODE to avoid unbound variable issues

# ------------------------------------
# Logging Functions
# ------------------------------------
log() {
    local type="$1"
    local msg="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$type] $msg" | tee -a "$LOG_FILE" >> "$REPORT_FILE"
}

append_to_report() {
    local section="$1"
    local message="$2"
    echo -e "\n---------- $section ----------" >> "$REPORT_FILE"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$REPORT_FILE"
}

# ------------------------------------
# Root Privilege Check
# ------------------------------------
check_root() {
    if [[ $(id -u) -ne 0 ]]; then
        log "ERROR" "Script must run as root. Use sudo."
        exit 1
    else
        export trueRoot=true
        [[ "$QUIET_MODE" = false ]] && echo "[+] SCRIPT IS RUNNING AS ROOT"
        log "INFO" "Script is running as root."
    fi
}

# ------------------------------------
# Argument Parsing
# ------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help|help)
                print_help
                ;;
            *)
                log "ERROR" "Unknown argument: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

print_help() {
    cat << EOF
Usage: $0 [options]

BloodHound and Neo4j Start Script for Active Directory Analysis

Options:
  This script does not take any input arguments.
  -h, --help        Show this help message and exit

Example:
  sudo ./spillblood.sh

The script starts Neo4j and BloodHound, logging output to $LOG_FILE and $REPORT_FILE.
Note: Ensure Neo4j and BloodHound are installed, and a GUI environment is available if running BloodHound's interface.
EOF
    exit 0
}

# ------------------------------------
# Check Neo4j Status
# ------------------------------------
check_neo4j_status() {
    local max_attempts=30
    local attempt=1
    log "INFO" "Checking if Neo4j is running..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null http://localhost:7474; then
            log "INFO" "Neo4j is running and accessible on port 7474"
            return 0
        fi
        log "INFO" "Neo4j not yet ready (attempt $attempt/$max_attempts). Waiting 2 seconds..."
        sleep 2
        ((attempt++))
    done
    log "ERROR" "Neo4j failed to start after $max_attempts attempts. Check logs at /var/lib/neo4j/logs/neo4j.log"
    exit 1
}

# ------------------------------------
# Start Neo4j Database
# ------------------------------------
execute_neo4j_db() {
    if ! command -v neo4j >/dev/null 2>&1; then
        log "ERROR" "neo4j is not installed. Install it with 'apt install neo4j' or equivalent."
        exit 1
    fi

    # Check if Neo4j is already running
    if curl -s -o /dev/null http://localhost:7474; then
        log "INFO" "Neo4j is already running on port 7474"
        return 0
    fi

    log "INFO" "Starting Neo4j database..."
    CMD="neo4j console"
    log "INFO" "Executing: $CMD"
    # Run Neo4j in the background and redirect output to a log file
    eval "$CMD" > "$OUTPUT_DIR/neo4j_output.log" 2>&1 &
    NEO4J_PID=$!
    log "INFO" "Neo4j started with PID $NEO4J_PID"

    # Wait for Neo4j to be fully up
    check_neo4j_status
}

# ------------------------------------
# Start BloodHound
# ------------------------------------
execute_bloodhound() {
    if ! command -v bloodhound >/dev/null 2>&1; then
        log "ERROR" "bloodhound is not installed. Install it with 'apt install bloodhound' or equivalent."
        exit 1
    fi

    log "INFO" "Starting BloodHound..."
    CMD="bloodhound"
    log "INFO" "Executing: $CMD"
    # Run BloodHound in the foreground (it typically opens a GUI)
    OUT=$(eval "$CMD" 2>&1)
    if [[ $? -ne 0 ]]; then
        log "ERROR" "BloodHound failed to start. Output: $OUT"
        append_to_report "BloodHound Failure" "$OUT"
        exit 1
    fi
    log "INFO" "BloodHound started successfully."
    append_to_report "BloodHound Output" "$OUT"
}

# ------------------------------------
# Main Execution
# ------------------------------------
main() {
    log "INFO" "Starting BloodHound and Neo4j at $(date '+%Y-%m-%d %H:%M:%S')"
    check_root
    parse_args "$@"
    execute_neo4j_db
    execute_bloodhound
    log "INFO" "Script completed. Logs saved to $LOG_FILE and $REPORT_FILE"
}

main "$@"

# Trap to clean up Neo4j process on script exit
trap 'log "INFO" "Shutting down Neo4j..."; kill $NEO4J_PID 2>/dev/null' EXIT

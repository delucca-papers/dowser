#!/usr/bin/env bash

function report_process_memory_usage {
    local pid=${1}
    
    local pid_rollup=$(cat "/proc/${pid}/smaps_rollup" 2>/dev/null)
    local rss_usage=$(echo "${pid_rollup}" | grep -i "Rss" | awk '{print $2}')
    local shared_clean_usage=$(echo "${pid_rollup}" | grep -i "Shared_Clean" | awk '{print $2}')
    local shared_dirty_usage=$(echo "${pid_rollup}" | grep -i "Shared_Dirty" | awk '{print $2}')
    local swap_usage=$(echo "${pid_rollup}" | grep -i "Swap:" | awk '{print $2}')
    
    echo ${rss_usage} ${shared_clean_usage} ${shared_dirty_usage} ${swap_usage}
}

function report_progress {
    local current_iteration=$1
    local iterations_total=$2
    local description=${@:3}

    local percentage=$((100 * ${current_iteration} / ${iterations_total}))
    local percentage_characters=$((${#percentage} + 7))
    local available_space=$((${TERMINAL_COLUMNS} - ${percentage_characters}))
    local percentage_space=$((${percentage} * ${available_space} / 100))
    local empty_space=$((${available_space} - ${percentage_space}))
    local percentage_seq=$(seq 1 ${percentage_space})
    local empty_seq=$(seq 1 ${empty_space})
    local percentage_bar=$(printf "#%.0s"  ${percentage_seq})
    local empty_bar=$(printf " %.0s"  ${empty_seq})
    local bar_span="  "; if [ "${percentage}" -eq "100" ]; then bar_span=" "; fi
    
    local description_header="Executing task: ${description}"
    local description_status="Iteration ${current_iteration} of ${iterations_total}"
    local description_space=$((${TERMINAL_COLUMNS} - ${#description_header} - ${#description_status}))
    
    if [ "${percentage}" -eq "0" ]; then
        unset percentage_bar
    fi
 
    echo -e "${description_header}$(printf ' %.0s' $(seq 1 ${description_space}))${description_status}"
    echo -e "[${percentage_bar}${empty_bar}]${bar_span}(${percentage}%)\r"

    if [ ! "${percentage}" -eq "100" ]; then
        tput cuu1 && tput cuu1
    fi
}
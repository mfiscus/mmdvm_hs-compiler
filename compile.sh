#!/usr/bin/env bash

# This tool was written to wrap docker compose commands

# strict mode
set -Eeuo pipefail
IFS=$'\n\t'

# debug mode
#set -o verbose

# define global variables

# set TERM to xterm if not already set
[[ ${TERM} =~ ^xterm.* ]] || export TERM="xterm"

# script name
#readonly script_name=$( echo ${0##*/} | sed 's/\.sh*$//' )
readonly script_name=${0##*/}

# tool name
readonly tool_name="KK7MNZ's Containerized MMDVM_HS Compiler"

# get logname
readonly logname=$( whoami )

# hardware types
readonly types=(
    "D2RG_MMDVM_HS"
    "generic_gpio"
    "MMDVM_HS_Dual_Hat"
    "NanoDV_NPI"
    "SkyBridge_RPi"
    "ZUMspot_Libre"
    "generic_duplex_gpio"
    "LoneStar_USB"
    "MMDVM_HS_Hat-12mhz"
    "NanoDV_USB"
    "ZUMspot_dualband"
    "ZUMspot_RPi"
    "generic_duplex_usb"
    "MMDVM_HS_Dual_Hat-12mhz"
    "MMDVM_HS_Hat"
    "Nano_hotSPOT"
    "ZUMspot_duplex"
    "ZUMspot_USB"

)


# hardware descriptions
readonly descriptions=(
    "D2RG MMDVM_HS RPi (BG3MDO, VE2GZI, CA6JAU)"
    "Libre Kit board or any homebrew hotspot with modified RF7021SE and Blue Pill STM32F103"
    "MMDVM_HS_Dual_Hat revisions 1.0 (DB9MAT & DF2ET & DO7EN)"
    "NanoDV NPi or USB revisions 1.1 (BG4TGO & BG5HHP)"
    "BridgeCom SkyBridge HotSpot"
    "Libre Kit board or any homebrew hotspot with modified RF7021SE and Blue Pill STM32F103"
    "Libre Kit board or any homebrew hotspot with modified RF7021SE and Blue Pill STM32F103"
    "LoneStar USB Stick ADF7071"
    "MMDVM_HS_Hat revisions 1.1, 1.2 and 1.4 (DB9MAT & DF2ET) 12mHz"
    "NanoDV NPi or USB revisions 1.1 (BG4TGO & BG5HHP)"
    "ZUMspot RPi or ZUMspot USB"
    "ZUMspot RPi or ZUMspot USB"
    "Libre Kit board or any homebrew hotspot with modified RF7021SE and Blue Pill STM32F103"
    "MMDVM_HS_Dual_Hat revisions 1.0 (DB9MAT & DF2ET & DO7EN)"
    "MMDVM_HS_Hat revisions 1.1, 1.2 and 1.4 (DB9MAT & DF2ET) 14mHz"
    "Nano hotSPOT (BI7JTA)"
    "ZUMspot RPi or ZUMspot USB"
    "ZUMspot RPi or ZUMspot USB"

)


# cleanup working copy
function __cleanup() {
    rm -f ./${hardware_type}-docker-compose.yml
    dialog --clear
    clear

    return

}


# remove temporary files upon trapping SIGHUP/SIGINT/SIGKILL/SIGTERM
trap __cleanup HUP INT KILL TERM


# function to catch error messages
# ${1} = error message
# ${2} = exit code
function __throw_error() {

    # validate arguments
    if [ ${#} -eq 2 ]; then
        local message=${1}
        local exit_code=${2}

        # log specific error message to syslog and write to STDERR
        logger -s -p user.err -t ${script_name}"["${logname}"]" -- ${message}

        exit ${exit_code}

    else

        # log generic error message to syslog and write to STDERR
        logger -s -p user.err -t ${tool_name}"["${logname}"]" -- "an unknown error occured"

        exit 255

    fi

}


# interpret command-line arguments

# usage
function __print_usage() {
    # disable verbosity to enhance readablity
    set +o verbose

    # print usage
    echo -e "\n\nUsage options:"
    echo -e "\t-h | --help"
    echo -e "\t-t | --hardware-type <hardware type>"
    echo -e "\t-q | --quiet"
    echo -e "\t-v | --verbose"
    echo -e "\nExample usage:"
    echo -e "\t"${script_name}" --quiet --hardware-type MMDVM_HS_Hat"
    echo -e "\t"${script_name}" --help"
    echo -e "\nHardware types supported:"
    echo -e "\tD2RG_MMDVM_HS generic_gpio MMDVM_HS_Dual_Hat NanoDV_NPI"
    echo -e "\tSkyBridge_RPi ZUMspot_Libre generic_duplex_gpio LoneStar_USB"
    echo -e "\tMMDVM_HS_Hat-12mhz NanoDV_USB ZUMspot_dualband ZUMspot_RPi"
    echo -e "\tgeneric_duplex_usb MMDVM_HS_Dual_Hat-12mhz MMDVM_HS_Hat"
    echo -e "\tNano_hotSPOT ZUMspot_duplex ZUMspot_USB\n"
    
    return

}


function __get_hardware_type() {
    local -a choice
    local choice_count=0
    local options i j

    options="
        dialog 
            --no-shadow 
            --cancel-label \"Quit\" 
            --backtitle \"${tool_name}\" 
            --menu \"Select hardware type to compile for:\" 16 76 76" 

    for i in "${!types[@]}"; do
        options+="
            \""${types[${i}]}"\" \""${descriptions[${i}]}"\""
    
    done

    # strip any trailing slashes
    options=$( echo ${options} | sed 's:\\*$::' )

    for j in $( eval "${options}" 3>&2 2>&1 1>&3 ); do
        choice[${choice_count}]=${j}
        (( ++choice_count ))

    done

    echo ${choice[0]:-}

}


# function to confirm selection
# $1 = hardware type
__edit_compose_file() {
    if [ $# -eq 1 ]; then
        # declare variables local to this function
        local hardware_type=${1}
    cat << EOF > ${hardware_type}-docker-compose.yml
version: "3.9"
services:
  mmdvm_hs:
    container_name: mmdvm_hs
    user: $(id -u):$(id -g)
    platform: linux/arm/v7
    build:
      context: .
      dockerfile: Dockerfile
      platforms: 
        - linux/arm/v7
      args:
        TYPE: ${hardware_type}
    volumes:
      - ./:/artifacts
    network_mode: none
    restart: no
EOF

    else
        return 255
    
    fi

}


# compile mmdvm_hs
# $1 = hardware type
function __mmdvm_hs_compile() {
    if [ ${#} -eq 1 ]; then
        # declare variables local to this function
        local hardware_type=${1}

        if [ ! -z ${quiet:-} ]; then
            docker compose --quiet --file ./${hardware_type}-docker-compose.yml build &>/dev/null
            docker compose --quiet --file ./${hardware_type}-docker-compose.yml up -d --remove-orphans &>/dev/null
            docker compose --quiet --file ./${hardware_type}-docker-compose.yml down &>/dev/null
        
        else
            docker compose --file ./${hardware_type}-docker-compose.yml build 2>&1 | __please_wait "Building Docker container and compiling source code"
            docker compose --file ./${hardware_type}-docker-compose.yml up -d --remove-orphans 2>&1 | __please_wait "Starting Docker container and extracting binary files"
            docker compose --file ./${hardware_type}-docker-compose.yml down 2>&1 | __please_wait "Stopping and removing Docker container"

        fi

        return ${?}

    else
        return 255
    
    fi

}


# function to confirm selection
# $1 = hardware type
function __confirm_action() {
    # validate argument
    if [ $# -eq 1 ]; then
        # declare variables local to this function
        local hardware_type=${1}
        local confirmation c choice_count=0
        local -a choice
        
        
        confirmation="
            dialog
                --no-shadow 
                --clear 
                --cancel-label \"Cancel\" 
                --backtitle \"${tool_name}\" 
                --inputbox \"Are you sure you want to compile firmware for:\n\n"${hardware_type}"\n\nType CONFIRM: \" 0 0 "
        
        
        # launch dialog and split output into an array
        # strip any trailing slashes
        confirmation=$( echo ${confirmation} | sed 's:\\*$::' )

        for c in $( eval "${confirmation}" 3>&2 2>&1 1>&3 ); do
            choice[${choice_count}]=${c}
            (( ++choice_count ))

        done

        [ -z ${choice[0]:-} ] && choice[0]="cancel"

        # case return value (in lower case)
        case "${choice[0],,}" in
            "confirm") # positive confirmation
                # just in case the object has a null property
                if [ -n "${choice[0]:-}" ]; then
                    # return true
                    return 0
                    
                else
                    # this shouldn't happen
                    __throw_error "unexpected response" 255
                    
                fi
                ;;
                
            *)  # negative confirmation
                __cleanup
                return 1
                ;;
                
        esac
        
    fi
    
}


# function to display wait message
# $1 = message
function __please_wait() {
    # validate argument
    if [ $# -eq 1 ]; then
        local wait_message=${1}
        dialog \
            --keep-window \
            --no-shadow \
            --scrollbar \
            --trim \
            --sleep 3 \
            --backtitle "${tool_name}" \
            --progressbox ${wait_message} 16 76

    fi

}


# function to display wait message
# $1 = message
function __done_prompt() {
    # validate argument
    if [ $# -eq 1 ]; then
        local done_message=${1}
        dialog \
            --no-shadow \
            --backtitle "${tool_name}" \
            --msgbox ${done_message} 8 50

    fi

}


# check for dependancies
# ${1} = dependancy
function __check_dependancy() {
    if [ ${#} -eq 1 ]; then
        local dependancy=${1}
        local exit_code=${null:-}

        type ${dependancy} &>/dev/null; exit_code=${?}
        
        if [ ${exit_code} -ne 0 ]; then
            return 255

        fi

    else
        return 1
        
    fi
    
}


####################
### main program ###
####################

# validate dependancies
readonly -a dependancies=( 'dialog' 'docker' 'logger' )
declare -i dependancy=0

while [ "${dependancy}" -lt "${#dependancies[@]}" ]; do
    __check_dependancy ${dependancies[${dependancy}]} || __throw_error ${dependancies[${dependancy}]}" required" ${?}

    (( ++dependancy ))

done

unset dependancy


# make sure we're using least bash 4 for proper support of associative arrays
[ $( echo ${BASH_VERSION} | grep -o '^[0-9]' ) -ge 4 ] || __throw_error "Please upgrade to at least bash version 4" ${?}


# Transform long options to short ones
for argv in "${@}"; do
    case "${argv}" in
        "--help"|"?")
            set -- "${@}" "-h"
            ;;

        "--hardware-type")
            set -- "${@}" "-t"
            ;;

        "--quiet")
            set -- "${@}" "-q"
            ;;

        "--verbose")
            set -- "${@}" "-v"
            ;;
        
        *)
            set -- "${@}" "${argv}"
            ;;

    esac

    shift

done


# Parse short options
declare -i OPTIND=1
declare optspec="htqv"
while getopts "${optspec}" opt; do
    case $opt in
        "h")
            __print_usage
            exit 0
            ;;

        "t")
            declare hardware_type=${!OPTIND:-}
            (( ++OPTIND ))
            ;;

        "q")
            readonly quiet=1
            ;;

        "v")
            set -o verbose
            ;;

        *)
            __print_usage
            exit 1
            ;;

    esac

done


# verify docker is running on this system
[ $( docker ps &>/dev/null; echo ${?} ) -eq 0 ] || __throw_error "Docker is not running on this host" ${?}


# prompt user to select hardware type if --hardware-type wasn't specificed as parameter
if [ -z ${hardware_type:-} ]; then
    hardware_type=$( __get_hardware_type ) || __throw_error "Unable to get hardware type" 1

fi

if [ ! -z ${quiet:-} ]; then
    __edit_compose_file ${hardware_type} || __throw_error "Unable to edit compose file for "${hardware_type} 1
    __mmdvm_hs_compile ${hardware_type} || __throw_error "Unable to compile firmware for "${hardware_type} 1

else
    # don't confirm if --hardware-type was specificed on cli
    if [ -z ${@:-} ]; then
        __confirm_action ${hardware_type}
    
    fi

    __edit_compose_file ${hardware_type} || __throw_error "Unable to edit compose file for "${hardware_type} 1
    __mmdvm_hs_compile ${hardware_type} || __throw_error "Unable to compile firmware for "${hardware_type} 1
    __done_prompt "Successfully compiled ${hardware_type} firmware\n\n        ./$( ls -1 ${hardware_type}/*.bin )"

fi


# Cleaning up
__cleanup || __throw_error "Unable to clean up" 1
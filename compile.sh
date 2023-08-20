#!/usr/bin/env bash

#   Copyright (C) 2023 by Matt Fiscus KK7MNZ

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#   This tool was written to automatically compile G4KLX's fork of
#   MMDVM_HS to easily prepare a pi-star hotspot for M17

# strict mode
set -Eeuo pipefail
IFS=$'\n\t'

# debug mode
#set -o verbose

# define global variables

# set TERM to xterm if not already set
[[ ${TERM} =~ ^xterm.* ]] || export TERM="xterm"

# define dependencies array
readonly -a dependencies=(
    'whiptail'
    'docker'
    'logger'

)

# script name
readonly script_name=${0##*/}

# tool name
readonly tool_name="KK7MNZ - Containerized ARM MMDVM_HS Compiler"

# get logname
readonly logname=$( whoami )

# hardware types
readonly -a types=(
    'D2RG_MMDVM_HS'
    'generic_gpio'
    'MMDVM_HS_Dual_Hat'
    'NanoDV_NPI'
    'SkyBridge_RPi'
    'generic_duplex_gpio'
    'MMDVM_HS_Hat-12mhz'
    'ZUMspot_dualband'
    'ZUMspot_RPi'
    'MMDVM_HS_Dual_Hat-12mhz'
    'MMDVM_HS_Hat'
    'Nano_hotSPOT'
    'ZUMspot_duplex'

)


# hardware descriptions
readonly -a descriptions=(
    'D2RG MMDVM_HS RPi (BG3MDO, VE2GZI, CA6JAU)'
    'Libre Kit board or any homebrew hotspot with modified RF7021SE and Blue Pill STM32F103'
    'MMDVM_HS_Dual_Hat revisions 1.0 (DB9MAT & DF2ET & DO7EN)'
    'NanoDV NPi revisions 1.1 (BG4TGO & BG5HHP)'
    'BridgeCom SkyBridge HotSpot'
    'Libre Kit board or any homebrew hotspot with modified RF7021SE and Blue Pill STM32F103'
    'MMDVM_HS_Hat revisions 1.1, 1.2 and 1.4 (DB9MAT & DF2ET) 12mHz'
    'ZUMspot RPi'
    'ZUMspot RPi'
    'MMDVM_HS_Dual_Hat revisions 1.0 (DB9MAT & DF2ET & DO7EN)'
    'MMDVM_HS_Hat revisions 1.1, 1.2 and 1.4 (DB9MAT & DF2ET) 14mHz'
    'Nano hotSPOT (BI7JTA)'
    'ZUMspot RPi'

)


# Put things back to the way they were before we found them
function __cleanup() {
    # remove temporary dynamically generated docker compose file
    rm -f ./${hardware_type}-docker-compose.yml

    # reset terminal colors
    tput sgr0

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
    echo -e "\t${script_name} --quiet --hardware-type MMDVM_HS_Hat"
    echo -e "\t${script_name} --help"
    echo -e "\nHardware types supported:"
    echo -e "\tD2RG_MMDVM_HS generic_gpio MMDVM_HS_Dual_Hat NanoDV_NPI"
    echo -e "\tSkyBridge_RPi generic_duplex_gpio MMDVM_HS_Hat-12mhz"
    echo -e "\tZUMspot_dualband ZUMspot_RPi MMDVM_HS_Dual_Hat-12mhz"
    echo -e "\tMMDVM_HS_Hat Nano_hotSPOT ZUMspot_duplex"
    
    return

}


function __get_hardware_type() {
    local -a choice
    local choice_count=0
    local options i j

    options="
        whiptail
            --backtitle \"${tool_name}\" 
            --menu \"Select hardware type to compile for:\" 0 0 0" 

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
__generate_compose_file() {
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
            docker compose --quiet --file ./${hardware_type}-docker-compose.yml build --pull --no-cache &>/dev/null
            docker compose --quiet --file ./${hardware_type}-docker-compose.yml up --remove-orphans &>/dev/null
            docker compose --quiet --file ./${hardware_type}-docker-compose.yml down &>/dev/null
        
        else
            docker compose --file ./${hardware_type}-docker-compose.yml build --pull --no-cache 2>&1 | __please_wait "Building Docker container and compiling ${hardware_type} firmware"
            docker compose --file ./${hardware_type}-docker-compose.yml up --remove-orphans 2>&1 | __please_wait "Starting Docker container and extracting binary files"
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
            whiptail
                --backtitle \"${tool_name}\" 
                --inputbox \"Are you sure you want to compile firmware for:\n\n${hardware_type}\n\nType CONFIRM: \" 0 0 "
        
        
        # launch whiptail and split output into an array
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

        tput bold
        echo -e "\n"${wait_message}"\n"
        
        while read -r stream; do
            echo -e "  ==> "${stream} | grep --color=always "==>"

        done

        sleep 3
        
    fi

}


# function to display wait message
# $1 = message
function __done_prompt() {
    # validate argument
    if [ $# -eq 1 ]; then
        local done_message=${1}

        tput bold
        tput setaf 2

        echo -e "\n\n\n"${done_message}"\n\n"

    fi

}


# check for dependencies
# ${1} = dependency
function __check_dependency() {
    if [ ${#} -eq 1 ]; then
        local dependency=${1}
        local exit_code=${null:-}

        type ${dependency} &>/dev/null; exit_code=${?}
        
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

# validate dependencies
declare -i dependency=0

while [ "${dependency}" -lt "${#dependencies[@]}" ]; do
    __check_dependency ${dependencies[${dependency}]} || __throw_error "${dependencies[${dependency}]} required" ${?}

    (( ++dependency ))

done

unset dependency


# make sure we're using least bash 4 for proper support of associative arrays
[ $( echo ${BASH_VERSION} | grep -o '^[0-9]' ) -ge 4 ] || __throw_error "Please upgrade to at least bash version 4" ${?}

# Interpret command-line arguments

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
    hardware_type=$( __get_hardware_type )
    # If we still don't have a harware type, then user canceled
    [ -z ${hardware_type:-} ] && __cleanup && exit 0

fi

if [ ! -z ${quiet:-} ]; then
    __generate_compose_file ${hardware_type} || __throw_error "Unable to generate compose file for ${hardware_type}" 1
    __mmdvm_hs_compile ${hardware_type} || __throw_error "Unable to compile firmware for ${hardware_type}" 1

else
    # don't confirm if --hardware-type was specificed on cli
    if [[ -z ${@:-} ]]; then
        __confirm_action ${hardware_type} || __throw_error "Unable to confirm hardware type selection" 1
    
    fi

    __generate_compose_file ${hardware_type} || __throw_error "Unable to generate compose file for ${hardware_type}" 1
    __mmdvm_hs_compile ${hardware_type} || __throw_error "Unable to compile firmware for ${hardware_type}" 1
    __done_prompt "Successfully compiled ${hardware_type} firmware\n\n\t${hardware_type}.bin"

fi


# Cleaning up
__cleanup || __throw_error "Unable to clean up" 1
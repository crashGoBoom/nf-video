#!/bin/bash

#==========================================================================
#
#         File: nf-video.sh
#
#        Usage: ./nf-video.sh -t $HASHTYPE -c $CHECKSUM -d $FILETODOWNLOAD
#
#  Description: Runs a video job.
#
# Requirements: -t -c -d
#       Author: Christopher Mundus <crashGoBoom>
#      Project: nf-video
#      Created: 20190116
#==========================================================================


#==========================================================================
# Error checking
#==========================================================================
set -o errexit   # Exit when a command fails

#==========================================================================
# Constants
#==========================================================================
WARN="\033[31m"
INFO="\033[32m"
NOCOLOR="\033[0m"

#==========================================================================
# Functions
#==========================================================================

#==== FUNCTION ============================================================
#         NAME: info
#  DESCRIPTION: Output some info.
#         ARGS: $1 = Type of info to display, $2 = Text to display
#      CREATED: 20190116
#==========================================================================

function log() {
  local type="$1" 
  local text="$2" 
  echo -e "${type}${text}${NOCOLOR}"
}

#==== FUNCTION ============================================================
#         NAME: usage
#  DESCRIPTION: Displays usage
#       AUTHOR: Christopher Mundus <chris@kindlyops.com>
#      CREATED: 20190115
#==========================================================================
function usage() {
  log $INFO "Usage:\n./nf-video.sh [OPTIONS]" 1>&2
  exit 1
}

while getopts 'h?:w:i:' opt; do
  case "${opt}" in
    h|\?)
      log $INFO "Help:\n-w Add a watermark image (PNG,JPG). "
      usage
    ;;
    w)
      WATERMARK=${OPTARG}
      log $INFO "Adding a watermark with ${WATERMARK}"
    ;;
    i)
      VIDEO_INPUT=${OPTARG}
      log $INFO "Processing: ${WATERMARK}"
    ;;
    *)
      usage
    ;;
    : ) 
      usage
    ;;
  esac
done
shift $((OPTIND-1))

if [[ ${VIDEO_INPUT} = "" ]]; then
  log $WARN "Please provide a video to process."
  usage
fi

#==== FUNCTION ============================================================
#         NAME: install_nextflow
#  DESCRIPTION: Install nextflow if its not already.
#      CREATED: 20190116
#==========================================================================

function install_nextflow() {
  if type ./nextflow &>/dev/null; then
    log $INFO "Nextflow found..."
    return 0
  else
    log $INFO "Installing from nextflow.io..."
    curl -s https://get.nextflow.io | bash >/dev/null
  fi
  return 0
}

#==== FUNCTION ============================================================
#         NAME: run_nextflow
#  DESCRIPTION: Run the nextflow command
#      CREATED: 20190116
#==========================================================================

function run_nextflow() {
  if ./nextflow run video.nf --inputs=$VIDEO_INPUT; then
    log $INFO "Successfully processed ${VIDEO_INPUT} as completed.mp4!"
    log $INFO "Cleaning up..."
    ./nextflow clean -f &>/dev/null
  fi

  return 0
}

#==== FUNCTION ============================================================
#         NAME: main
#  DESCRIPTION: Triggers the whole process.
#      CREATED: 20190116
#==========================================================================

function main() {
  install_nextflow
  run_nextflow
  exit 0
}

main "${@}"
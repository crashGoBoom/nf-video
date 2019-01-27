#!/bin/bash

#==========================================================================
#
#         File: nf-video.sh
#
#        Usage: ./nf-video.sh -i $FILETOENCODE
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
INSTALL_DIR="/usr/local/bin"
BACKGROUND_COLOR='WhiteSmoke'
FONT=''
FONT_COLOR='DarkGray'
DUR=5
TITLE_TEXT=''
SRT=''
SRT_LANG='eng'
CRF=23
X=10
Y=10

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
  cat <<help_message
--- script subcommand -------------------------------------------------------------
Commands related to this script
USAGE:
  ./nf-video.sh [FLAGS] [SUBCOMMAND]
FLAGS:
  --bgcolor Background Color of bumper video
  -c  CRF Number for ffmpeg
  -d  Set the duration of the bumper video
  -f  Font for bumper title
  --fontcolor Font Color of bumper video
  -h  Prints help information
  -i  Video to Process (Required.)
  -l  Language of the subtitle track in ISO 639. 3 letter language code. (eng, fra, etc..)
  -s  Adds a subtitle file.
  -t  Adds text to the bumper video.
  -w  Adds a watermark (Defaults to upper left.)
  -x  X location for the watermark
  -y  Y location for the watermark
SUBCOMMANDS:
  all                  Do everything (blah, blah2) [default]
help_message

  return 1
}

function get_opts() {
  #  Parse options to the main command.
  while getopts ':-:c:d:f:h?:i:l:s:t:w:x:y:' opt; do
    case "${opt}" in
      -)
          case "${OPTARG}" in
            bgcolor)
              BACKGROUND_COLOR="${!OPTIND}"
              OPTIND=$(( OPTIND + 1 ))
            ;;
            fontcolor)
              FONT_COLOR="${!OPTIND}"
              OPTIND=$(( OPTIND + 1 ))
            ;;
          esac
      ;;
      c)
        CRF="${OPTARG}"
      ;;
      d)
        DUR="${OPTARG}"
      ;;
      f)
        FONT=${OPTARG}
        log $INFO "Adding Font: ${FONT}"
      ;;
      h|\?)
        log $INFO "Help:\n-w Add a watermark image (PNG,JPG). "
        usage
      ;;
      i)
        VIDEO_INPUT=${OPTARG}
        log $INFO "Processing: ${VIDEO_INPUT}"
      ;;
      l)
        SRT_LANG=${OPTARG}
        log $INFO "Setting srt language to: ${SRT_LANG} "
      ;;
      s)
        SRT=${OPTARG}
        log $INFO "Adding Subtitles from: ${SRT}"
      ;;
      t)
        TITLE_TEXT=${OPTARG}
        log $INFO "Adding title text: ${TITLE_TEXT}"
      ;;
      w)
        WATERMARK="${OPTARG}"
        log $INFO "Adding a watermark with ${WATERMARK}"
      ;;
      x)
        X="${OPTARG}"
      ;;
      y)
        Y="${OPTARG}"
      ;;
      *)
        usage
      ;;
    esac
  done
  shift $((OPTIND-1))

  if [[ ${VIDEO_INPUT} = "" ]]; then
    log "${WARN}" "Please provide a video to process."
    usage
  fi

  #  Remove the main command from the argument list.
  local -r _subcommand="${1:-}"
  if [[ -z ${_subcommand} ]]; then
    install_nextflow
    run_nextflow
    return 0
  fi

  shift
  case "${_subcommand}" in
    run)
      run_nextflow
      ;;
    install)
      install_nextflow
      ;;
    *)
      usage
      ;;
  esac

  return 0
}

#==== FUNCTION ============================================================
#         NAME: install_nextflow
#  DESCRIPTION: Install nextflow if its not already.
#      CREATED: 20190116
#==========================================================================

function install_nextflow() {
  if type nextflow &>/dev/null; then
    log "${INFO}" "Nextflow found..."
    return 0
  elif type ./nextflow &>/dev/null; then
    log "${INFO}" "Nextflow found..."
    return 0
  else
    log "${WARN}" "Nextflow not found!"
    prompt_user "Would you like to install it?"
    log "${INFO}" "Installing from nextflow.io..."
    curl -s https://get.nextflow.io | bash >/dev/null
    mv "${PWD}/nextflow" "${INSTALL_DIR}/nextflow"
  fi
  return 0
}

#==== FUNCTION ============================================================
#         NAME: prompt_user
#  DESCRIPTION: Prompts the user for something.
#      CREATED: 20190116
#==========================================================================

function prompt_user() {
    log "${WARN}" "${1}"
    read -p "(Y)es or (N)o?" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        [[ "$0" = "${BASH_SOURCE[*]}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi
}

#==== FUNCTION ============================================================
#         NAME: run_nextflow
#  DESCRIPTION: Run the nextflow command
#      CREATED: 20190116
#==========================================================================

function run_nextflow() {
  if nextflow run video.nf \
      --inputs="${VIDEO_INPUT}" \
      --srt="${SRT}" \
      --language="${SRT_LANG}" \
      --watermark="${WATERMARK}" \
      --image="${IMAGE}" \
      --crf="${CRF}" \
      --font="${FONT}" \
      --text="${TITLE_TEXT}" \
      --duration="${DUR}" \
      --background_color="${BACKGROUND_COLOR}" \
      --font_color="${FONT_COLOR}" \
      --y="${Y}" --x="${X}"; then
    log "${INFO}" "Successfully processed ${VIDEO_INPUT} as completed.mp4!"
    log "${INFO}" "Cleaning up..."
    nextflow clean -f &>/dev/null
  fi

  return 0
}

#==== FUNCTION ============================================================
#         NAME: main
#  DESCRIPTION: Triggers the whole process.
#      CREATED: 20190116
#==========================================================================

function main() {
  get_opts "${@}"

  return 0
}

main "${@}"
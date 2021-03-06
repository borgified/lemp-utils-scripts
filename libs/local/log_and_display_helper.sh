#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
################################################################################

function _spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from spinner_stop)

    #local on_success="DONE"
    #local on_fail="FAIL"

    case $1 in

        start)

          # calculate the column where spinner and status msg will be displayed
          TEXT=$2
          INDENT=6
          LINESIZE=$(export LC_ALL= ; echo "${TEXT}" | wc -m | tr -d ' ')
          if [[ ${INDENT} -gt 0 ]]; then SPACES=$((62 - INDENT - LINESIZE)); fi
          if [[ ${SPACES} -lt 0 ]]; then SPACES=0; fi

          echo -e -n "\033[${INDENT}C${TEXT}${NORMAL}\033[${SPACES}C" >&2

          # start spinner
          i=1
          sp='\|/-'
          delay=${SPINNER_DELAY:-0.15}

          while :
          do
              printf "\b${sp:i++%${#sp}:1}"
              sleep "$delay"
          done

        ;;

        stop)

          if [[ -z ${3} ]]; then
              # spinner is not running
              exit 1
          fi

          clear_line

          kill $3 > /dev/null 2>&1

          # inform the user uppon success or failure
          #echo -en "\b["
          #if [[ $2 -eq 0 ]]; then
          #    echo -en "${GREEN}${on_success}${NORMAL}"
          #else
          #    echo -en "${RED}${on_fail}${NORMAL}"
          #fi
          #echo -e "]"

        ;;

        *)
          #invalid argument
          exit 1
        ;;

    esac

}

function spinner_start {
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

function spinner_stop {
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

function log_event() {

  # Parameters
  # $1 = {log_type} (success, info, warning, error, critical)
  # $2 = {message}
  # $3 = {console_display} optional (true or false, default is false)

  local log_type=$1
  local message=$2
  local console_display=$3

  case ${log_type} in

    success)
      echo " > SUCCESS: ${message}" >> "${LOG}"
      if [[ "${console_display}" = "true" ]]; then
        echo -e "${B_GREEN} > ${message}${ENDCOLOR}" >&2
      fi
    ;;

    info)
      echo " > INFO: ${message}" >> "${LOG}"
      if [[ "${console_display}" = "true" ]]; then
        echo -e "${B_CYAN} > ${message}${ENDCOLOR}" >&2
      fi
    ;;

    warning)
      echo " > WARNING: ${message}" >> "${LOG}"
      if [[ "${console_display}" = "true" ]]; then
        echo -e "${YELLOW}${ITALIC} > ${message}${ENDCOLOR}" >&2
      fi
    ;;

    error)
      echo " > ERROR: ${message}" >> "${LOG}"
      if [[ "${console_display}" = "true" ]]; then
        echo -e "${RED} > ${message}${ENDCOLOR}" >&2
      fi
    ;;

    critical)
      echo " > CRITICAL: ${message}" >> "${LOG}"
      if [[ "${console_display}" = "true" ]]; then
        echo -e "${B_RED} > ${message}${ENDCOLOR}" >&2
      fi
    ;;

    debug)
      if [[ "${DEBUG}" -eq 1 ]]; then

        echo " > DEBUG: ${message}" >> "${LOG}"
        if [[ "${console_display}" = "true" ]]; then
          echo -e "${B_MAGENTA} > ${message}${ENDCOLOR}" >&2
        fi

      fi
    ;;

    *)
      echo " > ${message}" >> "${LOG}"
      if [[ "${console_display}" = "true" ]]; then
        echo -e "${CYAN}${B_DEFAULT} > ${message}${ENDCOLOR}" >&2
      fi
    ;;

  esac

}

function log_break() {

  # Parameters
  # $1 = {console_display} optional (true or false, emtpy equals false)

  local console_display=$1

  local log_break
  
  if [[ "${console_display}" == "true" ]]; then

    log_break="        -------------------------------------------------"
    echo -e "${MAGENTA}${B_DEFAULT}${log_break}${ENDCOLOR}" >&2

  fi

  log_break=" > -------------------------------------------------"
  echo "${log_break}" >> "${LOG}"

}

function log_section() {

  # Parameters
  # $1 = {message}

  local message=$1

  if [[ ${QUIET} -eq 0 ]]; then
    # Console Display
    echo "" >&2
    echo -e "[+] Performing Action: ${YELLOW}${B_DEFAULT}${message}${ENDCOLOR}" >&2
    echo "----------------------------------------------" >&2
    # Log file
    echo " > -------------------------------------------------" >> "${LOG}"
    echo " > [+] Performing Action: ${message}" >> "${LOG}"
    echo " > -------------------------------------------------" >> "${LOG}"
  fi

}

function log_subsection() {

  # Parameters
  # $1 = {message}

  local message=$1

    if [[ "${QUIET}" -eq 0 ]]; then
      # Console Display
      echo "" >&2
      echo -e "    [·] ${CYAN}${B_DEFAULT}${message}${ENDCOLOR}" >&2
      echo "    ------------------------------------------" >&2
      # Log file
      echo " > -------------------------------------------------" >> "${LOG}"
      echo " > [·] ${message}" >> "${LOG}"
      echo " > -------------------------------------------------" >> "${LOG}"
    fi

}

function clear_screen() {

  echo -en "\ec" >&2

}

function clear_last_line() {

  printf "\033[1A" >&2
  echo -e "${F_DEFAULT}                                                                                                         ${ENDCOLOR}" >&2                    
  echo -e "${F_DEFAULT}                                                                                                         ${ENDCOLOR}" >&2
  printf "\033[1A" >&2
  printf "\033[1A" >&2

}

function clear_line() {

  printf "\033[G" >&2
  printf "                                                                                                         " >&2                    
  printf "\033[G" >&2

}

function display() {

  INDENT=0; TEXT=""; RESULT=""; TCOLOR=""; TSTYLE=""; COLOR=""; SPACES=0; SHOWDEBUG=0; CRONJOB=0;
  
  while [ $# -ge 1 ]; do
      case $1 in
          --color)
              shift
                  case $1 in
                    GREEN)    COLOR=${GREEN}   ;;
                    RED)      COLOR=${RED}     ;;
                    WHITE)    COLOR=${WHITE}   ;;
                    YELLOW)   COLOR=${YELLOW}  ;;
                    MAGENTA)  COLOR=${MAGENTA}  ;
                  esac
          ;;
          --debug)
              SHOWDEBUG=1
          ;;
          --indent)
              shift
              INDENT=$1
          ;;
          --result)
              shift
              RESULT=$1
          ;;
          --tcolor)
            shift
                case $1 in
                  GREEN)    TCOLOR=${GREEN}   ;;
                  RED)      TCOLOR=${RED}     ;;
                  WHITE)    TCOLOR=${WHITE}   ;;
                  YELLOW)   TCOLOR=${YELLOW}  ;;
                  MAGENTA)  TCOLOR=${MAGENTA}  ;
                esac
          ;;
          --tstyle)
            shift
                case $1 in
                  NORMAL)       TSTYLE=${NORMAL}   ;;
                  BOLD)         TSTYLE=${BOLD}     ;;
                  ITALIC)       TSTYLE=${ITALIC}   ;;
                  UNDERLINED)   TSTYLE=${UNDERLINED}  ;;
                  INVERTED)     TSTYLE=${INVERTED}  ;
                esac
          ;;
          --text)
              shift
              TEXT=$1
          ;;
          *)
              echo "INVALID OPTION (Display): $1" >&2
              #ExitFatal
          ;;
      esac
      # Go to next parameter
      shift
  done

  if [[ -z "${RESULT}" ]]; then
      RESULTPART=""
  else
      if [[ ${CRONJOB} -eq 0 ]]; then
          RESULTPART=" [ ${COLOR}${B_DEFAULT}${RESULT}${NORMAL} ]"
      else
          RESULTPART=" [ ${RESULT} ]"
      fi
  fi

  if [[ -n "${TEXT}" ]]; then
      SHOW=0

      if [[ ${SHOW} -eq 0 ]]; then

          # Display:
          # - for full shells, count with -m instead of -c, to support language locale (older busybox does not have -m)
          # - wc needs LANG to deal with multi-bytes characters but LANG has been unset in include/consts
          TEXT_C=$(string_remove_color_chars "${TEXT}")
          LINESIZE=$(export LC_ALL= ; echo "${TEXT_C}" | wc -m | tr -d ' ')

          if [[ "${SHOWDEBUG}" -eq 1 ]]; then DEBUGTEXT=" [${PURPLE}DEBUG${NORMAL}]"; else DEBUGTEXT=""; fi
          if [[ "${INDENT}" -gt 0 ]]; then SPACES=$((62 - INDENT - LINESIZE)); fi
          if [[ "${SPACES}" -lt 0 ]]; then SPACES=0; fi

          if [[ "${CRONJOB}" -eq 0 ]]; then
            # Check if we already have already discovered a proper echo command tool. It not, set it default to 'echo'.
            #if [ "${ECHOCMD}" = "" ]; then ECHOCMD="echo"; fi
            echo -e "\033[${INDENT}C${TCOLOR}${TSTYLE}${TEXT}${NORMAL}\033[${SPACES}C${RESULTPART}${DEBUGTEXT}" >&2

          else
            echo "${TEXT}${RESULTPART}" >&2

          fi

      fi

  fi

}
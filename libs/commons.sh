#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
#############################################################################

# Libs apps directory path
libs_apps_path="${SFOLDER}/libs/apps"

# Source all apps libs
libs_apps="$(find "${libs_apps_path}" -maxdepth 1 -name '*.sh' -type f -print)"
for f in ${libs_apps}; do source "${f}"; done

# Libs local directory path
libs_local_path="${SFOLDER}/libs/local"

# Source all local libs
libs_local="$(find "${libs_local_path}" -maxdepth 1 -name '*.sh' -type f -print)"
for f in ${libs_local}; do source "${f}"; done

# shellcheck source=${SFOLDER}/utils/installers_and_configurators.sh
source "${SFOLDER}/utils/installers_and_configurators.sh"
# shellcheck source=${SFOLDER}/utils/it_utils.sh
source "${SFOLDER}/utils/it_utils.sh"

#
#############################################################################
#
# * Private functions
#
#############################################################################
#

function _setup_globals_and_options() {

  # Script
  declare -g SCRIPT_N="LEMP UTILS SCRIPT"
  declare -g SCRIPT_V="3.0.17"

  # Hostname
  declare -g VPSNAME="$HOSTNAME"

  # Script modes
  declare -g DEBUG=1                             # Debugging mode (to screen)
  declare -g QUIET=0                             # Show normal messages and warnings as well
  declare -g SKIPTESTS=1                         # Skip tests

  # Default directories
  declare -g WSERVER="/etc/nginx"                # NGINX config files location
  declare -g MySQL_CF="/etc/mysql"               # MySQL config files location
  declare -g PHP_CF="/etc/php"                   # PHP config files location
  declare -g LENCRYPT_CF="/etc/letsencrypt"      # Let's Encrypt config files location

  # Folder blacklist
  declare -g SITES_BL=".wp-cli,html,phpmyadmin"

  # Database blacklist
  declare -g DB_BL="information_schema,performance_schema,mysql,sys,phpmyadmin"

  #MAILCOW BACKUP
  declare -g MAILCOW_TMP_BK="${SFOLDER}/tmp/mailcow"

  # PHP
  declare -g PHP_V
  PHP_V="$(php -r "echo PHP_VERSION;" | grep --only-matching --perl-regexp "7.\d+")"
  php_exit=$?
  if [[ ${php_exit} -eq 1 ]];then
    # Packages to watch
    PACKAGES=(linux-firmware dpkg nginx "php${PHP_V}-fpm" mysql-server openssl)
  fi

  # MySQL host and user
  declare -g MHOST="localhost"
  declare -g MUSER="root"

  #MySQL credentials file
  declare -g MYSQL_CONF="/root/.my.cnf"
  declare -g MYSQL
  declare -g MYSQLDUMP

  # Main partition
  declare -g MAIN_VOL
  MAIN_VOL=$(df /boot | grep -Eo '/dev/[^ ]+')

  # Dropbox Folder Backup
  declare -g DROPBOX_FOLDER="/"

  # Time Vars
  declare -g NOW
  NOW=$(date +"%Y-%m-%d")

  declare -g NOWDISPLAY
  NOWDISPLAY=$(date +"%d-%m-%Y")

  declare -g ONEWEEKAGO
  ONEWEEKAGO=$(date --date='7 days ago' +"%Y-%m-%d")

  # Others
  declare -g startdir=""
  declare -g menutitle="Config Selection Menu"

}

function _setup_colors_and_styles() {

  # Refs:
  # https://misc.flogisoft.com/bash/tip_colors_and_formatting

  # Declare read-only global vars
  declare -g NORMAL BOLD ITALIC UNDERLINED INVERTED
  declare -g BLACK RED GREEN YELLOW ORANGE MAGENTA CYAN WHITE ENDCOLOR F_DEFAULT
  declare -g B_BLACK B_RED B_GREEN B_YELLOW B_ORANGE B_MAGENTA B_CYAN B_WHITE B_ENDCOLOR B_DEFAULT

  # RUNNING FROM TERMINAL
  if [[ -t 1 ]]; then

    # Text Styles
    NORMAL="\033[m"
    BOLD='\x1b[1m'
    ITALIC='\x1b[3m'
    UNDERLINED='\x1b[4m'
    INVERTED='\x1b[7m'

    # Foreground/Text Colours
    BLACK='\E[30;40m'
    RED='\E[31;40m'
    GREEN='\E[32;40m'
    YELLOW='\E[33;40m'
    ORANGE='\033[0;33m'
    MAGENTA='\E[35;40m'
    CYAN='\E[36;40m'
    WHITE='\E[37;40m'
    ENDCOLOR='\033[0m'
    F_DEFAULT='\E[39m'

    # Background Colours
    B_BLACK='\E[40m'
    B_RED='\E[41m'
    B_GREEN='\E[42m'
    B_YELLOW='\E[43m'
    B_ORANGE='\043[0m'
    B_MAGENTA='\E[45m'
    B_CYAN='\E[46m'
    B_WHITE='\E[47m'
    B_ENDCOLOR='\e[0m'
    B_DEFAULT='\E[49m'

  else

    # Text Styles
    NORMAL='' BOLD='' ITALIC='' UNDERLINED='' INVERTED=''

    # Foreground/Text Colours
    BLACK='' RED='' GREEN='' YELLOW='' ORANGE='' MAGENTA='' CYAN='' WHITE='' ENDCOLOR='' F_DEFAULT=''

    # Background Colours
    B_BLACK='' B_RED='' B_GREEN='' B_YELLOW='' B_ORANGE='' B_MAGENTA='' B_CYAN='' B_WHITE='' B_ENDCOLOR='' B_DEFAULT=''

  fi

}

function _check_root() {

  local is_root
  
  is_root=$(id -u) # if return 0, the script is runned by the root user

  # Check if user is root
  if [[ ${is_root} != 0 ]]; then
    # $USER is a env var
    log_event "critical" "Script runned by ${USER}, but must be root! Exiting ..." "true"
    exit 1

  else
    log_event "debug" "Script runned by root"
    return 0

  fi

}

function _check_scripts_permissions() {

  ### chmod
  find ./ -name "*.sh" -exec chmod +x {} \;
  log_event "debug" "Executing chmod +x on *.sh"

}

function _check_distro() {

  local distro_old

  # For ext check
  distro_old="false"

  # Running Ubuntu?
  DISTRO=$(lsb_release -d | awk -F"\t" '{print $2}' | awk -F " " '{print $1}')
  if [[ ! ${DISTRO} = "Ubuntu" ]]; then
    log_event "critical" "This script only run on Ubuntu ... Exiting" "true"
    return 1

  else
    MIN_V=$(echo "18.04" | awk -F "." '{print $1$2}')
    DISTRO_V=$(get_ubuntu_version)
    
    log_event "info" "ACTUAL DISTRO: ${DISTRO} ${DISTRO_V}"

    if [[ ! ${DISTRO_V} -ge ${MIN_V} ]]; then
      whiptail --title "UBUNTU VERSION WARNING" --msgbox "Ubuntu version must be 18.04 or 20.04! Use this script only for backup or restore purpose." 8 78
      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then
        distro_old="true"
        log_event "info" "Setting distro_old: ${distro_old}"
        
      else
        return 1

      fi
      
    fi

  fi

}

#
#############################################################################
#
# * Functions
#
#############################################################################
#

function script_init() {

  # Script setup
  _setup_globals_and_options

  # Temp folders
  TMP_DIR="${SFOLDER}/tmp"

  # Creating temporary folders
  if [[ ! -d ${TMP_DIR} ]]; then
    echo " > Folder ${TMP_DIR} doesn't exist. Creating ..."
    mkdir "${TMP_DIR}"
  fi
  if [[ ! -d "${TMP_DIR}/${NOW}" ]]; then
    echo " > Folder ${TMP_DIR}/${NOW} doesn't exist. Creating ..."
    mkdir "${TMP_DIR}/${NOW}"
  fi

  # Log
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  PATH_LOG="${SFOLDER}/log"
  if [[ ! -d "${SFOLDER}/log" ]]; then
    mkdir "${SFOLDER}/log"
  fi

  LOG_NAME="log_lemp_utils_${TIMESTAMP}.log"
  LOG="${PATH_LOG}/${LOG_NAME}"

  find "${PATH_LOG}" -name "*.log" -type f -mtime +7 -print -delete >>"${LOG}"

  # Load colors and styles
  _setup_colors_and_styles

  # Clear Screen
  clear_screen

  # Log Start
  log_event "" "WELCOME TO ${SCRIPT_N} v${SCRIPT_V}" "true"
  log_event "info" "Script Start -- $(date +%Y%m%d_%H%M)"

  ### Welcome #####################################################################

  log_event "" "                                                 " "true"
  log_event "" "██████╗ ██████╗  ██████╗  ██████╗ ██████╗ ███████" "true"
  log_event "" "██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗██╔══██╗██╔══  " "true"
  log_event "" "██████╔╝██████╔╝██║   ██║██║   ██║██████╔╝█████  " "true"
  log_event "" "██╔══██╗██╔══██╗██║   ██║██║   ██║██╔══██╗██╔    " "true"
  log_event "" "██████╔╝██║  ██║╚██████╔╝╚██████╔╝██████╔╝███████" "true"
  log_event "" "╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚══════" "true"
  log_event "" "                                                 " "true"
  log_event "" "-------------------------------------------------" "true"

  # Ref: http://patorjk.com/software/taag/

  ################################################################################

  # Checking distro
  _check_distro

  # Checking if user is root
  _check_root

  # Checking script permissions
  _check_scripts_permissions

  # Status vars
  declare -g STATUS_BACKUP_DBS=""
  declare -g STATUS_BACKUP_FILES=""
  declare -g STATUS_SERVER=""
  declare -g STATUS_CERTS=""
  declare -g OUTDATED_PACKAGES="false"

  declare -g DPU_F
  declare -g DROPBOX_UPLOADER

  declare -g NETWORK_INTERFACE

  # BROOBE Utils config file
  LEMP_UTILS_CONFIG_FILE=~/.broobe-utils-options
  if test -f ${LEMP_UTILS_CONFIG_FILE}; then
    source "${LEMP_UTILS_CONFIG_FILE}"

  else

    menu_first_run
    
  fi

  # Checking required packages to run
  check_packages_required
  packages_output=$?
  if [[ ${packages_output} -eq 1 ]];then
    log_event "warning" "Some script dependencies are not setisfied." "true"
    prompt_return_or_finish
  fi

  # Dropbox-uploader config file
  DPU_CONFIG_FILE=~/.dropbox_uploader
  if [[ ${DROPBOX_ENABLE} == "true" && ! -f ${DPU_CONFIG_FILE} ]]; then
    generate_dropbox_config
  fi
  if [[ ${DROPBOX_ENABLE} == "true" ]]; then
    # shellcheck source=${DPU_CONFIG_FILE}
    source "${DPU_CONFIG_FILE}"
    # Dropbox-uploader directory
    DPU_F="${SFOLDER}/tools/third-party/dropbox-uploader"
    # Dropbox-uploader runner
    DROPBOX_UPLOADER="${DPU_F}/dropbox_uploader.sh"
    #DROPBOX_UPLOADER="${DPU_F}/dropbox_uploader_original.sh"

  fi

  # Cloudflare config file
  CLF_CONFIG_FILE=~/.cloudflare.conf
  if [[ ${CLOUDFLARE_ENABLE} == "true" && -f ${CLF_CONFIG_FILE} ]]; then
    # shellcheck source=${CLF_CONFIG_FILE}
    source "${CLF_CONFIG_FILE}"
  fi

  # Telegram config file
  TEL_CONFIG_FILE=~/.telegram.conf
  if [[ ${TELEGRAM_NOTIF} == "true" && -f ${TEL_CONFIG_FILE} ]]; then
    # shellcheck source=${TEL_CONFIG_FILE}
    source "${TEL_CONFIG_FILE}"
  fi

  # Check configuration
  check_script_configuration

  # METHOD TO GET PUBLIC IP (if server has configured a floating ip, it will return this)
  NETWORK_INTERFACE="$(ip link show | grep '2:' | cut -d ':' -f2)"
  NETWORK_INTERFACE="$(string_remove_spaces "${NETWORK_INTERFACE}")"
  SERVER_IP="$(ifconfig "${NETWORK_INTERFACE}" | grep 'inet ' | awk '{print $2}' | sed 's/addr://')"
  # Fallback
  if [[ ${SERVER_IP} == "" ]]; then
    # Alternative method to get public IP
    SERVER_IP=$(curl -s http://ipv4.icanhazip.com)
  fi

  # EXPORT VARS
  export SCRIPT_V VPSNAME TMP_DIR SFOLDER DPU_F DROPBOX_UPLOADER SITES SITES_BL DB_BL WSERVER MAIN_VOL PACKAGES PHP_CF PHP_V 
  export LENCRYPT_CF MySQL_CF MYSQL MYSQLDUMP MYSQL_ROOT MYSQLDUMP_ROOT TAR FIND DROPBOX_FOLDER MAILCOW_TMP_BK MHOST MUSER MAILA NOW NOWDISPLAY ONEWEEKAGO 
  export SENDEMAIL DISK_U ONE_FILE_BK SERVER_IP SMTP_SERVER SMTP_PORT SMTP_TLS SMTP_U SMTP_P STATUS_BACKUP_DBS STATUS_BACKUP_FILES STATUS_SERVER STATUS_CERTS OUTDATED_PACKAGES 
  export LOG BLACK RED GREEN YELLOW ORANGE MAGENTA CYAN WHITE ENDCOLOR dns_cloudflare_email dns_cloudflare_api_key

}

function customize_ubuntu_login_message() {

  # TODO: screenfetch support?

  # Remove unnecesary messages
  if [[ -d "/etc/update-motd.d/10-help-text " ]]; then
    rm "/etc/update-motd.d/10-help-text "

  fi
  if [[ -d "/etc/update-motd.d/50-motd-news" ]]; then
    rm "/etc/update-motd.d/50-motd-news"

  fi
  if [[ -d "/etc/update-motd.d/00-header" ]]; then
    rm "/etc/update-motd.d/00-header"

  fi

  # Copy new login message
  cp "${SFOLDER}/config/motd/00-header" "/etc/update-motd.d"

  # Force update
  run-parts "/etc/update-motd.d"

}

function install_script_aliases () {

  if [[ ! -f ~/.bash_aliases ]]; then
    cp "${SFOLDER}/utils/aliases.sh" ~/.bash_aliases
    display --indent 2 --text "- Installing script aliases" --result "DONE" --color GREEN
    display --indent 4 --text "Please now run: source ~/.bash_aliases" --tcolor CYAN

  else

    display --indent 2 --text "- Installing script aliases" --result "FAIL" --color RED
    display --indent 4 --text "File .bash_aliases already exists"

  fi

}

function change_project_status () {

  #$1 = ${project_status}

  local project_status=$1

  local to_change

  startdir="${SITES}"
  directory_browser "${menutitle}" "${startdir}"

  to_change=${filename%/}

  nginx_server_change_status "${to_change}" "${project_status}"

}

#
#############################################################################
#
# * Validators
#
#############################################################################
#

function validator_email_format() {

  local email=$1

  if [[ ! "${email}" =~ ^[A-Za-z0-9._%+-]+@[[:alnum:].-]+\.[A-Za-z]{2,63}$ ]] ; then

    log_event "ERROR" "Invalid email format :: ${email}"
    return 1

  fi

}

function validator_cron_format() {

  local limit
  local check_format
  local crn_values

  limit=59
  check_format=''

  if [[ "$2" = 'hour' ]]; then
      limit=23
  fi
  
  if [[ "$2" = 'day' ]]; then
      limit=31
  fi

  if [[ "$2" = 'month' ]]; then
      limit=12
  fi

  if [[ "$2" = 'wday' ]]; then
      limit=7
  fi

  if [[ "$1" = '*' ]]; then
      check_format='ok'
  fi
  
  if [[ "$1" =~ ^[\*]+[/]+[0-9] ]]; then
      if [[ "$(echo $1 |cut -f 2 -d /)" -lt $limit ]]; then
          check_format='ok'
      fi
  fi
  
  if [[ "$1" =~ ^[0-9][-|,|0-9]{0,70}[\/][0-9]$ ]]; then
      check_format='ok'
      crn_values=${1//,/ }
      crn_values=${crn_values//-/ }
      crn_values=${crn_values//\// }
      for crn_vl in $crn_values; do
          if [[ "$crn_vl" -gt $limit ]]; then
              check_format='invalid'
          fi
      done
  fi
  
  crn_values=$(echo $1 |tr "," " " | tr "-" " ")
  
  for crn_vl in $crn_values
      do
          if [[ "$crn_vl" =~ ^[0-9]+$ ]] && [ "$crn_vl" -le $limit ]; then
                check_format='ok'
            fi
      done
  
  if [[ ${check_format} != 'ok' ]]; then
      check_result $E_INVALID "invalid $2 format :: $1"
  fi

}

function cleanup() {

  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here

}

function die() {

  local msg=$1
  local code=${2-1} # default exit status 1

  log_event "info" "${msg}"

  exit "${code}"

}

#
#############################################################################
#
# * Helpers
#
#############################################################################
#

function whiptail_message() {

  # $1 = {whip_title}
  # $2 = {whip_message}

  local whip_title=$1
  local whip_message=$2

  whiptail --title "${whip_title}" --msgbox "${whip_message}" 15 60 3>&1 1>&2 2>&3
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then
    return 0

  else
    return 1

  fi

}

function whiptail_message_with_skip_option() {

  # $1 = {whip_title}
  # $2 = {whip_message}

  local whip_title=$1
  local whip_message=$2

  whiptail --title "${whip_title}" --yesno "${whip_message}" 15 60 3>&1 1>&2 2>&3
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then
    return 0

  else
    return 1

  fi

}

function get_ubuntu_version() {

  lsb_release -d | awk -F"\t" '{print $2}' | awk -F " " '{print $2}' | awk -F "." '{print $1$2}'

}

# TODO: refactor this
declare -a checklist_array

function array_to_checklist() {

  local array=$1

  local i

  i=0
  for option in ${array}; do

    checklist_array[$i]=$option
    i=$((i + 1))
    checklist_array[$i]=" "
    i=$((i + 1))
    checklist_array[$i]=off
    i=$((i + 1))

  done

  # checklist_array returned
  # export ${checklist_array}

}

function file_browser() {

  # $1= ${menutitle}
  # $2= ${startdir}

  local menutitle=$1
  local startdir=$2

  local dir_list

  if [ -z "${startdir}" ]; then
    dir_list=$(ls -lhp | awk -F ' ' ' { print $9 " " $5 } ')
  else
    cd "${startdir}"
    dir_list=$(ls -lhp | awk -F ' ' ' { print $9 " " $5 } ')
  fi
  curdir=$(pwd)
  if [ "$curdir" == "/" ]; then # Check if you are at root folder
    selection=$(whiptail --title "${menutitle}" \
      --menu "Select a Folder or Tab Key\n$curdir" 0 0 0 \
      --cancel-button Cancel \
      --ok-button Select $dir_list 3>&1 1>&2 2>&3)
  else # Not Root Dir so show ../ BACK Selection in Menu
    selection=$(whiptail --title "${menutitle}" \
      --menu "Select a Folder or Tab Key\n$curdir" 0 0 0 \
      --cancel-button Cancel \
      --ok-button Select ../ BACK $dir_list 3>&1 1>&2 2>&3)
  fi
  RET=$?
  if [ $RET -eq 1 ]; then # Check if User Selected Cancel
    return 1
  elif [ $RET -eq 0 ]; then
    if [[ -f "$selection" ]]; then # Check if File Selected
      if (whiptail --title "Confirm Selection" --yesno "Selection : $selection\n" 0 0 \
        --yes-button "Confirm" \
        --no-button "Retry"); then

        # Return 1
        filename="$selection"
        # Return 2
        filepath="$curdir" # Return full filepath and filename as selection variables
      
      fi
    
    fi
  
  fi

}

function directory_browser() {

  # $1= ${menutitle}
  # $2= ${startdir}

  local menutitle=$1
  local startdir=$2

  local dir_list

  if [ -z "${startdir}" ]; then
    dir_list=$(ls -lhp | awk -F ' ' ' { print $9 " " $5 } ')
  else
    cd "${startdir}"
    dir_list=$(ls -lhp | awk -F ' ' ' { print $9 " " $5 } ')
  fi
  curdir=$(pwd)
  if [ "$curdir" == "/" ]; then # Check if you are at root folder
    selection=$(whiptail --title "${menutitle}" \
      --menu "Select a Folder or Tab Key\n$curdir" 0 0 0 \
      --cancel-button Cancel \
      --ok-button Select $dir_list 3>&1 1>&2 2>&3)
  else # Not Root Dir so show ../ BACK Selection in Menu
    selection=$(whiptail --title "${menutitle}" \
      --menu "Select a Folder or Tab Key\n$curdir" 0 0 0 \
      --cancel-button Cancel \
      --ok-button Select ../ BACK $dir_list 3>&1 1>&2 2>&3)
  fi
  RET=$?
  if [ $RET -eq 1 ]; then # Check if User Selected Cancel
    return 1
  elif [ $RET -eq 0 ]; then
    if [[ -d "${selection}" ]]; then # Check if Directory Selected
      whiptail --title "Confirm Selection" --yesno "${selection}" --yes-button "Confirm" --no-button "Retry" 10 60 3>&1 1>&2 2>&3
      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then
          # Return 1
        filename="${selection}"
        # Return 2
        filepath="${curdir}" # Return full filepath and filename as selection variables

      else
        return 1

      fi

    fi

  fi

}

function get_all_directories() {

  # $1 = ${SITES}

  local main_dir=$1

  first_level_dir=$(find ${main_dir} -maxdepth 1 -type d)

  # Return
  echo "${first_level_dir}"

}

function copy_project_files() {

  # $1 = ${SOURCE_PATH}
  # $2 = ${DESTINATION_PATH}
  # $3 = ${EXCLUDED_PATH} - Neet to be a relative path

  local source_path=$1
  local destination_path=$2
  local excluded_path=$3

  if [ "${excluded_path}" != "" ];then
    rsync -ax --exclude "${excluded_path}" "${source_path}" "${destination_path}"

  else
    rsync -ax "${source_path}" "${destination_path}"

  fi

}

function get_project_type() {

  # $1 = ${dir_path}

  local dir_path=$1

  local project_type
  local is_wp

  if [[ ${dir_path} != "" ]];then

    is_wp=$(search_wp_config "${dir_path}")

    if [[ ${is_wp} != "" ]];then

      project_type="wordpress"

      else

      # TODO: implements laravel, yii, and others php framework support
      project_type="project_type_unknown"

    fi

  fi

  # Return
  echo "${project_type}"

}

function calculate_disk_usage() {

  # $1 = ${disk_volume}

  local disk_volume=$1

  local disk_u

  # Need to use grep with -w to exact match of the main volume
  disk_u="$(df -h | grep -w "${disk_volume}" | awk '{print $5}')"

  log_event "info" "Disk usage of ${disk_volume}: ${disk_u}"

  # Return
  echo "${disk_u}"

}

function string_remove_spaces() {

  # $1 = ${string}

  local string=$1

  # Return
  echo "${string//[[:blank:]]/}"

}

function string_remove_special_chars() {

  # From: https://stackoverflow.com/questions/23816264/remove-all-special-characters-and-case-from-string-in-bash
  #
  # The first tr deletes special characters. d means delete, c means complement (invert the character set). 
  # So, -dc means delete all characters except those specified. 
  # The \n and \r are included to preserve linux or windows style newlines, which I assume you want.
  # The second one translates uppercase characters to lowercase.
  # The third get rid of characters like \r \n or ^C.

  # Return
  #cat $1 | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]' | tr -d '[:cntrl:]' # for files

  # $1 = ${string}

  local string=$1

  # Return
  echo "${string}" | tr -dc ".[:alnum:]-\n\r"     # Let '.' and '-' chars

}

function string_remove_color_chars() {

  # $1 = ${string}

  local string=$1

  # Text Styles
  declare -a text_styles=("${NORMAL}" "${BOLD}" "${ITALIC}" "${UNDERLINED}" "${INVERTED}")

  # Foreground/Text Colours
  declare -a text_colors=("${BLACK}" "${RED}" "${GREEN}" "${YELLOW}" "${ORANGE}" "${MAGENTA}" "${CYAN}" "${WHITE}" "${ENDCOLOR}" "${F_DEFAULT}")

  # Background Colours
  declare -a text_background=("${B_BLACK}" "${B_RED}" "${B_GREEN}" "${B_YELLOW}" "${B_ORANGE}" "${B_MAGENTA}" "${B_CYAN}" "${B_WHITE}" "${B_ENDCOLOR}" "${B_DEFAULT}")

  for i in "${text_styles[@]}"
  do
    string=$(echo "${string}" | tr -d "${i}")

  done

  for j in "${text_colors[@]}"
  do
    string=$(echo "${string}" | tr -d "${j}")

  done

  for k in "${text_background[@]}"
  do
    string=$(echo "${string}" | tr -d "${k}")

  done

  # Return
  echo "${string}"

}

function change_ownership(){

  #$1 = ${user}
  #$2 = ${group}
  #$3 = ${path}

  local user=$1
  local group=$2
  local path=$3

  log_event "debug" "Running: chown -R ${user}:${group} ${path}"

  chown -R "${user}":"${group}" "${path}"

  #display --indent 2 --text "- Changing ownership of ${path} to ${user}:${group}" --result "DONE" --color GREEN

}

function prompt_return_or_finish() {

  log_break "true"

  while true; do

    echo -e "${YELLOW}${ITALIC} > Do you want to return to menu?${ENDCOLOR}"
    read -p "Please type 'y' or 'n'" yn

    case $yn in

      [Yy]*)
        break
      ;;

      [Nn]*)
        echo -e "${B_RED}Exiting script ...${ENDCOLOR}"
        exit 0
      ;;

      *) 
        echo "Please answer yes or no." 
      ;;

    esac

  done

  clear_last_line
  clear_last_line

}

function extract () {
  
  # $1 - File to uncompress or extract
  # $2 - Dir to uncompress file
  # $3 - Optional compress-program (ex: lbzip2)

  local file=$1
  local directory=$2
  local compress_type=$3

  log_event "info" "Trying to extract compressed file: ${file}"

  if [[ -f "${file}" ]]; then

      case "${file}" in

          *.tar.bz2)
            if [ -z "${compress_type}" ]; then
              tar xp "${file}" -C "${directory}" --use-compress-program="${compress_type}"
            else
              tar xjf "${file}" -C "${directory}"
            fi
          ;;

          *.tar.gz)
              tar -xzvf "${file}" -C "${directory}";;

          *.bz2)
              bunzip2 "${file}";;

          *.rar)
              unrar x "${file}";;

          *.gz)
              gunzip "${file}";;

          *.tar)
              tar xf "${file}" -C "${directory}";;

          *.tbz2)
              tar xjf "${file}" -C "${directory}";;

          *.tgz)
              tar xzf "${file}" -C "${directory}";;

          *.zip)
              unzip "${file}";;

          *.Z)
              uncompress "${file}";;

          *.7z)
              7z x "${file}";;

          *.xz)
              tar xvf "${file}" -C "${directory}";;

          *)
              echo "${file} cannot be extracted via extract()";;

      esac

  else
      log_event "error" "${file} is not a valid file"

  fi

}

function get_domain_extension() {

  # $1 = ${domain}

  local domain=$1

  local first_lvl 
  local next_lvl 
  local domain_ext

  log_event "info" "Working with domain: ${domain}"

  # Get first_lvl domain name
  first_lvl="$(cut -d'.' -f1 <<<"${domain}")"

  # Extract first_lvl
  domain_ext=${domain#"$first_lvl."}

  next_lvl="${first_lvl}"

  local -i count=0
  while ! grep --word-regexp --quiet ".${domain_ext}" "${SFOLDER}/config/domain_extension-list" && [ ! "${domain_ext#"$next_lvl"}" = "" ]
  do

    # Remove next level domain-name
    domain_ext=${domain_ext#"$next_lvl."}
    next_lvl="$(cut -d'.' -f1 <<<"${domain_ext}")"

    count=("$count"+1)

  done

  if  grep --word-regexp --quiet ".${domain_ext}" "${SFOLDER}/config/domain_extension-list" ; then

    domain_ext=.${domain_ext}

    # Logging
    log_event "debug" "Extracting domain extension from ${domain}."
    log_event "debug" "Domain extension extracted: ${domain_ext}"

    # Return
    echo "${domain_ext}"

  else

    # Logging
    log_event "error" "Extracting domain extension from ${domain}"

    return 1

  fi

}

function extract_filename_from_path() {

  # $1 = ${file_with_path}

  local file_with_path=$1

  local file_name

  file_name="$(basename -- "${file_with_path}")"

  # Return
  echo "${file_name}"

}

function extract_domain_extension() {

  # $1 = ${domain}

  local domain=$1

  local domain_extension
  local domain_no_ext

  domain_extension="$(get_domain_extension "${domain}")"
  domain_extension_output=$?
  if [[ ${domain_extension_output} -eq 0 ]]; then

    domain_no_ext=${domain%"$domain_extension"}

    # Logging
    log_event "debug" "domain_no_ext: ${domain_no_ext}"

    # Return
    echo "${domain_no_ext}"

  else

    log_break "true"
    return 1

  fi

}

function get_root_domain() {

  # $1 = ${domain}

  local domain=$1

  local domain_extension
  local domain_no_ext

  # Get Domain Ext
  domain_extension="$(get_domain_extension "${domain}")"

  # Check result
  domain_extension_output=$?
  if [[ ${domain_extension_output} -eq 0 ]]; then

    # Remove domain extension
    domain_no_ext=${domain%"$domain_extension"}

    root_domain=${domain_no_ext##*.}${domain_extension}

    # Return
    echo "${root_domain}"

  else

    return 1

  fi

}

function get_subdomain_part() {

  # $1 = ${domain}

  local domain=$1

  local domain_extension
  local domain_no_ext
  local subdomain_part

  # Get Domain Ext
  domain_extension="$(get_domain_extension "${domain}")"

  # Check result
  domain_extension_output=$?
  if [[ ${domain_extension_output} -eq 0 ]]; then

    # Remove domain extension
    domain_no_ext=${domain%"$domain_extension"}

    root_domain=${domain_no_ext##*.}${domain_extension}

    if [[ ${root_domain} != ${domain}  ]]; then

      subdomain_part=${domain//.$root_domain/}

      # Return
      echo "${subdomain_part}"

    else

      # Return
      echo ""

    fi

  else

    return 1

  fi

}

function install_crontab_script() {

  # $1 = ${script}
  # $2 = ${scheduled_time}

  local script=$1
  local scheduled_time=$2

  local cron_file

  log_section "Cron Tasks"

  cron_file="/var/spool/cron/crontabs/root"

  if [[ ! -f ${cron_file} ]]; then
    log_event "info" "Cron file for root does not exist, creating ..."

	  touch "${cron_file}"
	  /usr/bin/crontab "${cron_file}"

    log_event "success" "Cron file created"
    display --indent 2 --text "- Creating log file" --result DONE --color GREEN

	fi

  grep -qi "${script}" "${cron_file}"
  grep_result=$?
	if [[ ${grep_result} != 0 ]]; then

    log_event "info" "Updating cron job for script: ${script}"
    /bin/echo "${scheduled_time} ${script}" >> "${cron_file}"

    display --indent 2 --text "- Updating cron job" --result DONE --color GREEN

  else
    log_event "warning" "Script already installed"
    display --indent 2 --text "- Updating cron job" --result FAIL --color YELLOW
    display --indent 4 --text "Script already installed"

	fi

}

#
#################################################################################
#
# * Ask-for
#
#################################################################################
#

function ask_project_state() {

  #$1 = ${state} optional to select default option

  local state=$1

  project_states="prod stage beta test dev"
  project_state=$(whiptail --title "Project State" --menu "Choose a Project State" 20 78 10 $(for x in ${project_states}; do echo "$x [X]"; done) --default-item "${state}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Return
    echo "${project_state}"

  else

    return 1

  fi

}

function ask_project_name() {

  #$1 = ${project_name} optional to select default option

  local name=$1

  # Replace '-' and '.' chars
  name=$(echo "${name}" | sed -r 's/[.-]+/_/g')

  # TODO: remove some suffix keywords '_com' '_ar' '_es' ... and prefix 'www_'

  project_name=$(whiptail --title "Project Name" --inputbox "Insert a project name (only separator allow is '_'). Ex: my_domain" 10 60 "${name}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Return
    echo "${project_name}"

  else
    return 1

  fi

}

function ask_project_domain() {

  #$1 = ${project_domain} optional to select default option

  local project_domain=$1
  
  project_domain=$(whiptail --title "Domain" --inputbox "Insert the project's domain. Example: landing.domain.com" 10 60 "${project_domain}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Return
    echo "${project_domain}"

  else
    return 1

  fi

}

function ask_project_type() {

  local project_types
  local project_type

  project_types="WordPress X Laravel X Basic-PHP X HTML X"
  
  project_type=$(whiptail --title "SELECT PROJECT TYPE" --menu " " 20 78 10 $(for x in ${project_types}; do echo "$x"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Lowercase
    project_type="$(echo "${project_type}" | tr '[A-Z]' '[a-z]')"

    # Return
    echo "${project_type}"

  else
    return 1

  fi

}

function ask_rootdomain_for_cloudflare_config() {

  # TODO: check with CF API if root domain exists

  # $1 = ${root_domain} (could be empty)

  local root_domain=$1

  if [[ -z "${root_domain}" ]]; then
    root_domain=$(whiptail --title "Root Domain" --inputbox "Insert the root domain of the Project (Only for Cloudflare API). Example: broobe.com" 10 60 3>&1 1>&2 2>&3)
  else
    root_domain=$(whiptail --title "Root Domain" --inputbox "Insert the root domain of the Project (Only for Cloudflare API). Example: broobe.com" 10 60 "${root_domain}" 3>&1 1>&2 2>&3)
  fi
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then
    # Return
    echo "${root_domain}"

  else
    return 1

  fi

}

function ask_subdomains_to_cloudflare_config() {

  # TODO: MAKE IT WORKS

  # $1 = ${subdomains} optional to select default option (could be empty)

  local subdomains=$1;

  subdomains=$(whiptail --title "Cloudflare Subdomains" --inputbox "Insert the subdomains you want to update in Cloudflare (comma separated). Example: www.broobe.com,broobe.com" 10 60 "${DOMAIN}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    log_event "info" "Setting subdomains=${subdomains}"

    # Return
    echo "${subdomains}"

  else
    return 1

  fi

}

function ask_folder_to_install_sites() {

  # $1 = ${folder_to_install} optional to select default option (could be empty)

  local folder_to_install=$1

  if [[ -z "${folder_to_install}" ]]; then
    
    folder_to_install=$(whiptail --title "Folder to work with" --inputbox "Please select the project folder you want to work with:" 10 60 "${folder_to_install}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      log_event "info" "Folder to work with: ${folder_to_install}"

      # Return
      echo "${folder_to_install}"

    else
      return 1

    fi

  else

    log_event "info" "Folder to install: ${folder_to_install}"
    
    # Return
    echo "${folder_to_install}"
    
  fi

}

function ask_mysql_root_psw() {

  local mysql_root_pass

  # Check MySQL credentials on .my.cnf
  if [[ ! -f ${MYSQL_CONF} ]]; then

    mysql_root_pass=$(whiptail --title "MySQL root password" --inputbox "Please insert the MySQL root password" 10 60 "${mysql_root_pass}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then
      
      until mysql -u root -p"${mysql_root_pass}" -e ";"; do
        read -s -p " > Can't connect to MySQL, please re-enter ${MUSER} password: " mysql_root_pass
      
      done

      # Create new MySQL credentials file
      echo "[client]" >/root/.my.cnf
      echo "user=root">>/root/.my.cnf
      echo "password=${mysql_root_pass}">>/root/.my.cnf

    else

      return 1

    fi

  fi

}

#
#################################################################################
#
# * Menues
#
#################################################################################
#

function menu_main_options() {

  local whip_title              # whiptail var
  local whip_description        # whiptail var
  local runner_options          # whiptail array options
  local chosen_type             # whiptail var

  whip_title="LEMP UTILS SCRIPT"
  whip_description=" "

  runner_options=(
    "01)" "BACKUP OPTIONS" 
    "02)" "RESTORE OPTIONS" 
    "03)" "PROJECT UTILS" 
    "04)" "WPCLI MANAGER" 
    "05)" "CERTBOT MANAGER" 
    "06)" "CLOUDFLARE MANAGER" 
    "07)" "INSTALLERS & CONFIGS" 
    "08)" "IT UTILS" 
    "09)" "SCRIPT OPTIONS" 
    "10)" "CRON TASKS"
    )
  chosen_type=$(whiptail --title "${whip_title}" --menu "${whip_description}" 20 78 10 "${runner_options[@]}" 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    if [[ ${chosen_type} == *"01"* ]]; then
      menu_backup_options

    fi
    if [[ ${chosen_type} == *"02"* ]]; then
      restore_backup_menu

    fi

    if [[ ${chosen_type} == *"03"* ]]; then
      menu_project_utils

    fi

    if [[ ${chosen_type} == *"04"* ]]; then
      # shellcheck source=${SFOLDER}/utils/wpcli_manager.sh
      source "${SFOLDER}/utils/wpcli_manager.sh"

      wpcli_manager

    fi
    if [[ ${chosen_type} == *"05"* ]]; then
      # shellcheck source=${SFOLDER}/utils/certbot_manager.sh
      source "${SFOLDER}/utils/certbot_manager.sh"

      certbot_helper_menu

    fi
    if [[ ${chosen_type} == *"06"* ]]; then
      # shellcheck source=${SFOLDER}/utils/cloudflare_manager.sh
      source "${SFOLDER}/utils/cloudflare_manager.sh"

      cloudflare_helper_menu

    fi
    if [[ ${chosen_type} == *"07"* ]]; then
      installers_and_configurators

    fi
    if [[ ${chosen_type} == *"08"* ]]; then
      it_utils_menu

    fi
    if [[ ${chosen_type} == *"09"* ]]; then
      script_configuration_wizard "reconfigure"

    fi
    if [[ ${chosen_type} == *"10"* ]]; then
      # CRON SCRIPT TASKS
      menu_cron_script_tasks

    fi

  else

    echo -e "${B_RED}Exiting script ...${ENDCOLOR}"
    exit 0

  fi

}

function menu_first_run() {

  local first_run_options
  local first_run_string
  local chosen_first_run_options

  first_run_options=(
    "01)" "RUN LEMP SETUP" 
    "02)" "CONFIGURE THIS SCRIPT"
  )

  first_run_string+="\n It seens to be the first time you run this script.\n"
  first_run_string+=" Now you have to options:\n"
  first_run_string+="\n"
       
  chosen_first_run_options=$(whiptail --title "LEMP UTILS SCRIPT" --menu "${first_run_string}" 20 78 10 "${first_run_options[@]}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    if [[ ${chosen_first_run_options} == *"01"* ]]; then
      
      # shellcheck source=${SFOLDER}/utils/lemp_setup.sh
      source "${SFOLDER}/utils/lemp_setup.sh"

      lemp_setup

      exit 1

    else
      script_configuration_wizard "initial"

    fi

  else

    exit 1

  fi

}

function menu_cron_script_tasks() {

  local runner_options 
  local chosen_type 
  local scheduled_time

  runner_options=(
    "01)" "BACKUPS TASKS" 
    "02)" "OPTIMIZER TASKS" 
    "03)" "WORDPRESS TASKS" 
    "04)" "UPTIME TASKS" 
    "05)" "SCRIPT UPDATER"
    )
  chosen_type=$(whiptail --title "CRONEABLE TASKS" --menu "\n" 20 78 10 "${runner_options[@]}" 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    if [[ ${chosen_type} == *"01"* ]]; then

      # BACKUPS-TASKS
      suggested_cron="45 00 * * *" # Every day at 00:45 AM
      scheduled_time=$(whiptail --title "CRON BACKUPS-TASKS" --inputbox "Insert a cron expression for the task:" 10 60 "${suggested_cron}" 3>&1 1>&2 2>&3)
      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then
        
        install_crontab_script "${SFOLDER}/cron/backups_tasks.sh" "${scheduled_time}"

      fi

    fi
    if [[ ${chosen_type} == *"02"* ]]; then

      # OPTIMIZER-TASKS
      suggested_cron="45 04 * * *" # Every day at 04:45 AM
      scheduled_time=$(whiptail --title "CRON OPTIMIZER-TASKS" --inputbox "Insert a cron expression for the task:" 10 60 "${suggested_cron}" 3>&1 1>&2 2>&3)
      exitstatus=$?
      if [[ ${exitstatus} = 0 ]]; then
        
        install_crontab_script "${SFOLDER}/cron/optimizer_tasks.sh" "${scheduled_time}"

      fi

    fi
    if [[ ${chosen_type} == *"03"* ]]; then

      # WORDPRESS-TASKS
      suggested_cron="45 23 * * *" # Every day at 23:45 AM
      scheduled_time=$(whiptail --title "CRON WORDPRESS-TASKS" --inputbox "Insert a cron expression for the task:" 10 60 "${suggested_cron}" 3>&1 1>&2 2>&3)
      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then
        
        install_crontab_script "${SFOLDER}/cron/wordpress_tasks.sh" "${scheduled_time}"

      fi

    fi
    if [[ ${chosen_type} == *"04"* ]]; then

      # UPTIME-TASKS
      suggested_cron="45 22 * * *" # Every day at 22:45 AM
      scheduled_time=$(whiptail --title "CRON UPTIME-TASKS" --inputbox "Insert a cron expression for the task:" 10 60 "${suggested_cron}" 3>&1 1>&2 2>&3)
      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then
        
        install_crontab_script "${SFOLDER}/cron/uptime_tasks.sh" "${scheduled_time}"

      fi

    fi
    if [[ ${chosen_type} == *"05"* ]]; then

      # SCRIPT-UPDATER
      suggested_cron="45 22 * * *" # Every day at 22:45 AM
      scheduled_time=$(whiptail --title "CRON UPTIME-TASKS" --inputbox "Insert a cron expression for the task:" 10 60 "${suggested_cron}" 3>&1 1>&2 2>&3)
      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then
        
        install_crontab_script "${SFOLDER}/cron/updater.sh" "${scheduled_time}"

      fi

    fi

    prompt_return_or_finish
    menu_cron_script_tasks

  fi

  menu_main_options

}

function menu_security_utils () {

  # TODO: new options? https://upcloud.com/community/tutorials/scan-ubuntu-server-malware/

  local security_options chosen_security_options

  security_options=(
    "01)" "CLAMAV MALWARE SCAN" 
    "02)" "CUSTOM MALWARE SCAN" 
    "03)" "LYNIS SYSTEM AUDIT"
    )
  chosen_security_options=$(whiptail --title "SECURITY TOOLS" --menu "Choose an option to run" 20 78 10 "${security_options[@]}" 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    security_install

    if [[ ${chosen_security_options} == *"01"* ]]; then
      menu_security_clamav_scan

    fi
    if [[ ${chosen_security_options} == *"02"* ]]; then
      menu_security_custom_scan

    fi
    if [[ ${chosen_security_options} == *"03"* ]]; then
      menu_security_system_audit

    fi

    prompt_return_or_finish
    menu_security_utils

  fi

  menu_main_options

}

function menu_security_clamav_scan () {

  local to_scan

  startdir="${SITES}"
  directory_browser "${menutitle}" "${startdir}"

  to_scan=$filepath"/"$filename

  log_event "info" "Starting clamav scan on: ${to_scan}" "false"

  security_clamav_scan "${to_scan}"

}

function menu_security_custom_scan () {

  local to_scan

  startdir="${SITES}"
  directory_browser "${menutitle}" "${startdir}"

  to_scan=$filepath"/"$filename

  log_event "info" "Starting custom scan on: ${to_scan}" "false"

  security_custom_scan "${to_scan}"

}

function menu_project_utils () {

  local whip_title 
  local whip_description
  local project_utils_options
  local chosen_project_utils_options

  whip_title="PROJECT UTILS"
  whip_description=" "

  project_utils_options=(
    "01)" "CREATE WP PROJECT" 
    "02)" "CREATE PHP PROJECT" 
    "03)" "DELETE PROJECT"
    "04)" "CREATE PROJECT DB  & USER" 
    "05)" "PUT PROJECT ONLINE" 
    "06)" "PUT PROJECT OFFLINE" 
    "07)" "REGENERATE NGINX SERVER" 
    "08)" "BENCH PROJECT GTMETRIX"
    )
  chosen_project_utils_options=$(whiptail --title "${whip_title}" --menu "${whip_description}" 20 78 10 "${project_utils_options[@]}" 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [[ ${exitstatus} = 0 ]]; then

    if [[ ${chosen_project_utils_options} == *"01"* ]]; then
      
      # CREATE-WP-PROJECT
      project_install "${SITES}" "wordpress"

    fi

    if [[ ${chosen_project_utils_options} == *"02"* ]]; then

      # CREATE-PHP-PROJECT
      project_install "${SITES}" "php"

    fi

    if [[ ${chosen_project_utils_options} == *"03"* ]]; then

      # DELETE-PROJECT
      project_delete ""

    fi

    if [[ ${chosen_project_utils_options} == *"04"* ]]; then

      # CREATE PROJECT DATABASE & USER
      log_subsection "Create Project DB & User"
      
      # Folder where sites are hosted: $SITES
      menu_title="PROJECT TO WORK WITH"
      directory_browser "${menu_title}" "${SITES}"

      # Directory_broser returns: " $filepath"/"$filename
      if [[ -z "${filepath}" || "${filepath}" == "" ]]; then

        log_event "info" "Operation cancelled!"

        # Return
        #return 1
      
      else

        project_name="$(extract_domain_extension "${filename%/}")"
        project_name="$(mysql_name_sanitize "${project_name}")"
        project_name="$(ask_project_name "${project_name}")"

        log_event "info" "project_name: ${project_name}!"

        project_state=$(ask_project_state "")
        database_user_passw=$(openssl rand -hex 12)

        mysql_database_create "${project_name}_${project_state}"
        mysql_user_create "${project_name}_user" "${database_user_passw}"
        mysql_user_grant_privileges "${project_name}_user" "${project_name}_${project_state}"

        # TODO: check if is a wp project
        # TODO: change wp-config.php on wp projects

        # TODO: ask if want to import?

      fi

    fi

    if [[ ${chosen_project_utils_options} == *"05"* ]]; then

      # PUT PROJECT ONLINE
      change_project_status "online"

    fi

    if [[ ${chosen_project_utils_options} == *"06"* ]]; then

      # PUT PROJECT OFFLINE
      change_project_status "offline"

    fi

    if [[ ${chosen_project_utils_options} == *"07"* ]]; then

      # REGENERATE NGINX SERVER

      log_section "Nginx Manager"

      # Select project to work with
      directory_browser "Select a Website to work with" "${SITES}" #return $filename

      if [ "${filename}" != "" ]; then

        filename="${filename::-1}" # remove '/'
        
        display --indent 2 --text "- Selecting website to work with" --result DONE --color GREEN
        display --indent 4 --text "Selected website: ${filename}"

        # Aks project domain
        project_domain=$(ask_project_domain "${filename}")

        # Aks project type
        project_type=$(ask_project_type)
        
        # New site Nginx configuration
        nginx_server_create "${project_domain}" "${project_type}" "single" ""

      else

        display --indent 2 "Selecting website to work with" --result SKIPPED --color YELLOW

      fi

    fi

    if [[ ${chosen_project_utils_options} == *"08"* ]]; then

      # BENCH PROJECT GTMETRIX

      URL_TO_TEST=$(whiptail --title "GTMETRIX TEST" --inputbox "Insert test URL including http:// or https://" 10 60 3>&1 1>&2 2>&3)
      exitstatus=$?
      if [[ ${exitstatus} = 0 ]]; then
        # shellcheck source=${SFOLDER}/tools/third-party/google-insights-api-tools/gitools_v5.sh
        source "${SFOLDER}/tools/third-party/google-insights-api-tools/gitools_v5.sh" gtmetrix "${URL_TO_TEST}"
      fi

    fi

    prompt_return_or_finish
    menu_project_utils

  fi

  menu_main_options

}

#
#############################################################################
#
# * Help
#
#############################################################################
#

function show_help() {

  log_section "Help Menu"
  
  echo -n "./runner.sh [TASK] [SUB-TASK]... [DOMAIN]...

  Options:
    -t, --task        Task to run:
                        project-backup
                        project-restore
                        project-install
                        cloudflare-api
    -st, --subtask    Sub-task to run:
                        from cloudflare-api: clear_cache, dev_mode
    -s  --site        Site path for tasks execution
    -d  --domain      Domain for tasks execution
    -pn --pname       Project Name
    -pt --ptype       Project Type (wordpress,laravel)
    -ps --pstate      Project State (prod,dev,test,stage)
    -q, --quiet       Quiet (no output)
    -v, --verbose     Output more information. (Items echoed to 'verbose')
    -d, --debug       Runs script in BASH debug mode (set -x)
    -h, --help        Display this help and exit
        --version     Output version information and exit

  "

}

#
#############################################################################
#
# * Tasks
#
#############################################################################
#

function tasks_handler() {

  local task=$1

  case ${task} in

    backup)

      subtasks_backup_handler "${STASK}"

      exit
    ;;

    restore)
      log_event "warning" "TODO: run project-restore for $SITE" "true"
      exit
    ;;

    project-install)
      log_event "debug" "Running: project_install ${SITES} wordpress ${DOMAIN} ${PNAME} ${PSTATE}"
      project_install "${SITES}" "${PTYPE}" "${DOMAIN}" "${PNAME}" "${PSTATE}"
      exit
    ;;

    cloudflare-api)
      subtasks_cloudflare_handler "${STASK}"
      
      exit
    ;;

    *)
      log_event "error" "INVALID TASK: ${TASK}" "true"
      #ExitFatal
    ;;

  esac

}

function subtasks_backup_handler() {

  local subtask=$1

  case ${subtask} in

    all)

      log_event "debug" "Running: complete backup"
      #make_databases_backup
      make_all_server_config_backup
      make_sites_files_backup

      exit
    ;;

    files)

      log_event "debug" "Running: make_sites_files_backup"
      make_sites_files_backup

      exit
    ;;

    server-config)

      log_event "debug" "Running: make_all_server_config_backup"
      make_all_server_config_backup

      exit
    ;;

    databases)

      log_event "warning" "TODO: database backup from parameter" "true"
      #log_event "debug" "Running: make_sites_files_backup"
      #make_sites_files_backup

      exit
    ;;

    *)
      log_event "error" "INVALID SUBTASK: ${subtask}" "true"

      exit
    ;;

  esac

}

function subtasks_cloudflare_handler() {

  local subtask=$1

  case ${subtask} in

    clear_cache)

      log_event "debug" "Running: cloudflare_clear_cache ${DOMAIN}"
      cloudflare_clear_cache "${DOMAIN}"

      exit
    ;;

    dev_mode)

      log_event "debug" "Running: cloudflare_development_mode ${DOMAIN}"
      cloudflare_development_mode "${DOMAIN}"

      exit
    ;;

    *)

      log_event "error" "INVALID SUBTASK: ${subtask}" "true"
    
      exit
    ;;

  esac

}

#
#############################################################################
#
# * Flags
#
#############################################################################
#

function parse_params() {

  # default values of variables set from params
  param=''

  while :; do

    case "${1-}" in

      -h|-\?|--help)
        show_help    # Display a usage synopsis
        exit
      ;;

      -d|--debug)
        SHOWDEBUG=1
      ;;

      -t|--task)
        i="$((i+1))"
        TASK=${parameters[$i]}
      ;;

      -st|--subtask)
        i="$((i+1))"
        STASK=${parameters[$i]}
      ;;

      -s|--site)
        i="$((i+1))"
        SITE=${parameters[$i]}
      ;;

      -pn|--pname)
        i="$((i+1))"
        PNAME=${parameters[$i]}
      ;;

      -pt|--ptype)
        i="$((i+1))"
        PTYPE=${parameters[$i]}
      ;;

      -ps|--pstate)
        i="$((i+1))"
        PSTATE=${parameters[$i]}
      ;;

      -do|--domain)
        i="$((i+1))"
        DOMAIN=${parameters[$i]}
      ;;

      *)
        echo "INVALID OPTION: $i" >&2
        exit
      ;;

    esac

    shift

  done

  #args=("$@")

  # check required params and arguments
  #[[ -z "${param-}" ]] && die "Missing required parameter: param"
  #[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0

}

function flags_handler() {

  local arguments_count=$1
  local arguments=$2

  local parameters
  local i=0

  IFS=', ' read -a parameters <<< "$arguments"; # convert parameter to an array

  TASK=""; SITE=""; DOMAIN=""; PNAME=""; PTYPE=""; PSTATE=""; SHOWDEBUG=0;
    
  while [[ $i < ${arguments_count} ]]; do

    case ${parameters[$i]} in

      -h|-\?|--help)
        show_help    # Display a usage synopsis
        exit
      ;;

      -d|--debug)
        SHOWDEBUG=1
      ;;

      -t|--task)
        i="$((i+1))"
        TASK=${parameters[$i]}
      ;;

      -st|--subtask)
        i="$((i+1))"
        STASK=${parameters[$i]}
      ;;

      -s|--site)
        i="$((i+1))"
        SITE=${parameters[$i]}
      ;;

      -pn|--pname)
        i="$((i+1))"
        PNAME=${parameters[$i]}
      ;;

      -pt|--ptype)
        i="$((i+1))"
        PTYPE=${parameters[$i]}
      ;;

      -ps|--pstate)
        i="$((i+1))"
        PSTATE=${parameters[$i]}
      ;;

      -do|--domain)
        i="$((i+1))"
        DOMAIN=${parameters[$i]}
      ;;

      *)
        echo "INVALID OPTION: $i" >&2
        exit
      ;;
    
    esac

    i="$((i+1))"

  done

  tasks_handler "${TASK}"

}
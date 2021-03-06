#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
#############################################################################

# Check if program is installed (is_this_installed "mysql-server")
function is_this_installed() {

  # $1 = ${package}

  local package=$1

  if [ "$(dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -c "ok installed")" == "1" ]; then

    log_event "info" "${package} is installed"

    # Return
    echo "true"

  else

    log_event "info" "${package} is not installed"

    # Return
    echo "false"

  fi

}

function install_package_if_not() {

  # $1 = ${package}

  local package=$1

  if [[ "$(is_this_installed "${package}")" != "${package} is installed, it must be a clean server." ]]; then

    apt update -q4 &
    spinner_loading && apt install "${package}" -y

    log_event "info" "${package} installed"

  fi

}

# Adding PPA (support multiple args)
# Ex: add_ppa ondrej/php ondrej/nginx
function add_ppa() {

  local exit_status

  for i in "$@"; do

    grep -h "^deb.*$i" /etc/apt/sources.list.d/* >/dev/null 2>&1
    exit_status=$?
    if [[ ${exit_status} -ne 0 ]]; then
      echo "Adding ppa:$i"
      add-apt-repository -y ppa:"${i}"
    else
      echo "ppa:${i} already exists"
    fi

  done
  
}

function check_packages_required() {

  log_event "info" "Checking required packages ..."
  log_section "Script Package Manager"

  # Declare globals
  declare -g SENDEMAIL
  declare -g PV
  declare -g BC
  declare -g DIG
  declare -g LBZIP2
  declare -g ZIP
  declare -g UNZIP
  declare -g GIT
  declare -g MOGRIFY
  declare -g JPEGOPTIM
  declare -g OPTIPNG
  declare -g TAR
  declare -g FIND
  declare -g MYSQL
  declare -g MYSQLDUMP
  declare -g PHP
  declare -g CERTBOT

  # Check if sendemail is installed
  SENDEMAIL="$(command -v sendemail)"
  if [[ ! -x "${SENDEMAIL}" ]]; then
    display --indent 2 --text "- Installing sendemail"
    apt-get --yes install sendemail libio-socket-ssl-perl -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing sendemail" --result "DONE" --color GREEN
  fi

  # Check if pv is installed
  PV="$(command -v pv)"
  if [[ ! -x "${PV}" ]]; then
    display --indent 2 --text "- Installing pv"
    apt-get --yes install pv -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing pv" --result "DONE" --color GREEN
  fi

  # Check if bc is installed
  BC="$(command -v bc)"
  if [[ ! -x "${BC}" ]]; then
    display --indent 2 --text "- Installing bc"
    apt-get --yes install bc -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing bc" --result "DONE" --color GREEN
  fi

  # Check if dig is installed
  DIG="$(command -v dig)"
  if [[ ! -x "${DIG}" ]]; then
    display --indent 2 --text "- Installing dnsutils"
    apt-get --yes install dnsutils -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing dnsutils" --result "DONE" --color GREEN
  fi

  # Check if net-tools is installed
  IFCONFIG="$(command -v ifconfig)"
  if [[ ! -x "${IFCONFIG}" ]]; then
    display --indent 2 --text "- Installing net-tools"
    apt-get --yes install net-tools -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing net-tools" --result "DONE" --color GREEN
  fi

  # Check if lbzip2 is installed
  LBZIP2="$(command -v lbzip2)"
  if [[ ! -x "${LBZIP2}" ]]; then
    display --indent 2 --text "- Installing lbzip2"
    apt-get --yes install lbzip2 -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing lbzip2" --result "DONE" --color GREEN
  fi

  # Check if zip is installed
  ZIP="$(command -v zip)"
  if [[ ! -x "${ZIP}" ]]; then
    display --indent 2 --text "- Installing zip"
    apt-get --yes install zip -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing zip" --result "DONE" --color GREEN
  fi

  # Check if unzip is installed
  UNZIP="$(command -v unzip)"
  if [[ ! -x "${UNZIP}" ]]; then
    display --indent 2 --text "- Installing unzip"
    apt-get --yes install unzip -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing unzip" --result "DONE" --color GREEN
  fi

  # Check if unzip is installed
  GIT="$(command -v git)"
  if [[ ! -x "${GIT}" ]]; then
    display --indent 2 --text "- Installing git"
    apt-get --yes install git -qq > /dev/null
    clear_last_line
    display --indent 2 --text "- Installing git" --result "DONE" --color GREEN
  fi

  # MOGRIFY
  MOGRIFY="$(command -v mogrify)"
  if [[ ! -x "${MOGRIFY}" ]]; then
    # Install image optimize packages
    install_image_optimize_packages
  fi

  # JPEGOPTIM
  JPEGOPTIM="$(command -v jpegoptim)"

  # OPTIPNG
  OPTIPNG="$(command -v optipng)"

  # TAR
  TAR="$(command -v tar)"

  # FIND
  FIND="$(command -v find)"

  # MySQL
  MYSQL="$(command -v mysql)"
  if [[ ! -x ${MYSQL} ]]; then

    display --indent 2 --text "- Checking MySQL installation" --result "WARNING" --color YELLOW
    display --indent 4 --text "MySQL not found" --tcolor YELLOW
    return 1

  else

    MYSQLDUMP="$(command -v mysqldump)"

    if [[ -f ${MYSQL_CONF} ]]; then
      # Append login parameters to command
      MYSQL_ROOT="${MYSQL} --defaults-file=${MYSQL_CONF}"
      MYSQLDUMP_ROOT="${MYSQLDUMP} --defaults-file=${MYSQL_CONF}"
      
    fi

  fi

  # PHP
  PHP="$(command -v php)"
  if [[ ! -x "${PHP}" ]]; then

    display --indent 2 --text "- Checking PHP installation" --result "WARNING" --color YELLOW
    display --indent 4 --text "PHP not found" --tcolor YELLOW
    return 1

  else

    # PHP is installed, now checking WP-CLI
    WPCLI_INSTALLED=$(wpcli_check_if_installed)
    if [[ ${WPCLI_INSTALLED} = "true" ]]; then
      wpcli_update
    else
      wpcli_install
    fi

  fi

  # CERTBOT
  CERTBOT="$(command -v certbot)"
  if [[ ! -x "${CERTBOT}" ]]; then
    display --indent 2 --text "- Checking CERTBOT installation" --result "WARNING" --color YELLOW
    display --indent 4 --text "CERTBOT not found" --tcolor YELLOW
    return 1

  fi

  display --indent 6 --text "- Checking script dependencies" --result "DONE" --color GREEN
  log_event "info" "All required packages are installed"

}

function basic_packages_installation() {

  log_subsection "Basic Packages Installation"
  
  # Updating packages lists
  log_event "info" "Adding repos and updating package lists ..."
  display --indent 6 --text "- Adding repos and updating package lists"

  apt-get --yes install software-properties-common > /dev/null
  apt-get --yes update -qq > /dev/null

  clear_last_line
  display --indent 6 --text "- Adding repos and updating package lists" --result "DONE" --color GREEN

  # Upgrading packages
  log_event "info" "Upgrading packages before installation ..."
  display --indent 6 --text "- Upgrading packages before installation"

  apt-get --yes dist-upgrade -qq > /dev/null

  clear_last_line
  display --indent 6 --text "- Upgrading packages before installation" --result "DONE" --color GREEN

  # Installing packages
  log_event "info" "Installing basic packages ..."
  display --indent 6 --text "- Installing basic packages"

  apt-get --yes install vim unzip zip clamav ncdu imagemagick-* jpegoptim optipng webp sendemail libio-socket-ssl-perl dnsutils ghostscript pv ppa-purge -qq > /dev/null

  clear_last_line
  display --indent 6 --text "- Installing basic packages" --result "DONE" --color GREEN

}

function selected_package_installation() {

  # Define array of Apps to install
  local -n apps_to_install=(
    "certbot" " " off
    "monit" " " off
    "netdata" " " off
    "cockpit" " " off
    "zabbix" " " off
  )

  local chosen_apps

  chosen_apps=$(whiptail --title "Apps Selection" --checklist "Select the apps you want to install:" 20 78 15 "${apps_to_install[@]}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    log_subsection "Package Installer"

    for app in ${chosen_apps}; do
      
      app=$(sed -e 's/^"//' -e 's/"$//' <<<${app}) #needed to ommit double quotes

      log_event "info" "Executing ${app} installer ..."
      
      case ${app} in

        certbot)
          certbot_installer
        ;;

        monit)
          monit_installer_menu
        ;;

        netdata)
          netdata_installer
        ;;

        cockpit)
          cockpit_installer
        ;;

        zabbix)
          zabbix_server_installer
        ;;

        *)
          log_event "error" "Package installer for ${app} not found!"
        ;;

      esac

    done

  else

    log_event "info" "Package installer ommited ..."
  
  fi

}

function timezone_configuration() {

  #configure timezone
  dpkg-reconfigure tzdata
  
  display --indent 6 --text "- Time Zone configuration" --result "DONE" --color GREEN

}

function remove_old_packages() {

  log_event "info" "Cleanning old system packages ..."
  display --indent 6 --text "- Cleanning old system packages"

  apt-get --yes clean -qq > /dev/null
  apt-get --yes autoremove -qq > /dev/null
  apt-get --yes autoclean -qq > /dev/null

  log_event "info" "Old system packages cleaned"
  clear_last_line
  display --indent 6 --text "- Cleanning old system packages" --result "DONE" --color GREEN

}

function install_image_optimize_packages() {

  log_event "info" "Installing jpegoptim, optipng and imagemagick"
  display --indent 6 --text "- Installing jpegoptim, optipng and imagemagick"

  apt-get --yes install jpegoptim optipng pngquant gifsicle imagemagick-* -qq > /dev/null

  log_event "info" "Installation finished"
  clear_last_line # need an extra call to clear installation output
  clear_last_line
  display --indent 6 --text "- Installing jpegoptim, optipng and imagemagick" --result "DONE" --color GREEN

}

#!/bin/bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.1
################################################################################

# shellcheck source=${SFOLDER}/libs/commons.sh
source "${SFOLDER}/libs/commons.sh"
# shellcheck source=${SFOLDER}/libs/nginx_helper.sh
source "${SFOLDER}/libs/nginx_helper.sh"
# shellcheck source=${SFOLDER}/libs/cloudflare_helper.sh
source "${SFOLDER}/libs/cloudflare_helper.sh"

################################################################################

netdata_required_packages() {

  local ubuntu_version

  ubuntu_version=$(get_ubuntu_version)

  if [ "${ubuntu_version}" = "1804" ]; then
    apt-get --yes install zlib1g-dev uuid-dev libuv1-dev liblz4-dev libjudy-dev libssl-dev libmnl-dev gcc make git autoconf autoconf-archive autogen automake pkg-config curl python python-mysqldb lm-sensors libmnl netcat nodejs python-ipaddress python-dnspython iproute2 python-beanstalkc libuv liblz4 Judy openssl -qq > /dev/null
  
  elif [ "${ubuntu_version}" = "2004" ]; then
    apt-get --yes install curl python3-mysqldb lm-sensors libmnl netcat openssl -qq > /dev/null

  fi

}

netdata_installer() {

  log_event "info" "Installing Netdata ..." "true"

  bash <(curl -Ss https://my-netdata.io/kickstart.sh) all --dont-wait

  killall netdata && cp system/netdata.service /etc/systemd/system/

  log_event "info" "Netdata Installed" "true"

}

netdata_configuration() {

  # Ref: netdata config dir https://github.com/netdata/netdata/issues/4182

  # MySQL
  create_netdata_db_user
  cat "${SFOLDER}/config/netdata/python.d/mysql.conf" > "/etc/netdata/python.d/mysql.conf"
  log_event "info" "MySQL config done!" "true"

  # monit
  cat "${SFOLDER}/config/netdata/python.d/monit.conf" >"/etc/netdata/python.d/monit.conf"
  log_event "info" "Monit config done!" "true"

  # web_log
  cat "${SFOLDER}/config/netdata/python.d/web_log.conf" >"/etc/netdata/python.d/web_log.conf"
  log_event "info" "Nginx Web Log config done!" "true"

  # health_alarm_notify
  cat "${SFOLDER}/config/netdata/health_alarm_notify.conf" >"/etc/netdata/health_alarm_notify.conf"
  log_event "info" "Health alarm config done!" "true"

  # telegram
  netdata_telegram_config

  systemctl daemon-reload && systemctl enable netdata && service netdata start

  log_event "info" "Netdata Configuration done!" "true"

}

netdata_alarm_level() {

  NETDATA_ALARM_LEVELS="warning critical"
  NETDATA_ALARM_LEVEL=$(whiptail --title "NETDATA ALARM LEVEL" --menu "Choose the Alarm Level for Notifications" 20 78 10 $(for x in ${NETDATA_ALARM_LEVELS}; do echo "$x [X]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    echo "NETDATA_ALARM_LEVEL=${NETDATA_ALARM_LEVEL}" >>/root/.broobe-utils-options
    log_event "info" "Alarm Level for Notifications: ${NETDATA_ALARM_LEVEL}" "true"

  else
    return 1

  fi

}

netdata_telegram_config() {

  HEALTH_ALARM_NOTIFY_CONF="/etc/netdata/health_alarm_notify.conf"

  DELIMITER="="

  KEY="SEND_TELEGRAM"
  SEND_TELEGRAM=$(cat "/etc/netdata/health_alarm_notify.conf" | grep "^${KEY}${DELIMITER}" | cut -f2- -d"$DELIMITER")

  KEY="TELEGRAM_BOT_TOKEN"
  TELEGRAM_BOT_TOKEN=$(cat "/etc/netdata/health_alarm_notify.conf" | grep "^${KEY}${DELIMITER}" | cut -f2- -d"$DELIMITER")

  KEY="DEFAULT_RECIPIENT_TELEGRAM"
  DEFAULT_RECIPIENT_TELEGRAM=$(cat "/etc/netdata/health_alarm_notify.conf" | grep "^${KEY}${DELIMITER}" | cut -f2- -d"$DELIMITER")

  NETDATA_CONFIG_1_STRING+="\n . \n"
  NETDATA_CONFIG_1_STRING+=" Configure Telegram Notifications? You will need:\n"
  NETDATA_CONFIG_1_STRING+=" 1) Get a bot token. Contact @BotFather (https://t.me/BotFather) and send the command /newbot.\n"
  NETDATA_CONFIG_1_STRING+=" Follow the instructions and paste the token to access the HTTP API:\n"

  TELEGRAM_BOT_TOKEN=$(whiptail --title "Netdata: Telegram Configuration" --inputbox "${NETDATA_CONFIG_1_STRING}" 15 60 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    SEND_TELEGRAM="YES"
    sed -i "s/^\(SEND_TELEGRAM\s*=\s*\).*\$/\1\"$SEND_TELEGRAM\"/" $HEALTH_ALARM_NOTIFY_CONF
    sed -i "s/^\(TELEGRAM_BOT_TOKEN\s*=\s*\).*\$/\1\"$TELEGRAM_BOT_TOKEN\"/" $HEALTH_ALARM_NOTIFY_CONF

    NETDATA_CONFIG_2_STRING+="\n . \n"
    NETDATA_CONFIG_2_STRING+=" 2) Contact the @myidbot (https://t.me/myidbot) bot and send the command /getid to get \n"
    NETDATA_CONFIG_2_STRING+=" your personal chat id or invite him into a group and issue the same command to get the group chat id.\n"
    NETDATA_CONFIG_2_STRING+=" 3) Paste the ID here:\n"

    DEFAULT_RECIPIENT_TELEGRAM=$(whiptail --title "Netdata: Telegram Configuration" --inputbox "${NETDATA_CONFIG_2_STRING}" 15 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then

      # choose the netdata alarm level
      netdata_alarm_level

      # making changes on health_alarm_notify.conf
      sed -i "s/^\(DEFAULT_RECIPIENT_TELEGRAM\s*=\s*\).*\$/\1\"$DEFAULT_RECIPIENT_TELEGRAM|$NETDATA_ALARM_LEVEL\"/" $HEALTH_ALARM_NOTIFY_CONF
      
      # Uncomment the clear_alarm_always='YES' parameter on health_alarm_notify.conf
      if grep -q '^#.*clear_alarm_always' $HEALTH_ALARM_NOTIFY_CONF; then 
        sed -i '/^#.*clear_alarm_always/ s/^#//' $HEALTH_ALARM_NOTIFY_CONF
      fi

    else
      return 1

    fi

  else
    return 1

  fi

}

# TODO: replace with mysql_helper function
create_netdata_db_user() {

  local SQL1 SQL2 SQL3

  # TODO: must check if user exists
  SQL1="CREATE USER 'netdata'@'localhost';"
  SQL2="GRANT USAGE on *.* to 'netdata'@'localhost';"
  SQL3="FLUSH PRIVILEGES;"

  log_event "info" "Creating netdata user in MySQL" "true"
  mysql -u root -p"${MPASS}" -e "${SQL1}${SQL2}${SQL3}"

}

################################################################################

### Checking if Netdata is installed
NETDATA="$(which netdata)"

if [ ! -x "${NETDATA}" ]; then

  if [[ -z "${netdata_subdomain}" ]]; then

    netdata_subdomain=$(whiptail --title "Netdata Installer" --inputbox "Please insert the subdomain you want to install Netdata. Ex: monitor.broobe.com" 10 60 3>&1 1>&2 2>&3)
    exitstatus=$?

    if [ $exitstatus = 0 ]; then
      echo "netdata_subdomain=${netdata_subdomain}" >>"/root/.broobe-utils-options"

    else
      return 1

    fi

  fi

  # Only for Cloudflare API
  suggested_root_domain=${netdata_subdomain#[[:alpha:]]*.}

  ask_mysql_root_psw

  while true; do

    echo -e ${YELLOW}"> Do you really want to install netdata?"${ENDCOLOR}
    read -p "Please type 'y' or 'n'" yn

    case $yn in
    [Yy]*)

      log_event "info" "Updating packages before installation ..." "true"

      apt-get --yes update -qq > /dev/null

      netdata_required_packages

      netdata_installer

      # Netdata nginx proxy configuration
      nginx_server_create "${netdata_subdomain}" "netdata" "single"

      netdata_configuration

      # Confirm ROOT_DOMAIN
      root_domain=$(cloudflare_ask_root_domain "${suggested_root_domain}")

      # Cloudflare API
      cloudflare_change_a_record "${root_domain}" "${netdata_subdomain}"

      DOMAIN=${netdata_subdomain}
      #CHOSEN_CB_OPTION="1"
      #export CHOSEN_CB_OPTION DOMAIN

      # HTTPS with Certbot
      certbot_certificate_install "${MAILA}" "${DOMAIN}"

      break
      ;;
    [Nn]*)
      log_event "warning" "Aborting netdata installer script ..." "true"
      break
      ;;
    *) echo " > Please answer yes or no." ;;
    esac
  done

else

  NETDATA_OPTIONS="01 UPDATE_NETDATA 02 CONFIGURE_NETDATA 03 UNINSTALL_NETDATA 04 SEND_ALARM_TEST"
  NETDATA_CHOSEN_OPTION=$(whiptail --title "Netdata Installer" --menu "Netdata is already installed." 20 78 10 $(for x in ${NETDATA_OPTIONS}; do echo "$x"; done) 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    if [[ ${NETDATA_CHOSEN_OPTION} == *"01"* ]]; then
      cd netdata && git pull && ./netdata-installer.sh --dont-wait
      netdata_configuration

    fi
    if [[ ${NETDATA_CHOSEN_OPTION} == *"02"* ]]; then
      netdata_required_packages
      netdata_configuration

    fi
    if [[ ${NETDATA_CHOSEN_OPTION} == *"03"* ]]; then

      while true; do
        echo -e ${YELLOW}"> Do you really want to uninstall netdata?"${ENDCOLOR}
        read -p "Please type 'y' or 'n'" yn
        case $yn in
        [Yy]*)

          log_event "warning" "Uninstalling Netdata ..." "true"

          # TODO: remove MySQL user
          
          rm "/etc/nginx/sites-enabled/monitor"
          rm "/etc/nginx/sites-available/monitor"

          rm -R "/etc/netdata"
          rm "/etc/systemd/system/netdata.service"
          rm "/usr/sbin/netdata"

          source "/usr/libexec/netdata-uninstaller.sh" --yes --dont-wait

          log_event "info" "Netdata removed ok!" "true"

          break
          ;;
        [Nn]*)
          log_event "warning" "Aborting netdata installer script ..." "true"

          break
          ;;
        *) echo " > Please answer yes or no." ;;
        esac
      done

    fi
    if [[ ${NETDATA_CHOSEN_OPTION} == *"04"* ]]; then
      /usr/libexec/netdata/plugins.d/alarm-notify.sh test

    fi

  fi

fi

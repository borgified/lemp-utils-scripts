#!/bin/bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0-rc03
################################################################################

### Checking some things
if [[ -z "${SFOLDER}" ]]; then
  echo -e ${B_RED}" > Error: The script can only be runned by runner.sh! Exiting ..."${ENDCOLOR}
  exit 0
fi

################################################################################

# shellcheck source=${SFOLDER}/libs/commons.sh
source "${SFOLDER}/libs/commons.sh"

################################################################################

php_installer() {

  local PHP_V=$1

  apt --yes install "php${PHP_V}-fpm" "php${PHP_V}-mysql" php-imagick "php${PHP_V}-xml" "php${PHP_V}-cli" "php${PHP_V}-curl" "php${PHP_V}-mbstring" "php${PHP_V}-gd" "php${PHP_V}-intl" "php${PHP_V}-zip" "php${PHP_V}-bz2" "php${PHP_V}-bcmath" "php${PHP_V}-soap" "php${PHP_V}-dev" php-pear

}

php_custom_installer() {
  
  add_ppa "ondrej/php"
  
  apt-get update

  php_select_version_to_install
}

php_select_version_to_install() {

  PHPV_TO_INSTALL=(
    "7.4" " " off
    "7.3" " " off
    "7.2" " " off
    "7.1" " " off
    "7.0" " " off
    "5.6" " " off
    "5.5" " " off
  )

  CHOOSEN_PHPV=$(whiptail --title "PHP Version Selection" --checklist "Select the versions of PHP you want to install:" 20 78 15 "${PHPV_TO_INSTALL[@]}" 3>&1 1>&2 2>&3)
  echo "Setting CHOSEN_PHPV=$CHOOSEN_PHPV"
  for phpv in $CHOOSEN_PHPV; do
    phpv=$(sed -e 's/^"//' -e 's/"$//' <<<$phpv) #needed to ommit double quotes

    php_installer "${phpv}"

  done

}

php_redis_installer() {
  apt install redis-server php-redis
  systemctl enable redis-server.service

  cp "${SFOLDER}/confs/redis/redis.conf" "/etc/redis/redis.conf"

  systemctl restart redis-server.service

}

mail_utils_installer() {
  pear install mail mail_mime net_smtp
}

php_purge_all_installations() {
  echo " > Removing All PHP versions installed ..." >>$LOG
  apt --yes purge php*

}

php_purge_installation() {
  echo " > Removing PHP ${PHP_V} ..." >>$LOG
  apt --yes purge "php${PHP_V}-fpm" "php${PHP_V}-mysql" php-xml "php${PHP_V}-xml" "php${PHP_V}-cli" "php${PHP_V}-curl" "php${PHP_V}-mbstring" "php${PHP_V}-gd" php-imagick "php${PHP_V}-intl" "php${PHP_V}-zip" "php${PHP_V}-bz2" php-bcmath "php${PHP_V}-soap" "php${PHP_V}-dev" php-pear

}

php_check_if_installed() {
  PHP="$(which php)"
  if [ ! -x "${PHP}" ]; then
    php_installed="false"
  fi

}

php_check_installed_version() {
  php --version | awk '{ print $5 }' | awk -F\, '{ print $1 }'

}

################################################################################

#php_installed="true"
#php_check_if_installed

#if [ ${php_installed} == "false" ]; then

PHP_INSTALLER_OPTIONS="01 PHP_DISTRO_STANDARD 02 PHP_CUSTOM"
CHOSEN_PHP_INSTALLER_OPTION=$(whiptail --title "PHP INSTALLER" --menu "Choose a PHP version to install" 20 78 10 $(for x in ${PHP_INSTALLER_OPTIONS}; do echo "$x"; done) 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then

  if [[ ${CHOSEN_PHP_INSTALLER_OPTION} == *"01"* ]]; then
    
    DISTRO_V=$(get_ubuntu_version)
    if [ ! "$DISTRO_V" -e "1804" ]; then
      PHP_V="7.2"  #Ubuntu 18.04 LTS Default
    else
      PHP_V="7.4"  #Ubuntu 20.04 LTS Default
    fi
    
    # Installing packages
    php_installer "${PHP_V}"
    mail_utils_installer

  fi
  if [[ ${CHOSEN_PHP_INSTALLER_OPTION} == *"02"* ]]; then
    # Installing packages
    php_custom_installer
    mail_utils_installer

  fi
fi
#fi

# TODO: need refactor, using php_optimizations.sh
echo -e ${CYAN}" > Moving php configuration file ..."${ENDCOLOR}
echo " > Moving php configuration file ..." >>$LOG
cat "${SFOLDER}/confs/php/php.ini" >"/etc/php/${PHP_V}/fpm/php.ini"

echo -e ${CYAN}" > Moving fpm configuration file ..."${ENDCOLOR}
echo " > Moving fpm configuration file ..." >>$LOG
cat "${SFOLDER}/confs/php/php-fpm.conf" >"/etc/php/${PHP_V}/fpm/php-fpm.conf"

# Replace string to match PHP version
sudo sed -i "s#PHP_V#${PHP_V}#" "/etc/php/${PHP_V}/fpm/php-fpm.conf"
sudo sed -i "s#PHP_V#${PHP_V}#" "/etc/php/${PHP_V}/fpm/php-fpm.conf"
sudo sed -i "s#PHP_V#${PHP_V}#" "/etc/php/${PHP_V}/fpm/php-fpm.conf"

# Run php_optimizations.sh
"${SFOLDER}/utils/php_optimizations.sh"

# TODO: if you install a new PHP version, maybe you want to reconfigure an specific nginx_server
# reconfigure_nginx_sites()
# fastcgi_pass unix:/var/run/php/php5.6-fpm.sock;
# fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;

#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
################################################################################
#
# TODO: check when add www.DOMAIN.com and then select other stage != prod

function project_manager_menu() {

  # Installation types
  installation_types="Laravel,PHP"

  project_type=$(whiptail --title "INSTALLATION TYPE" --menu "Choose an Installation Type" 20 78 10 $(for x in ${installation_types}; do echo "$x [X]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    project_install "${SITES}" "${project_type}"

  fi

  menu_main_options

}
#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
################################################################################

function wordpress_project_installer () {

  # $1 = ${project_path}
  # $2 = ${project_domain}
  # $3 = ${project_name}
  # $4 = ${project_state}
  # $5 = ${project_root_domain}   # Optional

  local project_path=$1
  local project_domain=$2
  local project_name=$3
  local project_state=$4
  local project_root_domain=$5

  local installation_types
  local installation_type

  # Installation types
  installation_types=(
    "01)" "CLEAN INSTALL" 
    "02)" "COPY FROM PROJECT"
    )
  installation_type=$(whiptail --title "INSTALLATION TYPE" --menu "Choose an Installation Type" 20 78 10 "${installation_types[@]}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then


    if [[ ${installation_type} == *"COPY"* ]]; then

      wordpress_project_copy "${project_path}" "${project_domain}" "${project_name}" "${project_state}" "${project_root_domain}"

    else # Clean Install

      wordpress_project_install "${project_path}" "${project_domain}" "${project_name}" "${project_state}" "${project_root_domain}"

    fi

  fi
   
}

function wordpress_project_install () {

  # $1 = ${project_path}
  # $2 = ${project_domain}
  # $3 = ${project_name}
  # $4 = ${project_state}
  # $5 = ${project_root_domain}   # Optional

  local project_path=$1
  local project_domain=$2
  local project_name=$3
  local project_state=$4
  local project_root_domain=$5

  log_subsection "WordPress Clean Install"

  if [[ "${project_root_domain}" = '' ]]; then
    
    possible_root_domain="$(get_root_domain "${project_domain}")"
    project_root_domain="$(ask_rootdomain_for_cloudflare_config "${possible_root_domain}")"

  fi

  if [ ! -d "${project_path}" ]; then
    # Download WP
    mkdir "${project_path}"
    change_ownership "www-data" "www-data" "${project_path}"
    
    # Logging
    #display --indent 6 --text "- Making a copy of the WordPress project" --result "DONE" --color GREEN

  else

    # Logging
    display --indent 6 --text "- Creating WordPress project" --result "FAIL" --color RED
    display --indent 8 --text "Destination folder '${project_path}' already exist"
    log_event "error" "Destination folder '${project_path}' already exist, aborting ..."

    # Return
    return 1

  fi

  wp_change_permissions "${project_path}"

  # Create database and user
  db_project_name=$(mysql_name_sanitize "${project_name}")
  database_name="${db_project_name}_${project_state}" 
  database_user="${db_project_name}_user"
  database_user_passw=$(openssl rand -hex 12)

  mysql_database_create "${database_name}"
  mysql_user_create "${database_user}" "${database_user_passw}"
  mysql_user_grant_privileges "${database_user}" "${database_name}"

  # Download WordPress
  wpcli_core_download "${project_path}"

  # Create wp-config.php
  wpcli_create_config "${project_path}" "${database_name}" "${database_user}" "${database_user_passw}" "es_ES"

  # Startup Script for WordPress installation
  wpcli_run_startup_script "${project_path}" "${project_domain}"

  # Set WP salts
  wpcli_set_salts "${project_path}"

  # TODO: ask for Cloudflare support and check if root_domain is configured on the cf account

  # If domain contains www, should work without www too
  common_subdomain='www'
  if [[ ${project_domain} == *"${common_subdomain}"* ]]; then

    # Cloudflare API to change DNS records
    cloudflare_change_a_record "${project_root_domain}" "${project_domain}"

    # Cloudflare API to change DNS records
    cloudflare_change_a_record "${project_root_domain}" "${project_root_domain}"

    # New site Nginx configuration
    nginx_server_create "${project_domain}" "wordpress" "root_domain" "${project_root_domain}"

    # HTTPS with Certbot
    project_domain=$(whiptail --title "CERTBOT MANAGER" --inputbox "Do you want to install a SSL Certificate on the domain?" 10 60 "${project_domain},${project_root_domain}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      certbot_certificate_install "${MAILA}" "${project_domain},${project_root_domain}"

    else

      log_event "info" "HTTPS support for ${project_domain} skipped"
      display --indent 6 --text "- HTTPS support for ${project_domain}" --result "SKIPPED" --color YELLOW

    fi  

  else

    # Cloudflare API to change DNS records
    cloudflare_change_a_record "${project_root_domain}" "${project_domain}"

    # New site Nginx configuration
    nginx_create_empty_nginx_conf "${project_path}"
    nginx_create_globals_config
    nginx_server_create "${project_domain}" "wordpress" "single" ""

    # HTTPS with Certbot
    cert_project_domain=$(whiptail --title "CERTBOT MANAGER" --inputbox "Do you want to install a SSL Certificate on the domain?" 10 60 "${project_domain}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then
      
      certbot_certificate_install "${MAILA}" "${cert_project_domain}"

    else

      log_event "info" "HTTPS support for ${project_domain} skipped" "false"
      display --indent 6 --text "- HTTPS support for ${project_domain}" --result "SKIPPED" --color YELLOW

    fi
    
  fi

  log_event "success" "WordPress installation for domain ${project_domain} finished" "false"
  display --indent 6 --text "- WordPress installation for domain ${project_domain}" --result "DONE" --color GREEN

  telegram_send_message "${VPSNAME}: WordPress installation for domain ${project_domain} finished"

}

function wordpress_project_copy () {

  # $1 = ${project_path}
  # $2 = ${project_domain}
  # $3 = ${project_name}
  # $4 = ${project_state}
  # $5 = ${project_root_domain}   # Optional

  local project_path=$1
  local project_domain=$2
  local project_name=$3
  local project_state=$4
  local project_root_domain=$5

  log_subsection "Copy From Project"

  startdir=${folder_to_install}
  menutitle="Site Selection Menu"
  directory_browser "${menutitle}" "${startdir}"
  copy_project_path=$filepath"/"$filename

  display --indent 6 --text "- Preparing to copy project" --result "DONE" --color GREEN
  display --indent 8 --text "Path: ${copy_project_path}"
  log_event "info" "Setting copy_project_path=${copy_project_path}"

  copy_project="$(basename "${copy_project_path}")"

  log_event "info" "Setting copy_project=${copy_project}"

  # TODO: ask if want to exclude directory

  if [ -d "${folder_to_install}/${project_domain}" ]; then
    # Make a copy of the existing project
    log_event "info" "Making a copy of ${copy_project} on ${project_dir} ..."

    #cd "${folder_to_install}"
    copy_project_files "${folder_to_install}/${copy_project}" "${project_dir}"

    # Logging
    display --indent 6 --text "- Making a copy of the WordPress project" --result "DONE" --color GREEN
    log_event "success" "WordPress files copied"

  else
    # Logging
    display --indent 6 --text "- Making a copy of the WordPress project" --result "FAIL" --color RED
    display --indent 8 --text "Destination folder '${folder_to_install}/${project_domain}' already exist, aborting ..."
    log_event "error" "Destination folder '${folder_to_install}/${project_domain}' already exist, aborting ..."

    # Return
    return 1

  fi

  wp_change_permissions "${project_dir}"

  # Create database and user
  db_project_name=$(mysql_name_sanitize "${project_name}")
  database_name="${db_project_name}_${project_state}" 
  database_user="${db_project_name}_user"
  database_user_passw=$(openssl rand -hex 12)

  log_event "info" "Creating database ${database_name}, and user ${database_user} with pass ${database_user_passw}"

  mysql_database_create "${database_name}"
  mysql_user_create "${database_user}" "${database_user_passw}"
  mysql_user_grant_privileges "${database_user}" "${database_name}"


  log_event "info" "Copying database ${database_name} ..."

  # Create dump file

  # We get the database name from the copied wp-config.php
  source_wpconfig="${folder_to_install}/${copy_project}"
  db_tocopy=$(cat ${source_wpconfig}/wp-config.php | grep DB_NAME | cut -d \' -f 4)
  bk_file="db-${db_tocopy}.sql"

  # Make a database Backup
  mysql_database_export "${db_tocopy}" "${TMP_DIR}/${bk_file}"
  mysql_database_export_result=$?
  if [[ ${mysql_database_export_result} -eq 0 ]]; then

    # Target database
    target_db="${project_name}_${project_state}"

    # Importing dump file
    mysql_database_import "${target_db}" "${TMP_DIR}/${bk_file}"

    # Generate WP tables PREFIX
    tables_prefix=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 3 | head -n 1)
    # Change WP tables PREFIX
    wpcli_change_tables_prefix "${project_dir}" "${tables_prefix}"

    # WP Search and Replace URL
    wp_ask_url_search_and_replace "${project_dir}"

  else
    # Logging
    display --indent 6 --text "- Exporting actual database" --result "FAIL" --color RED
    display --indent 8 --text "mysqldump message: $?"
    log_event "error" "mysqldump message: $?"

    return 1

  fi

  # Set WP salts
  wpcli_set_salts "${project_dir}"

  # TODO: ask for Cloudflare support and check if root_domain is configured on the cf account

  # If domain contains www, should work without www too
  common_subdomain='www'
  if [[ ${project_domain} == *"${common_subdomain}"* ]]; then

    # Cloudflare API to change DNS records
    cloudflare_change_a_record "${root_domain}" "${project_domain}"

    # Cloudflare API to change DNS records
    cloudflare_change_a_record "${root_domain}" "${root_domain}"

    # New site Nginx configuration
    nginx_server_create "${project_domain}" "wordpress" "root_domain" "${root_domain}"

    # HTTPS with Certbot
    project_domain=$(whiptail --title "CERTBOT MANAGER" --inputbox "Do you want to install a SSL Certificate on the domain?" 10 60 "${project_domain},${root_domain}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      certbot_certificate_install "${MAILA}" "${project_domain},${root_domain}"

    else

      log_event "info" "HTTPS support for ${project_domain} skipped"
      display --indent 6 --text "- HTTPS support for ${project_domain}" --result "SKIPPED" --color YELLOW

    fi  

  else

    # Cloudflare API to change DNS records
    cloudflare_change_a_record "${root_domain}" "${project_domain}"

    # New site Nginx configuration
    nginx_create_empty_nginx_conf "${SITES}/${project_domain}"
    nginx_create_globals_config
    nginx_server_create "${project_domain}" "wordpress" "single" ""

    # HTTPS with Certbot
    cert_project_domain=$(whiptail --title "CERTBOT MANAGER" --inputbox "Do you want to install a SSL Certificate on the domain?" 10 60 "${project_domain}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then
      
      certbot_certificate_install "${MAILA}" "${cert_project_domain}"

    else

      log_event "info" "HTTPS support for ${project_domain} skipped" "false"
      display --indent 6 --text "- HTTPS support for ${project_domain}" --result "SKIPPED" --color YELLOW

    fi
    
  fi

  log_event "success" "WordPress installation for domain ${project_domain} finished" "false"
  display --indent 6 --text "- WordPress installation for domain ${project_domain}" --result "DONE" --color GREEN

  telegram_send_message "${VPSNAME}: WordPress installation for domain ${project_domain} finished"

}

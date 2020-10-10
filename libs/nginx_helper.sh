#!/bin/bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.5
################################################################################

nginx_server_create() {

    # $1 = ${project_domain}
    # $2 = ${project_type} (default, wordpress, symphony, phpmyadmin, zabbix, netdata)
    # $3 = ${server_type} (single, root_domain, multi_domain, tool) optional
    # $4 = ${redirect_domains} (list of domains or subdomains that will be redirect to project_domain) optional

    local project_domain=$1
    local project_type=$2
    local server_type=$3
    local redirect_domains=$4

    local nginx_result debug

    # Create nginx config files for site
    log_event "info" "Creating nginx configuration file for domain: ${project_domain}"
    log_event "info" "Project Type: ${project_type}"
    log_event "info" "Server Type: ${server_type}"
    log_event "info" "List of domains or subdomains that will be redirect to project_domain: ${redirect_domains}" "false"

    if [ -f "${WSERVER}/sites-available/${project_domain}" ]; then
        mv "${WSERVER}/sites-available/${project_domain}" "${WSERVER}/sites-available/${project_domain}_backup"
        rm "${WSERVER}/sites-enabled/${project_domain}"
    fi

    case ${server_type} in

        single)
            cp "${SFOLDER}/config/nginx/sites-available/${project_type}_${server_type}" "${WSERVER}/sites-available/${project_domain}"
            ln -s "${WSERVER}/sites-available/${project_domain}" "${WSERVER}/sites-enabled/${project_domain}"

            # Search and replace domain.com string with correct project_domain
            sed -i "s/domain.com/${project_domain}/g" "${WSERVER}/sites-available/${project_domain}"
        ;;

        root_domain)
            cp "${SFOLDER}/config/nginx/sites-available/${project_type}_${server_type}" "${WSERVER}/sites-available/${project_domain}"
            ln -s "${WSERVER}/sites-available/${project_domain}" "${WSERVER}/sites-enabled/${project_domain}"

            # Search and replace root_domain.com string with correct redirect_domains (must be root_domain here)
            sed -i "s/root_domain.com/${redirect_domains}/g" "${WSERVER}/sites-available/${project_domain}"

            # Search and replace domain.com string with correct project_domain
            sed -i "s/domain.com/${project_domain}/g" "${WSERVER}/sites-available/${project_domain}"

        ;;

        multi_domain)
            log_event "info" "TODO" "false"

        ;;

        tool)
            cp "${SFOLDER}/config/nginx/sites-available/${project_type}" "${WSERVER}/sites-available/${project_type}"
            ln -s "${WSERVER}/sites-available/${project_type}" "${WSERVER}/sites-enabled/${project_type}"

        ;;
        *)
            log_event "error" "Nginx server type unknow!" "false"
            return 1
        ;;

    esac

    # TODO: ask wich version of php want to work with

    # TODO: in the future, maybe we want this only on PHP projects

    # TODO: it's fails with $server_type = "tool"

    if [ "${PHP_V}" != "" ]; then
        # Replace string to match PHP version
        sed -i "s#PHP_V#${PHP_V}#" "${WSERVER}/sites-available/${project_domain}"
    else

        log_event "critical" "PHP_V not defined! Is PHP installed?" "false"
        
    fi
    
    #Test the validity of the nginx configuration
    nginx_result=$(nginx -t 2>&1 | grep -w "test" | cut -d"." -f2 | cut -d" " -f4)

    if [[ "${nginx_result}" = "successful" ]];then
        
        # Reload webserver
        service nginx reload

        log_event "success" "nginx configuration created" "false"
        display --indent 2 --text "- Nginx server configuration" --result DONE --color GREEN

    else

        debug=$(nginx -t 2>&1)
        log_event "error" "nginx configuration fail: $debug" "false"
        display --indent 2 --text "- Nginx server configuration" --result FAIL --color RED

    fi

}

nginx_server_delete() {

    #$1 = ${filename}

    local filename=$1

    if [ "${filename}" != "" ]; then

        # TODO: check if file exists
        rm "/etc/nginx/sites-available/${filename}"
        rm "/etc/nginx/sites-enabled/${filename}"

        # Reload webserver
        service nginx reload

        log_event "info" "Nginx config files for ${filename} deleted!"
        display --indent 2 --text "- Deleting nginx files" --result "DONE" --color GREEN

    fi

}

nginx_server_change_status() {

    # File test operators
    # -d FILE - True if the FILE exists and is a directory.
    # -f FILE - True if the FILE exists and is a regular file (not a directory or device).
    # -h FILE - True if the FILE exists and is a symbolic link.

    #$1 = ${project_domain}
    #$2 = ${project_status} (online,offline)

    local project_domain=$1
    local project_status=$2

    local result debug

    case ${project_status} in

    online)
        log_event "info" "New project status: ${project_status}" "false"
        if [ -f "${WSERVER}/sites-available/${project_domain}" ]; then
            ln -s "${WSERVER}/sites-available/${project_domain}" "${WSERVER}/sites-enabled/${project_domain}"
            log_event "info" "Project config added to ${WSERVER}/sites-enabled/${project_domain}" "false"
        else
            log_event "error" "${WSERVER}/sites-available/${project_domain} does not exist" "false"
        fi
        ;;

      offline)
        log_event "info" "New project status: ${project_status}" "false"
        if [ -h "${WSERVER}/sites-enabled/${project_domain}" ]; then
            rm "${WSERVER}/sites-enabled/${project_domain}"
            log_event "info" "Project config deleted from ${WSERVER}/sites-enabled/${project_domain}" "false"
        else
            log_event "error" "${WSERVER}/sites-enabled/${project_domain} does not exist" "false"
        fi
        ;;

      *)
        log_event "info" "New project status: Unknown" "false"
        return 1
        ;;
    esac

    #Test the validity of the nginx configuration
    result=$(nginx -t 2>&1 | grep -w "test" | cut -d"." -f2 | cut -d" " -f4)

    if [ "${result}" = "successful" ];then
        
        # Reload webserver
        service nginx reload

        log_event "success" "Project configuration status changed to ${project_status} for ${project_domain}" "false"
        #clear_last_line
        display --indent 2 --text "- Changing Project configuration status" --result "DONE" --color GREEN
        display --indent 4 --text "Status changed to ${project_status} for ${project_domain}"

    else
        debug=$(nginx -t 2>&1)
        log_event "error" "Problem changing project status for ${project_domain}: ${debug}" "false"
        #clear_last_line
        display --indent 2 --text "- Changing Project configuration status" --result "FAIL" --color RED
        display --indent 4 --text "Nginx configuration fails. Result: ${result}"

    fi

}

nginx_server_change_phpv() {

    #$1 = ${project_domain}
    #$2 = ${new_php_v} optional

    local project_domain=$1
    local new_php_v=$2

    # TODO: if $new_php_v is not set, must ask wich PHP_V

    if [[ ${new_php_v} = "" ]]; then
        new_php_v=$(check_default_php_version)

    fi

    # Updating nginx server file
    log_event "info" "Chaning PHP version on nginx server file" "false"
    display --indent 2 --text "- Chaning PHP version on nginx server file"

    # TODO: ask wich version of php want to work with

    # Replace string to match PHP version
    current_php_v_string=$(cat ${WSERVER}/sites-available/${project_domain} | grep fastcgi_pass | cut -d '/' -f 4 | cut -d '-' -f 1)
    current_php_v=${current_php_v_string#"php"}
    
    sed -i "s#${current_php_v}#${new_php_v}#" "${WSERVER}/sites-available/${project_domain}"

    log_event "info" "PHP version for ${project_domain} changed from ${current_php_v} to ${new_php_v}" "false"

    clear_last_line
    display --indent 2 --text "- Changing PHP version on nginx server file" --result "DONE" --color GREEN
    display --indent 4 --text "PHP version changed to ${new_php_v}"

    #Test the validity of the nginx configuration
    result=$(nginx -t 2>&1 | grep -w "test" | cut -d"." -f2 | cut -d" " -f4)

    if [ "${result}" = "successful" ];then

        # Reload webserver
        service nginx reload

        log_event "success" "Nginx configuration changed!" "false"
        display --indent 2 --text "- Testing nginx configuration" --result "DONE" --color GREEN

    else
        debug=$(nginx -t 2>&1)
        whiptail_event "WARNING" "Something went wrong changing Nginx configuration. Please check manually nginx config files."
        log_event "error" "Problem changing Nginx configuration. Debug: ${debug}" "false"

        display --indent 2 --text "- Testing nginx configuration" --result "FAIL" --color RED

    fi

}

nginx_reconfigure() {

    # nginx.conf broobe standard configuration
    cat "${SFOLDER}/config/nginx/nginx.conf" >"/etc/nginx/nginx.conf"

    # Reload webserver
    service nginx reload

}

nginx_new_default_server() {
    
    # New default nginx configuration
    log_event "info" "Moving nginx configuration files ..." "false"
    cat "${SFOLDER}/config/nginx/sites-available/default" >"/etc/nginx/sites-available/default"
    display --indent 2 --text "- Creating default nginx server" --result "DONE" --color GREEN

}

nginx_delete_default_directory() {

    # Remove html default nginx folders
    nginx_default_dir="/var/www/html"
    if [ -d "${nginx_default_dir}" ]; then
        rm -r $nginx_default_dir
        log_event "info" "Directory ${nginx_default_dir} deleted" "false"
        display --indent 2 --text "- Removing nginx default directory" --result "DONE" --color GREEN
    fi

}

nginx_create_globals_config() {

    # nginx.conf broobe standard configuration
    nginx_globals="/etc/nginx/globals/"

    if [ -d "${nginx_globals}" ]; then
        log_event "warning" "Directory ${nginx_globals} already exists ..." "false"
        return 1

    else
        log_event "info" "Creating directory ${nginx_globals} exists ..." "false"
        mkdir "${nginx_globals}"

    fi

    cp "${SFOLDER}/config/nginx/globals/security.conf" "/etc/nginx/globals/security.conf"
    cp "${SFOLDER}/config/nginx/globals/wordpress_sec.conf" "/etc/nginx/globals/wordpress_sec.conf"
    cp "${SFOLDER}/config/nginx/globals/wordpress_seo.conf" "/etc/nginx/globals/wordpress_seo.conf"

    display --indent 2 --text "- Creating nginx globals config" --result "DONE" --color GREEN

    # Replace string to match PHP version
    sudo sed -i "s#PHP_V#${PHP_V}#" "/etc/nginx/globals/wordpress_sec.conf"

    # Change ownership
    change_ownership "www-data" "www-data" "/etc/nginx/globals/"

    #Test the validity of the nginx configuration
    result=$(nginx -t 2>&1 | grep -w "test" | cut -d"." -f2 | cut -d" " -f4)

    if [ "${result}" = "successful" ];then
        
        # Reload webserver
        service nginx reload

        log_event "success" "Nginx global configuration added"
        display --indent 2 --text "- Creating nginx globals config" --result "DONE" --color GREEN


    else
        debug=$(nginx -t 2>&1)
        whiptail_event "WARNING" "Something went wrong changing Nginx configuration. Please check manually nginx config files."
        log_event "error" "Problem changing Nginx configuration. Debug: ${debug}"
        display --indent 2 --text "- Creating nginx globals config" --result "FAIL" --color RED
        display --indent 4 --text "Debug: ${debug}" --tcolor RED


    fi

}

nginx_create_empty_nginx_conf() {

    #$1 = ${path}

    local path=$1
    
    if [[ ! -f ${path}/nginx.conf ]];then
        mkdir "${path}/nginx.conf"
        return 0
    else
        return 1
    fi

}
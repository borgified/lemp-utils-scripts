#!/bin/bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.11
#############################################################################

#
#############################################################################
#
# * Private functions
#
#############################################################################
#

function _settings_config_mysql() {

    ask_mysql_root_psw

}

function _settings_config_smtp() {

    if [[ -z "${SMTP_SERVER}" ]]; then
        SMTP_SERVER=$(whiptail --title "SMTP SERVER" --inputbox "Please insert the SMTP Server" 10 60 "${SMTP_SERVER_OLD}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
            echo "SMTP_SERVER="${SMTP_SERVER} >>/root/.broobe-utils-options
        else
            return 1
        fi
    fi
    if [[ -z "${SMTP_PORT}" ]]; then
        SMTP_PORT=$(whiptail --title "SMTP SERVER" --inputbox "Please insert the SMTP Server Port" 10 60 "${SMTP_PORT_OLD}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
            echo "SMTP_PORT=${SMTP_PORT}" >>/root/.broobe-utils-options
        else
            return 1
        fi
    fi
    # TODO: change to SMTP_TYPE (none, ssl, tls)
    if [[ -z "${SMTP_TLS}" ]]; then
        SMTP_TLS=$(whiptail --title "SMTP TLS" --inputbox "SMTP yes or no:" 10 60 "${SMTP_TLS_OLD}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
            echo "SMTP_TLS=${SMTP_TLS}" >>/root/.broobe-utils-options
        else
            return 1
        fi
    fi
    if [[ -z "${SMTP_U}" ]]; then
        SMTP_U=$(whiptail --title "SMTP User" --inputbox "Please insert the SMTP user" 10 60 "${SMTP_U_OLD}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
            echo "SMTP_U=${SMTP_U}" >>/root/.broobe-utils-options
        else
            return 1
        fi
    fi
    if [[ -z "${SMTP_P}" ]]; then
        SMTP_P=$(whiptail --title "SMTP Password" --inputbox "Please insert the SMTP user password" 10 60 "${SMTP_P_OLD}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
            echo "SMTP_P=${SMTP_P}" >>/root/.broobe-utils-options
        else
            return 1
        fi
    fi

} 

function _settings_config_duplicity(){

    # DUPLICITY CONFIG
    if [[ -z "${DUP_BK}" ]]; then

        DUP_BK_DEFAULT=false
        DUP_BK=$(whiptail --title "Duplicity Backup Support?" --inputbox "Please insert true or false" 10 60 "${DUP_BK_DEFAULT}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
        echo "DUP_BK=${DUP_BK}" >>/root/.broobe-utils-options

        if [[ "${DUP_BK}" = true ]]; then

            if [[ -z "${DUP_ROOT}" ]]; then

            # Duplicity Backups Directory
            DUP_ROOT_DEFAULT="/media/backups/PROJECT_NAME"
            DUP_ROOT=$(whiptail --title "Duplicity Backup Directory" --inputbox "Insert the directory path to storage duplicity Backup" 10 60 "${DUP_ROOT_DEFAULT}" 3>&1 1>&2 2>&3)
            exitstatus="$?"
            if [[ ${exitstatus} -eq 0 ]]; then
                echo "DUP_ROOT=${DUP_ROOT}" >>/root/.broobe-utils-options
            else
                exit 1
            fi
            fi

            if [[ -z "${DUP_SRC_BK}" ]]; then

            # Source of Directories to Backup
            DUP_SRC_BK_DEFAULT="${SITES}"
            DUP_SRC_BK=$(whiptail --title "Projects Root Directory" --inputbox "Insert the root directory of projects to backup" 10 60 "${DUP_SRC_BK_DEFAULT}" 3>&1 1>&2 2>&3)
            exitstatus="$?"
            if [[ ${exitstatus} -eq 0 ]]; then
                echo "DUP_SRC_BK=${DUP_SRC_BK}" >>/root/.broobe-utils-options
            else
                exit 1
            fi
            fi

            if [[ -z "${DUP_FOLDERS}" ]]; then

            # Folders to Backup
            DUP_FOLDERS_DEFAULT="FOLDER1,FOLDER2"
            DUP_FOLDERS=$(whiptail --title "Projects Root Directory" --inputbox "Insert the root directory of projects to backup" 10 60 "${DUP_FOLDERS_DEFAULT}" 3>&1 1>&2 2>&3)
            exitstatus="$?"
            if [[ ${exitstatus} -eq 0 ]]; then
                echo "DUP_FOLDERS=${DUP_FOLDERS}" >>/root/.broobe-utils-options
            else
                exit 1
            fi
            fi

            if [[ -z "${DUP_BK_FULL_FREQ}" ]]; then

            # Create a new full backup every ...
            DUP_BK_FULL_FREQ_DEFAULT="7D"
            DUP_BK_FULL_FREQ=$(whiptail --title "Projects Root Directory" --inputbox "Insert the root directory of projects to backup" 10 60 "${DUP_BK_FULL_FREQ_DEFAULT}" 3>&1 1>&2 2>&3)
            exitstatus="$?"
            if [[ ${exitstatus} -eq 0 ]]; then
                echo "DUP_BK_FULL_FREQ=${DUP_BK_FULL_FREQ}" >>/root/.broobe-utils-options
            else
                exit 1
            fi
            fi

            if [[ -z "${DUP_BK_FULL_LIFE}" ]]; then

            # Delete any backup older than this
            DUP_BK_FULL_LIFE_DEFAULT="14D"
            DUP_BK_FULL_LIFE=$(whiptail --title "Projects Root Directory" --inputbox "Insert the root directory of projects to backup" 10 60 "${DUP_BK_FULL_LIFE_DEFAULT}" 3>&1 1>&2 2>&3)
            exitstatus="$?"
            if [[ ${exitstatus} -eq 0 ]]; then
                echo "DUP_BK_FULL_LIFE=${DUP_BK_FULL_LIFE}" >>/root/.broobe-utils-options
            else
                exit 1
            fi
            fi

        else

            echo "DUP_ROOT=none" >>/root/.broobe-utils-options
            echo "DUP_SRC_BK=none" >>/root/.broobe-utils-options
            echo "DUP_FOLDERS=none" >>/root/.broobe-utils-options
            echo "DUP_BK_FULL_FREQ=none" >>/root/.broobe-utils-options
            echo "DUP_BK_FULL_LIFE=none" >>/root/.broobe-utils-options
            
        fi

        fi
    
    fi
}

function _settings_config_mailcow(){

    # TODO: MAKE TRUE OR FALSE
    if [[ -z "${MAILCOW_BK}" ]]; then

        MAILCOW_BK_DEFAULT=false
        
        MAILCOW_BK=$(whiptail --title "Mailcow Backup Support?" --inputbox "Please insert true or false" 10 60 "${MAILCOW_BK_DEFAULT}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
        echo "MAILCOW_BK=${MAILCOW_BK}" >>/root/.broobe-utils-options
        
        if [[ -z "${MAILCOW}" && "${MAILCOW_BK}" = true ]]; then

            # MailCow Dockerized default files location
            MAILCOW_DEFAULT="/opt/mailcow-dockerized"
            MAILCOW=$(whiptail --title "Mailcow Installation Path" --inputbox "Insert the path where Mailcow is installed" 10 60 "${MAILCOW_DEFAULT}" 3>&1 1>&2 2>&3)
            exitstatus="$?"
            if [[ ${exitstatus} -eq 0 ]]; then
            echo "MAILCOW=${MAILCOW}" >>/root/.broobe-utils-options
            else
            return 1

            fi

        fi

        else
        return 1
        
        fi

    fi
}

function _settings_config_cloudflare(){

    #TODO: cloudflare enable (true or false)

    if [[ -z "${CLOUDFLARE_ENABLE}" ]]; then
        generate_cloudflare_config
    fi

}

function _settings_config_telegram(){

    #TODO: telegram notifications enable (true or false)

    if [[ -z "${TELEGRAM_ENABLE}" ]]; then
        generate_telegram_config
    fi

}

function _settings_config_notifications(){

    #TODO: option to select notification types (mail, telegram)

    if [[ -z "${MAILA}" ]]; then
        MAILA=$(whiptail --title "Notification Email" --inputbox "Insert the email where you want to receive notifications." 10 60 "${MAILA_OLD}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
            echo "MAILA=${MAILA}" >>/root/.broobe-utils-options
        else
            return 1
        fi
    fi

}

#
#################################################################################
#
# * Public
#
#################################################################################
#

function script_configuration_wizard() {

    #$1 = ${config_mode} // options: initial or reconfigure

    local config_mode=$1

    if [[ ${config_mode} == "reconfigure" ]]; then

        #Old vars
        SMTP_SERVER_OLD=${SMTP_SERVER}
        SMTP_PORT_OLD=${SMTP_PORT}
        SMTP_TLS_OLD=${SMTP_TLS}
        SMTP_U_OLD=${SMTP_U}
        SMTP_P_OLD=${SMTP_P}
        MAILA_OLD=${MAILA}
        SITES_OLD=${SITES}

        #Reset config vars
        SMTP_SERVER=""
        SMTP_PORT=""
        SMTP_TLS=""
        SMTP_U=""
        SMTP_P=""
        MAILA=""
        SITES=""

        #Rename old config file
        mv /root/.broobe-utils-options /root/.broobe-utils-options_bk

        log_event "debug" "Script config file renamed: /root/.broobe-utils-options_bk"

    fi

    _settings_config_mysql

    if [[ -z "${SITES}" ]]; then
        SITES=$(whiptail --title "Websites Root Directory" --inputbox "Insert the path where websites are stored. Ex: /var/www or /usr/share/nginx" 10 60 "${SITES_OLD}" 3>&1 1>&2 2>&3)
        exitstatus="$?"
        if [[ ${exitstatus} -eq 0 ]]; then
            echo "SITES=${SITES}" >>/root/.broobe-utils-options
        else
            return 1
        fi
    fi

    _settings_config_cloudflare

    _settings_config_notifications

    _settings_config_smtp

    _settings_config_duplicity

    _settings_config_mailcow

}

function generate_dropbox_config() {

  local oauth_access_token_string 
  local oauth_access_token

  oauth_access_token_string+="\n Please, provide a Dropbox Access Token ID.\n"
  oauth_access_token_string+=" 1) Log in: dropbox.com/developers/apps/create\n"
  oauth_access_token_string+=" 2) Click on \"Create App\" and select \"Dropbox API\".\n"
  oauth_access_token_string+=" 3) Choose the type of access you need.\n"
  oauth_access_token_string+=" 4) Enter the \"App Name\".\n"
  oauth_access_token_string+=" 5) Click on the \"Create App\" button.\n"
  oauth_access_token_string+=" 6) Click on the Generate button.\n"
  oauth_access_token_string+=" 7) Copy and paste the new access token here:\n\n"

  oauth_access_token=$(whiptail --title "Dropbox Uploader Configuration" --inputbox "${oauth_access_token_string}" 15 60 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Write config file
    echo "OAUTH_ACCESS_TOKEN=$oauth_access_token" >${DPU_CONFIG_FILE}
    log_event "info" "Dropbox configuration has been saved!" "false"

  else
    return 1

  fi

}

function generate_cloudflare_config() {

  # ${CLF_CONFIG_FILE} is a Global var

  local cfl_email 
  local cfl_api_token
  local cfl_email_string
  local cfl_api_token_string

  cfl_email_string="\n\nPlease insert the Cloudflare email account here:\n\n"

  cfl_email=$(whiptail --title "Cloudflare Configuration" --inputbox "${cfl_email_string}" 15 60 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    echo "dns_cloudflare_email=${cfl_email}">"${CLF_CONFIG_FILE}"

    cfl_api_token_string+="\n Please insert the Cloudflare Global API Key.\n"
    cfl_api_token_string+=" 1) Log in on: cloudflare.com\n"
    cfl_api_token_string+=" 2) Login and go to \"My Profile\".\n"
    cfl_api_token_string+=" 3) Choose the type of access you need.\n"
    cfl_api_token_string+=" 4) Click on \"API TOKENS\" \n"
    cfl_api_token_string+=" 5) In \"Global API Key\" click on \"View\" button.\n"
    cfl_api_token_string+=" 6) Copy the code and paste it here:\n\n"

    cfl_api_token=$(whiptail --title "Cloudflare Configuration" --inputbox "${cfl_api_token_string}" 15 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      # Write config file
      echo "dns_cloudflare_api_key=${cfl_api_token}">>"${CLF_CONFIG_FILE}"
      log_event "success" "The Cloudflare configuration has been saved!"

    else
      return 1

    fi

  else
    return 1

  fi

}

function generate_telegram_config() {

    # ${TEL_CONFIG_FILE} is a Global var

    local botfather_whip_line
    local botfather_key

    botfather_whip_line+=" \n "
    botfather_whip_line+=" Open Telegram and follow the next steps:\n\n"
    botfather_whip_line+=" 1) Get a bot token. Contact @BotFather (https://t.me/BotFather) and send the command /newbot.\n"
    botfather_whip_line+=" 2) Follow the instructions and paste the token to access the HTTP API:\n\n"

    botfather_key=$(whiptail --title "Telegram BotFather Configuration" --inputbox "${botfather_whip_line}" 15 60 3>&1 1>&2 2>&3)
    exitstatus="$?"
    if [[ ${exitstatus} -eq 0 ]]; then

        # Write config file
        echo "botfather_key=${botfather_key}" >>"/root/.telegram.conf"

        telegram_id_whip_line+=" \n\n "
		telegram_id_whip_line+=" 3) Contact the @myidbot (https://t.me/myidbot) bot and send the command /getid to get \n"
		telegram_id_whip_line+=" your personal chat id or invite him into a group and issue the same command to get the group chat id.\n"
		telegram_id_whip_line+=" 4) Paste the ID here:\n\n"
		
		telegram_user_id=$(whiptail --title "Telegram: BotID Configuration" --inputbox "${telegram_id_whip_line}" 15 60 3>&1 1>&2 2>&3)
		exitstatus="$?"
		if [[ ${exitstatus} -eq 0 ]]; then

            # Write config file
            echo "telegram_user_id=${telegram_user_id}" >>"/root/.telegram.conf"
            log_event "success" "The Telegram configuration has been saved!"

            # shellcheck source=${SFOLDER}/libs/telegram_notification_helper.sh
            source "${SFOLDER}/libs/telegram_notification_helper.sh"

            telegram_send_message "✅ ${VPSNAME}: Telegram notifications configured!"

		else

			return 1

		fi

    else

        return 1

    fi

}
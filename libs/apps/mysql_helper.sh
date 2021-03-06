#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
#############################################################################

function mysql_test_user_credentials() {

    # $1 = ${db_user}
    # $2 = ${db_user_psw}

    local db_user=$1
    local db_user_psw=$2

    local mysql_output
    local mysql_result

    # Execute command
    mysql_output="$("${MYSQL}" -u "${db_user}" -p"${db_user_psw}" -e ";")"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then
        
        # Logging
        clear_last_line
        display --indent 6 --text "- Testing MySQL user credentials" --result "DONE" --color GREEN
        log_event "success" " Testing MySQL user credentials. User '${db_user}' and pass '${db_user_psw}'"

        return 0

    else

        # Logging
        clear_last_line
        display --indent 6 --text "- Testing MySQL user credentials" --result "FAIL" --color RED
        log_event "error" "Something went wrong testing MySQL user credentials. User '${db_user}' and pass '${db_user_psw}'"
        log_event "debug" "Last command executed: ${MYSQL} -u${db_user} -p${db_user_psw} -e ;"

        return 1

    fi

}

function mysql_count_dabases() {

    # $1 = ${databases}

    local databases=$1
    local total_databases=0

    local db

    for db in ${databases}; do
        if [[ $DB_BL != *"${db}"* ]]; then              # $DB_BL contains blacklisted databases
            total_databases=$((total_databases + 1))
        fi
    done

    # Return
    echo "${total_databases}"
}

function mysql_list_databases() {

    local databases

    # Run command
    databases="$(${MYSQL_ROOT} -Bse 'show databases')"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then
        
        # Logging
        display --indent 6 --text "- Listing MySQL databases" --result "DONE" --color GREEN
        log_event "success" " Listing MySQL databases '${databases}'"

        # Return
        echo "${databases}"

    else

        # Logging
        display --indent 6 --text "- Listing MySQL databases" --result "FAIL" --color RED
        log_event "error" "Something went wrong listing MySQL databases"
        log_event "debug" "Last command executed: ${MYSQL_ROOT} -Bse 'show databases'"

        return 1

    fi

}

function mysql_user_create() {

    # $1 = ${db_user}
    # $2 = ${db_user_psw}
    # $3 = ${db_user_scope} // optional

    local db_user=$1
    local db_user_psw=$2
    local db_user_scope=$3

    local query

    # Logging
    display --indent 2 --text "- Creating MySQL user ${db_user}"
    log_event "info" "Creating MySQL user ..."

    # Define user scope
    if [[ -z ${db_user_scope} || ${db_user_scope} == "" ]]; then
        db_user_scope='localhost'
    fi

    # Query
    if [[ -z ${db_user_psw} || ${db_user_psw} == "" ]]; then
        query="CREATE USER '${db_user}'@'${db_user_scope}';"

    else
        query="CREATE USER '${db_user}'@'${db_user_scope}' IDENTIFIED BY '${db_user_psw}';"

    fi

    # Execute command
    ${MYSQL_ROOT} -e "${query}"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then
        
        # Logging
        clear_last_line
        display --indent 6 --text "- Creating MySQL user ${db_user}" --result "DONE" --color GREEN
        display --indent 8 --text "User created with pass: ${db_user_psw}" --tcolor YELLOW
        log_event "success" " MySQL user ${db_user} created with pass: ${db_user_psw}"

        return 0

    else

        # Logging
        clear_last_line
        display --indent 6 --text "- Creating MySQL user ${db_user}" --result "FAIL" --color RED
        display --indent 8 --text "MySQL output: ${mysql_output}" --tcolor RED
        display --indent 8 --text "Query executed: ${query}" --tcolor RED
        log_event "error" "Something went wrong creating user: ${db_user}."
        log_event "debug" "MySQL output: ${mysql_output}"
        log_event "debug" "Last command executed: ${MYSQL_ROOT} -e ${query}"

        return 1

    fi

}

function mysql_user_delete() {

    # $1 = ${db_user}
    # $2 = ${db_user_scope}

    local db_user=$1
    local db_user_scope=$2

    local query_1
    local query_2

    # Logging
    display --indent 6 --text "- Deleting user ${db_user}"
    log_event "info" "Deleting ${db_user} user in MySQL ..."

    # Define user scope
    if [[ -z ${db_user_scope} || ${db_user_scope} == "" ]]; then
        db_user_scope='localhost'
    fi

    # Query
    query_1="DROP USER '${db_user}'@'${db_user_scope}';"
    query_2="FLUSH PRIVILEGES;"

    # Execute command
    ${MYSQL_ROOT} -e "${query_1}${query_2}"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then

        # Logging
        clear_last_line
        display --indent 6 --text "- Deleting user ${db_user}" --result "DONE" --color GREEN
        log_event "success" " Database user ${db_user} deleted"

        return 0

    else

        # Logging
        clear_last_line
        display --indent 6 --text "- Deleting ${db_user} user in MySQL" --result "FAIL" --color RED
        log_event "error" "Something went wrong deleting user: ${db_user}."
        log_event "debug" "Last command executed: ${MYSQL_ROOT} -e \"${query_1}${query_2}\""

        return 1

    fi

}

function mysql_user_psw_change() {

    # $1 = ${db_user}
    # $2 = ${db_user_psw}

    local db_user=$1
    local db_user_psw=$2

    local query_1 
    local query_2

    log_event "info" "Changing password for user ${db_user} in MySQL"

    # Query
    query_1="ALTER USER '${db_user}'@'localhost' IDENTIFIED BY '${db_user_psw}';"
    query_2="FLUSH PRIVILEGES;"

    # Execute command
    ${MYSQL_ROOT} -e "${query_1}${query_2}"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then

        # Logging
        display --indent 6 --text "- Changing password to user ${db_user}" --result "DONE" --color GREEN
        display --indent 8 --text "New password: ${db_user_psw}" --result "DONE" --color GREEN  
        log_event "success" "New password for user ${db_user}: ${db_user_psw}"

        return 0

    else

        # Logging
        display --indent 6 --text "- Changing password to user ${db_user}" --result "FAIL" --color RED   
        log_event "error" "Something went wrong changing password to user ${db_user}."
        log_event "debug" "Last command executed: ${MYSQL_ROOT} -e \"${query_1}${query_2}\""

        return 1

    fi

}

function mysql_root_psw_change() {

    # $1 = ${db_root_psw}

    local db_root_psw=$1

    log_event "info" "Changing password for root in MySQL"

    # Kill any mysql processes currently running
	service mysql stop
	killall -vw mysqld
    display --indent 2 --text "- Shutting down any mysql processes" --result "DONE" --color GREEN
	
	# Start mysql without grant tables
	mysqld_safe --skip-grant-tables >res 2>&1 &
	
	# Sleep for 5 while the new mysql process loads (if get a connection error you might need to increase this.)
	sleep 5
	
	# Creating new password if db_root_psw is empty
    if [ "${db_root_psw}" = "" ];then
        db_root_psw_len=$(shuf -i 20-30 -n 1)
        db_root_psw=$(pwgen -scn "${db_root_psw_len}" 1)
        db_root_user='root'
    fi
	
	# Update root user with new password
	mysql mysql -e "USE mysql;UPDATE user SET Password=PASSWORD('${db_root_psw}') WHERE User='${db_root_user}';FLUSH PRIVILEGES;"
	
	# Kill the insecure mysql process
	killall -v mysqld
	
	# Starting mysql again
	service mysql restart
	
    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then

        # Logging
        display --indent 6 --text "- Setting new password for root" --result "DONE" --color GREEN
        display --indent 8 --text "New password: ${db_root_psw}"
        log_event "success" "New password for root: ${db_root_psw}"

        return 0

    else

        # Logging
        display --indent 6 --text "- Setting new password for root" --result "FAIL" --color RED
        log_event "error" "Something went wrong changing MySQL root password."
        log_event "debug" "Last command executed: mysql mysql -e \"USE mysql;UPDATE user SET Password=PASSWORD('${db_root_psw}') WHERE User='${db_root_user}';FLUSH PRIVILEGES;\""

        return 1

    fi

}

function mysql_user_grant_privileges() {

    # $1 = ${db_user}
    # $2 = ${db_target}
    # $3 = ${db_scope}

    local db_user=$1
    local db_target=$2
    local db_scope=$3

    local query_1 
    local query_2 

    local mysql_output
    local mysql_result

    # TODO: only if empty
    db_scope='localhost'

    log_event "info" "Granting privileges to ${db_user} on ${db_target} database in MySQL"

    # Query
    query_1="GRANT ALL PRIVILEGES ON ${db_target}.* TO '${db_user}'@'${db_scope}';"
    query_2="FLUSH PRIVILEGES;"

    # Execute command
    ${MYSQL_ROOT} -e "${query_1}${query_2}"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then

        # Logging
        log_event "success" "Privileges granted to user ${db_user}"
        display --indent 6 --text "- Granting privileges to ${db_user}" --result "DONE" --color GREEN

        return 0

    else

        # Logging
        display --indent 6 --text "- Granting privileges to ${db_user}" --result "FAIL" --color RED
        log_event "error" "Something went wrong granting privileges to user ${db_user}."
        log_event "debug" "Last command executed: ${MYSQL_ROOT} -e \"${query_1}${query_2}\""

        return 1

    fi

}

function mysql_user_exists() {

    # $1 = ${DB_USER}

    local db_user=$1

    local query
    local user_exists

    query="SELECT COUNT(*) FROM mysql.user WHERE user = '${db_user}';"

    user_exists="$(${MYSQL_ROOT} -e "${query}" | grep 1)"
    
    log_event "debug" "Last command executed: ${MYSQL_ROOT} -e ${query} | grep 1"

    if [[ ${user_exists} == "" ]]; then
        # Return 0 if user don't exists
        return 0
    else
        # Return 1 if user already exists
        return 1
    fi

}

function mysql_database_exists() {

    # $1 = ${DB}

    local database=$1

    local result

    # Run command
    result=$(${MYSQL_ROOT} -e "SHOW DATABASES LIKE '${database}';")

    if [[ -z "${result}" || "${result}" = "" ]]; then
        # Return 1 if database don't exists
        return 1
        
    else
        # Return 0 if database exists
        return 0
    fi

}

function mysql_name_sanitize() {

    # $1 = ${name} database_name or user_name

    local string=$1

    local clean

    #log_event "debug" "Running mysql_name_sanitize for ${string}" "true"

    # First, strip "-"
    clean=${string//-/}

    # Next, replace "." with "_"
    clean=${clean//./_}

    # Now, clean out anything that's not alphanumeric or an underscore
    clean=${clean//[^a-zA-Z0-9_]/}

    # Finally, lowercase with TR
    clean=$(echo -n "${clean}" | tr A-Z a-z)

    #log_event "debug" "Sanitized name: ${clean}" "true"

    # Return
    echo "${clean}"

}

function mysql_database_create() {

    # $1 = ${database}

    local database=$1

    local query_1

    local mysql_output
    local mysql_result

    log_event "info" "Creating ${database} database in MySQL ..."

    # Query
    query_1="CREATE DATABASE IF NOT EXISTS ${database};"

    # Execute command
    ${MYSQL_ROOT} -e "${query_1}"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then

        # Logging
        display --indent 6 --text "- Creating database: ${database}" --result "DONE" --color GREEN
        log_event "success" "Database ${database} created"

        return 0

    else

        # Logging
        display --indent 6 --text "- Creating database: ${database}" --result "ERROR" --color RED
        log_event "error" "Something went wrong creating database: ${database}."
        log_event "debug" "Last command executed: ${MYSQL_ROOT} -e \"${query_1}\""

        return 1

    fi

}

function mysql_database_drop() {

    # $1 = ${DB}

    local database=$1

    local query_1
    local mysql_result

    log_event "info" "Droping the database: ${database}"

    # Query
    query_1="DROP DATABASE ${database};"
    
    # Execute command
    ${MYSQL_ROOT} -e "${query_1}"

    # Check result
    mysql_result=$?
    if [[ ${mysql_result} -eq 0 ]]; then

        # Logging
        log_event "success" "- Database ${database} deleted successfully"
        display --indent 6 --text "- Droping database: ${database}" --result "DONE" --color GREEN

        return 0

    else

        # Logging
        display --indent 6 --text "- Droping database: ${database}" --result "ERROR" --color RED
        display --indent 8 --text "MySQL import output: ${mysql_output}" --tcolor RED
        display --indent 8 --text "Query executed: ${query_1}" --tcolor RED
        log_event "error" "Something went wrong deleting database: ${database}."
        log_event "debug" "Last command executed: ${MYSQL_ROOT} -e \"${query_1}\""

        return 1
        
    fi

}

function mysql_database_import() {

    # $1 = ${database} (.sql)
    # $2 = ${dump_file}

    local database=$1
    local dump_file=$2

    local import_status

    # Logging
    display --indent 6 --text "- Importing backup into database: ${database}" --tcolor YELLOW
    log_event "info" "Importing dump file ${dump_file} into database: ${database}"
    log_event "debug" "Running: pv ${dump_file} | ${MYSQL_ROOT} -f -D ${database}"

    # Execute command
    pv "${dump_file}" | ${MYSQL_ROOT} -f -D "${database}"

    # Check result
    import_status=$?
    if [[ ${import_status} -eq 0 ]]; then

        # Logging
        clear_last_line
        display --indent 6 --text "- Database backup import" --result "DONE" --color GREEN
        log_event "success" "Database ${database} imported successfully"

        return 0

    else
        
        # Logging
        clear_last_line
        display --indent 6 --text "- Database backup import" --result "ERROR" --color RED
        log_event "error" "Something went wrong importing database: ${database}"
        log_event "debug" "Last command executed: pv ${dump_file} | ${MYSQL_ROOT} -f -D ${database}"

        return 1

    fi

}

function mysql_database_export() {

    # $1 = ${database}
    # $2 = ${dump_file}

    local database=$1
    local dump_file=$2

    local dump_output
    local dump_status

    log_event "info" "Making a database backup of: ${database}"

    spinner_start "- Making a backup of: ${database}"

    # Run mysqldump
    ${MYSQLDUMP_ROOT} "${database}" > "${dump_file}"

    dump_status=$?
    spinner_stop "${dump_status}"

    # Check dump result
    if [[ ${dump_status} -eq 0 ]]; then

        # Logging
        display --indent 6 --text "- Database backup for ${database}" --result "DONE" --color GREEN
        log_event "success" "Database ${database} exported successfully"

        return 0
    
    else

        # Logging
        display --indent 6 --text "- Database backup for ${database}" --result "ERROR" --color RED
        log_event "error" "Something went wrong exporting database: ${database}."
        log_event "error" "Last command executed: ${MYSQLDUMP_ROOT} ${database} > ${dump_file}"

        return 1

    fi

}
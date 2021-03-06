#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
#############################################################################

function test_cloudflare_funtions() {

    test_cloudflare_domain_exists
    test_cloudflare_change_a_record
    test_cloudflare_delete_a_record
    test_cloudflare_clear_cache

}

function test_cloudflare_domain_exists() {

    log_subsection "Test: test_cloudflare_domain_exists"

    cloudflare_domain_exists "pacientesenred.com.ar"
    cf_result=$?
    if [[ ${cf_result} -eq 0 ]]; then 
        display --indent 6 --text "- cloudflare_domain_exists" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- cloudflare_domain_exists" --result "FAIL" --color RED
    fi
    log_break "true"

    cloudflare_domain_exists "www.pacientesenred.com.ar"
    cf_result=$?
    if [[ ${cf_result} -eq 1 ]]; then 
        display --indent 6 --text "- cloudflare_domain_exists" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- cloudflare_domain_exists" --result "FAIL" --color RED
    fi
    log_break "true"

    cloudflare_domain_exists "machupichu.com"
    cf_result=$?
    if [[ ${cf_result} -eq 1 ]]; then 
        display --indent 6 --text "- cloudflare_domain_exists" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- cloudflare_domain_exists" --result "FAIL" --color RED
    fi

}

function test_cloudflare_change_a_record() {

    log_subsection "Test: test_cloudflare_change_a_record"

    cloudflare_change_a_record "broobe.hosting" "bash.broobe.hosting" "false"
    cf_result=$?
    if [[ ${cf_result} -eq 0 ]]; then 
        display --indent 6 --text "- test_cloudflare_change_a_record" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- test_cloudflare_change_a_record" --result "FAIL" --color RED
    fi

}

function test_cloudflare_delete_a_record() {

    log_subsection "Test: test_cloudflare_delete_a_record"

    cloudflare_delete_a_record "broobe.hosting" "bash.broobe.hosting" "false"
    cf_result=$?
    if [[ ${cf_result} -eq 0 ]]; then 
        display --indent 6 --text "- test_cloudflare_delete_a_record" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- test_cloudflare_delete_a_record" --result "FAIL" --color RED
    fi

}

function test_cloudflare_clear_cache() {

    log_subsection "Test: test_cloudflare_clear_cache"

    cloudflare_clear_cache "broobe.hosting"
    cf_result=$?
    if [[ ${cf_result} -eq 0 ]]; then 
        display --indent 6 --text "- test_cloudflare_clear_cache" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- test_cloudflare_clear_cache" --result "FAIL" --color RED
    fi

}
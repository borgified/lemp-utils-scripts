#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.17
#############################################################################

function test_display_functions() {

    log_subsection "Testing display 1"

    display --indent 6 --text "- Testing message DONE" --result "DONE" --color WHITE
    display --indent 6 --text "- Testing message WARNING" --result "WARNING" --color YELLOW
    display --indent 6 --text "- Testing message ERROR" --result "ERROR" --color RED
    display --indent 8 --text "Testing output ERROR" --tcolor RED

    log_subsection "Testing display 2"

    display --indent 6 --text "- Testing message with color" --result "DONE" --color WHITE
    display --indent 8 --text "Testing output DONE" --tcolor WHITE --tstyle CURSIVE
    display --indent 6 --text "- Testing message with color" --result "DONE" --color WHITE
    display --indent 8 --text "Testing output WHITE in ITALIC" --tcolor WHITE --tstyle ITALIC
    display --indent 6 --text "- Testing message with color" --result "WARNING" --color YELLOW
    display --indent 8 --text "Testing output WARNING" --tcolor YELLOW

    log_subsection "Testing display with spinner"

    spinner_start "Testing spinner for 3 seconds"
    sleep 3
    spinner_stop $?
    display --indent 6 --text "- Testing spinner" --result "DONE" --color WHITE

}
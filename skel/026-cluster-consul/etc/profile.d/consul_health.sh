#!/bin/bash

# shellcheck disable=SC2120
function _show_consul_health() {
    ## only run if this is an interactive shell and  we've logged in via ssh;
    ## don't re-run for each su
    ## https://www.gnu.org/software/bash/manual/html_node/Is-this-Shell-Interactive_003f.html
    ## allow forcing the output
    if [ "${1:-}" != "force" ]; then
        if [ -z "$PS1" ] || ! ps -o cmd= $PPID | egrep -q "^sshd: ${USER}" ; then
            return
        fi
    fi
    
    local COLOR_YELLOW_BOLD="\033[1;33m"
    local COLOR_RED_BOLD="\033[1;31m"
    local COLOR_NORMAL="\033[0m"
    
    ## who are we, according to consul?
    local self
    self=$( curl -sf localhost:8500/v1/agent/self | jq -r .Member.Name )
    
    ## be graceful if consul's not running
    if [ -z "${self}" ]; then
        if [ "${1:-}" = "force" ]; then
            echo -e "${COLOR_RED_BOLD}unable to determine consul member name${COLOR_NORMAL}"
        fi
    else
        local node_health
        local warning_svcs
        local critical_svcs

        node_health=$( curl -sfS "localhost:8500/v1/health/node/${self}" )
        
        ## oh hai array!
        warning_svcs=( $( echo "${node_health}" | jq -r '.[] | select(.Status == "warning") | .CheckID' ) )
        critical_svcs=( $( echo "${node_health}" | jq -r '.[] | select(.Status == "critical") | .CheckID' ) )

        if [ ${#warning_svcs[@]} -gt 0 ]; then
            echo -e "${COLOR_YELLOW_BOLD}${#warning_svcs[@]} service$([ ${#warning_svcs[@]} -gt 1 ] && echo "s") with state 'warning':"

            ## Output is a double-quoted string with embedded newlines; we only want
            ## the first line
            local i=0
            while read -r output; do
                echo -e "${warning_svcs[$i]}\t${output}"
                i=$(( i + 1 ))
            done < <( echo "${node_health}" | jq '.[] | select(.Status == "warning") | .Output' | sed -r -e 's#(^"|"$)##g' -e 's#\\n.*##g' )  | column -c2 -t -s $'\t'

            echo -en "${COLOR_NORMAL}"
        fi

        if [ ${#critical_svcs[@]} -gt 0 ]; then
            echo -e "${COLOR_RED_BOLD}${#critical_svcs[@]} service$([ ${#critical_svcs[@]} -gt 1 ] && echo "s") with state 'critical':"

            local i=0
            while read -r output; do
                echo -e "${critical_svcs[$i]}\t${output}"
                i=$(( i + 1 ))
            done < <( echo "${node_health}" | jq '.[] | select(.Status == "critical") | .Output' | sed -r -e 's#(^"|"$)##g' -e 's#\\n.*##g' )  | column -c2 -t -s $'\t'

            echo -en "${COLOR_NORMAL}"
        fi
    fi
}

# shellcheck disable=SC2119
_show_consul_health

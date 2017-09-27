#!/bin/bash
#
# Script to make a proxy (ie HAProxy) capable of monitoring MySQL Cluster nodes properly
#
# Author: Olaf van Zandwijk <olaf.vanzandwijk@nedap.com>
# Author: Raghavendra Prabhu <raghavendra.prabhu@percona.com>
# Author: Petr Michalec <pmichalec@mirantis.com>
#
# Documentation and download: https://github.com/epcim/percona-clustercheck
#
# Based on the original script from Unai Rodriguez
#

function httpReply(){
    HTTP_STATUS="${1}"
    RESPONSE_CONTENT="${2}"

    # https://serverfault.com/questions/504756/curl-failure-when-receiving-data-from-peer-using-percona-xtradb-cluster-check
    sleep 0.1
    if [[ "${HTTP_STATUS}" == "503" ]]
    then
        echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    elif [[ "${HTTP_STATUS}" == "404" ]]
    then
        echo -en "HTTP/1.1 404 Not Found\r\n"
    elif [[ "${HTTP_STATUS}" == "401" ]]
    then
        echo -en "HTTP/1.1 401 Unauthorized\r\n"
    elif [[ "${HTTP_STATUS}" == "200" ]]
    then
        echo -en "HTTP/1.1 200 OK\r\n"
    else
        echo -en "HTTP/1.1 ${HTTP_STATUS}\r\n"
    fi

    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: ${#RESPONSE_CONTENT}\r\n"
    echo -en "\r\n"
    echo -en "${RESPONSE_CONTENT}"
    echo -en "\r\n"
    sleep 0.1
}

if [[ $1 == '-h' || $1 == '--help' ]];then
    echo "Usage: $0 <user> <pass> <available_when_donor=0|1> <log_file> <available_when_readonly=0|1> <defaults_extra_file> <timeout>"
    exit
fi

# if the disabled file is present, return 503. This allows
# admins to manually remove a node from a cluster easily.
if [ -e "/var/tmp/clustercheck.disabled" ]; then
    # Shell return-code is 1
    httpReply "503" "MySQL Cluster Node is manually disabled.\r\n"
    exit 1
fi

MYSQL_USERNAME="${1-clustercheckuser}"
MYSQL_PASSWORD="${2-clustercheckpassword!}"
AVAILABLE_WHEN_DONOR=${3:-0}
ERR_FILE="${4:-/dev/null}"
AVAILABLE_WHEN_READONLY=${5:-1}
DEFAULTS_EXTRA_FILE=${6:-/etc/my.cnf}
# Timeout exists for instances where mysqld may be hung
# Default value	considers the Galera timeouts
TIMEOUT=${7:-18}

EXTRA_ARGS=""
if [[ -n "$MYSQL_USERNAME" ]]; then
    EXTRA_ARGS="$EXTRA_ARGS --user=${MYSQL_USERNAME}"
fi
if [[ -n "$MYSQL_PASSWORD" ]]; then
    EXTRA_ARGS="$EXTRA_ARGS --password=${MYSQL_PASSWORD}"
fi
if [[ -r $DEFAULTS_EXTRA_FILE ]];then
    MYSQL_CMDLINE="mysql --defaults-extra-file=$DEFAULTS_EXTRA_FILE -nNE --connect-timeout=$TIMEOUT \
                    ${EXTRA_ARGS}"
else
    MYSQL_CMDLINE="mysql -nNE --connect-timeout=$TIMEOUT ${EXTRA_ARGS}"
fi
#
# Perform the query to check the wsrep_local_state
#
WSREP_STATUS=$($MYSQL_CMDLINE -e "SHOW STATUS LIKE 'wsrep_local_state';" \
    2>${ERR_FILE} | tail -1 2>>${ERR_FILE}; exit ${PIPESTATUS[0]})
mysql_ret=$?

if [[ $mysql_ret -eq 1 || $mysql_ret -eq 127 ]]; then
    # hash or command can be used here, but command is POSIX
    command -v "$MYSQL_CMD"; mysql_ret=$?
    if [[ $mysql_ret -eq 1 ]]; then
        # mysql program not found
        # => return HTTP 404
        # Shell return-code is 3
        httpReply "404" "Mysql command not found or service is not running.\r\n"
        exit 2
    fi

        # Failed mysql login
        # => return HTTP 401
        # Shell return-code is 2
        httpReply "401" "Access denied to database.\r\n"
        exit 2
fi



if [[ "${WSREP_STATUS}" == "4" ]] || [[ "${WSREP_STATUS}" == "2" && ${AVAILABLE_WHEN_DONOR} == 1 ]]
then
    # Check only when set to 0 to avoid latency in response.
    if [[ $AVAILABLE_WHEN_READONLY -eq 0 ]];then
        READ_ONLY=$($MYSQL_CMDLINE -e "SHOW GLOBAL VARIABLES LIKE 'read_only';" \
                    2>${ERR_FILE} | tail -1 2>>${ERR_FILE})

        if [[ "${READ_ONLY}" == "ON" ]];then
            # MySQL Cluster node local state is 'Synced', but it is in
            # read-only mode. The variable AVAILABLE_WHEN_READONLY is set to 0.
            # => return HTTP 503
            # Shell return-code is 1
            httpReply "503" "MySQL Cluster Node is read-only.\r\n"
            exit 1
        fi
    fi
    # MySQL Cluster node local state is 'Synced' => return HTTP 200
    # Shell return-code is 0
    httpReply "200" "MySQL Cluster Node is synced.\r\n"
    exit 0
else
    # MySQL Cluster node local state is not 'Synced' => return HTTP 503
    # Shell return-code is 1
    if [[ -z "${WSREP_STATUS}" ]]
    then
        httpReply "503" "Received empty reply from MySQL Cluster Node.\r\nMight be a permission issue, check the credentials used by ${0}\r\n"
    else
        httpReply "503" "MySQL Cluster Node is not synced.\r\n"
    fi
    exit 1
fi

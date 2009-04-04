#!/bin/sh

JMXUSER='jmsclient'
JMXPASS='jmsclient'
JMXPORT='1099'

JMXCLIENT_VERSION='0.10.3'
JMXCLIENT=${0%.sh}-cmdline-jmxclient-${JMXCLIENT_VERSION}.jar
JAVA=/usr/local/bin/java
GREP=/bin/grep

printHelp () {
    echo "USAGE: ${0##*/} [connection options] [query options]"
    echo
    echo "Connection options:"
    echo "  -H <hostname>"
    echo "  -j <jmx_hostname>   defaults to <hostname> if not supplied"
    echo "  -p <port>           default $JMXPORT"
    echo "  -U <username>       default $JMXUSER"
    echo "  -P <password>       default $JMXPASS"
    echo
    echo "Query options:"
    echo "  -w warning          warning level"
    echo "  -c critical         critical level"
    echo "  -q query            available query types:"
    echo "	                    size    check number of pending messages for each queue"
    echo "	                    mem     check for memory percent used"
    echo "	                    temp    check for temp percent used"
    echo "	                    store   check for store percent used"
    echo
    exit 0
}

queueSize () {
    QUEUES=`$CMD_TMPL | $GREP Type=Queue`
    EXITCODE=0
    for q in $QUEUES; do
        CURRQUEUE=${q%%,Type=Queue}; CURRQUEUE=${CURRQUEUE#*,Destination=}
        QUEUESIZE=`$CMD_TMPL $q QueueSize 2>&1`; QUEUESIZE=${QUEUESIZE##*QueueSize: }
        if [ $QUEUESIZE -ge $WARNLVL ]; then
            if [ $QUEUESIZE -ge $CRITLVL ]; then
                STATUS="$STATUS $CURRQUEUE ($QUEUESIZE/crit:$CRITLVL)"
                EXITCODE=2
            else
                STATUS="$STATUS $CURRQUEUE ($QUEUESIZE/warn:$WARNLVL)"
                if [ $EXITCODE -lt 1 ]; then
                    EXITCODE=1
                fi
            fi
        fi
    done
    if [ $EXITCODE -eq 0 ]; then
        echo "OK All queues are fine"
        exit 0
    else
        if [ $EXITCODE -eq 1 ]; then
            SHORT="WARNING"
        elif [ $EXITCODE -eq 2 ]; then
            SHORT="CRITICAL"
        fi
        echo "$SHORT QueueSize:$STATUS"
        exit $EXITCODE
    fi
}

checkUsed () {
    MBEAN="org.apache.activemq:BrokerName=${JMXNAME},Type=Broker"
    LIMIT=`$CMD_TMPL $MBEAN ${1}Limit 2>&1`; LIMIT=${LIMIT##*${1}Limit: }
    USED=`$CMD_TMPL $MBEAN ${1}PercentUsage 2>&1`; USED=${USED##*${1}PercentUsage: }
    if [ $USED -ge $WARNLVL ]; then
        if [ $USED -ge $CRITLVL ]; then
            echo "CRITICAL $1 usage ${USED}%/crit:$CRITLVL (${1}Limit: $LIMIT)"
            exit 2
        else
            echo "WARNING $1 usage ${USED}%/warn:$WARNLVL (${1}Limit: $LIMIT)"
            exit 1
        fi
    else
        echo "OK $1 usage ${USED}% (${1}Limit: $LIMIT)"
        exit 0
    fi
}

while getopts "H:U:P:p:w:c:q:j:" optionName; do
    case "$optionName" in
        U) JMXUSER="$OPTARG";;
        P) JMXPASS="$OPTARG";;
        H) JMXHOST="$OPTARG";;
        p) JMXPORT="$OPTARG";;
        w) WARNLVL="$OPTARG";;
        c) CRITLVL="$OPTARG";;
        q) QUERY="$OPTARG";;
        j) JMXNAME="$OPTARG";;
        *) printHelp;;
    esac
done

[[ -z "$JMXHOST" ]] && printHelp
[[ -z "$QUERY" ]] && printHelp
[[ -z "$WARNLVL" ]] && printHelp
[[ -z "$CRITLVL" ]] && printHelp
[[ -z "$JMXNAME" ]] && JMXNAME=$JMXHOST

CMD_TMPL="$JAVA -jar $JMXCLIENT $JMXUSER:$JMXPASS $JMXHOST:$JMXPORT"
WORKING=`$CMD_TMPL 2>&1 | $GREP -c -e activemq -e Type=Broker`
if [ "$WORKING" -eq 0 ]; then
    echo "UNKNOWN Cannot get information for broker $JMXHOST"
    exit 3
elif [ "$WORKING" -eq 1 ]; then
    echo "OK Broker $JMXHOST is working as a slave"
    exit 0
else
    case "$QUERY" in
        size) queueSize;;
        mem) checkUsed "Memory";;
        temp) checkUsed "Temp";;
        store) checkUsed "Store";;
        *) printHelp;;
    esac
fi


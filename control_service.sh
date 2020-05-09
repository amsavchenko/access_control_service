#!/bin/bash

CONF=./conf
IFS=":"

function trace {
    systemd-cat echo $1
}

function validateOwner {
    currentFileOwner=$( stat $FILE_NAME -c %U )
    if [[ $currentFileOwner != $VALID_OWNER ]]
    then
        trace "ACCESS_CONTROL_SERVICE: WARNING! $FILE_NAME HAD GOT NOT A VALID OWNER ($currentFileOwner). CHANGED TO $VALID_OWNER" 
        chown $VALID_OWNER $FILE_NAME
    fi
}

function validateGroup {
    currentFileGroup=$( stat $FILE_NAME -c %G )
    if [[ $currentFileGroup != $VALID_GROUP ]]
    then
        trace "ACCESS_CONTROL_SERVICE: WARNING! $FILE_NAME HAD GOT NOT A VALID GROUP ($currentFileGroup). CHANGED TO $VALID_GROUP" 
        chgrp $VALID_GROUP $FILE_NAME
    fi
}

function validatePermissions {
    currentFilePermissions=$( stat $FILE_NAME -c %a )
    if [[ $currentFilePermissions != $VALID_PERM ]]
    then
        trace "ACCESS_CONTROL_SERVICE: WARNING! $FILE_NAME HAD GOT NOT A VALID PERMISSIONS ($currentFilePermissions). CHANGED TO $VALID_PERM"
        chmod $VALID_PERM $FILE_NAME
    fi
}

function service {
    trace "ACCESS_CONTROL_SERVICE: begin scan"
    while read FILE_NAME VALID_PERM VALID_OWNER VALID_GROUP
    do
        validateOwner $FILE_NAME $VALID_OWNER
        validateGroup $FILE_NAME $VALID_GROUP
        validatePermissions $FILE_NAME $VALID_PERM
    done < $CONF
    trace "ACCESS_CONTROL_SERVICE: complete scan"
}

function onSignal {
    trace "SIGUSR1"
    service
}

function onExit {
    trace "exit"
}

trap "OnSignal" SIGUSR1
trap "OnExit" EXIT

while true
do
    trace "SERVICE START"
    wait && service
    sleep 1 &
done

#!/bin/bash
# alma2sap.sh -- Service runner for Alma/SAP conversion
# Written 2016 by Michael Slone.
# This file is in the public domain.
#
# Suitable for cron.  No arguments required.
#
# Sample config:
#  30 20 * * * bash /path/to/alma2sap.sh
#
set -e
set -u

group=alma

if [ $(id -gn) != "$group" ]; then
    exec sg "$group" "$0 $*"
fi

if [[ -e ~/.alma2sap.conf ]]; then
    source ~/.alma2sap.conf
elif [[ -e /etc/alma2sap.conf ]]; then
    source /etc/alma2sap.conf
else
    echo "no configuration found"
    exit 1
fi

ROOT="$ALMA2SAP_ROOT"
cd "$ROOT"

# All services can keep their own logs, but they are encouraged to write to the
# common log directory.
LOGDIR="$ROOT/log"
TS_LONG=$(date +"%Y-%m-%d %H:%M:%S")
TS_SHORT=$(echo "$TS_LONG" | perl -pe 's/[-\:]//g; s/\ /_/g')
BASELOG="$LOGDIR/$(date +"$TS_SHORT.alma2sap.txt")"
REPORT="$LOGDIR/$(date +"$TS_SHORT.report.txt")"
SUBJECT="Alma/SAP error report for $TS_LONG"

# Handy for timestamping logs
function timestamp {
    now=$(date +"%Y-%m-%d %H:%M:%S %z")
}

function log() {
    message=$1
    timestamp
    echo "alma2sap [$now]: $message" >> "$BASELOG"
}

log "started alma2sap in \"$ROOT\""

# Convention:
#
# A service has multiple associated directories.  (Not all services
# require all directories.)  The directories can be symlinks, but
# they are formally subdirectories of the main service directory.  If
# the directories exist, they MUST be distinct.
#
#  * inbox:   Clients should submit new work here.
#
#  * todo:    The main working directory for the service.  The service's
#             first task is to transfer all work from inbox to todo.  This
#             allows clients to continue to submit work to inbox without
#             interrupting the service.
#
#  * success: Work items which have been successfully completed should be
#             deposited here.
#
#  * failure: Work items which have not been successfully completed should
#             be deposited here.
#
#  * outbox:  If the service needs to send data to another service, it can
#             temporarily store that data here.  It's still the responsibility
#             of the service actually to deliver that data.  The service can
#             organize the contents of this directory however desired.
#
#  * service: Code for the service should live here.  In particular, there must
#             be a Bash script called run.sh that calls whatever other programs
#             need to be run.
#
# For example, if the main service directory for Reader is "/usr/share/reader",
# then the success directory is "/usr/share/reader/success".

Reader_DIR="$ROOT/reader"
Submitter_DIR="$ROOT/submitter"
SAP_DIR="$ROOT/sap"
SAP_DATA_DIR="$ROOT/submitter/destination"

# First, run the Reader service.
log "running Reader service"
log "bash \"$Reader_DIR/service/run.sh\" --root \"$Reader_DIR\" --destination \"$Submitter_DIR\" --log \"$BASELOG\" --report \"$REPORT\""
bash "$Reader_DIR/service/run.sh" --root "$Reader_DIR" --destination "$Submitter_DIR" --log "$BASELOG" --report "$REPORT"
log "finished Reader service"

# Next, run the Submitter service.
log "starting Submitter service"
log "bash \"$Submitter_DIR/service/run.sh\" --root \"$Submitter_DIR\" --destination \"$SAP_DATA_DIR\" --log \"$BASELOG\" --report \"$REPORT\""
bash "$Submitter_DIR/service/run.sh" --root "$Submitter_DIR" --destination "$SAP_DATA_DIR" --log "$BASELOG" --report "$REPORT"
log "finished Submitter service"

# Finally, mail the results.
echo "Attempting to send report with subject $SUBJECT: $REPORT"
perl mail.pl "$SUBJECT" "$REPORT"

log "finished"

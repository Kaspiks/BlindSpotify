#!/usr/bin/env bash
# GlitchTip heartbeat - POST to the endpoint so GlitchTip can monitor uptime.
# Run via cron every minute: * * * * * /opt/beatdrop/deploy/heartbeat.sh

HEARTBEAT_URL="${GLITCHTIP_HEARTBEAT_URL:-https://errors.blindjam.com/api/0/organizations/beatdrop/heartbeat_check/babac704-9405-477f-bd7c-1fd2a73d7a21/}"

curl -sf -X POST -o /dev/null "${HEARTBEAT_URL}" || true

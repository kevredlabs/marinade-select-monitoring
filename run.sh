#!/usr/bin/env bash
# Runs check.sh forever on a fixed interval (default: every 4 hours).
set -u

INTERVAL="${CHECK_INTERVAL_SECONDS:-14400}"

while true; do
  check.sh
  sleep "$INTERVAL"
done

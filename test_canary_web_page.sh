#!/usr/bin/env bash
set -o errexit -o pipefail # Exit on error
HTML_FILE=web/index.html

if [ -z "$1" ]; then
  echo "ERROR: input timestamp is needed for comparision!"
  exit 1
fi

YEAR=`date -d @${1} -u +%Y`
MONTH=`date -d @${1} -u +%m`
DAY=`date -d @${1} -u +%d`
TIME=`date -d @${1} -u +"%k:%M:%S UTC"`
SECONDS=`date -d @${1} -u +%s`

exit_code=0

if ! grep '<div id="year_div">' $HTML_FILE | grep "$YEAR" > /dev/null 2>&1; then
  echo "ERROR: year did not match!"
  exit_code=$((exit_code + 2))
fi

if ! grep '<div id="month_div">' $HTML_FILE | grep "$MONTH" > /dev/null 2>&1; then
  echo "ERROR: month did not match!"
  exit_code=$((exit_code + 4))
fi

if ! grep '<div id="day_div">' $HTML_FILE | grep "$DAY" > /dev/null 2>&1; then
  echo "ERROR: day did not match!"
  exit_code=$((exit_code + 8))
fi

if ! grep '<div id="time_div">' $HTML_FILE | grep "$TIME" > /dev/null 2>&1; then
  echo "ERROR: time did not match!"
  exit_code=$((exit_code + 16))
fi

if ! grep '<div id="seconds_div">' $HTML_FILE | grep "$SECONDS" > /dev/null 2>&1; then
  echo "ERROR: seconds did not match!"
  exit_code=$((exit_code + 32))
fi

exit $exit_code

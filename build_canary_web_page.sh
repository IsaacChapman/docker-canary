#!/usr/bin/env bash
set -e # Exit on error

# If an argument was passed, assume it was a timestamp to be used
if [ ! -z "$1" ]; then
  DATESTRING="-d @${1}"
fi

YEAR=`date $DATESTRING -u +%Y`
MONTH=`date $DATESTRING -u +%m`
DAY=`date $DATESTRING -u +%d`
TIME=`date $DATESTRING -u +"%k:%M:%S UTC"`
SECONDS=`date $DATESTRING -u +%s`

cat > web/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Status Canary</title>
  <style>
    body {background-color: 000000; margin: 0px;}
    #canary {display: block; width:100%;}
    #text_div {position: absolute; right: 20px; top: 20px;}
    #text_div div {color: #FFFFFF; font-weight: bold; font-size: x-large;}
  </style>
</head>
<body>
<img id="canary" title="canary" src="https://s3.amazonaws.com/isaacchapman/nature-branch-bird-wildlife-beak-yellow-700939-pxhere.com.jpg" />
<div id="text_div">
  <div id="year_div">${YEAR}</div>
  <div id="month_div">${MONTH}</div>
  <div id="day_div">${DAY}</div>
  <div id="time_div">${TIME}</div>
  <div id="seconds_div">${SECONDS}</div>
  <div id="divider" />
EOF

if [ -f $ARTIFACT_DIR/repo_info.html.txt ]; then
  echo '<div id="repo_info">' >> web/index.html
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "${line}<br />" >> web/index.html
  done < $ARTIFACT_DIR/repo_info.html.txt
  echo '</div>' >> web/index.html
fi

if [ -f $ARTIFACT_DIR/previous_sessions.html.txt ]; then
  echo '<div id="prev_sess_info">' >> web/index.html
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "${line}<br />" >> web/index.html
  done < $ARTIFACT_DIR/previous_sessions.html.txt 
  echo '</div>' >> web/index.html
fi

if [ -f $ARTIFACT_DIR/errors.txt ]; then
  echo '<div id="errors">' >> web/index.html
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "${line}<br />" >> web/index.html
  done < $ARTIFACT_DIR/errors.txt
  echo '</div>' >> web/index.html
fi

cat >> web/index.html <<EOF
  <div id="build_info_html">${BUILD_INFO_HTML}</div>
  <div id="previous_sessions_html">${EXTRA_HTML}</div>
  <div id="error_html">${ERROR_HTML}</div>
</div>
</body>
</html>
EOF



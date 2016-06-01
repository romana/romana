#!/bin/sh
body=`echo $1 | cut -d'=' -f2`
echo Posting $body to http://{{ romana_master_ip }}:9630/
echo curl -H 'content-type: application/json' -d @- -X POST http://localhost:9630/
echo $body | curl -H 'content-type: application/json' -d @- -X POST http://localhost:9630/





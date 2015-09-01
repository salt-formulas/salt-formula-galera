{%- from "galera/map.jinja" import slave with context -%}
#!/bin/bash

service {{ slave.service }} start

counter=70

while [ $counter -gt 0 ]
do
  service {{ slave.service }} status
  if [[ $? -eq 0 ]]; then
    exit 0
  fi
  counter=$(( $counter - 1 ))
  sleep 2
done

exit 1

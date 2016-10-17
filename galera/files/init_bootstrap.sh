#!/bin/bash

service {{ service.service }} start

counter=60

while [ $counter -gt 0 ]
do
  mysql -u root -e"quit"
  if [[ $? -eq 0 ]]; then
    exit 0
  fi
  counter=$(( $counter - 1 ))
  sleep 2
done

exit 1

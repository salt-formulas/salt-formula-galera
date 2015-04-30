#!/bin/bash

service mysql start

counter=20

while [ $counter -gt 0 ]
do
  service mysql status
  if [[ $? -eq 0 ]]; then
    exit 0
  fi
  counter=$(( $counter - 1 )) 
  sleep 2
done

exit 1
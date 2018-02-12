#!/bin/bash

service {{ service.service }} start

counter=${1:-120}
retries=0

while [ $counter -gt 0 ]
do
  if mysql -u {{ service.admin.user }} -p{{ service.admin.password }} -e"quit"; then
    echo "Sucessfully connected to the MySQL service ($retries retries)."
    exit 0
  fi
  counter=$(( counter - 1 ))
  retries=$(( retries + 1 ))
  sleep ${2:-4}
done

echo "Failed to connect to the MySQL service after $retries retries."
exit 1

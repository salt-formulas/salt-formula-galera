galera:
  engine: mariadb
  master:
    enabled: true
    name: galeracluster
    bind:
      address: 127.0.0.1
      port: 3306
    maintenance_password: password
    admin:
      user: root
      password: password
    members:
    - host: 127.0.0.1
      port: 4567
  clustercheck:
    enabled: False
mysql:
  server:
    enabled: true
    bind:
      address: 0.0.0.0
      port: 3306
      protocol: tcp
    database:
      mydb:
        encoding: 'utf8'
    users:
    - name: haproxy
      host: localhost
    - name: haproxy
      host: '%'
    - name: haproxy
      host: 127.0.0.1
    - name: clustercheck
      #host: localhost
      password: password
      database: '*.*'
      grants: PROCESS
    - name: inspector
      host: 127.0.0.1
      password: password
      databases:
        - database: mydb
          table: mytable
          grant_option: True
          grants:
          - all privileges

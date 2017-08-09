  galera:
    master:
      enabled: true
      name: galeracluster
      bind:
        address: 127.0.0.1
        port: 3306
      maintenance_password: password
      admin:
        user: user
        password: password
      members:
      - host: 127.0.0.1
        port: 4567
      - host: 127.0.0.1
        port: 4567
      - host: 127.0.0.1
        port: 4567
      max_connections: 20000
      innodb_buffer_pool_size: 3138M
  mysql:
    server:
      users:
      - name: haproxy
        host: localhost
      - name: haproxy
        host: '%'
      - name: haproxy
        host: 127.0.0.1

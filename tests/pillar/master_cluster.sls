linux:
  system:
    file:
      ca:
        name: /etc/mysql/ssl/ca.pem
        makedirs: true
        mode: 644
        contents: |
          -----BEGIN CERTIFICATE-----
          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
          M8IfJ5I=
          -----END CERTIFICATE-----
      cert:
        name: /etc/mysql/ssl/cert.pem
        makedirs: true
        mode: 644
        contents: |
          -----BEGIN CERTIFICATE-----
          MIIGHzCCBAegAwIBAgIIF4FaUAd0kCQwDQYJKoZIhvcNAQELBQAwSjELMAkGA1UE
          BhMCY3oxFzAVBgNVBAMMDlNhbHQgTWFzdGVyIENBMQ8wDQYDVQQHDAZQcmFndWUx
          ETAPBgNVBAoMCE1pcmFudGlzMB4XDTE4MDQxOTEzNDEwMVoXDTE5MDQxOTEzNDEw
          MVowSDELMAkGA1UEBhMCY3oxFTATBgNVBAMMDG15c3FsX3NlcnZlcjEPMA0GA1UE
          BwwGUHJhZ3VlMREwDwYDVQQKDAhNaXJhbnRpczCCAiIwDQYJKoZIhvcNAQEBBQAD
          ggIPADCCAgoCggIBAL4QIC/jDtaUb/KHSYLaUuWkW4n5qjiZ65FdMzbDs2nGsUqZ
          f7l3YSacUCRhQ2PF+qFDONGq4OhUQ41koFz1FJ7zwiCuJSkP48NvHVA+esr0Tyzv
          3tJx3xAN56yZ8z6mbsZ/b92ZkxYImePxU8Gqjx/lV6I6EfWdpKzAXuDd/UplPCZb
          DhbdamMkF1t20+j8QPD3S/kVG6N40HuAVC+pqKAaYWBk1odn2HnrEG5evXfp0mJw
          4oSxo4JCk/X0JNrDWVNe7ZlPOzW0+9Ro5tHd12rFOyKS+j4tlUxMT+HbYnvaLXV8
          ufvT0rLj+q0YZPShJWTikmYqsfSL/MbDNeA7jiJtZFmnZE/4jwJZjqiTl8PHk6MH
          6IWisW2m2WuRWsgygaT5ZsmPsa1Ykjt3Rmyquxuqj0fYLiGmz3jD2Mb3sDOi98T7
          JvbluMfpbti3bFYTf5sb2+wplejtjXsM8ohOBaIwrl+oY9Mct9jCuC5IaxCuNDu4
          1sJgqXer3J0n6kmdL9IX7jFvUs7Zqzv8oz6Zybh+VATUHwrnCuw6RPtesDquO2M9
          t0EbUMMajdwzMmtICmfCIfPKnlfzPiS+t3yiptw41OfVfrnPotgzO0DBDGfrQkIs
          1hOELFjrD27cewBDI5OHwpou5eK5T8Cxdaqh5hLeFpMvqLltwjP7GIuqBwapAgMB
          AAGjggEJMIIBBTAJBgNVHRMEAjAAMAsGA1UdDwQEAwIF4DAdBgNVHQ4EFgQUb+93
          8vEI9GmijvajmbGft9586HEwegYDVR0jBHMwcYAU14D8Rv+G8ORGjSAw72S4aN8H
          hK+hTqRMMEoxCzAJBgNVBAYTAmN6MRcwFQYDVQQDDA5TYWx0IE1hc3RlciBDQTEP
          MA0GA1UEBwwGUHJhZ3VlMREwDwYDVQQKDAhNaXJhbnRpc4IJAOkTQnjLz6rEMFAG
          A1UdEQRJMEeHBMCoAjOHBMCoAjKCDDE5Mi4xNjguMi41MYIMMTkyLjE2OC4yLjUw
          ggVkYnMwMYIWZGJzMDEubXVsdGlub2RlLWhhLmludDANBgkqhkiG9w0BAQsFAAOC
          AgEAOhjwhORG3AhgUvB5NgjnzsGdbg8B+P6B8UZsquLgjaMUwQfZHHYqfi9qHH8P
          zTE4Wx9aah8MD1Jskpo70LyID3A/8EaN98HlQeD9NtTdtddulGOSPDhGOWeMBMjj
          j5ehXAwlbifPBsB0M5+laTlqS1mIyPioUDKAiLcusFpAVz4tJpkfG/+AywZI5Nj7
          2bkxm0Hvq5nKoHZ/fiaBQ9RQhoNBYmFszprstMkRG394XO6G17Oq1BVUKN/7e4za
          AKZpVCTSl+lDm80Gt8j8VebW6tsAEzIisLgkKmqARO+AXZ6Atwl8sQUUNsy63A7i
          6BfrJb3tdZgXXgrdVU0DJfeq59xF57MYwca3IEhAxphnPavQN8JuouHMuiVsGc1M
          FB5xyMrW1XPQYtH8yu5SLcU+0ps+dfr+NWepLXEU8URluX17hTFZIVWyq1TZs7oj
          Pq3lPyAmMTc04zIyB3AUwYneKOVT2kEccaoM9a/TQR71Q8mdg//AbXLjTmUhAUSZ
          wuQAf7yml+TcAbmzwvzCW/T8QYhH/Cgwc2wTu0MJprX32/VuOw4wgDqe3GbwNSmM
          1jTj6g93pHADOo+kMoMUw4ADRIemW8Tq3ZsaQw3dt3UlUNu+82+vmBI3HW0V/NNA
          yuDE4X96Dopl4utK3QoJaBdiZ5uXui2UgJuVO/hkcx54T4E=
          -----END CERTIFICATE-----
      key:
        name: /etc/mysql/ssl/key.pem
        makedirs: true
        mode: 644
        contents: |
          -----BEGIN RSA PRIVATE KEY-----
          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
          -----END RSA PRIVATE KEY-----
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
    - host: 127.0.0.1
      port: 4567
    - host: 127.0.0.1
      port: 4567
    ssl:
      enabled: True
      key_file: /etc/mysql/ssl/key.pem
      cert_file: /etc/mysql/ssl/cert.pem
      ca_file: /etc/mysql/ssl/ca.pem
      ciphers:
        DHE-RSA-AES128-SHA:
          enabled: True
        DHE-RSA-AES256-SHA:
          name: DHE-RSA-AES256-SHA
          enabled: True
        EDH-RSA-DES-CBC3-SHA:
          name: EDH-RSA-DES-CBC3-SHA
          enabled: True
        AES128-SHA:AES256-SHA:
          enabled: True
        DES-CBC3-SHA:
          enabled: True
  clustercheck:
    enabled: True
    user: clustercheck
    password: password
    available_when_donor: 1
    available_when_readonly: 1
    port: 9200
    max_connections: 20000
    innodb_buffer_pool_size: 3138M
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

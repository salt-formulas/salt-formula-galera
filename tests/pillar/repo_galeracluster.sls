linux:
  system:
    enabled: true
    repo:
      galeracluster:
        key_id: BC19DDBA
        key_server: hkp://p80.pool.sks-keyservers.net:80
        pin:
        - pin: 'release o=Galera Cluster'
          priority: 1001
          package: '*'
      mysql-wsrep:
        key_id: BC19DDBA
        key_server: hkp://p80.pool.sks-keyservers.net:80
        pin:
        - pin: 'release o=Galera Cluster'
          priority: 1001
          package: '*'
      mitaka-staging_PPA:
        source: "deb http://ppa.launchpad.net/ubuntu-cloud-archive/mitaka-staging/ubuntu trusty main"
        key_id: 8A6844A29F68104E
        key_server: hkp://p80.pool.sks-keyservers.net:80

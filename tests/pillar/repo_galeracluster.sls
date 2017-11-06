linux:
  system:
    enabled: true
    repo:
      galeracluster:
        source: 'deb http://releases.galeracluster.com/galera-{{ pillar.galera.version.galera }}/ubuntu {{ grains.get('oscodename') }} main'
        key_id: BC19DDBA
        key_server: hkp://p80.pool.sks-keyservers.net:80
        pin:
        - pin: 'release o=Galera Cluster'
          priority: 1001
          package: '*'
      mysql-wsrep:
        source: 'deb http://releases.galeracluster.com/mysql-wsrep-{{ pillar.galera.version.mysql }}/ubuntu {{ grains.get('oscodename') }} main'
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

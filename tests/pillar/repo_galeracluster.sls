linux:
  system:
    enabled: true
    repo:
      galeracluster:
        source: 'deb http://releases.galeracluster.com/ubuntu {{ grains.get('oscodename') }} main'
        key_id: BC19DDBA
        key_server: hkp://p80.pool.sks-keyservers.net:80
      mirantis_openstack_repo:
        source: "deb http://mirror.fuel-infra.org/mcp-repos/1.0/{{ grains.get('oscodename') }} mitaka main"
        architectures: amd64
        key_url: "http://mirror.fuel-infra.org/mcp-repos/1.0/{{ grains.get('oscodename') }}/archive-mcp1.0.key"

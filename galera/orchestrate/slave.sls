galera.slave:
  salt.state:
    - tgt: 'galera:slave'
    - tgt_type: pillar
    - queue: True
    - sls: galera.slave
    - batch: 1
    - require:
      - salt: galera.server


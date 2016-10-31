galera.master:
  salt.state:
    - tgt: 'galera:master'
    - tgt_type: pillar
    - queue: True
    - sls: galera.master
    - batch: 1

galera.server:
  salt.state:
    - tgt: 'galera:master'
    - tgt_type: pillar
    - queue: True
    - sls: galera.server
    - batch: 1
    - require:
      - salt: galera.master


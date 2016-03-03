galera_master:
  salt.state:
    - tgt: 'roles:galera.master'
    - tgt_type: grain
    - sls: galera

galera_slaves:
  salt.state:
    - tgt: 'roles:galera.slave'
    - tgt_type: grain
    - sls: galera
    - require:
      - salt: galera_master


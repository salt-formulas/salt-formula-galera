{%- from "galera/map.jinja" import master with context %}
{%- if master.enabled %}

galera_packages:
  pkg.installed:
  - names: {{ master.pkgs }}

galera_log_dir:
  file.directory:
  - name: /var/log/mysql
  - makedirs: true
  - mode: 755
  - require:
    - pkg: galera_packages

galera_run_dir:
  file.directory:
  - name: /var/run/mysqld
  - makedirs: true
  - mode: 755
  - user: mysql
  - group: root
  - require:
    - pkg: galera_packages

galera_init_script:
  file.managed:
  - name: /etc/init.d/mysql
  - source: salt://galera/files/mysql
  - mode: 755
  - require: 
    - pkg: galera_packages

{%- if salt['cmd.run']('test -e /var/lib/mysql/.galera_bootstrap; echo $?') != '0'  %}

galera_bootstrap_temp_config:
  file.managed:
  - name: {{ master.config }}
  - source: salt://galera/files/my.cnf.bootstrap
  - mode: 644
  - template: jinja
  - require: 
    - pkg: galera_packages
    - file: galera_init_script

galera_bootstrap_start_service:
  cmd.script:
  - name: master_initial_bootstrap
  - source: salt://galera/files/bootstrap.sh
  - require: 
    - file: galera_bootstrap_temp_config
    - file: galera_run_dir

galera_bootstrap_set_root_password:
  cmd.run:
  - name: mysqladmin password "{{ master.admin.password }}"
  - require:
    - cmd: galera_bootstrap_start_service

mysql_bootstrap_update_maint_password:
  cmd.run:
  - name: mysql -u root -p{{ master.admin.password }} -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '{{ master.maintenance_password }}';"
  - require:
    - cmd: galera_bootstrap_set_root_password

galera_bootstrap_stop_service:
  service.dead:
  - name: {{ master.service }}
  - require:
    - cmd: mysql_bootstrap_update_maint_password

galera_bootstrap_init_config:
  file.managed:
  - name: {{ master.config }}
  - source: salt://galera/files/my.cnf.init
  - mode: 644
  - template: jinja
  - require: 
    - service: galera_bootstrap_stop_service

galera_bootstrap_start_service_final:
  cmd.script:
  - name: master_bootstrap
  - source: salt://galera/files/bootstrap.sh
  - require: 
    - file: galera_bootstrap_init_config

galera_bootstrap_finish_flag:
  file.touch:
  - name: /var/lib/mysql/.galera_bootstrap
  - require:
    - cmd: galera_bootstrap_start_service_final
  - watch_in:
    - file: galera_config

{%- endif %}

galera_config:
  file.managed:
  - name: {{ master.config }}
  - source: salt://galera/files/my.cnf
  - mode: 644
  - template: jinja
  - require_in: 
    - service: galera_service

galera_service:
  service.running:
  - name: {{ master.service }}
  - enable: true
  - reload: true

{%- endif %}

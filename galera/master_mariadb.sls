{%- from "galera/map.jinja" import master with context %}
{%- if master.get('enabled', False) %}

{%- if master.get('ssl', {}).get('enabled', False) %}
include:
  - galera._ssl
{%- endif %}

galera_packages:
  pkg.installed:
  - names: {{ master.pkgs }}
  - refresh: true
  - force_yes: True

galera_run_dir:
  file.directory:
  - name: /var/run/mysqld
  - makedirs: true
  - mode: 755
  - user: mysql
  - group: root
  - require:
    - galera_packages

{%- if salt['cmd.shell']('test -e /etc/salt/.galera_bootstrap; echo $?') != '0'  %}

galera_mariadb_stop_service:
  service.dead:
  - name: {{ master.service }}

galera_mariadb_new_cluster:
  cmd.run:
  - name: /usr/bin/galera_new_cluster
  - require:
    - galera_packages
    - galera_config

galera_set_root_password:
  cmd.run:
  - name: mysqladmin password "{{ master.admin.password }}"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - galera_mariadb_new_cluster

mariadb_update_maint_password:
  cmd.run:
  - name: mysql -u root -p{{ master.admin.password }} -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '{{ master.maintenance_password }}';"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - galera_mariadb_new_cluster

galera_mariadb_finish_flag:
  file.touch:
  - name: /etc/salt/.galera_bootstrap
  - require:
    - galera_mariadb_new_cluster

{%- endif %}

galera_config:
  file.managed:
  - name: {{ master.config }}
  - source: salt://galera/files/my.cnf
  - mode: 644
  - template: jinja

mariadb_service_enable:
  service.running:
  - name: {{ master.service }}
  - enable: true
  - require:
    - galera_packages
    - galera_config

{%- endif %}

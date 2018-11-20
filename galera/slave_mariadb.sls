{%- from "galera/map.jinja" import slave with context %}
{%- if slave.get('enabled', False) %}

{%- if slave.get('ssl', {}).get('enabled', False) %}
include:
  - galera._ssl
{%- endif %}

galera_packages:
  pkg.installed:
  - names: {{ slave.pkgs }}
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

galera_set_root_password:
  cmd.run:
  - name: mysqladmin password "{{ slave.admin.password }}"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

mariadb_update_maint_password:
  cmd.run:
  - name: mysql -u root -p{{ slave.admin.password }} -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '{{ slave.maintenance_password }}';"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

mariadb_service_dead:
  service.dead:
  - name: {{ slave.service }}

galera_mariadb_finish_flag:
  file.touch:
  - name: /etc/salt/.galera_bootstrap

{%- endif %}

galera_config:
  file.managed:
  - name: {{ slave.config }}
  - source: salt://galera/files/my.cnf
  - mode: 644
  - template: jinja

mariadb_service_enable:
  service.running:
  - name: {{ slave.service }}
  - enable: true
  - require:
    - galera_packages
    - galera_config

{%- endif %}

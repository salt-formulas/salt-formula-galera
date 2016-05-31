{%- from "galera/map.jinja" import slave with context %}
{%- if slave.enabled %}

{%- if grains.os_family == 'RedHat' %}
xtrabackup_repo:
  pkg.installed:
  - sources:
    - percona-release: {{ slave.xtrabackup_repo }}
  - require_in:
    - pkg: galera_packages

# Workaround https://bugs.launchpad.net/percona-server/+bug/1490144
xtrabackup_repo_fix:
  cmd.run:
    - name: |
        sed -i 's,enabled\ =\ 1,enabled\ =\ 1\nexclude\ =\ Percona-XtraDB-\*\ Percona-Server-\*,g' /etc/yum.repos.d/percona-release.repo
    - unless: 'grep "exclude = Percona-XtraDB-\*" /etc/yum.repos.d/percona-release.repo'
    - watch:
      - pkg: xtrabackup_repo
    - require_in:
      - pkg: galera_packages
{%- endif %}

{%- if grains.os_family == 'Debian' %}
mariadb_repo:
  file.managed:
  - name: /etc/apt/sources.list.d/mariadb_10-1.list
  - source: salt://galera/files/mariadb.list

mariadb_key:
  file.managed:
  - name: /root/mariadb.key
  - source: salt://galera/files/mariadb.key
  - mode: 660

install_mariadb_key:
  cmd.run:
  - name: 'cat /root/mariadb.key | apt-key add -'
  - require:
    - file: mariadb_key
    - file: mariadb_repo
{%- endif %}

mariadb_etc_dir:
  file.directory:
    - name: /etc/mysql
    - makedirs: true
    - mode: 755

mariadb-common-pkgs:
  pkg.installed:
    - names:
      - mariadb-common

galera_config:
  file.managed:
    - name: /etc/mysql/my.cnf
    - source: salt://galera/files/my.cnf
    - mode: 644
    - template: jinja
    - require:
      - pkg: mariadb-common-pkgs

galera_debian_config:
  file.managed:
    - name: /etc/mysql/debian.cnf
    - source: salt://galera/files/debian.cnf_slave
    - mode: 644
    - template: jinja
    - require:
      - pkg: mariadb-common-pkgs

galera_packages:
  pkg.installed:
  - names: {{ slave.pkgs }}
  - refresh: true
  - require:
    - cmd: install_mariadb_key
    - file: galera_config
    - file: galera_debian_config

galera_log_dir:
  file.directory:
    - name: /var/log/mysql
    - makedirs: true
    - mode: 755
    - require:
      - pkg: galera_packages

galera_start_service:
  service.running:
  - name: mysql
  - enable: True
  - require:
    - file: galera_config

galera_bootstrap_set_root_password:
  cmd.run:
  - name: mysqladmin password "{{ slave.admin.password }}"
  - require:
    - service: galera_start_service
  - unless: 'mysql --user="root" --password="{{ salt['pillar.get']('galera:slave:admin:password') }}" --database="mysql" --execute="show tables"'

mysql_bootstrap_update_maint_password:
  cmd.run:
  - name: mysql -u root -p{{ slave.admin.password }} -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '{{ slave.maintenance_password }}';"
  - require:
    - cmd: galera_bootstrap_set_root_password

{%- endif %}

{%- from "galera/map.jinja" import master with context %}
{%- if master.enabled %}

{%- if grains.os_family == 'RedHat' %}
xtrabackup_repo:
  pkg.installed:
  - sources:
    - percona-release: {{ master.xtrabackup_repo }}
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
  - unless: 'apt-key list | grep mariadb'

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

galera_bootstrap_config:
  file.managed:
  - name: {{ master.config }}
  - source: salt://galera/files/my.cnf.bootstrap
  - mode: 644
  - template: jinja
  - require:
    - pkg: mariadb-common-pkgs
    - file: mariadb_etc_dir
  - unless: 'mysql --user="root" --password="{{ salt['pillar.get']('galera:master:admin:password') }}" --database="mysql" --execute="show status" | grep wsrep_cluster_size | grep -E "2|3"'

galera_debian_config:
  file.managed:
    - name: /etc/mysql/debian.cnf
    - source: salt://galera/files/debian.cnf
    - mode: 644
    - template: jinja
    - require:
      - pkg: mariadb-common-pkgs

galera_packages:
  pkg.installed:
  - names: {{ master.pkgs }}
  - refresh: true
  - require:
    - cmd: install_mariadb_key
    - file: galera_bootstrap_config
    - file: galera_debian_config

galera_log_dir:
  file.directory:
  - name: /var/log/mysql
  - makedirs: true
  - mode: 755
  - require:
    - pkg: galera_packages

galera_bootstrap_start_service:
  service.running:
  - name: mysql
  - enable: True
  - require:
    - file: galera_bootstrap_config

galera_bootstrap_set_root_password:
  cmd.run:
  - name: mysqladmin password "{{ master.admin.password }}"
  - require:
    - service: galera_bootstrap_start_service
  - unless: 'mysql --user="root" --password="{{ salt['pillar.get']('galera:master:admin:password') }}" --database="mysql" --execute="show tables"'

mysql_bootstrap_update_maint_password:
  cmd.run:
  - name: mysql -u root -p{{ master.admin.password }} -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '{{ master.maintenance_password }}';"
  - require:
    - cmd: galera_bootstrap_set_root_password

galera_restart_bootstrap:
  service.running:
  - name: mysql
  - enable: True
  - watch:
    - file: galera_normal_config

galera_normal_config:
  file.managed:
    - name: /etc/mysql/my.cnf
    - source: salt://galera/files/my.cnf
    - mode: 644
    - template: jinja
    - require:
      - pkg: galera_packages
    - onlyif: 'mysql --user="root" --password="{{ salt['pillar.get']('galera:master:admin:password') }}" --database="mysql" --execute="show status"  | grep wsrep_cluster_size | grep -E "2|3"'

{%- endif %}

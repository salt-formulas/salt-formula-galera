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

galera_packages:
  pkg.installed:
  - names: {{ slave.pkgs }}
  - refresh: true
  - force_yes: True

galera_log_dir:
  file.directory:
  - name: /var/log/mysql
  - makedirs: true
  - mode: 755
  - require:
    - pkg: galera_packages

{%- if grains.os_family == 'Debian' %}
galera_run_dir:
  file.directory:
  - name: /var/run/mysqld
  - makedirs: true
  - mode: 755
  - user: mysql
  - group: root
  - require:
    - pkg: galera_packages

{%- if grains.get('init', None) == "upstart" %}

galera_purge_init:
  file.absent:
  - name: /etc/init.d/mysql
  - require:
    - pkg: galera_packages

galera_overide:
  file.managed:
  - name: /etc/init/mysql.override
  - contents: |
      limit nofile 102400 102400
      exec /usr/bin/mysqld_safe
  - require:
    - pkg: galera_packages

{%- elif grains.get('init', None) == "systemd" %}

galera_systemd_directory_present:
  file.directory:
  - name: /etc/systemd/system/mysql.service.d
  - user: root
  - group: root
  - mode: 755
  - require:
    - pkg: galera_packages

galera_override_limit_no_file:
  file.managed:
  - name: /etc/systemd/system/mysql.service.d/override.conf
  - contents: |
      [Service]
      LimitNOFILE=1024000
  - require:
    - pkg: galera_packages
    - file: galera_systemd_directory_present
  - watch_in:
    - service: galera_service

mysql_restart_systemd:
  module.wait:
  - name: service.systemctl_reload
  - watch:
    - file: /etc/systemd/system/mysql.service.d/override.conf
  - require_in:
    - service: galera_service

{%- endif %}

galera_conf_debian:
  file.managed:
  - name: /etc/mysql/debian.cnf
  - template: jinja
  - source: salt://galera/files/debian.cnf
  - mode: 640
  - require:
    - pkg: galera_packages

{%- endif %}

galera_init_script:
  file.managed:
  - name: /usr/local/sbin/galera_init.sh
  - mode: 755
  - source: salt://galera/files/init_bootstrap.sh
  - defaults:
      service: {{ slave|yaml }}
  - template: jinja

galera_bootstrap_script:
  file.managed:
  - name: /usr/local/sbin/galera_bootstrap.sh
  - mode: 755
  - defaults:
      service: {{ slave|yaml }}
  - source: salt://galera/files/bootstrap.sh
  - template: jinja

{%- if salt['cmd.run']('test -e /var/lib/mysql/.galera_bootstrap; echo $?') != '0'  %}

# Enforce config before package installation
galera_pre_config:
  file.managed:
  - name: {{ slave.config }}
  - source: salt://galera/files/my.cnf.pre
  - mode: 644
  - template: jinja
  - makedirs: true
  - require_in:
    - pkg: galera_packages

{%- if not grains.get('noservices', False) %}

galera_init_start_service:
  cmd.run:
  - name: /usr/local/sbin/galera_init.sh
  - require: 
    - file: galera_run_dir
    - file: galera_init_script
  - timeout: 1800

galera_bootstrap_set_root_password:
  cmd.run:
  - name: mysqladmin password "{{ slave.admin.password }}"
  - require:
    - cmd: galera_init_start_service

mysql_bootstrap_update_maint_password:
  cmd.run:
  - name: mysql -u root -p{{ slave.admin.password }} -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '{{ slave.maintenance_password }}';"
  - require:
    - cmd: galera_bootstrap_set_root_password

galera_bootstrap_stop_service:
  service.dead:
  - name: {{ slave.service }}
  - require:
    - cmd: mysql_bootstrap_update_maint_password

{%- endif %}

galera_bootstrap_init_config:
  file.managed:
  - name: {{ slave.config }}
  - source: salt://galera/files/my.cnf
  - mode: 644
  - template: jinja
  {%- if not grains.get('noservices', False) %}
  - require: 
    - service: galera_bootstrap_stop_service
  {%- endif %}

{%- if not grains.get('noservices', False) %}

galera_bootstrap_start_service_final:
  cmd.run:
  - name: /usr/local/sbin/galera_bootstrap.sh
  - require: 
    - file: galera_bootstrap_init_config
    - file: galera_bootstrap_script
  - timeout: 1800

galera_bootstrap_finish_flag:
  file.touch:
  - name: /var/lib/mysql/.galera_bootstrap
  - require:
    - cmd: galera_bootstrap_start_service_final
  - watch_in:
    - file: galera_config

{%- endif %}
{%- endif %}

galera_config:
  file.managed:
  - name: {{ slave.config }}
  - source: salt://galera/files/my.cnf
  - mode: 644
  - template: jinja
  {%- if not grains.get('noservices', False) %}
  - require_in: 
    - service: galera_service
  {%- endif %}

{%- if not grains.get('noservices', False) %}
galera_service:
  service.running:
  - name: {{ slave.service }}
  - enable: true
  - reload: true
{%- endif %}


{%- endif %}

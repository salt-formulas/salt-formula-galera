{%- from "galera/map.jinja" import master with context %}
{%- if master.get('enabled', False) %}

{%- if master.get('ssl', {}).get('enabled', False) %}
include:
  - galera._ssl
{%- endif %}

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

galera_packages:
  pkg.installed:
  - names: {{ master.pkgs }}
  - refresh: true
  - force_yes: True

galera_dirs:
  file.directory:
  - names: ['/var/log/mysql', '/etc/mysql']
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
      service: {{ master|yaml }}
  - template: jinja
  - timeout: 1800

galera_bootstrap_script:
  file.managed:
  - name: /usr/local/sbin/galera_bootstrap.sh
  - mode: 755
  - source: salt://galera/files/bootstrap.sh
  - defaults:
      service: {{ master|yaml }}
      slave: False
  - template: jinja

{%- if salt['cmd.shell']('test -e /var/lib/mysql/.galera_bootstrap; echo $?') != '0'  %}
{%- if salt['cmd.shell']('test -e /etc/salt/.galera_bootstrap; echo $?') != '0'  %}

# Enforce config before package installation
galera_pre_config:
  file.managed:
  - name: {{ master.config }}
  - source: salt://galera/files/my.cnf.pre
  - mode: 644
  - template: jinja
  - makedirs: True
  - require_in:
    - pkg: galera_packages

galera_init_start_service:
  cmd.run:
  - name: /usr/local/sbin/galera_init.sh
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - file: galera_run_dir
    - file: galera_init_script
  - timeout: 1800

galera_bootstrap_set_root_password:
  cmd.run:
  - name: mysqladmin password "{{ master.admin.password }}"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - cmd: galera_init_start_service

mysql_bootstrap_update_maint_password:
  cmd.run:
  - name: mysql -u root -p{{ master.admin.password }} -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '{{ master.maintenance_password }}';"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - cmd: galera_bootstrap_set_root_password

galera_bootstrap_stop_service:
  service.dead:
  - name: {{ master.service }}
  {%- if not grains.get('noservices', False) %}
  - require:
    - cmd: mysql_bootstrap_update_maint_password
  {%- else %}
  - onlyif: /bin/false
  {%- endif %}

galera_bootstrap_init_config:
  file.managed:
  - name: {{ master.config }}
  - source: salt://galera/files/my.cnf.init
  - mode: 644
  - template: jinja
  - require:
    - service: galera_bootstrap_stop_service

galera_bootstrap_start_service_final:
  cmd.run:
  - name: /usr/local/sbin/galera_bootstrap.sh
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - file: galera_bootstrap_init_config
    - file: galera_bootstrap_script

galera_bootstrap_finish_flag:
  file.touch:
  - name: /etc/salt/.galera_bootstrap
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
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}
{%- endif %}

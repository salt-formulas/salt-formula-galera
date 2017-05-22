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



{%- set _galera_xinetd_srv = [] %}

{%- for server_name, server in master.get('bind', {}).iteritems() %}
{%- if server.get.get('clustercheck', {}).get('enabled', False) == True %}
{%- for bind in slave.bind %}
{%- set index = '_{0}_{1}'.format(bind.address, bind.port) %}
{%- set _ccheck = server.clustercheck %}
{%- do _galera_xinetd_srv.append('clustercheck') %}
/etc/xinetd.d/mysql_clustercheck{{ index }}_{{ _ccheck.get('clustercheckport', 9200) }}:
  file.managed:
    - source: salt://galera/files/xinet.d.conf
    - template: jinja
    - defaults:
        user: nobody
        # FIXME, add optins if check_attr host/port is defined etc..
        server: '/usr/local/bin/clustercheck {{ _ccheck.get('user', 'clustercheck') }} {{ _ccheck.get('password', 'clustercheck') }} {{ _ccheck.get('available_when_donor', 0) }} {{ _ccheck.get('available_when_readonly', 0) }}'
        port: _ccheck.get('port', 9200)
        flags: REUSE
        per_source: UNLIMITED
    - require:
      - file: /usr/local/bin/mysql_clustercheck
    - watch_in:
      - galera_xinetd_service

{%- endfor %}
{%- endif %}
{%- endfor %}

{% if 'clustercheck' in _galera_xinetd_srv %}
clustercheck_dir:
  file.directory:
  - name: /usr/local/bin/
  - user: root
  - group: root
  - mode: 750

/usr/local/bin/mysql_clustercheck:
  file.managed:
    - source: salt://galera/files/clustercheck.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: clustercheck_dir
{%- endif %}

{%- if _galera_xinetd_srv|length > 0 %}
haproxy_xinetd_package:
  pkg.installed:
  - name: xinetd

galera_xinetd_service:
  service.running:
  - name: xinetd
  - require:
    - pkg: xinetd
{%- endif %}


{%- endif %}

{%- if pillar.get('mysql', {}).server is defined  %}

{%- set server = pillar.mysql.server %}

{%- for database_name, database in server.get('database', {}).iteritems() %}

mysql_database_{{ database_name }}:
  mysql_database.present:
  - name: {{ database_name }}

{%- for user in database.users %}

mysql_user_{{ user.name }}_{{ database_name }}_{{ user.host }}:
  mysql_user.present:
  - host: '{{ user.host }}'
  - name: '{{ user.name }}'
  - password: {{ user.password }}

mysql_grants_{{ user.name }}_{{ database_name }}_{{ user.host }}:
  mysql_grants.present:
  - grant: {{ user.rights }}
  - database: '{{ database_name }}.*'
  - user: '{{ user.name }}'
  - host: '{{ user.host }}'
  - require:
    - mysql_user: mysql_user_{{ user.name }}_{{ database_name }}_{{ user.host }}
    - mysql_database: mysql_database_{{ database_name }}

{%- endfor %}

{%- if database.initial_data is defined %}

/root/mysql/scripts/restore_{{ database_name }}.sh:
  file.managed:
  - source: salt://mysql/conf/restore.sh
  - mode: 770
  - template: jinja
  - defaults:
    database_name: {{ database_name }}
    database: {{ database }}
  - require: 
    - file: mysql_dirs
    - mysql_database: mysql_database_{{ database_name }}

restore_mysql_database_{{ database_name }}:
  cmd.run:
  - name: /root/mysql/scripts/restore_{{ database_name }}.sh
  - unless: "[ -f /root/mysql/flags/{{ database_name }}-installed ]"
  - cwd: /root
  - require:
    - file: /root/mysql/scripts/restore_{{ database_name }}.sh

{%- endif %}

{%- endfor %}

{%- if not grains.get('noservices', False) %}
{%- for user in server.get('users', []) %}
{%- set user_hosts = user.get('hosts', user.get('host', 'localhost'))|sequence %}
{%- for host in user_hosts %}
mysql_user_{{ user.name }}_{{ host }}:
  mysql_user.present:
  - host: '{{ user.host }}'
  - name: '{{ user.name }}'
  {%- if user['password_hash'] is defined %}
    - password_hash: '{{ user.password_hash }}'
  {%- elif user['password'] is defined and user['password'] != None %}
    - password: '{{ user.password }}'
  {%- else %}
  - allow_passwordless: True
  {%- endif %}
  - connection_charset: utf8

{%- if 'grants' in user %}
mysql_user_{{ user.name }}_{{ host }}_grants:
  mysql_grants.present:
    - name: {{ user.name }}
    - grant: {{ user['grants']|sequence|join(",") }}
    - database: '*.*'
    - grant_option: {{ user['grant_option'] | default(False) }}
    - user: {{ user.name }}
    - host: '{{ host }}'
    - connection_charset: utf8
    - require:
      - mysql_user_{{ user.name }}_{{ host }}
{%- endif %}

{%- if 'databases' in user %}
{% for db in user['databases'] %}
mysql_user_{{ user.name }}_{{ host }}_grants_db_{{ db }} ~ '_' ~ loop.index0:
  mysql_grants.present:
    - name: {{ user.name ~ '_' ~ db['database']  ~ '_' ~ db['table'] | default('all') }}
    - grant: {{db['grants']|sequence|join(",")}}
    - database: '{{ db['database'] }}.{{ db['table'] | default('*') }}'
    - grant_option: {{ db['grant_option'] | default(False) }}
    - user: {{ user.name }}
    - host: '{{ host }}'
    - connection_charset: utf8
    - require:
      - mysql_user_{{ user.name }}_{{ host }}
      - mysql_database_{{ db }}
{%- endfor %}
{%- endif %}

{%- endfor %}
{%- endfor %}

{%- endif %}

{%- set _galera_xinetd_srv = [] %}

{%- for server_name, server in slave.get('bind', {}).iteritems() %}
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
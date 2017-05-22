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
{%- endif %}

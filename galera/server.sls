{%- if pillar.get('mysql', {}).server is defined  %}
{%- from "mysql/map.jinja" import mysql_connection_args as connection with context %}
{%- set server = pillar.mysql.server %}

{%- for database_name, database in server.get('database', {}).iteritems() %}

{%- if not grains.get('noservices', False) %}
mysql_database_{{ database_name }}:
  mysql_database.present:
  - name: {{ database_name }}
  - character_set: {{ database.get('encoding', 'utf8') }}
  #- connection_user: {{ connection.user }}
  #- connection_pass: {{ connection.password }}
  #- connection_charset: {{ connection.charset }}
{%- endif %}

{%- for user in database.users %}
{%- if not grains.get('noservices', False) %}
mysql_user_{{ user.name }}_{{ database_name }}_{{ user.host }}:
  mysql_user.present:
  - host: '{{ user.host }}'
  - name: '{{ user.name }}'
  {%- if user.password is defined %}
  - password: {{ user.password }}
  {%- else %}
  - allow_passwordless: true
  {%- endif %}
  #- connection_user: {{ connection.user }}
  #- connection_pass: {{ connection.password }}
  #- connection_charset: {{ connection.charset }}

mysql_grants_{{ user.name }}_{{ database_name }}_{{ user.host }}:
  mysql_grants.present:
  - grant: {{ user.rights }}
  - database: '{{ database_name }}.*'
  - user: '{{ user.name }}'
  - host: '{{ user.host }}'
  #- connection_user: {{ connection.user }}
  #- connection_pass: {{ connection.password }}
  #- connection_charset: {{ connection.charset }}
  - require:
    - mysql_user: mysql_user_{{ user.name }}_{{ database_name }}_{{ user.host }}
    - mysql_database: mysql_database_{{ database_name }}
{%- endif %}
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

{%- for user in server.get('users', []) %}
{%- for host in user.get('hosts', user.get('host', 'localhost'))|sequence %}
{%- if not grains.get('noservices', False) %}
mysql_user_{{ user.name }}_{{ host }}:
  mysql_user.present:
  - host: '{{ host }}'
  - name: '{{ user.name }}'
  {%- if user['password_hash'] is defined %}
  - password_hash: '{{ user.password_hash }}'
  {%- elif user['password'] is defined and user['password'] != None %}
  - password: '{{ user.password }}'
  {%- else %}
  - allow_passwordless: True
  {%- endif %}
  #- connection_user: {{ connection.user }}
  #- connection_pass: {{ connection.password }}
  #- connection_charset: {{ connection.charset }}

{%- if 'grants' in user %}
mysql_user_{{ user.name }}_{{ host }}_grants:
  mysql_grants.present:
    - name: {{ user.name }}
    - grant: {{ user['grants']|sequence|join(",") }}
    - database: '{{ user.get('database','*.*') }}'
    - grant_option: {{ user['grant_option'] | default(False) }}
    - user: {{ user.name }}
    - host: '{{ host }}'
    #- connection_user: {{ connection.user }}
    #- connection_pass: {{ connection.password }}
    #- connection_charset: {{ connection.charset }}
    - require:
      - mysql_user_{{ user.name }}_{{ host }}
{%- endif %}

{%- if 'databases' in user %}
{%- for db in user['databases'] %}
mysql_user_{{ user.name }}_{{ host }}_grants_db_{{ db.database }}_{{ loop.index0 }}:
  mysql_grants.present:
    - name: {{ user.name ~ '_' ~ db['database']  ~ '_' ~ db['table'] | default('all') }}
    - grant: {{ db['grants']|sequence|join(",") }}
    - database: '{{ db['database'] }}.{{ db['table'] | default('*') }}'
    - grant_option: {{ db['grant_option'] | default(False) }}
    - user: {{ user.name }}
    - host: '{{ host }}'
    #- connection_user: {{ connection.user }}
    #- connection_pass: {{ connection.password }}
    #- connection_charset: {{ connection.charset }}
    - require:
      - mysql_user_{{ user.name }}_{{ host }}
      - mysql_database_{{ db.database }}
{%- endfor %}
{%- endif %}

{%- endif %}
{%- endfor %}
{%- endfor %}


{%- endif %}

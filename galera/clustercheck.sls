{%- from "galera/map.jinja" import clustercheck with context %}

{%- if clustercheck.get('enabled', False) %}
/usr/local/bin/mysql_clustercheck:
  file.managed:
    - source: salt://galera/files/clustercheck.sh
    - user: root
    - group: root
    - mode: 755
    - dir_mode: 755
    - makedirs: True

/etc/xinetd.d/mysql_clustercheck:
  file.managed:
    - source: salt://galera/files/xinet.d.conf
    - template: jinja
    - makedirs: True
    - defaults:
        name: mysqlchk
        user: nobody
        server: '/usr/local/bin/mysql_clustercheck'
        server_args: '{{ clustercheck.get('user', 'clustercheck') }} {{ clustercheck.get('password', 'clustercheck') }} available_when_donor={{ clustercheck.get('available_when_donor', 0) }} /dev/null available_when_readonly={{ clustercheck.get('available_when_readonly', 0) }} {{ clustercheck.config }}'
        port: {{ clustercheck.get('port', 9200) }}
        flags: REUSE
        per_source: UNLIMITED
    - require:
      - file: /usr/local/bin/mysql_clustercheck
{%- if not grains.get('noservices', False) %}
    - watch_in:
      - galera_xinetd_service
{%- endif %}

galera_xinetd_package:
  pkg.installed:
  - name: xinetd

{%- if not grains.get('noservices', False) %}
galera_xinetd_service:
  service.running:
  - name: xinetd
  - require:
    - pkg: xinetd
{%- endif %}
{%- endif %}


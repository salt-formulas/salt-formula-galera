{%- from "galera/map.jinja" import clustercheck %}

{%- if clustercheck.get('enabled', False) %}
clustercheck_dir:
  file.directory:
  - name: /usr/local/bin/
  - user: root
  - group: root
  - mode: 750
  - makedirs: True

/usr/local/bin/mysql_clustercheck:
  file.managed:
    - source: salt://galera/files/clustercheck.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: clustercheck_dir

/etc/xinetd.d/mysql_clustercheck.conf:
  file.managed:
    - source: salt://galera/files/xinet.d.conf
    - template: jinja
    - defaults:
        user: nobody
        server: '/usr/local/bin/clustercheck {{ clustercheck.get('user', 'clustercheck') }} {{ clustercheck.get('password', 'clustercheck') }} {{ clustercheck.get('available_when_donor', 0) }} {{ clustercheck.get('available_when_readonly', 0) }}'
        port: clustercheck.get('port', 9200)
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


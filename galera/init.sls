{% set engine = pillar.galera.get('engine', 'mysql') %}
{%- if pillar.galera is defined %}
include:
{%- if pillar.galera.master is defined %}
  {%- if engine == 'mysql' %}
- galera.master
  {%- else %}
- galera.master_mariadb
  {%- endif %}
{%- endif %}
{%- if pillar.galera.slave is defined %}
  {%- if engine == 'mysql' %}
- galera.slave
  {%- else %}
- galera.slave_mariadb
  {%- endif %}
{%- endif %}
{%- if pillar.galera.clustercheck is defined %}
- galera.clustercheck
{%- endif %}
{%- if pillar.galera.monitor is defined %}
- galera.monitor
{%- endif %}
{%- endif %}
{%- if pillar.mysql is defined %}
{%- if pillar.mysql.server is defined %}
- galera.server
{%- endif %}
{%- endif %}

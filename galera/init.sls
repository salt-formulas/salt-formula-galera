
{%- if pillar.galera is defined %}
include:
{%- if pillar.galera.master is defined %}
- galera.master
{%- endif %}
{%- if pillar.galera.slave is defined %}
- galera.slave
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


{%- if pillar.galera is defined %}
include:
{%- if pillar.galera.master is defined %}
- galera.master
{%- endif %}
{%- if pillar.galera.slave is defined %}
- galera.slave
{%- endif %}
{%- endif %}

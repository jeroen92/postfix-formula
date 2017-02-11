{% from "postfix/map.jinja" import postfix with context %}

include:
  - postfix

{{ postfix_config_dir }}/postfix:
  file.directory:
    - user: {{ postfix_config_user }}
    - group: {{ postfix_config_group }}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True

{{ postfix_config_dir }}/postfix/main.cf:
  file.managed:
    - source: salt://postfix/files/main.cf
    - user: {{ postfix_config_user }}
    - group: {{ postfix_config_group }}
    - mode: 644
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix
    - template: jinja

{% if 'vmail' in pillar.get('postfix', '') %}
{{ postfix_config_dir }}/postfix/virtual_alias_maps.cf:
  file.managed:
    - source: salt://postfix/files/virtual_alias_maps.cf
    - user: {{ postfix_config_user }}
    - group: {{ postfix_config_group }}
    - mode: 640
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix
    - template: jinja

{{ postfix_config_dir }}/postfix/virtual_mailbox_domains.cf:
  file.managed:
    - source: salt://postfix/files/virtual_mailbox_domains.cf
    - user: {{ postfix_config_user }}
    - group: {{ postfix_config_group }}
    - mode: 640
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix
    - template: jinja

{{ postfix_config_dir }}/postfix/virtual_mailbox_maps.cf:
  file.managed:
    - source: salt://postfix/files/virtual_mailbox_maps.cf
    - user: {{ postfix_config_user }}
    - group: {{ postfix_config_group }}
    - mode: 640
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix
    - template: jinja
{% endif %}

{% if salt['pillar.get']('postfix:manage_master_config', True) %}
{{ postfix_config_dir }}/postfix/master.cf:
  file.managed:
    - source: salt://postfix/files/master.cf
    - user: {{ postfix_config_user }}
    - group: {{ postfix_config_group }}
    - mode: 644
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix
    - template: jinja
{% endif %}

{% if 'transport' in pillar.get('postfix', '') %}
{{ postfix_config_dir }}/postfix/transport:
  file.managed:
    - source: salt://postfix/files/transport
    - user: {{ postfix_config_user }}
    - group: {{ postfix_config_group }}
    - mode: 644
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix
    - template: jinja

run-postmap:
  cmd.wait:
    - name: /usr/sbin/postmap {{ postfix_config_dir }}/postfix/transport
    - cwd: /
    - watch:
      - file: {{ postfix_config_dir }}/postfix/transport
{% endif %}

{%- for domain in salt['pillar.get']('postfix:certificates', {}).keys() %}

postfix_{{ domain }}_ssl_certificate:

  file.managed:
    - name: {{ postfix_config_dir }}/postfix/ssl/{{ domain }}.crt
    - makedirs: True
    - contents_pillar: postfix:certificates:{{ domain }}:public_cert
    - watch_in:
       - service: postfix

postfix_{{ domain }}_ssl_key:
  file.managed:
    - name: {{ postfix_config_dir }}/postfix/ssl/{{ domain }}.key
    - mode: 600
    - makedirs: True
    - contents_pillar: postfix:certificates:{{ domain }}:private_key
    - watch_in:
       - service: postfix

{% endfor %}

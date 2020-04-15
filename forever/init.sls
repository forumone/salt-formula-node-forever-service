{% set pget = salt['pillar.get'] %}
# Install nodejs and npm 
{% set ppa = pget('forever:nodesource_url') %}

"curl -sL {{ ppa }} | bash - ":
  cmd.run:
    - creates: /etc/yum.repos.d/nodesource-el7.repo
    - only_if: /usr/lib64/nginx

"yum install -y forever && yum install -y npm":
  cmd.run:
    - creates: /usr/bin/node
    - only_if: /etc/yum.repos.d/nodesource-el7.repo

"npm config set registry http://registry.npmjs.org/ && npm install forever -g":
  cmd.run:
     - creates: /usr/bin/forever
     - only_if: /usr/bin/npm
       
"npm install forever-service express -g":
  cmd.run:
     - creates: /usr/bin/forever-service
     - only_if: /usr/bin/npm

{% for app in pget('forever:Name', {}) %}
{% set user = pget('forever:'+ app +':user') %}
{% set location = pget('forever:'+ app +':location') %}
{% set environment = pget('forever:'+ app +':environment') %}
{% set configdir = pget('forever:'+ app +':configdir') %} 
{% set watchdirectory = pget('forever:'+ app +':watchdirectory') %}

'cd /home/{{ user }} && forever-service install --start -e "NODE_CONFIG_DIR={{ configdir }} NODE_ENV={{ environment }}" -r {{ user }} -s {{ location }} -f " --watchDirectory={{ watchdirectory }} -w" {{ app }}':
  cmd.run:
    - creates: /etc/init.d/{{ app }}
    - only_if: /usr/lib/node_modules/forever/bin/forever
    - order: last

{{ app }}:
  service.running:
    - enable: True
    - reload: True
    - only_if: /etc/init.d/{{ app }}

service {{ app }} restart:
  cmd.run:
    - only_if: /etc/init.d/{{ app }}

{% endfor %}


### Ansible Role 安装redis
Redis是一个使用ANSI C编写的开源、支持网络、基于内存、可选持久性的键值对存储数据库。

#### roles目录结构
```
[root@squid ansible]# tree  redis-install/
redis-install/
├── redis
│   ├── files
│   │   └── redis-4.0.6.tar.gz
│   ├── tasks
│   │   └── main.yml
│   └── templates
│       ├── install.redis.sh.j2
│       ├── redis.conf.j2
│       └── restart_redis.sh.j2
└── redis.yml
```

#### redis.conf配置文件
```
#修改过的部分:
1. 开启后台运行
[root@squid redis-install]# grep ^daemon redis/templates/redis.conf.j2
daemonize yes
2. 监听端口
[root@squid redis-install]# grep ^port redis/templates/redis.conf.j2
port {{redis_port}}
3. 修改bind绑定地址
[root@squid redis-install]# grep ^bind  redis/templates/redis.conf.j2
bind {{ansible_default_ipv4.address}}
```

#### tasks任务文件
```
[root@squid redis-install]# cat redis/tasks/main.yml 
---
- name: install rpm
  yum: name={{item}} state=present
  with_items:
  - gcc
  - tcl
- name: copy redis to remote
  unarchive: src=files/{{redis_soft_name}} dest={{redis_soft_dir}} copy=yes  mode=755
- name: run script to install redis
  template: src=install.redis.sh.j2 dest={{redis_soft_dir}}/install.redis.sh  mode=755
- shell: "{{redis_soft_dir}}/install.redis.sh"
  ignore_errors: True
- name: copy redis config file to remote hosts
  template: src=redis.conf.j2 dest={{redis_install_dir}}/conf/redis.conf
- name: copy redis restart script to remote hosts
  template: src=restart_redis.sh.j2 dest={{redis_install_dir}}/restart_redis.sh mode=755
- name: start redis
  shell: "{{redis_install_dir}}/restart_redis.sh"
- name: Check Redis Running Status
  shell: "netstat -nplt|grep -E '{{redis_port}}'"
  register: runStatus
- name: display Redis Running port
  debug: msg={{runStatus.stdout_lines}}
```

#### playbook执行过程
```
[root@squid redis-install]# ansible-playbook redis.yml 

PLAY [install redis] ******************************************************************************************************************************************************************************************

TASK [redis : install rpm] ************************************************************************************************************************************************************************************
ok: [10.241.0.10] => (item=[u'gcc', u'tcl'])
ok: [10.241.0.11] => (item=[u'gcc', u'tcl'])

TASK [redis : copy redis to remote] ***************************************************************************************************************************************************************************
changed: [10.241.0.10]
changed: [10.241.0.11]

TASK [redis : run script to install redis] ********************************************************************************************************************************************************************
ok: [10.241.0.11]
ok: [10.241.0.10]

TASK [redis : shell] ******************************************************************************************************************************************************************************************
changed: [10.241.0.10]
changed: [10.241.0.11]

TASK [redis : copy redis config file to remote hosts] *********************************************************************************************************************************************************
changed: [10.241.0.10]
changed: [10.241.0.11]

TASK [redis : copy redis restart script to remote hosts] ******************************************************************************************************************************************************
changed: [10.241.0.10]
changed: [10.241.0.11]

TASK [redis : start redis] ************************************************************************************************************************************************************************************
changed: [10.241.0.11]
changed: [10.241.0.10]

TASK [redis : Check Redis Running Status] *********************************************************************************************************************************************************************
changed: [10.241.0.10]
changed: [10.241.0.11]

TASK [redis : display Redis Running port] *********************************************************************************************************************************************************************
ok: [10.241.0.10] => {
    "msg": [
        "tcp        0      0 10.241.0.10:6379          0.0.0.0:*               LISTEN      1624/redis-server 1 "
    ]
}
ok: [10.241.0.11] => {
    "msg": [
        "tcp        0      0 10.241.0.11:6379          0.0.0.0:*               LISTEN      32268/redis-server  "
    ]
}

PLAY RECAP ****************************************************************************************************************************************************************************************************
10.241.0.10                : ok=9    changed=6    unreachable=0    failed=0
10.241.0.11                : ok=9    changed=6    unreachable=0    failed=0
```

upervisor：是用Python开发的一个client/server服务，是Linux/Unix系统下的一个进程管理工具，不支持Windows系统。它可以很方便的监听、启动、停止、重启一个或多个进程。用Supervisor管理的进程，当一个进程意外被杀死，supervisort监听到进程死后，会自动将它重新拉起.但是只支持前台程序.

安装后默认的用户名和密码为  admin/baiyongjie

#### roles介绍
```
#role目录结构如下:
[root@squid data]# tree Ansible-roles/
Ansible-roles/
├── supervisor.yml
└── supervisor
    ├── files
    │   └── supervisor_install.sh
    └── tasks
        └── main.yml

#supervisor.yml入口文件
[root@squid Ansible-roles]# cat supervisor.yml 
--- 
- name: install supervisor
  hosts: client
  roles: 
  - supervisor 
  tags:
  - install_supervisor

#tasks任务文件
[root@squid Ansible-roles]# cat supervisor/tasks/main.yml 
---
- script: supervisor_install.sh
  register: supervisor_install_out
  tags: supervisor_install

- debug: msg={{supervisor_install_out.stdout_lines}}
  tags: supervisor_install_out

#files下的脚本文件
[root@squid Ansible-roles]# cat supervisor/files/supervisor_install.sh
#!/bin/bash
#by: baiyongjie 20180830
#the script to install the supervisor

#supervisor env
port=9001
username=admin
password=baiyongjie
configdir=/etc/supervisor

#Get system version And localhost ip address
OSVERSION=`sed -r "s/.*[ ]([0-9])(.*)/\1/"  /etc/redhat-release`
if [ $OSVERSION -eq 6 ]
then
  LOCALIP=`ifconfig  | grep "inet addr:" | grep -v '127.0.0.1' | sed 's/^.*addr:\(.*\)  Bc.*$/\1/g' | tail -1 |awk '{print $1}'`
elif [ $OSVERSION -eq 7 ]
then
  LOCALIP=`ifconfig | grep inet | grep -Ev "inet6|127.0.0.1" | sed 's/^.*inet \(.*\)  ne.*$/\1/g' | tail -1`
fi

#check 9001 port available or not
if [ "`netstat -nplt | grep $port`" != "" ]
then
  echo -e "$port port is used ...\nscript exit" ; exit 10
fi


#install supervisor
cd /usr/local/src
wget http://download.baiyongjie.com/linux/supervisord/meld3-1.0.2.tar.gz   &> /dev/null
wget http://download.baiyongjie.com/linux/supervisord/supervisor-3.3.2.tar.gz   &> /dev/null
tar zxf meld3-1.0.2.tar.gz ; cd meld3-1.0.2 ; python setup.py install  > /dev/null ; cd ..
tar zxf supervisor-3.3.2.tar.gz ; cd supervisor-3.3.2 ; python setup.py install > /dev/null ; cd ..

#init supervisor
if [ ! -d $configdir ]
then
  mkdir -p $configdir/conf.d 
  echo_supervisord_conf > $configdir/supervisord.conf
  cat >> $configdir/supervisord.conf << EOF
[include]
files = ./conf.d/*.ini
[inet_http_server]         
port=$LOCALIP:$port
username=$username 
password=$password
EOF
fi

if [ $OSVERSION -eq 6 ]
then
  curl -s  http://download.baiyongjie.com/linux/supervisord/supervisord > /etc/init.d/supervisord
  chmod 755 /etc/init.d/supervisord
  /etc/init.d/supervisord start &> /dev/null
  echo "/etc/init.d/supervisord start" >> /etc/rc.d/rc.local
elif [ $OSVERSION -eq 7 ]
then
  curl -s http://download.baiyongjie.com/linux/supervisord/supervisord.service > /usr/lib/systemd/system/supervisord.service
  systemctl enable supervisord.service  &> /dev/null
  systemctl start supervisord.service  &> /dev/null
fi

if [ "`netstat -nplt | grep $port`" != "" ]
then
echo -e "url: $LOCALIP:$port
username: $username 
password: $password"
fi
```

#### 执行playbook
```
[root@squid Ansible-roles]# ansible-playbook supervisor.yml 

PLAY [install supervisor] **************************************************

TASK [supervisor : script] *************************************************
changed: [10.241.0.10]
changed: [10.241.0.11]

TASK [supervisor : debug] **************************************************
ok: [10.241.0.10] => {
    "msg": [
        "url: 10.241.0.10:9001", 
        "username: admin ", 
        "password: baiyongjie"
    ]
}
ok: [10.241.0.11] => {
    "msg": [
        "url: 10.241.0.11:9001", 
        "username: admin ", 
        "password: baiyongjie"
    ]
}

PLAY RECAP *****************************************************************
10.241.0.10                : ok=2    changed=1    unreachable=0    failed=0
10.241.0.11                : ok=2    changed=1    unreachable=0    failed=0

#执行tags,会失败是因为已经安装过了
[root@squid Ansible-roles]# ansible-playbook supervisor.yml --tags "install_supervisor"

PLAY [install supervisor] ************************************************************************************************************************

TASK [supervisor : script] ***********************************************************************************************************************
fatal: [10.241.0.10]: FAILED! => {"changed": true, "msg": "non-zero return code", "rc": 10, "stderr": "Shared connection to 10.241.0.10 closed.\r\n", "stderr_lines": ["Shared connection to 10.241.0.10 closed."], "stdout": "9001 port is used ...\r\nscript exit\r\n", "stdout_lines": ["9001 port is used ...", "script exit"]}
fatal: [10.241.0.11]: FAILED! => {"changed": true, "msg": "non-zero return code", "rc": 10, "stderr": "Shared connection to 10.241.0.11 closed.\r\n", "stderr_lines": ["Shared connection to 10.241.0.11 closed."], "stdout": "9001 port is used ...\r\nscript exit\r\n", "stdout_lines": ["9001 port is used ...", "script exit"]}
        to retry, use: --limit @/data/Ansible-roles/supervisor.retry

PLAY RECAP ***************************************************************************************************************************************
10.241.0.10                : ok=0    changed=0    unreachable=0    failed=1
10.241.0.11                : ok=0    changed=0    unreachable=0    failed=1
```

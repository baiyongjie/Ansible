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


#check pip available or not
if [ `which pip2 > /dev/null ; echo $?` -ne 0 ]
then
  wget https://bootstrap.pypa.io/ez_setup.py  &> /dev/null
  if [ $OSVERSION -eq 6 ]
  then
    python2.6 ez_setup.py  &> /dev/null
    easy_install-2.6 pip  &> /dev/null
  elif [ $OSVERSION -eq 7 ]
  then
    python2.7 ez_setup.py  &> /dev/null
    easy_install-2.7 pip  &> /dev/null
  fi
  if [ ! -d ~/.pip ]
  then
    mkdir  ~/.pip/
    cat >  ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
EOF
  fi
  pip2.7 install --upgrade pip &> /dev/null
fi

#install supervisor
pip install supervisor==3.3.2 &> /dev/null
if [ $? -ne 0 ]
then
  echo "supervisor install faled.. please check..."; exit 20
fi

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
  /etc/init.d/supervisord start
  chkconfig --level  35 supervisord on  &> /dev/null
  chkconfig --list | grep supervisord   &> /dev/null
elif [ $OSVERSION -eq 7 ]
then
  supervisord -c /etc/supervisor/supervisord.conf   &> /dev/null
  chmod +x /etc/rc.local 
  echo "supervisord -c /etc/supervisor/supervisord.conf" >> /etc/rc.local  
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

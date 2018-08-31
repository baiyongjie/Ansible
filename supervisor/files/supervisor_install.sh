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

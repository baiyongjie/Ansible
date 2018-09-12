#!/bin/bash
#by: baiyongjie 20180830
#the script to install the supervisor

#supervisor env
port=9001
username=admin
password=baiyongjie
configdir=/etc/supervisor

#Get system env
source /etc/profile

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
echo -e "url: http://$LOCALIP:$port
username: $username 
password: $password"
fi

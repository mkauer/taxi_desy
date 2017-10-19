#!bash

# first parameter is the tar file
# 2nd parameter is the host ip address or hostname
# 

TARFILE=$1
SSH_HOST=$2
SSH_PORT=22

SSH_CMD="ssh root@$SSH_HOST -p $SSH_PORT -i taxi_id_rsa -x" 
SCP_CMD="scp -P $SSH_PORT -i taxi_id_rsa " 

chmod 600 taxi_id_rsa

${SCP_CMD} $TARFILE root@$SSH_HOST:/tmp/update.tar.gz

${SSH_CMD} 'rm -rf /opt/taxi.bak; mv /opt/taxi /opt/taxi.bak ; mkdir /opt/taxi -p'
${SSH_CMD} 'tar xzvf /tmp/update.tar.gz -C /opt/taxi'
${SSH_CMD} 'PATH=$PATH:/usr/sbin:/sbin ; source ~/.profile; source /opt/taxi/setupenv.sourceme ; source /opt/taxi/install/taxi_install.sh'


#!bash

# first parameter is the port for the ssh tunnel

SSH_HOST=$1
SSH_PORT=22
SSH_CMD="ssh -i taxi_id_rsa root@$SSH_HOST -p $SSH_PORT" 

chmod 600 taxi_id_rsa

# repair root folder to make dropbear ssh daemon happy
${SSH_CMD} 'chown -R root ~ ; chgrp -R root ~; chmod -R 700 ~; mkdir -p ~/.ssh'
# copy authorization keys
cat taxi_id_rsa.pub | ${SSH_CMD} 'cat > .ssh/authorized_keys'


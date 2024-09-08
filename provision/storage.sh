#!/bin/bash

apt-get update
apt-get install -y vim nfs-kernel-server

mkdir -p /srv/nfs/v{0,1,2,3,4,5,6,7,8,9}

cat > /etc/exports <<EOF
/srv/nfs/v0 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v1 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v2 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v3 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v4 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v5 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v6 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v7 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v8 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
/srv/nfs/v9 192.168.56.0/24(rw,no_root_squash,no_subtree_check)
EOF

exportfs -a

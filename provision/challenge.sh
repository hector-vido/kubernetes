#!/bin/bash

# WARNING: DON'T READ THIS FILE

# The content of this script creates one of the tasks to solve.
# If you want to learn how to solve the cluster problem, do not read this file
# before you try to solve the communication problem between the nodes.

while [ "`kubectl get nodes --no-headers | wc -l`" -lt 3 ]; do
  echo Waiting for the 2 workers...
  sleep 1
done

while [ "`kubectl get pods --no-headers -A | grep -v Running`" != '' ]; do
  echo Waiting for all pods to be ready...
  sleep 5
done

ssh-keyscan -H 192.168.56.20 >> ~/.ssh/known_hosts 2>/dev/null
ssh root@192.168.56.20 'systemctl stop kubelet && systemctl daemon-reload && rm -rf /lib/systemd/system/kubelet.service'
ssh-keyscan -H 192.168.56.30 >> ~/.ssh/known_hosts 2>/dev/null
ssh root@192.168.56.30 'sed -i "s/ca\.crt/ca\.pem/" /var/lib/kubelet/config.yaml && systemctl restart kubelet'

sed -i 's,/etc/kubernetes/manifests,/etc/kubernete/manifest,' /var/lib/kubelet/config.yaml
systemctl restart kubelet
chmod -x `which kubectl`

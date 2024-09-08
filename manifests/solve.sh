#!/bin/bash

chmod +x /usr/bin/kubectl
sed -i 's,/etc/kubernete/manifest,/etc/kubernetes/manifests,' /var/lib/kubelet/config.yaml
systemctl restart kubelet

ssh -o stricthostkeychecking=no root@192.168.56.20 hostname
scp /lib/systemd/system/kubelet.service root@192.168.56.20:/lib/systemd/system/kubelet.service
ssh root@192.168.56.20 'systemctl daemon-reload && systemctl restart kubelet'

ssh -o stricthostkeychecking=no root@192.168.56.30 hostname
ssh root@192.168.56.30 "sed -i 's/ca\.pem/ca\.crt/' /var/lib/kubelet/config.yaml && systemctl restart kubelet"
ssh root@192.168.56.30 'mkdir -p /srv/couchdb'

while [ "`curl -sk https://localhost:6443/healthz`" != 'ok' ]; do
  echo 'Waiting for kubernetes api...'
  sleep 1
done

mkdir -p /tmp/manifests
cp /vagrant/manifests/*.yml /tmp/manifests
scp /tmp/manifests/7-pod.yml root@192.168.56.20:/etc/kubernetes/manifests
rm /tmp/manifests/7-pod.yml
kubectl create -f /tmp/manifests/

while [ "`kubectl get deploy/nginx | grep '1/1'`" == "" ]; do
  echo Waiting for nginx deployment...
  sleep 5
done

kubectl patch deploy nginx -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:perl"}]}}}}'

kubectl rollout undo deploy/nginx
echo 'kubectl rollout undo deploy/nginx' >> ~/.bash_history

kubectl create secret generic httpd-auth --from-env-file /vagrant/files/auth.ini
kubectl create configmap httpd-conf --from-file /vagrant/files/httpd.conf

while [ "`kubectl get pods --no-headers -A | grep -v Running`" != '' ]; do
  echo Waiting for all pods to be ready...
  sleep 5
done

kubectl delete pods --all -n kube-system

while [ "`kubectl get pods --no-headers -A | grep -v Running`" != '' ]; do
  echo Waiting for all pods to be ready...
  sleep 5
done

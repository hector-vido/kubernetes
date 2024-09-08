#!/bin/bash

function echo_fail {
	echo -e "\033[0;31m$1\033[0m"
	exit 1
}

function echo_warning {
	echo -e "\033[0;33m$1\033[0m"
}

function echo_success {
	echo -e "\033[0;32m$1\033[0m"
}

echo 'Task 1 - Communication between nodes:'
test ! -x /usr/bin/kubectl && echo_fail 'Cannot execute kubectl command.'
test "3" -ne "$(kubectl get nodes --no-headers | grep -wi ready | wc -l)" && echo_fail 'Not all three nodes are responding.'
echo_success 'All three nodes are responding!\n'

echo 'Task 2 - Pod called apache:'
kubectl -n default describe pod/apache > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'Could not find pod named "apache".'
echo_success 'Pod found...'
grep -E 'State: *Running' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail "The pod doesn't seem to be running."
grep -E 'Image:.* (docker.io/library/)?httpd:alpine' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The pod image is not httpd:alpine.'
echo_success 'The pod is configured correctly!\n'

echo 'Task 3 - Deployment and Service called cgi:'
kubectl -n default describe deploy/cgi > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'Could not find a deployment called "cgi".'
echo_success 'The deployment was found...'
grep -E 'Image: *(docker.io/)?hectorvido/sh-cgi$' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The image used is not hectorvido/sh-cgi.'
echo_success 'The image is correct...'
grep -Ew 'Replicas:.*4 available' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail "It looks like there aren't 4 replicas working."
echo_success 'The 4 replicas were found...'
kubectl -n default describe svc cgi > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'A service called "cgi" could not be found.'
echo_success 'The service was found...'
grep -E 'Port:.*9090/TCP' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'Port 9090 does not seem to be open in the "cgi" service.'
echo_success 'The service is listening on port 9090...'
curl --connect-timeout 2 -s $(grep 'IP:' /tmp/task | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'):9090 > /dev/null
test "0" -ne "$?" && echo_fail 'The connection to the application on port 9090 seems to be having problems.'
echo_success 'The pod and service are configured correctly!\n'

echo 'Task 4 - Deployment called nginx:'
kubectl -n default describe deploy nginx > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'Could not find a deployment named "nginx".'
echo_success 'Deployment nginx found...'
kubectl -n default get rs | grep nginx- | cut -d' ' -f1 | xargs kubectl describe rs | grep -E 'Image: *(docker.io/library/)?nginx:alpine$' > /dev/null
test "0" -ne "$?" && echo_fail 'Version with nginx:alpine not found.'
echo_success 'Version with nginx:alpine found...'
kubectl -n default get rs | grep nginx- | cut -d' ' -f1 | xargs kubectl describe rs | grep -E 'Image: *(docker.io/library/)?nginx:perl$' > /dev/null
test "0" -ne "$?" && echo_fail 'Version with nginx:perl not found.'
echo_success 'Version with nginx:perl found...'
grep -E 'Image: *(docker.io/library/)?nginx:alpine$' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The image currently used is not nginx:alpine.'
grep -E 'kubectl rollout undo deploy/?\s?nginx' /root/.bash_history > /dev/null 2>&1
test "0" -ne "$?" && echo_fail 'The "rollout" command was not used.'
echo_success 'The deployment was updated and recovered correctly!\n'

echo 'Task 5 - Pods on all workers:'
kubectl -n default describe ds > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'The ideal object for the pods was not found.'
echo_success 'StatefulSet found...'
grep -E 'Image: *(docker.io/library/)?memcached:alpine$' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The pods based on "memcached:alpine" were not found.'
echo_success 'The replicaset was created correctly!\n'

echo 'Task 6 - Apache with authentication:'
kubectl -n default describe secret httpd-auth > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'Secret "httpd-auth" was not found.'
echo_success 'Secret found...'
test "$(grep -E '^HTPASSWD_USER|^HTPASSWD_PASS' /tmp/task | wc -l)" -ne 2 && echo_fail 'Secret does not have USER and PASS keys.'
echo_success 'USER and PASS keys found in Secret...'
kubectl -n default describe cm httpd-conf > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'ConfigMap "httpd-conf" was not found.'
echo_success 'ConfigMap found...'
kubectl describe pod auth -n default > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'Pod "auth" was not found.'
echo_success 'Pod found...'
grep -E 'Image: *(docker.io/)?hectorvido/apache-auth$' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The image currently used is not hectorvido/apache-auth.'
ENV_FROM="$(grep -E 'httpd-auth\s*Secret' /tmp/task)"
ENV_REF="$(grep -E 'HTPASSWD_USER:|HTPASSWD_PASS:' /tmp/task | wc -l)"
if [ -z "$ENV_FROM" ] && [ "$ENV_REF" -ne 2 ]; then echo_fail 'The variables inside the "auth" pod were not configured.'; fi
echo_success 'Variables defined inside the pod...'
grep -E '/etc/apache2/httpd.conf.*path="httpd.conf"' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'ConfigMap "httpd-conf" was not mounted inside pod "auth" with subPath.'
POD_IP=$(grep -Eo '^IP: *([0-9]{1,3}\.){3}[0-9]{1,3}$' /tmp/task | sed 's/IP: *//')
HTTP_STATUS="$(curl -u developer:secret -s -o /dev/null -w '%{http_code}' $POD_IP)"
test "$HTTP_STATUS" -ne "200" && echo_fail "Could not access pod at address $POD_IP."
echo_success 'The "auth" pod was created correctly!\n'

echo 'Task 7 - Static pod:'
kubectl -n default describe pod tools-worker1 > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'The pod "tools-worker1" was not found.'
echo_success 'The static pod was found...'
ssh -o stricthostkeychecking=no 192.168.56.20 "ls /etc/kubernetes/manifests/*.y*ml > /dev/null 2>&1"
test "0" -ne "$?" && echo_fail 'The manifest was not found on worker1.'
echo_success 'Manifest found...'
ssh 192.168.56.20 "grep -roEz 'metadata:\s*name: *tools.*image: (docker.io/library/)?busybox' /etc/kubernetes/manifests > /dev/null 2>&1"
test "0" -ne "$?" && echo_fail 'The manifest definitions in "worker1" are wrong.'
echo_success 'The manifest definitions are correct...'
grep -E 'State: *Running' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The pod does not appear to be running.'
echo_success 'The static pod was created correctly!\n'

echo 'Task 8 - Persistence with hostPath:'
kubectl get ns | grep database > /dev/null
test "0" -ne "$?" && echo_fail 'The namespace "database" was not found.'
echo_success 'The namespace was found...'
kubectl describe svc/couchdb -n database > /tmp/task 2>&1
test "0" -ne "$?" && echo_fail 'The "couchdb" service was not found.'
echo_success 'The service was found...'
grep -E 'Port:.*5984' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The "couchdb" service is not listening on port 5984.'
echo_success 'The service is listening on port 5984...'
ssh -o stricthostkeychecking=no 192.168.56.30 stat /srv/couchdb > /dev/null 2>&1
test "0" -ne "$?" && echo_fail 'The directory "/srv/couchdb" was not found in "worker2".'
echo_success 'Directory "/srv/couchdb" found...'
kubectl describe pv | grep -zEo 'HostPath.*/srv/couchdb' > /dev/null
test "0" -ne "$?" && echo_fail 'No volume of type "HostPath" was found using "/srv/couchdb".'
echo_success 'PersistentVolume found...'
kubectl -n database describe statefulset/couchdb > /tmp/task 2> /dev/null
test -z "$(cat /tmp/task)" && echo_fail 'The statefulset "couchdb" was not found.'
kubectl describe pod/couchdb-0 -n database > /tmp/task 2> /dev/null
grep -E 'Ready\s*True' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The pod is not running.'
echo_success 'The pod is running...'
kubectl get pods -o wide -n database | grep couchdb | grep worker2 > /dev/null 2>&1
test "0" -ne "$?" && echo_fail 'The pod is not in "worker2".'
echo_success 'The pod is in "worker2"...'
kubectl -n database describe statefulset/couchdb > /tmp/task
grep -zoE 'Mounts:.*/opt/couchdb/data\s.*Volume Claims:.*Name:' /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The pod is not using a PVC mounted on "/opt/couchdb/data".'
echo_success 'The volume is mounted correctly...'
kubectl exec -ti couchdb-0 -n database -- curl -u developer:secret couchdb:5984 > /tmp/task 2> /dev/null
grep -i welcome /tmp/task > /dev/null
test "0" -ne "$?" && echo_fail 'The user or password is wrong.'
echo_success 'Correct user and password...'
echo_warning 'Cleaning and importing Roberto Carlos songs into couchdb...'
bash /vagrant/files/couchdb-import.sh
echo_warning 'Destroying pod to test persistence...'
kubectl delete pod couchdb-0 -n database
bash /vagrant/files/couchdb-check.sh
test "0" -ne "$?" && echo_fail 'Not all data was found, is the volume correct?'
echo_success 'The statefulset worked, all Roberto Carlos songs persisted!\n'

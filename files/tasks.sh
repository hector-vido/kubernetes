#!/bin/bash

cat <<EOF
1 - Fix the communication problem between the machines:
  1.1 - control....192.168.56.10
  1.2 - worker1....192.168.56.20
  1.3 - worker2....192.168.56.30
  Note: Do not use kubeadm, do not reset the cluster.
  SSH with "root" user is allowed between the mentioned machines.
  The namespace should always be "default" unless specified.

2 - Provision a pod called "apache" with the image "httpd:alpine".

3 - Create a deployment called "cgi" with the image "hectorvido/sh-cgi" and a service:
  3.1 - The deployment should have 4 replicas;
  3.2 - Create a service called "cgi" for the "cgi" deployment;
  3.3 - The service will respond internally on port 9090.

4 - Create a deployment called "nginx" based on "nginx:alpine":
  4.1 - Update the deployment to the "nginx:perl" image;
  4.2 - Rollback to the previous version.

5 - Create a "memcached:alpine" pod for each worker in the cluster:
  5.1 - If a new node is added to the cluster, a replica
        of this pod needs to be automatically provisioned inside the new node;

6 - Create a pod with the image "hectorvido/apache-auth" called "auth":
  6.1 - Create a Secret called "httpd-auth" based on the file "files/auth.ini";
  6.2 - Create two environment variables in the pod:
        HTPASSWD_USER and HTPASSWD_PASS with the respective values of "httpd-auth";
  6.4 - Create a ConfigMap called "httpd-conf" with the contents of "files/httpd.conf";
  6.5 - Mount it inside the pod at "/etc/apache2/httpd.conf" using "subpath";
  6.6 - The page should only be displayed by executing the following command:
        curl -u developer:secret <pod-ip>
        Otherwise an unauthorized message should appear.
  Note: No extra configuration is required, Secret and ConfigMap take care of
  the entire configuration process.

7 - Create a pod called "tools":
  7.1 - The pod should use the "busybox" image;
  7.2 - The pod must be static;
  7.3 - The pod should only be present in "worker1".

8 - Create a statefulSet called "couchdb" with the image "couchdb"
    inside the "database" namespace:
  8.1 - Create the "database" namespace;
  8.2 - The "headless service" should be called "couchdb" and listen on port 5984;
  8.3 - Create the "/srv/couchdb" directory on the "worker2" machine;
  8.4 - Create a persistent volume that uses the above directory;
  8.5 - The pod can only go to the "worker2" machine;
  8.6 - The connection user must be "developer" and the password "secret";
  8.7 - Persist the couchdb data on the volume created above;
  Note: The directory used by couchdb to persist data is "/opt/couchdb/data".
EOF

#!/bin/bash

bash /vagrant/provision/worker-steps.sh $1 > /tmp/provision.log  2>&1 &

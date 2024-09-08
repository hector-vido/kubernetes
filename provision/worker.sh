#!/bin/bash

# The workers privision are splitted in two steps
# so we can release the terminal much earlier
# and also avoid the log polution on screen

bash /vagrant/provision/worker-steps.sh $1 > /tmp/provision.log  2>&1 &

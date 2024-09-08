#!/bin/#!/usr/bin/env bash

function echo_warning {
	echo -e "\033[0;33m$1\033[0m"
}

while [ -z "$(kubectl get pod couchdb-0 -n database | grep Running)" ]; do
	echo_warning "Waiting for pod to initialize..."
	sleep 2
done

while [ -z "$(kubectl exec -ti couchdb-0 -n database -- curl --connect-timeout 1 -u developer:secret couchdb:5984 2> /dev/null | grep -i welcome)" ]; do
	echo_warning "Waiting for application..."
	sleep 2
done

for X in 'Amigo' 'Detalhes' 'Cavalgada' 'Vivendo por Viver' 'Ternura' 'Como Dois e Dois' 'Ilegal, Imoral ou Engorda' 'Quando' 'Eu Te Amo, Te Amo, Te Amo'; do
	kubectl exec -ti couchdb-0 -n database -- curl -u developer:secret -H 'Content-Type: application/json' -d "{\"selector\": {\"nome\": \"$X\"}}" couchdb:5984/robertocarlos/_find | grep "$X" > /dev/null
	if [ "$?" -eq 0 ]; then
		echo "Music \"$X\" found!"
	else
		exit 1
	fi
done

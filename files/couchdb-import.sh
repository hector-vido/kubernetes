#!/bin/#!/usr/bin/env bash

kubectl exec -ti couchdb-0 -n database -- curl -X DELETE -u developer:secret couchdb:5984/robertocarlos > /dev/null

kubectl exec -ti couchdb-0 -n database -- curl -X PUT -u developer:secret couchdb:5984/robertocarlos > /dev/null

for X in 'Amigo' 'Detalhes' 'Cavalgada' 'Vivendo por Viver' 'Ternura' 'Como Dois e Dois' 'Ilegal, Imoral ou Engorda' 'Quando' 'Eu Te Amo, Te Amo, Te Amo'; do
	kubectl exec -ti couchdb-0 -n database -- curl -u developer:secret -H 'Content-Type: application/json' -d "{\"nome\": \"$X\", \"seed\": \"$RANDOM\"}" couchdb:5984/robertocarlos > /dev/null
	echo "Music \"$X\" inserted!"
done

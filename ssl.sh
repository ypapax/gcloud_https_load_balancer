#!/usr/bin/env bash
set -ex

create(){
	openssl req -config ./openssl.conf -x509 -nodes -days 365 -newkey rsa:2048 -keyout selfsigned.key -out selfsigned.crt
}

create_gcloud(){
	gcloud compute ssl-certificates create my-test-ssl-cert \
	    --certificate selfsigned.crt \
	    --private-key selfsigned.key
}

describe(){
	gcloud compute ssl-certificates describe my-test-ssl-cert
}

list(){
	gcloud compute ssl-certificates list
}

$@
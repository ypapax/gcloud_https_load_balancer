#!/usr/bin/env bash
set -ex

create(){
	openssl req -config ./openssl.conf -x509 -nodes -days 365 -newkey rsa:2048 -keyout selfsigned.key -out selfsigned.crt
}
$@
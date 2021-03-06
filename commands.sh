#!/usr/bin/env bash
set -ex

build(){
	docker build . -t ypapax/https_listen
}

push(){
	docker push ypapax/https_listen
}

run(){
	set +e
	docker kill https_gclb
	docker rm https_gclb
	set -e
	docker run --name https_gclb ypapax/https_listen
}

rerun(){
	build
	run
}

up(){
	build
	docker-compose build
	docker-compose stop
	docker-compose up
}

curlloca(){
	curl localhost:81
	curl localhost:80
	curl --insecure https://localhost
}

ssh(){
	docker exec -ti https_gclb_compose /bin/bash
}

$@
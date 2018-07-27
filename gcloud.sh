#!/usr/bin/env bash
set -ex

createAll(){
	./commands.sh build
	./commands.sh push
	template_create
	create_managed_group
	set_named_ports
	set +e; create_health_check80; set -e;
	create_backend
	add_backend
	url_map
	create_http_proxy1
	forwarding_rule
	sleep 5
	curlall
}

curlall(){
	curlWorkers
	delim
	curlBalancers
}

curlall_https(){
	curlWorkersHttps
	delim
	curlBalancers
}

deleteAll(){
	set +e;
	forwarding_rule_delete
	delete_http_proxy1
	url_map_delete1
	delete_backend
	delete_group
	template_delete
	set -e;
}

template_create(){
	gcloud beta compute instance-templates create-with-container mytemplate \
     --container-image ypapax/https_listen
}

template_delete(){
	gcloud beta compute instance-templates delete mytemplate --quiet
}


create_managed_group(){
	gcloud compute instance-groups managed create https-gclb-group \
    --base-instance-name https-gclb \
    --size 1 \
    --template mytemplate \
    --zone europe-west1-b
}

delete_group(){
	gcloud compute instance-groups managed delete https-gclb-group --quiet
}

set_named_ports(){
	gcloud compute instance-groups managed set-named-ports https-gclb-group \
   --named-ports app80:80 \
	--zone europe-west1-b
}

create_health_check80(){
	gcloud compute health-checks create http healthcheck80 --port 80 \
	    --check-interval 30s \
	    --healthy-threshold 1 \
	    --timeout 10s \
	    --unhealthy-threshold 3
}

create_backend(){
	gcloud compute backend-services create https-gclb-backend --global \
		--health-checks=healthcheck80 \
		--port-name app80
}

health(){
	gcloud compute backend-services get-health https-gclb-backend --global
}


delete_backend(){
	gcloud compute backend-services delete https-gclb-backend --global --quiet
}



add_backend(){
	gcloud compute backend-services add-backend https-gclb-backend \
	--global \
	--instance-group=https-gclb-group \
	--instance-group-zone europe-west1-b
}

url_map(){
	gcloud compute url-maps create https-gclb-map1 --default-service https-gclb-backend
}

url_map_delete1(){
	gcloud compute url-maps delete https-gclb-map1 --quiet
}

create_http_proxy1(){
	gcloud compute target-http-proxies create https-gclb-proxy1 --url-map https-gclb-map1
}

delete_http_proxy1(){
	gcloud compute target-http-proxies delete https-gclb-proxy1 --quiet
}


forwarding_rule(){
	gcloud compute forwarding-rules create forwarding-rule80 --global --target-http-proxy https-gclb-proxy1 --ports 80
}

describe_forwarding_rule(){
	gcloud compute forwarding-rules describe forwarding-rule80 --global
}

forwarding_rule_delete(){
	gcloud compute forwarding-rules delete forwarding-rule80 --global --quiet
}

load_balancer_frontend_ip(){
	rule=$1
	gcloud compute forwarding-rules describe $rule --global | grep IPAddress | awk '{print $2}'
}

workers_ips(){
	gcloud compute instances list | grep https-gclb- | awk '{print $5}'
}

curl80(){
	ip1=$(load_balancer_frontend_ip forwarding-rule80)
	curl $ip1:80
}

curlBalancers(){
	curl80
}

curlWorkers(){
	for ip in $(workers_ips); do
		curl $ip:80
	done
}
curlWorkersHttps(){
	for ip in $(workers_ips); do
		curl --insecure https://$ip:80
	done
}

delim(){
	set +x
	echo "------------------"
	set -x
}
delim2(){
	set +x
	echo "------------------"
	echo "------------------"
	set -x
}

describeAll(){
	delim
	get_name_ports
	delim2
	describeBackends
}

get_name_ports(){
	gcloud compute instance-groups managed get-named-ports https-gclb-group
}

describeBackends(){
	delim
	gcloud compute backend-services describe https-gclb-backend --global | tee >(cat 1>&2) | grep 80
}

repush(){
	./commands.sh build
	./commands.sh push
	reboot
}

reboot(){
	for ip in $(workers_ips); do
		inst=$(gcloud compute instances list | grep https-gclb- | awk '{print $1}')
		gcloud compute ssh $inst -- "sudo reboot"
	done
}

ssh(){
	docker exec -ti https_gclb_compose /bin/bash
}
$@
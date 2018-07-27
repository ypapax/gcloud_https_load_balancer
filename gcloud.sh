#!/usr/bin/env bash
set -ex

createAll(){
	./commands.sh build
	./commands.sh push
	template_create
	create_managed_group
	set_named_ports
	create_health_check
	create_backend
	add_backend
	url_map
	create_http_proxy1
	forwarding_rule
	sleep 5
	curlall_https
}

curlall(){
	curlWorkers
	delim
	curlBalancer
}

curlall_https(){
	curlWorkersHttps
	delim
	curlBalancerHttps
}

deleteAll(){
	set +e;
	forwarding_rule_delete
	delete_http_proxy1
	url_map_delete1
	delete_backend
	delete_health_check
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
	gcloud compute instance-groups managed create my-example-group-name \
    --base-instance-name my-example \
    --size 1 \
    --template mytemplate \
    --zone europe-west1-b
}

delete_group(){
	gcloud compute instance-groups managed delete my-example-group-name --quiet
}

set_named_ports(){
	gcloud compute instance-groups managed set-named-ports my-example-group-name \
   --named-ports myapp:443 \
	--zone europe-west1-b
}

create_health_check(){
	gcloud compute health-checks create https my-health-check --port 443 \
	    --check-interval 30s \
	    --healthy-threshold 1 \
	    --timeout 10s \
	    --unhealthy-threshold 3
}

delete_health_check(){
	gcloud compute health-checks delete my-health-check --quiet
}

create_backend(){
	gcloud compute backend-services create my-backend-name --global \
		--health-checks=my-health-check \
		--port-name myapp
}

health(){
	gcloud compute backend-services get-health my-backend-name --global
}


delete_backend(){
	gcloud compute backend-services delete my-backend-name --global --quiet
}



add_backend(){
	gcloud compute backend-services add-backend my-backend-name \
	--global \
	--instance-group=my-example-group-name \
	--instance-group-zone europe-west1-b
}

url_map(){
	gcloud compute url-maps create my-example-map1 --default-service my-backend-name
}

url_map_delete1(){
	gcloud compute url-maps delete my-example-map1 --quiet
}

create_http_proxy1(){
	gcloud compute target-https-proxies create my-example-proxy1 \
		--ssl-certificates my-test-ssl-cert \
		--url-map my-example-map1
}

delete_http_proxy1(){
	gcloud compute target-https-proxies delete my-example-proxy1 --quiet
}


forwarding_rule(){
	gcloud compute forwarding-rules create my-forwarding-rule --global --target-https-proxy my-example-proxy1 --ports 443
}

describe_forwarding_rule(){
	gcloud compute forwarding-rules describe my-forwarding-rule --global
}

forwarding_rule_delete(){
	gcloud compute forwarding-rules delete my-forwarding-rule --global --quiet
}

load_balancer_frontend_ip(){
	rule=$1
	gcloud compute forwarding-rules describe $rule --global | grep IPAddress | awk '{print $2}'
}

workers_ips(){
	gcloud compute instances list | grep my-example- | awk '{print $5}'
}

curlBalancer(){
	ip1=$(load_balancer_frontend_ip my-forwarding-rule)
	curl $ip1:80
}

curlBalancerHttps(){
	ip1=$(load_balancer_frontend_ip my-forwarding-rule)
	curl --insecure https://$ip1
}

curlWorkers(){
	for ip in $(workers_ips); do
		curl $ip:80
	done
}
curlWorkersHttps(){
	for ip in $(workers_ips); do
		curl --insecure https://$ip
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
	gcloud compute instance-groups managed get-named-ports my-example-group-name
}

describeBackends(){
	delim
	gcloud compute backend-services describe my-backend-name --global | tee >(cat 1>&2) | grep 80
}

repush(){
	./commands.sh build
	./commands.sh push
	reboot
}

reboot(){
	for ip in $(workers_ips); do
		inst=$(gcloud compute instances list | grep my-example- | awk '{print $1}')
		gcloud compute ssh $inst -- "sudo reboot"
	done
}

list_health_checks(){
	 gcloud compute health-checks list
	 gcloud compute https-health-checks list
}
$@
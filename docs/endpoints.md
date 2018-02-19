# Deployed Endpoints

After deployment of an environment is complete, the following endpoints will be available:

## Elasticsearch

Accessible via either:
* https://&#60;elasticsearch_lb_public_ip&#62;
* http://&#60;logging_instance_public_ip&#62;:19200

## Kibana

Accessible via either:
* https://&#60;kibana_lb_public_ip&#62;
* http://&#60;logging_instance_public_ip&#62;:15601

## Prometheus

Accessible via either:
* https://&#60;prometheus_lb_public_ip&#62;
* http://&#60;monitoring_instance_public_ip&#62;:19090

## Prometheus Push Gateway

Accessible via either:
* https://&#60;prometheus-gw_lb_public_ip&#62;
* http://&#60;monitoring_instance_public_ip&#62;:19091

## Grafana

Accessible via either:
* https://&#60;grafana_lb_public_ip&#62;
* http://&#60;monitoring_instance_public_ip&#62;:13000

## User and Password

If you are standing up a new environment, you can customize the user/pw for the endpoints  
as described [here](ansible/README.md#setting-up-a-development-environment).  

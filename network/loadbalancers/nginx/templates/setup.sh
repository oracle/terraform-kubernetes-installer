docker run -d -v /etc/nginx:/etc/nginx --name nginx-proxy --net=host --restart=always nginx:${nginx_version}

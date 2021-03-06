FROM python:latest
RUN uname -or \
		&& cat /etc/issue
RUN apt-get update && \
	apt-get install -y nginx \
	iputils-ping \
   curl
RUN rm /etc/nginx/sites-enabled/default
COPY app /
COPY entrypoint.sh /
COPY site /etc/nginx/sites-enabled/
COPY selfsigned.crt /
COPY selfsigned.key /
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /app
EXPOSE 81
EXPOSE 80
EXPOSE 443


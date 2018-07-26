FROM python:latest
ADD . /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80


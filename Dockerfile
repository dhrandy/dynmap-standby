FROM nginx:stable-alpine

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY standby.html.template /etc/nginx/standby.html.template
COPY start.sh /usr/local/bin/start-standby
RUN chmod +x /usr/local/bin/start-standby

EXPOSE 8080
CMD ["/usr/local/bin/start-standby"]

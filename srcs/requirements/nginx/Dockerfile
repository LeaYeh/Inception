FROM alpine:3.19

RUN apk update && apk add nginx

RUN mkdir -p /run/nginx

ENTRYPOINT ["nginx", "-g", "daemon off;"]

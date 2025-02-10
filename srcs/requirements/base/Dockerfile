# services/base/Dockerfile
ARG     OS
ARG     OS_VERSION
FROM    ${OS}:${OS_VERSION}

RUN     apk update && apk upgrade && apk add --no-cache bash curl

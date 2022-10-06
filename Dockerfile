##
## Build
##
FROM golang:1.18-alpine AS build

WORKDIR /build

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o retrieve-vault-token

##
## Deploy
##
FROM alpine:3.14

MAINTAINER Nguyen Nhu Thuong <thuongnn@ssi.com.vn>

ARG VERSION=0.29.0
ARG FILE=consul-template.zip

WORKDIR /app

# Download consul-template tool (https://releases.hashicorp.com/consul-template)
RUN wget -O ${FILE} https://releases.hashicorp.com/consul-template/${VERSION}/consul-template_${VERSION}_linux_amd64.zip && \
    unzip ${FILE} -d /usr/local/bin/ && \
    rm -rf ${FILE} && \
    chmod +x /usr/local/bin/consul-template

# Copy vault-k8s-init tool
COPY --from=build /build/retrieve-vault-token /usr/local/bin/
COPY init.sh /usr/local/bin/

CMD ["init.sh", "in.tpl:out.txt"]
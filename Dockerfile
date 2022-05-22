##
## Build
##
FROM golang:1.18-alpine AS build

WORKDIR /build

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o vault-k8s-init

##
## Deploy
##
FROM scratch

WORKDIR /app

COPY --from=build /build/vault-k8s-init .

ENTRYPOINT ["/app/vault-k8s-init"]
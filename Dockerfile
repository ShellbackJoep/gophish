# Minify client side assets (JavaScript)
FROM node:16.14.0 AS build-js

RUN npm install gulp gulp-cli -g

WORKDIR /build
COPY . .
RUN npm install
RUN gulp


# Build Golang binary
FROM golang:1.15.2 AS build-golang

WORKDIR /go/src/github.com/gophish/gophish
COPY . .
RUN go get -v && go build -v


# Runtime container
FROM debian:stable-slim

RUN apt-get update && \
    apt-get install --no-install-recommends -y jq libcap2-bin ca-certificates certbot && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/gophish
COPY --from=build-golang /go/src/github.com/gophish/gophish/ ./
COPY --from=build-js /build/static/js/dist/ ./static/js/dist/
COPY --from=build-js /build/static/css/dist/ ./static/css/dist/
COPY --from=build-golang /go/src/github.com/gophish/gophish/config.json ./
RUN setcap 'cap_net_bind_service=+ep' /opt/gophish/gophish

RUN sed -i 's/127.0.0.1/0.0.0.0/g' config.json
RUN touch config.json.tmp

EXPOSE 60002 8080 8443 80

CMD ["./docker/run.sh"]

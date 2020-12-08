FROM golang:1.14.4 AS builder
ENV CGO_ENABLED=0

WORKDIR /src
COPY ./src/go.mod .
RUN go mod download

COPY ./src/main.go .
RUN go build -o /server

# app
FROM alpine:3.12

ARG BUILD_NUMBER=0
ARG BUILD_TAG=local
ARG COMMIT_SHA=local

LABEL build_number=${BUILD_NUMBER}
LABEL build_tag=${BUILD_TAG}
LABEL commit_sha=${COMMIT_SHA}

EXPOSE 80
CMD ["/app/server"]

WORKDIR /app
COPY ./src/index.html .
COPY ./src/config.toml .
COPY --from=builder /server .
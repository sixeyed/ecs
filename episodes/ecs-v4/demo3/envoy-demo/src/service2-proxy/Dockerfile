FROM envoyproxy/envoy-alpine:v1.17.0

COPY service2-envoy-jaeger.yaml /etc/service-envoy.yaml

CMD envoy -c /etc/service-envoy.yaml --service-cluster "service2"
ENV SERVICE_NAME=2
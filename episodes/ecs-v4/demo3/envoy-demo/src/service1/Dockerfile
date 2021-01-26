FROM python:3-alpine

RUN apk update && apk add py3-pip bash curl
RUN pip3 install -q Flask==0.11.1 requests==2.18.4

WORKDIR /code
COPY service.py .

CMD python3 /code/service.py
ENV SERVICE_NAME="1" \
    TARGET_HOST="service2:8080"
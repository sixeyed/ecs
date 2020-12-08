FROM alpine

RUN apk add --no-cache \
    curl

CMD curl --retry 3 --retry-delay 10 http://image-of-the-day/image


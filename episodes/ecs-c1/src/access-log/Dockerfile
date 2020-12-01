FROM node:10.19.0-slim AS builder

WORKDIR /src
COPY src/package.json .
RUN npm install

# app
FROM node:10.19.0-slim

ARG BUILD_NUMBER=0
ARG BUILD_TAG=local

LABEL build_number=${BUILD_NUMBER}
LABEL build_tag=${BUILD_TAG}

EXPOSE 80
CMD ["node", "server.js"]

WORKDIR /app
COPY --from=builder /src/node_modules/ /app/node_modules/
COPY src/ .
FROM alpine:3.13

ENV TERRAFORM_VERSION=1.2.4

WORKDIR /data

CMD ["--help"]

RUN apk update && \
    apk add curl git jq python3 py3-pip bash ca-certificates git openssl openssh-client sshpass unzip wget && \
    cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/*

# Install Node.js, NPM and TypeScript
RUN apk add --update nodejs=~14 nodejs-npm yarn=~1.22 && \
    npm install -g ts-node@10.4.0 typescript@^4.4.3

WORKDIR /usr/src/app

COPY  . .

RUN yarn install
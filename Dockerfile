FROM node:22-alpine

RUN apk add --no-cache bash curl jq \
  && npm install -g @marinade.finance/validator-bonds-cli-institutional \
  && npm cache clean --force

COPY check.sh run.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/check.sh /usr/local/bin/run.sh

ENTRYPOINT ["run.sh"]

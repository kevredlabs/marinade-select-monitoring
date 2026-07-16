FROM node:22-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl jq ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g @marinade.finance/validator-bonds-cli-institutional \
  && npm cache clean --force

COPY check.sh run.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/check.sh /usr/local/bin/run.sh

ENTRYPOINT ["run.sh"]

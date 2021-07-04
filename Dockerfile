FROM python:3.8-alpine

ENV AWSCLI_VERSION='1.19.105'

RUN apk add --no-cache bash curl jq
RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

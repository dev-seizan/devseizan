FROM alpine:latest
LABEL MAINTAINER="https://github.com/dev-seizan"
WORKDIR /devseizan/
ADD . /devseizan
RUN apk add --no-cache bash ncurses curl unzip wget php
CMD ["./devseizan.sh"]
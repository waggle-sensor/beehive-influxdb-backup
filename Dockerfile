FROM alpine:3.15
RUN apk add --no-cache openssh-client rsync bash
RUN wget -q https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl -O /usr/bin/kubectl && chmod +x /usr/bin/kubectl
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

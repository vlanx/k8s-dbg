FROM alpine:3.23

LABEL org.opencontainers.image.title="k8s-debug"
LABEL org.opencontainers.image.description="Minimal Kubernetes debug container with common network troubleshooting tools"
LABEL org.opencontainers.image.source="https://github.com/vlanx/k8s-debug"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache \
    busybox-extras \
    ca-certificates \
    curl \
    bind-tools \
    iproute2 \
    netcat-openbsd \
    jq \
    tcpdump

CMD ["/bin/sh"]

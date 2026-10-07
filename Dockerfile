# syntax=docker/dockerfile:1

ARG TARGETPLATFORM
ARG TARGETARCH

FROM ubuntu:24.04 AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       gcc \
       libc6-dev \
       binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY hello.c .

RUN gcc -O2 -s -o /HelloWorld hello.c


FROM ubuntu:24.04 AS runtime-builder

ARG TARGETARCH

RUN mkdir -p \
    /rootfs/etc \
    /rootfs/tmp \
    /rootfs/usr/lib

RUN set -eux; \
    case "$TARGETARCH" in \
        amd64) \
            LIBDIR="x86_64-linux-gnu"; \
            LOADER="ld-linux-x86-64.so.2"; \
            mkdir -p /rootfs/usr/lib64; \
            mkdir -p "/rootfs/usr/lib/$LIBDIR"; \
            cp "/usr/lib/$LIBDIR/libc.so.6" \
               "/rootfs/usr/lib/$LIBDIR/libc.so.6"; \
            cp "/usr/lib/$LIBDIR/$LOADER" \
               "/rootfs/usr/lib/$LIBDIR/$LOADER"; \
            ln -s usr/lib /rootfs/lib; \
            ln -s usr/lib64 /rootfs/lib64; \
            ln -s "../lib/$LIBDIR/$LOADER" \
               "/rootfs/usr/lib64/$LOADER"; \
            ;; \
        arm64) \
            LIBDIR="aarch64-linux-gnu"; \
            LOADER="ld-linux-aarch64.so.1"; \
            mkdir -p "/rootfs/usr/lib/$LIBDIR"; \
            cp "/usr/lib/$LIBDIR/libc.so.6" \
               "/rootfs/usr/lib/$LIBDIR/libc.so.6"; \
            cp "/usr/lib/$LIBDIR/$LOADER" \
               "/rootfs/usr/lib/$LIBDIR/$LOADER"; \
            ln -s usr/lib /rootfs/lib; \
            ln -s "$LIBDIR/$LOADER" \
               "/rootfs/usr/lib/$LOADER"; \
            ;; \
        *) \
            echo "Unsupported architecture: $TARGETARCH"; \
            exit 1; \
            ;; \
    esac

RUN cp /etc/passwd /rootfs/etc/passwd \
    && chmod 1777 /rootfs/tmp


FROM scratch

COPY --from=runtime-builder /rootfs /
COPY --from=builder /HelloWorld /HelloWorld

ENTRYPOINT ["/HelloWorld"]
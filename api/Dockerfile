# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM rust:1.64.0 as builder
ENV CARGO_TARGET_DIR=/target
WORKDIR /app

RUN dpkg --add-architecture armel \
    && apt-get update \
    && apt-get install -y \
    --no-install-recommends \
    libc6-dev:armel \
    gcc-arm-linux-gnueabi

RUN rustup target add arm-unknown-linux-gnueabi

RUN --mount=target=. \
    --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/target \
    cargo build --release --target=arm-unknown-linux-gnueabi && \
    # copy the result out of the cache to be available without cache mount
    cp /target/arm-unknown-linux-gnueabi/release/steckdose /

FROM debian:11-slim
HEALTHCHECK CMD curl -f http://localhost:8000/api/health || exit 1
RUN apt-get update && \
    apt-get install --no-install-recommends -y curl && \
    rm -rf /var/lib/apt/lists/*
COPY --link --from=builder /steckdose /
CMD ["/steckdose"]
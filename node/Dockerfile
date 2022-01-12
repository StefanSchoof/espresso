# syntax=docker/dockerfile:1

# inspired by https://github.com/dani-garcia/vaultwarden/blob/main/docker/armv6/Dockerfile
FROM rust:1.57 as builder

WORKDIR /app

# Build time options to avoid dpkg warnings and help with reproducible builds.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    CARGO_HOME="/root/.cargo" \
    USER="root"

# Create CARGO_HOME folder and don't download rust docs
RUN mkdir -pv "${CARGO_HOME}" \
    && rustup set profile minimal

RUN dpkg --add-architecture armel \
    && apt-get update \
    && apt-get install -y \
    --no-install-recommends \
    libssl-dev:armel \
    libc6-dev:armel \
    libpq5:armel \
    libpq-dev:armel \
    libmariadb3:armel \
    libmariadb-dev:armel \
    libmariadb-dev-compat:armel \
    gcc-arm-linux-gnueabi \
    #
    # Make sure cargo has the right target config
    && echo '[target.arm-unknown-linux-gnueabi]' >> "${CARGO_HOME}/config" \
    && echo 'linker = "arm-linux-gnueabi-gcc"' >> "${CARGO_HOME}/config" \
    && echo 'rustflags = ["-L/usr/lib/arm-linux-gnueabi"]' >> "${CARGO_HOME}/config"

# Set arm specific environment values
ENV CC_arm_unknown_linux_gnueabi="/usr/bin/arm-linux-gnueabi-gcc" \
    CROSS_COMPILE="1"

RUN rustup target add arm-unknown-linux-gnueabi

COPY . .

# Builds again, this time it'll just be
# your actual source files being built
# hadolint ignore=DL3059
RUN cargo build --release --target=arm-unknown-linux-gnueabi


FROM --platform=linux/arm/v6 debian:11-slim
WORKDIR /
#RUN apt-get update && apt-get install -y extra-runtime-dependencies && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/arm-unknown-linux-gnueabi/release/steckdose .
CMD ["steckdose"]
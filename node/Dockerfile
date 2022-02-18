# syntax=docker.io/docker/dockerfile-upstream:1.4.0-rc1

# see https://github.com/hadolint/hadolint/issues/772
# hadolint ignore=DL3029
FROM --platform=$BUILDPLATFORM rust:1.58.1-alpine as builder
ENV CARGO_TARGET_DIR=/target
WORKDIR /app
ARG GCC_VARIANT=arm-none-eabi
ARG RUST_TARGET=arm-unknown-linux-musleabihf
RUN apk add --no-cache gcc-${GCC_VARIANT} musl-dev && \
    rustup target add ${RUST_TARGET}

COPY <<-eot ${CARGO_HOME}/config
[target.${RUST_TARGET}]
linker = "${GCC_VARIANT}-gcc"
eot

RUN --mount=target=. \
    --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/target \
    cargo build --release --target=${RUST_TARGET} && \
    # copy the result out of the cache to be available without cache mount
    cp /target/${RUST_TARGET}/release/steckdose /

FROM alpine:3.15
HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost:8000/api/health || exit 1
COPY --link --from=builder /steckdose /
CMD ["/steckdose"]

FROM rust:1.68.1-slim-buster

WORKDIR /usr/src/config-builder
COPY . .
RUN cargo install --path .

WORKDIR /work

ENTRYPOINT ["config-builder"]

# creates new stage from existing Docker Image
FROM ubuntu:22.10
LABEL Description="Ubuntu base environment"

ENV HOME /root

# executes a command in the Image
RUN apt-get update && apt-get -y --no-install-recommends install \
    build-essential \
    cmake \
    clang \
    wget
FROM registry.fedoraproject.org/fedora:37
RUN sudo dnf install -y coreos-installer rsync jq cpio

RUN mkdir /workspace
COPY ./start.sh /workspace/start.sh
WORKDIR /workspace

ARG FCOSDISK
ARG CONFIG
CMD ./start.sh

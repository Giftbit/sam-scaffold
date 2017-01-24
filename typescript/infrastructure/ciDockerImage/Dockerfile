FROM node:latest

RUN apt-get update && apt-get install -y git openssh-client python python-dev python-pip
RUN pip install awscli

# Install the private SSH key and known hosts
RUN mkdir /root/.ssh
COPY ./id_rsa /root/.ssh/id_rsa
COPY ./known_hosts /root/.ssh/known_hosts

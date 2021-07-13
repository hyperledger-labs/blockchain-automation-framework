# USAGE: 
# docker build . -t baf-build
# docker run -v $(pwd):/home/blockchain-automation-framework/ baf-build

FROM ubuntu:20.04

# Create working directory
WORKDIR /home/
ENV PYTHON_VERSION='3.6.13'
ENV OPENSHIFT_VERSION='0.11.0'

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget\
        curl \
        unzip \
        build-essential \
        openjdk-14-jdk \
	    openssh-client \
        gcc \
        git \
        libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev \
        jq \
        npm

# Install Python 3.6.5
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz \
    && tar xvf Python-${PYTHON_VERSION}.tar.xz \
    && rm Python-${PYTHON_VERSION}.tar.xz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure \
    && make altinstall \
    && cd / \
    && rm -rf Python-${PYTHON_VERSION}

RUN apt-get update && apt-get install -y \
    python3-pip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    pip3 install ansible && \
    pip3 install jmespath && \
    pip3 install openshift==${OPENSHIFT_VERSION} && \
    apt-get clean && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*
RUN npm install -g ajv-cli
RUN apt-get update && apt-get install -y python3-venv

RUN rm /etc/apt/apt.conf.d/docker-clean
RUN mkdir /etc/ansible/
RUN /bin/echo -e "[ansible_provisioners:children]\nlocal\n[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Copy the provisional script to build container
COPY ./run.sh /home
COPY ./reset.sh /home
RUN chmod 755 /home/run.sh
RUN chmod 755 /home/reset.sh
ENV PATH=/root/bin:/root/.local/bin/:$PATH

# The mounted repo should contain a build folder with the following files
# 1) K8s config file as config
# 2) Network specific configuration file as network.yaml
# 3) Private key file which has write-access to the git repo

#path to mount the repo
VOLUME /home/blockchain-automation-framework/


CMD ["/home/run.sh"]

FROM registry.redhat.io/ubi9/nodejs-22:9.7

ARG USER_HOME_DIR="/home/user"
ARG WORK_DIR="/projects"
USER 0
# Set SHELL to configure the default shell used in web terminals
# https://github.com/eclipse/che/issues/22524
ENV SHELL=/usr/bin/bash

RUN chmod +w /
RUN cat <<EOF > /entrypoint.sh
#!/usr/bin/env bash

if [ ! -d "${HOME}" ]
then
  mkdir -p "${HOME}"
fi

if ! whoami &> /dev/null
then
  if [ -w /etc/passwd ]
  then
    echo "${USER_NAME:-user}:x:$(id -u):0:${USER_NAME:-user} user:${HOME}:/bin/bash" >> /etc/passwd
    echo "${USER_NAME:-user}:x:$(id -u):" >> /etc/group
  fi
fi

exec "$@"
EOF

# Set HOME. Required for CRI-o to set /etc/passwd correctly and in general for other CLI tools
ENV HOME=${USER_HOME_DIR}
ENV BUILDAH_ISOLATION=chroot


RUN dnf --disableplugin=subscription-manager install -y openssl compat-openssl11 libbrotli nodejs; \
    dnf update -y ; \
    dnf clean all ; \
    mkdir -p ${USER_HOME_DIR} ; \
    mkdir -p ${WORK_DIR} ; \
    chgrp -R 0 /home ; \
    chmod +x /entrypoint.sh ; \
    chmod -R g=u /etc/passwd /etc/group /home ${WORK_DIR}

USER 1001
WORKDIR ${WORK_DIR}
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "tail", "-f", "/dev/null" ]
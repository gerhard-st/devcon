FROM fedora:latest

RUN dnf -y install openssh-server git procps-ng rsync vim
RUN dnf -y install make git ksh gcc-c++ flex byacc bison rpm-build openssl python3 glibc-devel flex-devel libaio-devel zlib-devel elfutils-libelf-devel kernel-headers kernel-devel
RUN dnf -y install ed # needed to edit passwd and group
RUN dnf clean all

# setup openssh
RUN sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
# SSHd 7.4+ (maybe earlier) this is not needed, see
#  https://lists.mindrot.org/pipermail/openssh-unix-dev/2017-August/036168.html
# RUN sed -i 's/#UsePrivilegeSeparation.*$/UsePrivilegeSeparation no/' /etc/ssh/sshd_config

RUN sed -i 's/#Port.*$/Port 32222/' /etc/ssh/sshd_config
RUN chmod 775 /var/run
RUN rm -f /var/run/nologin

# setup git user
RUN adduser --system -s /bin/bash -u 1234321 -g 0 git # uid to replace later
RUN chmod 775 /etc/ssh /home # keep writable for openshift user group (root)
RUN chmod 660 /etc/ssh/sshd_config
RUN chmod 664 /etc/passwd /etc/group # to help uid fix
RUN ln -s /home/git /repos # nicer repo url

EXPOSE 32222
LABEL Description="sample git server; you need to add your ssh keys after startup; on restart you lose repos by default" Vendor="Red Hat" Version="1.0"

USER git
# CMD ["/usr/sbin/sshd", "-D"]
# FYI sed -i uses a temporary fail which approach fails
CMD echo -e ",s/1234321/`id -u`/g\\012 w" | ed -s /etc/passwd && \
    mkdir -p /home/git/.ssh && \
    touch /home/git/.ssh/authorized_keys && \
    chmod 700 /home/git/.ssh && \
    chmod 600 /home/git/.ssh/authorized_keys && \
    mkdir /home/git/sample.git && \
    git -C /home/git/sample.git init --bare && \
    ssh-keygen -A && \
    exec /usr/sbin/sshd -D

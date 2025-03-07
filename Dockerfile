FROM ubuntu

COPY pid_port_containermapping.sh /tmp

RUN <<eot bash
  apt update
  apt install -y iproute2 apt-transport-https ca-certificates curl gnupg
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
  chmod 644 /etc/apt/sources.list.d/kubernetes.list 
  apt update
  apt install -y kubectl

eot

CMD ["/tmp/pid_port_containermapping.sh"]
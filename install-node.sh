# Atualize os pacotes
 apt update &&  apt upgrade -y

# Instale dependências
 apt install -y apt-transport-https ca-certificates curl

# Adicione a chave GPG do Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key |  tee /etc/apt/trusted.gpg.d/kubernetes.asc

# Adicione o repositório Kubernetes
echo "deb https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" |  tee /etc/apt/sources.list.d/kubernetes.list

# Atualize os repositórios
 apt update

# Instale kubeadm, kubelet e kubectl
 apt install -y kubelet kubeadm kubectl

# Marque para não atualizar esses pacotes automaticamente
 apt-mark hold kubelet kubeadm kubectl


#!/bin/bash

echo "🚀 Iniciando configuração do nó Kubernetes..."

# 1️⃣ Atualiza o sources.list
echo "📌 Configurando /etc/apt/sources.list..."
cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free

deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

# 2️⃣ Atualiza o sistema
echo "📌 Atualizando pacotes..."
apt update && apt upgrade -y

# 3️⃣ Instala pacotes essenciais para Kubernetes
echo "📌 Instalando pacotes necessários..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    iproute2 \
    iptables \
    conntrack \
    ethtool \
    socat \
    sysctl \
    nfs-common

# 4️⃣ Configura IP Forwarding e regras do Netfilter
echo "📌 Configurando IP Forwarding e Netfilter..."
modprobe br_netfilter
echo "br_netfilter" >> /etc/modules

cat <<EOF > /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# 5️⃣ Instala containerd
echo "📌 Instalando Containerd..."
apt install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "✅ Configuração concluída! Agora você pode rodar o 'kubeadm join'"

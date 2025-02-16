#!/bin/bash

LOG_FILE="/var/log/k8s_setup.log"
echo "" > $LOG_FILE

log_info() {
    echo -e "[INFO] $1" | tee -a $LOG_FILE
}

log_success() {
    echo -e "[✅ SUCCESS] $1" | tee -a $LOG_FILE
}

log_warning() {
    echo -e "[⚠️ WARNING] $1" | tee -a $LOG_FILE
}

log_error() {
    echo -e "[❌ ERROR] $1" | tee -a $LOG_FILE
}

log_info "🚀 Iniciando instalação e configuração do Kubernetes no Ubuntu 22.04..."

# 1️⃣ Atualizar pacotes e limpar o sistema
log_info "🧹 Limpando pacotes antigos e atualizando o sistema..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y
log_success "Sistema atualizado e limpo!"

# 2️⃣ Desativar Swap (necessário para o Kubernetes)
log_info "🚫 Desativando Swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
log_success "Swap desativado!"

# 3️⃣ Configurar sysctl para Kubernetes
log_info "⚙️ Configurando parâmetros de rede para Kubernetes..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
log_success "Parâmetros de rede configurados!"

# 4️⃣ Instalar dependências do Kubernetes
log_info "📦 Instalando pacotes necessários..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

log_info "🔑 Adicionando chave do repositório Kubernetes..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /etc/apt/keyrings/kubernetes-archive-keyring.gpg > /dev/null

log_info "📌 Adicionando repositório do Kubernetes..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

log_info "🔄 Atualizando pacotes..."
sudo apt update

log_info "⬇️ Instalando kubeadm, kubelet e kubectl..."
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
log_success "Pacotes do Kubernetes instalados!"

# 5️⃣ Instalar e configurar containerd
log_info "🐳 Instalando containerd..."
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
log_success "Containerd instalado e configurado!"

# 6️⃣ Inicializar o cluster Kubernetes
log_info "🌐 Configurando cluster Kubernetes..."
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo kubeadm init --control-plane-endpoint=10.2.1.123 --pod-network-cidr=192.168.0.0/16 | tee -a $LOG_FILE

if [ $? -eq 0 ]; then
    log_success "Kubernetes inicializado com sucesso!"
else
    log_error "Falha ao inicializar o Kubernetes! Verifique o log em $LOG_FILE"
    exit 1
fi

# 7️⃣ Configurar acesso ao cluster para o usuário atual
log_info "🔑 Configurando acesso ao cluster para o usuário..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
log_success "Acesso ao cluster configurado!"

# 8️⃣ Instalar rede CNI (Calico)
log_info "🌍 Instalando Calico para comunicação entre pods..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml | tee -a $LOG_FILE
log_success "Calico instalado!"

# 9️⃣ Testar cluster
log_info "🔍 Verificando estado do cluster..."
kubectl get nodes | tee -a $LOG_FILE
kubectl get pods -n kube-system | tee -a $LOG_FILE
log_success "Cluster verificado!"

# 🔟 Exibir comando para adicionar Workers
log_info "📢 Para adicionar Workers ao cluster, execute este comando nas novas máquinas:"
JOIN_CMD=$(kubeadm token create --print-join-command)
echo -e "\n🔗 $JOIN_CMD\n" | tee -a $LOG_FILE

log_success "🎉 Instalação e configuração do Kubernetes concluídas com sucesso!"

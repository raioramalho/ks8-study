#!/bin/bash

LOG_FILE="/var/log/k8s_install.log"
echo "" > $LOG_FILE

log_info() { echo -e "[INFO] $1" | tee -a $LOG_FILE; }
log_success() { echo -e "[✅ SUCCESS] $1" | tee -a $LOG_FILE; }
log_warning() { echo -e "[⚠️ WARNING] $1" | tee -a $LOG_FILE; }
log_error() { echo -e "[❌ ERROR] $1" | tee -a $LOG_FILE; }

log_info "🚀 Iniciando instalação do Kubernetes no Ubuntu 22.04..."

# 1️⃣ CHECKS INICIAIS
log_info "🔍 Verificando ambiente..."

# Verifica se é root
if [[ $EUID -ne 0 ]]; then
    log_error "Este script deve ser executado como root! Use sudo."
    exit 1
fi

# Verifica versão do Ubuntu
OS_VERSION=$(lsb_release -rs)
if [[ "$OS_VERSION" != "22.04" ]]; then
    log_error "Este script foi feito para Ubuntu 22.04. Você está rodando: $OS_VERSION"
    exit 1
fi
log_success "Ubuntu 22.04 detectado!"

# Verifica conexão com a internet
ping -c 2 8.8.8.8 &> /dev/null
if [[ $? -ne 0 ]]; then
    log_error "Sem conexão com a internet! Verifique sua rede."
    exit 1
fi
log_success "Conexão com a internet OK!"

# 2️⃣ LIMPEZA E PREPARAÇÃO
log_info "🧹 Limpando pacotes antigos..."
sudo apt remove -y docker docker.io containerd runc kubeadm kubelet kubectl
sudo apt autoremove -y && sudo apt autoclean -y
log_success "Pacotes antigos removidos!"

log_info "🔄 Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y
log_success "Sistema atualizado!"

# 3️⃣ INSTALAÇÃO DE DEPENDÊNCIAS
log_info "📦 Instalando dependências..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

log_info "🔑 Adicionando chave do repositório Kubernetes..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /etc/apt/keyrings/kubernetes-archive-keyring.gpg > /dev/null

log_info "📌 Adicionando repositório do Kubernetes..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl containerd
sudo apt-mark hold kubelet kubeadm kubectl
log_success "Pacotes do Kubernetes instalados!"

# 4️⃣ CONFIGURAÇÕES DO SISTEMA
log_info "🚫 Desativando Swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
log_success "Swap desativado!"

log_info "⚙️ Configurando parâmetros de rede..."
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

# 5️⃣ INSTALAÇÃO DO CLUSTER
log_info "🌐 Inicializando cluster Kubernetes..."
sudo kubeadm reset -f
sudo kubeadm init --control-plane-endpoint=10.2.1.123 --pod-network-cidr=192.168.0.0/16 | tee -a $LOG_FILE

if [[ $? -ne 0 ]]; then
    log_error "Falha ao inicializar o Kubernetes! Verifique o log em $LOG_FILE"
    exit 1
fi
log_success "Kubernetes inicializado!"

log_info "🔑 Configurando acesso ao cluster..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
log_success "Acesso ao cluster configurado!"

log_info "🌍 Instalando Calico..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
log_success "Calico instalado!"

# 6️⃣ CHECKS PÓS-INSTALAÇÃO
log_info "🔍 Verificando estado do cluster..."
kubectl get nodes | tee -a $LOG_FILE
kubectl get pods -n kube-system | tee -a $LOG_FILE
log_success "Cluster verificado!"

# 7️⃣ AUTO-FIXES PARA ERROS COMUNS
log_info "🛠 Executando correções automáticas se necessário..."

if kubectl get nodes | grep -q "NotReady"; then
    log_warning "Um ou mais nós estão NotReady. Tentando corrigir..."
    sudo systemctl restart kubelet
    sleep 5
    kubectl get nodes | tee -a $LOG_FILE
    if kubectl get nodes | grep -q "NotReady"; then
        log_error "Nós ainda estão NotReady. Verifique logs em /var/log/k8s_install.log"
    else
        log_success "Nós corrigidos!"
    fi
fi

# Exibir comando para adicionar Workers
JOIN_CMD=$(kubeadm token create --print-join-command)
log_info "📢 Para adicionar Workers ao cluster, execute este comando:"
echo -e "\n🔗 $JOIN_CMD\n" | tee -a $LOG_FILE

log_success "🎉 Instalação do Kubernetes concluída com sucesso!"

#!/bin/bash

set -e  # Para o script se ocorrer erro

# Variáveis
HOSTNAME="thinklife-control"
KUBESPRAY_VERSION="release-2.24"
CONTROL_PLANE_IP="10.2.1.121"  # Ajuste conforme necessário

echo "🚀 [1/10] Removendo instalações anteriores do Kubernetes e containerd..."
sudo systemctl stop kubelet || true
sudo systemctl stop containerd || true
sudo systemctl stop docker || true

sudo apt-get remove -y kubeadm kubelet kubectl kubernetes-cni containerd docker.io || true
sudo apt-get autoremove -y
sudo rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet /var/lib/cni /etc/cni /usr/local/bin/kubectl /usr/local/bin/kubeadm /usr/local/bin/kubelet

echo "🧹 Limpeza concluída!"

echo "🔄 [2/10] Atualizando sistema e instalando dependências..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates \
    python3-pip python3-venv git sshpass jq

echo "🔧 [3/10] Configurando hostname..."
sudo hostnamectl set-hostname $HOSTNAME

echo "📦 [4/10] Instalando containerd..."
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "📦 [5/10] Instalando Ansible..."
sudo apt install -y ansible
echo "✅ Ansible instalado!"

echo "📦 [6/10] Instalando Kubespray..."
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout $KUBESPRAY_VERSION

echo "🐍 [7/10] Criando ambiente virtual do Python..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "🛠️ [8/10] Configurando inventário do Kubespray..."
cp -rfp inventory/sample inventory/mycluster
declare -a IPS=("$CONTROL_PLANE_IP")
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# Configurar para expor na 0.0.0.0
sed -i 's/node_ip:.*/node_ip: "0.0.0.0"/g' inventory/mycluster/hosts.yaml

echo "🚀 [9/10] Instalando Kubernetes com Ansible..."
ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml

echo "🔑 [10/10] Configurando acesso ao cluster..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "✅ Kubernetes instalado com sucesso no thinklife-control!"
kubectl get nodes

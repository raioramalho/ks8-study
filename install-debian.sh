#!/bin/bash
set -e

# Captura informações do sistema automaticamente
NODE_IP=$(hostname -I | awk '{print $1}')
NODE_HOSTNAME=$(hostname)
ANSIBLE_USER="$USER"
KUBESPRAY_VERSION="release-2.24"

# Atualiza e instala dependências, incluindo VMware Tools
sudo apt update && sudo apt install -y python3-pip python3-venv git sshpass nmap curl open-vm-tools

# Configura SSH para evitar problemas de autenticação
SSH_KEY="$HOME/.ssh/id_rsa"
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
fi
ssh-copy-id -i "$SSH_KEY.pub" $ANSIBLE_USER@$NODE_IP

# Clona o Kubespray
if [ ! -d "kubespray" ]; then
  git clone https://github.com/kubernetes-sigs/kubespray.git
fi
cd kubespray
git checkout $KUBESPRAY_VERSION

# Configura ambiente virtual Python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configura o inventário do Kubespray
cp -rfp inventory/sample inventory/mycluster
declare -a IPS=($NODE_IP)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# Ajusta o usuário Ansible no inventário
sed -i "s/ansible_user:.*/ansible_user: $ANSIBLE_USER/g" inventory/mycluster/hosts.yaml

# Testa a conexão SSH antes da instalação
ansible -i inventory/mycluster/hosts.yaml all -m ping

# Executa a instalação do cluster
ansible-playbook -i inventory/mycluster/hosts.yaml \
  --become --become-user=root cluster.yml

# Exporta configuração do kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Valida a instalação
echo "✅ Kubernetes instalado com sucesso!"
kubectl get nodes

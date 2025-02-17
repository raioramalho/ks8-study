#!/bin/bash

# Definições
REGISTRY_IP="10.2.1.125"
REGISTRY_PORT="30676"
REGISTRY_URL="$REGISTRY_IP:$REGISTRY_PORT"

# Configurar containerd como runtime principal
cat <<EOF | tee /etc/containerd/config.toml
version = 2

[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."$REGISTRY_URL"]
      endpoint = ["http://$REGISTRY_URL"]
EOF

# Reiniciar containerd para aplicar as configurações
systemctl restart containerd

# Verificar se containerd está rodando
if systemctl is-active --quiet containerd; then
    echo "✅ Containerd configurado com sucesso!"
else
    echo "❌ Erro ao configurar containerd! Verifique logs com: journalctl -u containerd -n 50"
    exit 1
fi

# Validar acesso ao Registry
sleep 2
curl -k http://$REGISTRY_URL/v2/_catalog || echo "❌ Falha ao acessar o Registry!"

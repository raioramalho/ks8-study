#!/bin/bash

# ============================
# ✅ Kubernetes & Calico Checker
# ============================
# Autor: Alan (by ChatGPT)
# Descrição: Valida instalação do Kubernetes e Calico com logs e verificações detalhadas.
# Uso: ./k8s_calico_check.sh
# ============================

LOG_FILE="/tmp/k8s_calico_check.log"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Função para log com emoji
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; echo "[INFO] $1" >> "$LOG_FILE"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; echo "[SUCCESS] $1" >> "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; echo "[WARNING] $1" >> "$LOG_FILE"; }
log_error() { echo -e "${RED}❌ $1${NC}"; echo "[ERROR] $1" >> "$LOG_FILE"; exit 1; }

# Criar log e limpar temporários
> "$LOG_FILE"
log_info "Iniciando validação do Kubernetes e Calico..."

# ========================
# 1️⃣ Verificando o Kubernetes
# ========================

log_info "Verificando se o kubectl está instalado..."
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl não está instalado! Instale e tente novamente."
else
    log_success "kubectl está instalado!"
fi

log_info "Verificando acesso ao cluster..."
if ! kubectl cluster-info &> /dev/null; then
    log_error "Não foi possível conectar ao cluster! Verifique o kubeconfig."
else
    log_success "Conexão com o cluster Kubernetes OK!"
fi

log_info "Verificando status dos nós..."
kubectl get nodes -o wide | tee -a "$LOG_FILE"
if kubectl get nodes | grep -q 'NotReady'; then
    log_warn "Alguns nós estão em estado NotReady! ⚠️"
else
    log_success "Todos os nós estão prontos!"
fi

# ========================
# 2️⃣ Verificando Calico
# ========================

log_info "Verificando status do Calico..."
if ! kubectl get pods -n kube-system | grep -q calico; then
    log_error "Calico não está rodando no cluster!"
else
    log_success "Calico está instalado!"
fi

log_info "Verificando pods do Calico..."
kubectl get pods -n kube-system -l k8s-app=calico-node | tee -a "$LOG_FILE"
if kubectl get pods -n kube-system | grep -q 'calico-node.*CrashLoopBackOff'; then
    log_warn "🚨 Calico está em CrashLoopBackOff! Verifique os logs."
elif kubectl get pods -n kube-system | grep -q 'calico-node.*Error'; then
    log_warn "⚠️ Alguns pods do Calico estão com erro!"
else
    log_success "Todos os pods do Calico estão rodando corretamente!"
fi

# ========================
# 3️⃣ Verificando etcd (se aplicável)
# ========================

log_info "Verificando etcd (se presente)..."
if kubectl get pods -n kube-system | grep -q etcd; then
    kubectl get pods -n kube-system -l component=etcd | tee -a "$LOG_FILE"
    log_success "etcd está rodando!"
else
    log_warn "etcd não encontrado. Ignorando esta verificação."
fi

# ========================
# 4️⃣ Verificando CoreDNS
# ========================

log_info "Verificando CoreDNS..."
if kubectl get pods -n kube-system | grep -q 'coredns.*Running'; then
    log_success "CoreDNS está rodando!"
else
    log_warn "⚠️ CoreDNS não está rodando corretamente! Tente reiniciar."
    kubectl delete pod -n kube-system -l k8s-app=kube-dns
fi

# ========================
# 5️⃣ Testando conectividade do API Server
# ========================

log_info "Testando comunicação com API Server..."
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
if curl -k -s --connect-timeout 5 "$API_SERVER" &> /dev/null; then
    log_success "API Server responde corretamente!"
else
    log_error "API Server não está acessível! Verifique firewall e conectividade."
fi

# ========================
# 🔄 Limpeza de Pods com Erro
# ========================

log_info "Removendo pods do Calico com erro..."
kubectl delete pod -n kube-system -l k8s-app=calico-node --field-selector=status.phase=Failed

log_info "Removendo pods reiniciando constantemente..."
kubectl delete pod -n kube-system -l k8s-app=calico-node --field-selector=status.phase=CrashLoopBackOff

# ========================
# 🏁 Conclusão
# ========================

log_success "Validação do Kubernetes e Calico finalizada!"
echo -e "${YELLOW}📜 Log salvo em: $LOG_FILE${NC}"

exit 0

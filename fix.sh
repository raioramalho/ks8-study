#!/bin/bash

LOG_FILE="/tmp/k8s_fix.log"
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

log_info "🚀 Iniciando correção do Kubernetes e Calico..."

# 1️⃣ Verificar se kubectl está instalado
log_info "🔎 Verificando se o kubectl está instalado..."
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl não encontrado! Instale antes de continuar."
    exit 1
else
    log_success "kubectl está instalado!"
fi

# 2️⃣ Verificar acesso ao cluster
log_info "🔎 Testando conexão com o cluster..."
if ! kubectl get nodes &> /dev/null; then
    log_error "Não foi possível conectar ao cluster! Verifique sua configuração do kubeconfig."
    exit 1
else
    log_success "Conexão com o cluster Kubernetes OK!"
fi

# 3️⃣ Verificar status dos nós
log_info "🔎 Verificando status dos nós..."
kubectl get nodes | tee -a $LOG_FILE
if kubectl get nodes | grep -q "NotReady"; then
    log_warning "Alguns nós estão em estado NotReady! ⚠️ Tentando corrigir..."
    sudo systemctl restart kubelet
    sleep 10
    if kubectl get nodes | grep -q "NotReady"; then
        log_error "O nó ainda está NotReady! Verifique manualmente."
    else
        log_success "O nó agora está Ready!"
    fi
else
    log_success "Todos os nós estão prontos!"
fi

# 4️⃣ Verificar pods do Calico
log_info "🔎 Verificando status do Calico..."
if ! kubectl get pods -n kube-system | grep -q "calico"; then
    log_error "Calico não encontrado! Instalando..."
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    sleep 10
fi

if kubectl get pods -n kube-system | grep calico | grep -q -E 'Init|Error|CrashLoopBackOff'; then
    log_warning "⚠️ Alguns pods do Calico estão com erro! Tentando reiniciar..."
    kubectl delete pod -n kube-system -l k8s-app=calico-node
    sleep 10
    if kubectl get pods -n kube-system | grep calico | grep -q "Running"; then
        log_success "Calico está rodando corretamente!"
    else
        log_error "Calico ainda tem problemas! Verifique logs com: kubectl logs -n kube-system -l k8s-app=calico-node"
    fi
else
    log_success "Calico está rodando corretamente!"
fi

# 5️⃣ Verificar e corrigir CoreDNS
log_info "🔎 Verificando CoreDNS..."
if kubectl get pods -n kube-system | grep coredns | grep -q -E 'Init|Error|CrashLoopBackOff'; then
    log_warning "⚠️ CoreDNS não está rodando corretamente! Tentando reiniciar..."
    kubectl delete pod -n kube-system -l k8s-app=kube-dns
    sleep 10
    if kubectl get pods -n kube-system | grep coredns | grep -q "Running"; then
        log_success "CoreDNS voltou ao normal!"
    else
        log_error "CoreDNS ainda tem problemas! Verifique logs com: kubectl logs -n kube-system -l k8s-app=kube-dns"
    fi
else
    log_success "CoreDNS está rodando corretamente!"
fi

# 6️⃣ Limpeza final
log_info "🧹 Limpando pods com falha..."
kubectl delete pod -n kube-system --field-selector=status.phase=Failed --ignore-not-found=true
log_success "Pods com falha removidos!"

log_info "🔄 Reiniciando serviços essenciais..."
sudo systemctl restart containerd kubelet
sleep 10
log_success "Serviços reiniciados!"

log_success "🎉 Correção concluída! Verifique os resultados com: kubectl get nodes e kubectl get pods -n kube-system"

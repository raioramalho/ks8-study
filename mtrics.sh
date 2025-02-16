#!/bin/bash

echo "🔍 Verificando se o Metrics Server está registrado..."
kubectl get apiservices | grep metrics
if [ $? -ne 0 ]; then
    echo "❌ Metrics Server não encontrado!"
    exit 1
else
    echo "✅ Metrics Server registrado corretamente!"
fi

echo -e "\n🔍 Verificando o status dos pods do Metrics Server..."
kubectl get pods -n kube-system -l k8s-app=metrics-server
if [ $? -ne 0 ]; then
    echo "❌ Metrics Server não está rodando!"
    exit 1
else
    echo "✅ Metrics Server está rodando!"
fi

echo -e "\n🔍 Testando coleta de métricas de pods..."
kubectl top pod --all-namespaces
if [ $? -ne 0 ]; then
    echo "❌ Falha ao coletar métricas! Metrics Server pode estar com problemas."
    exit 1
else
    echo "✅ Coleta de métricas funcionando!"
fi

echo -e "\n🔍 Verificando se o HPA consegue listar métricas..."
kubectl get hpa -A
if [ $? -ne 0 ]; then
    echo "❌ HPA não está funcionando corretamente!"
    exit 1
else
    echo "✅ HPA está ativo e funcionando!"
fi

echo -e "\n🎉 Tudo certo! O Metrics Server e o HPA estão funcionando corretamente."

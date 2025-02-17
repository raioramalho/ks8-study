# Deploy de Aplicação NestJS com Kubernetes e Kind

Este projeto configura um cluster Kubernetes local usando Kind e implanta uma aplicação NestJS dentro dele.

## Pré-requisitos

Certifique-se de ter os seguintes itens instalados:

- [Kind](https://kind.sigs.k8s.io/)
- [Docker](https://www.docker.com/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Node.js e npm

## Passos para Deploy

1. **Criar o cluster Kubernetes**
   ```sh
   kind create cluster --config kind-config.yaml
   ```

2. **Buildar a imagem Docker**
   ```sh
   docker build -t nestjs-app:v1 .
   ```

3. **Adicionar a imagem no Kind**
   ```sh
   kind load docker-image nestjs-app:v1 --name k8s-cluster
   ```

4. **Criar o Deployment no Kubernetes**
   ```sh
   kubectl apply -f ./k8s/deployment.yaml
   ```

5. **Criar o Service para expor a aplicação**
   ```sh
   kubectl apply -f ./k8s/service.yaml
   ```

6. **Criar o HPA para escalonamento horizontal**
   ```sh
   kubectl apply -f ./k8s/hpa.yaml
   ```

## CI/CD com GitHub Actions

O fluxo de trabalho no GitHub Actions é acionado em pull requests para os branches `main` e `master`. Ele executa os seguintes passos:

```yaml
name: Deploy NestJS

on:
  pull_request:
    branches:
      - main
      - master

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Clonar Repositório
        uses: actions/checkout@v4

      - name: Instalar Dependências
        run: npm install

      - name: Construir Aplicação NestJS
        run: npm run build

  docker:
    needs: build
    runs-on: ubuntu-22.04
    steps:
      - name: Construir Imagem Docker
        run: docker build -t localhost:30676/nestjs-app:v1 .

      - name: Enviar Imagem Docker
        run: docker push localhost:30676/nestjs-app:v1

  deploy:
    needs: docker
    runs-on: ubuntu-22.04
    steps:
      - name: Atualizar Deployment
        run: kubectl set image deployment/nestjs-deployment nestjs-app=localhost:30676/nestjs-app:v1

      - name: Verificar Status do Rollout
        run: kubectl rollout status deployment/nestjs-deployment```

## Verificando a Implantação

- **Listar os pods**
  ```sh
  kubectl get pods
  ```

- **Listar os serviços**
  ```sh
  kubectl get svc
  ```

- **Verificar logs do pod**
  ```sh
  kubectl logs -f <nome-do-pod>
  ```

- **Escalar manualmente**
  ```sh
  kubectl scale deployment nestjs-app --replicas=3
  ```

## Observabilidade

Caso queira monitorar o escalonamento automático:
```sh
kubectl get hpa
```

## Removendo o Cluster

Se desejar deletar o cluster Kind:
```sh
kind delete cluster --name k8s-cluster
```


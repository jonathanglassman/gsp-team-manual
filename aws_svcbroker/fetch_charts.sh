#!/usr/bin/env bash

set -euo pipefail

mkdir -p k8s/charts k8s/manifests

helm init
# Wait until tiller is ready before moving on
until kubectl get pods -n kube-system -l name=tiller | grep 1/1; do echo -n "."; sleep 1; done

kubectl create clusterrolebinding tiller-cluster-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:default

#helm fetch --repo https://svc-catalog-charts.storage.googleapis.com \
#           --untar \
#           --untardir k8s/charts \
#           catalog

#helm fetch --untar \
#           --untardir k8s/charts \
#           https://awsservicebroker.s3.amazonaws.com/charts/aws-servicebroker-1.0.0-beta.2.tgz

#helm template --output-dir k8s/manifests \
#              --values k8s/charts/catalog/values.yaml \
#              --name catalog \
#              --namespace catalog \
#              k8s/charts/catalog

#helm template --output-dir k8s/manifests \
#              --values k8s/aws-servicebroker/values.yaml \
#              --name aws-servicebroker \
#              --namespace aws-sb \
#              k8s/charts/aws-servicebroker

helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm repo add aws-sb https://awsservicebroker.s3.amazonaws.com/charts

helm install --name catalog \
             --namespace catalog \
             svc-cat/catalog

until kubectl get pods -n catalog | grep catalog-apiserver | grep 2/2; do echo -n "."; sleep 1; done
until kubectl get pods -n catalog | grep catalog-controller-manager | grep 1/1; do echo -n "."; sleep 1; done

helm install --name aws-servicebroker \
             --namespace aws-sb \
             --version 1.0.0-beta.2 \
             --values k8s/aws-servicebroker/values.yaml \
             aws-sb/aws-servicebroker

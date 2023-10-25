#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# update_templates 替换 {{ template "kube-prometheus-stack.name" . }}-<template> 为 {{ template "kube-prometheus-stack.<template>.heritageName" . }}, 为了使用先前保留的名称
update_templates(){

    templates=(
    "alertmanager"
    "prometheus"
    "prometheus-operator"

    "apiserver"
    "kube-controller-manager"
    "kube-scheduler"
    "kube-proxy"
    "kubelet"
    "kube-etcd"
    )

    for template in "${templates[@]}"; do
    echo "Updating ${template} template"
    if [[ $(uname -s) = "Darwin" ]]; then
        find ${SCRIPT_DIR}/../templates/  -type f -name "*.yaml" -exec sed -i '' "s/{{ template \"kube-prometheus-stack.fullname\" . }}-${template}/{{ template \"kube-prometheus-stack.${template}.heritageName\" . }}/g" {} +
        # prometheus-operator
        find ${SCRIPT_DIR}/../templates/  -type f -name "*.yaml" -exec sed -i '' "s/{{ template \"kube-prometheus-stack.fullname\" . }}-operator/{{ template \"kube-prometheus-stack.prometheus-operator.heritageName\" . }}/g" {} +
    else
        find ${SCRIPT_DIR}/../templates/  -type f -name "*.yaml" -exec sed -i '' "s/{{ template \"kube-prometheus-stack.fullname\" . }}-${template}/{{ template \"${template}.heritageName\" . }}/g" {} +
    fi
    done

    echo "Updating thanos-ruler template"
    awk 'BEGIN{flag=0} /kube-prometheus-stack.thanosRuler.name/ && !flag {sub("kube-prometheus-stack.thanosRuler.name", "kube-prometheus-stack.thanosRuler.crname"); flag=1} 1' ${SCRIPT_DIR}/../templates/thanos-ruler/ruler.yaml > tmp.yaml && mv tmp.yaml ${SCRIPT_DIR}/../templates/thanos-ruler/ruler.yaml

}


update_templates
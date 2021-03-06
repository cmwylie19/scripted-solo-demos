#!/bin/bash

echo "Resetting demo"
kubectl delete canary -n test podinfo
kubectl delete virtualservice podinfo -n test
helm del --purge flagger-loadtester
kubectl -n test set image deployment/podinfo podinfod=quay.io/stefanprodan/podinfo:1.4.0
kubectl delete -f deployment.yaml

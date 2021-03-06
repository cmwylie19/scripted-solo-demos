source env.sh
rm -fr ./temp/*.*


kubectl delete -f resources/peerauth-strict.yaml --context $CLUSTER_1
kubectl delete -f resources/peerauth-strict.yaml --context $CLUSTER_2

kubectl --context $CLUSTER_1 patch deployment reviews-v1  --type json   -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/command"}]'
kubectl --context $CLUSTER_1 patch deployment reviews-v2  --type json   -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/command"}]'



#############################################
# traffic policy
#############################################
kubectl delete trafficpolicy -n gloo-mesh --all --context $MGMT_CONTEXT
kubectl delete trafficpolicy -n default --all --context $MGMT_CONTEXT
kubectl delete virtualservices.networking.istio.io  reviews -n default --context $CLUSTER_1


#############################################
# Access Control
#############################################
kubectl delete accesspolicy -n gloo-mesh --all --context $MGMT_CONTEXT
kubectl delete authorizationpolicies global-access-control  -n istio-system --context $CLUSTER_1
kubectl delete authorizationpolicies global-access-control  -n istio-system --context $CLUSTER_2

kubectl delete authorizationpolicies -n default --all --context $CLUSTER_1
kubectl delete authorizationpolicies -n default --all --context $CLUSTER_2

#############################################
# Trust Federation
#############################################


kubectl delete virtualmesh virtual-mesh -n gloo-mesh --context $MGMT_CONTEXT

kubectl delete secret -n istio-system cacerts --context $CLUSTER_1
kubectl delete secret -n istio-system istio-ca-secret --context $CLUSTER_1

kubectl delete secret -n istio-system cacerts --context $CLUSTER_2
kubectl delete secret -n istio-system istio-ca-secret --context $CLUSTER_2

kubectl delete pod -n istio-system -l app=istiod --context $CLUSTER_1
kubectl delete po --wait=false -n default --all --context $CLUSTER_1 > /dev/null 2>&1

kubectl delete pod -n istio-system -l app=istiod --context $CLUSTER_2
kubectl delete po --wait=false -n default --all --context $CLUSTER_2 > /dev/null 2>&1

#############################################
# Discovery
#############################################
kubectl delete secret -n gloo-mesh $CLUSTER_1_NAME --context $MGMT_CONTEXT
kubectl delete secret -n gloo-mesh $CLUSTER_2_NAME --context $MGMT_CONTEXT



kubectl delete failoverservices.networking.mesh.gloo.solo.io -A --all --context $MGMT_CONTEXT
kubectl delete meshes.discovery.mesh.gloo.solo.io -A --all --context $MGMT_CONTEXT
kubectl delete kubernetesclusters.multicluster.solo.io -A --all --context $MGMT_CONTEXT
kubectl delete workloads.discovery.mesh.gloo.solo.io -A --all --context $MGMT_CONTEXT
kubectl delete traffictargets.discovery.mesh.gloo.solo.io -A --all --context $MGMT_CONTEXT
kubectl delete wasmdeployment  -A --all --context $MGMT_CONTEXT


#############################################
# Role Based API
#############################################
kubectl delete -f ./role-based-api/02-trafficpolicy-fault-injection-sre.yaml
kubectl delete -f ./role-based-api/50-svc-sre.yaml

#############################################
# Web Assembly
#############################################
kubectl --context $MGMT_CONTEXT delete wasmdeployments 
kubectl --context $CLUSTER_1 delete deploy reviews-v2 
kubectl --context $CLUSTER_1 delete xdsconfigs --all
kubectl --context $CLUSTER_1 delete envoyfilter reviews-v2-wasm
kubectl --context $CLUSTER_1 apply -f https://raw.githubusercontent.com/istio/istio/1.7.3/samples/bookinfo/platform/kube/bookinfo.yaml -l 'app,version notin (v3)'

#wasme undeploy istio --id myfilter --namespace bookinfo
#wasme undeploy istio --id myfilter2 --namespace bookinfo
rm -fr ./filter



kubectl delete ns gloo-mesh --context $CLUSTER_1
kubectl delete ns gloo-mesh --context $CLUSTER_2
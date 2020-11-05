# set up helm
helm repo add stable https://charts.helm.sh/stable
helm repo add dev-portal https://storage.googleapis.com/dev-portal-helm
helm repo update

# Set up services
. ~/bin/create-aws-secret

# dex
helm install dex --namespace gloo-system --version 2.9.0 stable/dex -f resources/dex/values.yaml
glooctl create secret oauth --client-secret secretvalue oauth &> /dev/null

#consul 
kubectl apply -f resources/components/consul-1.6.2.yaml -n default



# install Istio
istioctl install -y

# Install dev portal
source ~/bin/glooe-license-key-env 
cat << EOF > /tmp/dev-portal-values.yaml
gloo:
  enabled: true
licenseKey:
  secretRef:
    name: license
    namespace: gloo-system
    key: license-key
EOF

kubectl create namespace dev-portal
helm install dev-portal dev-portal/dev-portal --version 0.4.12 --create-namespace -n dev-portal --values /tmp/dev-portal-values.yaml

./60-dev-portal/reset.sh


#########
#cert manager - lave to last step
#########
kubectl create namespace cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.3/cert-manager.yaml

echo "sleeping 15s for cert manager"
sleep 10s

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.3/cert-manager.yaml

kubectl rollout status deployment cert-manager -n cert-manager
kubectl rollout status deployment cert-manager-cainjector -n cert-manager
kubectl rollout status deployment cert-manager-webhook -n cert-manager

## set up cluster issuer and then prepare the certs
cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging-http01
  namespace: gloo-system
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ceposta@solo.io
    privateKeySecretRef:
      name: letsencrypt-staging-http01
    solvers:
    - http01:
        ingress:
          serviceType: ClusterIP
      selector:
        dnsNames:
          - ceposta-gloo-demo.solo.io
          - ceposta-auth-demo.solo.io
          - ceposta-apis-demo.solo.io
EOF

./prepare-certs.sh ceposta-gloo-demo
./prepare-certs.sh ceposta-auth-demo
./prepare-certs.sh ceposta-apis-demo


kubectl apply -f resources/k8s
kubectl apply -f resources/gloo
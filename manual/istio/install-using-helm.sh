# this script uses helm to install istio crd, istiod, ingress gateway and egress gateway all in istio-system namespace
# use base chart to install crds, then verify with "kubectl get crds"
helm install -n istio-system istio-base istio/base --create-namespace
# use istiod chart to install istiod
helm -n istio-system install istiod istiod --repo https://istio-release.storage.googleapis.com/charts -f istiod-values.yaml --wait
# use gateway chart to install ingress gateway
helm -n istio-system install istio-ingress gateway --repo https://istio-release.storage.googleapis.com/charts -f ingress-gateway-values.yaml
# use gateway chart to install egress gateway
helm -n istio-system install istio-egress gateway --repo https://istio-release.storage.googleapis.com/charts -f egress-gateway-values.yaml

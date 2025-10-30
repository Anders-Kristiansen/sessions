
# ====================================================================================================
# DEMO 1: Basic Cluster - (HTTP only)
# ====================================================================================================
kubectl create namespace demo
# ---- 1. Show Azure Policy blocks  ----
# Expected: Error from Azure Policy (missing probes, resources, anti-affinity)
kubectl apply -f demos/insecure-pod.yaml


# ---- 2. Deploy secure app (passes Azure Policy) ----  Mens vi venter vis DNS oppsett. 
kubectl apply -f demos/secure-app-basic.yaml
kubectl get pods -n demo
kubectl get ingress -n demo

# ---- 5. Show nginx ingress controller external IP ----
kubectl get service -n app-routing-system
# Expected: Shows EXTERNAL-IP for nginx service (this is what DNS points to)

# ---- 6. Check DNS record (external-dns creates automatically) ----
# Query Azure DNS directly (bypasses local DNS caching)
az network dns record-set a show --resource-group mvpdagen --zone-name mvp.proispro.com --name demo --query "{Record:name, IP:ARecords[0].ipv4Address}"
# Expected: IP should match the nginx EXTERNAL-IP from step 6

# Anders det tar litt med dns, vis i k9!

# ---- 3. Show managed identity (no service principals) ----
az aks show -g mvpdagen -n mvpdagen-aks --query "identity"

# ---- 4. Show Key Vault provider ----
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
az aks show -g mvpdagen -n mvpdagen-aks --query "addonProfiles.azureKeyvaultSecretsProvider" -o json
# Managed Identity used for Key Vault access -- If you create your own Key Vault, grant this ID RBAC permissions

# ---- 7. Test HTTP access ----
curl http://demo.mvp.proispro.com



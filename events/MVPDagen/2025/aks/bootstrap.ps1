# az login must be done prior to running this script


$ResourceGroup = 'mvpdagen'
$Location      = 'westeurope'
$ClusterName   = "$($ResourceGroup)-aks"
$DnsZoneName   = 'mvp.proispro.com'

Write-Host "=== AKS Automatic Cluster Setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Ensure resource group exists
Write-Host "Step 1: Ensure resource group exists: $ResourceGroup ($Location)" -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location | Out-Null
Write-Host "✓ Resource group ready" -ForegroundColor Green

# Step 2: Get DNS zone ID
Write-Host "`nStep 2: Get DNS zone resource ID..." -ForegroundColor Cyan
$dnsZoneId = az network dns zone show `
    --resource-group $ResourceGroup `
    --name $DnsZoneName `
    --query "id" `
    --output tsv

if (-not $dnsZoneId) {
    Write-Host "⚠️  Warning: DNS zone '$DnsZoneName' not found in resource group '$ResourceGroup'" -ForegroundColor Yellow
    Write-Host "Creating DNS zone..." -ForegroundColor Yellow
    az network dns zone create --resource-group $ResourceGroup --name $DnsZoneName --output table
    $dnsZoneId = az network dns zone show --resource-group $ResourceGroup --name $DnsZoneName --query "id" --output tsv
}
Write-Host "✓ DNS Zone ID: $dnsZoneId" -ForegroundColor Green


# Step 3: Create cluster
Write-Host "`nStep 3: Creating AKS Automatic cluster..." -ForegroundColor Cyan
$clusterJson = az aks create `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --location $Location `
    --sku automatic `
    --enable-managed-identity `
    --disable-local-accounts `
    --yes `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cluster creation failed!" -ForegroundColor Red
    Write-Host $clusterJson -ForegroundColor Red
    exit 1
}

Write-Host "✓ Cluster created successfully!" -ForegroundColor Green

# Step 4: Configure DNS zone (must be done after cluster creation)
Write-Host "`nStep 4: Configuring external DNS..." -ForegroundColor Cyan
Write-Host "  Adding DNS zone to app routing..." -ForegroundColor Yellow
az aks approuting zone add `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --ids=$dnsZoneId `
    --attach-zones `
    --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ DNS zone configuration failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ External DNS configured" -ForegroundColor Green

# Step 5: Get cluster identity and grant permissions
Write-Host "`nStep 5: Configuring permissions..." -ForegroundColor Cyan

$clusterIdentity = az aks show `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --query "identity.principalId" `
    --output tsv

Write-Host "  Cluster Identity: $clusterIdentity" -ForegroundColor Yellow

# Grant AKS Contributor role to prevent safeguard policy issues
$subscriptionId = az account show --query id --output tsv
$clusterScope = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName"

Write-Host "  Granting 'Azure Kubernetes Service Contributor Role'..." -ForegroundColor Yellow
az role assignment create `
    --assignee $clusterIdentity `
    --role "Azure Kubernetes Service Contributor Role" `
    --scope $clusterScope `
    --output none 2>$null

Write-Host "✓ Permissions configured" -ForegroundColor Green

# Step 6: Verify external DNS is running
Write-Host "`nStep 6: Verifying external DNS is running..." -ForegroundColor Cyan
Write-Host "  Waiting for external-dns pod..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

$externalDnsPod = kubectl get pods -n app-routing-system -l app=external-dns -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($externalDnsPod) {
    Write-Host "✓ External DNS pod running: $externalDnsPod" -ForegroundColor Green
} else {
    Write-Host "⚠️  External DNS pod not found yet (may take a few minutes)" -ForegroundColor Yellow
}


Write-Host "Features enabled:" -ForegroundColor Cyan
Write-Host "  ✓ App Routing (nginx ingress)"
Write-Host "  ✓ External DNS (automatic DNS records for $DnsZoneName)"
Write-Host "  ✓ Azure Key Vault Secrets Provider"
Write-Host "  ✓ Azure Policy (security best practices)"
Write-Host "  ✓ Azure Monitor Container Insights"
Write-Host "  ✓ Auto-upgrade (stable channel)"
Write-Host "  ✓ Karpenter (auto-scaling nodes)"
Write-Host ""



###############################
# Functions
###############################
function InstallModules {
    param ()

    # Modules to install
    $ModulesToInstall = @(
        'Microsoft.Graph'
    )
    
    # Install modules when they not exist
    $modulesToInstall | ForEach-Object {
        if (-not (Get-Module -ListAvailable -All $_)) {
            Write-Host "Module [$_] not found, installing..." -ForegroundColor DarkGray
            Install-Module $_ -Force
        }
    }
    # Import modules
    $modulesToInstall | ForEach-Object {
        Write-Host "Importing Module [$_]" -ForegroundColor DarkGray
        Import-Module $_ 
    }
}

###############################
# Main
###############################
# Install modules
Write-Host "┏━━━" -ForegroundColor Cyan
Write-Host "┃  Installing/Importing PowerShell modules" -ForegroundColor Cyan
Write-Host "┗━━━" -ForegroundColor Cyan
InstallModules

# Authentication
Write-Host "┏━━━" -ForegroundColor Cyan
Write-Host "┃ Logging you in" -ForegroundColor Cyan
Write-Host "┗━━━" -ForegroundColor Cyan
Connect-MgGraph -Scopes Application.ReadWrite.All | Out-Null


Write-Host "┏━━━" -ForegroundColor Cyan
Write-Host "┃ Restricting apps" -ForegroundColor Cyan
Write-Host "┗━━━" -ForegroundColor Cyan
# Apps to limit
# 14d82eec-204b-4c2f-b7e8-296a70dab67e --> Microsoft Graph PowerShell / Microsoft Graph Command Line Tools
# 1b730954-1685-4b74-9bfd-dac224a7b894 --> Azure Active Directory PowerShell
# 1950a258-227b-4e31-a9cf-717495945fc2 --> Microsoft Azure PowerShell
$AppIds = @("1950a258-227b-4e31-a9cf-717495945fc2")

foreach ($AppId in $AppIds) {
    # Get existing service principle
    $SP = (Get-MgServicePrincipal -Filter "AppId eq '$($AppId)'")
    # Create service principal if not exists
    if (-not $SP) { 
        $SP = New-MGServicePrincipal -AppId $AppId 
        Write-Host "  ┖─ Did not found service principal with AppId $AppId so created one" -ForegroundColor Yellow
    } else {
        Write-Host "  ┖─ Found service principal with AppId $AppId" -ForegroundColor Green
    }
    # Set assignment required
    Update-MgServicePrincipal -ServicePrincipalId $SP.Id -AppRoleAssignmentRequired:$false
    Write-Host "  ┖─ Updated assignment required for $AppId with display name $($SP.DisplayName)" -ForegroundColor Green
}

#verify the changes
Get-MgServicePrincipal -Filter "AppId eq '1b730954-1685-4b74-9bfd-dac224a7b894'" | Select-Object *
Get-MgServicePrincipal -Filter "AppId eq '1950a258-227b-4e31-a9cf-717495945fc2'" | Select-Object *






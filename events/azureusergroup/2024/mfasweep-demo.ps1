
#tenant information

$tenantId = ""
$username = '@tenantname.onmicrosoft.com'


#tenant info> 
# https://aadinternals.com/osint/ 
# https://www.whatismytenantid.com/ 

#load modules in mfasweep beforehand. 
#read passwords. 
$securePassword = Read-Host -Prompt 'Enter your password' -AsSecureString
$clearTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securePassword

######## Recon auth possiblities 1b730954-1685-4b74-9bfd-dac224a7b894 ################ 
Invoke-GraphAPIAuth -Username $username -Password $clearTextPassword 


#### AAD INTERNALALS 
Import-Module AADInternals
Get-AADIntAccessTokenForMSGraph -Credentials $credential -SaveToCache
Get-AADIntCache
Get-AADIntGlobalAdmins
Get-AADIntTenantAuthPolicy 
Clear-AADIntCache
##### Get all users with roles.################

Import-Module MSOnline -EA 0
Connect-MsolService -Credential $credential
Get-MsolRole -RoleName "Company Administrator"


$admins=@()
$roles = Get-MsolRole 
foreach ($role in $roles) {
    $roleUsers = Get-MsolRoleMember -RoleObjectId $role.ObjectId

    foreach ($roleUser in $roleUsers) {
        $roleOutput = New-Object -TypeName PSObject
        $roleOutput | Add-Member -MemberType NoteProperty -Name RoleMemberType -Value $roleUser.RoleMemberType
        $roleOutput | Add-Member -MemberType NoteProperty -Name EmailAddress -Value $roleUser.EmailAddress
        $roleOutput | Add-Member -MemberType NoteProperty -Name DisplayName -Value $roleUser.DisplayName
        $roleOutput | Add-Member -MemberType NoteProperty -Name isLicensed -Value $roleUser.isLicensed
        $roleOutput | Add-Member -MemberType NoteProperty -Name RoleName -Value $role.Name

        $admins += $roleOutput
    }
} 

$admins | Export-Csv -NoTypeInformation -Path C:\git\priv\demo\output\asug.csv



############# AZ 1950a258-227b-4e31-a9cf-717495945fc2 ####################
Invoke-AzureManagementAPIAuth  -Username $username -Password $clearTextPassword 
Connect-AzAccount -Credential $credential

Get-AzTenant
Get-AzADUser -First 10
Get-AzContext -ListAvailable
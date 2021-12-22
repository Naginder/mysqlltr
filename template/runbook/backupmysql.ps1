Param(
    [Parameter(Mandatory=$true)]
    [String] $AccountID,
    [Parameter(Mandatory = $true)]
    [String] $rgname,
    [Parameter(Mandatory = $true)]
    [String] $hostname,
    [Parameter(Mandatory = $true)]
    [String] $username,
    [Parameter(Mandatory = $true)]
    [String] $password,
    [Parameter(Mandatory = $true)]
    [String] $storagename,
    [Parameter(Mandatory = $true)]
    [String] $backupfileshare   
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

#get the managed identity
# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $AccountID).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

Write-Output "Successfully connected with Automation account's Managed Identity"  

$datetimestr=get-date -format "yyyyMMddhhmmss"
$filename="--result-file=/data/backups/dumps"+$datetimestr+".sql"

#get storage keys
$storagekey=((Get-AzStorageAccountKey -ResourceGroupName $rgname -AccountName $storagename) | Where-object {$_.KeyName -eq "Key1"}).value
#create mount object as backup volume in container
$volumemount=New-AzContainerInstanceVolumeMountObject -Name "backups" -MountPath "/data/backups/" -ReadOnly $false
#create new volume on the mount object from the azure fileshare
$volume=New-AzContainerGroupVolumeObject -Name "backups" -AzureFileShareName $backupfileshare `
        -AzureFileStorageAccountName $storagename `
        -AzureFileStorageAccountKey (ConvertTo-SecureString $storagekey -AsPlainText -Force)
#create container object
$container = New-AzContainerInstanceObject -Name mysqldumpci1 -Image schnitzler/mysqldump -VolumeMount $volumemount `
            -Command "mysqldump","--opt","--single-transaction",$hostname,$username,$password,$filename,"--all-databases"
#deploy the container in azure container groups
Write-Output "creating container"
$containergroup=New-AzContainerGroup -ResourceGroupName $rgname -Name mysqldumpci1  -Location eastus -Container $container -Volume $volume `
            -RestartPolicy Never -OSType Linux 
#stop container after backup
Write-Output "stopping container"
Stop-AzContainerGroup -Name mysqldumpci1 -ResourceGroupName $rgname

#remove container

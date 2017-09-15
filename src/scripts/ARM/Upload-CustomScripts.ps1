#
# Upload_CustomScripts.ps1
#
Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
    [string] $StorageResourceGroupName = "ARM_Deploy_Staging",
	[string] [Parameter(Mandatory=$true)] $ReleaseName,
    [string] $ArtifactStagingDirectory = '.'
)

Import-Module Azure -ErrorAction SilentlyContinue

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(" ","_"), "2.9.5")
} catch { }

Set-StrictMode -Version 3

# Convert relative paths to absolute paths if needed
$ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))

$subscriptionId = ((Get-AzureRmContext).Subscription.SubscriptionId).Replace('-', '').substring(0, 19)
$StorageAccountName = "stage${subscriptionId}"

$StorageAccount = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName})

# Create the storage account if it doesn't already exist
if($StorageAccount -eq $null){
    New-AzureRmResourceGroup -Location "$ResourceGroupLocation" -Name $StorageResourceGroupName -Force
    $StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Type 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location "$ResourceGroupLocation"
}

$StorageAccountContext = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName}).Context

# Generate the value for artifacts location
$StorageContainerName = $ReleaseName.ToLowerInvariant()
$ArtifactsLocation = $StorageAccountContext.BlobEndPoint + $StorageContainerName

# Copy files from the local storage staging location to the storage account container
New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccountContext -Permission Container -ErrorAction SilentlyContinue *>&1

$ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process {$_.FullName}
foreach ($SourcePath in $ArtifactFilePaths) {
    $BlobName = $SourcePath.Substring($ArtifactStagingDirectory.length + 1)
    Set-AzureStorageBlobContent -File $SourcePath -Blob $BlobName -Container $StorageContainerName -Context $StorageAccountContext -Force -ErrorAction Stop
}

# Create a SAS token for the storage container - this gives temporary read-only access to the container
$ArtifactsLocationSasToken = New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccountContext -Permission r -ExpiryTime (Get-Date).AddHours(4)
## $ArtifactsLocationSasToken = ConvertTo-SecureString $ArtifactsLocationSasToken -AsPlainText -Force

# export as Variables in VSTS/TFS build
Write-Host ("##vso[task.setvariable variable=ArtifactsLocation;]${ArtifactsLocation}")
Write-Host ("##vso[task.setvariable variable=ArtifactsLocationSasToken;issecret=true;]${ArtifactsLocationSasToken}")

return $ArtifactsLocation,$ArtifactsLocationSasToken

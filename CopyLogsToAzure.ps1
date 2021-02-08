##########################################################################################################
##########################################################################################################
##########################################################################################################
#############							        	##########################
#############           Author: Arshad Jugon    				##########################
#############									##########################
#############			Purpose: To Transfer local logs			##########################
#############					 to an Azure Blob Storage	##########################
#############			Requirements: Azure Blob Storage &		##########################
#############			CMG (for internet based clients) 		##########################
#############			How to use: Use in a Run Script in CM/Intune or ##########################
#############				remote Powershell	        	##########################
#############							       		##########################
##########################################################################################################
##########################################################################################################
##########################################################################################################
#############	Big Thanks to Tom Degreef - https://www.oscc.be/sccm/Logging-in-the-cloud-Part-1/ ########
##########################################################################################################
#### Blog URL - 
###  Replace $url , StorageAccountName , storSas and container with your values ##########################


#Check if the Azure Modules are installed

If ((get-module -listavailable -name Azure.Storage).Name -eq 'Azure.Storage') {

		Write-Host('Module exists')

} else {

		# Downloading the Azure modules required for this to work from the Azure Blob Storage

		Write-Host('Module does not exist, proceeding to download it from the Azure Blob Storage')

		#Setting the url to download from (this was generated using SAS)

		$url = ""

		#Sets the destination where the zip file will be downloaded

		$dest = 'C:\ProgramData\AzureModules.zip'

		Write-Host "Downloading Azure Modeuls required from the Blob Storage"

		#Download the file using System.Net.WebClient to 'C:\ProgramData'

		$client = new-object System.Net.WebClient
		$client.DownloadFile($url, $dest)

		#Extract the file to 'C:\Program Files\WindowsPowerShell\Modules'

		$proc = Expand-Archive -LiteralPath 'C:\ProgramData\AzureModules.zip' -DestinationPath 'C:\Program Files\WindowsPowerShell\Modules'

}

#Import the Azure Modile azure.storage

Import-Module azure.storage

#Set the variables

$BlobProperties = @{

    StorageAccountName   = 'xxxxx'
    storSas              = 'xxxxx'
    container            = 'xxxxx'
}

#Set more variables

$TSHostname = $env:computername
$hostname = ($TSHostname).toupper()
$Timestamp = get-date -f yyyy-MM-dd-HH-mm-ss
$localpath = "C:\temp\Logs\$hostname-$Timestamp"

#Create folders corresponding to the type of logs being transferred

New-Item -ItemType Directory -Path $localpath -Force
New-Item -ItemType Directory -Path $localpath\Panther -Force
New-Item -ItemType Directory -Path $localpath\Software -Force
New-Item -ItemType Directory -Path $localpath\CCM -Force
New-Item -ItemType Directory -Path $localpath\Dism -Force

#Copy the child items to the respective folders created above

Get-ChildItem -Path C:\Windows\Panther | Copy-Item -Destination $localpath\Panther -Recurse
Get-ChildItem -Path C:\Windows\Logs\Software | Copy-Item -Destination $localpath\Software -Recurse
Get-ChildItem -Path C:\Windows\CCM\Logs | Copy-Item -Destination $localpath\CCM -Recurse
Get-ChildItem -Path C:\Windows\Logs\Dism | Copy-Item -Destination $localpath\Dism -Recurse

#Compress the folder

Compress-Archive -Path $localpath -DestinationPath "C:\temp\Logs\$hostname-$Timestamp.zip"

#Transfer the zipped folder to the Azure Blob Storage

$clientContext = New-AzureStorageContext -SasToken ($BlobProperties.storsas) -StorageAccountName ($blobproperties.StorageAccountName)

Set-AzureStorageBlobContent -Context $ClientContext -container ($BlobProperties.container) -File "C:\temp\Logs\$hostname-$Timestamp.zip"



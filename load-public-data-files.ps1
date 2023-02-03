# Import modules
Import-Module "..\solliance-synapse-automation"


# User must sign in using az login
Write-Host "Sign into Azure using your credentials.."
#az login

# Now sign in again for PowerShell resource management and select subscription
Write-Host "Now sign in again to allow this script to create resources..."
#Connect-AzAccount

$selectedSub = "c24530f6-a857-4327-bde5-e4fc61b7e392"
$dataLakeAccountName = "asadatalakerwulbyk"
$resourceGroupName = "data-engineering-synapse-rwulbyk"


if(-not ([string]::IsNullOrEmpty($selectedSub)))
{
    Select-AzSubscription -SubscriptionId $selectedSub
}


Write-Information "Copy Data"
Write-Host "Uploading data to Azure..."

Ensure-ValidTokens $true

if ([System.Environment]::OSVersion.Platform -eq "Unix")
{
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
        tar -xf "azCopy.tar.gz"
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName
        cd $azCopyCommand
        chmod +x azcopy
        cd ..
        $azCopyCommand += "\azcopy"
}
else
{
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
        }

        #Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
        #Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName
        $azCopyCommand += "\azcopy"
}

$download = $true;

$publicDataUrl = "https://solliancepublicdata.blob.core.windows.net/"

$dataLakeStorageUrl = "https://"+ $dataLakeAccountName + ".dfs.core.windows.net/"
$dataLakeStorageBlobUrl = "https://"+ $dataLakeAccountName + ".blob.core.windows.net/"
$dataLakeStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $dataLakeStorageAccountKey

$destinationSasKey = New-AzStorageContainerSASToken -Container "files" -Context $dataLakeContext -Permission rwdl

if ($download)
{
	Write-Information "Copying single files from the public data account..."
	$singleFiles = @{
		customer_info = "files,wwi-02,/customer-info/customerinfo.csv"
		products = "files,wwi-02,/data-generators/generator-product/generator-product.csv"
		dates = "files,wwi-02,/data-generators/generator-date.csv"
		customer = "files,wwi-02,/data-generators/generator-customer.csv"
		customer_clean = "files,wwi-02,/data-generators/generator-customer-clean.csv"
	}
	
	foreach ($singleFile in $singleFiles.Keys) {
		$vals = $singleFiles[$singleFile].tostring().split(",");
		$source = $publicDataUrl + $vals[1] + $vals[2];
		$path = $vals[0] + $vals[2];
		$destination = $dataLakeStorageBlobUrl + $path + $destinationSasKey
		Write-Information "Copying file $($source) to $($destination)"
		& $azCopyCommand copy $source $destination 
	}

	Write-Information "Copying sample sales raw data directories from the public data account..."

	$dataDirectories = @{
		salesmall = "files/sale-small,wwi-02/sale-small/Year=2019"
		analytics = "files,wwi-02/campaign-analytics/"
		factsale = "files,wwi-02/sale-csv/"
		security = "files,wwi-02-reduced/security/"
		salespoc = "files,wwi-02/sale-poc/"
	}

	foreach ($dataDirectory in $dataDirectories.Keys) {

		$vals = $dataDirectories[$dataDirectory].tostring().split(",");

		$source = $publicDataUrl + $vals[1];

		$path = $vals[0];

		$destination = $dataLakeStorageBlobUrl + $path + $destinationSasKey
		Write-Information "Copying directory $($source) to $($destination)"
		& $azCopyCommand copy $source $destination --recursive=true
	}
}
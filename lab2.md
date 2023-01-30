## Lab 2: Query & Secure Data
  **Lab setup instruction** (This Lab need **data** in data lake storage account.)
  1. Download zip/rar file from [here](https://github.com/pankajcloudthat/azdata/blob/main/data/sales.rar) and extract it in lab VM.
  2. Download Azure Data Explorer from [here](https://azure.microsoft.com/en-in/products/storage/storage-explorer).
  3. Go to data lake storage account and copy the *storage account name* & *key1* from **Access Keys** under **Security + networking** blade of storage account and past it in a notepad.
  4. Configure Azure Data Explorer:
     - Click on plug icon (*open connect dialog*) in Azure Data Explorer.
     - Select **storage account or service**
     - Select **Account name and key**
     - Proved the details you copied from storage account
       - Display name: **Storage Account name**
       - Account name: **Storage Account name**
       - Account key: **Account key**
    
     - Click next and Connect.
     - Upload sales folder to data lake **files** container (if not exists then create *files* container)

       ![Image](/data/img/synapse_000419.png)
   
#### [Ex 1: Query and Transform the data using serverless SQL pool](lab/Query%20and%20Transform%20the%20data%20using%20serverless%20SQL%20pool.pdf)
#### [Ex 2: Query and Transform the data using spark pool](lab/Query%20and%20Transform%20the%20data%20using%20spark%20pool.pdf)
#### [Ex 3: Secure Data in Synapse](lab/Secure%20Data%20in%20Synapse.pdf)
#### [Ex 4: Manage and configure the secrets in Azure Key Vault](lab/Manage%20and%20configure%20the%20secrets%20in%20Azure%20Key%20Vault.pdf)

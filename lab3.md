## Lab 3: Ingest & Transform Data

### Setup steps

Perform the following tasks to prepare your environment for the labs.

1. Use the Windows **Search** box to search for **Windows PowerShell**, and then run it as an administrator.

    > **Note**: Make sure you run **Windows Powershell**, <u>not</u> Windows PowerShell ISE; and be sure to run it as Administrator.

2. In Windows PowerShell, run the following commands to download the required course files. This may take a few minutes.

    ```
    mkdir c:\dp-203

    cd c:\dp-203

    git clone https://github.com/microsoftlearning/dp-203-data-engineer.git data-engineering-ilt-deployment
    ```

3. In Windows PowerShell, run the following command set the execution policy so you can run a local PowerShell script file:

    > **Note**: You may need to run Windows PowerShell in Administrator.  To complete this, right click on Windows PowerShell and select "Run as Administrator". 

    ```
    Set-ExecutionPolicy Unrestricted
    ```

    > **Note**: If you receive a prompt that you are installing the module from an untrusted repository, enter **A** to select the *Yes to All* option.

4. In Windows PowerShell, use the following command to change directories to the folder containing the automation scripts.

    ```
    cd C:\dp-203\data-engineering-ilt-deployment\Allfiles\00\artifacts\environment-setup\automation\
    ```
5. Create a file in the automation directory as follows:
    - Open file browser and go to the above mention file path and create a file with name: **data-load-wwi-02.ps1**
    - Copy the content of file [data-load-wwi-02.txt](/data-load-wwi-02.txt) and past in above created file and save it.
    - Modify the **data-load-wwi-02.ps1** file as:
        - # Enter the subscription ID
        - $selectedSub = ""
        - # Enter Storage Account Name
        - $dataLakeAccountName = ""
        - # Enter Resource Group Name where your storage account is created.
        - $resourceGroupName = ""

6. Open Azure portal, go to the Azure Data Lake Gen 2 Storage account that you created in previous lab and create a new container **wwi-02**.

7. Now in Windows PowerShell which is already open, enter the following command to run the setup script:
        
    ```
    .\data-load-wwi-02.ps1
    ```
    
7. When prompted to sign into Azure, and your browser opens; sign in using your credentials. After signing in, you can close the browser and return to Windows PowerShell, which should display the Azure subscriptions to which you have access.

8. When prompted, sign into your Azure account again (this is required so that the script can manage resources in your Azure subscription - be sure you use the same credentials as before).

## Ex1: [Import data with PolyBase & COPY using T-SQL and Copy Activity](/lab/Import%20data%20with%20PolyBase%20%26%20COPY%20using%20T-SQL%20and%20Copy%20Activity.pdf)

## Ex2: [Orchestrating Data Movement with Azure Data Factory](/lab/Code%20Free%20Transformation%20using%20Data%20Flow%20in%20ADF.pdf)

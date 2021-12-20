# mysqlltr
long term retention of Azure DB for MySQL databases using azure container instances

this template will deploy the automation account, blob storage, managed identity and the runbook which takes the backup of mysql database. there are few steps that you need to do.

1. provide access to managed identity to the resource group as a contributor where automation account, storage account is deployed.

2. provide parameters to the runbook and execute.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FNaginder%2Fmysqlltr%2Fmain%2Ftemplate%2Ftemplate.json)

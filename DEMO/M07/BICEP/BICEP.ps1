
## Depoly bicep
az group create --name exampleRG --location eastus

az deployment group create --resource-group Demo062002 --template-file ./deploy.bicep --parameters adminPassword=P@ssw0rdP@ssword

## Decompile bicep to ARM Template
az bicep decompile --file ./deploy.json
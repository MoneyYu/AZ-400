using Pulumi;
using Pulumi.AzureNative.Migrate;
using Pulumi.AzureNative.Resources;
using Pulumi.AzureNative.Web;
using Pulumi.AzureNative.Web.Inputs;
using System;

class MyStack : Stack
{
    public MyStack()
    {
        Random random = new Random();
        int num = random.Next();
        string suffix = num.ToString("X").Substring(0, 4).ToLower();

        // Create an Azure Resource Group
        var az400Group = new ResourceGroup($"AZ-400",
            new ResourceGroupArgs() { Location = AzureLocation.SoutheastAsia.ToString(), ResourceGroupName = $"AZ-400-{suffix}" });

        var lab01Plan = new AppServicePlan($"lab01", new AppServicePlanArgs()
        {
            Name = $"lab01-{suffix}",
            ResourceGroupName = az400Group.Name,
            Location = az400Group.Location,
            Sku = new SkuDescriptionArgs
            {
                Name = "S1",
                Tier = "Standard",
                Size = "S1"
            },
            Kind = "app"
        });

        var lab01App = new WebApp($"lab01", new WebAppArgs
        {
            Name = $"lab01-{suffix}",
            Location = az400Group.Location,
            ResourceGroupName = az400Group.Name,
            ServerFarmId = lab01Plan.Id,
        });
    }
}

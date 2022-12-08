configuration LabConfig
{
    Node localhost
    {
        WindowsFeature IIS {
            Ensure               = 'Present'
            Name                 = 'Web-Server'
            IncludeAllSubFeature = $true
        }

        # Printer Spooler Service
        Service "Spooler - Running" {
            Ensure = "Present"
            Name   = "Spooler"
            State  = "Stopped"
        }
    }
}
Configuration Main
{

Param ( [string] $nodeName )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xWebAdministration

    
Node $nodeName
  {
   
    WindowsFeature WebServerRole
    {
      Name = "Web-Server"
      Ensure = "Present"
    }
    WindowsFeature WebManagementConsole
    {
      Name = "Web-Mgmt-Console"
      Ensure = "Present"
    }
    WindowsFeature WebManagementService
    {
      Name = "Web-Mgmt-Service"
      Ensure = "Present"
    }
    WindowsFeature ASPNet45
    {
      Name = "Web-Asp-Net45"
      Ensure = "Present"
    }
    WindowsFeature HTTPRedirection
    {
      Name = "Web-Http-Redirect"
      Ensure = "Present"
    }
    WindowsFeature CustomLogging
    {
      Name = "Web-Custom-Logging"
      Ensure = "Present"
    }
    WindowsFeature LogginTools
    {
      Name = "Web-Log-Libraries"
      Ensure = "Present"
    }
    WindowsFeature RequestMonitor
    {
      Name = "Web-Request-Monitor"
      Ensure = "Present"
    }
    WindowsFeature Tracing
    {
      Name = "Web-Http-Tracing"
      Ensure = "Present"
    }
    WindowsFeature BasicAuthentication
    {
      Name = "Web-Basic-Auth"
      Ensure = "Present"
    }
    WindowsFeature WindowsAuthentication
    {
      Name = "Web-Windows-Auth"
      Ensure = "Present"
    }
    WindowsFeature ApplicationInitialization
    {
      Name = "Web-AppInit"
      Ensure = "Present"
    }
    Script DownloadWebDeploy
    {
        TestScript = {
            Test-Path "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        }
        SetScript ={
            $source = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
            $dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
            Invoke-WebRequest $source -OutFile $dest
        }
        GetScript = {@{Result = "DownloadWebDeploy"}}
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Package InstallWebDeploy
    {
        Ensure = "Present"  
        Path  = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        Name = "Microsoft Web Deploy 3.6"
        ProductId = "{ED4CC1E5-043E-4157-8452-B5E533FE2BA1}"
        Arguments = "ADDLOCAL=ALL"
        DependsOn = "[Script]DownloadWebDeploy"
    }
    Service StartWebDeploy
    {                    
        Name = "WMSVC"
        StartupType = "Automatic"
        State = "Running"
        DependsOn = "[Package]InstallWebDeploy"
    }
	
	xWebAppPool CatSitePool

    {
	    Ensure = "Present"
		Name   = 'CatSitePool'
		State  = 'Started'
		autoStart = $true
	}

    File DirectoryWeb
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "c:\web"
        }

	File DirectoryCatSite
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "c:\web\CatSite"
        }
	File DirectoryCatSiteWWWROOT
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "c:\web\CatSite\WWWROOT"
        }

    Log AfterDirectoryCreationWeb
        {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message = "Finished running the file resource with ID Directoryweb"
            DependsOn = "[File]Directoryweb" # This means run "DirectoryCopy" first.
        }

	
    Log AfterDirectoryCreationCatSite
        {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message = "Finished running the file resource with ID DirectoryCatSite"
            DependsOn = "[File]DirectoryCatSite" # This means run "DirectoryCopy" first.
        }

	Log AfterDirectoryCreationCatSiteWWWROOT
        {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message = "Finished running the file resource with ID DirectoryCatSiteWWWROOT"
            DependsOn = "[File]DirectoryCatSiteWWWROOT" # This means run "DirectoryCopy" first.
        }

    }



	
	xWebsite CatSite
	{

            Ensure          = "Present"
			Name            = 'CatSite'
			State           = 'Started'
			PhysicalPath    = 'C:\Web\CatSite\wwwroot'
			ServiceAutoStartEnabled = $true
			ApplicationPool = 'CatSitePool'
			BindingInfo     = @(
				              @(MSFT_xWebBindingInformation   

								{  
									Protocol              = "HTTP"
									Port                  =  80
									HostName              = "*"
								}
							)
						)

      AuthenticationInfo =  MSFT_xWebAuthenticationInformation  

        {

            Anonymous = $true
			Basic = $false
			Windows = $false
			Digest = $false
		}
		
            DependsOn       = '[xWebAppPool]CatSitePool'

        }        


	}
}
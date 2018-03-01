Configuration Main
{

Param ( [string] $nodeName )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xWebAdministration
Import-DscResource -ModuleName PowerShellModule
Import-DSCResource -ModuleName xTimeZone
    
Node $nodeName
  {
   
    
	xTimeZone TimeZoneExample
    {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Eastern Standard Time'
    }
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
        ProductId = "{6773A61D-755B-4F74-95CC-97920E45E696}"
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
	
	PSModuleResource AzureStorage
        {
		    Ensure      = "Present"
            Module_Name   = "Azure.Storage"
        
        }   
	
	
	xWebAppPool CatSitePool

    {
	    Ensure = "Present"
		Name   = 'CatSitePool'
		State  = 'Started'
		autoStart = $true
		Dependson = "[WindowsFeature]WebServerRole"
	}

	xWebAppPool DefaultPool

    {
	    
		Name   = 'DefaultAppPool'
		State  = 'Stopped'
		autoStart = $false
		Dependson = "[WindowsFeature]WebServerRole"
	}

    File DirectoryWeb
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "c:\web"
        }

	File DirCatSite
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "c:\web\CatSite"
			Dependson = "[File]DirectoryWeb"
        }
	
	File DirWWWROOT
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "c:\web\CatSite\WWWROOT"
			Dependson = "[File]DirCatSite"
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
            DependsOn = "[File]DirCatSite" # This means run "DirectoryCopy" first.
        }

	Log AfterDirectoryCreationCatSiteWWWROOT
        {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message = "Finished running the file resource with ID DirectoryCatSiteWWWROOT"
            DependsOn = "[File]DirWWWROOT" # This means run "DirectoryCopy" first.
        }

    
	
	script CopyCatSiteFromAzureStorage
		    {
			    GetScript = 
			    {   
				    $Context = New-AzureStorageContext -StorageAccountName webteamstorage -Anonymous;
				    $WebsiteFileCountTMP = (Get-AzureStorageBlob -Context $Context -Container "catsite").count
				    $WebsiteFileCount = ((Get-ChildItem -Path "c:\web\CatSite\WWWROOT" -recurse).count -1)
                    return @{ 'Result' = "Count on blob : $WebsiteFileCountTMP, Count on wwwRoot : $WebsiteFileCount " }
			    }


			    SetScript = 
			    {   
                    write-verbose -Message "Setting Azure storage context (Anonymous)"
                    $Context = New-AzureStorageContext -StorageAccountName webteamstorage -Anonymous;
				    write-verbose -message "Retreiving container content"
                    Get-AzureStorageBlob -Context $Context -Container "catsite" | Get-AzureStorageBlobContent -Destination "c:\web\CatSite\WWWROOT" -force
			    }
			    TestScript =
			    {   
				    write-verbose -Message "Counting files in wwwRoot"
                    $WebsiteFileCount = ((Get-ChildItem -Path "c:\web\CatSite\WWWROOT" -recurse).count -1)
                    write-verbose -Message "Setting Azure storage context (Anonymous)"
                    $Context = New-AzureStorageContext -StorageAccountName webteamstorage -Anonymous;
				    write-verbose -Message "Conting blob in storage container"
                    $WebsiteFileCountTMP = (Get-AzureStorageBlob -Context $Context -Container "catsite").count
				    
                    if($WebsiteFileCountTMP -eq $WebsiteFileCount)
				
				    {
					    write-verbose -Message ('There is nothing to do {0} -eq {1}' -f $WebsiteFileCountTMP, $websiteFileCount)
					    return $true
				    }
				    ELSE
				    {
					    write-verbose -Message ('Number of blob does not match, calling setScript {0} -ne {1}' -f $WebsiteFileCountTMP, $websiteFileCount)
                        return $false

				    }
				
			    }
			 
			DependsOn = "[File]DirWWWROOT"

		
		
		
		
		}
	
	xWebsite DefaultWebSite
	{

            Ensure          = "Present"
			Name            = 'Default Web Site'
			State           = 'Stopped'
			ServiceAutoStartEnabled = $false
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
									HostName              = ""
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
		
            DependsOn       = "[xWebAppPool]CatSitePool"

        }        

	}
	
}
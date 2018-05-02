<#
.SYNOPSIS
  This Script will configure Software Update Point Component
.DESCRIPTION
  Script will configure software update component after ConfigMgrLab Standard
.PARAMETER <Parameter_Name>
    Parameters Will tell to add patch classes
.INPUTS
  
.OUTPUTS
  
.NOTES
  Version:        1.2
  Author:         Nicholai Kjærgaard
  Creation Date:  02-05-2015
  Purpose/Change:
    1.2 - Windows 7 class added  

    1.1 - Software Update Category added  

    1.0 - Script Created
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

function Set-SoftwareUpdatePointComponent {
    
    param(

        # Windows 7 Updates
        [Parameter(Mandatory=$true)]
        [bool]
        $Windows7Patches,

        # Windows 8 Patches
        [Parameter(Mandatory=$true)]
        [bool]
        $Windows8Patches

    )

    # Get SCCM Installation Path
    $SCCMDirectory = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\SMS\Setup -Name "Installation Directory" | Select-Object "Installation Directory")."Installation Directory"

    # Get Site Code
    $SCCMSiteCode = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\SMS\Identification -Name "Site Code" | Select-Object "Site Code")."Site Code"

    # Get WSUS Server
    $WSUSServer = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\SMS\Identification -Name "Site Server" | Select-Object "Site Server")."Site Server"

    # Import SCCM Module
    Import-Module $SCCMDirectory\AdminConsole\bin\ConfigurationManager.psd1

    # Set Location 
    Set-Location $SCCMSiteCode":"

    # Get Software Update Category
    $SoftwareUpdateCategory = (Get-CMSoftwareUpdateCategory -TypeName UpdateClassification | Select-Object LocalizedCategoryInstanceName).LocalizedCategoryInstanceName

    If ($Windows7Patches -eq $true)
        {
            $Windows7 = "Windows 7"
        }
    else {
        $Windows7 = $null
    }
    
    if ($Windows8Patches -eq $true)
        {
            $Windows8 = "Windows 8"
        }
    else {
            $Windows8 = $null        
        }
    # Configure Software Update Point Component
    Set-CMSoftwareUpdatePointComponent -SiteCode $SCCMSiteCode -DefaultWsusServer $WSUSServer -SynchronizeAction SynchronizeFromMicrosoftUpdate -ReportingEvent CreateOnlyWsusStatusReportingEvents -AddUpdateClassification $SoftwareUpdateCategory -AddProductFamilies "Developer Tools, Runtimes, and Redistributables","Silverlight" -AddProduct $Windows7,$Windows8
}
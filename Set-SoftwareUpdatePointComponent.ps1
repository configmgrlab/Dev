<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

function Set-SoftwareUpdatePointComponent (OptionalParameters) {
    
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

    Set-CMSoftwareUpdatePointComponent -SiteCode $SCCMSiteCode -DefaultWsusServer $WSUSServer -SynchronizeAction SynchronizeFromMicrosoftUpdate -ReportingEvent CreateOnlyWsusStatusReportingEvents -AddUpdateClassification "" -AddProductFamilies "Developer Tools, Runtimes, and Redistributables","Silverlight"
}
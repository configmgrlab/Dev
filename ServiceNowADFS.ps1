
<#

.SYNOPSIS

  This script is created for adding new reyling party trust for Service-Now



.DESCRIPTION

  This function will create a relying party trust for Service-Now



.PARAMETER 

    Environment:
    This will name the relying party trust after the environment

    TransformRule:
    Here it will be decided wheter it's UPN or SamAcountName for the transformrule

    ADFSurl:
    The insert url will be added as a SAML logout Endpoints

    ServiceNowUrl:
    The inserted url will be added to SAML Assertion Consumer and Reyling party identifiers

.INPUTS
  
    ADFS URL

    Service-Now instance URL

.OUTPUTS

  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>



.NOTES

  Version:        1.1

  Author:         Nicholai Kjærgaard

  Creation Date:  25/04/2018

  Purpose/Change: 
    
    1.1 Version - Verb changed  

    1.0 Version - Document created

  

.EXAMPLE

  Create-ServiceNowTrust -Environment Development -TransformRules SamAccountName -ADFSurl https://sts.syspeople.dk -ServiceNowUrl https://syspeople.servicenow.com

#>

Function New-ServiceNowTrust {
    
    param(

        # Define which environment to create
        [Parameter(Mandatory=$true)]
        [ValidateSet("Production","Development")]
        [string]
        $Environment,

        # Define which login method to use
        [Parameter(Mandatory=$true)]
        [ValidateSet("SamAccountName","userPrincipalName")]
        [String]
        $TransformRules = "UserPrincipalName",

        # Input for ADFS URL adresse
        [Parameter(Mandatory=$true)]
        [string]
        $ADFSurl,

        # Input for Service-Now
        [Parameter(Mandatory=$true)]
        [string]
        $ServiceNowUrl
    )

    Switch ($TransformRules)
    {
        SamAccountName {
            $TSRule = @"
            @RuleTemplate = "LdapClaims"
            @RuleName = "Get-Attributes"
            c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]
             => issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"), query = ";sAMAccountName;{0}", param = c.Value);

            @RuleTemplate = "MapClaims"
            @RuleName = "SAMAccountName to nameid"
            c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] == "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"]
             => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", Issuer = c.Issuer, OriginalIssuer = c.OriginalIssuer, Value = c.Value, ValueType = c.ValueType, Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified");
"@
        }
        userPrincipalName {
            $TSRule = @"
            @RuleTemplate = "LdapClaims"
            @RuleName = "Get-Attributes"
            c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]
            => issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"), query = ";userPrincipalName;{0}", param = c.Value);

            @RuleTemplate = "MapClaims"
            @RuleName = "UPN to nameid"
            c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"]
             => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", Issuer = c.Issuer, OriginalIssuer = c.OriginalIssuer, Value = c.Value, ValueType = c.ValueType, Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified");
"@
        }
    }
    try {
            # Test if Relying party exist
            if (Get-AdfsRelyingPartyTrust -Name "ServiceNow$Environment") {Write-Error -Message "Relying Party trust already exist" -ErrorAction Stop}
            
            # Create Metadata file
            @"
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="$ServiceNowUrl">
 	<SPSSODescriptor AuthnRequestsSigned="false" WantAssertionsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
		<SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="$ADFSurl/adfs/ls/?wa=wsignout1.0" />
		<NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified</NameIDFormat>
		<AssertionConsumerService isDefault="true" index="0" Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="$ServiceNowUrl/navpage.do" />
		<AssertionConsumerService index="1" Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="$ServiceNowUrl/consumer.do"/>
	</SPSSODescriptor>
</EntityDescriptor>
"@ | Out-file metadata.xml

        # Create Issuance Authorization Rules
        $IssuanceAuthorizationRules = @"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");
"@
        
        $Metadata = ".\metadata.xml"

        # Create Relying Party Trust
        Add-AdfsRelyingPartyTrust -Name "ServiceNow$Environment" -MetadataFile $Metadata -IssuanceTransformRules $TSRule -IssuanceAuthorizationRules $IssuanceAuthorizationRules -ErrorAction Stop
        
        # Set Algorithm to SHA1
        Set-AdfsRelyingPartyTrust -TargetName "ServiceNow$Environment" -SignatureAlgorithm "http://www.w3.org/2000/09/xmldsig#rsa-sha1" -ErrorAction Stop

        Remove-Item $Metadata -Force
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "$ErrorMessage" -ForegroundColor Red
    }
}
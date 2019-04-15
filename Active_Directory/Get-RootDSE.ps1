# connects to the RootDSE and grabs info, requires no auth.

Function Get-RootDSE {
param($DomainController)

    begin
    {   
        Function Get-FunctionalLevel
        {
        param([int]$NumericValue)
            switch ($NumericValue)
            {
                0 {'2000'}
                1 {'2003 Interim'}
                2 {'2003'}
                3 {'2008'}
                4 {'2008 R2'}
                5 {'2012'}
                6 {'2012 R2'}
                7 {'2016'}
            }
        }
    }

    process
    {
        $adsi = New-Object adsi -ArgumentList "LDAP://$DomainController/rootDSE",$Null,$Null,'Anonymous'
        $properties = $adsi.Properties
        $Out = '' | Select-Object DNSHostName, HostDN, DomainDN, HostOS, CurrentTime, DomainFunctionalLevel, ForestFunctionalLevel, Sychronized, GlobalCatalog
        $Out.DNSHostName = $properties.dnsHostName[0]
        $Out.HostDN = $properties.serverName[0]
        $Out.DomainDN = $properties.rootDomainNamingContext[0]
        $Out.HostOS = Get-FunctionalLevel -NumericValue ([string]$properties.domainControllerFunctionality)
        $Out.CurrentTime = [datetime]::ParseExact($properties.currentTime,'yyyyMMddHHmmss\.\0\Z',$null)
        $Out.DomainFunctionalLevel = Get-FunctionalLevel -NumericValue ([string]$properties.domainFunctionality)
        $Out.ForestFunctionalLevel = Get-FunctionalLevel -NumericValue ([string]$properties.forestFunctionality)
        $Out.Sychronized = [bool]::Parse($properties.isSynchronized)
        $Out.GlobalCatalog = [bool]::Parse($properties.isGlobalCatalogReady)
        $Out
    }

}

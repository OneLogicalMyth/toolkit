Function Get-NSXRules {
param($NSXFile)

    begin
    {
        # Convert XML file to XML object
        [XML]$File = Get-Content $NSXFile
        $Rules = $File.SelectNodes('//section/rule')


        # object properties
        $Props = @(
            'SectionID'
            'SectionName'
            'SectionType'
            'RuleID'
            'RuleDisabled'
            'RuleLogged'
            'RuleName'
            'RuleAction'
            'RuleDirection'
            'RulePacketType'
            'AppliesToName'
            'AppliesToValue'
            'AppliesToType'
            'AppliesToIsValid'
            'SourceName'
            'SourceValue'
            'SourceType'
            'SourceIsValid'
            'DestinationName'
            'DestinationValue'
            'DestinationType'
            'DestinationIsValid'
            'ServiceName'
            'ServiceValue'
            'ServiceType'
            'ServiceIsValid'
        )

    }

    process
    {
        # loop each section rule
        foreach($Rule in $Rules)
        {
            # Expand applied to first
            foreach($AppliedTo in $Rule.appliedToList.appliedTo)
            {
                # Expand sources second
                foreach($Source in $Rule.sources.source)
                {
                    # Check for destination 
                    if($Rule.destinations.destination -is [System.Xml.XmlElement])
                    {
                        # Expand destinations third
                        foreach($Destination in $Rule.destinations.destination)
                        {

                            # Expand services fourth
                            foreach($Service in $Rule.services.service)
                            {
                        
                                $Out = '' | Select-Object $Props
                                $Out.SectionID = $Rule.sectionId
                                $Out.SectionName = $Rule.ParentNode.name
                                $Out.SectionType = $Rule.ParentNode.type
                                $Out.RuleID = $Rule.id
                                $Out.RuleDisabled = $Rule.disabled
                                $Out.RuleLogged = $Rule.logged
                                $Out.RuleName = $Rule.name.Trim()
                                $Out.RuleAction = $Rule.action
                                $Out.RuleDirection = $Rule.direction
                                $Out.RulePacketType = $Rule.packetType
                                $Out.AppliesToName = $AppliedTo.name
                                $Out.AppliesToValue = $AppliedTo.value
                                $Out.AppliesToType = $AppliedTo.type
                                $Out.AppliesToIsValid = $AppliedTo.isValid
                                $Out.SourceName = $Source.name
                                $Out.SourceValue = $Source.value
                                $Out.SourceType = $Source.type
                                $Out.SourceIsValid = $Source.isValid
                                $Out.DestinationName = $Destination.name
                                $Out.DestinationValue = $Destination.value
                                $Out.DestinationType = $Destination.type
                                $Out.DestinationIsValid = $Destination.isValid
                                $Out.ServiceName = $Service.name
                                $Out.ServiceValue = $Service.value
                                $Out.ServiceType = $Service.type
                                $Out.ServiceIsValid = $Service.isValid
                                $Out

                            }


                        }


                    }else{
                    

                            # Expand services fourth
                            foreach($Service in $Rule.services.service)
                            {
                        
                                $Out = '' | Select-Object $Props
                                $Out.SectionID = $Rule.sectionId
                                $Out.SectionName = $Rule.ParentNode.name
                                $Out.SectionType = $Rule.ParentNode.type
                                $Out.RuleID = $Rule.id
                                $Out.RuleDisabled = $Rule.disabled
                                $Out.RuleLogged = $Rule.logged
                                $Out.RuleName = $Rule.name.Trim()
                                $Out.RuleAction = $Rule.action
                                $Out.RuleDirection = $Rule.direction
                                $Out.RulePacketType = $Rule.packetType
                                $Out.AppliesToName = $AppliedTo.name
                                $Out.AppliesToValue = $AppliedTo.value
                                $Out.AppliesToType = $AppliedTo.type
                                $Out.AppliesToIsValid = $AppliedTo.isValid
                                $Out.SourceName = $Source.name
                                $Out.SourceValue = $Source.value
                                $Out.SourceType = $Source.type
                                $Out.SourceIsValid = $Source.isValid
                                $Out.DestinationName = $null
                                $Out.DestinationValue = $null
                                $Out.DestinationType = $null
                                $Out.DestinationIsValid = $null
                                $Out.ServiceName = $Service.name
                                $Out.ServiceValue = $Service.value
                                $Out.ServiceType = $Service.type
                                $Out.ServiceIsValid = $Service.isValid
                                $Out

                            }


                    }


                }

            }
            
        }
    }


}

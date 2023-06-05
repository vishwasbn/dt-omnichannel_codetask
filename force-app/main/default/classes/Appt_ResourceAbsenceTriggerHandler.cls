public class Appt_ResourceAbsenceTriggerHandler 
{

    // this funciton handles all the Trigger states
    public static void handle(Map<Id, ResourceAbsence> oldMap, Map<Id, ResourceAbsence> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug('Appt ResourceAbsenceTrigger Handler - START');

        // get the ResourceId set
        // get a set of all the Service Resources in the Trigger data
        Set<Id> resourceIdSet = new Set<Id>();

        if ((oldMap != null) && (oldMap.size() > 0))
        {
            for (ResourceAbsence resAb : oldMap.values())
            {
                resourceIdSet.add(resAb.ResourceId);
            }
        }

        if ((newMap != null) && (newMap.size() > 0))
        {
            for (ResourceAbsence resAb : newMap.values())
            {
                resourceIdSet.add(resAb.ResourceId);
            }
        }

        // ... this should never happen
        if ( resourceIdSet.size() < 1 ) return;

        // get the ServiceTerritoryMenber for the ServiceResources in question ... this gets the Territory (Store) and Type (Front / Back)
        List<ServiceTerritoryMember> servTerritoryMember = [SELECT Id, ServiceResource.Type__c, ServiceResourceId, ServiceTerritoryId FROM ServiceTerritoryMember WHERE ServiceResourceId IN: resourceIdSet]; 
        system.debug('ServiceTerritory: ' + servTerritoryMember.size());

        // create a Map of ServiceTerritoryMembers indexed  by ServiceResource Id
        Map<Id, ServiceTerritoryMember> servTerrByServRes = new Map<Id, ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm: servTerritoryMember) {
                // organize ServiceTerritoryMember by Service Resource Id
            servTerrByServRes.put(stm.ServiceResourceId, stm);
        }          

        switch on triggerEvent 
        {
            when AFTER_INSERT {
                // check the unAvailable Time slots
                update_IsUnavaiilable( newMap, servTerrByServRes, 'Set' );
            }
            when AFTER_UPDATE {
                // modify the unAvailable Time slots
                handleAfterUpdate(oldMap, newMap, servTerritoryMember, servTerrByServRes);
            }
            when AFTER_DELETE {
                // uncheck the unAvailable Time slots
                update_IsUnavaiilable(oldMap, servTerrByServRes, 'Clear' );

            }
            when else {
                //do nothing 
            }
        }
    
        System.debug('Appt ResourceAbsenceTrigger Handler - END');

    }


    public static void handleAfterUpdate( Map<Id, ResourceAbsence> oldMap, Map<Id, ResourceAbsence> newMap, List<ServiceTerritoryMember> servTerritoryMember, Map<Id, ServiceTerritoryMember> servTerrByServRes ) 
    {
        // create Maps of the ResourceAbsences that need to clear or set the unAvailable flags
        Map<Id, ResourceAbsence> clearMap = new Map<Id, ResourceAbsence>();
        Map<Id, ResourceAbsence> setMap = new Map<Id, ResourceAbsence>();

        // recreate a Set of the ServiceResource involved, based on ResourceAbsences that have a date/time change
        //   if something else changed don't worry about it
        Set<Id> resourceIdSet = new Set<Id>();
		Map<Id, String> whereClauseMap = new Map<Id, String>();

        for (ResourceAbsence resAb : oldMap.values())
        {
            // if the Start or End Datetime changes, then change
            if ( (resAb.Start != newMap.get(resAb.Id).Start) || (resAb.End != newMap.get(resAb.Id).End) )
            {
                // save the Old and the New ResourceAbsence
                clearMap.put(resAb.Id, resAb);
                setMap.put(newMap.get(resAb.Id).Id, newMap.get(resAb.Id));
                // save the ServiceResource Id
                resourceIdSet.add(resAb.ResourceId);
                // create the Where filter for the new and the old map, the SOQL will one retrieve one copy for of each time slot
                whereClauseMap.put(resAb.Id, '((Start_Time__c >= ' + resAb.Start.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') + ' AND End_Time__c <= ' + resAb.End.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') + ') OR (Start_Time__c >= ' + newMap.get(resAb.Id).Start.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') + ' AND End_Time__c <= ' + newMap.get(resAb.Id).End.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') + '))' );
            }
            // otherwise ignore
        }

        // get the time slots for the old and the new ResoureAbsences dates related to the ServiceResource Id
        //   step 1, clear the old flags
        List<Appt_Time_Slot__c> tmeSlots = getTimeSlotsSets( clearMap, servTerrByServRes, whereClauseMap );

        if ( (tmeSlots == null) || (tmeSlots.size() < 1) ) return; // no Time Slots to process

        // find the matching ServiceResource/ServiceTerritory and times to clear
        for (ResourceAbsence resAbsClear : clearMap.values())
        {
            system.debug('Id: ' + servTerrByServRes.get( resAbsClear.ResourceId ).ServiceTerritoryId + ' Type: ' +  servTerrByServRes.get( resAbsClear.ResourceId ).ServiceResource.Type__c + ' Start Time: ' + resAbsClear.Start + ' End Time: ' + resAbsClear.End );
            // loop through the time slots
            for (Appt_Time_Slot__c timeSlot : tmeSlots)
            {
                // check against the Clear Resource Absence
                if ( ( timeSlot.Service_Territory__c == servTerrByServRes.get( resAbsClear.ResourceId ).ServiceTerritoryId ) && ( resAbsClear.Start <= timeSlot.Start_Time__c && resAbsClear.End >= timeSlot.End_Time__c ) )
                {
                    // if the time slot matches the ResourceAbsense period, clear the flag
                    system.debug('Clear Name: ' + timeSlot.Name + ' Start Time: ' + timeSlot.Start_Time__c + ' End Time: ' + timeSlot.End_Time__c);
                    if (servTerrByServRes.get( resAbsClear.ResourceId ).ServiceResource.Type__c == 'Back Room' ) timeSlot.isBackUnavailable__c = false;
                    if (servTerrByServRes.get( resAbsClear.ResourceId ).ServiceResource.Type__c == 'Front Room' ) timeSlot.isFrontUnavailable__c = false;
                }
            }
        }

        // find the matching ServiceResource/ServiceTerritory and times to set
        for (ResourceAbsence resAbsSet : setMap.values())
        {
            system.debug('Id: ' + servTerrByServRes.get( resAbsSet.ResourceId ).ServiceTerritoryId + ' Type: ' +  servTerrByServRes.get( resAbsSet.ResourceId ).ServiceResource.Type__c + ' Start Time: ' + resAbsSet.Start + ' End Time: ' + resAbsSet.End );
            // loop through the time slots
            for (Appt_Time_Slot__c timeSlot : tmeSlots)
            {
                // check against the Resource Absence
                if ( ( timeSlot.Service_Territory__c == servTerrByServRes.get( resAbsSet.ResourceId ).ServiceTerritoryId ) && ( resAbsSet.Start <= timeSlot.Start_Time__c && resAbsSet.End >= timeSlot.End_Time__c ) )
                {
                    // if the time slot matches the ResourceAbsense period, set the flag
                    system.debug('Set Name: ' + timeSlot.Name + ' Start Time: ' + timeSlot.Start_Time__c + ' End Time: ' + timeSlot.End_Time__c);
                    if (servTerrByServRes.get( resAbsSet.ResourceId ).ServiceResource.Type__c == 'Back Room' ) timeSlot.isBackUnavailable__c = true;
                    if (servTerrByServRes.get( resAbsSet.ResourceId ).ServiceResource.Type__c == 'Front Room' ) timeSlot.isFrontUnavailable__c = true;
                }
            }
        }
        update tmeSlots;

    } // End of handleAfterUpdate()


    public static void update_IsUnavaiilable( Map<Id, ResourceAbsence> newMap, Map<Id, ServiceTerritoryMember> servTerrByServRes, String actionStr )
    {
        // create a set of where clauses from the Resource Absences
        //   including all the slots between the Start and End Times
		Map<Id, String> whereClauseMap = new Map<Id, String>();
        for (ResourceAbsence resAb : newMap.values())
        {
            whereClauseMap.put(resAb.Id, '(Start_Time__c >= ' + resAb.Start.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') + ' AND End_Time__c <= ' + resAb.End.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') + ')' );
        }

        List<Appt_Time_Slot__c> tmeSlots = getTimeSlotsSets( newMap, servTerrByServRes, whereClauseMap );

        if ( (tmeSlots == null) || (tmeSlots.size() < 1) ) return; // no Time Slots to process

        // find the matching ServiceResource/ServiceTerritory and times
        for (ResourceAbsence resrcAbsnce : newMap.values())
        {
            system.debug('Id: ' + servTerrByServRes.get( resrcAbsnce.ResourceId ).ServiceTerritoryId + ' Start Time: ' + resrcAbsnce.Start + ' End Time: ' + resrcAbsnce.End );
            // loop through the time slots, which may need to be unavailable
            for (Appt_Time_Slot__c timeSlot : tmeSlots)
            {
                // check against the Resource Absence
                if ( ( timeSlot.Service_Territory__c == servTerrByServRes.get( resrcAbsnce.ResourceId ).ServiceTerritoryId ) && ( resrcAbsnce.Start <= timeSlot.Start_Time__c && resrcAbsnce.End >= timeSlot.End_Time__c ) )
                {
                    system.debug(actionStr + ' Name: ' + timeSlot.Name + ' Type: ' +  servTerrByServRes.get( resrcAbsnce.ResourceId ).ServiceResource.Type__c  + ' Start Time: ' + timeSlot.Start_Time__c + ' End Time: ' + timeSlot.End_Time__c);

                    if (actionStr == 'Set'){
                        if (servTerrByServRes.get( resrcAbsnce.ResourceId ).ServiceResource.Type__c == 'Back Room' ) timeSlot.isBackUnavailable__c = true;
                        if (servTerrByServRes.get( resrcAbsnce.ResourceId ).ServiceResource.Type__c == 'Front Room' ) timeSlot.isFrontUnavailable__c = true;
                    } else if (actionStr == 'Clear'){
                        if (servTerrByServRes.get( resrcAbsnce.ResourceId ).ServiceResource.Type__c == 'Back Room' ) timeSlot.isBackUnavailable__c = false;
                        if (servTerrByServRes.get( resrcAbsnce.ResourceId ).ServiceResource.Type__c == 'Front Room' ) timeSlot.isFrontUnavailable__c = false;
                    }
                }
            }
        }
        update tmeSlots;

    } // End of update_IsUnavaiilable()


    // This function gets all the time slots between the ResourceAbsence Stert and End Datetime
    public static List<Appt_Time_Slot__c> getTimeSlotsSets( Map<Id, ResourceAbsence> newMap, Map<Id, ServiceTerritoryMember> servTerrByServRes, Map<Id, String> whereClauseMap)
    {
        system.debug('getTimeSlotsSets() - Resource Absences periods: ' + whereClauseMap.size());
        List<Appt_Time_Slot__c> tmeSlots;

        // create the Query string
        String queryString = 'SELECT Id,Name,Start_Time__c,End_Time__c,Service_Territory__c,isBackUnavailable__c,isFrontUnavailable__c FROM Appt_Time_Slot__c WHERE ';

        Boolean orTag = false;
        // create the where filter by ResourceAbsence and Territory (Store) / indexed by ServiceResource
        for (ResourceAbsence resAb : newMap.values())
        {
            if (orTag){
                queryString += ' OR ';  
            }
            queryString += '(Service_Territory__c=\'' + servTerrByServRes.get(resAb.ResourceId).ServiceTerritoryId + '\' AND Type__c = \'' + servTerrByServRes.get(resAb.ResourceId).ServiceResource.Type__c + '\' AND ' + whereClauseMap.get(resAb.Id) + ')';
            orTag = true;
        }
        System.debug('getTimeSlotsSets() - Query String: ' + queryString);

        // get all the Time Slots for the ServiceTerritories with the ServiceResources on the Days being "Absenced"
        try {
            tmeSlots = Database.query(queryString);
            system.debug('getTimeSlotsSets() - Retrieved TimeSlots: ' + tmeSlots.size());
        } catch (Exception e) {
            //-- caught exception, do nothing
            system.debug('getTimeSlotsSets() - WARNING! Caught exception executing SOQL, returning null - e: ' + e.getMessage());
        }

        return tmeSlots;

    } // End of getTimeSlotsSets()

} // End of class Appt_ResourceAbsenceTriggerHandler
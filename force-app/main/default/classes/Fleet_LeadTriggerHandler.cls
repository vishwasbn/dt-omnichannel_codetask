public class Fleet_LeadTriggerHandler
{
    public static String lprefix = 'FLEET_LTH:';

    //---Primary Lead Trigger Handler for Fleet
    public static void handle(Map<Id, Lead> oldMap, Map<Id, Lead> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Fleet LeadTrigger Handler - START');

        switch on triggerEvent 
        {
            when BEFORE_INSERT 
            {
                //updatePublicNotes(newMap.values());
            }
            when AFTER_INSERT 
            {
                
            }
            when BEFORE_UPDATE 
            {
                processBeforeLeadChange(oldMap, newMap);
                updatePublicNotes(newMap.values());
            }
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + 'Fleet LeadTrigger Handler - END');
    }
    
    public static void updatePublicNotes(List<Lead> newMap)
    {
        for(Lead rec : newMap)
        {
            if(rec.Fleet_Public_Notes__c != NULL)
            {
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('<b>', '**strong**').replace('</b>', '**/strong**');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('<strong>', '**strong**').replace('</strong>', '**/strong**');
                
                String notes = '';
                for(String s : rec.Fleet_Public_Notes__c.split('<br>'))
                {
                    if(s.contains('</p>'))
                        notes += s;
                    else
                        notes += s+'<br>';
                }
                
                rec.Fleet_Public_Notes__c = notes;
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('</p>', '<br>');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.stripHtmlTags();
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('\r\n', '<br>').replace('\r', '<br>').replace('\n', '<br>');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('**strong**', '<strong>').replace('**/strong**', '</strong>');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace(' <br>', '<br>').replace('<br> ', '<br>');
            }
        }
    }

    //--Process before change for Lead Owner change, and then make them the Fleet Specialist (if not the queue)
    public static void processBeforeLeadChange(Map<Id, Lead> oldMap, Map<Id, Lead> newMap)
    {   
        Id b2bRT = Schema.Sobjecttype.Lead.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        List<Lead> b2bLeadList = new List<Lead>();

        System.debug( lprefix + 'Processing the following Leads: ' + newMap);
        
        //---Loop through the changed records
        for( Lead newObj : newMap.values())
        {
            //---Only process the B2B
            if (newObj.RecordTypeId == b2bRT)
            {
                //---Get the Old Record
                Lead oldObj = oldMap.get( newObj.Id);

                if (oldObj != null)
                {
                    //---Only act if the owner has changed
                    if (newObj.OwnerId != oldObj.OwnerId)
                    {
                        System.debug( lprefix + 'Found Lead with changed Owner, Old: ' + oldObj + '  New: ' + newObj);

                        //---Only add b2bleads that have the owner field changed
                        b2bLeadList.add( newObj);
                    }
                }
            }
        }

        //---Process the Lead List
        if (b2bLeadList.size() > 0)
        {
            //---Get the Lead Queue
            Id leadQueueId;
            List<Group> leadGroups = [SELECT Id FROM Group WHERE Type = 'Queue' AND NAME = 'B2B Leads Queue'];
            if (leadGroups != null && leadGroups.size() > 0) leadQueueId = leadGroups[0].Id;

            System.debug( lprefix + 'Found the following Lead Queue: ' + leadQueueId + '  Processsing the following list: ' + b2bLeadList);

            for( Lead lRow : b2bLeadList)
            {
                if (lRow.OwnerId != leadQueueId)
                {
                    lRow.Fleet_Specialist__c = lRow.OwnerId;
                    lRow.Assigned_Date__c = Date.today();

                    System.debug( lprefix + 'Updated Lead: ' + lRow);
                }
            }
        }
    }
}
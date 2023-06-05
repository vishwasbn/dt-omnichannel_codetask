public class Fleet_SpecialistUserTriggerHandler {
    public static void handle(System.TriggerOperation triggerEvent){
         switch on triggerEvent 
        {
           
            when AFTER_UPDATE 
            {   
                resetPriority();      
            }
            when else {
                //do nothing 
            }
        }
    }
    public static void resetPriority() {
        List<User> updatedUserList =new List<User>();
        //count
        AggregateResult[] groupedResults = [SELECT count(Id) FROM User WHERE IsActive = true AND Fleet_Is_Specialist__c = TRUE];
        Integer count=(Integer)groupedResults[0].get('expr0');
        System.debug('count '+count);
        //max value
        AggregateResult[] groupedResultsMax = [SELECT Max(LeadAssignmentPriority__c) FROM User WHERE IsActive = true AND Fleet_Is_Specialist__c = TRUE];
        Decimal maxValue=(Decimal)groupedResultsMax[0].get('expr0');
        Integer max=maxValue.intValue();
        System.debug('max '+max);
        if((count-1) < max){
            List<User> userList=[SELECT Id, Name, LeadAssignmentPriority__c FROM User WHERE IsActive = true AND Fleet_Is_Specialist__c = TRUE order by LeadAssignmentPriority__c ];
        
        for(Integer i=count-1; i>=0; --i){
            System.debug('userList i '+userList.get(i));
            User usr =userList.get(i);
            usr.LeadAssignmentPriority__c=i;
            updatedUserList.add(usr);
        }
        update updatedUserList;
        }
        
    }
    
    
    
    
    
    
}
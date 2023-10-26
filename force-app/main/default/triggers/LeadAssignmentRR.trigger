trigger LeadAssignmentRR on Lead (before insert,before update) {
    
    if(trigger.Isbefore){
        if(Trigger.isInsert){ 
            system.debug('@@@ new Lead insert: '+Trigger.new);
            system.debug('===');
            //system.debug('@@@ new Lead: '+Trigger.new);
            for(Lead ll: trigger.new){ 
                system.debug('==='+ll.createdby);
                if(!ll.isLeadAssigned__c){
                    system.debug('@@@ ll.Fleet_Specialist_Id__c: '+ ll.Fleet_Specialist_Id__c);  
                    system.debug('@@@ ll.country__c: '+ ll.country__c);
                    if(ll.Fleet_Specialist_Id__c != null && ll.country__c == 'United States'){
                        LeadAssignmentRRHandler.AssignToFleetSpecialist(Trigger.new);
                    }if(ll.Fleet_Specialist_Id__c == null && ll.country__c == 'United States'){
                        LeadAssignmentRRHandler.ProcessLeadWithExactMatchOnInsert(Trigger.new);
                    } 
                }
                             
            }
        }
        
        if(Trigger.isUpdate){
            system.debug('@@@ new Lead update: '+Trigger.newMap);
           /* for(Lead ll: trigger.new){
                if(ll.Fleet_Specialist_Id__c != null && ll.country__c == 'United States'){
                    LeadAssignmentRRHandler.AssignToFleetSpecialistOnUpdate(Trigger.new,Trigger.old);
                }if(ll.Fleet_Specialist_Id__c == null && ll.country__c == 'United States'){
                    LeadAssignmentRRHandler.ProcessLeadWithExactMatchOnInsert(Trigger.new);
                }
            } */       
        }
    }else{
        
        for(Lead l : trigger.New){
            
            system.debug('----'+l.id);
        }
    }
}
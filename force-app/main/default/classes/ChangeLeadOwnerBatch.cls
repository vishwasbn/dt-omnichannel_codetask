global class ChangeLeadOwnerBatch implements Database.Batchable <sObject>,Database.Stateful,schedulable{
    
    List<Lead> leadLst = new List<Lead>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select id,isLeadAssigned__c,Fleet_Specialist__c,Fleet_Specialist_Id__c,country__c,State__c,Selectedcity__c,Fleet_Purchase_Product__c,OwnerId from Lead where isLeadAssigned__c = true and createdby.name = \'Fleet Community Site Guest User\' and isconverted = false order by CreatedDate ASC';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc,List<Lead> batch) {
        System.debug('==Batch=='+batch.size());
        
        
        
         for(Lead ll: batch){
            
           // if(ll.Fleet_Specialist_Id__c == null && ll.country__c == 'United States'){          
                ll.isLeadAssigned__c = false;
                leadLst.add(ll);
            
          }
         
         if(leadLst.size()>0 && leadLst!= null){
         LeadAssignmentRRHandler.assigntofleetspecialist(leadLst);
         }
      
       
        
        
              
        
        if(!leadLst.isEmpty())
            update leadLst;
        System.debug('== Updated Lead List=='+leadLst);    
    }
    
    global void finish(Database.BatchableContext bc) {
        //Do Nothing.
    }
    
    public void execute(SchedulableContext sc) {
        ChangeLeadOwnerBatch mbtBatch = new ChangeLeadOwnerBatch();
        Database.executeBatch(mbtBatch);
    } 
}
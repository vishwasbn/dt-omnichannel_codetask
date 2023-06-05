public without sharing class Appt_InsertShareRecordQueueable implements Queueable{

    List<ServiceTerritoryShare> newSharedStoresList = new List<ServiceTerritoryShare>();
    // constructor that accepts a list of share records 
    public Appt_InsertShareRecordQueueable(List<ServiceTerritoryShare> newSharedStoresList ) {
        this.newSharedStoresList = newSharedStoresList;
    }

    // execute method ot insert the share records
    public void execute(QueueableContext context) {
        System.debug('Appt_InsertShareRecordQueueable.execute Start'); 
        System.debug('Share List ' + newSharedStoresList); 
        if(newSharedStoresList.size() > 0){
            System.debug('Before insert - START');
            System.debug('Before Insert List:' + newSharedStoresList);
            insert newSharedStoresList;
            System.debug('First Id: ' + newSharedStoresList[0].id);
            System.debug('After insert - End');
        }    
        System.debug('Appt_InsertShareRecordQueueable.execute End');    
    }
}
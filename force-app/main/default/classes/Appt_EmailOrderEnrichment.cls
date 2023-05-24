public class Appt_EmailOrderEnrichment implements Queueable, Database.AllowsCallouts{
    public static String lprefix = 'APPT_mailOrderEnrichmentQueue: ';

    List<id> idsToProcess;

    // instantiates the object, expects notification ids to be passed in
    public Appt_EmailOrderEnrichment(List<id> idsToProcess) {
        this.idsToProcess = idsToProcess;
    }


    // executable method that will possess the notification ids
    public void execute(QueueableContext context){

        //---06.09.22.SS - Switch to new SFMC Email System
        Boolean useSFMCEmail = Appt_SettingUtil.getSettingBooleanValue( 'Use_SFMC_Email');

        if (useSFMCEmail)
        {
            System.debug(lprefix + 'Using new SFMC Email, no need for this processing');
            return;
        }


        System.debug(lprefix + 'Start Process execute method');
        System.debug(idsToProcess);
        System.debug('ids count' + idsToProcess.size());

        id processId;
        // pulls the last id off the list to be processed
        for (Integer i = (idsToProcess.size()-1) ; i>= 0 ; i--){            
            processId = idsToProcess.remove(i);
            break;            
        } 
        System.debug('ID SELECTED');
        System.debug(processId);

        System.debug('IDs Left');
        System.debug(idsToProcess);
        System.debug('ids count' + idsToProcess.size());               

        // Sends selected id to be processed 
        try{
            Appt_EmailBatch.processNotification(processId, idsToProcess);
        } catch (Exception e) {
            System.debug('Error: ' +e.getMessage());
            // keeps the pocess going for the next notifications even if this particular notification errors out
            // creates a new queued job to process the remaining ids
            if(idsToProcess.size() > 0){
                
                // Excludes chaining methods for tests
                if(!Test.isRunningTest()){
                    System.enqueueJob(new Appt_EmailOrderEnrichment(idsToProcess));
                }
                
            } else {
                System.debug(lprefix + 'All Ids have been processed');
            }

            List <Notification__c> errorNotify = [SELECT id FROM Notification__c WHERE id = :processId LIMIT 1];
            if(errorNotify.size() > 0){
                errorNotify[0].Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR;
                errorNotify[0].Last_Error_Message__c = e.getMessage();
            }
            

        }
        
        System.debug(lprefix + 'End Process execute method');
    }

    // accpets a list of notifications and then creates queued job(s) to add order information to the notification record
    public static void buildQueueableJobs(List<notification__c> notificationsToProcess){

        //---06.09.22.SS - Switch to new SFMC Email System
        Boolean useSFMCEmail = Appt_SettingUtil.getSettingBooleanValue( 'Use_SFMC_Email');

        if (useSFMCEmail)
        {
            System.debug(lprefix + 'Using new SFMC Email, no need for this processing');
            return;
        }

        // capture notification ids
        List <id> idList = new List <id>();
        Set<Id> resultIds = (new Map<Id,Notification__c>(notificationsToProcess)).keySet();
        idList.addAll(resultIds);

        // Checks for a large amount of notifications to be processed and splits them into multiple queueable jobs if more than 20 are proccessed
        /*if(idList.size() > 20)
        {
            List<id> list1 = new List<id>();
            List<id> list2 = new List<id>();
            List<id> list3 = new List<id>();
            List<id> list4 = new List<id>();
            List<id> list5 = new List<id>(); 
            Integer position = 1;
            
            for(id notif :idList)
            {
                // evenly create sub lists to process
                switch on position {
                    when 1 {                        
                        list1.add(notif);
                    }
                    when 2 {
                        list2.add(notif);
                    }
                    when 3 {
                        list3.add(notif);
                    }
                    when 4 {
                        list4.add(notif);
                    }
                    when 5 {
                        list5.add(notif);
                    }                               
                    
                }

                if(position == 5){
                    position = 1;
                } else {
                    position += 1;
                }

            }

            // creates 5 queuable jobs to speed up the async process
            if(list1.size() > 0){
                System.enqueueJob(new Appt_EmailOrderEnrichment(list1));
            }  
            if(list2.size() > 0){
                System.enqueueJob(new Appt_EmailOrderEnrichment(list2));
            }
            if(list3.size() > 0){
                System.enqueueJob(new Appt_EmailOrderEnrichment(list3));
            }
            if(list4.size() > 0){
                System.enqueueJob(new Appt_EmailOrderEnrichment(list4));
            }
            if(list5.size() > 0){
                System.enqueueJob(new Appt_EmailOrderEnrichment(list5));
            }    

        } else {*/
            // if less than 20 ids need to be processed just one job is created
            if(idList.size() > 0){
                System.enqueueJob(new Appt_EmailOrderEnrichment(idList));
            }
        //}        
    }
}
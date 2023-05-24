public class Appt_CapacityUpdateHistoryBatch implements Database.Batchable<sObject> {

    Integer maxRecords = 9500;
    Map<Id, List<Appt_Capacity_Update_History__c>> storeRecordsMap = new Map<Id, List<Appt_Capacity_Update_History__c>>();



    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('>>>> Start QUERY records for Appt_CapacityUpdateHistoryBatch');
        //Queries 4 Service Territories specified in schedule class
        return Database.getQueryLocator(
            'SELECT ID, Total_Appt_Capacity_Update_History__c ' +
            'FROM ServiceTerritory ' +
            'WHERE Total_Appt_Capacity_Update_History__c > ' +  String.valueOf(maxRecords)
        );
        
    }


    // execute method that runs to process the records
    public void execute(Database.BatchableContext bc, List<ServiceTerritory> records){
        //Determine records to be deleted
        System.debug('>>>> Record to be processed' + records);
        Set<Id> recordIDs = new Set<Id>();
        for (ServiceTerritory territory : records) {
            recordIDs.add(territory.id);// Create list of IDs from the 4 service territory records
            System.debug('>>>> Add Record to be processed' + recordIDs);
        }
        
        if (recordIDs.size() > 0) {
            List<Appt_Capacity_Update_History__c> recordsToBeProcessed = [SELECT ID, 
                                                                            Service_Territory__c, 
                                                                            Service_Territory__r.Total_Appt_Capacity_Update_History__c, 
                                                                            CreatedDate 
                                                                            FROM Appt_Capacity_Update_History__c 
                                                                            WHERE Service_Territory__c IN :recordIDs 
                                                                            ORDER BY CreatedDate ASC 
                                                                            LIMIT 50000];


            System.debug('>>>> Finish recordsToBeProcessed: ' + recordsToBeProcessed);
            System.debug('>>>> Finish records IDs: ' + recordIDs);
            List<Appt_Capacity_Update_History__c> recordsToDelete = getRecordsToDelete(recordsToBeProcessed, recordIDs);
            doDml(recordsToDelete);
        }

    }

    public void finish(Database.BatchableContext bc){
        System.debug('>>>> Finish Appt_CapacityUpdateHistoryBatch');
    }

    // determines the records that need to be deleted from the list of Appt_Capacity_Update_History__c for each Service Territory
    public List<Appt_Capacity_Update_History__c> getRecordsToDelete(List<Appt_Capacity_Update_History__c> recordsToBeProcessed, Set<Id> recordIDs) {

        System.debug('>>>> Start getRecordsToDelete');
        System.debug('>>>> Records To Be Processed Size: ' + recordsToBeProcessed.size());
        System.debug('>>>> Records To Be Processed: ' + recordsToBeProcessed);
        List<Appt_Capacity_Update_History__c> returnList = new List<Appt_Capacity_Update_History__c>();

        // Groups the Appt_Capacity_Update_History__c records to a list of records per Service Territory
        for (Id serviceTerritoryId : recordIDs) {
            getStoreRecords(recordsToBeProcessed, serviceTerritoryId);

        }
        System.debug('>>>> Store Records Map Size: ' + storeRecordsMap.size());
        System.debug('>>>> Store Records Map: ' + storeRecordsMap);

        // Loops through the list of stores to get the delete list
        for (Id key : storeRecordsMap.keySet()) {

            List<Appt_Capacity_Update_History__c> storeRecordsToDelete = getIndividualStoreRecordsToDelete(storeRecordsMap.get(key));
            if (storeRecordsToDelete.size() > 0) {
                returnList.addAll(storeRecordsToDelete);
            }

        }

        System.debug('>>>> End getRecordsToDelete');
        return returnList;
    }

    // Determines what individual records should be grouped up to delete the oldest records
    public List<Appt_Capacity_Update_History__c> getIndividualStoreRecordsToDelete(List<Appt_Capacity_Update_History__c> recordsToBeProcessed) {
        List<Appt_Capacity_Update_History__c> returnList = new List<Appt_Capacity_Update_History__c>();
        Integer maxIndividualStoreRecords = Integer.valueOf(recordsToBeProcessed[0].Service_Territory__r.Total_Appt_Capacity_Update_History__c);
        Integer minRecordsToDelete = maxIndividualStoreRecords - maxRecords;
        System.debug('>>>> Min Records: ' + minRecordsToDelete);
        System.debug('>>>> Max Individual Store Records: ' + maxIndividualStoreRecords);
        System.debug('>>>> Max Records: ' + maxRecords);
        Integer recordsProcessed = 0;
        Datetime lastValidTransactionDate;

        for (Appt_Capacity_Update_History__c record : recordsToBeProcessed) {
            //System.debug('>>>> Records ' + record);
            recordsProcessed += 1;
            // finds the oldest records
            if (recordsProcessed <= minRecordsToDelete) {
                lastValidTransactionDate = record.CreatedDate;
                returnList.add(record);
            // once under 9500 find the group of records for the last transaction completed to delete
            } else if (record.CreatedDate == lastValidTransactionDate || record.CreatedDate.addMinutes(-1) < lastValidTransactionDate) {
                System.debug('>>>> Create Date Time: ' + record.CreatedDate + ' --- ' + lastValidTransactionDate.addMinutes(-1));
                returnList.add(record);
            } else {
                // under 9500 and the final record for the last batch of changes has been found
                break;
            }
        }
        System.debug('>>>> Return List Size ' + returnList.size());
        return returnList;
    }


    // Get all Appt_Capacity_Update_History__c the records for the stores to be processed
    public void getStoreRecords(List<Appt_Capacity_Update_History__c> records, Id serviceTerritoryId) {
        List<Appt_Capacity_Update_History__c> storeRecords = new List<Appt_Capacity_Update_History__c>();

        for (Appt_Capacity_Update_History__c record : records ) {
            if (record.Service_Territory__c == serviceTerritoryId) {
                storeRecords.add(record);//all records from each service territory
            }
        }
        if (storeRecords.size() > 0) {
            storeRecordsMap.put(storeRecords[0].Service_Territory__c, storeRecords);
        }

    } 

    // Complete the DML for the process
    public void doDml(List<Appt_Capacity_Update_History__c> deleteList) {

        System.debug('>>>> Records To Be Deleted Size: ' + deleteList.size());
        System.debug('>>>> Records To Be Deleted: ' + deleteList);
        // limits it to 10k records to keep from running into a DML limit if it was to ever happen. The records not found would be picked up in the next run
        if (deleteList.size() > 10000) {
            for(Integer i = deleteList.size() - 1; i >= 0; i--){
                deleteList.remove(i);
                if (deleteList.size() < 10000) {
                    break;
                }
            }
        }
        // deletes the records
        if (deleteList.size() > 0) {
            try {
                delete deleteList;
            } catch (Exception e) {
                System.debug('>>>> Delete Error: ' + e.getMessage());
            }
            
        }

    }

}
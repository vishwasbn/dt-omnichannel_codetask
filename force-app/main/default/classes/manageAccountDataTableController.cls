public with sharing class manageAccountDataTableController {
    @testVisible
    private static Boolean throwException = false;

    private virtual class BaseException extends Exception {}
    private class OtherException extends BaseException {}
    
    @AuraEnabled(Cacheable = true)
    public static Id getRecordTypeId() {
        try {
            if(manageAccountDataTableController.throwException){
                throw new OtherException('Script-thrown exception');
            }
            Id recordTypeId = [SELECT id from RecordType where Name ='Fleet Community Case'].id;
            return recordTypeId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(Cacheable = true)
    public static Id getAccounts() {
        try {
            if(manageAccountDataTableController.throwException){
                throw new OtherException('Script-thrown exception');
            }
            Account acct = [SELECT Id, Name,OwnerId FROM Account LIMIT 1];
            return acct.id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(Cacheable = true)
    public static User getContact(string userId) {
        try {
            if(manageAccountDataTableController.throwException){
                throw new OtherException('Script-thrown exception');
            }
            User user = [select id, name, contactId, Email from user where id= :userId];
            return user;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable = true)
    public static Id getGroupId(){
        try {
             if(manageAccountDataTableController.throwException){
                throw new OtherException('Script-thrown exception');
            }
            Group grp = [select id, Name, type from group where type='queue' AND Name='AR Group Queue' LIMIT 1];
            return grp.id;
        } catch (Exception e) {
            system.debug('@@@ '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}
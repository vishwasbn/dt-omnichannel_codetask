/**
 * Created by jasondaluga on 7/11/18.
 */

public with sharing class Peak_LinkedInController {
    @AuraEnabled
    public static String getMetaData(String recordLabel){
        System.debug(recordLabel);
        X7Summits_Social_Component_Settings__mdt setting = [SELECT LinkedIn_Featured_Posts__c FROM X7Summits_Social_Component_Settings__mdt WHERE DeveloperName = :recordLabel];

        return setting.LinkedIn_Featured_Posts__c;
    }
}
/**
 * Created by kentheberling on 8/23/18.
 */


/*
    Get a single record, returning a Peak Response
        results list = well, just the one record
        peakResults list = fields with translated labels, passing through security!
 */
public with sharing class Peak_RecordDetailController {

    @AuraEnabled
    public static Peak_Response getRecordDetail(String recordIdString, String objectType,String fieldsString){
        Peak_Response peakResponse = new Peak_Response();

        // Split incoming string after removing any white space
        fieldsString = fieldsString.replaceAll(' ','');
        List<String> fields = fieldsString.split(',');

        // Build query string for this object, fields, and record ID
        String queryString = Peak_RecordQueryHelper.buildQueryString(objectType,fields,Peak_RecordQueryHelper.buildIdWhereClause(recordIdString));

        try{
            peakResponse.results = Peak_RecordQueryHelper.executeQuery(queryString);

            // If results are found (we did get the record detail), format fields with translated labels
            if(!Peak_Utils.isNullOrEmpty(peakResponse.results)){
                peakResponse.peakResults = Peak_RecordQueryHelper.formatRecordDetailWithLabels(objectType,peakResponse.results[0],fields);
            }
        } catch (Exception e){
        	peakResponse.success = false;
        	peakResponse.messages.add(e.getMessage());
        }
        return peakResponse;
    }


}
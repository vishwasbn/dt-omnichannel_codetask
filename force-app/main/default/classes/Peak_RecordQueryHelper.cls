/**
 * Created by kentheberling on 8/23/18.
 */

public with sharing class Peak_RecordQueryHelper {

    /*
        Execute query
     */
    public static List<sObject> executeQuery(String queryString){
        return Database.query(queryString);
    }

    /*
       Build a query
    */
    public static String buildQueryString(String objectType,List<String> fields, String whereClause){

        // Start off string
        String queryString = 'Select ';

        // Fields
        String fieldsList =  String.escapeSingleQuotes(Peak_Utils.buildStringFromList(fields));// Escape (prevent injection), build String from list
        queryString += fieldsList;

        // From clause
        queryString += ' from ' +  String.escapeSingleQuotes(objectType);

        // Where clause
        if (whereClause != null){
            queryString += ' where ' + whereClause;
        }

        // TODO, limit clause

        return queryString;
    }

    /*
        Build a where clause for a detail (by ID)
     */
    public static String buildIdWhereClause(String recordIdString){
        return 'Id = \'' + String.escapeSingleQuotes(recordIdString) + '\'';
    }

    /*
        Format a detail result as Peak Content Objects to get field labels!
     */
    public static List<Peak_ContentObject> formatRecordDetailWithLabels(String objectType, SObject recordDetail,List<String> fields){

        // Get describe, object schema, and field map
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get(objectType);
        Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();

        // List of PCO to return
        List<Peak_ContentObject> labeledFields = new List<Peak_ContentObject>();

        // For each field, check if user can see it, and if so, get it's label, map to value in a PCO, add to list
        for(String fieldName : fields){

            // Is this field accessible to user?
            if (fieldMap.get(fieldName).getDescribe().isAccessible()){
                Peak_ContentObject fieldLabelValue = new Peak_ContentObject();

                // Set "title" as the field name. We will use this on the front end
                fieldLabelValue.title = fieldName; // Not doing this anymore! fieldMap.get(fieldName).getDescribe().getLabel(); // get the label (translation!) for this field

                // get value from our queried record detail. This will ONLY be used later to determine if the value is null! Therefore, we can cram it into a string
                fieldLabelValue.description = String.valueOf(recordDetail.get(fieldName));

                // Add to list
                labeledFields.add(fieldLabelValue);
            }
        }

        return labeledFields;
    }
}
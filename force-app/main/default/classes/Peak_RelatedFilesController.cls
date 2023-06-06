/**
 * Created by kentheberling on 6/7/18.
 */

public with sharing class Peak_RelatedFilesController {

    /*
        Get attachments a User added to a Record
     */
    @AuraEnabled
    public static Peak_Response getFilesForCurrentUserForRecord(String recordIdString){
        // Init response
        Peak_Response peakResponse = new Peak_Response();

        // Call Helper
        peakResponse = Peak_FilesHelper.getFilesForCurrentUserForRecord(UserInfo.getUserId(),Id.valueOf(recordIdString));

        // Return
        return peakResponse;
    }

}
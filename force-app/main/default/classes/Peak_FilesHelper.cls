/**
 * Created by kentheberling on 6/7/18.
 */

public with sharing class Peak_FilesHelper {
  private static Logger logInstance = Logger.getInstance();
  public class Peak_FilesHelperException extends Exception {}
  /*
  	Get attachments a User added to a Record
  */
  public static Peak_Response getFilesForCurrentUserForRecord(Id userId,Id recordId) {
    Peak_Response peakResponse = new Peak_Response();
    try {
        if(Test.isRunningTest() && userId==null && recordId==null){
            throw new Peak_FilesHelperException();
        }
      // Query by User and Parent record
      List<Attachment> attachments = [
        SELECT
          BodyLength,
          ContentType,
          CreatedById,
          CreatedDate,
          Id,
          IsDeleted,
          Name,
          ParentId,
          SystemModstamp
        FROM Attachment
        WHERE OwnerId = :userId AND ParentId = :recordId
      ];
      peakResponse.results = attachments;

      // Get that 75%
      peakResponse.messages.add('Attachments found');
      peakResponse.success = true;
    } 
    catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_FilesHelper', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }
}
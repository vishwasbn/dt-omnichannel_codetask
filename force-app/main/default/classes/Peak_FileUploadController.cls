public without sharing class Peak_FileUploadController {
  private static Logger logInstance = Logger.getInstance();
  //Get the file restrictions set by the community. If not set it will take the restrictions from Salesforce
  @AuraEnabled
  public static Peak_Response getFileRestrictions() {
    Peak_Response peakResponse = new Peak_Response();
    System.debug('getFileRestrictions ===');
    try {
      String networkId = Network.getNetworkId();
      Network curNetwork;
      List<Network> networkList;
      if (Test.isRunningTest()) {
        networkId = [SELECT Id FROM Network LIMIT 1][0].Id;
      }
      networkList = [
        SELECT Id, MaxFileSizeKb, AllowedExtensions
        FROM Network
        WHERE Id = :networkId
      ];
      if (!Peak_Utils.isNullOrEmpty(networkList)) {
        curNetwork = networkList[0];
      }
      //If max file size of the community exceeds ~4.2mb set it to that. This is a apex heap limit.
      if (
        curNetwork.MaxFileSizeKb == null ||
        curNetwork.MaxFileSizeKb == 0 ||
        curNetwork.MaxFileSizeKb > 4248
      ) {
        curNetwork.MaxFileSizeKb = 4248;
        //If the heap issue ever gets fixed then set the max size to the Salesforce max file size of 2GB.
        //curNetwork.MaxFileSizeKb = 2097152;
      }
      peakResponse.results.add(curNetwork);
      peakResponse.success = true;
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_FileUploadController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }

  //Save the file chunk that is passed from the front end.
  @AuraEnabled
  public static Peak_Response saveChunk(
    Id parentId,
    String fileName,
    String base64Data,
    String contentType,
    String fileId
  ) {
    Peak_Response peakResponse = new Peak_Response();
    try {
      Attachment uploadedFile;
      Peak_ContentObject peakObject = new Peak_ContentObject();
      if (fileId == '' || fileId == null) {
        //If this is a new file chunk create a new file attachment
        uploadedFile = saveTheFile(parentId, fileName, base64Data, contentType);
      } else {
        //If this the chunk is associated with an already existing file attachment then append the chunk to the existing chunk
        uploadedFile = appendToFile(fileId, base64Data);
      }
      peakObject.contentID = uploadedFile.Id;
      peakResponse.peakResults.add(peakObject);
      peakResponse.success = true;
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_FileUploadController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }

  //Create the file attachment.
  public static Attachment saveTheFile(
    String parentId,
    String fileName,
    String base64Data,
    String contentType
  ) {
    base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

    Attachment fileAttachment = new Attachment();
    fileAttachment.parentId = parentId;

    fileAttachment.Body = EncodingUtil.base64Decode(base64Data);
    fileAttachment.Name = fileName;
    fileAttachment.ContentType = contentType;

    insert fileAttachment;
    return fileAttachment;
  }

  //Append the file chunk to the previously added chunk
  public static Attachment appendToFile(String fileId, String base64Data) {
    base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

    Attachment existingAttachment = [
      SELECT Id, Body, Name, ContentType
      FROM Attachment
      WHERE Id = :fileId
    ];

    String existingBody = EncodingUtil.base64Encode(existingAttachment.Body);

    existingAttachment.Body = EncodingUtil.base64Decode(
      existingBody + base64Data
    );

    update existingAttachment;
    return existingAttachment;
  }

  //Delete the file attachment
  @AuraEnabled
  public static Peak_Response deleteAttachment(
    String fileName,
    String parentId
  ) {
    Peak_Response peakResponse = new Peak_Response();
    try {
      Attachment deleteAttachment;
      List<Attachment> attachmentList = [
        SELECT Id, Name, ParentId
        FROM Attachment
        WHERE ParentId = :parentId AND Name = :fileName
      ];
      if (!Peak_Utils.isNullOrEmpty(attachmentList)) {
        deleteAttachment = attachmentList[0];
      }
      delete deleteAttachment;
      peakResponse.success = true;
      peakResponse.messages.add('File deleted successfully');
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_FileUploadController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }
}
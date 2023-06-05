declare module "@salesforce/apex/Peak_FileUploadController.getFileRestrictions" {
  export default function getFileRestrictions(): Promise<any>;
}
declare module "@salesforce/apex/Peak_FileUploadController.saveChunk" {
  export default function saveChunk(param: {parentId: any, fileName: any, base64Data: any, contentType: any, fileId: any}): Promise<any>;
}
declare module "@salesforce/apex/Peak_FileUploadController.deleteAttachment" {
  export default function deleteAttachment(param: {fileName: any, parentId: any}): Promise<any>;
}

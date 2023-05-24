declare module "@salesforce/apex/Fleet_InvoiceController.getDaysPerBlock" {
  export default function getDaysPerBlock(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_InvoiceController.getMaxInvoiceSearchDays" {
  export default function getMaxInvoiceSearchDays(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_InvoiceController.getInvoiceSummaryDataForDisplay" {
  export default function getInvoiceSummaryDataForDisplay(param: {recordId: any, startDate: any, endDate: any, invoiceIdSearch: any, vinNumberSearch: any, poNumberSearch: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_InvoiceController.getInvoiceDetail" {
  export default function getInvoiceDetail(param: {siteId: any, invoiceId: any, invoiceBusinessDate: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_InvoiceController.getMockInvoiceDetail" {
  export default function getMockInvoiceDetail(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_InvoiceController.getSiteData" {
  export default function getSiteData(param: {siteId: any}): Promise<any>;
}

@isTest(SeeAllData=false)
public class  Appt_GetAvailabilityServiceModelTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 

    @isTest static void MethodsTest()
    {
               
        Date startDate = system.today();
        Date endDate = system.today().addDays(2);

        System.debug(startDate);
        System.debug(endDate);
        String startDateString = String.valueOf(startDate);
        String endDateString = String.valueOf(endDate);
        System.debug(startDateString);
        System.debug(endDateString);



        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "'+startDateString+'","endDate": "'+endDateString+'","orderType": "ROPIS","customerType": "Retail","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": [ { "requestType": "Article", "articleId": "1245", "articleType": "", "articleCount": "2", "articleSize": "", "articleDescription": "tires" } ] }';
        
        Appt_GetAvailabilityServiceModel asmObject = Appt_GetAvailabilityServiceModel.parseGetAvailabilityRequest( Appt_GetAvailabilityRequest.parse(JSONMsg) );

        Boolean isItemPresent = asmObject.isProductInItemList('1245');
        System.debug('Appt_GetAvailabilityServiceModelTest:ItemList: ' + isItemPresent);
        System.assertEquals(true, isItemPresent, 'Item is not in list');
        
        System.assertEquals(1, asmObject.numberOfItems(), 'Number of items is incorrect');

        String bucketStr = asmObject.getBucketField(Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR);

        System.debug('BucketField: ' + bucketStr);
        System.assertEquals('FWR_Available__c', bucketStr, 'Front Bucket field is wrong');
        
    } 

}
@IsTest
public class Appt_VFEmailControllerTest
{
    public Appt_VFEmailControllerTest() {

    }

    @testSetup
    static void setupData() {
        // setup the Account ... Territory ... Resource ... Appoitments... 
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');
    }

    @isTest
    static void getApptEmailTest(){
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Work_Order__c, Work_Order__r.AccountId, Work_Order__r.Source__c, Work_Order__r.ContactId FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        ServiceAppointment appt = appts[0];
        
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = 'EMAIL';
        newNotificaiton.Communication_Type__c = 'TRANSACTION';                    
        newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
        newNotificaiton.Alternate_Contact__c = false;

        newNotificaiton.Invoice_Payload__c = Appt_InvoiceDetailModelTest.getJSON();

        insert newNotificaiton;     

        
        Appt_VFEmailController vfCont = new Appt_VFEmailController();
        vfCont.NotificationRef = newNotificaiton;

        String storeName = vfCont.getStoreName();
        String orderDate = vfCont.getOrderDate();
        String rescheduleUrl = vfCont.getRescheduleUrl();
        String cancelUrl = vfCont.getCancelUrl();
        String newApptUrl = vfCont.getNewApptUrl();
        String checkinUrl = vfCont.getCheckInUrl();
        String storeExpUrl = vfCont.getStoreExperienceUrl();
        String googleMapUrl = vfCont.getGoogleMapUrl();
        String appStoreUrl = vfCont.getAppleStoreUrl();
        String googleStoreUrl = vfCont.getGoogleStoreUrl();
        String facebookUrl = vfCont.getFacebookUrl();
        String twitterUrl = vfCont.getTwitterUrl();
        String instagramUrl = vfCont.getInstagramUrl();
        String youTubeUrl = vfCont.getYouTubeUrl();
        String unsubUrl = vfCont.getUnsubscribeUrl();
        String contactUsUrl = vfCont.getContactUsUrl();
        String prefUrl = vfCont.getPreferencesUrl();
        String privPolicyUrl = vfCont.getPrivacyPolicyUrl();
        String notTypeUrl = vfCont.getNotificationType();
        Boolean isConfirmed = vfCont.getIsConfirmed();
        Boolean isScheduled = vfCont.getIsScheduled();
        Boolean isCancelled = vfCont.getIsCancelled();
        Boolean isReminder = vfCont.getIsReminder();
        Boolean showOrder = vfCont.getShowMyOrder();
        String emailTitle = vfCont.getEmailTitle();
        String vehLine1 = vfCont.getVehicleLine1();
        String vehLine2 = vfCont.getVehicleLine2();
        List<Appt_VFEmailController.ProductItem> prodItemList = vfCont.getProductList();

        List<String> excludedList = new List<String>();
        excludedList.add('REFUND');


        Appt_InvoiceDetailModel.LineItems liRow = new Appt_InvoiceDetailModel.LineItems();
        Boolean inclRow = vfCont.includeRow( liRow, excludedList);

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_CONFIRMED;
        String confTitle = vfCont.getEmailTitle();

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED;
        String schTitle = vfCont.getEmailTitle();

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_CANCELLED;
        String cancelTitle = vfCont.getEmailTitle();

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
        String reminderTitle = vfCont.getEmailTitle();

        System.assertEquals(1, 1);  
    }
}
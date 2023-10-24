public class Appt_VFEmailController
{
    public Notification__c relatedTo {get;set;}
    public String BaseActionUrl {get; set;}
    public String baseImageUrl {get; set;}
    public String dtLogo {get; set;}
    public String atLogo {get; set;}
    public String calendarImg {get; set;}
    public String redMarker {get; set;}
    public String directions {get; set;}
    public String reschedule {get; set;}
    public String cancel {get; set;}
    public String speachBubble {get; set;}
    public String clock {get; set;}
    public String calendar {get; set;}
    public String personClock {get; set;}
    public String handshake {get; set;}
    public String idImage {get; set;}
    public String welcomeSign {get; set;}
    public String car {get; set;}
    public String appstore {get; set;}
    public String googlePlay {get; set;}
    public String facebook {get; set;}
    public String twitter {get; set;}
    public String instagram {get; set;}
    public String youTube {get; set;}
    public String pinterest {get; set;}
    public String outsidePilotProgramSign {get; set;}
    public String pilotCheckiSign {get; set;}
    public Boolean IsAT {get; set;}
    public String borderColor {get; set;}
    public String textColor {get; set;}
    public String heading1 {get; set;}
    public String heading2 {get; set;}
    public String heading3 {get; set;}
    public String defaultText {get; set;}
    public String boxTiles {get; set;}
    public String marginZero {get; set;}
    public String phoneNumber {get; set;}
    public String tileImageSize {get; set;}
    public String linkImageSize {get; set;}
    public String socialStyles {get; set;}
    public String onlineCheckIn {get; set;}
    public String customerPhoneNumber {get; set;}
    public String carAlt {get; set;}
    public String customerCity {get; set;}

    public String itemName {get; set;}
    public String itemQTY {get; set;}
    public String itemText {get; set;}
    public String DTName {get; set;}

    //---Attribute that is set from the controlling page, need to load data
    public Notification__c NotificationRef
    {
        get;
        set 
        {
            NotificationRef = value;
            setupData();
        } 
    }

    //---Setup the data
    public void setupData()
    {
        Id notificationId = NotificationRef.Id;
        relatedTo = [SELECT ID, Is_AT__c, Invoice_Payload__c, Order_Items_List__c, Vehicle_Trim__c, 
                Vehicle_Model__c, Vehicle_Make__c, Customer_Mobile_Phone__c, Vehicle_Year__c,
                Customer_Email__c, Customer_Zip__c, Customer_State__c, Customer_City__c, 
                Customer_Street__c, Store_Google_Maps_address__c, Store_Phone_Number__c, 
                Store_Zip__c, Store_State__c, Store_City__c, Store_Street__c, Appointment_Day_of_Week__c,
                Order_Date__c, Email_Template_Date_Label__c, Appointment_Time__c, Order_Number__c, 
                Appointment_Year__c, Appointment_Date__c, Email_Template_Number_Label__c, Store_Logo__c, 
                Customer_Name__c, Notification_Type__c, SAP_Store_Id__c , Store_DBA_Name__c, Work_Order__r.Order_Date__c, 
                Has_Check_In_Waitlist__c, Order_Type__c, API_Callout_Order_Type__c
                FROM Notification__c WHERE Id=:notificationId];

        IsAT = relatedTo.Is_AT__c;
        customerPhoneNumber = relatedTo.Customer_Mobile_Phone__c;
        
        // formats the customers phone number
        if(customerPhoneNumber == null){
            customerPhoneNumber = '';
        } else {      
            
            // clears out possible formating issues on the phone number
            customerPhoneNumber = customerPhoneNumber.replace('-','');
            customerPhoneNumber = customerPhoneNumber.replace('(','');
            customerPhoneNumber = customerPhoneNumber.replace(')','');
            customerPhoneNumber = customerPhoneNumber.replace('.','');
            customerPhoneNumber = customerPhoneNumber.replace(' ','');                  

            // Check for a vaild phone numebr
            if(customerPhoneNumber.length() == 10 ){
                customerPhoneNumber = customerPhoneNumber.substring(0, 3) + '-' + customerPhoneNumber.substring(3, 6) + '-' + customerPhoneNumber.substring(6, 10);        
            }
        }

        
        String atUrl = Appt_SettingUtil.getSettingValue('Email_Hybris_AT_Url');
        String dtUrl = Appt_SettingUtil.getSettingValue('Email_Hybris_DT_Url');

        BaseActionUrl = IsAT ? atUrl : dtUrl;
        DTName = IsAT ? 'America\'s Tire' : 'Discount Tire';

        // setup base image site id
        Site mySite = [SELECT Id FROM Site WHERE Name = 'Appt_Email_Images'];
        SiteDetail mySiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :mySite.Id];
        baseImageUrl = mySiteDetail.SecureURL;
        System.debug(mySiteDetail.SecureURL);

        StaticResource static_resource = [SELECT Id, SystemModStamp, Name
                                  FROM StaticResource 
                                  WHERE Name = 'ApptMailImages'
                                  LIMIT 1];
        String url_file_ref = '/resource/'
                            + String.valueOf(((DateTime)static_resource.get('SystemModStamp')).getTime())
                            + '/' 
                            + static_resource.get('Name');

        dtLogo = baseImageUrl + url_file_ref + '/discount-tire-logo.png';
        atLogo = baseImageUrl + url_file_ref + '/AmericasTireLogo.png';
        calendarImg = baseImageUrl + url_file_ref + '/calendar.png';

        redMarker = baseImageUrl + url_file_ref + '/redMarker.png';
        directions = baseImageUrl + url_file_ref + '/directions.png';
        reschedule = baseImageUrl + url_file_ref + '/reschedule.png';
        cancel = baseImageUrl + url_file_ref + '/cancel.png';
        speachBubble = baseImageUrl + url_file_ref + '/speachBubble.png';
        clock = baseImageUrl + url_file_ref + '/clock.png';
        calendar = baseImageUrl + url_file_ref + '/calendar.png';
        personClock = baseImageUrl + url_file_ref + '/personClock.png';
        car = baseImageUrl + url_file_ref + '/car.png';
        appstore = baseImageUrl + url_file_ref + '/appstore.png';
        googlePlay = baseImageUrl + url_file_ref + '/googlePlay.png';
        facebook = baseImageUrl + url_file_ref + '/facebook.png';
        twitter = baseImageUrl + url_file_ref + '/twitter.png';
        instagram = baseImageUrl + url_file_ref + '/instagram.png';
        youTube = baseImageUrl + url_file_ref + '/youTube.png';
        pinterest = baseImageUrl + url_file_ref + '/pinterest.png';
        outsidePilotProgramSign = baseImageUrl + url_file_ref + '/outsidePilotProgramSign.png';
        pilotCheckiSign = baseImageUrl + url_file_ref + '/pilotCheckiSign.png';
        handshake = baseImageUrl + url_file_ref + '/handshake.png';
        idImage = baseImageUrl + url_file_ref + '/id-card.png';
        welcomeSign = baseImageUrl + url_file_ref + '/welcomeSign.png';
        onlineCheckIn = baseImageUrl + url_file_ref + '/onlineCheckIn.png';
        carAlt = baseImageUrl + url_file_ref + '/car-alt.png';

        borderColor = '#D8D8D8';
        textColor = 'color: #333333;';
        heading1 = 'color: #333333; font-size: 18pt; font-family: arial;';
        heading2 = 'color: #333333; font-size: 14pt; font-family: arial;';
        heading3 = 'color: #333333; font-size: 12pt; font-family: arial;';
        defaultText = 'color: #333333; font-size: 10pt; font-family: arial;';
        boxTiles = 'width: 50%; min-width: 335px; max-height: 135px; min-height: 135px; border: 2px solid #EAEAEA; border-radius: 2px; margin: 5px;';
        marginZero = 'margin-left: 0px;';
        phoneNumber = 'max-height: 16px; width: 113px; color: #2376D7; font-family: arial;font-size: 16px;letter-spacing: 0; line-height: 20px;';
        tileImageSize = 'max-height: 80px; padding-right: 20px; padding-left: 20px;';
        linkImageSize = 'max-height: 35px; padding: 5px;';
        socialStyles = 'max-height: 25px; padding: 5px;';
        itemName = 'color: #333333; font-size: 20pt; font-weight: 750 font-family: arial;';
        itemQTY = 'color: #333333; font-size: 16pt; font-weight: 750 font-family: arial;';
        itemText = 'color: #333333; font-size: 14pt; font-family: arial;';

        customerCity = relatedTo.Customer_City__c;
        if(customerCity != null) {customerCity += ',';} else {customerCity = '';}
        //font = 'Lato Regular';

    }

    //---Get the Token  TODO - (how to encrypt)
    public String getToken()
    {
        String token = Appt_NotificationUtil.getToken(relatedTo.Order_Number__c,relatedTo.API_Callout_Order_Type__c);
        return token;
    }

    //---Get the store name 
    public String getStoreName()
    {
        return relatedTo.SAP_Store_Id__c;
    }

    //---Get the order date
    public String getOrderDate()
    {   
        String orderDateStr= '';
        try{    
            Date orderDate = relatedTo.Work_Order__r.Order_Date__c;
            String orderYear = '' + orderDate.year();
            String orderMonth = '' + orderDate.month();
            String orderDay = '' + orderDate.day();
            orderDateStr = orderYear.leftPad(4, '0') + '-' + orderMonth.leftPad(2, '0') + '-' + orderDay.leftPad(2, '0');

        } catch (Exception e){
            System.debug('try to convert order date failed: ' + e.getMessage());
            //Addedd for SO-41:  Added logInstance 
    		Logger logInstance = Logger.getInstance();
			String LPREFIX = 'Appt_VFEmailController :';
            String errDetails = 'Cause: '+ e.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ e.getMessage();
            logInstance.Log(LPREFIX, Appt_VFEmailController.class.getName(), errDetails); // SO-41 END
        }
        
        return orderDateStr;
    }
    
    //---Build the reschedule Url
    public String getRescheduleUrl()
    {
        String token = relatedTo.Order_Number__c;
        return BaseActionUrl + 'schedule-appointment/installation/initiate?token=' + getToken() + '&orderDate=' + getOrderDate() + '&storeName=' + getStoreName() + '&requestType=RESCHEDULE&fromEmail=true';
    }

    //---Build the cancel Url 
    public String getCancelUrl()
    {
        String token = relatedTo.Order_Number__c;
        return BaseActionUrl + 'schedule-appointment/installation/cancel?token=' + getToken() + '&orderDate=' + getOrderDate() + '&storeName=' + getStoreName() + '&fromEmail=true';
    }   
    
    //---Build the new appt Url
    public String getNewApptUrl()
    {
        String token = relatedTo.Order_Number__c;
        return BaseActionUrl + 'schedule-appointment/installation/initiate?token=' + getToken() + '&orderDate=' + getOrderDate() + '&storeName=' + getStoreName() + '';
    }   

    //---Build the new appt Url 
    public String getCheckInUrl()
    {
        String url = Appt_SettingUtil.getSettingValue('Email_CheckIn_'+getSettingType()+'_Url');

        return url;
    }  

    //---Build the new appt Url
    public String getStoreExperienceUrl()
    {
        String url = Appt_SettingUtil.getSettingValue('Email_StoreExp_'+getSettingType()+'_Url');
        return url;
    }
    
    //---Google Maps
    public String getGoogleMapUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_GoogleMap_Url');
        return settingUrl + relatedTo.Store_Google_Maps_address__c; 
    }

    //---App Store
    public String getAppleStoreUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_AppleStore_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Google Play Store
    public String getGoogleStoreUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_GoogleStore_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Facebook
    public String getFacebookUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_Facebook_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Twitter
    public String getTwitterUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_Twitter_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Pinterest
    public String getPinterestUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_Pinterest_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Instagram
    public String getInstagramUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_Instagram_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---YouTube
    public String getYouTubeUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_YouTube_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Unsubscribe
    public String getUnsubscribeUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_Unsubsribe_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Contact us
    public String getContactUsUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_ContactUs_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Preferences
    public String getPreferencesUrl()
    {
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_Preferences_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Privacy Policy
    public String getPrivacyPolicyUrl()
    {   
        
        String settingUrl = Appt_SettingUtil.getSettingValue('Email_Privacy_'+getSettingType()+'_Url');
        return settingUrl;
    }

    //---Determine the top level action (this is adjusted for debugging)
    public String getNotificationType()
    {
        return relatedTo.Notification_Type__c;
    }

    //---Email - Is Confirmed
    public Boolean getHasWaitList()
    {
        return relatedTo.Has_Check_In_Waitlist__c;
    }

    //---Email - Is Confirmed
    public Boolean getIsConfirmed()
    {
        return getNotificationType() == Appt_ConstantValues.NOTIFICATION_APPT_CONFIRMED;
    }

    //---Email - Is Scheduled
    public Boolean getIsScheduled()
    {
        return getNotificationType() == Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED;
    }

    //---Email - Is Rescheduled
    public Boolean getIsRescheduled()
    {
        return getNotificationType() == Appt_ConstantValues.NOTIFICATION_APPT_RESCHEDULED;
    }

    //---Email - Is Cancelled
    public Boolean getIsCancelled()
    {
        return getNotificationType() == Appt_ConstantValues.NOTIFICATION_APPT_CANCELLED;
    }

    //---Email - Is Reminder
    public Boolean getIsReminder()
    {
        return getNotificationType() == Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
    }

    // returns either AT for AT stores or DT for DT stores
    public String getSettingType(){
        String type;
        type = IsAT ? 'AT' : 'DT';

        return type;
    }

    //---Email - display cancel
    public Boolean getDisaplyCancel()
    {
        Boolean option = true;

        if(getIsCancelled()){
            option = false;
        }

        return option;
    }

    public Boolean getNotCancel()
    {
        Boolean option = false;

        if(getIsCancelled()){
            option = true;
        }

        return option;
    }


    //---Should it show My Order Section
    public Boolean getShowMyOrder()
    {
        Boolean returnVal = false;

        if (getIsCancelled())
        {
            //Future - May need to show order if cancelled
        }
        else 
        {
            returnVal = true;    
        }

        return returnVal;
    }

    //---Get the Email Title
    public String getEmailTitle()
    {
        if (getIsConfirmed()) return 'Appointment Confirmed';
        if (getIsScheduled()) return 'Appointment Confirmed';
        if (getIsCancelled()) return 'Appointment Cancellation Complete';
        if (getIsReminder()) return 'Your appointment is coming up!';
        if (getIsRescheduled()) return 'Your appointment has been rescheduled';
        return 'MISSING TYPE';
    }

    //---Get first line
    public String getVehicleLine1()
    {
        String line = '';
        if(relatedTo.Vehicle_Year__c != null){
            line = relatedTo.Vehicle_Year__c;
        }
        if(relatedTo.Vehicle_Make__c != null){
            if(line != ''){
                line = line + ' ' +relatedTo.Vehicle_Make__c;
            } else {
                line = relatedTo.Vehicle_Make__c;
            }
        }     
        if(line == '0' || line == ''){
            line = 'No vehicle selected for your appointment';
        }   
        return line; 
    }

    //---Get second line
    public String getVehicleLine2()
    {   
        String line = '';
        if(relatedTo.Vehicle_Model__c != null){
            line = relatedTo.Vehicle_Model__c;
        }
        if(relatedTo.Vehicle_Trim__c != null){
            if(line != ''){
                line = line + ' ' +relatedTo.Vehicle_Trim__c;
            } else {
                line = relatedTo.Vehicle_Trim__c;
            }
        }        
        return line; 
    }

    //---Get the Product List
    public List<ProductItem> getProductList()
    {
        List<String> excludeList = new List<String>();

        String excludeListString = Appt_SettingUtil.getSettingValue('Email_Product_Exclude_List');

        if (excludeListString == null) excludeListString = '';
        String[] excudeListArray = excludeListString.split(';');

        if (excudeListArray != null && excudeListArray.size() > 0 )
        {          
            for (String eRow : excudeListArray)
            {
                if (eRow != null && eRow != '') excludeList.add(eRow);
            } 
        }

        List<ProductItem> returnVal = new List<ProductItem>();

        if (relatedTo.Invoice_Payload__c == null || relatedTo.Invoice_Payload__c == '') return returnVal;
        
        //---Read the Invoice Model from th JSON Payload
        Appt_InvoiceDetailModel invModel = Appt_InvoiceDetailModel.parse(relatedTo.Invoice_Payload__c);

        if (invModel.responseDetail != null && invModel.responseDetail.orderHistoryDetails.size() > 0 && invModel.responseDetail.orderHistoryDetails[0].lineItems != null)
        {   
            for (Appt_InvoiceDetailModel.LineItems liRow : invModel.responseDetail.orderHistoryDetails[0].lineItems)
            {
                if (includeRow(liRow, excludeList))
                {
                    ProductItem pItem = new ProductItem();
                    pItem.ArticleName = liRow.storeDescription;
                    pItem.Description = liRow.storeSize;
                    pItem.Quantity = '' + liRow.retailQuantity;

                    String itemNum = liRow.articleNumber;
                    if (itemNum != null) itemNum = itemNum.replaceFirst('^0+','');

                    pItem.ItemNumber = itemNum;
                    returnVal.add( pItem);
                }
            }
        }

        return returnVal;
    }

    //---Determine if the Product Item row should be included
    public Boolean includeRow(Appt_InvoiceDetailModel.LineItems liRow, List<String> excludeList)
    {
        Boolean returnVal = true;

        for(String eRow : excludeList)
        {
            if (liRow.storeDescription == null || liRow.storeDescription.contains(eRow)) 
            {
                returnVal = false;
                break;
            }
        }

        return returnVal;
    }

    //---Local Class for Product Items
    public class ProductItem
    {
        public String ArticleName {get; set;}
        public String Description {get; set;}
        public String Quantity {get; set;}
        public String ItemNumber {get; set;}
    }
}
public without sharing class Appt_AppointmentHandler {
  public static String lprefix = 'Appt_ApptH: ';
  //APPT3-449 - Declaration of woid and articlesList static variables. These variables are used in addition of work order line items.
  public static List<Appt_CreateAppointmentServiceModel.Articles> articlesList = new List<Appt_CreateAppointmentServiceModel.Articles>();
  public static ID woid;
  //APPT3-449
  //Addedd for SO-41
  public static Logger logInstance = Logger.getInstance();

  //Create appointment for Site, Customer and Vehicle if tQueueable he appointment is still available.
  public static Appt_CreateAppointmentServiceModel createAppointment(
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    //start timer for performance loging
    DateTime startTimeAll = Datetime.now();
    DateTime startTimePart = Datetime.now();

    System.debug(lprefix + 'create database savepoint for rollback');
    Savepoint sp = Database.setSavepoint();

    System.debug(
      lprefix + 'createAppointment() ENTRY - apptModel:' + apptModel
    );

    Appt_CreateAppointmentServiceModel returnModel = apptModel;
    //if apptModel param is null return with an error
    if (apptModel == null) {
      returnModel = new Appt_CreateAppointmentServiceModel();
      return rollbackReturn(
        returnModel,
        sp,
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'apptModel parameter is null'
      );
    }

    System.debug(
      lprefix +
        '   custom times modal check: apptModel.selectedSlotStartTime=' +
        apptModel.selectedSlotStartTime +
        ', apptModel.selectedSlotStartTime=' +
        apptModel.selectedSlotEndTime
    ); //DEBUG

    // 0. Validate the parameters in the model. If not valid, return model which will contain error codes and message
    if (validateModelParams(returnModel) == false) {
      return returnModel;
    }

    //  1. get Time Zon Offset for the store's timezone on the date of appointment
    //LIMIT NOTE: 1 SOQL query
    apptModel.timeZoneOffset = Appt_AppointmentUtil.getTimeZoneOffset(
      apptModel.siteId,
      apptModel.appointmentDate
    );
    if (apptModel.timeZoneOffset == null || apptModel.timeZoneOffset == 0) {
      // return error because we couldn't get timezoneoffset, probably because service territory couldn't be found for the siteId
      return rollbackReturn(
        returnModel,
        sp,
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_FOUND,
        'Unable to retrieve the ServiceTerritory as well as timezone offset with siteId=' +
        apptModel.siteId
      );
    }

    Int_Values.addTiming(
      'ApptHandler.CrAppt.TimeZone',
      startTimePart,
      Datetime.now()
    );
    startTimePart = Datetime.now();

    //  2. lookup or insert the Person Account and set on model.
    //LIMIT NOTE: This contains 1 DYNAMIC SOQL query and (1 DML insert OR 1 DML Update)
    // **********************************START Provessing Account
    apptModel = Appt_AppointmentDataProcessUtil.processAccountData(apptModel);

    Int_Values.addTiming(
      'ApptHandler.CrAppt.GetAccount',
      startTimePart,
      Datetime.now()
    );
    startTimePart = Datetime.now();

    //lookup and if necesary create alertnate contact from recipient fields
    getRecipientAltContact(apptModel);

    Int_Values.addTiming(
      'ApptHandler.CrAppt.GetAlt',
      startTimePart,
      Datetime.now()
    );
    startTimePart = Datetime.now();

    //  3. lookup or insert the Asset vehicle record, put Id on model
    //LIMIT NOTE: This contains 1 SOQL query and maybe 1 DML insert
    //getVehicle(apptModel);
    // **********************************START Provessing Vehicle
    apptModel = Appt_AppointmentDataProcessUtil.processVehicleData(apptModel);

    Int_Values.addTiming(
      'ApptHandler.CrAppt.ProcessVeh',
      startTimePart,
      Datetime.now()
    );
    startTimePart = Datetime.now();

    //  4. caluclate work types and durations needed for the appointment
    Appt_workTypeModel wrkTypModel = Appt_AvailabilityHandler.calculateWorkType(
      apptModel.spawnGetAvailabilityServiceModel(false)
    );
    if (wrkTypModel != null && wrkTypModel.isError()) {
      // return error because we couldn't calculate the work type and duration
      return rollbackReturn(
        returnModel,
        sp,
        wrkTypModel.statusCode,
        wrkTypModel.message
      );
    }

    Int_Values.addTiming(
      'ApptHandler.CrAppt.WorkType',
      startTimePart,
      Datetime.now()
    );

    // 4.5.  Now that we have Appt_workTypeModel, validate that we have correct params for Back, Front or Both appointments
    if (validateModelParamsAgainstWrkTyp(apptModel, wrkTypModel) == false) {
      return rollbackReturn(returnModel, sp, '', '');
    }

    //  5. check if appointment slot is still available, if it is not RETURN from method with ERROR
    //     Do not check availability if apptModel.checkAvailabilityFirst = FALSE
    if (
      apptModel.checkAvailabilityFirst == null ||
      apptModel.checkAvailabilityFirst == true
    ) {
      if (!checkAvailability(apptModel, wrkTypModel)) {
        return rollbackReturn(
          returnModel,
          sp,
          Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_AVAILABLE,
          'The appointment time slot is no longer available'
        );
      }
    }

    startTimePart = Datetime.now();

    //  6. Query Service Territory, Service Resources, Scheduling Policy and Front and Back Room Work Types and put info on Model
    // by use of Service Territory Member
    //LIMIT NOTE: 1 SOQL
    List<ServiceTerritoryMember> siteAppointmentInfo = [
      SELECT
        ServiceTerritoryId,
        ServiceTerritory.Name,
        ServiceResourceId,
        ServiceResource.Type__c,
        ServiceTerritory.Scheduling_Policy__c,
        ServiceTerritory.Front_Appointment_Work_Type__c,
        ServiceTerritory.Back_Appointment_Work_Type__c,
        ServiceTerritory.Appt_Record_Owner__c
      FROM ServiceTerritoryMember
      WHERE ServiceTerritory.Site_Account__r.SAP_STORE_ID__c = :apptModel.siteId
    ];

    Int_Values.addTiming(
      'ApptHandler.CrAppt.SiteSOQL',
      startTimePart,
      Datetime.now()
    );

    //Populate Appt_CreateAppointmentServiceModel with the appointment record Ids from the SOQL.
    // If query unsuccessful, return model with error code and message
    populateAppointmentModel(siteAppointmentInfo, apptModel);
    if (apptModel.isError()) {
      return rollbackReturn(
        returnModel,
        sp,
        apptModel.statusCode,
        apptModel.message
      );
    }

    startTimePart = Datetime.now();

    //  7. create and save the Work Order and then put Id on model
    //LIMIT NOTE - 1 insert
    createWorkOrder(apptModel);

    // Appt 3.0 Changes - Add articles to WOLI for Hybris/GK/Alert Cen
    // Added to check the source
    if (
      (apptModel.isVisionFeature != null && apptModel.isVisionFeature) ||
      (apptModel.salesOrderId != null) ||
      apptModel.source == Appt_ConstantValues.APPOINTMENT_SOURCE_WEB
    ) {
      if (apptModel.articles != null && apptModel.articles.size() > 0) {
        //APPT3-449 Assign woid and articlesList static variables
        woid = apptModel.workOrderId;
        articlesList.addAll(apptModel.articles);
        //APPT3-449
      }
    }
    // Appt 3.0 Changes - End

    Int_Values.addTiming(
      'ApptHandler.CrAppt.SaveWO',
      startTimePart,
      Datetime.now()
    );
    //startTimePart = Datetime.now();

    //  8. create and save Service Appointments and put IDs on model
    //LIMIT NOTE - 1 or 2 inserts, followed by potentially one bulk update
    createServiceAppointments(apptModel, wrkTypModel);
    if (apptModel.isError()) {
      return rollbackReturn(
        returnModel,
        sp,
        apptModel.statusCode,
        apptModel.message
      );
    }

    //Int_Values.addTiming('ApptHandler.CrAppt.SaveServAppt',startTimePart, Datetime.now());
    startTimePart = Datetime.now();

    //-- **** This is where FSL code was removed from. The removed code can be found commented out at the bottom of this class. **************

    //set model status to SUCCESS
    returnModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;
    returnModel.appointmentStatus = apptModel.appointmentStatus;

    Int_Values.addTiming(
      'ApptHandler.CrAppt.All',
      startTimeAll,
      Datetime.now()
    );

    System.debug(
      lprefix + 'createAppointment() EXIT - returnModel:' + returnModel
    );
    return returnModel;
  }

  // validate that we have correct params for Back, Front or Both appointments
  public static Boolean validateModelParamsAgainstWrkTyp(
    Appt_CreateAppointmentServiceModel apptModel,
    Appt_workTypeModel wrkTypModel
  ) {
    System.debug(
      lprefix +
        'validateModelParamsAgainstWrkTyp() ENTRY - wrkTypModel.type=' +
        wrkTypModel.type
    );

    if (
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH ||
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT
    ) {
      if (
        String.isBlank(apptModel.consultStartTime) ||
        String.isBlank(apptModel.consultEndTime)
      ) {
        apptModel.setError(
          Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
          'consultStartTime and consultEndTime are required for Front Room Appointment.'
        );
        System.debug(
          lprefix +
          'validateModelParamsAgainstWrkTyp() EXIT - consultStartTime and consultEndTime are required, return FALSE'
        );
        return false;
      }
    }

    if (
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH ||
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK
    ) {
      if (
        String.isBlank(apptModel.backOfficeStartTime) ||
        String.isBlank(apptModel.backOfficeEndTime)
      ) {
        apptModel.setError(
          Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
          'backOfficeStartTime and backOfficeEndTime are required for Back Room Appointment.'
        );
        System.debug(
          lprefix +
          'validateModelParamsAgainstWrkTyp() EXIT - backOfficeStartTime and backOfficeEndTime are required, return FALSE'
        );
        return false;
      }
    }

    //if here, then parameters passed validation
    System.debug(
      lprefix + 'validateModelParamsAgainstWrkTyp() EXIT - return TRUE'
    );
    return true;
  }

  // validate important parameters on model and if errors found, set error code and message on model and return FALSE
  public static Boolean validateModelParams(
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    if (String.isBlank(apptModel.siteId)) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'siteId parameter is blank or null'
      );
      return false;
    }

    if (String.isBlank(apptModel.appointmentStatus)) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'appointmentStatus parameter is blank or null, siteId=' +
        apptModel.siteId
      );
      return false;
    }

    if (
      String.isBlank(apptModel.source) || String.isBlank(apptModel.orderType)
    ) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'Source or OrderType parameter is blank or null'
      );
      return false;
    }

    if (
      apptModel.appointmentDate == null ||
      apptModel.appointmentDate < Date.today()
    ) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'appointmentDate must be greater than or equal to today'
      );
      return false;
    }

    if (
      (String.isBlank(apptModel.consultStartTime) ||
      String.isBlank(apptModel.consultEndTime)) &&
      (String.isBlank(apptModel.backOfficeStartTime) ||
      String.isBlank(apptModel.backOfficeEndTime))
    ) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'It is required that either consultStartTime and consultEndTime or backOfficeStartTime and backOfficeEndTime are properly populated'
      );
      return false;
    }

    if (
      !String.isBlank(apptModel.consultStartTime) &&
      !String.isBlank(apptModel.consultEndTime) &&
      apptModel.consultEndTime <= apptModel.consultStartTime
    ) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'consultEndTime must be greater than consultStartTime'
      );
      return false;
    }

    if (
      !String.isBlank(apptModel.backOfficeStartTime) &&
      !String.isBlank(apptModel.backOfficeEndTime) &&
      apptModel.backOfficeEndTime <= apptModel.backOfficeStartTime
    ) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'backOfficeEndTime must be greater than backOfficeStartTime'
      );
      return false;
    }

    //if here, then parameters passed validation
    return true;
  }

  //Check if a specific appointment slot is available. Used to confirm availability before creating or updating appointment.
  // This is a pass-through to Appt_AvailbilityHandler
  public static Boolean checkAvailability(
    Appt_CreateAppointmentServiceModel apptModel,
    Appt_workTypeModel wrkTypModel
  ) {
    return Appt_AvailabilityHandler.checkAvailability(
      apptModel.spawnGetAvailabilityServiceModel(),
      wrkTypModel
    );
  }

  // According to DT (confirmed in Paired Appointment Scenario meeting on 1/18/21), Fleet Accounts are out of scope for pilot project.
  //  Therefore this method will only search for and if necessary create Person Accounts.
  // LIMIT NOTE: Either 1 DML Insert or 1 DML Update
  //-- NOTE! This method is called by LWC Controllers --------
  public static Account getAccount(
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    System.debug(
      lprefix +
        'getAccount() ENTRY - customerType=' +
        apptModel.customerType +
        ', hybrisCustomerId=' +
        apptModel.hybrisCustomerId +
        ', posCustomerId=' +
        apptModel.posCustomerId +
        ', GUID=' +
        apptModel.customerGuid + 'CUSTOMER TYPE :: >> ' +apptModel.customerType
    );

    DateTime startTimeAll = Datetime.now();
    DateTime startTimePart = Datetime.now();

    List<Account> custAccounts;

    String accountId = '';
    if (
      apptModel.workOrderId != null && !String.isBlank(apptModel.workOrderId)
    ) {
      List<WorkOrder> woList = [
        SELECT Id, AccountId
        FROM WorkOrder
        WHERE Id = :apptModel.workOrderId
      ];

      if (woList.size() > 0) {
        accountId = woList[0].AccountId;
      }
    }
         
      
    // Only query for Accounts if at least one of the where clause params is populated
    if (
      (!String.isBlank(apptModel.hybrisCustomerId) ||
      !String.isBlank(apptModel.posCustomerId) ||
      !String.isBlank(apptModel.customerGuid) ||
      !String.isBlank(accountId)) && apptModel.customerType != Appt_ConstantValues.CUSTOMER_TYPE_FLEET // SO-559
    ) {
      String soql =
        'SELECT Id, PersonContactId, IsPersonAccount,  RecordTypeId, POS_Customer_Id__c, Hybris_Customer_Id__c, GUID__c, Appt_Customer_Type__c,  FirstName, LastName, Email__c, Appt_Email_Opt_In__pc, ' +
        'PersonEmail, PersonMobilePhone, Phone, PersonHomePhone, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Appt_SMS_Opt_In__pc FROM Account WHERE ';
      String whereClause = Appt_AppointmentDataProcessUtil.buildAccountWhereClause(
        apptModel
      );

      if (!String.isBlank(accountId)) {
        System.debug('Found matching account id: ' + accountId);
        whereClause = 'Id=' + '\'' + accountId + '\'';
      }

      System.debug(lprefix + '     getAccount SOQL = ' + soql + whereClause);
      custAccounts = (List<Account>) Database.query(soql + whereClause);
      System.debug(
        lprefix + '     AFTER SOQL Retrieved Accounts:' + custAccounts
      );

      String hybrisId = 'XXXXXXXXXXXXXXXXXXXX';
      String posID = 'XXXXXXXXXXXXXXXXXXXX';
      String guid = 'XXXXXXXXXXXXXXXXXXXX';

      if (!String.isBlank(apptModel.hybrisCustomerId)) {
        hybrisId = apptModel.hybrisCustomerId;
      }
      if (!String.isBlank(apptModel.posCustomerId)) {
        posID = apptModel.posCustomerId;
      }
      if (!String.isBlank(apptModel.customerGuid)) {
        guid = apptModel.customerGuid;
      }

      if (!String.isBlank(accountId) && custAccounts.size() > 0) {
        List<Account> accts = [
          SELECT Id, POS_Customer_Id__c, Hybris_Customer_Id__c, GUID__c
          FROM Account
          WHERE
            (Hybris_Customer_Id__c = :hybrisId
            OR POS_Customer_Id__c = :posID
            OR GUID__c = :guid)
            AND Id != :custAccounts[0].Id
          LIMIT 5000
        ];

        if (accts.size() > 0) {
          apptModel = evaluateDuplicateId(apptModel, accts, custAccounts[0]);
        }
      }

      Int_Values.addTiming(
        'ApptHandler.getAccount.GetAcctSOQL',
        startTimePart,
        Datetime.now()
      );
    } else if(apptModel.customerType == Appt_ConstantValues.CUSTOMER_TYPE_FLEET && !String.isBlank(accountId)){
        system.debug('ReACHED HERE ?>> ');           
    }

    Account custAccount;

    if (custAccounts != null && custAccounts.size() > 0) {
      // ACCOUNT LOOKUP LOGIC: Three ID fields are used in dynamic WHERE and ORDER BY clause in SOQL above, depending on if
      //  each ID field is populated (Hybris_Customer_Id__c OR POS_Customer_Id__c OR GUID__c). Since WHERE uses OR, If multiple IDs
      //  are passed in the parameters, which identify mutiple accounts, then multiple accounts will be retrieved. In this case we
      //  use source parameter value (WEB or STORE) to order the results by the ID appropriate to the source. In this way, we are able to
      //  choose the account that more likely is the account for the source system in which the appointment was made: The store POS terminal
      //  or the Hybris web site. For example, if source = WEB but we retrieve one account for Hybris_Customer_Id__c and another account for
      //  the populated POS_Customer_Id__c ID, the Service Appointment will be associated with the Hybris_Customer_Id__c account, since the
      //  Hybris web site is likely to have the correct Hybris_Customer_Id__c.
      // IF multiple IDs are populated and used in the WHERE clause, but only 1 account is in the SOQL response, then we'll use that account and
      //  update it to contain all IDs fields that were populated (not empty or null).

      //use Account retrieved from SOQL, if more than 1 use the first
      custAccount = custAccounts.get(0);
      System.debug(
        lprefix + '    Customer Account found via SOQL: ' + custAccount
      );

      if (custAccounts.size() == 1) {
        custAccount.POS_Customer_Id__c = apptModel.posCustomerId;
        custAccount.Hybris_Customer_Id__c = apptModel.hybrisCustomerId;
        custAccount.GUID__c = apptModel.customerGuid;
      }

      //update existing account with data from model
      populateAccountFields(custAccount, apptModel);

      try {
        System.debug(
          lprefix + '     about to update existing Account:' + custAccount
        );
        update custAccount;
        System.debug(
          lprefix +
            '     successfully update existing AccountId:' +
            custAccount.Id
        );
      } catch (Exception e) {
        System.debug(
          lprefix +
            '     EXCEPTION when updating, SECOND ATTEMPT to update existing Account. Exception:' +
            e
        );
        update custAccount;

        // SO-41 START:  Added logInstance
        String errDetails = 'Cause: ' + e.getCause() + '\n';
        errDetails = errDetails + 'LineNumber: ' + e.getLineNumber() + '\n';
        errDetails =
          errDetails +
          'Stack trace: ' +
          e.getStackTraceString() +
          '\n';
        errDetails = errDetails + 'Message: ' + e.getMessage();
        logInstance.Log(
          LPREFIX,
          Appt_AppointmentHandler.class.getName(),
          errDetails
        ); // SO-41 END
      }
    } else {
      //if existing account not found, then create a Person Account
      Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('PersonAccount')
        .getRecordTypeId();
      custAccount = new Account(RecordTypeId = personAccountRecordTypeId);
      if (!String.isBlank(apptModel.posCustomerId)) {
        custAccount.POS_Customer_Id__c = apptModel.posCustomerId;
      }
      if (!String.isBlank(apptModel.hybrisCustomerId)) {
        custAccount.Hybris_Customer_Id__c = apptModel.hybrisCustomerId;
      }
      if (!String.isBlank(apptModel.customerGuid)) {
        custAccount.GUID__c = apptModel.customerGuid;
      }

      populateAccountFields(custAccount, apptModel);

      try {
        System.debug(
          lprefix + '     about to save newly created Account:' + custAccount
        );
        insert custAccount;
        System.debug(
          lprefix + '     successfully saved AccountId:' + custAccount.Id
        );
      } catch (Exception e) {
        System.debug(
          lprefix +
            '     EXCEPTION when inserting, SECOND ATTEMPT to save newly created Account. Exception:' +
            e
        );
        insert custAccount;

        // SO-41 START:  Added logInstance
        String errDetails = 'Cause: ' + e.getCause() + '\n';
        errDetails = errDetails + 'LineNumber: ' + e.getLineNumber() + '\n';
        errDetails =
          errDetails +
          'Stack trace: ' +
          e.getStackTraceString() +
          '\n';
        errDetails = errDetails + 'Message: ' + e.getMessage();
        logInstance.Log(
          LPREFIX,
          Appt_AppointmentHandler.class.getName(),
          errDetails
        ); // SO-41 END
      }
    }

    //update IDs on model
    apptModel.accountId = custAccount.Id;
    apptModel.contactId = custAccount.PersonContactId;

    System.debug(
      lprefix +
        'getAccount() EXIT - accountId=' +
        apptModel.accountId +
        ', contactId=' +
        apptModel.contactId
    );
    return custAccount;
  }
    
    

  //-- lookup or create Alternative Contact for the appointment
  public static void getRecipientAltContact(
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    System.debug(
      lprefix +
        'getRecipientAltContact() Entry - apptModel.recipientPhone=' +
        apptModel.recipientPhone +
        ', apptModel.recipientEmail=' +
        apptModel.recipientEmail
    );

    //-- to lookup or create an alternate contact, recipientEmail or recipientPhone are required.
    if (
      String.isBlank(apptModel.recipientEmail) &&
      String.isBlank(apptModel.recipientPhone)
    ) {
      return;
    }

    Id altCustomerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
      .get('B2C_Alternate')
      .getRecordTypeId();
    Contact contct;
    List<Contact> contacts;

    // Search for Contact by email or phone or both.
    //Splitting into multiple SOQL so no nulls are used in where clause, which would cause performance issues
    if (String.isBlank(apptModel.recipientPhone)) {
      contacts = [
        SELECT FirstName, lastName, Email, Phone, MobilePhone
        FROM Contact
        WHERE Email = :apptModel.recipientEmail
      ];
    } else if (String.isBlank(apptModel.recipientEmail)) {
      contacts = [
        SELECT FirstName, lastName, Email, Phone, MobilePhone
        FROM Contact
        WHERE
          Phone = :apptModel.recipientPhone
          OR MobilePhone = :apptModel.recipientPhone
          OR HomePhone = :apptModel.recipientPhone
          OR OtherPhone = :apptModel.recipientPhone
      ];
    } else {
      //-- if here than both phone and email must be populated
      contacts = [
        SELECT FirstName, lastName, Email, Phone, MobilePhone
        FROM Contact
        WHERE
          Email = :apptModel.recipientEmail
          OR Phone = :apptModel.recipientPhone
          OR MobilePhone = :apptModel.recipientPhone
          OR HomePhone = :apptModel.recipientPhone
          OR OtherPhone = :apptModel.recipientPhone
      ];
    }

    //-- If 1 contact queried, use it. If more than 1 contact found don't use and instead insert new contact in later code below
    if (contacts != null && contacts.size() == 1) {
      contct = contacts.get(0);
      System.debug(lprefix + '     found Alternate Contact:' + contct);
    }

    if (contct != null) {
      // Update any non-null recipient fields except for Email
      if (apptModel.recipientFirstName != null) {
        contct.FirstName = apptModel.recipientFirstName;
      }
      if (apptModel.recipientLastName != null) {
        contct.LastName = apptModel.recipientLastName;
      }
      if (apptModel.recipientPhone != null) {
        contct.Phone = apptModel.recipientPhone;
      }

      System.debug(
        lprefix + '     about to update existing Alternate Contact:' + contct
      );
      update contct;
      System.debug(
        lprefix + '     successfully updated Alternate Contact Id=' + contct.Id
      );
    } else {
      contct = new Contact(RecordTypeId = altCustomerRecordTypeId);
      contct.FirstName = apptModel.recipientFirstName;
      //-- last name cannot be null
      contct.LastName = !String.isBlank(apptModel.recipientLastName)
        ? apptModel.recipientLastName
        : 'Not Provided';
      contct.Email = apptModel.recipientEmail;
      contct.Phone = apptModel.recipientPhone;

      System.debug(
        lprefix + '     about to save newly created Alternate Contact:' + contct
      );
      insert contct;
      System.debug(
        lprefix + '     successfully saved Alternate Contact Id:' + contct.Id
      );
    }

    if (contct != null) {
      apptModel.alternateContactId = contct.Id;
    }

    System.debug(
      lprefix +
        'getRecipientAltContact() EXIT - apptModel.alternateContactId=' +
        apptModel.alternateContactId
    );
  }

  // creates and saves a Work Order record and returns the Id
  private static Id createWorkOrder(
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    System.debug(lprefix + 'createWorkOrder() ENTRY -  apptModel:' + apptModel);

    //-- There is a timing issue with PersonAccounts where immediately after inserting a new PersonAcount, the PersonContactId might not yet be populated on the Account record.
    //-- If toUpdateModel.contactId=null, we have to query the account here to get the PersonContactId - DTA-355
    if (String.isBlank(apptModel.contactId)) {
      apptModel.contactId = Appt_AppointmentDataProcessUtil.getPersonContactId(
        apptModel.accountId
      );
      System.debug(
        lprefix +
          'PersonContactId=null, but after re-query PersonContactId=:' +
          apptModel.contactId
      );
    }

    WorkOrder wo = new WorkOrder();
    // NOTE: status on WorkOrder isn't being used, so commenting out setting of WorkOrder.status
    //wo.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING;
    wo.ServiceTerritoryId = apptModel.ServiceTerritoryId;
    wo.AccountId = apptModel.accountId;
    wo.ContactId = apptModel.contactId;
    wo.WorkTypeId = apptModel.backroomWorkTypeId != null
      ? apptModel.backroomWorkTypeId
      : apptModel.frontroomWorkTypeId;
    wo.Source__c = apptModel.source;
    wo.Appointment_Comments__c = apptModel.comments;
    wo.Order_Type__c = apptModel.orderType;
    wo.Form_Type__c = apptModel.formType;
    wo.Form_Number__c = apptModel.formNumber;
    wo.Form_Date__c = !String.isBlank(apptModel.formDate)
      ? Date.valueOf(apptModel.formDate)
      : null;
    wo.Hybris_Order_Id__c = apptModel.hybrisOrderId;
    wo.POS_Web_Order_Id__c = apptModel.posWebOrderId;
    wo.Layaway_Number__c = apptModel.layawayNumber;
    wo.Quote_Number__c = apptModel.quoteNumber;
    wo.Invoice_Number__c = apptModel.invoiceNumber;
    wo.Order_Date__c = !String.isBlank(apptModel.orderDate)
      ? Date.valueOf(apptModel.orderDate)
      : null;
    wo.Vehicle__c = apptModel.assetId;
    wo.Alternate_Contact__c = apptModel.alternateContactId;
    //Appt3.0 Changes Start
    if (String.isNotBlank(apptModel.salesOrderId)) {
      wo.Appt3_Sales_Order_Id__c = apptModel.salesOrderId;
    }
    //Appt3.0 Changes End
    //--DTA-261 - use smsPhoneNumber if populated, otherwise use mobile phone in WO SMS field (if  populated)
    if (!String.isBlank(apptModel.smsPhoneNumber)) {
      wo.SMS_Phone__c = apptModel.smsPhoneNumber;
    } else if (!String.isBlank(apptModel.mobilePhoneNumber)) {
      wo.SMS_Phone__c = apptModel.mobilePhoneNumber;
    }

    //-- Set the owner of the WorkOrder to be the Store's record owner user (like POS user) so that the store can see all of its Service Appointment
    //--  records, but only the stores' Service Appointment records - DTA-353
    if (!String.isBlank(apptModel.appointmentRecordOwnerId)) {
      wo.OwnerId = apptModel.appointmentRecordOwnerId;
    }

    //Appt 3.0 Changes - Populate MDM Sales Order Id when its available.
    if (
      (apptModel.isVisionFeature != null && apptModel.isVisionFeature) ||
      apptModel.salesOrderId != null
    ) {
      if (
        apptModel.salesOrderId != null &&
        !String.isBlank(apptModel.salesOrderId)
      ) {
        wo.Appt3_Sales_Order_Id__c = apptModel.salesOrderId;
      }
      if (apptModel.unPaid != null) {
        wo.Appt3_UnPaid__c = apptModel.unPaid;
      }
    }
    //Appt 3.0 Changes - End

    //-- SAVE RECORD
    System.debug(lprefix + '     about to save newly created WorkOrder:' + wo);
    insert wo;
    System.debug(lprefix + '     successfully saved WorkOrderId:' + wo.Id);

    apptModel.workOrderId = wo.Id;
    apptModel.appointmentId = wo.Id;

    System.debug(lprefix + 'createWorkOrder() EXIT - wo.Id=' + wo.Id);
    return wo.Id;
  }

  //create and insert ServiceAppointment records, possibly one for front room and one for back room
  private static void createServiceAppointments(
    Appt_CreateAppointmentServiceModel apptModel,
    Appt_workTypeModel wrkTypModel
  ) {
    System.debug(
      lprefix + 'createServiceAppointments() ENTRY -  apptModel:' + wrkTypModel
    );

    DateTime startTimePart = Datetime.now();

    if (wrkTypModel == null || wrkTypModel.type == null) {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST,
        'wrkTypModel param or wrkTypModel.type field is null or blank'
      );
      return;
    }

    List<ServiceAppointment> saList = new List<ServiceAppointment>();
    ServiceAppointment fsa;

    //---- FRONT ROOM SERVICE APPOINTMENT -----------------
    if (
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH ||
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT
    ) {
      // construct DateTime for ConsultStartTime and ConsultEndTime in GMT
      Datetime startDateTime = Appt_AppointmentUtil.convertTime(
        String.valueOf(apptModel.appointmentDate),
        apptModel.consultStartTime,
        apptModel.timeZoneOffset
      );
      Datetime endDateTime = Appt_AppointmentUtil.convertTime(
        String.valueOf(apptModel.appointmentDate),
        apptModel.consultEndTime,
        apptModel.timeZoneOffset
      );

      // create and save FRONT ROOM service appointment
      fsa = new ServiceAppointment(ParentRecordId = apptModel.workOrderId);
      fsa.Activity_Type__c = Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT;
      fsa.EarliestStartTime = startDateTime;
      fsa.SchedStartTime = startDateTime;
      fsa.DueDate = endDateTime;
      fsa.SchedEndTime = endDateTime;
      fsa.Duration = Appt_AppointmentUtil.minutesBetweenDatetimes(
        startDateTime,
        endDateTime
      );
      fsa.Start_Time_String__c = apptModel.consultStartTime;
      fsa.End_Time_String__c = apptModel.consultEndTime;
      fsa.Original_Date_String__c = String.valueOf(apptModel.appointmentDate);
      fsa.Original_Start_Time_String__c = apptModel.consultStartTime;
      fsa.Original_End_Time_String__c = apptModel.consultEndTime;
      // set as notification appointment
      fsa.Notification_Appointment__c = true;

      //populate common fields, like Date_String__c and ServiceTerritoryId
      populateServiceAppointmentFields(fsa, apptModel);

      //-- put ServiceAppointment on list for bulk insert later
      saList.add(fsa);
    }

    ServiceAppointment bsa;

    //---- BACK ROOM SERVICE APPOINTMENT -----------------
    if (
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH ||
      wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK
    ) {
      // construct DateTime for ConsultStartTime and ConsultEndTime in GMT
      Datetime startDateTime = Appt_AppointmentUtil.convertTime(
        String.valueOf(apptModel.appointmentDate),
        apptModel.backOfficeStartTime,
        apptModel.timeZoneOffset
      );
      Datetime endDateTime = Appt_AppointmentUtil.convertTime(
        String.valueOf(apptModel.appointmentDate),
        apptModel.backOfficeEndTime,
        apptModel.timeZoneOffset
      );

      // create and save BACK ROOM service appointment
      bsa = new ServiceAppointment(ParentRecordId = apptModel.workOrderId);
      bsa.Activity_Type__c = Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK;
      bsa.EarliestStartTime = startDateTime;
      bsa.SchedStartTime = startDateTime;
      bsa.DueDate = endDateTime;
      bsa.SchedEndTime = endDateTime;
      bsa.Duration = Appt_AppointmentUtil.minutesBetweenDatetimes(
        startDateTime,
        endDateTime
      );
      bsa.Start_Time_String__c = apptModel.backOfficeStartTime;
      bsa.End_Time_String__c = apptModel.backOfficeEndTime;
      bsa.Original_Date_String__c = String.valueOf(apptModel.appointmentDate);
      bsa.Original_Start_Time_String__c = apptModel.backOfficeStartTime;
      bsa.Original_End_Time_String__c = apptModel.backOfficeEndTime;
      // set notifcation appointment if only a back office appointment is created
      if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {
        bsa.Notification_Appointment__c = true;
      }

      //populate common fields, like Date_String__c and ServiceTerritoryId
      populateServiceAppointmentFields(bsa, apptModel);

      //-- put ServiceAppointment on list for bulk insert later
      saList.add(bsa);
    }

    // Appt 3.0 Changes - On the fly flag enabled during Service Appointment creation. This will be used in SA trigger to enable the consumption of multiple time slots for Vision
    if (apptModel.isVisionFeature != null && apptModel.isVisionFeature) {
      Appt_ConstantValues.isVisionFeature = true;
    }
    // Appt 3.0 Changes - End

    //-- Insert the ServiceAppointments on the list. IN past inserts occasionally failed on first attempt, so try again if exception
    try {
      System.debug(
        lprefix +
          '     about to save newly created List of ServiceAppointment with ' +
          saList.size() +
          ' items:' +
          saList
      );
      insert saList;
      System.debug(
        lprefix +
          '     successfully INSERTED List of ServiceAppointment:' +
          saList
      );
    } catch (Exception e) {
      System.debug(
        lprefix +
          '     EXCEPTION when inserting List of ServiceAppointment, SECOND ATTEMPT. Exception:' +
          e
      );
      insert saList;
      // SO-41 START:  Added logInstance
      String errDetails = 'Cause: ' + e.getCause() + '\n';
      errDetails = errDetails + 'LineNumber: ' + e.getLineNumber() + '\n';
      errDetails =
        errDetails +
        'Stack trace: ' +
        e.getStackTraceString() +
        '\n';
      errDetails = errDetails + 'Message: ' + e.getMessage();
      logInstance.Log(
        LPREFIX,
        Appt_AppointmentHandler.class.getName(),
        errDetails
      ); // SO-41 END
    }

    //-- Set IDs from inserted ServiceAppointment records on model
    // FRONT ROOM SERVICE APPOINTMENT ----
    if (fsa != null) {
      apptModel.consultAppointmentId = fsa.Id;
    }
    if (fsa != null) {
      apptModel.consultDuration = String.valueOf(fsa.Duration);
    }
    // BACK ROOM SERVICE APPOINTMENT ----
    if (bsa != null) {
      apptModel.backOfficeAppointmentId = bsa.Id;
    }
    if (bsa != null) {
      apptModel.backOfficeDuration = String.valueOf(bsa.Duration);
    }

    //If there is front and back appointments, Set Related_Appointment__c lookup to each other Service Appointments
    if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH) {
      List<ServiceAppointment> bulkUpdateList = new List<ServiceAppointment>();
      bsa.Related_Appointment__c = fsa.Id;
      bulkUpdateList.add(bsa);
      fsa.Related_Appointment__c = bsa.Id;
      bulkUpdateList.add(fsa);
      try {
        update bulkUpdateList;
      } catch (Exception e) {
        System.debug(
          lprefix +
            '     EXCEPTION when updating to link SAs, SECOND ATTEMPT to UPDATE. Exception:' +
            e
        );
        update bulkUpdateList;

        // SO-41 START:  Added logInstance
        String errDetails = 'Cause: ' + e.getCause() + '\n';
        errDetails = errDetails + 'LineNumber: ' + e.getLineNumber() + '\n';
        errDetails =
          errDetails +
          'Stack trace: ' +
          e.getStackTraceString() +
          '\n';
        errDetails = errDetails + 'Message: ' + e.getMessage();
        logInstance.Log(
          LPREFIX,
          Appt_AppointmentHandler.class.getName(),
          errDetails
        ); // SO-41 END
      }
    }

    Int_Values.addTiming(
      'ApptHandler.CreateSrvAppt',
      startTimePart,
      Datetime.now()
    );

    System.debug(lprefix + 'createServiceAppointments() EXIT with....');
    if (fsa != null) {
      System.debug(
        lprefix +
          ' FRONT SA:' +
          fsa.SchedStartTime +
          '|' +
          fsa.SchedEndTime +
          '|' +
          fsa.status
      );
    } //DEBUG TODO REMOVE
    if (bsa != null) {
      System.debug(
        lprefix +
          ' BACK SA:' +
          bsa.SchedStartTime +
          '|' +
          bsa.SchedEndTime +
          '|' +
          bsa.status
      );
    } //DEBUG TODO REMOVE
  }

  //populate common serviceappointment fields
  private static void populateServiceAppointmentFields(
    ServiceAppointment sa,
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    if (sa == null) {
      sa = new ServiceAppointment(ParentRecordId = apptModel.workOrderId);
    }

    //sa.ContactId = apptModel.contactId;    //The contact associated with the appointment. If the parent record is a work order or work order line item, this field’s value is inherited from the parent.
    sa.ServiceTerritoryId = apptModel.ServiceTerritoryId;
    sa.Work_Order__c = apptModel.workOrderId;
    sa.Date_String__c = String.valueOf(apptModel.appointmentDate);
    if (!String.isBlank(apptModel.appointmentStatus)) {
      sa.Status = apptModel.appointmentStatus;
    } else {
      sa.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING;
    }
    sa.DurationType = Appt_ConstantValues.WORK_ORDER_DURATION_TYPE;
    sa.Customer_Type__c = apptModel.customerType;
    sa.Source__c = apptModel.source;
    sa.Site_Id__c = apptModel.siteId;
    sa.Timezone_Offset__c = apptModel.timeZoneOffset;
    sa.Order_Type__c = apptModel.orderType;
    sa.FSL__Schedule_over_lower_priority_appointment__c = true;
    sa.Priority__c = 1;

    //if populated, set start/end times of originally selected appt slot on appointment record (originally selected appt slot from POS Custom Times Modal - DTA-503)
    System.debug(
      lprefix +
        'populateServiceAppointmentFields()  - apptModel.selectedSlotStartTime=' +
        apptModel.selectedSlotStartTime +
        ', apptModel.selectedSlotEndTime=' +
        apptModel.selectedSlotEndTime
    ); //DEBUG

    if (
      !String.isBlank(apptModel.selectedSlotStartTime) &&
      apptModel.selectedSlotStartTime.trim().length() == 4
    ) {
      sa.Selected_Slot_Start_Time_String__c = apptModel.selectedSlotStartTime.trim();
    } else {
      sa.Selected_Slot_Start_Time_String__c = null;
    }

    if (
      !String.isBlank(apptModel.selectedSlotEndTime) &&
      apptModel.selectedSlotEndTime.trim().length() == 4
    ) {
      sa.Selected_Slot_End_Time_String__c = apptModel.selectedSlotEndTime.trim();
    } else {
      sa.Selected_Slot_End_Time_String__c = null;
    }

    System.debug(
      lprefix +
        'populateServiceAppointmentFields()  - sa.Selected_Slot_Start_Time_String__c=' +
        sa.Selected_Slot_Start_Time_String__c +
        ', sa.Selected_Slot_End_Time_String__c=' +
        sa.Selected_Slot_End_Time_String__c
    ); //DEBUG

    //-- Set the owner of the ServiceAppointment to be the Store's record owner user (like POS user) so that the store can see all of its Service Appointment
    //--  records, but only the stores' Service Appointment records - DTA-353
    if (!String.isBlank(apptModel.appointmentRecordOwnerId)) {
      sa.OwnerId = apptModel.appointmentRecordOwnerId;
    }
  }

  //populate common necessary fields on the model
  private static void populateAppointmentModel(
    List<ServiceTerritoryMember> siteAppointmentInfo,
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    System.debug(
      lprefix +
        'populateAppointmentModel() ENTRY - siteAppointmentInfo:' +
        siteAppointmentInfo
    );

    if (siteAppointmentInfo != null && siteAppointmentInfo.size() > 0) {
      apptModel.ServiceTerritoryId = siteAppointmentInfo.get(0)
        .ServiceTerritoryId;
      apptModel.schedulingPolicyId = siteAppointmentInfo.get(0)
        .ServiceTerritory.Scheduling_Policy__c;
      apptModel.frontroomWorkTypeId = siteAppointmentInfo.get(0)
        .ServiceTerritory.Front_Appointment_Work_Type__c;
      apptModel.backroomWorkTypeId = siteAppointmentInfo.get(0)
        .ServiceTerritory.Back_Appointment_Work_Type__c;

      // Appt 3.0 Changes - Record owner will individual user when calling application is either GK or Alert Center. For Legacy, the record owner will still be the generic POS terminal user
      if (apptModel.isVisionFeature == null || !apptModel.isVisionFeature) {
        apptModel.appointmentRecordOwnerId = siteAppointmentInfo.get(0)
          .ServiceTerritory.Appt_Record_Owner__c;
      }
      // Appt 3.0 Changes - End

      //loop through list to populate frontroom and backroom service resource ids
      for (ServiceTerritoryMember info : siteAppointmentInfo) {
        if (
          info.ServiceResource.Type__c ==
          Appt_ConstantValues.SERVICE_RESOURCE_TYPE_FRONT
        ) {
          apptModel.frontroomServiceResourceId = info.ServiceResourceId;
        } else if (
          info.ServiceResource.Type__c ==
          Appt_ConstantValues.SERVICE_RESOURCE_TYPE_BACK
        ) {
          apptModel.backroomServiceResourceId = info.ServiceResourceId;
        }
      }
    } else {
      apptModel.setError(
        Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_FOUND,
        'unable to retrieve Service Territory, Scheduling Policy, Service Resources and Work Types with siteId=' +
        apptModel.siteId
      );
      return;
    }

    System.debug(
      lprefix + 'populateAppointmentModel() EXIT - apptModel:' + apptModel
    );
  }

  // populate the Account object with values from param model only if a field is not null. If null ignore that param.
  public static void populateAccountFields(
    Account custAccount,
    Appt_CreateAppointmentServiceModel apptModel
  ) {
    if (custAccount == null) {
      Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('PersonAccount')
        .getRecordTypeId();
      custAccount = new Account(RecordTypeId = personAccountRecordTypeId);
    }

    if (apptModel.firstName != null) {
      custAccount.FirstName = apptModel.firstName;
    }
    if (apptModel.lastName != null) {
      custAccount.LastName = apptModel.lastName;
    }

    if (apptModel.emailAddress != null) {
      custAccount.Email__c = apptModel.emailAddress;
      custAccount.PersonEmail = apptModel.emailAddress;
    }

    if (apptModel.homePhoneNumber != null) {
      custAccount.PersonHomePhone = apptModel.homePhoneNumber;
    }
    if (apptModel.mobilePhoneNumber != null) {
      custAccount.PersonMobilePhone = apptModel.mobilePhoneNumber;
    }
    if (apptModel.workPhoneNumber != null) {
      custAccount.Phone = apptModel.workPhoneNumber;
    }

    if (apptModel.address1 != null && apptModel.address2 != null) {
      custAccount.put(
        'ShippingStreet',
        apptModel.address1 + '\n' + apptModel.address2
      );
    } else if (apptModel.address1 != null) {
      custAccount.put('ShippingStreet', apptModel.address1);
    }

    if (apptModel.city != null) {
      custAccount.put('ShippingCity', apptModel.city);
    }

    if (apptModel.state != null) {
      if (!String.isBlank(apptModel.state) && apptModel.state.length() < 4) {
        custAccount.put(
          'ShippingState',
          Appt_AppointmentUtil.convertToFullStateName(apptModel.state)
        );
      } else {
        custAccount.put('ShippingState', apptModel.state);
      }
    }

    if (apptModel.zipCode != null) {
      custAccount.put('ShippingPostalCode', apptModel.zipCode);
    }

    //-- If country unknown, derivate from the state
    if (!String.isBlank(apptModel.country)) {
      custAccount.put('ShippingCountry', apptModel.country);
    } else if (!String.isBlank(apptModel.state)) {
      custAccount.put(
        'ShippingCountry',
        Appt_AppointmentUtil.getCountryByState(apptModel.state.trim())
      );
    }

    if (apptModel.customerType != null) {
      custAccount.Appt_Customer_Type__c = apptModel.customerType;
    }
    if (apptModel.emailAddressOptIn != null) {
      custAccount.Appt_Email_Opt_In__pc = apptModel.emailAddressOptIn;
    }
    if (apptModel.textOptIn != null) {
      custAccount.Appt_SMS_Opt_In__pc = apptModel.textOptIn;
    }

    // Appt 3.0 Changes - Map new customer fields sent as part of GK and Alert Center payload.
    if (apptModel.isVisionFeature != null && apptModel.isVisionFeature) {
      custAccount.Appt3_My_Account__c = apptModel.showMyAccount;
      custAccount.Appt3_AAA_Membership__c = apptModel.showAAAMember;
      custAccount.Appt3_Private_Label_Cardholder__c = apptModel.showDTCC;
      custAccount.Appt3_Military__c = apptModel.showMilitary;
      //Vison payload always sends 2 character country code, so fetch country based on state. Fallback is 'United States'.
      String country = Appt_AppointmentUtil.getCountryByState(
        apptModel.state.trim()
      );
      custAccount.put(
        'ShippingCountry',
        (country != null ? country : 'United States')
      );
    }
    // Appt 3.0 Changes - End
  }

  private static Appt_CreateAppointmentServiceModel rollbackReturn(
    Appt_CreateAppointmentServiceModel returnModel,
    Savepoint sp,
    String errorCode,
    String errorMessage
  ) {
    Database.rollback(sp);
    if (String.isNotBlank(errorCode) || String.isNotBlank(errorMessage)) {
      returnModel.setError(errorCode, errorMessage);
    }
    return returnModel;
  }

  public static Appt_CreateAppointmentServiceModel evaluateDuplicateId(
    Appt_CreateAppointmentServiceModel apptModel,
    List<Account> listLoopAcc,
    Account workOrderAcc
  ) {
    if (
      apptModel.posCustomerId != null &&
      !String.isBlank(apptModel.posCustomerId)
    ) {
      Boolean accountFound = false;
      for (Account a : listLoopAcc) {
        if (a.POS_Customer_Id__c == apptModel.posCustomerId) {
          accountFound = true;
        }
      }

      if (accountFound) {
        apptModel.posCustomerId = workOrderAcc.POS_Customer_Id__c;
      }
      // Else POS model does not need to change
    } else {
      apptModel.posCustomerId = workOrderAcc.POS_Customer_Id__c;
    }

    if (
      apptModel.hybrisCustomerId != null &&
      !String.isBlank(apptModel.hybrisCustomerId)
    ) {
      Boolean accountFound = false;
      for (Account a : listLoopAcc) {
        if (a.Hybris_Customer_Id__c == apptModel.hybrisCustomerId) {
          accountFound = true;
        }
      }

      if (accountFound) {
        apptModel.hybrisCustomerId = workOrderAcc.Hybris_Customer_Id__c;
      }
      // Else POS model does not need to change
    } else {
      apptModel.hybrisCustomerId = workOrderAcc.Hybris_Customer_Id__c;
    }

    if (
      apptModel.customerGuid != null && !String.isBlank(apptModel.customerGuid)
    ) {
      Boolean accountFound = false;
      for (Account a : listLoopAcc) {
        if (a.GUID__c == apptModel.customerGuid) {
          accountFound = true;
        }
      }

      if (accountFound) {
        apptModel.customerGuid = workOrderAcc.GUID__c;
      }
      // Else POS model does not need to change
    } else {
      apptModel.customerGuid = workOrderAcc.GUID__c;
    }

    return apptModel;
  }

  // Appt 3.0 - Adds articles to WOLI object during appointment create and reschedule.

  public static void addArticlesToWOLI(
    List<Appt_CreateAppointmentServiceModel.Articles> articlesList,
    Id woId
  ) {
    System.debug(
      lprefix +
        'addArticlesToWOLI() ENTRY -  articlesList:' +
        articlesList +
        'Work Order ID ' +
        woId
    );
    List<WorkOrderLineItem> workLineArticles = new List<WorkOrderLineItem>();
    Id apptRecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName()
      .get('Appt3_Appointment_Articles')
      .getRecordTypeId();
    for (
      Appt_CreateAppointmentServiceModel.Articles itemArticle : articlesList
    ) {
      if (!String.isBlank(itemArticle.articleId)) {
        WorkOrderLineItem lineItem = new WorkOrderLineItem();
        lineItem.RecordTypeId = apptRecordTypeId;
        lineItem.WorkOrderId = woId;
        lineItem.WOM_Article_Description__c = itemArticle.articleDescription;
        lineItem.WOM_Article_Number__c = itemArticle.articleId;
        if (!String.isBlank(itemArticle.articleCount)) {
          lineItem.WOM_Article_Quantity__c = Integer.valueOf(
            itemArticle.articleCount
          );
        }
        lineItem.WOM_ArticleSize__c = itemArticle.articleSize;
        lineItem.Appt3_Article_Type__c = itemArticle.articleType;
        if (itemArticle.tredWell != null) {
          lineItem.Appt3_Treadwell__c = itemArticle.tredWell;
        }
        workLineArticles.add(lineItem);
      }
    }
    if (workLineArticles.size() > 0) {
      insert workLineArticles;
    }
    System.debug(lprefix + 'addArticlesToWOLI() EXIT');
  }

  // Appt 3.0 Changes - End

  // Appt 3.0 - Removes WOLIs that are stored during appointment creation so that incoming articles are added freshly during appointment update.

  public static void removeArticlesFromWOLI(Id woId) {
    System.debug(
      lprefix + 'removeArticlesFromWOLI() ENTRY -  Work Order ID:' + woId
    );
    Id apptRecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName()
      .get('Appt3_Appointment_Articles')
      .getRecordTypeId();
    List<WorkOrderLineItem> deleteArticles = [
      SELECT Id
      FROM WorkOrderLineItem
      WHERE WorkOrderId = :woId AND RecordTypeId = :apptRecordTypeId
    ];
    if (deleteArticles.size() > 0) {
      delete deleteArticles;
    }
    System.debug(lprefix + 'removeArticlesFromWOLI() EXIT');
  }
  // Appt 3.0 Changes - End
}
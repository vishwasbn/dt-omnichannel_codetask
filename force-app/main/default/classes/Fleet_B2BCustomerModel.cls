public class Fleet_B2BCustomerModel
{
    public static String lprefix = 'FLEET_B2B_CUSTOMER_MODEL:';

    public String eccId;
    public String country;
    public String countryDescription;
    public String companyName;
    public String companyName2;
    public String city;
    public String postalCode;
    public String state;
    public String street;
    public String phoneNumber;
    public String industryKey;
    public String industryKeyDescription;
    public String createdDate;
    public String groupKey;
    public String corporateGroupDescription;
    public String certificate;
    public String certificateDescription;
    public String invoiceCopy;
    public String invoiceCopyDescription;
    public String poRequired;
    public String poRequiredDescription;
    public String accountType;
    public String accountTypeDescription;
    public String accountPaymentType;
    public String accountPaymentTypeDescription;
    public String accountManager;
    public String accountManagerDescription;
    public String accountCompany;
    public String accountCompanyDescription;
    public String autoIntegrate;
    public String autoIntegrateDescription;
    public String creditLimit;
    public String taxClassification;
    public String taxClassificationDescription;
    public String street4;
    public String postingBlockForCompanyCode;
    public String accountingClerkAbbreviation;
    public String termsOfPaymentKey;
    public String termsOfPaymentKeyDescription;
    public String salesforceId;
    public String billingBlockforSalesArea;
    public String billingBlockforSalesAreaDescription;

    public String publicNotes;
    public String privateNotes;
    public String eccPOSNotes;

    public List<Contacts> contacts;

    public class Contacts {
        public String contactPersonId;
        public String firstName;
        public String lastName;
        public String department;
        public String departmentDescription;
        public String phoneNumber;
        public String customerReferenceNumber;
        public String primaryContactIndicator;
        public String primaryContactIndicatorDescription;
        public String title;
        public String emailAddress;
    }

    public List<InvoiceARRequiredFields> invoiceARRequiredFields;

    public class InvoiceARRequiredFields {
        public String characteristicValueAUSP;
        public String characteristicValueDescriptioinCAWNT;
        public String objectKeyINOB;
    }
    
    //---Primary Parse 
    public static Fleet_B2BCustomerModel parse(String json) {
        return (Fleet_B2BCustomerModel) System.JSON.deserialize(json, Fleet_B2BCustomerModel.class);
    }

    //---Map a single Account from model to Account record, if there are changes
    public static Account buildUpdateAccount(Account currAcct, Fleet_B2BCustomerModel b2bModel, id fleetSpecialistId, List<Fleet_State_Abbrev__mdt> stateCompareList) 
    {
        Account updateAcct = new Account(Id=currAcct.Id);
        Boolean hasChg = false;
        List<Fleet_State_Abbrev__mdt> stateCompareLists = [ SELECT State_Abbrev__c, State_Output__c FROM Fleet_State_Abbrev__mdt];
        //---Strip leading zeros for eccId update in salesforce (This is needed for golabl search to find accounts, since people won't seach with leading zeros)  
        String eccIdNoZeros = Fleet_B2BCustomerService.getECCIdNoZeros(b2bModel.eccId);

        Boolean isFirstSynch = (currAcct.ECC_Account_Number__c == null || currAcct.ECC_Account_Number__c == '');

        //---Do a state conversion if state code is 2 digit     
        if(b2bModel.state.length() == 2){
            //---Convert to full state name
            String convertState = Fleet_Util.convertTwoDigitStateToFullName(b2bModel.state, stateCompareList); 
            //---If conversion is successful check for changes and update the account - if not do nothing keeping a error from being thrown.
            if(convertState.length() > 2){
                hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, convertState, 'ShippingState');
            }
        }
        

        //---Update the eccId for the process of tying an account back once salesforce id has been input into ECC
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, eccIdNoZeros, 'ECC_Account_Number__c'); 

        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.companyName, 'Name');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.companyName2, 'Legal_Name__c');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.termsOfPaymentKeyDescription, 'Payment_Key_Terms__c');  //---termsOfPaymentKeyDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.eccPOSNotes, 'Fleet_POS_Notes__c');       
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.accountTypeDescription, 'Account_Type__c');  //---accountTypeDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.accountingClerkAbbreviation, 'Accounting_Clerk__c');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeededNum(currAcct, updateAcct, b2bModel.creditLimit, 'Credit_Limit__c');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.autoIntegrateDescription, 'ECC_AutoIntegrate__c');  //---autoIntegrateDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.corporateGroupDescription, 'ECC_Corporate_Group__c');  //--corporateGroupDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeededCB(currAcct, updateAcct, b2bModel.certificate, 'Fleet_Use_Certificates__c');  //---certificateDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.phoneNumber, 'Phone');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeededCB(currAcct, updateAcct, b2bModel.poRequired, 'PO_Required__c');  //---poRequiredDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeededCB(currAcct, updateAcct, b2bModel.invoiceCopy, 'Invoice_Copy_Sent__c'); //---invoiceCopyDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.accountPaymentTypeDescription, 'Payment_Type__c');  //---accountPaymentTypeDescription
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.taxClassificationDescription, 'Tax_Classification__c');  //---taxClassificationDescription  
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.country, 'ShippingCountryCode'); // User Story-437--added to fix FIELD_INTEGRITY_EXCEPTION
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.street, 'ShippingStreet');  
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.city, 'ShippingCity');  
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.postalCode, 'ShippingPostalCode');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.state, 'ShippingStateCode');// User Story-437--added to fix FIELD_INTEGRITY_EXCEPTION          
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.state, 'ECC_State__c');  
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.industryKeyDescription, 'ECC_Industry_Key__c');  
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.billingBlockforSalesAreaDescription, 'ECC_Billing_Block_Sale_Area__c');  
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.postingBlockForCompanyCode, 'ECC_Posting_Block_Company_Code__c');       
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.countryDescription, 'ECC_Country__c');       //---country   
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeededDate(currAcct, updateAcct, b2bModel.createdDate, 'SAP_Created_Date__c');          
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.accountManager, 'ECC_Account_Manager__c');          //accountManagerDescription

        if (fleetSpecialistId != null)
        {
            hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, fleetSpecialistId, 'Fleet_Specialist__c');  //---sets the fleet specialist user based on the account manager code
        }      
        
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.accountCompanyDescription, 'ECC_Account_Company__c');          //accountCompany
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currAcct, updateAcct, b2bModel.street4, 'ECC_Street_4__c');       

        //---Write a serialized string to the field
        String serializedARFields = Fleet_B2BCustomerModel.getSerializedARFields(b2bModel.invoiceARRequiredFields);
        if (currAcct.Fleet_Invoice_AR_Fields__c != serializedARFields)
        {
            updateAcct.Fleet_Invoice_AR_Fields__c = serializedARFields;
            hasChg = true;
        }

        if (hasChg) return updateAcct;
        return null;
    }

    //---Serialize just the AR fields
    public static String getSerializedARFields(List<InvoiceARRequiredFields> inputARFields )
    {
        Fleet_B2BCustomerModel newModel = new Fleet_B2BCustomerModel();
        newModel.invoiceARRequiredFields = inputARFields;

        return  System.JSON.serialize(newModel);
    }

    //---Deserialzed AR Fields
    public static Fleet_B2BCustomerModel getDeserializedARFields(String inputValue)
    {
        return (Fleet_B2BCustomerModel) System.JSON.deserialize(inputValue, Fleet_B2BCustomerModel.class);
    }

    //---Map a list of Contacts from model to list of contacts record, if there are changes
    public static Contact buildUpdateContact(List<Contact> currContactList, Fleet_B2BCustomerModel.Contacts b2bContactRow, String contactRTId, String acctId)
    {
        System.debug('b2bContactRow = '+b2bContactRow);
        if (b2bContactRow.contactPersonId == null)
        {
            System.debug( lprefix + 'b2bcontact has an empty contactPersonId, cannot match with existng Contact:' + b2bContactRow);
            return null;
        }

        Contact currContact = null;

        //---Check for a match based on Contact Person Id
        for( Contact cRow : currContactList)
        {
            System.debug('cRow = '+cRow);
            if (cRow.ECC_Contact_Person_Id__c == b2bContactRow.contactPersonId || (cRow.FirstName == b2bContactRow.firstName && cRow.LastName == b2bContactRow.lastName))
            {
                currContact = cRow;
                System.debug('currContact = '+currContact);
                break;
            }
        }

        if (currContact == null)
        {
            //---Have a Create model reference to match initially created values with the incoming payload
            Fleet_B2BCustomerModel.B2BCreateValues createModel = buildModelFromContactModel(b2bContactRow);
            System.debug( lprefix + 'Searching for existing Contact with the Create Values: ' + createModel);

            //---Check for a match based on the ECC Create Values
            for( Contact cRow : currContactList)
            {
                System.debug( lprefix + 'Building Compare Model from the String:' + cRow.ECC_Create_Values__c);
                Fleet_B2BCustomerModel.B2BCreateValues rowCreateModel = parseCreateModelFromString( cRow.ECC_Create_Values__c);

                //---Find a matching Contact, that has not already been assigned to an incoming Contact
                if (createModel.isEqual(rowCreateModel) && (cRow.ECC_Contact_Person_Id__c == null || cRow.ECC_Contact_Person_Id__c == ''))
                {
                    System.debug( lprefix + 'Found matching Contact: ' + cRow);

                    currContact = cRow;
                    break;
                }
            }

            /*
            if (currContact != null)
            {
                currContact.ECC_Contact_Person_Id__c=b2bContactRow.contactPersonId;
                
                //---Need to send outbound message of any updates that have been pending
                //SALESFORCE-420 : change to prevent cyclic calls between Salesforce & Mulesoft - commented below sync       
                //Fleet_ContactTriggerHandler.sendOutboundForContactECCSynch( currContact);
            }
			*/
        }


        Contact updateContact = null;

        if (currContact == null)
        {
            currContact = new Contact();
            updateContact = new Contact( RecordTypeId=contactRTId, AccountId=acctId, ECC_Contact_Person_Id__c=b2bContactRow.contactPersonId);
        }
        else 
        {
            updateContact = new Contact(Id=currContact.Id, ECC_Contact_Person_Id__c=b2bContactRow.contactPersonId);
        }

        Boolean hasChg = false;
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, b2bContactRow.contactPersonId, 'ECC_Contact_Person_Id__c');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, b2bContactRow.firstName, 'FirstName');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, b2bContactRow.lastName, 'LastName');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, b2bContactRow.departmentDescription, 'Department');  //---department
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, b2bContactRow.phoneNumber, 'Phone');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, b2bContactRow.title, 'Title');
        
        //---Check if the incoming
        if (Fleet_IntegrationUtil.getSettingBooleanValue( Fleet_Values.SETTING_ECC_MASK_CUSTOMER_EMAILS))
        {
            //---Mask the incoming email
            String maskSuffix = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_ECC_MASK_SUFFIX);

            if (b2bContactRow.emailAddress != null && b2bContactRow.emailAddress != '')
            {
                //---Get the incoming value and add the mask suffix
                String updateEmail = b2bContactRow.emailAddress;

                if (b2bContactRow.emailAddress.endsWith(maskSuffix))
                {
                    updateEmail = getTruncatedEmail(b2bContactRow.emailAddress, '');
                } 
                else 
                {
                    updateEmail = getTruncatedEmail(b2bContactRow.emailAddress, maskSuffix);
                }
                
                //---Check if the current email matches
                if (currContact.Email == null || currContact.Email == '' || currContact.Email != updateEmail)
                {
                    updateContact.Email = updateEmail;
                    hasChg = true;
                }
            }
        }
        else 
        {
            String email = getTruncatedEmail(b2bContactRow.emailAddress, '');
            hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, email, 'Email');
        }

        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeeded(currContact, updateContact, b2bContactRow.customerReferenceNumber, 'ECC_Customer_Reference_Number__c');
        hasChg = hasChg | Fleet_B2BCustomerModel.setUpdateFieldIfNeededCB(currContact, updateContact, b2bContactRow.primaryContactIndicator, 'ECC_Is_Primary_Contact__c');  //---primaryContactIndicatorDescription
        
        if (hasChg) return updateContact;
        return null;
    }

    //---Salesforce has a limit of 80 characters, need to truncate
    public static String getTruncatedEmail(String email, String mask)
    {
        Integer maxEmailLen = 80;  //---This is the Salesforce limit on the Contact Email Field

        String returnVal = '';
        if (email != null) returnVal = email;

        if (mask != null && mask != '')
        {
            Integer maskLen = mask.length();
            returnVal = returnVal.left(maxEmailLen-maskLen) + mask;
        }
        else 
        {
            returnVal = returnVal.left(maxEmailLen);
        }

        return returnVal;
    }

    //---Set the field on the Update Object, if the value has changed
    public static Boolean setUpdateFieldIfNeeded(SObject currObj, SObject updateObj, String modelField, String accountField)
    {
        System.debug( lprefix + 'Set Str Value:  FieldName:' + accountField + ' modelField:' + modelField + ' currObj:' +  currObj);

        if (modelField != null)
        {
            Object obj = currObj.get(accountField);

            if (obj == null)
            {                
                
                updateObj.put(accountField, modelField);
                System.debug( lprefix + 'Setting Str Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
                return true;
            }
            else
            {                
                String currVal = (String)currObj.get(accountField);

                //---If different, then set the update field
                if (currVal != modelField)
                {
                    updateObj.put(accountField, modelField);
                    System.debug( lprefix + 'Setting Str Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
                    return true;
                }
            }
        }

        return false;
    }

    //---Set the field on the Update Object, if the value has changed
    public static Boolean setUpdateFieldIfNeededCB(SObject currObj, SObject updateObj, String modelField, String accountField)
    {
       System.debug( lprefix + 'Set CB Value:  FieldName:' + accountField + ' modelField:' + modelField + ' currObj:' +  currObj);

        if (modelField != null)
        {
           Boolean modelVal = modelField == Fleet_Values.ECC_YES;
           Object obj = currObj.get(accountField);

           if (obj == null)
           {
               updateObj.put(accountField, modelVal);
               System.debug( lprefix + 'Setting CB Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
               return true;
           }
           else
           {
               //---Get current Value
               Boolean currVal = (Boolean)currObj.get(accountField);
   
               //---If different, then set the update field
               if (currVal != modelVal)
               {
                   updateObj.put(accountField, modelVal);
                   System.debug( lprefix + 'Setting CB Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
                   return true;
               }
           }
        }

        return false;
    }

    //---Set the field on the Update Object, if the value has changed
    public static Boolean setUpdateFieldIfNeededNum(SObject currObj, SObject updateObj, String modelField, String accountField)
    {
       System.debug( lprefix + 'Set Decimal Value:  FieldName:' + accountField + ' modelField:' + modelField + ' currObj:' +  currObj);

        if (modelField != null && modelField.trim() != '')
        {
            
            // Check for a valid value before casting to decimial            
            Decimal modelVal = Decimal.valueOf(modelField.trim());             
            
            Object obj = currObj.get(accountField);
                      

           if (obj == null)
           {
               updateObj.put(accountField, modelVal);
               System.debug( lprefix + 'Setting Decimal Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
               return true;
           }
           else
           {
               //---Get current Value
               Decimal currVal = (Decimal)currObj.get(accountField);
   
               //---If different, then set the update field
               if (currVal != modelVal)
               {
                   updateObj.put(accountField, modelVal);
                   System.debug( lprefix + 'Setting Decimal Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
                   return true;
               }
           }
        }

        return false;
    }

    //---Set the field on the Update Object, if the value has changed
    public static Boolean setUpdateFieldIfNeededDate(SObject currObj, SObject updateObj, String modelField, String accountField)
    {
       System.debug( lprefix + 'Set Date Value:  FieldName:' + accountField + ' modelField:' + modelField + ' currObj:' +  currObj);

        if (modelField != null && modelField.length() >= 8)
        {
            Integer year = Integer.valueOf(modelField.substring(0,4));
            Integer month = Integer.valueOf(modelField.substring(4,6));
            Integer day = Integer.valueOf(modelField.substring(6,8));

            Date modelVal = Date.newInstance(year, month, day); 
            Object obj = currObj.get(accountField);

           if (obj == null)
           {
               updateObj.put(accountField, modelVal);
               System.debug( lprefix + 'Setting Date Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
               return true;
           }
           else
           {
               //---Get current Value
               Date currVal = (Date)currObj.get(accountField);
   
               //---If different, then set the update field
               if (currVal != modelVal)
               {
                   updateObj.put(accountField, modelVal);
                   System.debug( lprefix + 'Setting Date Value:  FieldName:' + accountField + ' modelField:' + modelField + ' updateObj:' +  updateObj);
                   return true;
               }
           }
        }

        return false;
    }

    public static Fleet_B2BCustomerModel.B2BCreateValues parseCreateModelFromString(String json) 
    {
        Fleet_B2BCustomerModel.B2BCreateValues returnVal = new Fleet_B2BCustomerModel.B2BCreateValues();

        try 
        {
            returnVal = (Fleet_B2BCustomerModel.B2BCreateValues) System.JSON.deserialize(json, Fleet_B2BCustomerModel.B2BCreateValues.class);
        } 
        catch (Exception ex) 
        {
            String errorMessage = ex.getMessage();
            System.debug( lprefix + 'Error deserializing: ' + json + '  Incompatiable Format: ' + errorMessage);
        }

        return returnVal;
    }

    //---Get the values at time of ECC Contact Creation, use to match on incoming ECC update
    public static String getSerializedModelFromContactModel( Contacts contactObj)
    {
        Fleet_B2BCustomerModel.B2BCreateValues cModel = buildModelFromContactModel(contactObj);
        return System.JSON.serialize( cModel);
    }

    //---Get the values at time of ECC Contact Creation, use to match on incoming ECC update
    public static Fleet_B2BCustomerModel.B2BCreateValues buildModelFromContactModel(Contacts contactObj)
    {
        Fleet_B2BCustomerModel.B2BCreateValues retObj = new Fleet_B2BCustomerModel.B2BCreateValues();

        retObj.FirstName = getModelValue( contactObj.firstName);
        retObj.LastName = getModelValue( contactObj.lastName);
        retObj.Phone = getModelValue( contactObj.phoneNumber);
        retObj.Title = getModelValue( contactObj.title);
        retObj.Email = getModelValue( contactObj.emailAddress);

        return retObj;
    }

    //---Get the values at time of ECC Contact Creation, use to match on incoming ECC update
    public static String getSerializedModelFromContact( Contact contactObj)
    {
        Fleet_B2BCustomerModel.B2BCreateValues cModel = buildModelFromContact(contactObj);
        return System.JSON.serialize( cModel);
    }

    //---Get the values at time of ECC Contact Creation, use to match on incoming ECC update
    public static Fleet_B2BCustomerModel.B2BCreateValues buildModelFromContact(Contact contactObj)
    {
        Fleet_B2BCustomerModel.B2BCreateValues retObj = new Fleet_B2BCustomerModel.B2BCreateValues();

        retObj.FirstName = getModelValue( contactObj.FirstName);
        retObj.LastName = getModelValue( contactObj.LastName);
        retObj.Phone = getModelValue( contactObj.Phone);
        retObj.Title = getModelValue( contactObj.Title);
        retObj.Email = getModelValue( contactObj.Email);

        return retObj;
    }

    //---Get a value or ''
    public static String getModelValue(String inputVal)
    {
        return inputVal == null || inputVal == '' ? '' : inputVal;
    }

    //---This is used for tracking new Contacts and then matching with ECC Messages showing up later
    public class B2BCreateValues
    {
        public String FirstName;
        public String LastName;
        public String Phone;
        public String Title;
        public String Email;     
        
        public Boolean isEqual(B2BCreateValues compareObj)
        {   
            if (FirstName != compareObj.FirstName) return false;
            if (LastName != compareObj.LastName) return false;
            if (Phone != compareObj.Phone) return false;
            if (Title != compareObj.Title) return false;
            if (Email != compareObj.Email) return false;
            return true;
        }
    }
}
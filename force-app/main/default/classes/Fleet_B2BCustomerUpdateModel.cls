/**
 Created By : John Bruning
 Description : An apex page controller that exposes the site login functionality
 Modified By : Krishna Murty Sastry
 Modified Date :  21-03-2023
 User Story Number : Salesforce-864.
 */
public class Fleet_B2BCustomerUpdateModel
{
    public static String lprefix = 'FLEET_B2B_CUSTOMER_UPDATE_MODEL:'; 

    public String eccId;
    public String certificate;
    public String invoiceCopy;
    public String accountManager;
    public String contactPersonId;
    public String firstName;
    public String lastName;
    public String phoneNumber;
    //Added this field as part of UserStory-864 for bi-directional sync
    public String phoneExtension;
    public String isAlternateContact;//Added this field as part of UserStory-864 for bi-directional sync
    public String sendInvoiceReceipt;//Added this field as part of UserStory-864 for bi-directional sync
    public String customerReferenceNumber;
    public String primaryContactIndicator;
    public String title;
    public String emailAddress;

    public List<PublicNotes> publicNotes = new List<PublicNotes> ();
    public List<PublicNotes> privateNotes = new List<PublicNotes>() ;

    public class PublicNotes {
        public String line;
    }

    //---Primary parse method
    public static Fleet_B2BCustomerUpdateModel parse(String json) {
        return (Fleet_B2BCustomerUpdateModel) System.JSON.deserialize(json, Fleet_B2BCustomerUpdateModel.class);
    }

    //---Primary serialize method
    public String getJson()
    {
        return System.JSON.serialize(this);
    }

    //---Build the model from the Account (comparing old to new)
    public Boolean buildFromAccount(Account oldObj, Account newObj)
    {
        Boolean hasECCChanges = false;

        if (newObj.Fleet_Use_Certificates__c != oldObj.Fleet_Use_Certificates__c)
        {
            hasECCChanges = true;
            certificate = newObj.Fleet_Use_Certificates__c ? Fleet_Values.ECC_YES : Fleet_Values.ECC_NO;
        }
        if (newObj.Invoice_Copy_Sent__c != oldObj.Invoice_Copy_Sent__c)
        {
            hasECCChanges = true;
            invoiceCopy = newObj.Invoice_Copy_Sent__c ? Fleet_Values.ECC_YES : Fleet_Values.ECC_NO;
        }
        if (newObj.Fleet_Specialist__c != oldObj.Fleet_Specialist__c)  //---Fleet Specialist
        {
            hasECCChanges = true;
            accountManager = '0';     //---Placeholder, This is queried from User Table before sending
        }
        if (newObj.Fleet_Public_Notes__c != oldObj.Fleet_Public_Notes__c)
        {
            hasECCChanges = true;

            if (newObj.Fleet_Public_Notes__c != null && newObj.Fleet_Public_Notes__c != '')
            {
                publicNotes = buildSeparateLineList(newObj.Fleet_Public_Notes__c.replace('<br>', Fleet_Values.LINE_BREAK));
            }
            else 
            {
                publicNotes = buildSeparateLineList('');
            }
        }

        if (newObj.Fleet_Private_Notes__c != oldObj.Fleet_Private_Notes__c)
        {
            hasECCChanges = true;

            if (newObj.Fleet_Private_Notes__c != null && newObj.Fleet_Private_Notes__c != '')
            {
                privateNotes = buildSeparateLineList(newObj.Fleet_Private_Notes__c);
            }
            else 
            {
                privateNotes = buildSeparateLineList('');
            }
        }

        return hasECCChanges;
    }

    //---Build the model from the Contact (comparing old to new)
    public ModelBuildStatus buildFromContact(Contact oldObj, Contact newObj)
    {
        Boolean hasECCChanges = false;
        ModelBuildStatus returnVal = new ModelBuildStatus();

        List<String> fieldsChangedList = new List<String>();

        contactPersonId = newObj.ECC_Contact_Person_Id__c;
         
        if (newObj.FirstName != oldObj.FirstName)
        {
            hasECCChanges = true;
            fieldsChangedList.add('FirstName');

            if (newObj.FirstName != null && newObj.FirstName != '')
            {
                firstName = newObj.FirstName;
            }
            else 
            {
                firstName = '';
            }
        }
        if (newObj.LastName != oldObj.LastName)
        {
            hasECCChanges = true;
            fieldsChangedList.add('LastName');

            if (newObj.LastName != null && newObj.LastName != '')
            {
                lastName = newObj.LastName;
            }
            else 
            {
                lastName = '';
            }
        }
        if (newObj.Phone != oldObj.Phone)
        {
            hasECCChanges = true;
            fieldsChangedList.add('Phone');

            if (newObj.Phone != null && newObj.Phone != '')
            {
                phoneNumber = formatPhoneNumber(newObj.Phone);
            }
            else 
            {
                phoneNumber = '';
            }
        }
         //Added this field as part of UserStory-864 for bi-directional sync
          if (newObj.Phone_Extension__c != oldObj.Phone_Extension__c)
        {
            hasECCChanges = true;
            fieldsChangedList.add('Phone_Extension__c');

            if (newObj.Phone_Extension__c != null && newObj.Phone_Extension__c != '')
            {
                phoneExtension = newObj.Phone_Extension__c;
            }
            else 
            {
                phoneExtension = '';
            }
        }
        if (newObj.Is_Alternate_Contact__c != oldObj.Is_Alternate_Contact__c)
        {
            hasECCChanges = true;
            fieldsChangedList.add('Is_Alternate_Contact__c');

            isAlternateContact = newObj.Is_Alternate_Contact__c ? Fleet_Values.ECC_YES : '';
        }
        if (newObj.Send_Invoice_Receipt__c != oldObj.Send_Invoice_Receipt__c)
        {
            hasECCChanges = true;
            fieldsChangedList.add('Send_Invoice_Receipt__c');

            sendInvoiceReceipt = newObj.Send_Invoice_Receipt__c ? Fleet_Values.ECC_YES : '';
        }
        if (newObj.Title != oldObj.Title)
        {
            hasECCChanges = true;
            fieldsChangedList.add('Title');

            if (newObj.Title != null && newObj.Title != '')
            {
                title = newObj.Title;
            }
            else 
            {
                title = '';
            }
        }

        //---Check emails, but supress if the Mask flag is set
        if (newObj.Email != oldObj.Email )
        {
            hasECCChanges = true;
            fieldsChangedList.add('Email');

            if (newObj.Email != null && newObj.Email != '')
            {
                String currEmail = newObj.Email;

                //---Check if Masking
                if (Fleet_IntegrationUtil.getSettingBooleanValue( Fleet_Values.SETTING_ECC_MASK_CUSTOMER_EMAILS))
                {
                    String maskSuffix = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_ECC_MASK_SUFFIX);

                    if (maskSuffix != null)
                    {
                        //---Remvoe the mask if it exists
                        if (currEmail.endsWith(maskSuffix)) currEmail = currEmail.substring(0, currEmail.length() - maskSuffix.length());
                    }                    
                }

                emailAddress = currEmail;
            }
            else 
            {
                emailAddress = '';
            }
        }
        if (newObj.ECC_Is_Primary_Contact__c != oldObj.ECC_Is_Primary_Contact__c)
        {
            hasECCChanges = true;
            fieldsChangedList.add('ECC_Is_Primary_Contact__c');

            primaryContactIndicator = newObj.ECC_Is_Primary_Contact__c ? Fleet_Values.ECC_YES : '';
        }
        if (newObj.ECC_Customer_Reference_Number__c != oldObj.ECC_Customer_Reference_Number__c)
        {
            hasECCChanges = true;
            fieldsChangedList.add('ECC_Customer_Reference_Number__c');

            if (newObj.ECC_Customer_Reference_Number__c != null && newObj.ECC_Customer_Reference_Number__c != '')
            {
                customerReferenceNumber = newObj.ECC_Customer_Reference_Number__c;
            }
            else 
            {
                customerReferenceNumber = '';
            }
        }

        if (hasECCChanges == true && contactPersonId  == null)
        {
            System.debug( lprefix + 'There are Contact changes, but the ECC Id is null.   Need to supress outbound update to prevent duplicate NEW contacts, but record which fields have been updated.');

            //---Get the updated list of fields that have been changed
            returnVal.eccPendingFields = addPendingFields(newObj.ECC_Pending_Fields__c,  fieldsChangedList);

            System.debug( lprefix + 'The following fields have been updated: ' + returnVal.eccPendingFields);
            hasECCChanges = false;
        }

        returnVal.hasChanges = hasECCChanges;
        return returnVal;
    }

    //---Build the model from the Contact
    public ModelBuildStatus buildFromNewContact(Contact newObj)
    {     
        ModelBuildStatus returnVal = new ModelBuildStatus();

        List<String> fieldsChangedList = new List<String>();

        contactPersonId = newObj.ECC_Contact_Person_Id__c;     
        
        firstName = newObj.FirstName;    
        if (firstName != null) fieldsChangedList.add('FirstName');
        
        lastName = newObj.LastName;                
        if (lastName != null) fieldsChangedList.add('LastName');

        phoneNumber = newObj.Phone;          
        if (phoneNumber != null ) fieldsChangedList.add('Phone');
    
        //Added this field as part of UserStory-864 for bi-directional sync
        phoneExtension = newObj.Phone_Extension__c;          
        if (phoneExtension != null ) fieldsChangedList.add('Phone_Extension__c');
        
        isAlternateContact = newObj.Is_Alternate_Contact__c ? Fleet_Values.ECC_YES : '';           
        fieldsChangedList.add('Is_Alternate_Contact__c');
               
        sendInvoiceReceipt = newObj.Send_Invoice_Receipt__c ? Fleet_Values.ECC_YES : '';           
        fieldsChangedList.add('Send_Invoice_Receipt__c');
        
    
        title = newObj.Title;
        if (title != null) fieldsChangedList.add('Title');                

        emailAddress = newObj.Email;    
        if (emailAddress != null ) fieldsChangedList.add('Email');            

        primaryContactIndicator = newObj.ECC_Is_Primary_Contact__c ? Fleet_Values.ECC_YES : '';           
        fieldsChangedList.add('ECC_Is_Primary_Contact__c');    
        
        customerReferenceNumber = newObj.ECC_Customer_Reference_Number__c;    
        if (customerReferenceNumber != null) fieldsChangedList.add('ECC_Customer_Reference_Number__c');
        
        returnVal.hasChanges = true;
        returnVal.eccPendingFields = addPendingFields(newObj.ECC_Pending_Fields__c,  fieldsChangedList);

        return returnVal;
    }

    //---Build the model from the Contact, using the fields flagged as changed
    public Boolean buildFromPendingContact(Contact newObj)
    {
        String pendingFields = newObj.ECC_Pending_Fields__c;
        if (pendingFields == null || pendingFields == '')
        {
            System.debug( lprefix + 'The list of pending fields is empty, no need to send a message');
            return false;
        }

        if (pendingFields.contains('FirstName')) firstName = newObj.FirstName; 
        if (pendingFields.contains('LastName')) lastName = newObj.LastName; 
        if (pendingFields.contains('Phone')) phoneNumber = newObj.Phone; 
         //Added this field as part of UserStory-864 for bi-directional sync
        if (pendingFields.contains('Phone_Extension__c')) phoneExtension = newObj.Phone_Extension__c;
        if (pendingFields.contains('Is_Alternate_Contact__c')) isAlternateContact = newObj.Is_Alternate_Contact__c? Fleet_Values.ECC_YES : '';  
        if (pendingFields.contains('Send_Invoice_Receipt__c')) sendInvoiceReceipt = newObj.Send_Invoice_Receipt__c ? Fleet_Values.ECC_YES : '';
        if (pendingFields.contains('Title')) title = newObj.Title; 
        if (pendingFields.contains('Email')) emailAddress = newObj.Email; 
        if (pendingFields.contains('ECC_Is_Primary_Contact__c')) primaryContactIndicator = newObj.ECC_Is_Primary_Contact__c ? Fleet_Values.ECC_YES : '';    
        if (pendingFields.contains('ECC_Customer_Reference_Number__c')) customerReferenceNumber = newObj.ECC_Customer_Reference_Number__c;   

        contactPersonId = newObj.ECC_Contact_Person_Id__c;

        return true;
    }

    //---Build the delete model from the Contact
    public Boolean buildDeleteContact(Contact deleteObj)
    {
        Boolean hasECCContactId = false;

        if (deleteObj.ECC_Contact_Person_Id__c != null && deleteObj.ECC_Contact_Person_Id__c != '')
        {
            hasECCContactId = true; 
            contactPersonId = deleteObj.ECC_Contact_Person_Id__c;
            lastName = 'DELETETHISCONTACTNOW';         
        } 

        if (hasECCContactId == false){
            System.debug('error thrown because you can not make upodates in sap without an customer id');
            deleteObj.addError('Contact must be synced from SAP before it can be deleted in salesforce. Refresh the data then try again');
        }

        return hasECCContactId;
    }

    //---Build separate lines
    public List<PublicNotes> buildSeparateLineList(String inputField)
    {
        List<PublicNotes> retList = new List<PublicNotes>();

        List<String> sepLineList = getSeparateLines(inputField);
        for(String strLine : sepLineList) 
        {
            PublicNotes nRow = new PublicNotes();
            nRow.line = strLine;
            retList.add(nRow);
        }

        return retList;
    }

    //---Split the Text by Lines
    public List<String> getSeparateLines(String multiLineText)
    {
        List<String> retList = new List<String>();
        //---Split by line breaks
        List<String> pass1List = multiLineText.split(Fleet_Values.LINE_BREAK);

        for(String p1Row : pass1List)
        {
            //---Check for max length
            if (p1Row.length() > Fleet_Values.MAX_CHARS_PER_LINE)
            {   
                List<String> pass2List = getSeparateLinesSplitBySpace( p1Row);

                for(String p2Row : pass2List)
                {
                    //---Check for max length
                    if (p2Row.length() > Fleet_Values.MAX_CHARS_PER_LINE)
                    {   
                        List<String> pass3List = getSeparateLinesSplitBySize( p2Row);
                        for(String p3Row : pass3List) retList.add( p3Row);
                    }
                    else 
                    {
                        retList.add( p2Row);
                    }
                }
            }
            else 
            {
                retList.add( p1Row);
            }
        }

        return retList;
    }

    //---Get separate lines, by separating words
    public List<String> getSeparateLinesSplitBySpace(String multiLineText)
    { 
        List<String> retList = new List<String>();
        String currText = multiLineText;

        while (true)
        {
            String rowLine = getFirstLineByWordBreak(currText);
            retList.add( rowLine);

            if (rowLine.length() == currText.length())
            {
                break;
            }
            else 
            {
                //---Take off the first part of the string
                if (currText.length() > rowLine.length())
                {
                    currText = currText.substring(rowLine.length() + 1);
                }
                else 
                {
                    break;
                }

                if (currText.length() == 0 ) break;
                if (currText.length() < Fleet_Values.MAX_CHARS_PER_LINE)
                {
                    retList.add(currText);
                    break;
                }
            }
        }

        return retList;
    }

    //---Get the first line, breaking at the first space below the max characters
    public String getFirstLineByWordBreak(String inputLine)
    {
        if (inputLine.length() < Fleet_Values.MAX_CHARS_PER_LINE) return inputLine;

        for (Integer pos = Fleet_Values.MAX_CHARS_PER_LINE-1; pos > 0; pos--)
        {
            if (inputLine.substring(pos, pos+1) == ' ')
            {
                return inputLine.substring(0, pos);
            }
        }

        return inputLine;
    }

    //---Get separate lines, breaking up at the position (regardless of text)
    public List<String> getSeparateLinesSplitBySize(String multiLineText)
    { 
        List<String> retList = new List<String>();
        String currLine = '';

        //---Loop through all the characters, building the lines up to the max length
        for (Integer pos = 0; pos < multiLineText.length(); pos++)
        {
            currLine += multiLineText.charAt(pos);

            if (currLine.length() >= Fleet_Values.MAX_CHARS_PER_LINE)
            {
                retList.add(currLine);
                currLine = '';
            }
        }

        return new List<String>();
    }

    public static String addPendingFields(String eccPendingFields, List<String> fieldChangeList)
    {
        if (eccPendingFields == null) eccPendingFields = '';

        for(String fRow: fieldChangeList)
        {
            if (!eccPendingFields.contains( fRow))
            {
                if (eccPendingFields != '') eccPendingFields += ',';
                eccPendingFields += fRow;
            } 
        }

        return eccPendingFields;
    }

    //---Get the values at time of ECC Contact Creation, use to match on incoming ECC update
    public static String getNewContactCreateValues(Contact newObj)
    {
        return Fleet_B2BCustomerModel.getSerializedModelFromContact( newObj);
    }

    public class ModelBuildStatus {
        public Boolean hasChanges;
        public String eccPendingFields;
    }
    
    static String formatPhoneNumber(String phone) {
        if(phone == null) return phone;
        phone = phone.replace('(', '');
        phone = phone.replace(')', '');
        phone = phone.replace('-', '');
        phone = phone.replace(' ', '');
        
        if(phone.length() == 10)
            phone = phone.substring(0, 3) + '-' + phone.substring(3, 6) + '-' + phone.substring(6);
         System.debug('Phone--'+phone);   
        return phone;
    }
}
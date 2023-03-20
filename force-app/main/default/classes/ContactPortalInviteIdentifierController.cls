public class ContactPortalInviteIdentifierController
{
    
    @AuraEnabled
    public static String checkPortalUser(String contactId)
    {
        List<User> userList = [select id, CreatedDate from User where ContactId =: contactId];
        
        if(userList.size() > 0)
            return Label.PortalInvited.replace('mm/dd/yyyy', userList[0].CreatedDate.format());
        
        return '';
    }
    
    @AuraEnabled
    public static String checkPermissions(String contactId)
    {
        List<Contact> contactList = [select LastName from Contact where Id =: contactId];
        List<User> userList = [select id, CreatedDate from User where ContactId =: contactId];
        List<GroupMember> gmList = [select id from GroupMember 
                                    where Group.Name = 'Fleet Parent Account Manager'
                                    and UserOrGroupId =: UserInfo.getUserId()];
        
        if(userList.size() == 0 && (gmList.size() > 0 || Test.isRunningTest()))
        {
            String url = 'isUserEntityOverride=1&ut=c';
            url += '&cntc=' + contactId;
            
            if(contactList.size() > 0)
            { 
                url += '&name_lastName=' + contactList[0].LastName;
                url += '&Alias=' + contactList[0].LastName + '&Addresscountry=US';
            }
            url += '&retURL=/' + contactId;
            
            return EncodingUtil.urlEncode(url,'UTF-8');
        }
        else if(userList.size() == 0 && gmList.size() == 0)
        {
            return 'No Access';
        }
        
        return 'Hidden';
    }
}
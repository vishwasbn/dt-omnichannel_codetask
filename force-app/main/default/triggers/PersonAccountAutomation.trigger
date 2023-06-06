/*
Change Log
10/18/12    SB @ IC    Initial Creation
10/24/12    SB @ IC    Implement existing account matching
*/
trigger PersonAccountAutomation on Case (before insert) {
    
    Boolean canBypassLogic = FeatureManagement.checkPermission('Bypass_Logic');
    system.debug('###'+canBypassLogic);
    if(!canBypassLogic)
    {
        RecordType personType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND sObjectType = 'Account' LIMIT 1];
        for (Case c : Trigger.new) {
            if (c.SuppliedEmail != null) {
                Account person;
                //Checks for existing accounts matching based on email
                list<Account> accts = [SELECT Id,Phone FROM Account WHERE PersonEmail = :c.SuppliedEmail];
                if (!accts.isEmpty()) {
                    if (accts.size() == 1)
                        person = accts[0];
                    else {
                        //If multiple matches, match based on phone
                        for (Account a : accts) {
                            if(a.phone!=null)
                            {
                                if (a.Phone.equals(c.SuppliedPhone)) {
                                    person = a;
                                    break;
                                }
                            }
                        }
                        if (person == null)
                            person = accts[0];
                    }
                } else {
                    String first = '';
                    String last = '';
                    //Break the name into first and last if possible
                    if (c.SuppliedName != null && c.SuppliedName.contains(' ')) {
                        first = c.SuppliedName.substring(0,c.SuppliedName.indexOf(' '));
                        last = c.SuppliedName.substring(c.SuppliedName.indexOf(' ')+1);
                    } else {
                        last = c.SuppliedName;
                    }
                    //If no supplied name use unknown and email
                    if (c.SuppliedName == null) {
                        last = 'Unknown';
                        first = c.SuppliedEmail;
                    }
                    person = new Account(RecordTypeId = personType.Id,FirstName = first,LastName = last,PersonEmail = c.SuppliedEmail,Phone = c.SuppliedPhone);
                    insert person;
                }
                //Set the account and contact on the new case
                c.AccountId = person.Id;
                c.ContactId = [SELECT PersonContactId FROM Account WHERE Id = :person.Id].PersonContactId;
            }
        }
    }
}
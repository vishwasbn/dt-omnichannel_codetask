public with sharing class LimitsMonitor_Scheduler implements System.Schedulable {
    
    private Decimal percent;
    private String email;
    String limitTabPath = '/lightning/n/Limits_Monitor';
    String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

    public LimitsMonitor_Scheduler(Decimal percent, String email) {
        
        this.percent = percent;
        this.email = email;
        
    }
    public void execute(System.SchedulableContext context){
        List<String> limitsForNotification = new List<String>();
        Map<String, OrgLimit> limits = LimitsMonitor_Controller.getThisOrgLimits();
        for(String key : limits.keySet()){
            
            OrgLimit orgLimit = limits.get(key);
            system.debug(orgLimit.getName() + ' ' + orgLimit.getValue() + ' ' + orgLimit.getLimit());
            if(orgLimit.getLimit() != 0){
                Decimal max = Decimal.valueOf(orgLimit.getLimit());
                Decimal val = Decimal.valueOf(orgLimit.getValue());
                Decimal consumedPercent = val.divide(max, 2);
                if(consumedPercent >= percent){
                    limitsForNotification.add(orgLimit.getName());
                }
            }
        }
        
        system.debug(limitsForNotification);
        if(!limitsForNotification.isEmpty()){
            // Send Email to Current Logged in User
            sendEmailAlert(limitsForNotification);
        }
    }
    
    public void sendEmailAlert(List<String> limitsForNotification){
        OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where address='it_salesforce@discounttire.com' limit 1];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(new List<String>{owa.Address});
        //message.setTargetObjectId(UserInfo.getUserId());
        if(owa!=null){
            message.setOrgWideEmailAddressId(owa.id);
        }
        if(email != ''){
            message.setCcAddresses(new List<String>{email});
        }
        
        message.subject = 'Limit Alert'+' - '+ getSandboxName();
        
        String plainTextBody = 'Hello Admin, Please be alerted about the following limits crossing '+percent+ '%. Please check Limits Monitor for further details' ;
        String htmlBody = 'Hello Admin, <br/>' + 
            'Please be alerted about the following limits crossing '+percent+ '%. Please check Limits Monitor App for further details'+
            '<ul>';
        
        
        for(String lim : limitsForNotification){
            htmlBody += '<li>'+ lim + '</lim>';
            plainTextBody += ' ' + lim;
        }
        htmlBody+= '</ul>';
        htmlBody+= '<br/>'+
        '<p>Check limit monitor dashboard here : <a href="'+baseUrl+limitTabPath+'">'+baseUrl+limitTabPath+'</a></p>';
        message.setHtmlBody(htmlBody);
        message.setPlainTextBody(plainTextBody);
        message.setSaveAsActivity(false);
        
        Messaging.SingleEmailMessage[] messages = 
            new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: '
                         + results[0].errors[0].message);
        }  
    }
    
    public String getSandboxName(){
        System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
        String sandboxName = d.getSandboxName();
        if(sandboxName == null){
            sandboxName = 'Production';
        }
        Organization orgInfo = [SELECT Id, Name FROM Organization LIMIT 1];
        String orgId = orgInfo.Id;
        String orgName = orgInfo.Name;
        return orgId.substring(0, 15)+' ( '+orgName+' - '+sandboxName+' )';
    }
    
    
}
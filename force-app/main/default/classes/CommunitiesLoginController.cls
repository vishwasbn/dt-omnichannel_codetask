/**
 Created By : John Bruning
 Creatted Dated : 10/29/2020, 6:08 AM
 Description : An apex page controller that exposes the site login functionality
 Modified By : Krishna Murty Sastry
 Modified Date :  8/22/2022, 28/03/2023,20-04-2023
 User Story Number : Salesforce-464,Salesforce-897,-Salesforce-897,Salesforce-1051,Salesforce-1082.
 */
global without sharing class CommunitiesLoginController {

    global CommunitiesLoginController () {}
    
    // Code we will invoke on page load.
    global PageReference forwardToAuthPage() {
    	String startUrl = System.currentPageReference().getParameters().get('startURL');
        String displayType = System.currentPageReference().getParameters().get('display');
        System.debug('startUrl: ' + startUrl + ' displayType: ' + displayType);
        return Network.forwardToAuthPage(startUrl, displayType);
    }

    @AuraEnabled
    public static String loginUser(String username, String password, String urlParam){

        // Try to login using PageReference, pass back exception if unsuccessful
        try {
            String pageName = '/';
            if(urlParam != null && String.isNotBlank(urlParam) && urlParam.contains('app')){
                pageName =  '/apex/Fleet_MotorqRedirectURL';
            }
            PageReference redirectPage = Site.login(username, password, pageName);
            // Pass a string back out to controller to allow it to redirect
            String redirectUrl = redirectPage.getUrl(); return redirectUrl;
            //System.debug('redirectUrl: ' + redirectUrl);
            
        }
        catch(Exception ex){
            system.debug('Exception: ' + ex.getMessage());
            AuraHandledException ahe = new AuraHandledException('Username or password is incorrect');
            ahe.setMessage('Username or password is incorrect');
            throw ahe;
        }
    }
    // The below method accepts 4 parameters to redirect the page to Fleet Sercies parking tab.
    @AuraEnabled
    public static String loginUser(String username, String password, String urlParam,String redirect){

        // Try to login using PageReference, pass back exception if unsuccessful
        try {
            String pageName = '/';
            if(urlParam != null && String.isNotBlank(urlParam) && urlParam.contains('app')){
                pageName =  '/apex/Fleet_MotorqRedirectURL';
            }
            // The below if condition redirects to Fleet services Parking tab
            if(redirect=='parking') {
               pageName =  System.Label.Fleet_ParkingTabURL; 
            }
            // The below if condition redirects to Oil Changes sub-tab under Mobile services Page.
            if(redirect=='mobileservices'){
                system.debug('in Mobile services');
                pageName=System.Label.Fleet_MobileServices;
            }
            // The below if condition redirects to Mobile Auto Repair sub-tab under Mobile services Page.
            if(redirect=='Nubrakes'){
                system.debug('in Nubrakes');
                pageName=System.Label.Fleet_NubrakesURL;
            }
            // The below if condition redirects to RoadSide Assistance sub-tab under Fleet services Page.
            if(redirect=='rsa'){
                system.debug('in RoadSideAssistance');
                pageName=System.Label.Fleet_RSATabsetURL;
            }
            // The below if condition redirects to Fuel sub-tab under Fleet services Page.
            if(redirect=='coast'){
                system.debug('in Coast');
                pageName=System.Label.Fleet_CoastTabsetURL;
            }
             // The below if condition redirects to DT Mobile Services sub-tab under Mobile services Page.
            if(redirect=='MobileVan'){
                system.debug('in MobileVan');
                pageName=System.Label.Fleet_MobileVanTabURL;
            }
            PageReference redirectPage = Site.login(username, password, pageName);
            // Pass a string back out to controller to allow it to redirect
            String redirectUrl = redirectPage.getUrl(); return redirectUrl;
            //System.debug('redirectUrl: ' + redirectUrl);
            
        }
        catch(Exception ex){
            system.debug('Exception: ' + ex.getMessage());
            AuraHandledException ahe = new AuraHandledException('Username or password is incorrect');
            ahe.setMessage('Username or password is incorrect');
            throw ahe;
        }
    }

    @AuraEnabled
    public static string resetUserPassword(string username){
        // Retrieve user with the given username
        User u;
        try 
        {
            u = [SELECT Id FROM User WHERE Username = :username LIMIT 1];
        }
        catch (Exception ex) {
            system.debug('Exception: ' + ex.getMessage());
            AuraHandledException ahe = new AuraHandledException('Cannot find a user with that username.');
            ahe.setMessage('Cannot find a user with that username.');
            throw ahe;
        }

        System.resetPassword(u.Id, true);
        return 'An email has been sent succesfully to your email address!';
    }
    
}
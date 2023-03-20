@isTest
public with sharing class TokenCacheControllerTest {
    @isTest
    public static void TokenCacheControllerTest() {
        Int_Message__c intMsg = new Int_Message__c();
        String token = TokenCacheController.getCachedToken(TokenCacheController.ECC, intMsg);
        //System.assert(token.length()>0, 'Token Recieved');
    }
}
public class TokenCacheController {
    
    public static final String ECC = 'ECC';
    
    // Get partition
	static Cache.OrgPartition orgPart = Cache.Org.getPartition('local.AccessTokenCache');
    
    public static String getCachedToken(String destinationSystem, Int_Message__c intMsg){
        String token = null;
      
        if(destinationSystem == ECC){
            token = (String)orgPart.get(ECC);
            if(token == null) {
                System.debug('okta token not available in the cache, performing refresh');
                token = refreshToken(destinationSystem, intMsg);
            }else{
                System.debug('okta token retrieved from cache');
            }
        }
        
        return token;
    }
    
    private static String refreshToken(String destinationSystem, Int_Message__c intMsg){
    	String token = null;
        token = Fleet_IntegrationUtil.getBearerToken(intMsg);
        if(token != null && token != ''){
        	orgPart.put(ECC, token, Integer.valueOf(Label.Okta_Token_Cache_Expiration));
            System.debug('okta token refreshed');
        } 
        return token;
    }
}
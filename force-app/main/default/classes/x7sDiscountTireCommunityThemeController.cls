public with sharing class x7sDiscountTireCommunityThemeController {
  @AuraEnabled
  public static string getUserType() {
    return UserInfo.getUserType();
  }
}
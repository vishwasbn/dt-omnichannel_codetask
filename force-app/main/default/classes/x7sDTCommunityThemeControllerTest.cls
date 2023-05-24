@IsTest
public class x7sDTCommunityThemeControllerTest {
  @IsTest
  public static void testGetUserType() {
    User u = [SELECT id FROM user WHERE usertype = 'Guest' LIMIT 1];
    System.runAs(u) {
      String result = x7sDiscountTireCommunityThemeController.getUserType();
      System.AssertEquals(result, 'Guest');
    }
  }
}
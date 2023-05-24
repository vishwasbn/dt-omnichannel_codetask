@isTest
public class FleetDiscountImgCntrlTest {
    @isTest
    public static void FleetDiscountImgCntrlTest(){
        Test.startTest();
        FleetDiscountImgCntrl fleet = New FleetDiscountImgCntrl();
        ApexPages.currentPage().getParameters().put('name','Testtttttttttttttt Acccccccccccouuuuuuuuuunnnnnnntttttttt');
        fleet.accountNameBreak();
        Test.stopTest();
    }
}
@istest public class Appt_ConstantValuesTest {

    static TestMethod void ConstantExtension_UnitTest1(){
        Test.startTest();
        System.assertEquals(Appt_ConstantValues.CUSTOMER_TYPE_FLEET,'Fleet');
        test.stopTest();
    }

}
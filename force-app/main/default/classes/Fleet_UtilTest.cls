@isTest
public class Fleet_UtilTest {

    @isTest
    public static void stateConvertTest() {

        List<Fleet_State_Abbrev__mdt> stateCompareList = [ SELECT State_Abbrev__c, State_Output__c FROM Fleet_State_Abbrev__mdt];

        Test.startTest();

        String result = Fleet_Util.convertTwoDigitStateToFullName('AL',stateCompareList);
        System.assert(result == 'Alabama', 'Alabama Test');
 
        result = Fleet_Util.convertTwoDigitStateToFullName('AK', stateCompareList);
        System.assert(result == 'Alaska', 'Alaska Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('AZ', stateCompareList);
        System.assert(result == 'Arizona', 'Arizona Test');
        
        result = Fleet_Util.convertTwoDigitStateToFullName('AR', stateCompareList);
        System.assert(result == 'Arkansas', 'Arkansas Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('CA', stateCompareList);
        System.assert(result == 'California', 'California Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('CO', stateCompareList);
        System.assert(result == 'Colorado', 'Colorado Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('CT', stateCompareList);
        System.assert(result == 'Connecticut', 'Connecticut Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('DE', stateCompareList);
        System.assert(result == 'Delaware', 'Delaware Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('FL', stateCompareList);
        System.assert(result == 'Florida', 'Florida Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('GA', stateCompareList);
        System.assert(result == 'Georgia', 'Georgia Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('HI', stateCompareList);
        System.assert(result == 'Hawaii', ' Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('ID', stateCompareList);
        System.assert(result == 'Idaho', ' Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('IL', stateCompareList);
        System.assert(result == 'Illinois', 'Illinois Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('IN', stateCompareList);
        System.assert(result == 'Indiana', 'Indiana Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('IA', stateCompareList);
        System.assert(result == 'Iowa', 'Iowa Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('KS', stateCompareList);
        System.assert(result == 'Kansas', 'Kansas Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('KY', stateCompareList);
        System.assert(result == 'Kentucky', 'Kentucky Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('LA', stateCompareList);
        System.assert(result == 'Louisiana', 'Louisiana Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('ME', stateCompareList);
        System.assert(result == 'Maine', 'Maine Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('MD', stateCompareList);
        System.assert(result == 'Maryland', 'Maryland Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('MA', stateCompareList);
        System.assert(result == 'Massachusetts', 'Massachusetts Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('MI', stateCompareList);
        System.assert(result == 'Michigan', 'Michigan Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('MN', stateCompareList);
        System.assert(result == 'Minnesota', 'Minnesota Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('MS', stateCompareList);
        System.assert(result == 'Mississippi', 'Mississippi Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('MO', stateCompareList);
        System.assert(result == 'Missouri', 'Missouri Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('MT', stateCompareList);
        System.assert(result == 'Montana', 'Montana Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('NE', stateCompareList);
        System.assert(result == 'Nebraska', 'Nebraska Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('NV', stateCompareList);
        System.assert(result == 'Nevada', 'Nevada Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('NH', stateCompareList);
        System.assert(result == 'New Hampshire', 'New Hampshire Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('NJ', stateCompareList);
        System.assert(result == 'New Jersey', 'New Jersey Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('NM', stateCompareList);
        System.assert(result == 'New Mexico', 'New Mexico Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('NY', stateCompareList);
        System.assert(result == 'New York', 'New York Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('NC', stateCompareList);
        System.assert(result == 'North Carolina', 'North Carolina Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('ND', stateCompareList);
        System.assert(result == 'North Dakota', 'North Dakota Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('OH', stateCompareList);
        System.assert(result == 'Ohio', 'Ohio Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('OK', stateCompareList);
        System.assert(result == 'Oklahoma', 'Oklahoma Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('OR', stateCompareList);
        System.assert(result == 'Oregon', 'Oregon Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('PA', stateCompareList);
        System.assert(result == 'Pennsylvania', 'Pennsylvania Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('RI', stateCompareList);
        System.assert(result == 'Rhode Island', 'Rhode Island Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('SC', stateCompareList);
        System.assert(result == 'South Carolina', 'South Carolina Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('SD', stateCompareList);
        System.assert(result == 'South Dakota', 'South Dakota Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('TN', stateCompareList);
        System.assert(result == 'Tennessee', 'Tennessee Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('TX', stateCompareList);
        System.assert(result == 'Texas', 'Texas Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('UT', stateCompareList);
        System.assert(result == 'Utah', 'Utah Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('VT', stateCompareList);
        System.assert(result == 'Vermont', 'Vermont Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('VA', stateCompareList);
        System.assert(result == 'Virginia', 'Virginia Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('WA', stateCompareList);
        System.assert(result == 'Washington', 'Washington Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('WV', stateCompareList);
        System.assert(result == 'West Virginia', 'West Virginia Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('WI', stateCompareList);
        System.assert(result == 'Wisconsin', 'Wisconsin Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('WY', stateCompareList);
        System.assert(result == 'Wyoming', 'Wyoming Test');

        result = Fleet_Util.convertTwoDigitStateToFullName('DC', stateCompareList);
        System.assert(result == 'District of Columbia', 'Districtof Columbia Test');     

        result = Fleet_Util.convertTwoDigitStateToFullName('Arizona', stateCompareList);
        System.assert(result == 'Arizona', 'Arizona fully spelled out Test');   
        
        Test.stopTest();

    }
    
}
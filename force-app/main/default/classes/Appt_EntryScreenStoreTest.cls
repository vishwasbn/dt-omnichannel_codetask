@isTest
public with sharing class Appt_EntryScreenStoreTest {
    @IsTest
    static void createAppt_EntryScreenStoreTest(){
        Map<Id,Boolean> favsMap = new Map<Id,Boolean>();
        favsMap.put('0Hh6C000000XG7LSAW', true);
        
        System.debug('***Start Test***');
        Test.startTest();
        Appt_EntryScreenStore nullObjTest = new Appt_EntryScreenStore();
        Appt_EntryScreenStore createNewStore = new Appt_EntryScreenStore('0Hh6C000000XG7LSAW', 'AZP12', '154', '123 street', 'someplace', 'AZ', '85395-11', favsMap);
        Appt_EntryScreenStore createNewStore2 = new Appt_EntryScreenStore('0Hh6C000000XG7LSAS', 'AZP12', '154', '123 street', 'someplace', 'AZ', '85395-11', favsMap);
        Test.stopTest();
        System.debug('***End Test***');
        System.assertEquals('123 STREET', createNewStore.street, 'check for uppercase');
        System.assertEquals(true, createNewStore.userFavorite, 'check for favorite');
        System.assertEquals(false, createNewStore2.userFavorite, 'check for no favorite');
        System.assert(nullObjTest.id == null, 'check for null constructor');
        
    }
}
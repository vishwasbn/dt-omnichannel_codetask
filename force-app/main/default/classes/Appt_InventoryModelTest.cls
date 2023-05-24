@IsTest
public class Appt_InventoryModelTest {
    
    static testMethod void testParse() {
        String json = getJSON();

        Appt_InventoryModel obj = Appt_InventoryModel.parse(json);
        System.assert(obj != null);
    }

    public static String getJSON()
    {
        String json = '{'+
            '\"site\": ['+
            '    {'+
            '        \"siteId\": \"2132\",'+
            '        \"article\": ['+
            '            {'+
            '                \"articleId\": \"000000000000070951\",'+
            '                \"baseUOM\": \"EA\",'+
            '                \"articleStatus\": \"N\",'+
            '                \"OnHandStockQuantity\": \"0.000\",'+
            '                \"AtpStockQuantity\": \"0.000\",'+
            '                \"TotalReservedStockQuantity\": \"0.000\",'+
            '                \"onOrderIn\": \"0.000\",'+
            '                \"onOrderOut\": \"0.000\",'+
            '                \"inTransit\": \"0.000\",'+
            '                \"LaywayStockQuantity\": \"0.000\",'+
            '                \"WeborderStockQuantity\": \"0.000\",'+
            '                \"onHoldQuantity\": \"0.000\",'+
            '                \"suspend\": 0,'+
            '                \"specialOrderQuantity\": \"0.000\",'+
            '                \"BOPIS\": \"0.000\",'+
            '                \"serviceLaterStock\": \"0.000\"'+
            '            }'+
            '        ]'+
            '    }'+
            ']'+
        '}';

        return json;
    }
}
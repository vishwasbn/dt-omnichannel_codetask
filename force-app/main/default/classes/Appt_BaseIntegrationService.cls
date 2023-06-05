public virtual class Appt_BaseIntegrationService {
        //---Build the Appointment Integration Http Request
        public static HttpRequest buildAppointmentHttpReq(String endUrl) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ApptExperienceAPI' + endUrl);
            req.setMethod('GET');
            req.setHeader('dtSourceSystem', BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_DT_SOURCE_SYSTEM, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT));  
            req.setHeader('dtSourceSubsystem', BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_DT_SOURCE_SUBSYSTEM, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT) );  
    
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
    
            req.setHeader('dtRequestIdentifier', guid);  
            
            return req;
        }
}
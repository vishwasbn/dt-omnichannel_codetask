public class Appt_UpdateAppointmentServiceModel extends Appt_CreateAppointmentServiceModel{
    
    public String cancelReason;
    public String cancelReasonText;
    public String frontApptStatus;

    public static Appt_UpdateAppointmentServiceModel parseUpdateAppointmentRequest(Appt_UpdateAppointmentRequest request) {
        
        String requestString = JSON.serialize(request);
        return (Appt_UpdateAppointmentServiceModel) System.JSON.deserialize(requestString, Appt_UpdateAppointmentServiceModel.class);
        
	}
}
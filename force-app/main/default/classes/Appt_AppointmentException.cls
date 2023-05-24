public class Appt_AppointmentException extends Exception {

    public Integer errorCode;

    public Appt_AppointmentException(String message, Integer errorCode){
        this(message);
        this.errorCode = errorCode;

    }

}
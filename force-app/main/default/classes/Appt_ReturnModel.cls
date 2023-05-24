public virtual class Appt_ReturnModel {

    public String status;
    public String message;
    public String statusCode;

    public void setError(String errorCode, String message) {
        this.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
        this.statusCode = errorCode;
        this.message = message;
        System.debug('Appt_Model ERROR: ['+this.statusCode+'] '+ this.message);
    }

    public Boolean isError() {
        if (!String.isBlank(this.status) && this.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR) return true;
        else return false;
    }
}
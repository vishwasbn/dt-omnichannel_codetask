global class FleetSpecialistWrapper implements Comparable {

    public User usr;

    // Constructor
    public FleetSpecialistWrapper(User arg) {
        usr= arg;
    }

    // Compare user based on the LeadAssignmentPriority__c.
    global Integer compareTo(Object compareTo) {
        // Cast argument to FleetSpecialistWrapper
        FleetSpecialistWrapper compareToOppy = (FleetSpecialistWrapper)compareTo;

        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (usr.LeadAssignmentPriority__c > compareToOppy.usr.LeadAssignmentPriority__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (usr.LeadAssignmentPriority__c < compareToOppy.usr.LeadAssignmentPriority__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }

        return returnValue;       //LeadAssignmentPriority__c
    }
}
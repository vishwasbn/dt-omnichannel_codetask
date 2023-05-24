public class Fleet_Util { 
    // Converts a two digit State to a full state name (accepts a list of meta data to compare against)
    public static String convertTwoDigitStateToFullName(String state, List<Fleet_State_Abbrev__mdt> stateList){
        System.debug('State name to be converted ' + state);
        
        String stateUpper = state.toUpperCase();

        for(Fleet_State_Abbrev__mdt checkAbbreviation: stateList){
            if(checkAbbreviation.State_Abbrev__c.toUpperCase() == stateUpper){
                state = checkAbbreviation.State_Output__c;
                break;
            }
        }

        return state;

    }

}
public with sharing class Appt_EntryScreenStore {
    public String id;
    public String legacyStoreCode;
    public String sapId;
    public String street;
    public String city;
    public String state;
    public String zipCode;
    public Boolean userFavorite;

    // build store constructor
    public Appt_EntryScreenStore(id ServiceTerritoryid, String legacyStoreCode, String sapId, String street, String city, String state, String zipCode, Map<Id,Boolean> favsMap) {
        //System.debug('Start Appt_EntryScreenStore');
        
        this.id = ServiceTerritoryid;
        // Format data
        if(legacyStoreCode!= null){this.legacyStoreCode = legacyStoreCode.toUpperCase();}else{this.legacyStoreCode = '';}
        if(sapId!= null){this.sapId = sapId.toUpperCase();}else{this.sapId = '';}
        if(street!= null){this.street = street.toUpperCase();}else{this.street = '';}
        if(city!= null){this.city = city.toUpperCase();}else{this.city = '';}
        if(state!= null){this.state = state.toUpperCase();}else{this.state = '';}
        if(zipCode!= null){this.zipCode = zipCode.substring(0, 5);}else{this.zipCode = '';}        
        
        // Check for a store favorite to be setup
        if(favsMap.get(ServiceTerritoryid) != null){
            this.userFavorite = true;
        } else {
            this.userFavorite = false;
        }
        //System.debug('End Appt_EntryScreenStore');
    }

    // base constructor
    public Appt_EntryScreenStore() {

    }
}
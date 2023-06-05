public class FleetDiscountImgCntrl {
    public String accName{get;set;}
	public PageReference accountNameBreak(){
        accName = ApexPages.currentPage().getParameters().get('name');
        system.debug('===12>');
        String accNewName = '';
        system.debug('===11>'+accName.length());
        if(accName.length() > 25){
            system.debug('===>'+accName.length());
            Integer intBreaks = accName.length()/25;
            system.debug('===intBreaks>'+intBreaks);
            Integer newVal = 25;
            for(Integer i=0;i<intBreaks;i++){
                if(i==0){
                    accNewName+=accName.substring((newVal+1)*i, (newVal+1)*(i+1))+'\n';
                }else{
                    accNewName+=accName.substring((newVal+1)*i, (newVal+2)*(i+1))+'\n';
                }
                
                system.debug('===accNewName>'+accNewName);
            }
            
            system.debug('===accNewName.length()>'+accNewName.length());
            system.debug('===accName.length()>'+accName.length());
            system.debug('===accNamebefore=>'+accNewName);
            if(math.mod(accName.length(), 25) !=0)
            	accNewName+= accName.substring(accNewName.length()-intBreaks, accName.length());
        
        system.debug('===accNameafter=>'+accNewName);
        accNewName = accNewName.replaceAll('\n','<br />');
        system.debug('===accName=>'+accNewName);
        accNewName = accNewName.removeEnd('<br />');   
        accName = accNewName;
        }
        system.debug('===accName1=>'+accName);
        return null;
    }
}
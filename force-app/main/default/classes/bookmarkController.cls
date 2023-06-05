public class bookmarkController {
    public List <WebLink> weblinks;
    public List<WebLink> getweblinks(){
        weblinks= [SELECT   MasterLabel,name, NamespacePrefix, PageOrSobjectType,Url FROM WebLink where PageOrSobjectType='CustomPageItem'];
        List<weblink> sortedLink= new List<WebLink>();
        for(WebLink weblink: weblinks){
        	if(!weblink.name.contains('Email_to_Case_Premium_Setup_Wizard')){
        		sortedLink.add(weblink);
        	}
        }
        if(sortedLink.size() > 0)
          return sortedLink;
        else return null;
    }
}
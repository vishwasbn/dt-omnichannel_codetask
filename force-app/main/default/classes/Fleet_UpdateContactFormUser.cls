public class Fleet_UpdateContactFormUser implements Queueable
{
    private List<Contact> updateContactList;
    
    public  Fleet_UpdateContactFormUser(List<Contact> updateContactList)
    {
        this.updateContactList = updateContactList;
    }
    
    public void execute(QueueableContext context) 
    {
         if(this.updateContactList.size() >0 )
         {
             update this.updateContactList;
         }            
    }
}
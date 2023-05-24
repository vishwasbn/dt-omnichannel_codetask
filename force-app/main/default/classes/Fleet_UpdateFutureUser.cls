public class Fleet_UpdateFutureUser {
	@future
    public static void updateUser(String userId) {
        Update [SELECT Id FROM User WHERE Id=:userId];
    }
}
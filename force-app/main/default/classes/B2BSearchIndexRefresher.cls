public class B2BSearchIndexRefresher {
    //PRIVATE METHODS
    public static void refreshSearchIndex(){
        String webstoreId = [SELECT Id FROM Webstore WHERE Name = : System.Label.WebshopDoNotTranslateStoreName LIMIT 1].Id;
        ConnectApi.CommerceSearchIndex index = ConnectApi.CommerceSearchSettings.createCommerceSearchIndex(webstoreId);
    }
}
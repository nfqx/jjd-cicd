public class MigrationProductImagesBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    private static Map<String, String> mediaGroupMap = new Map<String, String>{
        'Product Detail Images' => 'Produktdetailbilder',
        'Product List Image' => 'Produktlistenbild',
        'Banner Image' => 'Bannerbild',
        'Tile Image' => 'Kachelbild',
        'Attachments' => 'Anhänge'
    };
    private List<ElectronicMediaObject> emoList = new List<ElectronicMediaObject>();

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id,
                OldProductNumber__c
            FROM Product2
            WHERE OldProductNumber__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Product2> products = (List<Product2>) scope;
        for (Product2 targetProduct : products) {
            try {
                migrateProductImages(targetProduct);
            } catch (Exception e) {
                System.debug(
                    'Image migration failed for ' +
                    targetProduct.Id +
                    ': ' +
                    e.getMessage()
                );
            }
        }    }



    private void migrateProductImages(Product2 targetProduct) {
        String productCode = targetProduct.OldProductNumber__c;
        /*
         * Find source product media
         */
        String soql =
            'SELECT Id,' +
            '       ElectronicMediaId,' +
            '       ElectronicMediaGroup.Name,' +
            '       SortOrder ' +
            'FROM ProductMedia ' +
            'WHERE Product.ProductCode = \'' +
                String.escapeSingleQuotes(productCode) +
            '\'';

        List<Object> sourceMedia = SourceOrgApi.query(soql);

        for (Object row : sourceMedia) {
            Map<String,Object> media = (Map<String,Object>)row;
            String sourceElectronicMediaId = (String)media.get('ElectronicMediaId');
            Map<String, Object> grp = (Map<String,Object>)media.get('ElectronicMediaGroup');
            String sourceElectronicMediaGroupName = grp != null ? (String)grp.get('Name') : null;
            if(sourceElectronicMediaGroupName != null && mediaGroupMap.containsKey(sourceElectronicMediaGroupName)){
                Integer sortOrder =
                    media.get('SortOrder') == null
                        ? null
                        : Integer.valueOf(
                            String.valueOf(
                                media.get('SortOrder')
                            )
                        );

                /*
                * Get image from source org
                */
                SourceImage image = downloadSourceImage(sourceElectronicMediaId);

                /*
                * Create CMS content in target org
                */
                this.emoList.add(new ElectronicMediaObject(targetProduct.Id, null, sortOrder, sourceElectronicMediaGroupName, image));
                
            }
        }
        List<String> managedContentIDs = new List<String>();
        for(ElectronicMediaObject emo : this.emoList){
            emo.managedContentId = uploadManagedContent(emo.sourceImage);
            managedContentIDs.add(emo.managedContentId);
        }        
        ConnectApi.ManagedContentPublishInput publishInput = new ConnectApi.ManagedContentPublishInput();
        publishInput.contentIds = managedContentIDs;
        ConnectApi.ManagedContent.publish(publishInput);
        createProductMedia(this.emoList);
    }




    /*
     * Downloads the actual image bytes
     *
     */
    private static SourceImage downloadSourceImage(String electronicMediaId) {

        String token = SourceOrgAuth.getAccessToken();
        String baseUrl = 'https://darboven--uatnew.sandbox.my.salesforce.com';

        // Metadata request
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(
            baseUrl +
            '/services/data/v61.0/connect/cms/contents/' +
            electronicMediaId
        );
        req.setHeader('Authorization', 'Bearer ' + token);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException(res.getBody());
        }

        Map<String,Object> json = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
        Map<String,Object> contentBody = (Map<String,Object>)json.get('contentBody');
        Map<String,Object> source = (Map<String,Object>)contentBody.get('source');

        String mediaUrl = (String)source.get('url');

        HttpRequest imageReq = new HttpRequest();
        imageReq.setMethod('GET');
        imageReq.setEndpoint(baseUrl + mediaUrl);
        imageReq.setHeader('Authorization', 'Bearer ' + token);
        HttpResponse imageRes = new Http().send(imageReq);
        if (imageRes.getStatusCode() == 301 ||
            imageRes.getStatusCode() == 302) {

            String location = imageRes.getHeader('Location');

            HttpRequest redirectReq = new HttpRequest();
            redirectReq.setMethod('GET');
            redirectReq.setEndpoint(location);
            redirectReq.setHeader('Authorization', 'Bearer ' + token);

            imageRes = new Http().send(redirectReq);
        }

        if (imageRes.getStatusCode() != 200) {
            throw new CalloutException(imageRes.getStatus() + ': ' + imageRes.getBody());
        }

        SourceImage img = new SourceImage();
        img.body = imageRes.getBodyAsBlob();
        img.filename = (String)source.get('filename');
        img.mimeType = (String)source.get('mimeType');

        return img;
    }

    /*
     * Creates CMS Managed Content in destination org
     */
    private static Id uploadManagedContent(SourceImage image) {
        ConnectApi.BinaryInput binary = new ConnectApi.BinaryInput(
            image.body,
            image.mimeType,
            image.filename
        );
        Map<String, String> typel = new Map<String, String>{ 'type' => 'file', 'mimeType' => image.mimeType};

        Map<String, Object> sourcel = new Map<String, Object>{
            'source' => typel
        };
        Map<String, Object> bodyMap = new Map<String, Object>{
            'sfdc_cms:media' => sourcel
        };

        ConnectApi.ManagedContentBodyInput contentBody = new ConnectApi.ManagedContentBodyInput();
        contentBody.nodeMap = bodyMap;
        ConnectApi.ManagedContentDocumentInput input = new ConnectApi.ManagedContentDocumentInput();
        input.title = image.filename;
        input.contentBody = contentBody;
        input.contentType ='sfdc_cms__image';
        input.contentSpaceOrFolderId = '9Pu9O000000SfrmSAC';
        try {
            ConnectApi.ManagedContentDocument result = ConnectApi.ManagedContent.createManagedContentWithMedia(input, binary);
            return result.managedContentId;
        } catch (ConnectApi.NotFoundException e) {
            System.debug('TYPE: ' + e.getTypeName());
            System.debug('MESSAGE: ' + e.getMessage());
            System.debug('STACK: ' + e.getStackTraceString());
            throw e;
        }
    }

    private static void createProductMedia(
        List<ElectronicMediaObject> emoList
    ) {
        List<ProductMedia> pmList = new List<ProductMedia>();
        for(ElectronicMediaObject emo : emoList){
            System.debug(emo.sourceImage.body);
            if(mediaGroupMap.containsKey(emo.sourceElectronicMediaGroupName)){
                String mediaGroupName = mediaGroupMap.get(emo.sourceElectronicMediaGroupName);
                ElectronicMediaGroup emg = [SELECT Id FROM ElectronicMediaGroup WHERE Name = : mediaGroupName];
                ProductMedia pm = new ProductMedia();
                pm.ProductId = emo.productId;
                pm.SortOrder = emo.sortOrder;
                pm.ElectronicMediaId = emo.managedContentId;
                pm.ElectronicMediaGroupId = emg.Id;
                pmList.add(pm);
            }
        }
        Database.insert(pmList, false);
    }




    public void finish(Database.BatchableContext bc) {
    }

    public class SourceImage {
        public Blob body;
        public String filename;
        public String mimeType;
    }

    public class ElectronicMediaObject {
        public Id productId {get; set;}
        public Id managedContentId {get; set;}
        public Integer sortOrder {get; set;}
        public String sourceElectronicMediaGroupName {get; set;}
        public SourceImage sourceImage {get; set;}
        public ElectronicMediaObject(Id productId, Id managedContentId, Integer sortOrder, String sourceElectronicMediaGroupName, SourceImage sourceImage){
            this.productId = productId;
            this.managedContentId = managedContentId;
            this.sortOrder = sortOrder;
            this.sourceElectronicMediaGroupName = sourceElectronicMediaGroupName;
            this.sourceImage = sourceImage;
        }
    }

    
}
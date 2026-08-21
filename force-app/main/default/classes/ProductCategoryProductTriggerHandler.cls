public without sharing class ProductCategoryProductTriggerHandler {
    public static void populateUniqueKey(List<ProductCategoryProduct> newRecords){
        for(ProductCategoryProduct rec : newRecords){
            if(rec.ProductId != null && rec.ProductCategoryId != null){
                rec.UniqueKey__c =
                    String.valueOf(rec.ProductId) + '|' +
                    String.valueOf(rec.ProductCategoryId);
            }
        }
    }
    public static void addHierarchyRecords(List<ProductCategoryProduct> newRecords){
        List<String> allCategoryIds = CollectionUtils.generateStringListFromSObjectList(newRecords, 'ProductCategoryId', true, true);
        Map<Id, ProductCategory> categoryWithParents = new Map<Id, ProductCategory>([SELECT Id, ParentCategoryId, ParentCategory.ParentCategoryId, ParentCategory.ParentCategory.ParentCategoryId, ParentCategory.ParentCategory.ParentCategory.ParentCategoryId FROM ProductCategory WHERE Id IN : allCategoryIds]);
        List<ProductCategoryProduct> recordsToInsert = new List<ProductCategoryProduct>();
        for(ProductCategoryProduct pcp : newRecords){
            if(categoryWithParents.containsKey(pcp.ProductCategoryId)){
                ProductCategory pc = categoryWithParents.get(pcp.ProductCategoryId);
                if(pc.ParentCategoryId != null){
                    recordsToInsert.add( new ProductCategoryProduct(
                        ProductCategoryId = pc.ParentCategoryId,
                        ProductId = pcp.ProductId
                    ));
                }
                if(pc.ParentCategory.ParentCategoryId != null){
                    recordsToInsert.add( new ProductCategoryProduct(
                        ProductCategoryId = pc.ParentCategory.ParentCategoryId,
                        ProductId = pcp.ProductId
                    ));
                }
                if(pc.ParentCategory.ParentCategory.ParentCategoryId != null){
                    recordsToInsert.add( new ProductCategoryProduct(
                        ProductCategoryId = pc.ParentCategory.ParentCategory.ParentCategoryId,
                        ProductId = pcp.ProductId
                    ));
                }
                if(pc.ParentCategory.ParentCategory.ParentCategory.ParentCategoryId != null){
                    recordsToInsert.add( new ProductCategoryProduct(
                        ProductCategoryId = pc.ParentCategory.ParentCategory.ParentCategory.ParentCategoryId,
                        ProductId = pcp.ProductId
                    ));
                }
            }
        }

        if(!recordsToInsert.isEmpty()){
            Database.insert(recordsToInsert, false);
        }
    }
}
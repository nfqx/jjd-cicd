public with sharing class ChainRightsPassController {
    @TestVisible private static final Integer MAX_HIGHEST_LEVEL = 30;
    @TestVisible private static final Map<String, RightsPassCategoryDefault__mdt> METADATA_MAP = RightsPassCategoryDefault__mdt.getAll();
    @TestVisible private static final Set<String> ACCOUNT_FIELDS = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
    @TestVisible private static final Set<String> ACCOUNT_SELECT_FIELDS = new Set<String>{'Id', 'Name', 'ConditionChainHead__c', 'ConditionChainParent__c', 'Status__c', 'AccountCategory__c'};
    @TestVisible private static final Map<String, Map<String, String>> RIGHT_FIELD_MAPPING = new Map<String, Map<String, String>>{
        'listing' => new Map<String, String>{
            'own' => 'OwnListingRightState__c',
            'inherited' => 'InhListingRightState__c',
            'cappedBy' => 'ListingRightCappedBy__c',
            'authority' => 'ListingRightAuthority__c'
        },
        'condition' =>new Map<String, String>{
            'own' => 'OwnConditionRightState__c',
            'inherited' => 'InhConditionRightState__c',
            'cappedBy' => 'ConditionRightCappedBy__c',
            'authority' => 'ConditionRightAuthority__c'
        },
        'rebate' => new Map<String, String>{
            'own' => 'OwnRebateRightState__c',
            'inherited' => 'InhRebateRightState__c',
            'cappedBy' => 'RebateRightCappedBy__c',
            'authority' => 'RebateRightAuthority__c'
        },
        'wkz' => new Map<String, String>{
            'own' => 'OwnAdvertisingSubsidyRightState__c',
            'inherited' => 'InhAdvertisingSubsidyRightState__c',
            'cappedBy' => 'AdvertisingSubsidyRightCappedBy__c',
            'authority' => 'AdvertisingSubsidyRightAuthority__c'
        },
        'index' => new Map<String, String>{
            'own' => 'OwnIndexationRightState__c',
            'inherited' => 'InhIndexationRightState__c',
            'cappedBy' => 'IndexationRightCappedBy__c',
            'authority' => 'IndexationRightAuthority__c'
        },
        'sampling' => new Map<String, String>{
            'own' => 'OwnSamplingRightState__c',
            'inherited' => 'InhSamplingRightState__c',
            'cappedBy' => 'SamplingRightCappedBy__c',
            'authority' => 'SamplingRightAuthority__c'
        }
    };

    @AuraEnabled(cacheable=true)
    public static String saveChanges(Map<String, Map<String, String>> ownChanges, Map<String, Map<String, String>> inheritedChanges, Map<String, Map<String, String>> inheritedBy){
        try {
            Map<Id, Account> accountMap = new Map<Id, Account>();
            for(String accountId : ownChanges.keySet()){
                Account ac = accountMap.containsKey(accountId) ? accountMap.get(accountId) : new Account(Id = accountId);
                Boolean hasResult = false;
                for(String rightsKey : ownChanges.get(accountId).keySet()){
                    if(RIGHT_FIELD_MAPPING.containsKey(rightsKey) && ACCOUNT_FIELDS.contains(RIGHT_FIELD_MAPPING.get(rightsKey).get('own').toLowerCase())){
                        ac.put(RIGHT_FIELD_MAPPING.get(rightsKey).get('own'), ownChanges.get(accountId).get(rightsKey));
                        hasResult = true;
                    }
                }
                if(hasResult){
                    accountMap.put(accountId, ac);
                }
            }
            for(String accountId : inheritedChanges.keySet()){
                Account ac = accountMap.containsKey(accountId) ? accountMap.get(accountId) : new Account(Id = accountId);
                Boolean hasResult = false;
                for(String rightsKey : inheritedChanges.get(accountId).keySet()){
                    if(RIGHT_FIELD_MAPPING.containsKey(rightsKey) && ACCOUNT_FIELDS.contains(RIGHT_FIELD_MAPPING.get(rightsKey).get('inherited').toLowerCase())){
                        ac.put(RIGHT_FIELD_MAPPING.get(rightsKey).get('inherited'), inheritedChanges.get(accountId).get(rightsKey));
                        hasResult = true;
                    }
                }
                if(hasResult){
                    accountMap.put(accountId, ac);
                }
            }
            for(String accountId : inheritedBy.keySet()){
                Account ac = accountMap.containsKey(accountId) ? accountMap.get(accountId) : new Account(Id = accountId);
                Boolean hasResult = false;
                for(String rightsKey : inheritedBy.get(accountId).keySet()){
                    if(RIGHT_FIELD_MAPPING.containsKey(rightsKey) && ACCOUNT_FIELDS.contains(RIGHT_FIELD_MAPPING.get(rightsKey).get('cappedBy').toLowerCase())){
                        ac.put(RIGHT_FIELD_MAPPING.get(rightsKey).get('cappedBy'), inheritedBy.get(accountId).get(rightsKey));
                        hasResult = true;
                    }
                }
                if(hasResult){
                    accountMap.put(accountId, ac);
                }
            }
            update accountMap.values();
            return 'success';
        } catch(Exception e){
            return e.getMessage();
        }
    }

    @AuraEnabled(cacheable=true)
    public static ItemHolder retrieveData(Id accountId, Boolean onlyActive){
        Set<String> expansionTree = new Set<String>{};
        Set<String> selectFields = ACCOUNT_SELECT_FIELDS;
        for(String rightMapKey : RIGHT_FIELD_MAPPING.keySet()){
            selectFields.addAll(RIGHT_FIELD_MAPPING.get(rightMapKey).values());
        }
        Account currentAcc = Database.query('SELECT ' + String.join(selectFields, ',') + ' FROM Account WHERE Id = : accountId');
        Id headId = currentAcc.ConditionChainHead__c == null ? accountId : currentAcc.ConditionChainHead__c;
        Account headAcc = Database.query('SELECT ' + String.join(selectFields, ',') + ' FROM Account WHERE Id = : headId');
        Set<Id> lowestAccIds = new Set<Id>{headId};


        // Prep Chain
        Integer highestLevel = 1;
        Map<Integer, Map<Id, Set<Id>>> parentToImmediateChildrenMap = new Map<Integer, Map<Id, Set<Id>>>();
        Map<Id, Item> accIdToItemMap = new Map<Id, Item>{headId => new Item(headAcc, accountId, true)};
        Set<Id> allAccountsSoFar = lowestAccIds;
        List<Item> topAccIdToItemList = new List<Item>();

        List<Account> nextLevelChildren = Database.query('SELECT ' + String.join(selectFields, ',') + ' FROM Account WHERE ConditionChainHead__c = : headId AND ConditionChainParent__c IN : lowestAccIds');
        while(!nextLevelChildren.isEmpty() && highestLevel < MAX_HIGHEST_LEVEL){
            highestLevel++;
            lowestAccIds = new Set<Id>();
            Map<Id, Set<Id>> innerMap = new Map<Id, Set<Id>>();
            for(Account acc : nextLevelChildren){
                accIdToItemMap.put(acc.Id, new Item(acc, accountId, false));
                Set<Id> childSet = innerMap.containsKey(acc.ConditionChainParent__c) ? innerMap.get(acc.ConditionChainParent__c) : new Set<Id>();
                childSet.add(acc.Id);
                innerMap.put(acc.ConditionChainParent__c, childSet);
                lowestAccIds.add(acc.id);
            }
            parentToImmediateChildrenMap.put(highestLevel, innerMap);
            Set<Id> accIdToItemMapKeys = accIdToItemMap.keySet();
            nextLevelChildren = Database.query('SELECT ' + String.join(selectFields, ',') + ' FROM Account WHERE ConditionChainHead__c = : headId AND ConditionChainParent__c IN : lowestAccIds AND Id NOT IN : accIdToItemMapKeys');
        }

        Id idToExpand = accountId;
        if(highestLevel > 1){
            for(Integer i = highestLevel; i > 1; i--){
                if(parentToImmediateChildrenMap.containsKey(i)){
                    for(Id parentId : parentToImmediateChildrenMap.get(i).keySet()){
                        Item parentItem = accIdToItemMap.get(parentId);
                        for(Id childId : parentToImmediateChildrenMap.get(i).get(parentId)){
                            if(accIdToItemMap.containsKey(childId)){
                                Item childItem = accIdToItemMap.get(childId);
                                Boolean toExpand = childId == idToExpand;
                                if(childItem.active || !onlyActive || toExpand){
                                    parentItem.childItems.add(childItem);
                                    if(toExpand){
                                        expansionTree.add(parentId);
                                        idToExpand = parentId;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


        return new ItemHolder(new List<Item>{accIdToItemMap.get(headId)}, expansionTree);
    }
    /**
     * Wrapper Classes
     */
    public class ItemHolder {
        @AuraEnabled public List<Item> items { get; set; }
        @AuraEnabled public Set<String> expansionTree { get; set; }
        public ItemHolder(List<Item> items, Set<string> expansionTree) {
            this.expansionTree = expansionTree;
            this.items = items;
        }
    }
    public class Right {
        @AuraEnabled public Boolean granted { get; set; }
        @AuraEnabled public Boolean endshere { get; set; }
        @AuraEnabled public Boolean removed { get; set; }
        @AuraEnabled public Boolean lockedbychain { get; set; }
        @AuraEnabled public Boolean notallowed { get; set; }
        @AuraEnabled public Boolean inheritedbyparent { get; set; }
        @AuraEnabled public Boolean clickable { get; set; }
        @AuraEnabled public Boolean ischanged { get; set; }

        public Right(Boolean granted){
            this.granted = granted;
            this.endshere = false;
            this.removed = false;
            this.lockedbychain = false;
            this.notallowed = false;
            this.inheritedbyparent = false;
            this.clickable = granted;
            this.ischanged = false;
        }
        public Right(){
            this.granted = false;
            this.endshere = false;
            this.removed = false;
            this.lockedbychain = false;
            this.notallowed = false;
            this.inheritedbyparent = false;
            this.clickable = false;
            this.ischanged = false;
        }
    }
    public class OriginalData {
        @AuraEnabled public Right listing { get; set; }
        @AuraEnabled public Right condition { get; set; }
        @AuraEnabled public Right rebate { get; set; }
        @AuraEnabled public Right wkz { get; set; }
        @AuraEnabled public Right index { get; set; }
        @AuraEnabled public Right sampling { get; set; }
        public OriginalData(Right listing, Right condition, Right rebate, Right wkz, Right index, Right sampling){
            this.listing = listing;
            this.condition = condition;
            this.rebate = rebate;
            this.wkz = wkz;
            this.index = index;
            this.sampling = sampling;
        }
    }
    public class Item {
        @AuraEnabled public String href { get; set; }
        @AuraEnabled public Right listing { get; set; }
        @AuraEnabled public Right condition { get; set; }
        @AuraEnabled public Right rebate { get; set; }
        @AuraEnabled public Right wkz { get; set; }
        @AuraEnabled public Right index { get; set; }
        @AuraEnabled public Right sampling { get; set; }
        @AuraEnabled public String accountname { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public Boolean active { get; set; }
        @AuraEnabled public Boolean head { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public List<Item> childItems { get; set; }
        @AuraEnabled public OriginalData originaldata { get; set; }

        public Item(Account account, Id originalAccountId, Boolean head) {
            this.href = URL.getSalesforceBaseUrl().toExternalForm() + '/' + account.Id;
            this.head = head;
            this.id = account.Id;
            this.accountname = account.Name;
            this.description = (account.Id == originalAccountId) ? 'background-color:#C9C9C9;' : '';
            this.active = account.Status__c != 'Inactive';
            this.childItems = new List<Item>();
            this.listing = new Right(true);
            this.condition = new Right(true);
            this.rebate = new Right(true);
            this.wkz = new Right(true);
            this.index = new Right(true);
            this.sampling = new Right(true);
            // Rights Processing
            this.originaldata = new OriginalData(this.listing, this.condition, this.rebate, this.wkz, this.index, this.sampling);
        }
    }
}
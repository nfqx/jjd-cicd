public with sharing class ChainRightsPassController {
    @TestVisible private static final Integer MAX_HIGHEST_LEVEL = 30;
    @TestVisible private static final Map<String, RightsPassCategoryDefault__mdt> METADATA_MAP = RightsPassCategoryDefault__mdt.getAll();
    @TestVisible private static final Set<String> ACCOUNT_CONDITION_FIELDS = Schema.getGlobalDescribe().get('AccountConditions__c').getDescribe().fields.getMap().keySet();
    @TestVisible private static final Set<String> ACCOUNT_SELECT_FIELDS = new Set<String>{'Id', 'Name', 'OwnerId', 'ConditionChainHead__c', 'ConditionChainParent__c', 'Status__c', 'AccountCategory__c'};
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

    @AuraEnabled(cacheable=false)
    public static String saveChanges(Map<String, Map<String, String>> ownChanges, Map<String, Map<String, String>> inheritedChanges, Map<String, Map<String, String>> inheritedBy){
        try {
            Map<Id, Account> accountMap = new Map<Id, Account>();
            Map<Id, AccountConditions__c> accountConditionsUpdateMap = new Map<Id, AccountConditions__c>();
            for(String accountId : ownChanges.keySet()){
                accountMap.put(accountId, null);
            }
            for(String accountId : inheritedChanges.keySet()){
                accountMap.put(accountId, null);
            }
            for(String accountId : inheritedBy.keySet()){
                accountMap.put(accountId, null);
            }
            Set<String> selectFields = new Set<String>();
            for(String rightMapKey : RIGHT_FIELD_MAPPING.keySet()){
                selectFields.addAll(RIGHT_FIELD_MAPPING.get(rightMapKey).values());
            }
            Set<Id> allAccIds = accountMap.keySet();
            Map<Id, AccountConditions__c> accountConditionMap = new Map<Id, AccountConditions__c>();
            String accountConditionQuery = 'SELECT Id, ApplicableAccount__c, ' + String.join(selectFields, ',') + ' FROM AccountConditions__c WHERE ApplicableAccount__c IN : allAccIds AND Active__c = TRUE ORDER BY ValidFrom__c';
            for(AccountConditions__c ac : Database.query(accountConditionQuery)){
                accountConditionMap.put(ac.ApplicableAccount__c, ac);
            }
            
            for(String accountId : ownChanges.keySet()){
                AccountConditions__c baseCondition = accountConditionMap.containsKey(accountId) ? accountConditionMap.get(accountId) : new AccountConditions__c(
                    ApplicableAccount__c = accountId,
                    Active__c = TRUE,
                    ValidFrom__c = Date.today()
                );
                AccountConditions__c ac = accountConditionsUpdateMap.containsKey(accountId) ? accountConditionsUpdateMap.get(accountId) : baseCondition;
                Boolean hasResult = false;
                for(String rightsKey : ownChanges.get(accountId).keySet()){
                    if(RIGHT_FIELD_MAPPING.containsKey(rightsKey) && ACCOUNT_CONDITION_FIELDS.contains(RIGHT_FIELD_MAPPING.get(rightsKey).get('own').toLowerCase())){
                        ac.put(RIGHT_FIELD_MAPPING.get(rightsKey).get('own'), ownChanges.get(accountId).get(rightsKey));
                        hasResult = true;
                    }
                }
                if(hasResult){
                    accountConditionsUpdateMap.put(accountId, ac);
                }
            }
            for(String accountId : inheritedChanges.keySet()){
                AccountConditions__c baseCondition = accountConditionMap.containsKey(accountId) ? accountConditionMap.get(accountId) : new AccountConditions__c(
                    ApplicableAccount__c = accountId,
                    Active__c = TRUE,
                    ValidFrom__c = Date.today()
                );
                AccountConditions__c ac = accountConditionsUpdateMap.containsKey(accountId) ? accountConditionsUpdateMap.get(accountId) : baseCondition;
                Boolean hasResult = false;
                for(String rightsKey : inheritedChanges.get(accountId).keySet()){
                    if(RIGHT_FIELD_MAPPING.containsKey(rightsKey) && ACCOUNT_CONDITION_FIELDS.contains(RIGHT_FIELD_MAPPING.get(rightsKey).get('inherited').toLowerCase())){
                        ac.put(RIGHT_FIELD_MAPPING.get(rightsKey).get('inherited'), inheritedChanges.get(accountId).get(rightsKey));
                        hasResult = true;
                    }
                }
                if(hasResult){
                    accountConditionsUpdateMap.put(accountId, ac);
                }
            }
            for(String accountId : inheritedBy.keySet()){
                AccountConditions__c baseCondition = accountConditionMap.containsKey(accountId) ? accountConditionMap.get(accountId) : new AccountConditions__c(
                    ApplicableAccount__c = accountId,
                    Active__c = TRUE,
                    ValidFrom__c = Date.today()
                );
                AccountConditions__c ac = accountConditionsUpdateMap.containsKey(accountId) ? accountConditionsUpdateMap.get(accountId) : baseCondition;
                Boolean hasResult = false;
                for(String rightsKey : inheritedBy.get(accountId).keySet()){
                    if(RIGHT_FIELD_MAPPING.containsKey(rightsKey) && ACCOUNT_CONDITION_FIELDS.contains(RIGHT_FIELD_MAPPING.get(rightsKey).get('cappedBy').toLowerCase())){
                        ac.put(RIGHT_FIELD_MAPPING.get(rightsKey).get('cappedBy'), inheritedBy.get(accountId).get(rightsKey) == 'none' ? null : inheritedBy.get(accountId).get(rightsKey));
                        hasResult = true;
                    }
                }
                if(hasResult){
                    accountConditionsUpdateMap.put(accountId, ac);
                }
            }
            upsert accountConditionsUpdateMap.values();
            return 'success';
        } catch(Exception e){
            return e.getMessage();
        }
    }

    @AuraEnabled(cacheable=true)
    public static ItemHolder retrieveData(Id accountId, Boolean includingInternalDepartments, Boolean onlyActive, Long timestamp){
        Boolean hasInactive = false;
        Boolean hasInternalDepartments = false;
        Set<String> expansionTree = new Set<String>{};
        Set<String> selectFields = new Set<String>();
        for(String rightMapKey : RIGHT_FIELD_MAPPING.keySet()){
            selectFields.addAll(RIGHT_FIELD_MAPPING.get(rightMapKey).values());
        }
        Account currentAcc = Database.query('SELECT ' + String.join(ACCOUNT_SELECT_FIELDS, ',') + ' FROM Account WHERE Id = : accountId');
        Id headId = currentAcc.ConditionChainHead__c == null ? accountId : currentAcc.ConditionChainHead__c;
        Account headAcc = Database.query('SELECT ' + String.join(ACCOUNT_SELECT_FIELDS, ',') + ' FROM Account WHERE Id = : headId');
        Set<Id> lowestAccIds = new Set<Id>{headId};


        // Prep Chain
        Integer highestLevel = 1;
        Map<Integer, Map<Id, Set<Id>>> parentToImmediateChildrenMap = new Map<Integer, Map<Id, Set<Id>>>();
        Map<Id, Item> accIdToItemMap = new Map<Id, Item>{headId => new Item(headAcc, accountId, true)};
        Set<Id> allAccountsSoFar = lowestAccIds;
        List<Item> topAccIdToItemList = new List<Item>();

        List<Account> nextLevelChildren = Database.query('SELECT ' + String.join(ACCOUNT_SELECT_FIELDS, ',') + ' FROM Account WHERE ConditionChainHead__c = : headId AND ConditionChainParent__c IN : lowestAccIds');
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
                if(!hasInactive && acc.Status__c == 'Inactive'){
                    hasInactive = true;
                }
                if(!hasInternalDepartments && acc.AccountCategory__c == AccountCategoryClassifier.CAT_DEPARTMENT){
                    hasInternalDepartments = true;
                }
            }
            parentToImmediateChildrenMap.put(highestLevel, innerMap);
            Set<Id> accIdToItemMapKeys = accIdToItemMap.keySet();
            nextLevelChildren = Database.query('SELECT ' + String.join(ACCOUNT_SELECT_FIELDS, ',') + ' FROM Account WHERE ConditionChainHead__c = : headId AND ConditionChainParent__c IN : lowestAccIds AND Id NOT IN : accIdToItemMapKeys');
        }

        Set<Id> allAccIds = accIdToItemMap.keySet();
        Map<Id, AccountConditions__c> accountConditionMap = new Map<Id, AccountConditions__c>();
        String accountConditionQuery = 'SELECT Id, ApplicableAccount__c, ' + String.join(selectFields, ',') + ' FROM AccountConditions__c WHERE ApplicableAccount__c IN : allAccIds AND Active__c = TRUE ORDER BY ValidFrom__c';
        for(AccountConditions__c ac : Database.query(accountConditionQuery)){
            accountConditionMap.put(ac.ApplicableAccount__c, ac);
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
                                childItem.processRights(accountConditionMap.get(childId));
                                Boolean toExpand = childId == idToExpand;
                                if(((childItem.active || !onlyActive) && (!childItem.isDepartment || includingInternalDepartments)) || toExpand){
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

        accIdToItemMap.get(headId).processRights(accountConditionMap.get(headId));
        if(!FeatureManagement.checkPermission('ConditionChainOverrideOwnership')){
            accIdToItemMap.get(headId).inheritOwner();
        }
        return new ItemHolder(new List<Item>{accIdToItemMap.get(headId)}, expansionTree, hasInactive, hasInternalDepartments);
    }
    /**
     * Wrapper Classes
     */
    public class ItemHolder {
        @AuraEnabled public List<Item> items { get; set; }
        @AuraEnabled public Boolean hasInactive { get; set; }
        @AuraEnabled public Boolean hasInternalDepartments { get; set; }
        @AuraEnabled public Set<String> expansionTree { get; set; }
        public ItemHolder(List<Item> items, Set<string> expansionTree, Boolean hasInactive, Boolean hasInternalDepartments) {
            this.expansionTree = expansionTree;
            this.items = items;
            this.hasInactive = hasInactive;
            this.hasInternalDepartments = hasInternalDepartments;
        }
    }
    public class RightsBracket {
        @AuraEnabled public Right listing { get; set; }
        @AuraEnabled public Right condition { get; set; }
        @AuraEnabled public Right rebate { get; set; }
        @AuraEnabled public Right wkz { get; set; }
        @AuraEnabled public Right index { get; set; }
        @AuraEnabled public Right sampling { get; set; }
        public RightsBracket(){}
            
        public RightsBracket(Right listing, Right condition, Right rebate, Right wkz, Right index, Right sampling){
            this.listing = listing;
            this.condition = condition;
            this.rebate = rebate;
            this.wkz = wkz;
            this.index = index;
            this.sampling = sampling;
        }
    }
    public class Right {
        @AuraEnabled public Boolean granted { get; set; }
        @AuraEnabled public Boolean endshere { get; set; }
        @AuraEnabled public Boolean removed { get; set; }
        @AuraEnabled public Boolean lockedbychain { get; set; }
        @AuraEnabled public Boolean notallowed { get; set; }
        @AuraEnabled public Boolean ischanged { get; set; }

        public Right(String categoryMod, String type, String currentRight){
            RightsPassCategoryDefault__mdt typeMetadata = METADATA_MAP.get(categoryMod + '_' + type);
            if(typeMetadata != null && typeMetadata.Mode__c == 'forbidden'){
                this.granted = false;
                this.endshere = false;
                this.removed = false;
                this.lockedbychain = false;
                this.notallowed = true;
            } else {
                this.granted = currentRight != 'AgreedAccountOnly' && currentRight != 'Locked' && currentRight != 'CappedByChain' && currentRight != 'NotPermitted';
                this.endshere = currentRight == 'AgreedAccountOnly';
                this.removed = currentRight == 'Locked';
                this.lockedbychain = currentRight == 'CappedByChain';
                this.notallowed = false;
            }
            this.ischanged = false;
        }
        public Right(){
            this.granted = true;
            this.endshere = false;
            this.removed = false;
            this.lockedbychain = false;
            this.notallowed = false;
            this.ischanged = false;
        }
    }
    public class Item {
        @AuraEnabled public String href { get; set; }
        @AuraEnabled public String accountname { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String style { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public Boolean active { get; set; }
        @AuraEnabled public Boolean head { get; set; }
        @AuraEnabled public Boolean isDepartment { get; set; }
        @AuraEnabled public Boolean isOwner { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public List<Item> childItems { get; set; }
        @AuraEnabled public RightsBracket inheritedDataOriginal { get; set; }
        @AuraEnabled public RightsBracket inheritedDataCurrent { get; set; }
        @AuraEnabled public RightsBracket selfDataOriginal { get; set; }
        @AuraEnabled public RightsBracket selfDataCurrent { get; set; }

        public void processRights(AccountConditions__c cond){
            String categoryMod = String.isNotBlank(this.category) ? this.category.replaceAll(' ', '') : '';
            if(cond != null){
                this.selfDataOriginal = new RightsBracket(
                    new Right(categoryMod, 'listing', (String) cond.get(RIGHT_FIELD_MAPPING.get('listing').get('own'))),
                    new Right(categoryMod, 'condition', (String) cond.get(RIGHT_FIELD_MAPPING.get('condition').get('own'))),
                    new Right(categoryMod, 'rebate', (String) cond.get(RIGHT_FIELD_MAPPING.get('rebate').get('own'))),
                    new Right(categoryMod, 'wkz', (String) cond.get(RIGHT_FIELD_MAPPING.get('wkz').get('own'))),
                    new Right(categoryMod, 'index', (String) cond.get(RIGHT_FIELD_MAPPING.get('index').get('own'))),
                    new Right(categoryMod, 'sampling', (String) cond.get(RIGHT_FIELD_MAPPING.get('sampling').get('own')))
                );
                this.selfDataCurrent = this.selfDataOriginal;
                if(this.head){
                    this.inheritedDataOriginal = null;
                    this.inheritedDataCurrent = null;
                } else {
                    this.inheritedDataOriginal = new RightsBracket(
                        new Right(categoryMod, 'listing', (String) cond.get(RIGHT_FIELD_MAPPING.get('listing').get('inherited'))),
                        new Right(categoryMod, 'condition', (String) cond.get(RIGHT_FIELD_MAPPING.get('condition').get('inherited'))),
                        new Right(categoryMod, 'rebate', (String) cond.get(RIGHT_FIELD_MAPPING.get('rebate').get('inherited'))),
                        new Right(categoryMod, 'wkz', (String) cond.get(RIGHT_FIELD_MAPPING.get('wkz').get('inherited'))),
                        new Right(categoryMod, 'index', (String) cond.get(RIGHT_FIELD_MAPPING.get('index').get('inherited'))),
                        new Right(categoryMod, 'sampling', (String) cond.get(RIGHT_FIELD_MAPPING.get('sampling').get('inherited')))
                    );
                    this.inheritedDataCurrent = this.inheritedDataOriginal;
                }
            }
        }

        public void inheritOwner(){
            if(this.isOwner){
                for(Item item : this.childItems){
                    item.isOwner = true;
                    item.inheritOwner();
                }
            }
        }

        public Item(Account account, Id originalAccountId, Boolean head) {
            this.href = URL.getSalesforceBaseUrl().toExternalForm() + '/' + account.Id;
            this.head = head;
            this.id = account.Id;
            this.accountname = account.Name;
            this.category = account.AccountCategory__c;
            // Defines the shape and size of the badge
            String baseBadgeStyle = 'padding: 0.15rem 0.5rem; border-radius: 0.25rem; font-weight: 700; font-size: 0.75rem; margin-left: 0.5rem; ';
            // Maps the picklist values to their specific background and text colors
            switch on this.category {
                when 'Central Regulator' {
                    this.style = baseBadgeStyle + 'background-color: #fef1e8; color: #c25400;';
                }
                when 'Association Member' {
                    this.style = baseBadgeStyle + 'background-color: #eef4ff; color: #005fb2;';
                }
                when 'Direct Customer' {
                    this.style = baseBadgeStyle + 'background-color: #ebf7e6; color: #1e5a34;';
                }
                when 'Department' {
                    this.style = baseBadgeStyle + 'background-color: #f3f3f3; color: #3e3e3c;';
                }
                when 'Unclassified' {
                    this.style = baseBadgeStyle + 'background-color: #ffffff; color: #706e6b; border: 1px dashed #dcdcdc;';
                }
                when else {
                    this.style = String.isBlank(this.category) ? '' : baseBadgeStyle + 'background-color: #f3f3f3; color: #3e3e3c;';
                }
            }
            this.description = (account.Id == originalAccountId) ? 'background-color:#EAEAEA;' : '';
            this.active = account.Status__c != 'Inactive';
            this.isDepartment = account.AccountCategory__c == AccountCategoryClassifier.CAT_DEPARTMENT;
            this.childItems = new List<Item>();
            this.inheritedDataOriginal = new RightsBracket(new Right(), new Right(), new Right(), new Right(), new Right(), new Right());
            this.inheritedDataCurrent = this.inheritedDataOriginal;
            this.selfDataOriginal = new RightsBracket(new Right(), new Right(), new Right(), new Right(), new Right(), new Right());
            this.selfDataCurrent = this.selfDataOriginal;
            this.isOwner = FeatureManagement.checkPermission('ConditionChainOverrideOwnership') || account.OwnerId == UserInfo.getUserId();
        }
    }
}
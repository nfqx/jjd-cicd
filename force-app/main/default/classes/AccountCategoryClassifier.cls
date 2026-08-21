public with sharing class AccountCategoryClassifier {
    public static final String CONST_MANUAL = 'Manual';
    public static final String CONST_AUTOMATIC = 'Automatic';
    public static final String CONST_NO_OWN_LEGAL_FORM = 'No legal entity status';

    public static final String FLAG_NO_EVIDENCE = 'FLAG_NO_EVIDENCE';
    public static final String FLAG_NO_CHAIN_FOREIGN_BILLED = 'NO_CHAIN_FOREIGN_BILLED';   
    public static final String FLAG_LEGALFORM_MISSING = 'LEGALFORM_MISSING';   
    public static final String FLAG_BILLING_UNKNOWN = 'BILLING_UNKNOWN';  
     

    public static final String CAT_CENTRAL_REGULATOR = 'Central Regulator';
    public static final String CAT_DIRECT_CUSTOMER = 'Direct Customer';
    public static final String CAT_ASSOCIATION_MEMBER = 'Association Member';
    public static final String CAT_DEPARTMENT = 'Department';
    public static final String CAT_UNCLASSIFIED = 'Unclassified';

    public static final String REGULATOR_ALL = 'Main';
    public static final String REGULATOR_SUB = 'Sub';


    public static List<Account> classify(List<Account> inputAccts){
        Set<Id> accountsAsCentralRegulators = new Set<Id>();
        Set<Id> accountsAsChainParents = new Set<Id>();
        Set<Id> accountsAsChainHeads = new Set<Id>();

        for(AggregateResult ar : [SELECT CentralRegulator__c FROM Account WHERE CentralRegulator__c IN : inputAccts GROUP BY CentralRegulator__c]){
            accountsAsCentralRegulators.add((Id) ar.get('CentralRegulator__c'));
        }
        for(AggregateResult ar : [SELECT ConditionChainParent__c FROM Account WHERE ConditionChainParent__c IN : inputAccts GROUP BY ConditionChainParent__c]){
            accountsAsChainParents.add((Id) ar.get('ConditionChainParent__c'));
        }
        for(AggregateResult ar : [SELECT ConditionChainHead__c FROM Account WHERE ConditionChainHead__c IN : inputAccts GROUP BY ConditionChainHead__c]){
            accountsAsChainHeads.add((Id) ar.get('ConditionChainHead__c'));
        }

        for(Account ac : inputAccts){
            // Decision Node 0
            if(ac.AccountCategorySource__c == CONST_MANUAL){ continue; }
            if(ac.IsChainMember__c){
                // Decision Node 1.1: Is Chain Member
                if(
                    ac.ConditionChainParent__c != null || ac.ConditionChainHead__c != null || ac.CentralRegulator__c != null || 
                    accountsAsCentralRegulators.contains(ac.Id) || accountsAsChainParents.contains(ac.Id) || accountsAsChainHeads.contains(ac.Id)
                ){
                    // Decision Node 1.1.1: Is Regulator 
                    if(accountsAsCentralRegulators.contains(ac.Id)){
                        // Decision Node 1.1.1.1 and 1.1.1.2: Is Central or Sub Regulator
                        ac = setRegulatorCategory(ac, ac.CentralRegulator__c == null);
                        continue;
                    }
                    // Decision Node 1.1.2: Is Own Legal Person
                    Boolean selfBillingCheck = false;
                    if(String.isNotBlank(ac.LegalForm__c)){
                        if(ac.LegalForm__c == CONST_NO_OWN_LEGAL_FORM){
                            // Decision Node 1.1.2.1: Department
                            ac = setCategory(ac, CAT_DEPARTMENT);
                            continue;
                        } else {
                            // Decision Node 1.1.2.3: Self Billing?
                            selfBillingCheck = true;
                        }
                    } else {
                        if(String.isNotBlank(ac.TaxID__c)){
                            if(String.isBlank(ac.ParentTaxId__c) || extendedTrim(ac.ParentTaxId__c) != extendedTrim(ac.TaxId__c)){
                                // Decision Node 1.1.2.3: Self Billing?
                                selfBillingCheck = true;
                            } else {
                                // Decision Node 1.1.2.1: Department
                                ac = setCategory(ac, CAT_DEPARTMENT);
                                continue;
                            }
                        } else {
                            // Decision Node 1.1.2.2: Unclassified as both Legal Form and Tax ID are missing
                            ac = setCategory(ac, CAT_UNCLASSIFIED, FLAG_LEGALFORM_MISSING);
                            continue;
                        }
                    }
                    // Decision Node 1.1.2.3: Self Billing?
                    if(selfBillingCheck == true){
                        if(ac.InvoiceRecipient__c != null && ac.Id != null && (ac.Id != ac.InvoiceRecipient__c)){
                            ac = setCategory(ac, CAT_ASSOCIATION_MEMBER);
                            continue;
                        }
                        if(ac.SelfBilled__c == true || (ac.Id != null && (ac.Id == ac.InvoiceRecipient__c))){
                            ac = setCategory(ac, CAT_DIRECT_CUSTOMER);
                            continue;
                        }
                        ac = setCategory(ac, CAT_UNCLASSIFIED, FLAG_BILLING_UNKNOWN);
                        continue;
                    }
                } else {
                    ac = setCategory(ac, CAT_UNCLASSIFIED, FLAG_NO_EVIDENCE);
                    continue;
                }
            } else {
                // Decision Node 1.2: Not Chain Member
                if(ac.InvoiceRecipient__c == null){
                    ac = setCategory(ac, CAT_DIRECT_CUSTOMER);
                    continue;
                } else {
                    ac = setCategory(ac, CAT_UNCLASSIFIED, FLAG_NO_CHAIN_FOREIGN_BILLED);
                    continue;
                }
            }
            // Fallback: Unclassified without reason if not been classified so far
            ac = setCategory(ac, CAT_UNCLASSIFIED, null);
        }

        return inputAccts;
    }

    private static String extendedTrim(String inputString){
        return String.isNotBlank(inputString) ? inputString.trim().toLowerCase().replaceAll('[^a-zA-Z0-9]', '') : '';
    }

    private static Account setCategory(Account ac, String category){
        if(ac.AccountCategory__c != category){
            ac.AccountCategory__c = category;
            ac.AccountCategoryReason__c = null;
            ac.AccountCategorySource__c = CONST_AUTOMATIC;
            ac.AccountCategoryDerivedAt__c = Datetime.now();
        }
        return ac;
    } 
    private static Account setCategory(Account ac, String category, String reasonFlag){
        if(ac.AccountCategory__c != category || ac.AccountCategoryReason__c != reasonFlag){
            ac.AccountCategory__c = category;
            ac.AccountCategoryReason__c = reasonFlag;
            ac.AccountCategorySource__c = CONST_AUTOMATIC;
            ac.AccountCategoryDerivedAt__c = Datetime.now();
        }
        return ac;
    } 
    private static Account setRegulatorCategory(Account ac, Boolean isAll){
        String category = CAT_CENTRAL_REGULATOR;
        String regulatorLevel = isAll ? REGULATOR_ALL : REGULATOR_SUB;
        if(ac.AccountCategory__c != category || ac.RegulatorLevel__c != regulatorLevel){
            ac.AccountCategory__c = category;
            ac.RegulatorLevel__c = regulatorLevel;
            ac.AccountCategorySource__c = CONST_AUTOMATIC;
            ac.AccountCategoryDerivedAt__c = Datetime.now();
        }
        return ac;
    } 
}
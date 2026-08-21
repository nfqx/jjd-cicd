import { LightningElement, api, track } from 'lwc';

import product from '@salesforce/label/c.GeneralProduct';
import subgroup from '@salesforce/label/c.GeneralSubgroup';
import individual from '@salesforce/label/c.GeneralIndividual';
import yes from '@salesforce/label/c.GeneralYes';
import no from '@salesforce/label/c.GeneralNo';
import freeFromSurcharge from '@salesforce/label/c.PriceConfiguratorWarningFreeFromSurcharge';
import firstLevelWarning from '@salesforce/label/c.PriceConfiguratorWarningFirstLevel';
import secondLevelWarning from '@salesforce/label/c.PriceConfiguratorWarningSecondLevel';
import thirdLevelWarning from '@salesforce/label/c.PriceConfiguratorWarningThirdLevel';
import { stringIsNotBlank } from 'c/stringHelper';
import searchWithIds from '@salesforce/apex/LookupController.searchWithIds';

export default class PriceConfiguratorConditionProductRow extends LightningElement {
    @api rowdata = {};
    @api standardPricebookEntries = {};
    @api auxiliaryTables = {};
    @api industry = '';
    @api isInherited = false;
    @track _params = {};
    @track _numTypes = {};
    @track _existingRows = [];
    @track _rowdata = {};
    @api
    set params(value) {
        this._params = value;
        this.calculateRow();
    }
    get params() {
        return this._params;
    }
    @api
    set existingRows(value) {
        this._existingRows = value;
    }
    get existingRows() {
        return this._existingRows;
    }
    @api
    set numTypes(value) {
        this._numTypes = value;
        this.calculateRow();
    }
    get numTypes() {
        return this._numTypes;
    }



    label = {
        freeFromSurcharge,
        yes,
        no,
        product,
        subgroup,
        individual,
        firstLevelWarning,
        secondLevelWarning,
        thirdLevelWarning
    }

    connectedCallback(){
        this._rowdata = JSON.parse(JSON.stringify(this.rowdata));
        if(this._rowdata && this._rowdata.producttype && this._rowdata.product){
            if(this._rowdata.producttype == this.label.product){
                let self = this;
                setTimeout(() => {
                    self.template.querySelectorAll('[data-field="product"]').forEach(element => {
                        element.selection = ([{
                            id : self._rowdata.product,
                            sObjectType : 'Product2',
                            icon : 'standard:product',
                            title : self._rowdata.productName,
                            subtitle : self._rowdata.productGroup
                        }]);
                    });
                }, 200);
            } else if(this._rowdata.producttype == this.label.subgroup){
                let self = this;
                setTimeout(() => {
                    self.template.querySelectorAll('[data-field="productSubgroup"]').forEach(element => {
                        element.selection = ([{
                            id : self._rowdata.product,
                            sObjectType : 'Product2',
                            icon : 'standard:product',
                            title : self._rowdata.productName,
                            subtitle : self._rowdata.productGroup
                        }]);
                    });
                }, 200);
            }
        }
        this.calculateRow();
    }

    // Getters
    get isKann(){
        return this.params && this.params.customerType && this.params.customerType == 'Einkaufsgesellschaft KANN';
    }
    get isMuss(){
        return this.params && this.params.customerType && this.params.customerType == 'Einkaufsgesellschaft MUSS';
    }
    get isMussOrNotCoffeeTea(){
        return this.isMuss || 
            (this._rowdata.productGroup != 'Röstkaffee' && this._rowdata.productGroup != 'Tee') || 
            (this._rowdata.productGroup == 'Röstkaffee' && !stringIsNotBlank(this.params.coffeeRefundType)) || 
            (this._rowdata.productGroup == 'Tee' && !stringIsNotBlank(this.params.teaRefundType));
    }
    get isChain(){
        return this.params && this.params.customerType && this.params.customerType == 'Kette';
    }
    get isProduct(){
        return this._rowdata.producttype == this.label.product;
    }
    get isSubgroup(){
        return this._rowdata.producttype == this.label.subgroup;
    }
    get isSubgroupOrMuss(){
        return this.isSubgroup || this.isMuss;
    }
    get isSubgroupAndHasNoPrice(){
        return this.isSubgroup && !this._rowdata.subgroupHasPrice;
    }
    get displayRow(){
        return !this.isMuss || stringIsNotBlank(this._rowdata.product);
    }
    get hasTotalAddition(){
        return stringIsNotBlank(this._rowdata.totalAddition) && parseFloat(this._rowdata.totalAddition) != 0;
    }
    get showWarning(){
        return parseInt(this._rowdata.warningLevel) >= 1;
    }
    get rowClass() {
        return this._rowdata.individualCondition ? 'highlighted-row' : 'row';
    }
    get colorStyle(){
        if(stringIsNotBlank(this._rowdata.warningLevel) && parseInt(this._rowdata.warningLevel) != 0){
            if(parseInt(this._rowdata.warningLevel) == 1){
                return 'color: #FFC300;';
            } else if(parseInt(this._rowdata.warningLevel) == 2){
                return 'color: #FF5733;';
            } else if(parseInt(this._rowdata.warningLevel) == 3){
                return 'color: #C70039;';
            }
        }
        return '';
    }
    get warningMessage(){
        if(stringIsNotBlank(this._rowdata.warningLevel) && parseInt(this._rowdata.warningLevel) != 0){
            if(parseInt(this._rowdata.warningLevel) == 1){
                return this.label.firstLevelWarning;
            } else if(parseInt(this._rowdata.warningLevel) == 2){
                return this.label.secondLevelWarning;
            } else if(parseInt(this._rowdata.warningLevel) == 3){
                return this.label.thirdLevelWarning;
            }
        }
        return '';
    }

    get productColumnSize(){
        if(this._showSimulationColumns){
            return this._showRefund && this._showRefundColumn ? (this.isMuss || this.isInherited ? '2' : '1') : (this.isMuss || this.isInherited ? '4' : '3');
        } else {
            return this._showRefund && this._showRefundColumn ? (this.isMuss || this.isInherited ? '3' : '2') : (this.isMuss || this.isInherited ? '5' : '4');
        }
    }

    productTypeOptions = [
        {label: this.label.product, value: this.label.product, selected: true},
        {label: this.label.subgroup, value: this.label.subgroup, selected: false}
    ]

    handleProductSearch(event){
        let searchParam = {
            parentObjectApiName: "PricebookEntry",
            lookupApiName: "Product2Id",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'Product2', filter : 'IsActive = TRUE AND ProductGroup__c != NULL AND (NOT Name LIKE \'Produktgruppe%\') AND (NOT Name LIKE \'Produkt-Untergruppe%\')'}],
            //lookupFilters: [{objectType : 'Product2', filter : 'IsActive = TRUE AND ProductGroup__c != NULL AND ProductSubgroup__c != NULL AND (NOT Name LIKE \'Produktgruppe%\')'}],
            additionalFields: ['ProductCode', 'ExemptFromSurcharges__c', 'ProductGroupName__c', 'ProductSubgroupName__c', 'LowestConditionForSalesAreaManager__c', 'LowestConditionForSalesManager__c'],
            listIds: Object.keys(this.standardPricebookEntries),
            listIdsExclude: this._existingRows,
            displayField: 'QuoteName__c'
        };
        searchWithIds(searchParam)
        .then(results => {
            this.template
                .querySelector('[data-field="product"]')
                .setSearchResults(results);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleProductSubgroupSearch(event){
        let searchParam = {
            parentObjectApiName: "Product2",
            lookupApiName: "ProductSubgroup__c",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'Product2', filter : 'IsActive = TRUE AND Name LIKE \'%Produkt-Untergruppe%\''}],
            //lookupFilters: [{objectType : 'Product2', filter : 'IsActive = TRUE AND Ist_Untergruppe__c = TRUE'}],
            additionalFields: ['ProductGroupName__c'],
            listIds: Object.keys(this.standardPricebookEntries),
            listIdsExclude: this._existingRows,
            displayField: 'QuoteName__c'
        };
        searchWithIds(searchParam)
        .then(results => {
            this.template
                .querySelector('[data-field="productSubgroup"]')
                .setSearchResults(results);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleProductSubgroupChange(event){
        this._rowdata.specialRebate = 0;
        this._rowdata.specialRebatePercent = 0;
        this._rowdata.refundAmount = 0;
        this._rowdata.refundPercent = 0;
        if (event.target.selection && event.target.selection.length > 0) {
            event.target.selection.forEach(selection => {
                this._rowdata.product = selection.id;
                this._rowdata.productName = selection.title;
                this._rowdata.productSubgroup = stringIsNotBlank(selection.title) ? selection.title.replace('Produkt-Untergruppe: ', '') : '';
                this._rowdata.productGroup = stringIsNotBlank(selection.additionalFieldMap.ProductGroupName__c) ? selection.additionalFieldMap.ProductGroupName__c.replace('Produktgruppe: ', '') : '';
                if(Object.keys(this.standardPricebookEntries).includes(selection.id) && parseInt(this.standardPricebookEntries[selection.id]) > 0){
                    this._rowdata.basePricePre = parseFloat(this.standardPricebookEntries[selection.id]);
                    this._rowdata.subgroupHasPrice = true;
                } else {
                    this._rowdata.basePricePre = 0;
                    this._rowdata.subgroupHasPrice = false;
                }
            })
        } else {
            this._rowdata.basePricePre = 0;
        }
        this.calculateRow();
    }

    handleProductChange(event){
        this._rowdata.specialRebate = 0;
        this._rowdata.specialRebatePercent = 0;
        this._rowdata.refundAmount = 0;
        this._rowdata.refundPercent = 0;
        if (event.target.selection && event.target.selection.length > 0) {
            event.target.selection.forEach(selection => {
                this._rowdata.product = selection.id;
                this._rowdata.productName = selection.title;
                this._rowdata.productSubgroup = stringIsNotBlank(selection.additionalFieldMap.ProductSubgroupName__c) ? selection.additionalFieldMap.ProductSubgroupName__c.replace('Produkt-Untergruppe: ', '') : '';
                this._rowdata.productGroup = stringIsNotBlank(selection.additionalFieldMap.ProductGroupName__c) ? selection.additionalFieldMap.ProductGroupName__c.replace('Produktgruppe: ', '') : '';
                this._rowdata.freeFromSurcharge = selection.additionalFieldMap.ExemptFromSurcharges__c;
                this._rowdata.lowestConditionSalesAreaManager = stringIsNotBlank(selection.additionalFieldMap.LowestConditionForSalesAreaManager__c) ? parseFloat(selection.additionalFieldMap.LowestConditionForSalesAreaManager__c) : 0;
                this._rowdata.lowestConditionSalesManager = stringIsNotBlank(selection.additionalFieldMap.LowestConditionForSalesManager__c) ? parseFloat(selection.additionalFieldMap.LowestConditionForSalesManager__c) : 0;
                this._rowdata.minimumPrice = 0; //stringIsNotBlank(selection.additionalFieldMap.Minimum_Price__c) ? parseFloat(selection.additionalFieldMap.Minimum_Price__c) : 0;
                this._rowdata.basePricePre = Object.keys(this.standardPricebookEntries).includes(selection.id) ? parseFloat(this.standardPricebookEntries[selection.id]) : 0;
            })
        } else {
            let preProduct = this._rowdata.product;
            let existingRowsAlt = JSON.parse(JSON.stringify(this._existingRows));
            let index = existingRowsAlt.indexOf(preProduct);
            if (index > -1) {
                existingRowsAlt.splice(index, 1);
            }
            this._existingRows = JSON.parse(JSON.stringify(existingRowsAlt));
            this._rowdata.product = null;
            this._rowdata.productName = null;
            this._rowdata.productSubgroup = null;
            this._rowdata.productGroup = null;
            this._rowdata.freeFromSurcharge = null;
            this._rowdata.lowestConditionSalesAreaManager = null;
            this._rowdata.lowestConditionSalesManager = null;
            this._rowdata.minimumPrice = 0;
            this._rowdata.basePricePre = 0;
        }
        this.calculateRow();
    }

    changeField(event){
        let field = event.target.dataset.field;
        let value = event.target.value;
        this._rowdata[field] = stringIsNotBlank(value) ? value : 0;
        if(field == 'producttype'){
            this._rowdata.product = '';
            this._rowdata.specialRebate = 0;
            this._rowdata.specialRebatePercent = 0;
            this._rowdata.refundAmount = 0;
            this._rowdata.refundPercent = 0;
        }
        this.calculateRow();
    }

    calculateRow(){    
        let simulationPercent = 0;
        this._rowdata.productBasedDiscount = 0;
        this._rowdata.warningLevel = 0;
        this._rowdata.coffeeKgCharge = 0;
        this._rowdata.offerPrice =  0
        this._rowdata.simulationPrice = 0;
        this._rowdata.rebate = 0;
        this._rowdata.coffeeQuantityDiscount = 0;
        this._rowdata.coffeeSelectionDiscount = 0;
        this._rowdata.teaQuantityDiscount = 0;
        this._rowdata.teaSelectionDiscount = 0;
        this._rowdata.cocoaQuantityDiscount = 0;
        this._rowdata.cocoaSelectionDiscount = 0;
        this._rowdata.otherQuantityDiscount = 0;
        this._rowdata.otherSelectionDiscount = 0;
        this._rowdata.brandingTableDiscount= 0;
        this._rowdata.brandingMenuDiscount= 0;
        this._rowdata.brandingPropertyDiscount = 0;
        this._rowdata.brandingDigitalDiscount = 0,
        this._rowdata.simRebateDiscount = 0;
        this._rowdata.simRefundDiscount = 0;
        this._rowdata.simGrowthDiscount = 0;
        this._rowdata.coffeeBaseDiscount = 0;
        this._rowdata.teaBaseDiscount = 0;
        this._rowdata.cocoaBaseDiscount = 0;
        this._rowdata.otherBaseDiscount = 0;
        this._rowdata.baseConditionDiscount = 0;
        let refundAmount = 0;
        let refundPercent = 0;
        if(stringIsNotBlank(this._rowdata.product)){

            this._rowdata.simGrowthDiscount = 
                stringIsNotBlank(this.params.simulatedRevenue) && stringIsNotBlank(this.params.growthPercent) && Object.keys(this.auxiliaryTables).includes('simulationAndGrowth') && Object.keys(this.auxiliaryTables.simulationAndGrowth).includes(this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()) ? 
                this.auxiliaryTables.simulationAndGrowth[this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()] :
                0;
            this._rowdata.simRebateDiscount = (stringIsNotBlank(this.params.discount) && Object.keys(this.auxiliaryTables).includes('discount') && Object.keys(this.auxiliaryTables.discount).includes(this.params.discount) ?  this.auxiliaryTables.discount[this.params.discount] : 0);
            this._rowdata.simRefundDiscount = stringIsNotBlank(refundPercent) ? parseFloat(refundPercent) : 0;
            
            simulationPercent = (
                this._rowdata.simRebateDiscount + 
                this._rowdata.simRefundDiscount +
                this._rowdata.simGrowthDiscount
            );
            let currentlyValidKey = 0;
            let currentlyValidValue = 0;
            if(this.numTypes.coffeeInherit.quantities != null && this.numTypes.coffeeInherit.quantities != 0){
                currentlyValidValue = this.numTypes.coffeeInherit.quantities;
            } else if(this.numTypes.coffee.quantities != null && this.numTypes.coffee.quantities != 0){
                currentlyValidValue = this.numTypes.coffee.quantities;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('volumeCoffee')){
                    Object.keys(this.auxiliaryTables.volumeCoffee).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.coffeeQuantityDiscount = parseInt(this.auxiliaryTables.volumeCoffee[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }
            currentlyValidKey = 0;
            currentlyValidValue = 0;
            if(this.numTypes.coffeeInherit.selection != null && this.numTypes.coffeeInherit.selection != 0){
                currentlyValidValue = this.numTypes.coffeeInherit.selection;
            } else if(this.numTypes.coffee.selection != null && this.numTypes.coffee.selection != 0){
                currentlyValidValue = this.numTypes.coffee.selection;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('assortmentCoffee')){
                    Object.keys(this.auxiliaryTables.assortmentCoffee).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.coffeeSelectionDiscount = parseInt(this.auxiliaryTables.assortmentCoffee[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }
            currentlyValidKey = 0;
            currentlyValidValue = 0;
            if(this.numTypes.teaInherit.quantities != null && this.numTypes.teaInherit.quantities != 0){
                currentlyValidValue = this.numTypes.teaInherit.quantities;
            } else if(this.numTypes.tea.quantities != null && this.numTypes.tea.quantities != 0){
                currentlyValidValue = this.numTypes.tea.quantities;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('volumeTea')){
                    Object.keys(this.auxiliaryTables.volumeTea).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.teaQuantityDiscount = parseInt(this.auxiliaryTables.volumeTea[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }
            currentlyValidKey = 0;
            currentlyValidValue = 0;
            if(this.numTypes.teaInherit.selection != null && this.numTypes.teaInherit.selection != 0){
                currentlyValidValue = this.numTypes.teaInherit.selection;
            } else if(this.numTypes.tea.selection != null && this.numTypes.tea.selection != 0){
                currentlyValidValue = this.numTypes.tea.selection;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('assortmentTea')){
                    Object.keys(this.auxiliaryTables.assortmentTea).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.teaSelectionDiscount = parseInt(this.auxiliaryTables.assortmentTea[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }
            currentlyValidKey = 0;
            currentlyValidValue = 0;
            if(this.numTypes.otherInherit.quantities != null && this.numTypes.otherInherit.quantities != 0){
                currentlyValidValue = this.numTypes.otherInherit.quantities;
            } else if(this.numTypes.other.quantities != null && this.numTypes.other.quantities != 0){
                currentlyValidValue = this.numTypes.other.quantities;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('volumeOther')){
                    Object.keys(this.auxiliaryTables.volumeOther).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.otherQuantityDiscount = parseInt(this.auxiliaryTables.volumeOther[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }
            currentlyValidKey = 0;
            currentlyValidValue = 0;
            if(this.numTypes.otherInherit.selection != null && this.numTypes.otherInherit.selection != 0){
                currentlyValidValue = this.numTypes.otherInherit.selection;
            } else if(this.numTypes.other.selection != null && this.numTypes.other.selection != 0){
                currentlyValidValue = this.numTypes.other.selection;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('assortmentOther')){
                    Object.keys(this.auxiliaryTables.assortmentOther).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.otherSelectionDiscount = parseInt(this.auxiliaryTables.assortmentOther[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }
            currentlyValidKey = 0;
            currentlyValidValue = 0;
            if(this.numTypes.cocoaInherit.quantities != null && this.numTypes.cocoaInherit.quantities != 0){
                currentlyValidValue = this.numTypes.cocoaInherit.quantities;
            } else if(this.numTypes.cocoa.quantities != null && this.numTypes.cocoa.quantities != 0){
                currentlyValidValue = this.numTypes.cocoa.quantities;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('volumeCocoa')){
                    Object.keys(this.auxiliaryTables.volumeCocoa).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.cocoaQuantityDiscount = parseInt(this.auxiliaryTables.volumeCocoa[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }
            currentlyValidKey = 0;
            currentlyValidValue = 0;
            if(this.numTypes.cocoaInherit.selection != null && this.numTypes.cocoaInherit.selection != 0){
                currentlyValidValue = this.numTypes.cocoaInherit.selection;
            } else if(this.numTypes.cocoa.selection != null && this.numTypes.cocoa.selection != 0){
                currentlyValidValue = this.numTypes.cocoa.selection;
            }
            if(currentlyValidValue != 0){
                if(Object.keys(this.auxiliaryTables).includes('assortmentCocoa')){
                    Object.keys(this.auxiliaryTables.assortmentCocoa).forEach(key => {
                        if(parseInt(key) >= currentlyValidKey && parseInt(currentlyValidValue) >= parseInt(key)){
                            this._rowdata.cocoaSelectionDiscount = parseInt(this.auxiliaryTables.assortmentCocoa[key]);
                            currentlyValidKey = parseInt(key);
                        }
                    })
                }
            }

            if(this._rowdata.productGroup == 'Röstkaffee'){
                this._rowdata.coffeeBaseDiscount = 
                    stringIsNotBlank(this.industry) && stringIsNotBlank(this._rowdata.productGroup) && Object.keys(this.auxiliaryTables).includes('industryProductSubgroup') && Object.keys(this.auxiliaryTables.industryProductSubgroup).includes(this.industry + this._rowdata.productGroup) ? 
                    this.auxiliaryTables.industryProductSubgroup[this.industry + this._rowdata.productGroup] :
                    0;
                this._rowdata.productBasedDiscount = this._rowdata.coffeeQuantityDiscount + this._rowdata.coffeeSelectionDiscount;
            } else if(this._rowdata.productGroup == 'Tee'){
                this._rowdata.teaBaseDiscount = 
                    stringIsNotBlank(this.industry) && stringIsNotBlank(this._rowdata.productGroup) && Object.keys(this.auxiliaryTables).includes('industryProductSubgroup') && Object.keys(this.auxiliaryTables.industryProductSubgroup).includes(this.industry + this._rowdata.productGroup) ? 
                    this.auxiliaryTables.industryProductSubgroup[this.industry + this._rowdata.productGroup] :
                    0;
                this._rowdata.productBasedDiscount = this._rowdata.teaQuantityDiscount + this._rowdata.teaSelectionDiscount;
            } else if(this._rowdata.productGroup == 'Trinkschokolade'){
                this._rowdata.cocoaBaseDiscount = 
                    stringIsNotBlank(this.industry) && stringIsNotBlank(this._rowdata.productGroup) && Object.keys(this.auxiliaryTables).includes('industryProductSubgroup') && Object.keys(this.auxiliaryTables.industryProductSubgroup).includes(this.industry + this._rowdata.productGroup) ? 
                    this.auxiliaryTables.industryProductSubgroup[this.industry + this._rowdata.productGroup] :
                    0;
                this._rowdata.productBasedDiscount = this._rowdata.cocoaQuantityDiscount + this._rowdata.cocoaSelectionDiscount;
            } else if(stringIsNotBlank(this._rowdata.productGroup)) {
                this._rowdata.otherBaseDiscount = 
                    stringIsNotBlank(this.industry) && stringIsNotBlank(this._rowdata.productGroup) && Object.keys(this.auxiliaryTables).includes('industryProductSubgroup') && Object.keys(this.auxiliaryTables.industryProductSubgroup).includes(this.industry + 'Sonstiges') ? 
                    this.auxiliaryTables.industryProductSubgroup[this.industry + 'Sonstiges'] :
                    0;
                this._rowdata.productBasedDiscount = this._rowdata.otherQuantityDiscount + this._rowdata.otherSelectionDiscount;
            } 

            this._rowdata.brandingTableDiscount = (stringIsNotBlank(this.params.hasOfferOnTable) && this.params.hasOfferOnTable == this.label.yes && Object.keys(this.auxiliaryTables).includes('branding') && Object.keys(this.auxiliaryTables.branding).includes('offerOnTable') ?  this.auxiliaryTables.branding.offerOnTable : 0);
            this._rowdata.brandingMenuDiscount = (stringIsNotBlank(this.params.hasMenuLogo) && this.params.hasMenuLogo == this.label.yes && Object.keys(this.auxiliaryTables).includes('branding') && Object.keys(this.auxiliaryTables.branding).includes('menuLogo') ?  this.auxiliaryTables.branding.menuLogo : 0);
            this._rowdata.brandingPropertyDiscount = (stringIsNotBlank(this.params.hasOfferInProperty) && this.params.hasOfferInProperty == this.label.yes && Object.keys(this.auxiliaryTables).includes('branding') && Object.keys(this.auxiliaryTables.branding).includes('offerInProperty') ?  this.auxiliaryTables.branding.offerInProperty : 0);
            this._rowdata.brandingDigitalDiscount = (stringIsNotBlank(this.params.hasDigitalRequired) && this.params.hasDigitalRequired == this.label.yes && Object.keys(this.auxiliaryTables).includes('digital') && Object.keys(this.auxiliaryTables.digital).includes(this.params.hasDigitalRequired) ?  this.auxiliaryTables.digital[this.params.hasDigitalRequired] : 0);
            this._rowdata.baseConditionDiscount = parseFloat(this.params.indexCondition);
            
            this._rowdata.rebate = (
                this._rowdata.brandingTableDiscount+
                this._rowdata.brandingMenuDiscount+
                this._rowdata.brandingPropertyDiscount +
                this._rowdata.brandingDigitalDiscount +
                this._rowdata.productBasedDiscount +
                parseFloat(this._rowdata.specialRebatePercent)
            ) / 100;
            this._rowdata.coffeeKgCharge = !this._rowdata.freeFromSurcharge ? (this._rowdata.productGroup == 'Röstkaffee' && this._rowdata.type != this.label.subgroup ? parseFloat(this.params.kgChargeCalculated) + parseFloat(this.params.coffeeSurchargeMachine) : 0) : 0;
            // CRM-1523
            let preDiscount = (this._rowdata.coffeeBaseDiscount +
                this._rowdata.teaBaseDiscount +
                this._rowdata.cocoaBaseDiscount +
                this._rowdata.otherBaseDiscount ) / 100;
            if(this._rowdata.productGroup == 'Röstkaffee'){
                preDiscount += (this._rowdata.baseConditionDiscount / 100);
            }
            let factor = 1 - preDiscount < 0 ? 0 : 1 - preDiscount;
            this._rowdata.basePrice = (this._rowdata.basePricePre ?? 0) * factor;
            // CRM-1523 END
            if(stringIsNotBlank(this._rowdata.basePrice)){
                this._rowdata.offerPrice =  this._rowdata.basePrice != null && this._rowdata.rebate != null ?
                                            ((parseFloat(this._rowdata.basePrice) - (parseFloat(this._rowdata.basePrice) * this._rowdata.rebate)) + (this._rowdata.coffeeKgCharge - parseFloat(this._rowdata.specialRebate))) : 0;
                this._rowdata.simulationPrice = stringIsNotBlank(this._rowdata.offerPrice) ? (this._rowdata.offerPrice - ( (this._rowdata.offerPrice * (simulationPercent / 100)) + parseFloat(refundAmount)) ) : 0;
                // CRM-1426
                if(this._rowdata.productGroup == 'Röstkaffee' || this._rowdata.productGroup == 'Trinkschokolade'){
                    if(stringIsNotBlank(this.params.coffeeWkzRuntime) && stringIsNotBlank(this.params.coffeeWkzOneTimeAmount)){
                        let annualWkz = ((parseFloat(this.params.coffeeWkzOneTimeRefund) * 12) / parseFloat(this.params.coffeeWkzRuntime)) + parseFloat(this.params.coffeeWkzAnnualRefund);
                        let wkzBasedDiscount = annualWkz / parseFloat(this.params.coffeeWkzOneTimeAmount);
                        this._rowdata.simulationPrice -= wkzBasedDiscount;
                    }
                } else if(this._rowdata.productGroup == 'Tee'){
                    if(stringIsNotBlank(this.params.teaWkzRuntime) && stringIsNotBlank(this.params.teaWkzOneTimeAmount)){
                        let annualWkz = ((parseFloat(this.params.teaWkzOneTimeRefund) * 12) / parseFloat(this.params.teaWkzRuntime)) + parseFloat(this.params.teaWkzAnnualRefund);
                        let wkzBasedDiscount = annualWkz / parseFloat(this.params.teaWkzOneTimeAmount);
                        this._rowdata.simulationPrice -= wkzBasedDiscount;
                    }
                }
                // End CRM-1426
            }
        }
        // Warnings
        let validPrice = this._rowdata.offerPrice;
        if(!this.isSubgroupAndHasNoPrice){
            /*if(stringIsNotBlank(this._rowdata.minimumPrice) && parseFloat(this._rowdata.minimumPrice) != 0 && validPrice < parseFloat(this._rowdata.minimumPrice)){
                this._rowdata.warningLevel = 3;
            } else*/ if(stringIsNotBlank(this._rowdata.lowestConditionSalesManager) && parseFloat(this._rowdata.lowestConditionSalesManager) != 0 && validPrice < parseFloat(this._rowdata.lowestConditionSalesManager)){
                this._rowdata.warningLevel = 2;
            } else if(stringIsNotBlank(this._rowdata.lowestConditionSalesAreaManager) && parseFloat(this._rowdata.lowestConditionSalesAreaManager) != 0 && validPrice < parseFloat(this._rowdata.lowestConditionSalesAreaManager)){
                this._rowdata.warningLevel = 1;
            }
        }
        // Display values
        this._rowdata.offerPriceDisplay = stringIsNotBlank(this._rowdata.offerPrice) ? this._rowdata.offerPrice.toFixed(2) : 0;
        this._rowdata.simulationPriceDisplay = stringIsNotBlank(this._rowdata.simulationPrice) ? this._rowdata.simulationPrice.toFixed(2) : 0;
        this._rowdata.rebateDisplay = this._rowdata.rebate != null ? (this._rowdata.rebate * 100).toFixed(2) : 0;
        this._rowdata.basePriceDisplay = this._rowdata.basePrice != null ? this._rowdata.basePrice.toFixed(2) : 0;
        this.reportToParent();
    }

    reportToParent(){
        const changeEvent = new CustomEvent('valuechange', {
            detail: this._rowdata
        });
        this.dispatchEvent(changeEvent);
    }
    
    handleRemoveRow(){
        const deleteEvent = new CustomEvent('rowdelete', {
            detail: this._rowdata.rownumber
        });
        this.dispatchEvent(deleteEvent);
    }
    
    handlePromoteToIndividual(){
        const next = JSON.parse(JSON.stringify(this._rowdata));
        next.individualCondition = true;
        const promoteEvent = new CustomEvent('promote', {
            detail: next
        });
        this.dispatchEvent(promoteEvent);
    }
}
import { LightningElement, api, track } from 'lwc';

import yes from '@salesforce/label/c.GeneralYes';
import no from '@salesforce/label/c.GeneralNo';
import product from '@salesforce/label/c.GeneralProduct';
import warningMessage from '@salesforce/label/c.PriceConfiguratorTeaDiscountWarningMessage';

import searchWithIds from '@salesforce/apex/LookupController.searchWithIds';
import { stringIsNotBlank } from 'c/stringHelper';

export default class PriceConfiguratorInitialEquipmentRow extends LightningElement {
    @api rowdata = {};
    @api standardPricebookEntries = {};
    @track _rowdata = {};
    @track _showTeaColumn = null;
    @track _maxTeaDiscountViolated = false;
    @track _maxTeaDiscountValue = 0;
    @track _existingRowsInitial = [];
    @track quantity = 1;
    @api
    set showTeaColumn(value) {
        this._showTeaColumn = value;
        if(!value){
            this._rowdata.teaDiscount = 0;
        }
        this.calculateRow();
    }
    get showTeaColumn() {
        return this._showTeaColumn == null ? this._rowdata.showTeaColumn : this._showTeaColumn;
    }

    @api
    set maxTeaDiscountViolated(value) {
        this._maxTeaDiscountViolated = value;
    }
    get maxTeaDiscountViolated() {
        return this._maxTeaDiscountViolated;
    }

    @api
    set existingRowsInitial(value) {
        this._existingRowsInitial = value;
    }
    get existingRowsInitial() {
        return this._existingRowsInitial;
    }

    @api
    set maxTeaDiscountValue(value) {
        this._maxTeaDiscountValue = value;
    }
    get maxTeaDiscountValue() {
        return this._maxTeaDiscountValue;
    }


    get productColumnSize(){
        return this.showTeaColumn ? '2' : '3';
    }
    get hasProductName(){
        return stringIsNotBlank(this._rowdata.productName);
    }

    connectedCallback(){
        this._rowdata = JSON.parse(JSON.stringify(this.rowdata));
        this.calculateRow();
    }

    label = {
        product,
        yes,
        no,
        warningMessage
    }

    get warningMessageLabel(){
        return this.label.warningMessage.replaceAll('{0}', this._maxTeaDiscountValue.toFixed(2));
    }
    
    yesNoOptions = [
        {label: this.label.yes, value: this.label.yes, selected: false},
        {label: this.label.no, value: this.label.no, selected: true}
    ]

    handleProductSearch(event){
        let searchParam = {
            parentObjectApiName: "PricebookEntry",
            lookupApiName: "Product2Id",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'Product2', filter : 'IsActive = TRUE AND Ist_Aufschlagsprodukt__c = TRUE AND ProductClass = \'VariationParent\' AND PreviewPrice__c != NULL AND ProductSubgroup__c != NULL AND (NOT Name LIKE \'Produkt-Untergruppe%\')'}],
            additionalFields: ['ProductCode', 'ProductGroupName__c', 'ProductSubgroupName__c', 'PreviewPrice__c'],
            listIds: Object.keys(this.standardPricebookEntries),
            listIdsExclude: this._existingRowsInitial,
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

    handleProductChange(event){
        if (event.target.selection && event.target.selection.length > 0) {
            event.target.selection.forEach(selection => {
                this._rowdata.product = selection.id;
                this._rowdata.previewPrice = stringIsNotBlank(selection.additionalFieldMap.PreviewPrice__c) ? parseFloat(selection.additionalFieldMap.PreviewPrice__c) : parseFloat(this.standardPricebookEntries[selection.id]);
                this._rowdata.productName = selection.title;
                this._rowdata.productSubgroup = stringIsNotBlank(selection.additionalFieldMap.ProductSubgroupName__c) ? selection.additionalFieldMap.ProductSubgroupName__c.replace('Produkt-Untergruppe: ', '') : '';
                this._rowdata.productGroup = stringIsNotBlank(selection.additionalFieldMap.ProductGroupName__c) ? selection.additionalFieldMap.ProductGroupName__c.replace('Produktgruppe: ', '') : '';
                this._rowdata.isSubgroup = false;
            })
        } else {
            let preProduct = this._rowdata.product;
            let existingRowsAlt = JSON.parse(JSON.stringify(this._existingRowsInitial));
            let index = existingRowsAlt.indexOf(preProduct);
            if (index > -1) {
                existingRowsAlt.splice(index, 1);
            }
            this._existingRowsInitial = JSON.parse(JSON.stringify(existingRowsAlt));
            this._rowdata.product = null;
            this._rowdata.productName = null;
            this._rowdata.productSubgroup = null;
            this._rowdata.productGroup = null;
            this._rowdata.previewPrice = 0;
        }
        this.calculateRow();
    }

    @track timeoutId = null;
    changeQuantity(event){
        if(stringIsNotBlank(this.timeoutId)){
            clearTimeout(this.timeoutId);
        }
        let value = event.target.value;
        let populatedValue = stringIsNotBlank(value);
        let intVal = populatedValue ? parseInt(value) : 0;
        if(populatedValue === true){
            this._rowdata.quantity = intVal < 0 || intVal == 0 ? 1 : intVal;
            this.template.querySelectorAll('[data-field="quantity"]').forEach(element => {
                element.value = this._rowdata.quantity;
            });
            this.calculateRow();
        } else {
            let self = this;
            this.timeoutId = setTimeout(() => {
                self._rowdata.quantity = intVal < 0 || intVal == 0 ? 1 : intVal;
                self.template.querySelectorAll('[data-field="quantity"]').forEach(element => {
                    element.value = self._rowdata.quantity;
                });
                self.calculateRow();
            }, 1000);
        }
    }
    changeField(event){
        let field = event.target.dataset.field;
        let value = event.target.value;
        this._rowdata[field] = stringIsNotBlank(value) ? value : 0;
        this.calculateRow();
    }

    calculateRow(){
        let teaDiscount = this._rowdata.teaDiscount != null ? parseFloat(this._rowdata.teaDiscount) : 0;
        this._rowdata.sum = this._rowdata.previewPrice != null ? (parseInt(this._rowdata.quantity) == 0 ? 0 : ((this._rowdata.previewPrice * parseInt(this._rowdata.quantity)) - teaDiscount)) : null;
        this._rowdata.previewPriceDisplay = this._rowdata.previewPrice != null ? this._rowdata.previewPrice.toFixed(2) : '';
        this._rowdata.sumDisplay = this._rowdata.sum != null ? this._rowdata.sum.toFixed(2) : '';
        if(stringIsNotBlank(this._rowdata.product)){
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
        }
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
}
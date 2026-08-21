import { LightningElement, api, track } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import clearAll from '@salesforce/label/c.WebshopFilterClearAll';
import showResults from '@salesforce/label/c.WebshopFilterShowResults';
import yes from '@salesforce/label/c.GeneralYes';
import no from '@salesforce/label/c.GeneralNo';
import filterAndSort from '@salesforce/label/c.WebshopFilterAndSort';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import productsNoPrices from '@salesforce/label/c.WebshopProductsNoPrices';

export default class WebshopSliderFilter extends LightningElement {
    @api filters;
    @api showPrices;
    @api loaded = false;
    @api hasData = false;
    @track filterQuery = '';
    @track filterObject = {};
    @track filterObjectBool = {};
    @track filterObjectNum = {};
    //@track filterPrice = [null, null];
    @track filterCategory = [];

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
    } 

    label = {
        productsNoPrices,
        clearAll,
        showResults,
        yes,
        no,
        filterAndSort,
        generalError,
        generalErrorMsg
    }

    get hasFilters(){
        return this.filters.length > 0;
    }

    handleClearAllFilters(event){
        this.filterQuery = '';
        //this.filterPrice = [null, null];
        this.filterCategory = [];
        this.dispatchCustomEvent(true);
    }

    buildBoolFilter(fieldApiName, filterValue, checkboxValue){
        let innerList = fieldApiName in this.filterObjectBool ? this.filterObjectBool[fieldApiName] : [];
        let index = innerList.indexOf(filterValue);
        if (index > -1) { // only splice array when item is found
            if(!checkboxValue){
                innerList.splice(index, 1);
            }
        } else {
            if(innerList.length == 0){
                if(checkboxValue){
                    innerList.push(filterValue);
                }
            } else {
                // both checked - empty them
                this.template.querySelectorAll('input[data-fieldname=' + fieldApiName + ']').forEach(element => {
                    element.checked = false;
                });
                innerList = [];
            }
        }
        this.filterObjectBool[fieldApiName] = innerList;
        this.buildQuery();
    }
    buildFilter(fieldApiName, filterValue, checkboxValue){
        let innerList = fieldApiName in this.filterObject ? this.filterObject[fieldApiName] : [];
        let index = innerList.indexOf(filterValue);
        if (index > -1) { // only splice array when item is found
            if(!checkboxValue){
                innerList.splice(index, 1);
            }
        } else {
            if(checkboxValue){
                innerList.push(filterValue);
            }
        }
        this.filterObject[fieldApiName] = innerList;
        this.buildQuery();
    }
    buildRangeFilter(fieldApiName, min, max){
        let innerList = [min, max];
        this.filterObjectNum[fieldApiName] = innerList;
        this.buildQuery();
    }
    buildQuery(){
        let query = '';
        Object.keys(this.filterObject).forEach(key => {
            if(this.filterObject[key].length > 0){
                query += '(';
                this.filterObject[key].forEach(innerKey => {
                    query += ('(' + key + ' = \'' + innerKey + '\') OR ');
                });
                query = query.substring(0, query.length - 4);
                query += ') AND '
            }
        });

        Object.keys(this.filterObjectBool).forEach(key => {
            if(this.filterObjectBool[key].length == 1){
                if(this.filterObjectBool[key][0] == this.label.yes){
                    query += ('(' + key + ' = TRUE) AND ');
                } else if(this.filterObjectBool[key][0] == this.label.no){
                    query += ('(' + key + ' = FALSE) AND ');
                } 
            }
        });
        Object.keys(this.filterObjectNum).forEach(key => {
            if(this.filterObjectNum[key].length > 0 && this.filterObjectNum[key][0] != null){
                query += ('(' + key + ' >= ' + this.filterObjectNum[key][0] + ') AND ');
                if(this.filterObjectNum[key].length > 1 && this.filterObjectNum[key][1] != null){
                    query += ('(' + key + ' <= ' + this.filterObjectNum[key][1] + ') AND ');
                }
                query = query.substring(0, query.length - 5);
                query += ') AND '
            }
        });
        query = stringIsNotBlank(query) ? query.substring(0, query.length - 5) : '';
        this.filterQuery = stringIsNotBlank(query) ? ' AND ' + query : '';
    }
    dispatchCustomEvent(rerender){
        const changeEvent = new CustomEvent('filterchange', {
            detail: {
                filter: this.filterQuery,
                //filterPrice: this.filterPrice,
                categoryFilter: this.filterCategory,
                rerender: rerender
            }
        });
        this.dispatchEvent(changeEvent);
    }

    /*changePriceFilter(event){
        let min = event.detail.start;
        let max = event.detail.end;
        //this.filterPrice = [min, max];
        this.dispatchCustomEvent(false);
    }*/
    changeRangeFilter(event){
        let fieldApiName = event.currentTarget.dataset.fieldname;
        let min = event.detail.start;
        let max = event.detail.end;
        this.buildRangeFilter(fieldApiName, min, max);
        this.dispatchCustomEvent(false);
    }
    changeBoolFilter(event){
        let fieldApiName = event.currentTarget.dataset.fieldname;
        let filterValue = event.currentTarget.dataset.value;
        let checkboxValue = event.target.checked;
        this.buildBoolFilter(fieldApiName, filterValue, checkboxValue);
        this.dispatchCustomEvent(false);
    }
    changeMultiselectFilter(event){
        let fieldApiName = event.currentTarget.dataset.fieldname;
        let filterValue = event.currentTarget.dataset.value;
        let checkboxValue = event.target.checked;
        this.buildFilter(fieldApiName, filterValue, checkboxValue);
        this.dispatchCustomEvent(false);
    }

    changeCategoryFilter(event){
        let filterValue = event.currentTarget.dataset.value;
        let checkboxValue = event.target.checked;
        let index = this.filterCategory.indexOf(filterValue);
        if (index > -1) { // only splice array when item is found
            if(!checkboxValue){
                this.filterCategory.splice(index, 1);
            }
        } else {
            if(checkboxValue){
                this.filterCategory.push(filterValue);
            }
        }
        this.dispatchCustomEvent(false);
    }

    handleOpenFilterModal() {
        this.template.querySelector('.filter-container').classList.remove('d-none');
        this.template.querySelector('.filter-container').classList.add('d-block');
    }
    
    handleCloseFilterModal() {
        this.template.querySelector('.filter-container').classList.remove('d-block');
        this.template.querySelector('.filter-container').classList.add('d-none');
    }

    handleToggleFilter(event) {
        const filterKey = event.currentTarget.dataset.key;
        const content = this.template.querySelector(`.body-regular[data-key="${filterKey}"]`);
        const chevronDown = event.currentTarget.querySelector('.bi-chevron-down');
        const chevronUp = event.currentTarget.querySelector('.bi-chevron-up');
    
        if (content.style.display === 'none' || content.style.display === '') {
            content.style.display = 'block';

            chevronUp.style.transform = 'rotate(0deg)';
            chevronDown.style.transform = 'rotate(-180deg)';
            setTimeout(() => {
                chevronDown.style.display = 'none';
                chevronUp.style.display = 'inline-block'; 
            }, 300); 
        } else {
            content.style.display = 'none';

            chevronDown.style.transform = 'rotate(0deg)';
            chevronUp.style.transform = 'rotate(180deg)';
            setTimeout(() => {
                chevronUp.style.display = 'none';
                chevronDown.style.display = 'inline-block';
            }, 300);
        }        
    }    
    
}
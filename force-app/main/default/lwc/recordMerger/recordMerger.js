import { LightningElement, api, track } from 'lwc';
import generalFields from '@salesforce/label/c.GeneralFields';
import generalLead from '@salesforce/label/c.GeneralLead';
import mergeValues from '@salesforce/label/c.GeneralMergeValues';
import generalValue from '@salesforce/label/c.GeneralValue';
import emptyValue from '@salesforce/label/c.GeneralEmptyValue';
import nothingToMerge from '@salesforce/label/c.GeneralNothingToMerge';
import { stringIsNotBlank } from 'c/stringHelper';

export default class RecordMerger extends LightningElement {
    @api fieldResults = [];
    /*
    [{
        sourceFieldName: '',
        targetFieldName: '',
        sourceValue: '',
        targetValue: '',
        sourceValueIsNull : false,
        targetValueIsNull : false,
        sourceEqualTarget : false,
    }]
    */
    @api targetObject = null;
    @track hasRow = false;
    @track showLastColumn = false;

    get containerClass(){
        return this.showLastColumn ? 'container' : 'container-alt';
    }

    connectedCallback(){
        this.fieldResults.forEach(element => {
            if(!element.sourceEqualTarget){
                this.hasRow = true;
            }
            if(!element.sourceOrTargetEmpty && (element.isMultiPicklist || element.isTextArea)){
                this.showLastColumn = true;
            }
        });
    }
    label = {
        generalFields,
        generalLead,
        generalValue,
        mergeValues,
        emptyValue,
        nothingToMerge
    }

    handleRadioChange(event){
        let targetFieldApiName = event.target.dataset.targetfield;
        let targetValue = stringIsNotBlank(event.target.value) && event.target.value != 'undefined' ? event.target.value : '';
        if(this.fieldResults.isMultiPicklist && event.target.dataset.merge == 'merge'){
            let firstValues = event.target.dataset.firstvalue;
            let secondValues = event.target.dataset.secondvalue;
            let firstList = stringIsNotBlank(firstValues) ? firstValues.split(';') : [];
            let secondList = stringIsNotBlank(secondValues) ? secondValues.split(';') : [];
            firstList.forEach(element => {
                if(!secondList.includes(element)){
                    secondList.push(element);
                }
            });
            targetValue = secondList.join(';');
        } else if(this.fieldResults.isTextArea && event.target.dataset.merge == 'mergeTextarea'){
            let firstValue = event.target.dataset.firstvalue;
            let secondValue = event.target.dataset.secondvalue;
            targetValue = 'Lead:\r\n' + firstValue + '\r\n\r\n' + this.targetObject + ':\r\n' + secondValue;
        }
        this.dispatchEvent(new CustomEvent('fieldselection', { 
            detail: {
                field: targetFieldApiName,
                value: targetValue
            }
        }));
    }
}
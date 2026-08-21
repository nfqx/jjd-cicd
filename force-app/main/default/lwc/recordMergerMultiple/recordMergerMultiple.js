import { LightningElement, api, track } from 'lwc';
import generalFields from '@salesforce/label/c.GeneralFields';
import generalLead from '@salesforce/label/c.GeneralLead';
import mergeValues from '@salesforce/label/c.GeneralMergeValues';
import generalValue from '@salesforce/label/c.GeneralValue';
import emptyValue from '@salesforce/label/c.GeneralEmptyValue';
import nothingToMerge from '@salesforce/label/c.GeneralNothingToMerge';
import setAsMaster from '@salesforce/label/c.GeneralSetAsMasterRecord';
import { stringIsNotBlank } from 'c/stringHelper';

export default class RecordMergerMultiple extends LightningElement {
    @api fieldResults = [];
    @api recordNames = [];
    @api recordIds = [];
    @api masterId;
    
    @api targetObject = null;
    @track hasRow = false;
    @track showLastColumn = false;

    connectedCallback(){
        this.fieldResults.forEach(element => {
            if(!element.hideRow){
                this.hasRow = true;
                if(element.isMultiPicklist || element.isTextArea){
                    this.showLastColumn = true;
                }
            }
        });
    }
    label = {
        generalFields,
        generalLead,
        generalValue,
        mergeValues,
        emptyValue,
        nothingToMerge,
        setAsMaster
    }

    handleMasterChange(event){
        this.dispatchEvent(new CustomEvent('mainrecordchange', { 
            detail: {
                recordid: event.target.value
            }
        }));
    }

    handleRadioChange(event){
        let targetFieldApiName = event.target.dataset.targetfield;
        let targetValue = stringIsNotBlank(event.target.value) && event.target.value != 'undefined' ? event.target.value : '';
        if(event.target.dataset.merge == 'merge'){
            let initialValue = event.target.dataset.firstvalue;
            let remainingValues = event.target.dataset.secondvalue.split(';;;;;'); // to prevent semicolon accidental split for long text areas
            let firstList = stringIsNotBlank(initialValue) ? initialValue.split(';') : []; 
            remainingValues.forEach(element => {
                if(stringIsNotBlank(element) && element != 'null'){
                    let elemList = element.split(';');
                    elemList.forEach(innerElement => {
                        if(!firstList.includes(innerElement.value)){
                            firstList.push(innerElement.value);
                        }
                    });
                }
            });
            targetValue = firstList.join(';');
        } else if(event.target.dataset.merge == 'mergeTextarea'){
            let initialValue = event.target.dataset.firstvalue;
            let remainingValues = event.target.dataset.secondvalue.split(';;;;;'); // to prevent semicolon accidental split for long text areas
            console.log('remainingValues: ' + JSON.stringify(remainingValues));
            for(let i = 0; i < this.recordNames.length; i++){
                if(i == 0){
                    if(stringIsNotBlank(initialValue) && initialValue != 'null'){
                        targetValue = (this.recordNames[i] + ':\r\n' + initialValue);
                    }
                } else {
                    if(stringIsNotBlank(remainingValues[i-1]) && remainingValues[i-1] != 'null'){
                        if(stringIsNotBlank(targetValue)){
                            targetValue += '\r\n\r\n';
                        }
                        targetValue += (this.recordNames[i] + ':\r\n' + remainingValues[i-1]);
                    }
                }
            }
        }
        this.dispatchEvent(new CustomEvent('fieldselection', { 
            detail: {
                field: targetFieldApiName,
                value: targetValue
            }
        }));
    }
}
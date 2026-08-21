import { LightningElement, api, track } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getStaticSliderDataByName from '@salesforce/apex/WebshopDataController.getStaticSliderDataByName';
import getStaticSliderDataById from '@salesforce/apex/WebshopDataController.getStaticSliderDataById';
import getLexOriginUrl from '@salesforce/apex/WebshopDataController.getLexOriginUrl';

// Labels
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopStaticSlider extends LightningElement {
    @api sliderName;
    @api sliderId;
    @track sliderData = [];
    @track showSlider = false;

    label = {
        generalError,
        generalErrorMsg
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        let lexOriginUrl = sessionStorage.getItem('darboven_lexOriginUrl');
        if(!stringIsNotBlank(lexOriginUrl)){
            getLexOriginUrl({})
            .then(outerResult => {
                if(outerResult != null){
                    sessionStorage.setItem('darboven_lexOriginUrl', outerResult);
                    this.processData(outerResult);
                } else {
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                }
            })
            .catch(error => {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;});
            });
        } else {
            this.processData(lexOriginUrl);
        }
    }

    processData(outerResult){
        if(stringIsNotBlank(this.sliderName)){
            getStaticSliderDataByName({
                staticSliderName : this.sliderName
            })
            .then(result => {
                if(result != null){
                    this.sliderData = JSON.parse(JSON.stringify(result));
                    this.sliderData.forEach(sliderItem => {
                        sliderItem.Image__c = stringIsNotBlank(sliderItem.Image__c) ? sliderItem.Image__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
                    })
                    this.showSlider = true;
                } else {
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                }
            })
            .catch(error => {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            });
        } else if(stringIsNotBlank(this.sliderId)){
            getStaticSliderDataById({
                staticSliderId : this.sliderId
            })
            .then(result => {
                if(result != null){
                    this.sliderData = JSON.parse(JSON.stringify(result));
                    this.sliderData.forEach(sliderItem => {
                        sliderItem.Image__c = stringIsNotBlank(sliderItem.Image__c) ? sliderItem.Image__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
                    })
                    this.showSlider = true;
                } else {
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                }
            })
            .catch(error => {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            });
        }
    }
}
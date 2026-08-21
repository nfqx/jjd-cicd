import { LightningElement, api, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getFeaturedAdById from '@salesforce/apex/WebshopDataController.getFeaturedAdById';
import getFeaturedAdByName from '@salesforce/apex/WebshopDataController.getFeaturedAdByName';
import getLexOriginUrl from '@salesforce/apex/WebshopDataController.getLexOriginUrl';
import { stringIsNotBlank } from 'c/stringHelper';

// LABELS
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopFeaturedAd extends LightningElement {
    @track featuredAd;
    @track hasFeaturedAd = false;
    @track hasButton = false;
    @api featuredAdId;
    @api featuredAdName;
    @api styleName;
    @api fromBrandPage = false;

    label = {
        generalError,
        generalErrorMsg
    }
    get className(){
        return 'featured-ad-' + this.styleName;
    }
    get showButton(){
        return this.hasButton && !this.fromBrandPage;
    }
    get target(){
        return this.fromBrandPage ? '#' : (stringIsNotBlank(this.featuredAd?.Target__c) ? this.featuredAd.Target__c : '#');
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle)
        let lexOriginUrl = sessionStorage.getItem('darboven_lexOriginUrl');
        if(!stringIsNotBlank(lexOriginUrl)){
            getLexOriginUrl({})
            .then(outerResult => {
                sessionStorage.setItem('darboven_lexOriginUrl', outerResult);
                this.processData(outerResult);
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
        if(outerResult != null){
            if(stringIsNotBlank(this.featuredAdId)){
                getFeaturedAdById({
                    featuredAdId : this.featuredAdId
                })
                .then(result => {
                    if(result != null){
                        this.featuredAd = JSON.parse(JSON.stringify(result));
                        this.featuredAd.Image__c = stringIsNotBlank(this.featuredAd.Image__c) ? this.featuredAd.Image__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
                        this.hasButton = stringIsNotBlank(this.featuredAd.ButtonLabel__c) && stringIsNotBlank(this.featuredAd.Target__c);
                        this.hasFeaturedAd = result != null;
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
            } else if(stringIsNotBlank(this.featuredAdName)) {
                getFeaturedAdByName({
                    featuredAdName : this.featuredAdName
                })
                .then(result => {
                    if(result != null){
                        this.featuredAd = JSON.parse(JSON.stringify(result));
                        this.featuredAd.Image__c = stringIsNotBlank(this.featuredAd.Image__c) ? this.featuredAd.Image__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
                        this.hasButton = stringIsNotBlank(this.featuredAd.ButtonLabel__c) && stringIsNotBlank(this.featuredAd.Target__c);
                        this.hasFeaturedAd = result != null;
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
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
        }
    }
}
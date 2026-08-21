import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getBrandData from '@salesforce/apex/WebshopDataController.getBrandData';
import getLexOriginUrl from '@salesforce/apex/WebshopDataController.getLexOriginUrl';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Labels
import home from '@salesforce/label/c.GeneralHome';
import myBrands from '@salesforce/label/c.WebshopMyBrands';
import topProducts from '@salesforce/label/c.WebshopTopProducts';
import topProductsSubheader from '@salesforce/label/c.WebshopTopProductsSubheader';
import viewAllProducts from '@salesforce/label/c.WebshopViewAllProducts';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import hasNoProducts from '@salesforce/label/c.WebshopHasNoProducts';
import accessoriesSubheader from '@salesforce/label/c.WebshopAccessoriesSubheader';
import accessoriesHeader from '@salesforce/label/c.WebshopAccessoriesHeader';

export default class WebshopBrandPage extends NavigationMixin(LightningElement)  {
    @track recordId;
    @track lastRecordId;
    @track gettingData = false;
    @track showData = false;
    @track brandLoaded = false;
    @track brandData;
    @track brandImage;
    @track hasStaticSlider = false;
    @track hasFeaturedAd = false;
    @track hasProducts = null;
    @track hasAccessories = null;

    label = {
        home,
        myBrands,
        topProducts,
        topProductsSubheader,
        viewAllProducts,
        generalError,
        generalErrorMsg,
        hasNoProducts,
        accessoriesSubheader,
        accessoriesHeader
    }
    path = [
        {
            label: this.label.myBrands,
            value: '',
            hasLink: false
        }
    ];

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.lastRecordId = this.recordId;
        this.recordId = window.location.href.replaceAll('/detail', '').split("/").pop();
        if(this.lastRecordId != this.recordId){
            loadStyle(this, BOOTSTRAP )
            if(!this.gettingData){
                this.getData();
            }
        }
    }

    connectedCallback(){
        this.connected = true;
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        this.lastRecordId = this.recordId;
        this.recordId = window.location.href.replaceAll('/detail', '').split("/").pop();
        if(this.lastRecordId != this.recordId){
            if(!this.gettingData){
                this.getData();
            }
        }
    }

    getData(){
        this.gettingData = true;
        this.showData = false;
        let lexOriginUrl = sessionStorage.getItem('darboven_lexOriginUrl');
        if(!stringIsNotBlank(lexOriginUrl)){
            getLexOriginUrl({})
            .then(outerResult => {
                if(outerResult != null){
                    sessionStorage.setItem('darboven_lexOriginUrl', outerResult);
                    this.processData(outerResult);
                } else {
                    this.gettingData = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                }
            })
            .catch(error => {
                this.gettingData = false;
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
        getSessionContext()
        .then(sessionContext => {
            this.accountId = sessionContext.effectiveAccountId;
            if(this.recordId != null && this.accountId != null){
                getBrandData({recordId : this.recordId})
                .then(result => {
                    if(result != null){
                        this.brandData = JSON.parse(JSON.stringify(result));
                        this.hasStaticSlider = stringIsNotBlank(result.WebshopStaticSlider__c);
                        this.hasFeaturedAd = stringIsNotBlank(result.WebshopFeaturedAd__c);
                        this.brandText = stringIsNotBlank(this.brandData.BrandText__c) ? this.brandData.BrandText__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
                        this.brandImage = stringIsNotBlank(this.brandData.BrandLogo__c) ? this.brandData.BrandLogo__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
                        this.brandLoaded = true;
                        let self = this;
                        setTimeout(function (){
                            document.title = 'Brand: ' + self.brandData.Name;
                        }, 500);
                        this.showData = true;
                        this.gettingData = false;
                    } else {
                        this.gettingData = false;
                        setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                            title: this.label.generalError,
                            message: this.label.generalErrorMsg,
                            variant: 'error',
                        };
                        this.template.querySelector('c-webshop-toast').show = true;}); 
                    }
                })
                .catch(error => {
                    this.gettingData = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else {
                this.gettingData = false;
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
        })
        .catch(error => {
            this.gettingData = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    handleClickHome(){
        window.location.assign('/');
    }

    handleNoAccessories(){
        this.hasAccessories = false;
    }
    handleHasAccessories(){
        this.hasAccessories = true;
    }
    handleNoProducts(){
        this.hasProducts = false;
    }
    handleHasProducts(){
        this.hasProducts = true;
    }

    handleClickViewAll(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Brand_Products__c',
            },
            state: {
                c__recordId: this.recordId
            }
        });
    }
}
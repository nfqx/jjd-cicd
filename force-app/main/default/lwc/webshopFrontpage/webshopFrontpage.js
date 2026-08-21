import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub'

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Commerce API
import { getSessionContext } from 'commerce/contextApi'
import { effectiveAccount } from 'commerce/effectiveAccountApi';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getAccountSwitcherOptions from '@salesforce/apex/WebshopDataController.getAccountSwitcherOptions';
import getAccountWarning from '@salesforce/apex/WebshopDataController.getAccountWarning';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import topPicksSlider from '@salesforce/label/c.WebshopDoNotTranslateTopPicks';
import buyAgainSlider from '@salesforce/label/c.WebshopDoNotTranslateBuyAgain';
import frontpageSlider from '@salesforce/label/c.WebshopDoNotTranslateFrontpage';
//import goodMorning from '@salesforce/label/c.WebshopFrontpageGoodMorning';
//import goodAfternoon from '@salesforce/label/c.WebshopFrontpageGoodAfternoon';
//import goodEvening from '@salesforce/label/c.WebshopFrontpageGoodEvening';
import onBehalf from '@salesforce/label/c.WebshopFrontpageOnBehalf';
import topProductsTitle from '@salesforce/label/c.WebshopFrontpageTopProductsTitle';
import topProductsSubtitle from '@salesforce/label/c.WebshopFrontpageTopProductsSubTitle';
import buyAgainTitle from '@salesforce/label/c.WebshopFrontpageBuyAgainTitle';
import buyAgainSubtitle from '@salesforce/label/c.WebshopFrontpageBuyAgainSubTitle';
import hello from '@salesforce/label/c.GeneralHello';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import searchAccounts from '@salesforce/label/c.GeneralSearchAccounts';

import { stringIsNotBlank } from 'c/stringHelper';

export default class WebshopFrontpage extends  NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId = null;
    @track accountOptions = [];
    @track firstName;
    @track dataLoaded = false;
    @track hasMultipleOptions = false;
    @track showSliderHeadingOne = false;
    @track showSliderHeadingTwo = false;
    @track accountWarning = 'null';
    @track searchTerm = '';
    @track showOptions = false;
    @track filteredOptions = [];

    label = {
        topPicksSlider,
        buyAgainSlider,
        frontpageSlider,
        //goodMorning,
        //goodAfternoon,
        //goodEvening,
        onBehalf,
        topProductsTitle,
        topProductsSubtitle,
        buyAgainTitle,
        buyAgainSubtitle,
        hello,
        generalError,
        generalErrorMsg,
        searchAccounts
    };

    /*
    get greeting(){
        let d = new Date();
        let hour = d.getHours();
        if(hour >= 0 && hour < 12){
            return this.label.goodMorning;
        } else if(hour < 18){
            return this.label.goodAfternoon;
        } else {
            return this.label.goodEvening;
        }
    }
    */

    get showAccountWarning(){
        return stringIsNotBlank(this.accountWarning) && this.accountWarning != 'null';
    }

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;
                this.firstName = sessionContext?.profile?.firstName;
                let accountWarning = sessionStorage.getItem('darboven_accountWarning');
                if(stringIsNotBlank(accountWarning)){
                    if(accountWarning != 'null'){
                        this.accountWarning = accountWarning;
                    }
                    this.getBaseInfo(false);
                } else {
                    getAccountWarning({accountId: this.accountId})
                    .then(result => {
                        this.accountWarning = result;
                        sessionStorage.setItem('darboven_accountWarning', result);
                        this.getBaseInfo(false);
                    });
                }
            } else {
                this.getBaseInfo(true);
            }
        })
        .catch(error => {
            this.getBaseInfo(true);
        });
    }

    getBaseInfo(setAccount){
        getAccountSwitcherOptions({accountId: this.accountId})
        .then(innerResult => {
            if(innerResult != null){
                this.accountOptions = [...innerResult.accountOptions];
                this.mainAccountOption = innerResult.mainAccountOption;
                this.filteredOptions = [...this.accountOptions];
                this.hasMultipleOptions = this.accountOptions.length > 0;
                this.dataLoaded = true;
                if(setAccount && this.accountOptions.length > 0){
                    sessionStorage.clear();
                    getCartSummaryOrCreateCart({accountId: this.accountOptions[0].value})
                    .then(result => {
                        sessionStorage.setItem('darboven_cartId', result);
                        fireEvent(this.pageRef, 'setCartIdEvent', {  });
                        effectiveAccount.update(this.accountOptions[0].value, this.accountOptions[0].label);
                        window.location.reload();
                    });
                }
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

    handleSearch(event) {
        this.searchTerm = event.target.value;

        this.filteredOptions = this.accountOptions.filter(opt =>
            opt.label.toLowerCase().includes(this.searchTerm.toLowerCase())
        );

        this.showOptions = true;
    }

    showDropdown() {
        this.showOptions = true;
    }

    handleSelect(event) {
        this.accountId = event.currentTarget.dataset.value;
        this.searchTerm = event.currentTarget.dataset.label;
        this.showOptions = false;
        this.handleChangeAccOption();
    }

    handleChangeAccOption(event){
        let newAccName = this.accountOptions.find(opt => opt.value === this.accountId).label;
        if(stringIsNotBlank(this.accountId) && stringIsNotBlank(newAccName)){ 
            sessionStorage.clear();
            getCartSummaryOrCreateCart({accountId: this.accountId})
            .then(result => {
                sessionStorage.setItem('darboven_cartId', result);
                fireEvent(this.pageRef, 'setCartIdEvent', {  });
                effectiveAccount.update(this.accountId, newAccName);
                window.location.reload();
            });
        }
    }

    showHeadingOne(){
        this.showSliderHeadingOne = true;
    }

    showHeadingTwo(){
        this.showSliderHeadingTwo = true;
    }

    
}
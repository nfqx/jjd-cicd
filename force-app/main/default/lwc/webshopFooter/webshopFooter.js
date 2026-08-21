import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import JJD_LOGO from "@salesforce/resourceUrl/JJDLogo";
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import { stringIsNotBlank } from 'c/stringHelper';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getIcons from '@salesforce/apex/WebshopDataController.getIcons';
import getLexOriginUrl from '@salesforce/apex/WebshopDataController.getLexOriginUrl';

// LABELS
import socialMedia from '@salesforce/label/c.WebshopSocialMedia';
import weAreCertified from '@salesforce/label/c.WebshopWeAreCertified';
import contact from '@salesforce/label/c.GeneralHelpAndContact';
import contactEmail from '@salesforce/label/c.WebshopContactEmail';
import contactPhone from '@salesforce/label/c.WebshopContactPhone';
import privacyPolicy from '@salesforce/label/c.WebshopFooterPrivacyPolicy';
import termsOfService from '@salesforce/label/c.WebshopFooterTermsOfService';
import cookieSettings from '@salesforce/label/c.WebshopFooterCookieSettings';
import legalInformation from '@salesforce/label/c.WebshopFooterLegalInformation';
import allRightsReserved from '@salesforce/label/c.WebshopFooterAllRightsReserved';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopFooter extends NavigationMixin(LightningElement) {
    @track hasCertifiedIcons = false;
    @track certifiedIcons = [];
    @track hasSocialIcons = false;
    @track socialIcons = []; 

    jjdLogo = JJD_LOGO;

    label = {
        contact,
        socialMedia,
        weAreCertified,
        contactEmail,
        contactPhone,
        privacyPolicy,
        termsOfService,
        cookieSettings,
        legalInformation,
        allRightsReserved,
        generalError,
        generalErrorMsg
    }

    get year(){
        return new Date().getFullYear();
    }

    handleContactUs(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.show = true;
        });
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
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
            let iconsOne = sessionStorage.getItem('darboven_iconsOne');
            if(!stringIsNotBlank(iconsOne)){
                getIcons({iconCategory: 'certifications'})
                .then(result => {
                    if(result != null){            
                        sessionStorage.setItem('darboven_iconsOne', JSON.stringify(result));
                        this.processCertifiedIcons(result, outerResult);
                    }
                })
            } else {
                this.processCertifiedIcons(JSON.parse(iconsOne), outerResult);
            }

            let iconsTwo = sessionStorage.getItem('darboven_iconsTwo');
            if(!stringIsNotBlank(iconsTwo)){
                getIcons({iconCategory: 'social'})
                .then(result => {
                    if(result != null){
                        sessionStorage.setItem('darboven_iconsTwo', JSON.stringify(result));
                        this.processSocialIcons(result, outerResult);
                    }
                })
            } else {
                this.processSocialIcons(JSON.parse(iconsTwo), outerResult);
            }
        }
    }

    processSocialIcons(result, outerResult){
        this.hasSocialIcons = result.length > 0;
        this.socialIcons = JSON.parse(JSON.stringify(result));
        this.socialIcons.forEach(icon => {
            icon.Image__c = stringIsNotBlank(icon.Image__c) ? icon.Image__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
        });
    }

    processCertifiedIcons(result, outerResult){
        this.hasCertifiedIcons = result.length > 0;
        this.certifiedIcons = JSON.parse(JSON.stringify(result));
        this.certifiedIcons.forEach(icon => {
            icon.Image__c = stringIsNotBlank(icon.Image__c) ? icon.Image__c.replaceAll('/lwrshopvforcesite', outerResult) : '';
        });
    }

    handleRedirectPage(event){
        let pageName = event.currentTarget.dataset.pagename;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageName,
            }
        });
    }

    get contactEmailMailto(){
        return 'mailto:' + this.label.contactEmail;
    }
}
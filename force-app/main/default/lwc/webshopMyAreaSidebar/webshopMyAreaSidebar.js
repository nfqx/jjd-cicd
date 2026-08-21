import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Core
import { getSessionContext } from 'commerce/contextApi';

// Apex
import retrieveFTPInfo from '@salesforce/apex/WebshopDataController.retrieveFTPInfo';

// LABELS
import menuHome from '@salesforce/label/c.WebshopMenuHome';
import menuWishlist from '@salesforce/label/c.WebshopMenuWishlist';
import menuOrders from '@salesforce/label/c.WebshopMenuOrders';
import menuInvoices from '@salesforce/label/c.WebshopMenuInvoices';
import menuTeam from '@salesforce/label/c.WebshopMenuTeam';
import menuOutlets from '@salesforce/label/c.WebshopMenuOutlets';
import menuSettings from '@salesforce/label/c.WebshopMenuSettings';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import menuUploadOrder from '@salesforce/label/c.WebshopUploadOrder';

export default class WebshopMyAreaSIdebar extends NavigationMixin(LightningElement) {
    @api activeElement;
    @track navItems = [];
    @track loaded = false;

    label = {
        menuHome,
        menuWishlist,
        menuOrders,
        menuInvoices,
        menuTeam,
        menuOutlets,
        menuSettings,
        generalError,
        generalErrorMsg,
        menuUploadOrder
    }

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
                retrieveFTPInfo({accountId: this.accountId})
                .then(result => {
                    let menuItems =  [
                        {icon: '', label: this.label.menuHome , pageName: 'My_Account__c', isActive : this.activeElement == 'My_Account__c'},
                        {icon: '', label: this.label.menuWishlist, pageName: 'My_Wishlist__c', isActive : this.activeElement == 'My_Wishlist__c'},
                        {icon: '', label: this.label.menuOrders, pageName: 'My_Orders__c', isActive : this.activeElement == 'My_Orders__c'}
                    ];
                    if(result == true){
                        menuItems.push(
                            {icon: '', label: this.label.menuUploadOrder, pageName: 'Upload_Order__c', isActive : this.activeElement == 'Upload_Order__c'}
                        );
                    }
                    menuItems.push(
                        {icon: '', label: this.label.menuInvoices, pageName: 'My_Invoices__c', isActive : this.activeElement == 'My_Invoices__c'},
                        {icon: '', label: this.label.menuTeam, pageName: 'Team_Members__c', isActive : this.activeElement == 'Team_Members__c'},
                        {icon: '', label: this.label.menuOutlets, pageName: 'My_Outlets__c', isActive : this.activeElement == 'My_Outlets__c'},
                        {icon: '', label: this.label.menuSettings, pageName: 'My_Account_Settings__c', isActive : this.activeElement == 'My_Account_Settings__c'},
                    );
                    this.navItems = JSON.parse(JSON.stringify(menuItems));
                    this.loaded = true;
                })
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

    handleNavItemClick(event) {
        let pageName = event.currentTarget.dataset.pagename;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageName,
            }
        });
    }
}
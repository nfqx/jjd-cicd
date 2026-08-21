import { LightningElement, track, wire } from 'lwc';
import JJD_LOGO from "@salesforce/resourceUrl/JJDLogo";
import { registerListener } from 'c/pubsub'
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// LABELS
import helpText from '@salesforce/label/c.GeneralHelp';
import myAccount from '@salesforce/label/c.WebshopMyAccount';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import cart from '@salesforce/label/c.WebshopCart';
import favourites from '@salesforce/label/c.webshopFavourites';
import logout from '@salesforce/label/c.WebshopLogout';
import refreshCartInMs from '@salesforce/label/c.WebshopDoNotTranslateRefreshCartInMs';


export default class webshopCustomHeader extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track firstName;
    @track showIcons = false;
    @track showWishlistCount = false;
    @track showDoubleOptInModal = false;
    @track showExtendedHeader = false;
    @track showMegaMenu = false;
    @track isMobileMenuOpen = false; // New track variable to manage mobile menu visibility
    @track isSearchOpen = false; 
    @track isLoggedIn = false;

    get notLoggedIn(){
        return !this.isLoggedIn;
    }

    jjdLogo = JJD_LOGO;

    label = {
        helpText,
        myAccount,
        generalError,
        generalErrorMsg,
        cart,
        favourites,
        logout,
        refreshCartInMs
    }

    handleLogout(){
        sessionStorage.clear();
        window.location.assign('https://' + window.location.hostname + '/secur/logout.jsp');
    }

    connectedCallback() {
        registerListener('recalcCartItemsEvent', this.handleRecalc, this);
        registerListener('refreshCartEvent', this.handleRefreshCart, this);
        registerListener('addToWishlistEvent', this.handleAddedToWishlist, this);
        registerListener('removeFromWishlistEvent', this.handleRemovedFromWishlist, this);

        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);

        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                // Show just means logged in here. Whether the modal is actually shown, is part of the modal logic.
                this.firstName = sessionContext?.profile?.firstName;
                this.isLoggedIn = true;
                this.accountId = sessionContext.effectiveAccountId;
                this.showWishlistCount = true;
                this.showDoubleOptInModal = true;
                this.showExtendedHeader = true;
                this.showIcons = true;
                this.showMegaMenu = true;
            }
        })
        .catch(error => {
            console.log(JSON.stringify(error));
            // No Session Context
        });
    }

    handleClickLogo(){
        window.location.assign('/');
    }

    // New function to toggle the mobile menu
    toggleMobileMenu() {
        this.isMobileMenuOpen = !this.isMobileMenuOpen;
    }

    toggleSearch() {
        this.isSearchOpen = !this.isSearchOpen;
    }

    handleOpenCart(){
        this.template.querySelectorAll('c-webshop-cart-modal').forEach(element => {
            element.show = true;
        });
        this.isMobileMenuOpen = false;
    }

    handleAddedToWishlist(event){
        this.template.querySelectorAll('c-webshop-wishlist-count[data-type="Wishlist"]').forEach(element => {
            element.increase();
        });        
    }

    handleRemovedFromWishlist(event){
        this.template.querySelectorAll('c-webshop-wishlist-count[data-type="Wishlist"]').forEach(element => {
            element.decrease();
        });        
    }

    handleRecalc(event){
        this.template.querySelectorAll('c-webshop-wishlist-count[data-type="Cart"]').forEach(element => {
            element.recalc();
        });
    }

    handleRefreshCart(event){
        let self = this;
        setTimeout(function(){
            self.template.querySelectorAll('c-webshop-wishlist-count[data-type="Cart"]').forEach(element => {
                element.recalc();
            });
            self.template.querySelectorAll('c-webshop-cart-modal').forEach(element => {
                element.recalc();
            });
        }, parseInt(this.label.refreshCartInMs));
    }

    handleContactUs(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.show = true;
        });
        this.isMobileMenuOpen = false;
    }
    handleOpenWishlist(event) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Wishlist__c',
            }
        })
        this.isMobileMenuOpen = false;
    }
    handleOpenMyAccount(event) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Account__c',
            }
        });
        this.isMobileMenuOpen = false;
    }

    closeDropdown(){
        this.template.querySelectorAll('c-webshop-mega-menu').forEach(element => {
            element.closeDropdown();
        });
    }

    // Additional styling class to control display of mobile menu based on isMobileMenuOpen
    get mobileMenuClass() {
        return this.isMobileMenuOpen ? 'mobile-menu-overlay d-sm-none d-block' : 'mobile-menu-overlay d-sm-none';
    }
/*
    get mobileIconsClass() {
        return this.isSearchOpen ? "col-8 d-flex justify-content-evenly d-sm-none" :"col-8 d-flex justify-content-evenly d-sm-none";
    }

    get searchClass() {
        return this.isSearchOpen ? "col-12 d-flex d-sm-none align-items-center" :"d-none";
    }
   */     
}
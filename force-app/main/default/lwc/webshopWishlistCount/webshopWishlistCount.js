import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import { registerListener } from 'c/pubsub'
import { CurrentPageReference } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Apex
import getWishlistCount from '@salesforce/apex/WebshopDataController.getWishlistCount';
import countItemsInCart from '@salesforce/apex/WebshopDataController.countItemsInCart';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopWishlistCount extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track wishlistCount = 0;
    @track hasWishlistCount = false;
    @track accountId = null;
    @track cartId = null;
    @api type;

    @api increase(){
        this.wishlistCount++;
        this.hasWishlistCount = true;
    }
    @api decrease(){
        this.wishlistCount = this.wishlistCount > 0 ? this.wishlistCount - 1 : 0;
        this.hasWishlistCount = this.wishlistCount > 0;
    }

    @api
    recalc(){
        this.hasWishlistCount = false;
        countItemsInCart({accountId: this.accountId, cartId: this.cartId})
        .then(result => {
            this.wishlistCount = result;
            this.hasWishlistCount = this.wishlistCount > 0;
        })
    }

    label = {
        generalError,
        generalErrorMsg
    }

    platformSetCartId(event){
        this.cartId = sessionStorage.getItem('darboven_cartId');
        this.processData();
    }

    connectedCallback() {
        registerListener('setCartIdEvent', this.platformSetCartId, this);

        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP );
        getSessionContext()
        .then(sessionContext => {
            this.accountId = sessionContext.effectiveAccountId;
            if(stringIsNotBlank(this.accountId)){
                this.cartId = sessionStorage.getItem('darboven_cartId');
                this.processData();
            }
        })
        .catch(error => {
            console.log(error);
            this.wishlistCount = 0;
            this.hasWishlistCount = false;
        });
    } 

    processData(){
        if(this.type == 'Cart'){
            this.recalc();
        } else {
            getWishlistCount({accountId: this.accountId})
            .then(result => {
                if(result != null){
                    this.wishlistCount = result;
                    this.hasWishlistCount = this.wishlistCount > 0;
                } else {
                    this.wishlistCount = 0;
                    this.hasWishlistCount = false;
                }
            })
            .catch(error => {
                console.log(error);
                this.wishlistCount = 0;
                this.hasWishlistCount = false;
            });
        }
    }

    handleClick(event){
        this[NavigationMixin.GenerateUrl]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Wishlist__c',
            }
        }).then((url) => {
            window.open(url, '_blank');
        });
    }
}
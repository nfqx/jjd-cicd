import { LightningElement, track, wire } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub'

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Apex
import getCartPromoValue from '@salesforce/apex/WebshopDataController.getCartPromoValue';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

export default class WebshopCartRefresher extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    @track cartId = null;
    @track promoValue = 0;
    @track promoInitialized = false;
    
    connectedCallback() {
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
                let cartId = sessionStorage.getItem('darboven_cartId');
                if(!stringIsNotBlank(cartId) || cartId == 'null'){
                    getCartSummaryOrCreateCart({accountId: this.accountId})
                    .then(result => {
                        sessionStorage.setItem('darboven_cartId', result);
                        fireEvent(this.pageRef, 'setCartIdEvent', {  });
                        this.cartId = result;
                        this.setCheckInterval();
                    });
                } else {
                    this.cartId = cartId;
                    this.setCheckInterval();
                }
            }
        });
    }

    setCheckInterval(){
        setInterval(() => {
            getCartPromoValue({cartId: this.cartId})
            .then(result => {
                let oldPromoValue = this.promoValue;
                this.promoValue = result;
                if(oldPromoValue != this.promoValue){
                    if(this.promoInitialized){
                        window.location.reload();
                    }
                }
                if(!this.promoInitialized){
                    this.promoInitialized = true;
                } 
            })
        }, 5000);
    }
}
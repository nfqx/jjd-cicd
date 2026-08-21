import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import { registerListener } from 'c/pubsub'
import { CurrentPageReference } from 'lightning/navigation';

// BOOTSTRAP
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// LABELS
import itemsAddedToCart from '@salesforce/label/c.WebshopItemsAddedToCart';
import continueShopping from '@salesforce/label/c.WebshopOrderConfirmationContinueShopping';
import viewCart from '@salesforce/label/c.WebshopViewCart';
import myCart from '@salesforce/label/c.WebshopMyShoppingCart';
import productsRelatedTo from '@salesforce/label/c.WebshopProductsRelatedTo';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class webshopCartModal extends  NavigationMixin(LightningElement)  {
    @wire(CurrentPageReference) pageRef;
    @track _show = false;  
    @api
    get show() {
      return this._show;
    }
    set show(value) {
      this._show = value;
    }

    @track productIdAndCode = '';     
    @track _productId = '';     
    @track _productCode = '';      
    @track _productSlider = '';     
    @track _productBrand = ''; 
    @track cartId = null; 
    @api
    get productid() {
      return this.productIdAndCode;
    }
    set productid(value) {
      this.showNote = false;
      this.showRelated = false;
      this.productIdAndCode = value;
      if(stringIsNotBlank(value) && value.includes('___')){
        this._productId = value.split('___')[0];
        this._productCode = value.split('___')[1];
        this._productSlider = value.split('___')[2];
        this._productBrand = value.split('___')[3];
        this.showNote = true;
        this.showRelated = true;
        this.template.querySelectorAll('c-webshop-cart-product-summary').forEach(element => {
            element.refreshCartData();
        });
      }
    }

    @track _productname = '';
    @api
    get productname() {
      return this._productname;
    }
    set productname(value) {
      this._productname = value;
    }

    @track _newitems = 0;     
    @api
    get newitems() {
      return this._newitems;
    }
    set newitems(value) {
      this._newitems = value;
    }

    @api recalc(){
      this.template.querySelectorAll('c-webshop-cart-product-summary').forEach(element => {
          element.recalc();
      });
    }

    @track accountId;
    @track showNote = false;
    @track showCart = true;
    @track showRelated = false;
    @track cartCount = 0;
    @track showSliderHeading = false;

    label = {
        itemsAddedToCart,
        continueShopping,
        viewCart,
        myCart,
        productsRelatedTo,
        generalError,
        generalErrorMsg
    }
    
    platformSetCartId(event){
      this.cartId = sessionStorage.getItem('darboven_cartId');
    }

    connectedCallback() {
        registerListener('setCartIdEvent', this.platformSetCartId, this);
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
        getSessionContext()
        .then(sessionContext => {
          if(sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
            this.accountId = sessionContext.effectiveAccountId;
            this.cartId = sessionStorage.getItem('darboven_cartId');
          } else {
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ' error1',
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
          }
        })
        .catch(error => {
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ' error2: ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }

    showHeading(){
      this.showSliderHeading = true;
    }   

    handleViewCart(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Current_Cart',
            }
        });
        this.show = false;
    }

    handleClose(){
        this._show = false;
        this.showRelated = false;
        this.showNote = false;
        this.newitems = 0;
    }

}
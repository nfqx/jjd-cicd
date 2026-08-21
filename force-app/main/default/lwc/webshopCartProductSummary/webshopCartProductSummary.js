import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub'
import { stringIsNotBlank } from 'c/stringHelper';
import { registerListener } from 'c/pubsub'

// BOOTSTRAP
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// APEX
import getCartItems from '@salesforce/apex/WebshopDataController.getCartItems';
import removeItemFromCart from '@salesforce/apex/WebshopDataController.removeItemFromCart';
import changeCartQuantity from '@salesforce/apex/WebshopDataController.changeCartQuantity';
import addProductToWishlist from '@salesforce/apex/WebshopDataController.addProductToWishlist';
import removeFromWishlist from '@salesforce/apex/WebshopDataController.removeFromWishlist';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';

// LABELS
import noProducts from '@salesforce/label/c.WebshopCartNoProducts';
import shippingProductCodes from '@salesforce/label/c.ShippingProductCodes';
import checkout from '@salesforce/label/c.WebshopCheckout';
import shipping from '@salesforce/label/c.WebshopOrderConfirmationShipping';
import subtotal from '@salesforce/label/c.WebshopOrderConfirmationSubtotal';
import total from '@salesforce/label/c.WebshopOrderConfirmationTotal';
import free from '@salesforce/label/c.GeneralFree';
import emptyCart from '@salesforce/label/c.WebshopEmptyCart';
import shippingCostsWithPricesOne from '@salesforce/label/c.WebshopShippingCostsWithPricesOne';
import shippingCostsWithPricesTwo from '@salesforce/label/c.WebshopShippingCostsWithPricesTwo';
import shippingCostsWithoutPrices from '@salesforce/label/c.WebshopShippingCostsWithoutPrices';
import shippingCost from '@salesforce/label/c.WebshopDoNotTranslateShippingCost';
import shippingFreeThreshold from '@salesforce/label/c.WebshopDoNotTranslateShippingFreeThreshold';
import promotions from '@salesforce/label/c.GeneralPromotions';
import maxBoxCount from '@salesforce/label/c.WebshopDoNotTranslateMaxBoxCount';
import maxPaletteCount from '@salesforce/label/c.WebshopDoNotTranslateMaxPaletteCount';
import box from '@salesforce/label/c.GeneralBox';
import boxes from '@salesforce/label/c.GeneralBoxes';
import palette from '@salesforce/label/c.GeneralPalette';
import palettes from '@salesforce/label/c.GeneralPalettes';
import piece from '@salesforce/label/c.GeneralPiece';


export default class WebshopCartProductSummary extends  NavigationMixin(LightningElement)  {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track cartData = [];
    @track hasCartData = false;
    @track showPrices = true;
    @api hideProducts = false;
    @api showShippingText = false;
    @api showSubtotal = false;
    @api showShipping = false;
    @api showTotal = false;
    @api hideInputs = false;
    @api showEmptyCartMessage = false;
    @api noReloadAfterChange = false;
    @api delayedLoad = false;
    @track subtotalPromo = 0;
    @track subtotalLine = 0;
    @track shipping = 0;
    @track total = 0;
    @track currencyIsoCode = '€';
    @track isLoading = false;
    @track isLoadingInner = false;
    @track cartId = null;
    @track oneToHundredOptions = [];


    label = {
        noProducts,
        checkout,
        shippingProductCodes,
        shipping,
        subtotal,
        total,
        free,
        emptyCart,
        shippingCostsWithPricesOne,
        shippingCostsWithPricesTwo,
        shippingCostsWithoutPrices,
        shippingCost,
        shippingFreeThreshold,
        promotions,
        maxBoxCount,
        maxPaletteCount,
        box,
        boxes,
        palette,
        palettes,
        piece
    }

    get shippingCostsWithPricesOne(){
        return this.label.shippingCostsWithPricesOne.replace('{0}', this.label.shippingFreeThreshold).replace('{1}', this.label.shippingCost)
    }

    get showPromotions(){
        return this.subtotalPromo != 0;
    }

    platformSetCartId(event){
        this.cartId = sessionStorage.getItem('darboven_cartId');
        this.processData();
    }

    connectedCallback() {
        registerListener('setCartIdEvent', this.platformSetCartId, this);
        registerListener('refreshCartDataEvent', this.refreshCartData, this);
        this.isLoading = true;
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
        this.oneToHundredOptions = [];
        for(let i = 1; i < 201; i++){
            let innerObj = {
                label: i.toString(),
                value: i
            };
            this.oneToHundredOptions.push(innerObj);
        }
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
                this.cartId = sessionStorage.getItem('darboven_cartId');
                this.processData();
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
                message: this.label.generalErrorMsg,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    processData(){
        let showPriceInfo = sessionStorage.getItem('darboven_showPriceInfo');
        if(!stringIsNotBlank(showPriceInfo)){
            getShowPriceInfo({accountId: this.accountId})
            .then(outerResult => {
                if(outerResult != null){
                    this.showPrices = outerResult;
                    sessionStorage.setItem('darboven_showPriceInfo', this.showPrices);
                    this.initData();
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
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            });
        } else {
            this.showPrices = showPriceInfo === true || showPriceInfo == 'true' ? true : false;
            this.initData();
        }
    }

    initData(){
        if(!this.delayedLoad){
            this.getCartItems();
        } else {
            let self = this;
            setTimeout(() => {
                self.getCartItems();
            }, 500);
        }
    }

    @api recalc(){
        this.getCartItems();
    }

    getCartItems(){
        getCartItems({accountId: this.accountId, cartId: this.cartId})
        .then(result => {
            if(result != null){
                console.log(JSON.stringify(result));
                this.processCartData(JSON.parse(JSON.stringify(result)));
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
                message: this.label.generalErrorMsg,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    processCartData(result){
        this.hasCartData = null;
        let shippingProductCodes = this.label.shippingProductCodes.split(',');
        this.subtotalPromo = 0;
        this.subtotalLine = 0;
        this.shipping = 0;
        this.total = 0;
        this.cartData = [];
        let tempCartData = JSON.parse(JSON.stringify(result));
        tempCartData.forEach(cartItem => {
            cartItem.freeItem = false; 
            cartItem.hideDeleteIcon = false; 
            if(cartItem.cartItem){
                cartItem.cartItem.CurrencyIsoCode = cartItem.cartItem.CurrencyIsoCode == 'EUR' ? '€' : cartItem.cartItem.CurrencyIsoCode;
                cartItem.freeItem = cartItem.cartItem.FreeItem__c || cartItem.cartItem.CartFreeItem__c || cartItem.cartItem.LetterCampaignFreeItem__c;
                cartItem.hideDeleteIcon = cartItem.cartItem.FreeItem__c || cartItem.cartItem.LetterCampaignFreeItem__c;
                this.currencyIsoCode = cartItem.cartItem.CurrencyIsoCode;
                if(cartItem.cartItem && stringIsNotBlank(cartItem.cartItem.Product2.WebshopImageURL__c)){
                    cartItem.imageUrl = '/sfsites/c' + cartItem.cartItem.Product2.WebshopImageURL__c;
                    cartItem.hasImage = true;
                } else {
                    cartItem.imageUrl = null;
                    cartItem.hasImage = false;
                }
                let totalAmount = Number(cartItem.cartItem.TotalAmount) || 0;
                let totalLineAmount = Number(cartItem.cartItem.TotalLineAmount) || 0;
                let promoAmount = Number(cartItem.cartItem.TotalPromoAdjustmentAmount) || 0;
                this.total += totalAmount;
                if(shippingProductCodes.includes(cartItem.cartItem.Product2.ProductCode)){
                    this.shipping += totalAmount;
                } else {
                    this.subtotalPromo += cartItem.cartItem.TotalPromoAdjustmentAmount;
                    this.subtotalLine += totalLineAmount;
                }
                cartItem.cartItem.hasPromotion = promoAmount < 0;
                cartItem.cartItem.TotalAmount = totalAmount.toFixed(2);
                if(cartItem.cartItem.hasPromotion){
                    cartItem.cartItem.TotalPromoAdjustmentAmount = promoAmount.toFixed(2);
                    cartItem.cartItem.TotalLineAmount = totalLineAmount.toFixed(2);
                }
                cartItem.quantityOptions = [];
                let boxCount = cartItem.cartItem.Product2.BoxCount__c != null ? parseInt(cartItem.cartItem.Product2.BoxCount__c) : null;
                let paletteCount = cartItem.cartItem.Product2.PaletteCount__c != null ? parseInt(cartItem.cartItem.Product2.PaletteCount__c) : null;
                let unitMeasure = cartItem.cartItem.Product2.QuantityUnitOfMeasure;
                if(!stringIsNotBlank(unitMeasure) || unitMeasure == 'ST'){
                    if(boxCount != null || paletteCount != null){
                        let lowerNumber = (boxCount == null ? paletteCount : (paletteCount == null ? boxCount : (paletteCount < boxCount ? paletteCount : boxCount)));
                        let boxFirst = boxCount == lowerNumber;
                        for(let i = 1; i < lowerNumber; i++){
                            let innerObj = {
                                label: i.toString() + ' ' + this.label.piece,
                                value: i
                            };
                            cartItem.quantityOptions.push(innerObj);
                        }
                        let boxOptions = [];
                        let paletteOptions = [];
                        if(boxCount != null){
                            for(let i = 1; i <= parseInt(this.label.maxBoxCount); i++){
                                let innerObj = {
                                    label: i.toString() + ' ' + (i == 1 ? this.label.box : this.label.boxes) + ' (' + (i * boxCount).toString() + ' ' + this.label.piece + ')',
                                    value: i * boxCount
                                };
                                boxOptions.push(innerObj);
                            }
                        }
                        if(paletteCount != null){
                            for(let i = 1; i <= parseInt(this.label.maxPaletteCount); i++){
                                let innerObj = {
                                    label: i.toString() + ' ' + (i == 1 ? this.label.palette : this.label.palettes) + ' (' + (i * paletteCount).toString() + ' ' + this.label.piece + ')',
                                    value: i * paletteCount
                                };
                                paletteOptions.push(innerObj);
                            }
                        }
                        cartItem.quantityOptions = boxFirst ? cartItem.quantityOptions.concat(boxOptions).concat(paletteOptions) : cartItem.quantityOptions.concat(paletteOptions).concat(boxOptions);
                    } else {
                        cartItem.quantityOptions = JSON.parse(JSON.stringify(this.oneToHundredOptions));
                    }
                } else if(unitMeasure == 'KAR'){
                    if(paletteCount != null){
                        for(let i = 1; i < paletteCount; i++){
                            let innerObj = {
                                label: i + ' ' + (i == 1 ? this.label.box : this.label.boxes),
                                value: i
                            };
                            cartItem.quantityOptions.push(innerObj);
                        }
                        if(paletteCount != null){
                            for(let i = 1; i <= parseInt(this.label.maxPaletteCount); i++){
                                let innerObj = {
                                    label: i.toString() + ' ' + (i == 1 ? this.label.palette : this.label.palettes) + ' (' + (i * paletteCount).toString() + ' ' + this.label.boxes + ')',
                                    value: i * paletteCount
                                };
                                cartItem.quantityOptions.push(innerObj);
                            }
                        }
                    } else {
                        cartItem.quantityOptions = JSON.parse(JSON.stringify(this.oneToHundredOptions));
                    }
                }
                this.cartId = cartItem.cartItem.CartId;
                if(cartItem.cartItem.Type != 'Charge'){
                    this.cartData.push(cartItem);
                }
            }
        });
        this.shipping = this.shipping == 0 ? this.label.free : this.shipping.toFixed(2) + ' ' + this.currencyIsoCode;
        this.subtotalPromo = this.subtotalPromo == 0 ? '0.00 ' + this.currencyIsoCode : this.subtotalPromo.toFixed(2) + ' ' + this.currencyIsoCode;
        this.subtotalLine = this.subtotalLine == 0 ? '0.00 ' + this.currencyIsoCode : this.subtotalLine.toFixed(2) + ' ' + this.currencyIsoCode;
        this.total = this.total == 0 ? '0.00 ' + this.currencyIsoCode : this.total.toFixed(2) + ' ' + this.currencyIsoCode;
        this.hasCartData = this.cartData.length > 0;
        this.isLoading = false;
        this.isLoadingInner = false;
    }

    @api 
    refreshCartData(){
        this.isLoadingInner = true;
        let self = this;
        setTimeout(() => {
            getCartItems({accountId: this.accountId, cartId: this.cartId})
            .then(result => {
                if(self.noReloadAfterChange){
                    fireEvent(self.pageRef, 'recalcCartItemsEvent', {  });
                    self.processCartData(result);
                } else {
                    setTimeout(() => {
                        window.location.reload();
                    }); // Timeout to prevent intersections 
                }
            })
        }, 2000);
    }

    removeItemFromCart(event){
        this.isLoadingInner = true;
        let productId = event.currentTarget.dataset.productid;
        if(!this.noReloadAfterChange){
            this.isLoading = true;
        } else {
            this.cartData.forEach(cartItem => {
                if(cartItem.cartItem.Product2Id == productId){
                    cartItem.isRemoved = true;
                }
            });
        }
        removeItemFromCart({cartId: this.cartId, accountId: this.accountId, productId: productId})
        .then(outerResult => {
            if(outerResult == true){
                fireEvent(this.pageRef, 'closeSliderEventMultiRows', { });
                fireEvent(this.pageRef, 'closeSliderEventSingleRow', { });
                fireEvent(this.pageRef, 'closeSliderEventSingleRecord', { });
                this.refreshCartData();
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
            this.isLoadingInner = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    handleGoToCheckout(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Current_Checkout',
            }
        });
    }

    handleChangeQuantity(event){
        this.isLoadingInner = true;
        let productId = event.currentTarget.dataset.productid;
        let quantity = parseInt(event.target.value);
        if(!this.noReloadAfterChange){
            this.isLoading = true;
        }
        changeCartQuantity({cartId: this.cartId, accountId: this.accountId, productId: productId, quantity: quantity})
        .then(outerResult => {
            if(outerResult == true){
                fireEvent(this.pageRef, 'closeSliderEventMultiRows', { });
                fireEvent(this.pageRef, 'closeSliderEventSingleRow', { });
                fireEvent(this.pageRef, 'closeSliderEventSingleRecord', { });
                this.refreshCartData();
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
            this.isLoadingInner = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    handleNavigateToProduct(event){
        let recordId = event.currentTarget.dataset.productid;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Product2',
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    addProductToWishlist(event){
        let productId = event.currentTarget.dataset.productid;
        this.cartData.forEach(item => {
            if(item.cartItem.Product2.Id == productId){
                item.inWishlist = true;
            }
        });
        fireEvent(this.pageRef, 'addToWishlistEvent', {  });
        addProductToWishlist({accountId: this.accountId, productId: productId})
        .then(result => {
            if(result == false){
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

    removeFromWishlist(event){
        let productId = event.currentTarget.dataset.productid;
        this.cartData.forEach(item => {
            if(item.cartItem.Product2.Id == productId){
                item.inWishlist = false;
            }
        });
        fireEvent(this.pageRef, 'removeFromWishlistEvent', {  });
        removeFromWishlist({accountId: this.accountId, productId: productId})
        .then(result => {
            if(result == false){
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
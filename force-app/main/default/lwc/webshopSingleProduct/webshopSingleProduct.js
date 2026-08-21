import { LightningElement, track, wire } from 'lwc';
import { fireEvent, registerListener } from 'c/pubsub'

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getProductDataById from '@salesforce/apex/WebshopDataController.getProductDataById';
import getProductImageDataById from '@salesforce/apex/WebshopDataController.getProductImageDataById';
import addProductToWishlist from '@salesforce/apex/WebshopDataController.addProductToWishlist';
import removeFromWishlist from '@salesforce/apex/WebshopDataController.removeFromWishlist';
import removeItemFromCart from '@salesforce/apex/WebshopDataController.removeItemFromCart';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';

// SFCC API
import { getSessionContext } from 'commerce/contextApi';
import { addItemToCart } from 'commerce/cartApi';

// Custom Labels
import availability from '@salesforce/label/c.WebshopAvailability';
import noAvailability from '@salesforce/label/c.WebshopNoAvailability';
import contents from '@salesforce/label/c.WebshopContents';
import netPrice from '@salesforce/label/c.WebshopNetPrice';
import productDetails from '@salesforce/label/c.WebshopProductDetails';
import shippingReturns from '@salesforce/label/c.WebshopShippingReturns';
import shippingReturnsDetails from '@salesforce/label/c.WebshopShippingReturnsDetails';
import addToCart from '@salesforce/label/c.WebshopAddToCartButtonLabel';
import addToWishlist from '@salesforce/label/c.WebshopAddToWishlistButtonLabel';
import alreadyInWishlist from '@salesforce/label/c.WebshopAlreadyInWishlist';
import quantity from '@salesforce/label/c.WebshopQuantity';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import itemNumber from '@salesforce/label/c.WebshopItemNumber';
import relatedProducts from '@salesforce/label/c.WebshopRelatedProducts';
import moreFrom from '@salesforce/label/c.WebshopMoreFrom';
import ingredients from '@salesforce/label/c.WebshopIngredients';
import allergens from '@salesforce/label/c.WebshopAllergens';
import nutritionalValue from '@salesforce/label/c.WebshopNutritionalValue';
import maxBoxCount from '@salesforce/label/c.WebshopDoNotTranslateMaxBoxCount';
import maxPaletteCount from '@salesforce/label/c.WebshopDoNotTranslateMaxPaletteCount';
import box from '@salesforce/label/c.GeneralBox';
import boxes from '@salesforce/label/c.GeneralBoxes';
import palette from '@salesforce/label/c.GeneralPalette';
import palettes from '@salesforce/label/c.GeneralPalettes';
import piece from '@salesforce/label/c.GeneralPiece';
import addedToCart from '@salesforce/label/c.WebshopItemsAddedToCart2';

// System
import { stringIsNotBlank } from 'c/stringHelper';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

export default class WebshopSingleProduct extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track recordId;
    @track accountId;
    @track brandId;
    @track brandName;
    @track productRecord;
    @track productLoaded = false;
    @track hasBrand = false;
    @track productImagesLoaded = false;
    @track productImages = [];
    @track highlightedImage;
    @track selectedImage;    // Currently selected thumbnail for styling
    @track showPrices = true;
    @track path = [];
    @track showSliderHeadingOne = false;
    @track showSliderHeadingTwo = false;
    @track productCodeLoaded = false;
    @track productCode = '';
    @track productSlider = '';
    @track hasStaticSlider = false;
    @track brandStaticSliderId = '';
    @track oneToHundredOptions = [];
    @track hasIngredients = false;
    @track hasAllergens = false;
    @track hasNutritionalValue = false;
    @track addToCartClicked = false;
    @track addToCartFading = false;
    @track cartId = null;
    @track isAvailable = false;
    @track availabilityColour = 'red';
    @track hasSubtitle = false;
    quantityChangeTimer = null;


    label = {
        availability,
        noAvailability,
        contents,
        netPrice,
        productDetails,
        shippingReturns,
        shippingReturnsDetails,
        addToCart,
        addToWishlist,
        alreadyInWishlist,
        quantity,
        generalError,
        generalErrorMsg,
        itemNumber,
        relatedProducts,
        moreFrom,
        ingredients,
        allergens,
        nutritionalValue,
        maxBoxCount,
        maxPaletteCount,
        box,
        boxes,
        palette,
        palettes,
        piece,
        addedToCart
    };

    get dotStyle(){
        return 'background-color:' + this.availabilityColour;
    }

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP );
        registerListener('closeSliderEventSingleRecord', this.closeSliderEventSingleRecord, this);
        this.recordId = window.location.href.split("/").pop();
        this.oneToHundredOptions = [];
        for(let i = 1; i < 201; i++){
            let innerObj = {
                label: i.toString(),
                value: i.toString(),
                selected: i == 1
            };
            this.oneToHundredOptions.push(innerObj);
        }
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
                this.cartId = sessionStorage.getItem('darboven_cartId');
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
                        setTimeout(() => {
                            this.template.querySelector('c-webshop-toast').toast = {
                                title: this.label.generalError,
                                message: this.label.generalErrorMsg + ': ' + error,
                                variant: 'error',
                            };
                            this.template.querySelector('c-webshop-toast').show = true;
                        });  
                    });
                } else {
                    this.showPrices = showPriceInfo === true || showPriceInfo == 'true' ? true : false;
                    this.initData();
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

    initData(){
        getProductDataById({
            productId : this.recordId,
            accountId : this.accountId
        })
        .then(result => {
            if(result != null){
                this.productRecord = JSON.parse(JSON.stringify(result));
                this.isAvailable = this.productRecord?.product?.AvailableQuantity__c == null || this.productRecord?.product?.AvailableQuantity__c > 0;
                this.availabilityColour = this.productRecord?.product?.AvailableQuantity__c == null ? 'green' : (this.productRecord?.product?.AvailableQuantity__c == 0 ? 'red' : (this.productRecord?.product?.AvailableQuantity__c < this.productRecord?.threshold ? 'yellow' : 'green'));
                this.hasSubtitle = stringIsNotBlank(this.productRecord?.product?.ProductSubtitle__c);
                let boxCount = this.productRecord?.product?.BoxCount__c != null ? parseInt(this.productRecord?.product?.BoxCount__c) : null;
                let paletteCount = this.productRecord?.product?.PaletteCount__c != null ? parseInt(this.productRecord?.product?.PaletteCount__c) : null;
                let unitMeasure = this.productRecord?.product?.QuantityUnitOfMeasure;
                if(!stringIsNotBlank(unitMeasure) || unitMeasure == 'ST'){
                    if(boxCount != null || paletteCount != null){
                        let lowerNumber = (boxCount == null ? paletteCount : (paletteCount == null ? boxCount : (paletteCount < boxCount ? paletteCount : boxCount)));
                        let boxFirst = boxCount == lowerNumber;
                        this.oneToHundredOptions = [];
                        for(let i = 1; i < lowerNumber; i++){
                            let innerObj = {
                                label: i.toString() + ' ' + this.label.piece,
                                value: i.toString(),
                                selected: i == 1
                            };
                            this.oneToHundredOptions.push(innerObj);
                        }
                        let boxOptions = [];
                        let paletteOptions = [];
                        if(boxCount != null){
                            for(let i = 1; i <= parseInt(this.label.maxBoxCount); i++){
                                let innerObj = {
                                    label: i.toString() + ' ' + (i == 1 ? this.label.box : this.label.boxes) + ' (' + (i * boxCount).toString() + ' ' + this.label.piece + ')',
                                    value: (i * boxCount).toString(),
                                    selected: false
                                };
                                boxOptions.push(innerObj);
                            }
                        }
                        if(paletteCount != null){
                            for(let i = 1; i <= parseInt(this.label.maxPaletteCount); i++){
                                let innerObj = {
                                    label: i.toString() + ' ' + (i == 1 ? this.label.palette : this.label.palettes) + ' (' + (i * paletteCount).toString() + ' ' + this.label.piece + ')',
                                    value: (i * paletteCount).toString(),
                                    selected: false
                                };
                                paletteOptions.push(innerObj);
                            }
                        }
                        this.oneToHundredOptions = boxFirst ? this.oneToHundredOptions.concat(boxOptions).concat(paletteOptions) : this.oneToHundredOptions.concat(paletteOptions).concat(boxOptions);
                    }
                } else if(unitMeasure == 'KAR'){
                    if(paletteCount != null){
                        this.oneToHundredOptions = [];
                        for(let i = 1; i < paletteCount; i++){
                            let innerObj = {
                                label: i.toString(),
                                value: i.toString(),
                                selected: i == 1
                            };
                            this.oneToHundredOptions.push(innerObj);
                        }
                        for(let i = 1; i <= parseInt(this.label.maxPaletteCount); i++){
                            let innerObj = {
                                label: i.toString() + ' ' + (i == 1 ? this.label.palette : this.label.palettes) + ' (' + (i * paletteCount).toString() + ' ' + this.label.boxes + ')',
                                value: (i * paletteCount).toString(),
                                selected: false
                            };
                            this.oneToHundredOptions.push(innerObj);
                        }
                    }
                }
                this.path = this.productRecord.breadcrumbs;
                this.productLoaded = true;
                this.hasIngredients = stringIsNotBlank(this.productRecord?.product?.Ingredients__c);
                this.hasAllergens = stringIsNotBlank(this.productRecord?.product?.Allergens__c);
                this.hasNutritionalValue = stringIsNotBlank(this.productRecord?.product?.NutritionalValue__c);
                this.hasBrand = stringIsNotBlank(this.productRecord?.product?.BrandId__c);
                if(this.hasBrand){
                    this.brandId = this.productRecord.product.BrandId__c;
                    this.brandName = this.productRecord.product.BrandName__c;
                    this.hasStaticSlider = stringIsNotBlank(this.productRecord.product.BrandStaticSlider__c);
                    this.brandStaticSliderId = this.productRecord.product.BrandStaticSlider__c;
                }
                this.productRecord.product.CurrencyIsoCode = this.productRecord.product.CurrencyIsoCode == 'EUR' ? '€' : this.productRecord.product.CurrencyIsoCode;
                this.productCode = this.productRecord.product.ProductCode;
                this.productSlider = this.productRecord.product.ProductSlider__c;
                this.productCodeLoaded = true;                
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
        getProductImageDataById({
            productId : this.recordId,
            accountId : this.accountId
        })
        .then(result => {
            if(result != null){
                this.productImagesLoaded = true;
                this.productImages = [];
                result.forEach(item => {
                    this.productImages.push('/sfsites/c/cms/delivery/media/' + item);
                });
                this.highlightedImage = this.productImages[0]; // Set the first image as the highlighted image 
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

    handleChangeQuantity(event){
        this.addToCartClicked = false;
        let quantity = parseInt(event.target.value);
        this.addToCartFading = true;
        let self = this;
        clearTimeout(this.quantityChangeTimer);
        this.quantityChangeTimer = setTimeout(function(){
            self.addToCartFading = false;
        }, 3000);
        if(quantity >= 2){
            this.addItemsToCart(this.recordId, quantity - 1);
        }
    }

    handleDeleteItemFromCart(){
        this.addToCartClicked = false;
        if(this.cartId != null){
            removeItemFromCart({cartId: this.cartId, accountId: this.accountId, productId: this.recordId})
            .then(result => {
                if(result !== true){
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

    handleGoToBrand(event) {
        let brandid = event.currentTarget.dataset.brandid;
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: brandid,
                objectApiName: "WebshopBrand__c", // objectApiName is optional
                actionName: "view",
            },
        });
    }

    handleRemoveFromWishlist() {
        this.productRecord.inWishlist = false;
        fireEvent(this.pageRef, 'removeFromWishlistEvent', {  });
        removeFromWishlist({accountId: this.accountId, productId: this.recordId})
        .then((data) => {
            if(data == false){
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

    handleAddToWishlist() {
        this.productRecord.inWishlist = true;
        fireEvent(this.pageRef, 'addToWishlistEvent', {  });
        addProductToWishlist({accountId: this.accountId, productId: this.recordId})
        .then((data) => {
            if(data == false){
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

    handleAddToCart() {
        this.addToCartClicked = true;
        this.addItemsToCart(this.recordId, 1);

        this.addToCartFading = true;
        let self = this;
        clearTimeout(this.quantityChangeTimer);
        this.quantityChangeTimer = setTimeout(function(){
            self.addToCartFading = false;
        }, 3000);
    }

    closeSliderEventSingleRecord(){
        this.addToCartClicked = false;
    }

    addItemsToCart(recordId, quantity){
        addItemToCart(recordId, quantity)
        .then((data) => {
            if (data) {
                // this will update the cart and Cart icon.
                fireEvent(this.pageRef, 'refreshCartEvent', { newitems: quantity });
            } else if(error){
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
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

    toggleAccordion(event) {
        const button = event.currentTarget;
        const targetId = event.currentTarget.dataset.id; // Use data-id for targeting
        const collapseElement = this.template.querySelector(`[data-recipient="${targetId}"]`);
        
        if (collapseElement) {
            // Check if the element is currently expanded
            const isExpanded = collapseElement.classList.contains('show');

            // Collapse all other sections
            this.template.querySelectorAll('.accordion-collapse').forEach(element => {
                element.classList.remove('show');
                element.style.maxHeight = null;
            });

            // Reset all buttons
            this.template.querySelectorAll('.accordion-button').forEach(btn => {
                btn.setAttribute('aria-expanded', 'false');
                btn.classList.add('collapsed'); // Adds 'collapsed' class to all buttons
            });

            if (!isExpanded) {
                // Expand the selected section
                collapseElement.classList.add('show');
                collapseElement.style.maxHeight = `${collapseElement.scrollHeight}px`;
                button.setAttribute('aria-expanded', 'true');
                button.classList.remove('collapsed'); // Removes 'collapsed' class from the active button
            }
        }
    }

    handleThumbnailClick(event) {
        const clickedImage = event.currentTarget.dataset.image;
        this.highlightedImage = clickedImage; // Updates highlighted image
        this.selectedImage = clickedImage; 
    }

    // Check if the thumbnail is selected and applies classes
    get imageList() {
        return this.productImages.map(image => {
            const baseClasses = 'img-thumbnail mb-md-2 me-2';
            const selectedClass = image === this.selectedImage ? ' selected-thumbnail' : '';
            return {
                url: image,
                divClass: `${baseClasses}${selectedClass}`
            };
        });
    }

    showHeadingOne(){
        this.showSliderHeadingOne = true;
    }
    showHeadingTwo(){
        this.showSliderHeadingTwo = true;
    }

}
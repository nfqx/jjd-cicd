import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import { fireEvent, registerListener } from 'c/pubsub';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getSliderDataById from '@salesforce/apex/WebshopDataController.getSliderDataById';
import getSliderDataByName from '@salesforce/apex/WebshopDataController.getSliderDataByName';
import getSliderDataByCategory from '@salesforce/apex/WebshopDataController.getSliderDataByCategory';
import getSliderDataBySearchTerm from '@salesforce/apex/WebshopDataController.getSliderDataBySearchTerm';
import getSliderDataByProduct from '@salesforce/apex/WebshopDataController.getSliderDataByProduct';
import getSliderDataByBrand from '@salesforce/apex/WebshopDataController.getSliderDataByBrand';
import getSliderDataByMyProducts from '@salesforce/apex/WebshopDataController.getSliderDataByMyProducts';
import getSliderDataByRecommendation from '@salesforce/apex/WebshopDataController.getSliderDataByRecommendation';
import getSliderFilters from '@salesforce/apex/WebshopDataController.getSliderFilters';
import addProductToWishlist from '@salesforce/apex/WebshopDataController.addProductToWishlist';
import removeFromWishlist from '@salesforce/apex/WebshopDataController.removeFromWishlist';
import removeItemFromCart from '@salesforce/apex/WebshopDataController.removeItemFromCart';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';
import { addItemToCart } from 'commerce/cartApi';

// Custom Labels

import availability from '@salesforce/label/c.WebshopAvailability';
import noAvailability from '@salesforce/label/c.WebshopNoAvailability';
import unit from '@salesforce/label/c.GeneralUnit';
import contents from '@salesforce/label/c.WebshopContents';
import ProductImageAlt from '@salesforce/label/c.WebshopProductImageAlt';
import AddToCart from '@salesforce/label/c.WebshopAddToCartButtonLabel';
import AddToWishlist from '@salesforce/label/c.WebshopAddToWishlistButtonLabel';
import Previous from '@salesforce/label/c.GeneralPreviousLabel';
import Next from '@salesforce/label/c.GeneralNextLabel';
import PerPage from '@salesforce/label/c.WebshopSliderPerPage';
import nameAscending from '@salesforce/label/c.WebshopSliderSortNameAsc';
import nameDescending from '@salesforce/label/c.WebshopSliderSortNameDesc';
import priceAscending from '@salesforce/label/c.WebshopSliderSortPriceAsc';
import priceDescending from '@salesforce/label/c.WebshopSliderSortPriceDesc';
import alreadyInWishlist from '@salesforce/label/c.WebshopAlreadyInWishlist';
import noMatchesForFilter from '@salesforce/label/c.WebshopSearchResultsNoMatchesForFilter';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import totalItemsFound from '@salesforce/label/c.WebshopTotalItemsFound';
import sortBy from '@salesforce/label/c.WebshopSliderSort';
import itemNumber from '@salesforce/label/c.WebshopItemNumber';
import addedToCart from '@salesforce/label/c.WebshopItemsAddedToCart2';
import maxBoxCount from '@salesforce/label/c.WebshopDoNotTranslateMaxBoxCount';
import maxPaletteCount from '@salesforce/label/c.WebshopDoNotTranslateMaxPaletteCount';
import box from '@salesforce/label/c.GeneralBox';
import boxes from '@salesforce/label/c.GeneralBoxes';
import palette from '@salesforce/label/c.GeneralPalette';
import palettes from '@salesforce/label/c.GeneralPalettes';
import piece from '@salesforce/label/c.GeneralPiece';

export default class WebshopSlider extends NavigationMixin(LightningElement) {
    // Four ways to call a slider - only use one
    @wire(CurrentPageReference) pageRef;
    @api sliderName = null;
    @api sliderId = null;
    @api categoryId = null;
    @api productId = null;
    @api productCode = null;
    @api productSlider = null;
    @api productBrand = null;
    @api brandId = null;
    @api searchTerm = null;
    @api categoryType = null;

    // Slider Styling
    @api mineOnly = false;
    @api withPreselection = false;
    @api showImage = false;
    @api showVariant = false;
    @api showPrice = false;
    @api showCta = false;
    @api showDescription = false;
    @api showMultipleRows = false;
    @api showWishlist = false;
    @api showSorting = false;
    @api showFilters = false;
    @api showProductPagination = false;
    @api myProductsStyle = false;
    @api noFilter = false;
    @api getBrandInstead = false;
    @api brandAccessories = false;
    @api recommended = false;
    @api myItemsOnly = false;
    @api showExtendedRows = false;

    @track isLoading = false;    
    @track accountId = null;
    @track wishlistId = null;
    @track sliderData = [];
    @track hasSliderData = false;
    @track filterReset = false;
    @track offset = 0;
    @track filter = '';
    //@track filterPrice = [];
    @track sorting = 'nameAsc';
    @track showPagination = false;
    @track filters = [];
    @track filtersLoaded = false;
    @track recordIds = [];
    @track showPrices = true;
    @track paginationDots = [];
    @track showPaginationDots = false;
    @track categoryFilter = [];
    @track oneToHundredOptions = [];
    @track reserveSliderData = null;
    @track preventForceClose = false;

    @track currentPage = 1;
    @track recordsCount = 0;
    @track recordsPerPage = parseInt(PerPage);
    @track currentStartIndex = 0; // Tracks the starting index of visible products

    label = {
        availability,
        noAvailability,
        unit,
        contents,
        ProductImageAlt,
        AddToCart,
        Previous,
        Next,
        AddToWishlist,
        nameAscending,
        nameDescending,
        priceAscending,
        priceDescending,
        alreadyInWishlist,
        noMatchesForFilter,
        generalError,
        generalErrorMsg,
        totalItemsFound,
        sortBy,
        itemNumber,
        addedToCart,
        maxBoxCount,
        maxPaletteCount,
        box,
        boxes,
        palette,
        palettes,
        piece
    }

    sortOptions = [
        { label: this.label.nameAscending, value: 'nameAsc' },
        { label: this.label.nameDescending, value: 'nameDesc' },
        { label: this.label.priceAscending, value: 'priceAsc' },
        { label: this.label.priceDescending, value: 'priceDesc' }
    ]

    get _showPrice(){
        return this.showPrice && this.showPrices;
    }

    get _showSliderData(){
        return this.hasSliderData && !this.isLoading;
    }

    get _showNoData(){
        return !this.hasSliderData && (stringIsNotBlank(this.filter) || /* this.filterPrice.length > 0 || */ this.categoryFilter.length > 0) && !this.isLoading;
    }

    get _setFilters(){
        return !this.showMultipleRows ? false : !this.noFilter;
    }

    closeSliderEventMultiRowsPre(){
        this.closeSliderEventMultiRows(false);
    }
    closeSliderEventSingleRowPre(){
        this.closeSliderEventSingleRow(false);
    }

    closeSliderEventMultiRows(checkRemainActive){
        if(!this.preventForceClose){
            if(!this.showExtendedRows && this.showMultipleRows){
                this.sliderData.forEach(sliderRow => {
                    if(!checkRemainActive || !sliderRow.remainActive){
                        sliderRow.addToCartClicked = false;
                    }         
                    sliderRow.remainActive = false;       
                });
            }
        }
        this.preventForceClose = this.checkRemainActive;
    }

    closeSliderEventSingleRow(checkRemainActive){
        if(!this.preventForceClose){
            if(!this.showExtendedRows && !this.showMultipleRows){
                this.sliderData.forEach(sliderRow => {
                    if(!checkRemainActive || !sliderRow.remainActive){
                        sliderRow.addToCartClicked = false;
                    }         
                    sliderRow.remainActive = false;       
                });
            }
        }
        this.preventForceClose = this.checkRemainActive;
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);  
        loadStyle(this, webshopStyle); 
        registerListener('closeSliderEventMultiRows', this.closeSliderEventMultiRowsPre, this);
        registerListener('closeSliderEventSingleRow', this.closeSliderEventSingleRowPre, this);
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
                let showPriceInfo = sessionStorage.getItem('darboven_showPriceInfo');
                if(!stringIsNotBlank(showPriceInfo)){
                    getShowPriceInfo({accountId: this.accountId})
                    .then(result => {
                        if(result != null){
                            this.showPrices = result;
                            sessionStorage.setItem('darboven_showPriceInfo', this.showPrices);
                            this.fetchSliderData(this._setFilters);
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
                } else {
                    this.showPrices = showPriceInfo === true || showPriceInfo == 'true' ? true : false;
                    this.fetchSliderData(this._setFilters);
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
    
        window.addEventListener('resize', this.updateTransformClass.bind(this));
    }

    processSliderData(result, setFilters){
        console.log('result: ' + JSON.stringify(result));
        console.log('setFilters: ' + setFilters);
        if(result != null){
            // reset
            this.sliderData = [];
            let yellowGreenThreshold = result.threshold;
            // set images
            result.data.forEach(sliderItem => {
                sliderItem.addToCartClicked = false;
                sliderItem.addToCartFading = false;
                sliderItem.quantityChangeTimer = null;
                sliderItem.quantity = 1;
                sliderItem.isAvailable = sliderItem.product.AvailableQuantity__c == null || sliderItem.product.AvailableQuantity__c > 0;
                sliderItem.availabilityColour = sliderItem.product.AvailableQuantity__c == null ? 'green' : (sliderItem.product.AvailableQuantity__c == 0 ? 'red' : (sliderItem.product.AvailableQuantity__c < yellowGreenThreshold ? 'yellow' : 'green'));
                sliderItem.availabilityStyle = 'background-color:' + sliderItem.availabilityColour;
                sliderItem.remainActive = false;
                sliderItem.imageUrl = stringIsNotBlank(sliderItem.product.WebshopImageURL__c) ? '/sfsites/c' + sliderItem.product.WebshopImageURL__c : '';
                sliderItem.product.CurrencyIsoCode = sliderItem.product.CurrencyIsoCode == 'EUR' ? '€' : sliderItem.product.CurrencyIsoCode;
                
                sliderItem.quantityOptions = [];
                let boxCount = sliderItem.product.BoxCount__c != null ? parseInt(sliderItem.product.BoxCount__c) : null;
                let paletteCount = sliderItem.product.PaletteCount__c != null ? parseInt(sliderItem.product.PaletteCount__c) : null;
                let unitMeasure = sliderItem.product.QuantityUnitOfMeasure;
                if(!stringIsNotBlank(unitMeasure) || unitMeasure == 'STÜCK' || unitMeasure == 'STUECK' || unitMeasure == 'ST'){
                    if(boxCount != null || paletteCount != null){
                        let lowerNumber = (boxCount == null ? paletteCount : (paletteCount == null ? boxCount : (paletteCount < boxCount ? paletteCount : boxCount)));
                        let boxFirst = boxCount == lowerNumber;
                        for(let i = 1; i < lowerNumber; i++){
                            let innerObj = {
                                label: i.toString() + ' ' + this.label.piece,
                                value: i.toString(),
                                selected: i == 1
                            };
                            sliderItem.quantityOptions.push(innerObj);
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
                        sliderItem.quantityOptions = boxFirst ? sliderItem.quantityOptions.concat(boxOptions).concat(paletteOptions) : sliderItem.quantityOptions.concat(paletteOptions).concat(boxOptions);
                    } else {
                        sliderItem.quantityOptions = JSON.parse(JSON.stringify(this.oneToHundredOptions));
                    }
                } else if(unitMeasure == 'KARTON' || unitMeasure == 'KAR'){
                    if(paletteCount != null){
                        for(let i = 1; i < paletteCount; i++){
                            let innerObj = {
                                label: i.toString(),
                                value: i.toString(),
                                selected: i == 1
                            };
                            sliderItem.quantityOptions.push(innerObj);
                        }
                        if(paletteCount != null){
                            for(let i = 1; i <= parseInt(this.label.maxPaletteCount); i++){
                                let innerObj = {
                                    label: i.toString() + ' ' + (i == 1 ? this.label.palette : this.label.palettes) + ' (' + (i * paletteCount).toString() + ' ' + this.label.boxes + ')',
                                    value: (i * paletteCount).toString(),
                                    selected: false
                                };
                                sliderItem.quantityOptions.push(innerObj);
                            }
                        }
                    } else {
                        sliderItem.quantityOptions = JSON.parse(JSON.stringify(this.oneToHundredOptions));
                    }
                }
            });
            this.sliderData = result.data;
            this.recordsCount = result.total;
            this.hasSliderData = result.data.length > 0;
            this.showPagination = result.showPagination;
            if(!this.hasSliderData){
                this.dispatchEvent(new CustomEvent('nodata', {bubbles: true}));
            } else {
                this.dispatchEvent(new CustomEvent('hasdata', {bubbles: true}));
            }
            if(!this.showExtendedRows && !this.showMultipleRows){
                this.calcPaginationDots();
            }
            this.updateTransformClass(); // Update carousel transform
            this.isLoading = false;
            if(this.showFilters && setFilters){
                getSliderFilters({
                    productIdsPreWithPrices: result.productIdsPreWithPricesKeys,
                    categoryId: this.categoryId
                })
                .then(result => {
                    this.filters = JSON.parse(JSON.stringify(result));
                    this.filtersLoaded = true;
                    this.filterReset = true;
                    let self = this;
                    setTimeout(function(){
                        self.filterReset = false;
                    }, 1);
                });
            }
        }  else {
            this.isLoading = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        }
    }

    calcPaginationDots(){
        this.showPaginationDots = false;
        this.paginationDots = [];
        let currentPage = Math.floor(this.currentStartIndex / this.visibleCount)
        for(let i = 0; i < Math.ceil(this.recordsCount / this.visibleCount); i++){
            let innerObject = {};
            innerObject.number = i;
            innerObject.classNames = i == currentPage ? 'dot active' : 'dot';
            this.paginationDots.push(innerObject);
        }
        this.showPaginationDots = true;
    }

    retrieveRecommendationData(){
        getSliderDataByRecommendation({
            accountId : this.accountId
        })
        .then(result => {
            this.processSliderData(JSON.parse(JSON.stringify(result)), false);
        })
        .catch(error => {
            this.isLoading = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    getSliderData(setFilters){
        this.isLoading = true;
        if(this.accountId != null){
            if(this.recommended == true){
                this.retrieveRecommendationData();
            } else if(this.mineOnly == true){
                getSliderDataByMyProducts({
                    accountId : this.accountId,
                    offset: this.offset,
                    filter: this.filter,
                    categoryFilter: this.categoryFilter,
                    //filterPrice: this.filterPrice,
                    sorting: this.sorting,
                    setFilters: setFilters,
                    multiRows: this.showMultipleRows,
                    withPreselection: this.withPreselection
                })
                .then(result => {
                    this.processSliderData(JSON.parse(JSON.stringify(result)), setFilters);
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else if(this.sliderName != null){
                getSliderDataByName({
                    sliderName : this.sliderName,
                    accountId : this.accountId,
                    offset: this.offset,
                    filter: this.filter,
                    categoryFilter: this.categoryFilter,
                    //filterPrice: this.filterPrice,
                    sorting: this.sorting,
                    multiRows: this.showMultipleRows
                })
                .then(result => {
                    this.processSliderData(JSON.parse(JSON.stringify(result)), setFilters);
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else if(this.sliderId != null) {
                getSliderDataById({
                    sliderId : this.sliderId,
                    accountId : this.accountId,
                    offset: this.offset,
                    filter: this.filter,
                    //filterPrice: this.filterPrice,
                    sorting: this.sorting,
                    multiRows: this.showMultipleRows
                })
                .then(result => {
                    this.processSliderData(JSON.parse(JSON.stringify(result)), setFilters);
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else if(this.categoryId != null) {
                getSliderDataByCategory({
                    categoryId : this.categoryId,
                    accountId : this.accountId,
                    offset: this.offset,
                    filter: this.filter,
                    categoryFilter: this.categoryFilter,
                    //filterPrice: this.filterPrice,
                    sorting: this.sorting,
                    multiRows: this.showMultipleRows,
                    currentProductId: this.recordId,
                    categoryType: this.categoryType,
                    onlyMyItems: this.myItemsOnly
                })
                .then(result => {
                    this.processSliderData(JSON.parse(JSON.stringify(result)), setFilters);
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else if(this.searchTerm != null) {
                getSliderDataBySearchTerm({
                    searchTerm : this.searchTerm,
                    accountId : this.accountId,
                    offset: this.offset,
                    filter: this.filter,
                    categoryFilter: this.categoryFilter,
                    //filterPrice: this.filterPrice,
                    sorting: this.sorting,
                    multiRows: this.showMultipleRows
                })
                .then(result => {
                    this.processSliderData(JSON.parse(JSON.stringify(result)), setFilters);
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else if(this.productId != null) {
                getSliderDataByProduct({
                    productId : this.productId,
                    productCode : this.productCode,
                    productSlider : this.productSlider,
                    brandId : this.productBrand,
                    accountId : this.accountId,
                    offset: this.offset,
                    filter: this.filter,
                    categoryFilter: this.categoryFilter,
                    //filterPrice: this.filterPrice,
                    sorting: this.sorting,
                    multiRows: this.showMultipleRows,
                    getBrandInstead: this.getBrandInstead
                })
                .then(result => {
                    this.processSliderData(JSON.parse(JSON.stringify(result)), setFilters);
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else if(this.brandId != null) {
                getSliderDataByBrand({
                    brandId : this.brandId,
                    accountId : this.accountId,
                    offset: this.offset,
                    filter: this.filter,
                    categoryFilter: this.categoryFilter,
                    //filterPrice: this.filterPrice,
                    sorting: this.sorting,
                    multiRows: this.showMultipleRows,
                    currentProductId: this.recordId,
                    brandAccessories: this.brandAccessories
                })
                .then(result => {
                    this.processSliderData(JSON.parse(JSON.stringify(result)), setFilters);
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            }
        }
    }

    fetchSliderData(setFilters) {
        return new Promise((resolve, reject) => {
            // Call original getSliderData function
            this.getSliderData(setFilters);
    
            const checkSliderData = () => {
                if (this.sliderData && this.sliderData.length > 0) {
                    resolve(this.sliderData); // Resolve when data is ready
                } else {
                    setTimeout(checkSliderData, 100);
                }
            };

            checkSliderData();
        });
    }   

    handleAddToWishlist(event) {
        let currentProductId = event.currentTarget.dataset.id;
        this.sliderData.forEach(item => {
            if(item.product.Id == currentProductId){
                item.inWishlist = true;
            }
        });
        fireEvent(this.pageRef, 'addToWishlistEvent', {  });
        addProductToWishlist({accountId: this.accountId, productId: currentProductId})
        .then((result) => {
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

    handleRemoveFromWishlist(event){
        let productId = event.currentTarget.dataset.productid;
        this.sliderData.forEach(item => {
            if(item.product.Id == productId){
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

    handleAddToCartAlt(event) {
        let currentProductId = event.currentTarget.dataset.id;
        this.setAddToCartFading(currentProductId, true, false);
        let itemsToAdd = 1;
        this.sliderData.forEach(sliderRow => {
            if(sliderRow.product.Id == currentProductId){
                itemsToAdd = sliderRow.quantity;
            }             
        });
        
        this.addItemsToCart(currentProductId, itemsToAdd, true);

    }

    handleAddToCart(event) {
        let currentProductId = event.currentTarget.dataset.id;
        this.setAddToCartFading(currentProductId, true, true);
        this.sliderData.forEach(sliderRow => {
            sliderRow.remainActive = false;
            if(sliderRow.product.Id == currentProductId){
                sliderRow.remainActive = true;
            }                
        });

        if(!this.showExtendedRows){
            if(this.showMultipleRows){
                this.closeSliderEventMultiRows(true);
                fireEvent(this.pageRef, 'closeSliderEventMultiRows', { });
            } else {
                this.closeSliderEventSingleRow(true);
                fireEvent(this.pageRef, 'closeSliderEventSingleRow', {});
            }
        }
        this.setAddToCartClicked(currentProductId, true);
        this.addItemsToCart(currentProductId, 1, false);
    }

    addItemsToCart(recordId, quantity, withReload){
        addItemToCart(recordId, quantity)
        .then((data) => {
            if(withReload){
                setTimeout(function(){
                    window.location.reload();
                });
            } else {
                if (data) {
                    fireEvent(this.pageRef, 'refreshCartEvent', { newitems: quantity });
                }
            }
        })
        .catch(error => {
            console.log(error);
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }


    handleChangeQuantity(event){
        let currentProductId = event.currentTarget.dataset.id;
        this.setAddToCartClicked(currentProductId, false);
        this.setAddToCartFading(currentProductId, true, true);
        let quantity = parseInt(event.target.value);
        if(quantity >= 2){
            this.addItemsToCart(currentProductId, quantity - 1, false);
        }
    }

    handleChangeQuantityAlt(event){
        let currentProductId = event.currentTarget.dataset.id;
        this.setQuantity(currentProductId, parseInt(event.target.value));
    }

    handleDeleteItemFromCart(event){
        let currentProductId = event.currentTarget.dataset.id;
        this.setAddToCartClicked(currentProductId, false);
        let cartId = sessionStorage.getItem('darboven_cartId');
        if(!stringIsNotBlank(cartId) || cartId == 'null'){
            getCartSummaryOrCreateCart({accountId: this.accountId})
            .then(result => {
                sessionStorage.setItem('darboven_cartId', result);
                fireEvent(this.pageRef, 'setCartIdEvent', {  });
                this.deleteItemFromCart(currentProductId, cartId);
            });
        } else {
            this.deleteItemFromCart(currentProductId, cartId);
        }
    }

    deleteItemFromCart(cartId, currentProductId){
        removeItemFromCart({cartId: this.cartId, accountId: this.accountId, productId: currentProductId})
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

    setAddToCartFading(productId, value, clear){
        this.sliderData.forEach(sliderRow => {
            if(sliderRow.product.Id == productId){
                sliderRow.addToCartFading = value;
                if(value == false){
                    sliderRow.quantityChangeTimer = null;
                } else {
                    if(clear){
                        clearTimeout(sliderRow.quantityChangeTimer);
                        let self = this;
                        sliderRow.quantityChangeTimer = setTimeout(function(){
                            self.setAddToCartFading(productId, false, false);
                        }, 3000); 
                    }  
                }
            }                
        });
    }
    setQuantity(productId, value){
        this.sliderData.forEach(sliderRow => {
            if(sliderRow.product.Id == productId){
                sliderRow.quantity = value;
            }                
        });
    }

    setAddToCartClicked(productId, value){
        this.sliderData.forEach(sliderRow => {
            if(sliderRow.product.Id == productId){
                sliderRow.addToCartClicked = value;
            }                
        });
    }

    handleNavigateToProduct(event){
        let recordId = event.currentTarget.dataset.productid;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Product2',
                recordId: recordId,
                actionName: 'view',
            }
        })
        .then(url => {
            window.location.replace(url);
        })
    }

    handleFilterChange(event){
        this.showPagination = false;
        this.offset = 0;
        this.currentPage = 1;
        this.filter = event.detail.filter;
        //this.filterPrice = event.detail.filterPrice;
        this.categoryFilter = event.detail.categoryFilter;
        if(event.detail.rerender == true){
            this.filterReset = true;
            let self = this;
            setTimeout(function(){
                self.filterReset = false;
            }, 1);
        }
        this.getSliderData(false);
    }

    handleSortingChange(event){
        this.showPagination = false;
        this.offset = 0;
        this.currentPage = 1;
        this.sorting = event.target.value;
        this.getSliderData(false);
    }

    handlePageChange(event){
        this.showPagination = false;
        if(event.detail.page && event.detail.page > 0){
            this.currentPage = event.detail.page;
            this.offset = (this.currentPage - 1) * this.recordsPerPage;
            this.getSliderData(false);
        }
    }

    get filterColumnClass() {
        return `pe-0 pe-md-3 ${this._setFilters ? 'col-lg-3 col-12' : 'd-none'}`; 
    }

    get carouselColumnClass() {
        return this._setFilters ? 'col-lg-9 ml-2' : 'col-12'; 
    }

    get multipleRowsProductBackgroundClass() {
        return this.myProductsStyle ? 'card-img-top bg-light rounded-0' : 'card-img-top rounded-0'; 
    }

    get singleRowProductBackgroundClass() {
        return this.myProductsStyle ? 'card-img-top slider bg-light rounded-0' : 'card-img-top slider rounded-0'; 
    }

    get cardColumnClass() {
        const screenWidth = window.innerWidth;
        const result = !this._setFilters && screenWidth > 1050 ? 'd-flex justify-content-center col-6 col-md-3 p-0' : 'd-flex justify-content-center col-6 col-md-4 p-0';
        return result;
    }

    get visibleCount() {
        const screenWidth = window.innerWidth;

        if (screenWidth >= 992) {
            return 4; 
        } else if (screenWidth >= 768) {
            return 2; 
        } else {
            return 1; 
        }
    }

    // Apply transform via a dynamically updated class
    updateTransformClass() {
        if (!this.sliderData || this.sliderData.length === 0) {
            console.warn('No sliderData available, skipping transform update.');
            return;
        }
    
        const totalItems = this.sliderData.length;
        const visibleCount = this.visibleCount;

        const totalGroups = Math.ceil(totalItems / visibleCount);
    
        const currentGroup = Math.min(
            Math.floor(this.currentStartIndex / visibleCount),
            totalGroups - 1
        );

        const translateXPercentage = -(currentGroup * 100);

        const carouselInner = this.template.querySelector('.carousel-inner');
        if (carouselInner) {
            carouselInner.style.transform = `translateX(${translateXPercentage}%)`;
            carouselInner.style.transition = 'transform 0.5s ease';
        } 
        
        this.calcPaginationDots();
    }    

    handleClickDot(event) {
        let visibleCount = this.visibleCount;
        let currentDot = event.currentTarget.dataset.number;
        let totalItems = this.sliderData.length;

        this.template.querySelectorAll('.dot').forEach(element => {
            element.classList.remove('active')
        });
        event.currentTarget.classList.add('active');
    
        this.currentStartIndex = Math.min(
            currentDot * visibleCount,
            totalItems - (totalItems % visibleCount === 0 ? visibleCount : totalItems % visibleCount)
        );

        this.updateTransformClass();
    }

    handleNext() {
        const visibleCount = this.visibleCount;
        const totalItems = this.sliderData.length;
    
        if (!this.disableNext) {
            // Align currentStartIndex to the next group boundary
            this.currentStartIndex = Math.min(
                this.currentStartIndex + visibleCount,
                totalItems - (totalItems % visibleCount === 0 ? visibleCount : totalItems % visibleCount)
            );
            this.updateTransformClass();
        }
    }
    
    handlePrev() {
        const visibleCount = this.visibleCount;
    
        if (!this.disablePrev) {
            // Align currentStartIndex to the previous group boundary
            this.currentStartIndex = Math.max(this.currentStartIndex - visibleCount, 0);
            this.updateTransformClass();
        }
    }

    get disableNext() {
        const visibleCount = this.visibleCount;
        const totalItems = this.sliderData.length;
        return this.currentStartIndex + visibleCount >= totalItems;
    }
    
    get disablePrev() {
        return this.currentStartIndex === 0;
    }

}
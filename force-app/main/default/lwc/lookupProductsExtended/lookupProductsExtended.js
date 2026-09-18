import { LightningElement, api } from 'lwc';

const TAB_CORE = 'core';
const TAB_LISTED = 'listed';
const TAB_ALL = 'all';
const MINIMUM_SEARCH_LENGTH = 3;

import allLabel from '@salesforce/label/c.LookupExtendedAllProducts';
import alreadyAdded from '@salesforce/label/c.LookupExtendedAlreadyAdded';
import coreAssortment from '@salesforce/label/c.LookupExtendedCoreAssortment';
import heading from '@salesforce/label/c.LookupExtendedHeading';
import itemGroupUnit from '@salesforce/label/c.LookupExtendedItemGroupUnit';
import listedProducts from '@salesforce/label/c.LookupExtendedListedProducts';
import minCharMessage from '@salesforce/label/c.LookupExtendedMinCharMsg';
import noProductsFound from '@salesforce/label/c.LookupExtendedNoMatchingProductsFound';
import placeholder from '@salesforce/label/c.LookupExtendedPlaceholder';
import priceLabel from '@salesforce/label/c.WebshopPriceLabel';
import productLabel from '@salesforce/label/c.ReturnOrderMaskProduct';
import productsAvailable from '@salesforce/label/c.LookupExtendedProductsAvailable';

export default class LookupProductsExtended extends LightningElement {

    label = {
        allLabel,
        alreadyAdded,
        coreAssortment,
        heading,
        itemGroupUnit,
        listedProducts,
        minCharMessage,
        noProductsFound,
        placeholder,
        priceLabel,
        productLabel,
        productsAvailable,
    }

    @api heading = this.label.heading;
    @api helpText = '';
    @api placeholder = this.label.placeholder;
    @api contextLabel = '';
    @api coreLabel = this.label.coreAssortment;
    @api listedLabel = this.label.listedProducts;
    @api allLabel = this.label.allLabel;
    @api productLabel = this.label.productLabel;
    @api itemLabel = this.label.itemGroupUnit;
    @api priceLabel = this.label.priceLabel;
    @api productsAvailableLabel = this.label.productsAvailable;
    @api alreadyAddedLabel = this.label.alreadyAdded;
    @api minimumCharactersMessage = this.label.minCharMessage;
    @api noResultsMessage = this.label.noProductsFound;
    @api locale = 'de-DE';
    @api currency = 'EUR';
    @api pageSize = 25;
    @api coreProducts = [];
    @api listedProducts = [];
    @api priceByProductId = {};
    @api excludedProductIds = [];

    activeTab = TAB_CORE;
    allProducts = [];
    isLoading = false;
    isOpen = false;
    query = '';
    requestId = 0;
    listedPage = 1;
    searchTimer;
    _selection = [];
    windowMouseDownHandler;
    internalMouseDown = false;

    @api
    get selection(){
        return this._selection;
    }

    set selection(value){
        this._selection = Array.isArray(value) ? value : [];
        if(this._selection.length === 0){
            this.query = '';
        }
    }

    connectedCallback(){
        this.windowMouseDownHandler = this.handleWindowMouseDown.bind(this);
        window.addEventListener('mousedown', this.windowMouseDownHandler);
    }

    disconnectedCallback(){
        window.removeEventListener('mousedown', this.windowMouseDownHandler);
        window.clearTimeout(this.searchTimer);
    }

    @api
    setSearchResults(results, requestId){
        if(requestId != null && requestId !== this.requestId){
            return;
        }
        this.allProducts = Array.isArray(results) ? results : [];
        this.isLoading = false;
    }

    get ariaExpanded(){
        return this.isOpen ? 'true' : 'false';
    }

    get coreTabClass(){
        return this.activeTab === TAB_CORE ? 'tab tab-active' : 'tab';
    }

    get listedTabClass(){
        return this.activeTab === TAB_LISTED ? 'tab tab-active' : 'tab';
    }

    get allTabClass(){
        return this.activeTab === TAB_ALL ? 'tab tab-active' : 'tab';
    }

    get isCoreTab(){
        return this.activeTab === TAB_CORE;
    }

    get isListedTab(){
        return this.activeTab === TAB_LISTED;
    }

    get isAllTab(){
        return this.activeTab === TAB_ALL;
    }

    get showPriceColumn(){
        return !this.isAllTab;
    }

    get resultGridClass(){
        return this.showPriceColumn ? 'result-grid result-grid-price' : 'result-grid result-grid-no-price';
    }

    get displayRows(){
        if(this.isAllTab && this.query.trim().length < MINIMUM_SEARCH_LENGTH){
            return [];
        }
        let products = this.isCoreTab ? this.coreProducts : (this.isListedTab ? this.listedProducts : this.allProducts);
        if(this.isListedTab && this.query.trim().length === 0){
            let startIndex = (this.currentListedPage - 1) * this.normalizedPageSize;
            products = (products ?? []).slice(startIndex, startIndex + this.normalizedPageSize);
        }
        let rows = this.normalizeProducts(products).filter(product => this.matchesQuery(product));
        if(this.isListedTab && this.query.trim().length > 0){
            let startIndex = (this.currentListedPage - 1) * this.normalizedPageSize;
            rows = rows.slice(startIndex, startIndex + this.normalizedPageSize);
        }
        return rows.map(product => ({
            ...product,
            rowClass: this.resultGridClass + ' result-row' + (product.isSelected ? ' result-row-selected' : ''),
            tabIndex: product.isSelected ? '-1' : '0'
        }));
    }

    get normalizedPageSize(){
        let size = Number(this.pageSize);
        return Number.isFinite(size) && size > 0 ? Math.floor(size) : 25;
    }

    get listedResultCount(){
        if(this.query.trim().length === 0){
            return (this.listedProducts ?? []).length;
        }
        return this.normalizeProducts(this.listedProducts).filter(product => this.matchesQuery(product)).length;
    }

    get listedPageCount(){
        return Math.max(1, Math.ceil(this.listedResultCount / this.normalizedPageSize));
    }

    get currentListedPage(){
        return Math.min(this.listedPage, this.listedPageCount);
    }

    get showListedPagination(){
        return this.isListedTab && this.listedResultCount > this.normalizedPageSize;
    }

    get isPreviousPageDisabled(){
        return this.currentListedPage <= 1;
    }

    get isNextPageDisabled(){
        return this.currentListedPage >= this.listedPageCount;
    }

    get paginationText(){
        return this.currentListedPage + ' / ' + this.listedPageCount;
    }

    get hasResults(){
        return this.displayRows.length > 0;
    }

    get showMinimumCharactersMessage(){
        return this.isAllTab && this.query.trim().length < MINIMUM_SEARCH_LENGTH;
    }

    get showNoResultsMessage(){
        return !this.isLoading && !this.showMinimumCharactersMessage && !this.hasResults;
    }

    get activeTabLabel(){
        return this.isCoreTab ? this.coreLabel : (this.isListedTab ? this.listedLabel : this.allLabel);
    }

    get statusText(){
        let prefix = this.contextLabel ? this.contextLabel + ' · ' : '';
        let resultCount = this.isListedTab ? this.listedResultCount : this.displayRows.length;
        return prefix + this.activeTabLabel + ': ' + resultCount + ' ' + this.productsAvailableLabel;
    }

    get helpTextDisplay(){
        return this.helpText || 'Switch between the core assortment, listed products and the full active catalogue.';
    }

    handleWindowMouseDown(){
        if(this.isOpen && !this.internalMouseDown){
            this.isOpen = false;
        }
        this.internalMouseDown = false;
    }

    handleInternalMouseDown(){
        this.internalMouseDown = true;
    }

    handleInputFocus(){
        this.isOpen = true;
    }

    handleInput(event){
        this.query = event.target.value;
        this.listedPage = 1;
        this.isOpen = true;
        if(this.isAllTab){
            this.queueAllProductSearch();
        }
    }

    handleInputKeyDown(event){
        if(event.key === 'Escape'){
            this.isOpen = false;
            return;
        }
        if(event.key === 'ArrowDown' && this.hasResults){
            event.preventDefault();
            this.template.querySelector('.result-row')?.focus();
        }
        if(event.key === 'Enter' && this.hasResults){
            event.preventDefault();
            this.selectProduct(this.displayRows[0]);
        }
    }

    handleTabMouseDown(event){
        event.preventDefault();
    }

    handleTabClick(event){
        if(this.activeTab !== event.currentTarget.dataset.tab){
            this.listedPage = 1;
        }
        this.activeTab = event.currentTarget.dataset.tab;
        this.isOpen = true;
        if(this.isAllTab){
            this.queueAllProductSearch(true);
        }
        this.template.querySelector('.search-input')?.focus();
    }

    handlePreviousPage(){
        if(!this.isPreviousPageDisabled){
            this.listedPage = this.currentListedPage - 1;
        }
    }

    handleNextPage(){
        if(!this.isNextPageDisabled){
            this.listedPage = this.currentListedPage + 1;
        }
    }

    handleResultMouseDown(event){
        event.preventDefault();
    }

    handleResultClick(event){
        let product = this.displayRows.find(item => item.id === event.currentTarget.dataset.id);
        if(product != null){
            this.selectProduct(product);
        }
    }

    selectProduct(product){
        if(product.isSelected){
            return;
        }
        this._selection = [product.selection];
        this.query = product.name;
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {selection: this._selection},
            bubbles: true,
            composed: true
        }));
    }

    queueAllProductSearch(immediate = false){
        window.clearTimeout(this.searchTimer);
        let searchTerm = this.query.trim();
        if(searchTerm.length < MINIMUM_SEARCH_LENGTH){
            this.allProducts = [];
            this.isLoading = false;
            this.requestId++;
            return;
        }
        if(immediate){
            this.dispatchAllProductSearch(searchTerm);
            return;
        }
        this.searchTimer = window.setTimeout(() => this.dispatchAllProductSearch(searchTerm), 250);
    }

    dispatchAllProductSearch(searchTerm){
        let requestId = ++this.requestId;
        this.isLoading = true;
        this.dispatchEvent(new CustomEvent('search', {
            detail: {searchTerm, requestId},
            bubbles: true,
            composed: true
        }));
    }

    matchesQuery(product){
        if(this.isAllTab){
            return true;
        }
        let searchTerm = this.query.trim().toLocaleLowerCase();
        if(searchTerm.length === 0){
            return true;
        }
        return product.searchText.includes(searchTerm);
    }

    normalizeProducts(products){
        let excludedIds = new Set((this.excludedProductIds ?? []).map(productId => String(productId)));
        return (products ?? []).map(product => this.normalizeProduct(product, excludedIds)).filter(product => product.id);
    }

    normalizeProduct(product, excludedIds){
        let fieldMap = product.additionalFieldMap ?? {};
        let id = product.id ?? product.Id ?? product.productId ?? product.Product2Id;
        let name = product.title ?? product.Name ?? product.name ?? product.Product2?.Name ?? '';
        let productCode = fieldMap.ProductCode ?? product.ProductCode ?? product.productCode ?? product.Product2?.ProductCode ?? '';
        let quantityUnitOfMeasure = fieldMap.QuantityUnitOfMeasure ?? product.QuantityUnitOfMeasure ?? product.quantityUnitOfMeasure ?? product.Product2?.QuantityUnitOfMeasure ?? '';
        let factor = fieldMap.Factor__c ?? product.Factor__c ?? product.factor ?? product.Product2?.Factor__c ?? 1;
        let baseProductCode = fieldMap.BaseProductCode__c ?? product.BaseProductCode__c ?? product.baseProductCode ?? product.Product2?.BaseProductCode__c;
        let currencyIsoCode = fieldMap.CurrencyIsoCode ?? product.CurrencyIsoCode ?? product.currencyIsoCode ?? product.Product2?.CurrencyIsoCode ?? this.currency;
        let productGroup = fieldMap.ProductGroupName__c ?? product.ProductGroupName__c ?? product.ProductGroupName ?? product.productGroupName ?? product.ProductGroup__r?.Name ?? product.Product2?.ProductGroup__r?.Name ?? '';
        let price = fieldMap.price ?? product.price ?? product.UnitPrice ?? this.priceByProductId?.[id];
        let factorNumber = Number(factor);
        let itemDetails = [productGroup, quantityUnitOfMeasure, Number.isFinite(factorNumber) && factorNumber > 1 ? factorNumber + ' units' : ''].filter(value => value !== '').join(' · ');
        let additionalFieldMap = {
            ...fieldMap,
            ProductCode: productCode,
            QuantityUnitOfMeasure: quantityUnitOfMeasure,
            CurrencyIsoCode: currencyIsoCode,
            BaseProductCode__c: baseProductCode,
            Factor__c: Number.isFinite(factorNumber) && factorNumber > 0 ? factorNumber : 1
        };
        if(price != null && price !== ''){
            additionalFieldMap.price = price;
        }
        return {
            id: String(id ?? ''),
            name,
            productCode,
            itemDetails,
            displayPrice: this.formatPrice(price, currencyIsoCode),
            isSelected: excludedIds.has(String(id)),
            searchText: [name, productCode, productGroup, quantityUnitOfMeasure].join(' ').toLocaleLowerCase(),
            selection: {
                ...product,
                id,
                title: name,
                subtitle: productCode,
                sObjectType: 'Product2',
                additionalFieldMap
            }
        };
    }

    formatPrice(value, currencyIsoCode){
        if(value == null || value === '' || !Number.isFinite(Number(value))){
            return '—';
        }
        try {
            return new Intl.NumberFormat(this.locale, {style: 'currency', currency: currencyIsoCode || this.currency}).format(Number(value));
        } catch(error){
            return Number(value).toFixed(2) + ' ' + (currencyIsoCode || this.currency);
        }
    }
}
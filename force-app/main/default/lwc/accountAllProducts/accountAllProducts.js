import { LightningElement, api, wire, track } from 'lwc';
import getAccountProducts from '@salesforce/apex/AccountAllProductsController.getAccountProducts';
import { refreshApex } from '@salesforce/apex';
import { stringIsNotBlank } from 'c/stringHelper';

// Permission
import hasManageEntitlement from '@salesforce/customPermission/ManageEntitlement';

// Labels
import ownProducts from '@salesforce/label/c.AccountAllProductsOwnProducts';
import extensionProducts from '@salesforce/label/c.AccountAllProductsExtensionProducts';
import otherProducts from '@salesforce/label/c.AccountAllProductsOtherProducts';
import allProducts from '@salesforce/label/c.AccountAllProductsAllProducts';
import availableProducts from '@salesforce/label/c.AccountAllProductsAvailableProducts';
import ownAssortment from '@salesforce/label/c.AccountAllProductsOwnAssortment';
import ownAssortmentOnly from '@salesforce/label/c.AccountAllProductsOwnAssortmentOnly';
import noProductsInThisView from '@salesforce/label/c.AccountAllProductsNoProductsInThisView';
import removeFromAssortment from '@salesforce/label/c.AccountAllProductsRemoveFromAssortment';
import product from '@salesforce/label/c.GeneralProduct';
import brand from '@salesforce/label/c.GeneralBrand';
import search from '@salesforce/label/c.GeneralSearch';
import productCode from '@salesforce/label/c.GeneralProductCode';
import yes from '@salesforce/label/c.GeneralYes';
import no from '@salesforce/label/c.GeneralNo';
import cancel from '@salesforce/label/c.GeneralCancel';
import save from '@salesforce/label/c.GeneralSave';
import listPrice from '@salesforce/label/c.GeneralListPrice';
import ownPrice from '@salesforce/label/c.GeneralOwnPrice';
import productGroup from '@salesforce/label/c.GeneralProductGroup';
import productSubGroup from '@salesforce/label/c.GeneralProductSubgroup';
import source from '@salesforce/label/c.GeneralSource';
import sourceExtension from '@salesforce/label/c.GeneralSourceExtension';
import sourceOther from '@salesforce/label/c.GeneralSourceOther';
import sourceOwn from '@salesforce/label/c.GeneralSourceOwn';
import searchResults from '@salesforce/label/c.GeneralSearchResults';

// Apex
import removeEntitlement from '@salesforce/apex/AccountAllProductsController.removeEntitlement';
import addEntitlement from '@salesforce/apex/AccountAllProductsController.addEntitlement';


export default class AccountProductTable extends LightningElement {

    @api recordId;
    @track stoppedLoading = false;
    @track selectedProductId = null;
    @track showModal = false;
    @track saveDisabled = true;
    @track activeTab = '1';
    @track showSearchResults = false;
    canManageEntitlement = hasManageEntitlement;
    pageLength = 50;

    label = {
        search,
        availableProducts,
        ownAssortment,
        ownAssortmentOnly,
        productCode,
        product,
        brand,
        listPrice,
        ownPrice,
        productGroup,
        productSubGroup,
        yes,
        no,
        cancel,
        save,
        removeFromAssortment,
        noProductsInThisView,
        ownProducts,
        extensionProducts,
        otherProducts,
        allProducts,
        source,
        sourceOwn,
        sourceExtension,
        sourceOther,
        searchResults
    }

    rows = [];
    ownRows = [];
    extensionRows = [];
    otherRows = [];
    allRows = [];
    resultsRows = [];
    ownRowsCurrentPage = [];
    extensionRowsCurrentPage = [];
    otherRowsCurrentPage = [];
    allRowsCurrentPage = [];
    resultsRowsCurrentPage = [];
    hasOwnProducts = false;
    hasExtensionProducts = false;
    hasOtherProducts = false;
    hasAllProducts = false;
    hasSearchResults = false;
    ownTotal = 0;
    extensionTotal = 0;
    otherTotal = 0;
    allTotal = 0;
    searchResultsTotal = 0;
    showPaginationOwnProducts = false;
    showPaginationExtensionProducts = false;
    showPaginationOtherProducts = false;
    showPaginationAllProducts = false;
    showPaginationSearchResults = false;
    ownOnly = false;
    assortmentExtended = false;
    wiredResult;
    searchTimer = null;

    @wire(getAccountProducts,{accountId:'$recordId'})
    wiredProducts(result){
        this.wiredResult = result;
        if(result.data){
            this.rows = result.data.rows;
            let visibleRows = [...this.rows];            
            this.allRows = JSON.parse(JSON.stringify(visibleRows));
            this.hasAllProducts = this.allRows.length > 0;
            this.showPaginationAllProducts = this.allRows.length > this.pageLength;
            this.allTotal = this.allRows.length;
            this.allRowsCurrentPage = this.allRows.length > this.pageLength ? this.allRows.slice(0, this.pageLength) : this.allRows;
            this.ownRows = visibleRows.filter(c => c.isOwnAssortment === true);
            this.hasOwnProducts = this.ownRows.length > 0;
            this.showPaginationOwnProducts = this.ownRows.length > this.pageLength;
            this.ownTotal = this.ownRows.length;
            this.ownRowsCurrentPage = this.ownRows.length > this.pageLength ? this.ownRows.slice(0, this.pageLength) : this.ownRows;
            this.extensionRows = visibleRows.filter(c => c.isExtension === true);
            this.hasExtensionProducts = this.extensionRows.length > 0;
            this.showPaginationExtensionProducts = this.extensionRows.length > this.pageLength;
            this.extensionTotal = this.extensionRows.length;
            this.extensionRowsCurrentPage = this.extensionRows.length > this.pageLength ? this.extensionRows.slice(0, this.pageLength) : this.extensionRows;
            this.otherRows = visibleRows.filter(c => c.isOther === true);
            this.hasOtherProducts = this.otherRows.length > 0;
            this.showPaginationOtherProducts = this.otherRows.length > this.pageLength;
            this.otherTotal = this.otherRows.length;
            this.otherRowsCurrentPage = this.otherRows.length > this.pageLength ? this.otherRows.slice(0, this.pageLength) : this.otherRows;
            this.assortmentExtended = result.data.assortmentExtended;
            if(!this.assortmentExtended){
                this.columns = this.columns.filter(c => c.fieldName !== 'isOwnAssortment');
            }
            this.stoppedLoading = true;
        }
    }

    get productFilter() {
        let criteria= [
            {
                fieldPath: 'ProductClass',
                operator: 'in',
                value: ['Variation','Simple']
            },
            {
                fieldPath: 'IsActive',
                operator: 'eq',
                value: true
            }
        ]
        // exclude already entitled products
        if(this.excludedProductIds.length){
            criteria.push({
                fieldPath: 'Id',
                operator: 'nin',
                value: this.excludedProductIds
            });
        }

        return { criteria };
    };

    refresh(){
        refreshApex(this.wiredResult);
    }

    columns = [
        {
            label: this.label.product,
            fieldName: 'productUrl',
            type: 'url',
            typeAttributes:{label:{fieldName:'productName'}}
        },
        {
            label: this.label.productCode,
            fieldName: 'productCode'
        },
        {
            label: this.label.productGroup,
            fieldName: 'groupUrl',
            type: 'url',
            typeAttributes: {label:{fieldName:'groupName'}}
        },
        {label: this.label.listPrice, fieldName:'listPrice', type:'currency'},
        {label: this.label.ownPrice, fieldName:'ownPrice', type:'currency'},
        {label: this.label.ownAssortment, fieldName:'isOwnAssortment', type:'boolean'}
    ];

    columnsAll = [
        ...this.columns,
        {
            label: this.label.sourceOwn,
            fieldName: 'ownAssortmentSourceId',
            type: 'url',
            typeAttributes:{label:{fieldName:'ownAssortmentSourceName'}}
        },
        {
            label: this.label.sourceExtension,
            fieldName: 'extensionSourceId',
            type: 'url',
            typeAttributes:{label:{fieldName:'extensionSourceName'}}
        },
        {
            label: this.label.sourceOther,
            fieldName: 'otherSourceId',
            type: 'url',
            typeAttributes:{label:{fieldName:'otherSourceName'}}
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions.bind(this)}
        }
    ];

    columnsOwn = [
        ...this.columns,
        {
            label: this.label.source,
            fieldName: 'ownAssortmentSourceId',
            type: 'url',
            typeAttributes:{label:{fieldName:'ownAssortmentSourceName'}}
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions.bind(this)}
        }
    ];

    columnsExtension = [
        ...this.columns,
        {
            label: this.label.source,
            fieldName: 'extensionSourceId',
            type: 'url',
            typeAttributes:{label:{fieldName:'extensionSourceName'}}
        }
    ];

    columnsOther = [
        ...this.columns,
        {
            label: this.label.source,
            fieldName: 'otherSourceId',
            type: 'url',
            typeAttributes:{label:{fieldName:'otherSourceName'}}
        }
    ];
    
    getRowActions(row, doneCallback) {
        const actions = [];
        if(this.canManageEntitlement && row.isOwnAssortment){
            actions.push({
                label: this.label.removeFromAssortment,
                name: 'remove'
            });
        }

        doneCallback(actions);
    }

    handleSearch(event){
        let searchKey = event.target.value.toLowerCase();
        if(this.searchTimer != null){
            clearTimeout(this.searchTimer);
        }
        let self = this;
        this.searchTimer = setTimeout(() => {
            self.handleSearchDetail(searchKey);
        }, 300);
    }
    handleSearchDetail(searchKey){
        if(stringIsNotBlank(searchKey)){
            this.resultsRows = [];
            let allRows = JSON.parse(JSON.stringify(this.allRows));
            this.resultsRows = allRows.filter(r =>
                (r.productName || '').toLowerCase().includes(searchKey) ||
                (r.productCode || '').toLowerCase().includes(searchKey)
            );
            this.hasSearchResults = this.resultsRows.length > 0;
            this.showPaginationSearchResults = this.resultsRows.length > this.pageLength;
            this.searchResultsTotal = this.resultsRows.length;
            this.resultsRowsCurrentPage = this.resultsRows.length > this.pageLength ? this.resultsRows.slice(0, this.pageLength) : this.resultsRows;
            this.showSearchResults = true;
            setTimeout(() => {
                this.activeTab = '5';
            }, 10);
        } else {
            if(this.activeTab == '5'){
                this.activeTab = '1';
            }
            this.showSearchResults = false;
        }
    }

    handleActive(event){
        this.activeTab = event.target.value;
    }

    handleOpenModal(){
        this.showModal = true;
    }

    handleCloseModal(){
        this.showModal = false;
    }

    handleProductSelect(event){
        this.selectedProductId = event.detail.recordId;
        this.saveDisabled =  !stringIsNotBlank(this.selectedProductId);
    }

    get excludedProductIds(){
        return this.rows
            .filter(r => r.isOwnAssortment)
            .map(r => r.productId);
    }

    handleRowAction(event){
        const actionName = event.detail.action.name;
        const rowInfo = event.detail.row;
        if(actionName === 'remove'){
            removeEntitlement({
                accountId: this.recordId,
                productId: rowInfo.productId
            })
            .then(()=>this.refresh())
        }
    }

    handleSave(){
        addEntitlement({
            accountId:this.recordId,
            productId:this.selectedProductId
        })
        .then(()=>{
            this.handleCloseModal();
            this.selectedProductId = null;
            this.saveDisabled = true;
            this.refresh();
        });
    }

    handleAllPageChange(event){
        let pageNo = event.detail.page;
        let newMin = (pageNo - 1) * this.pageLength;
        let newMax = (pageNo * this.pageLength) < this.allTotal ? (pageNo * this.pageLength) : this.allTotal;
        this.allRowsCurrentPage = this.allRows.slice(newMin, newMax);
    }

    handleExtensionPageChange(event){
        let pageNo = event.detail.page;
        let newMin = (pageNo - 1) * this.pageLength;
        let newMax = (pageNo * this.pageLength) < this.extensionTotal ? (pageNo * this.pageLength) : this.extensionTotal;
        this.extensionRowsCurrentPage = this.extensionRows.slice(newMin, newMax);
    }

    handleOtherPageChange(event){
        let pageNo = event.detail.page;
        let newMin = (pageNo - 1) * this.pageLength;
        let newMax = (pageNo * this.pageLength) < this.otherTotal ? (pageNo * this.pageLength) : this.otherTotal;
        this.otherRowsCurrentPage = this.otherRows.slice(newMin, newMax);
    }

    handleOwnPageChange(event){
        let pageNo = event.detail.page;
        let newMin = (pageNo - 1) * this.pageLength;
        let newMax = (pageNo * this.pageLength) < this.ownTotal ? (pageNo * this.pageLength) : this.ownTotal;
        this.ownRowsCurrentPage = this.ownRows.slice(newMin, newMax);
    }

    handleSearchResultsPageChange(event){
        let pageNo = event.detail.page;
        let newMin = (pageNo - 1) * this.pageLength;
        let newMax = (pageNo * this.pageLength) < this.searchResultsTotal ? (pageNo * this.pageLength) : this.searchResultsTotal;
        this.resultsRowsCurrentPage = this.resultsRows.slice(newMin, newMax);
    }

    getRowClass(row){
        return row.isOwnAssortment ? 'own-row' : '';
    }
}
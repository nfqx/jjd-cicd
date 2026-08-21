import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import custommodalcss from "@salesforce/resourceUrl/custommodalcss";
import removeStyle from '@salesforce/resourceUrl/removeStyle';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Order';

// APEX
import searchProducts from '@salesforce/apex/OrderMaskController.searchProducts';
import sendToOrderSimulation from '@salesforce/apex/OrderMaskController.sendToOrderSimulation';
import createOrder from '@salesforce/apex/OrderMaskController.createOrder';
import saveOrderDraft from '@salesforce/apex/OrderMaskController.saveOrderDraft';
import getAccountContext from '@salesforce/apex/OrderMaskController.getAccountContext';

export default class CustomOrderMask extends LightningElement {

    @api recordId;       
    @api objectApiName;

    currentStep = 1;
    hasRendered = false;
    customNotification = null;
    @track searchType = 'bought';  
    searchTerm = '';  
    isFirstOrder = false;

    currentAccountId;
    @track customerData = {
        name: '',
        customerNumber: '',
        erpNumber: ''
    };
    @track orderData = {
        //step 1
        orderNumber: '',
        source: '',
        type: '',
        requestedDeliveryDate: '',
        orderStartDate: this.todayIsoDate(),
        reason: '',
        description: '',
        //step 2
        poNumber: '',
        //step 3
        billingAddress: '',
        shippingName: '',
        shippingStreet: '',
        shippingCity: '',
        shippingPostalCode: '',
        shippingCountry: '',
        shippingCondition: '',
        pickupLocation: '',
        deliveryText: '',
        carrierNote: ''
    };
    createdOrderId = null;
    foundProducts = [];
    @track cartItems = [];
    @track shippingAddresses = [];
    @track billingAddresses = [];
    selectedShippingAddressId = null;
    recipientAccountId;
    @track recipientAccountData = { name: '', shippingAddress: null };
    isSimulating = false;
    /* FORMAT FOR CART ITEMS
        [
            {
                "01txxxxxxxxxxxx": 
                {
                    "quantity": 4,
                    "productId": "01txxxxxxxxxxxx",
                    "productCode": "1234",
                    "productName": "My Product",
                    "quantityUnitOfMeasure": "kg",
                    "currencyIsoCode": "EUR"
                }
            }
        ]
    */
    erpResponse = {};
    shippingData = {};
    summaryData = {};
    // EXTRACT THESE TWO ABOVE FROM this.erpResponse
    @track orderSourceOptions = [];
    @track orderTypeOptions = [];
    @track pickupLocationOptions = [];
    @track preferredShippingConditionOptions = [];
    @track countryOptions = [];
    @track lineDiscounts = {};              // { prodId: { percent: 10 } | { absolute: 2 } }
    isDiscountModalOpen = false;
    discountModalProductId = null;
    discountType = 'percent';
    discountValue = '';
    @track discountModalItem = null;
    isDifferentShippingAddress = false;
    orderSent = false;

    _activeTimerId;
    _searchRequestId = 0;
    notificationDurationMs = 5000;

    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    orderObjectInfo;
    @wire(getPicklistValuesByRecordType, {
        objectApiName: ORDER_OBJECT,
        recordTypeId: '$orderObjectInfo.data.defaultRecordTypeId'
    })

    wiredAllPicklists({ error, data }) {
        if (data) {
            if (data.picklistFieldValues.Type) {
                const allowedTypes = ['ZTAA', 'ZKLA', 'ZTST', 'ZVOR'];
                this.orderTypeOptions = data.picklistFieldValues.Type.values
                .filter(item => allowedTypes.includes(item.value))
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }

            if (data.picklistFieldValues.OrderSource__c) {
                this.orderSourceOptions = data.picklistFieldValues.OrderSource__c.values
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }
            if (data.picklistFieldValues.PreferredShippingCondition__c) {
                this.preferredShippingConditionOptions = data.picklistFieldValues.PreferredShippingCondition__c.values.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }
            if (data.picklistFieldValues.ShippingCountryCode) {
                this.countryOptions = data.picklistFieldValues.ShippingCountryCode.values.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }
            if (data.picklistFieldValues.PlantLocation__c) {
                this.pickupLocationOptions = data.picklistFieldValues.PlantLocation__c.values.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }
        } else if (error) {
            console.error('Error fetching dynamic picklist configurations:', error);
        }
    }

    renderedCallback() {
        if (!this._contextLoaded && this.recordId) {
            this._contextLoaded = true;
            this.loadAccountContext(this.recordId, this.objectApiName);
        }
        if (this.hasRendered) {
            return;
        }
        this.hasRendered = true;

        loadStyle(this, custommodalcss)
            .catch(error => console.error('Error loading custom modal CSS', error)); 
        try {
            this.headerStyleElement = document.createElement('style');
            this.headerStyleElement.innerText = `
                .slds-modal__header h1 {
                    display: none !important;
                }
                .slds-modal__header {
                    padding: 0 !important; 
                    border-bottom: none !important;
                    height: 0px !important;
                    min-height: 0px !important;
                }
                .slds-modal__header .slds-modal__close {
                    top: 0.5rem !important;
                    right: 0.5rem !important;
                    z-index: 9999 !important;
                }
                .slds-modal__content, 
                .quick-action-panel__body, 
                .slds-quick-action-panel {
                    padding: 0 !important;
                    margin: 0 !important;
                }
            `;
            document.head.appendChild(this.headerStyleElement);
        } catch (error) {
            console.error('Error injecting custom header styles', error);
        }
    }

    loadAccountContext(recordId, objectApiName) {
        if (!recordId) {
            return;
        }
        getAccountContext({ recordId, objectApiName })
            .then(data => {
                this.applyAccountContext(data);
            })
            .catch(error => {
                this.showNotification('error', 'Kein Kundenkontext gefunden.');
                console.error(error);
            });
    }

    applyAccountContext(data) {
        this.currentAccountId = data.accountRecord.Id;
        this.isFirstOrder = data.isFirstOrder === true;

        this.customerData = {
            ...this.customerData,
            name: data.accountRecord.Name,
            customerNumber: data.accountRecord.AccountNumber,
            erpNumber: data.accountRecord.ERPCustomerNumber__c,
            billingAddress: data.accountRecord.BillingAddress
        };

        this.shippingAddresses = [];
        this.billingAddresses = [];
        if (data.addresses && data.addresses.length > 0) {
            this.shippingAddresses = data.addresses.filter(addr => addr.AddressType__c === 'Shipping');
            this.billingAddresses = data.addresses.filter(addr => addr.AddressType__c === 'Billing');
        }

        this.orderData = {
            ...this.orderData,
            billingAddress: ''
        };
        
        this.applyRecipientData(this.currentAccountId, data);
    }

    applyRecipientData(accountId, data) {
        this.recipientAccountId = accountId;

        const shippingAddr = {
            street: data.accountRecord.ShippingStreet,
            postalCode: data.accountRecord.ShippingPostalCode,
            city: data.accountRecord.ShippingCity,
            country: data.accountRecord.ShippingCountryCode  
        };

        this.recipientAccountData = {
            name: data.accountRecord.Name,
            shippingAddress: (shippingAddr.street || shippingAddr.postalCode || shippingAddr.city) ? shippingAddr : null
        };

        this.shippingAddresses = (data.addresses || []).filter(addr => addr.AddressType__c === 'Shipping');
        this.resetRecipientAddressSelection(); 
    }

    handleCancel() {
        this.removeInjectedHeaderStyle();

        loadScript(this, removeStyle)
            .then(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('Error removing style', error);
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    handleSearch(event) {
        window.clearTimeout(this.delayTimeout);
        this.searchTerm = event.target.value;

        if (this.searchTerm.trim().length < 2) {
            this.foundProducts = [];
            return;
        }

        this.delayTimeout = setTimeout(() => this.executeProductSearch(), 300);
    }

    handleTabChange(event) {
        const nextType = event.currentTarget.dataset.type;
        if (!nextType || nextType === this.searchType) return;
        this.searchType = nextType;
        this.executeProductSearch();
    }

    handleTypeChange(event) {
        const previousType = this.orderData.type;
        this.orderData.type = event.detail.value;

        if (this.freeShipping) {
            this.markAllItemsFree();
        } else if (previousType === 'ZKLA') {
            this.lineDiscounts = {};
        }

        if (this.isDirectShipmentOrder) {
            this.isDifferentShippingAddress = false;
            this.selectedShippingAddressId = null;
            this.orderData = {
                ...this.orderData,
                shippingName: '',
                shippingStreet: '',
                shippingCity: '',
                shippingPostalCode: '',
                shippingCountry: ''
            };
        } else {
            this.orderData = { ...this.orderData, shippingName: '' };
            this.resetRecipientAddressSelection();
        }
    }

    markAllItemsFree() {
        const next = {};
        this.cartItems.forEach(wrapper => {
            const prodId = Object.keys(wrapper)[0];
            next[prodId] = { isFree: true };
        });
        this.lineDiscounts = next;
    }

    handleSourceChange(event) {
        this.orderData = { ...this.orderData, source: event.detail.value };
    }

    handleDeliveryDateChange(event) {
        this.orderData = { ...this.orderData, requestedDeliveryDate: event.detail.value || '' };
    }
    handleOrderStartDateChange(event) {
        this.orderData = { ...this.orderData, orderStartDate: event.detail.value };
    }
    handleReasonChange(event) {
        this.orderData = { ...this.orderData, reason: event.detail.value };
    }
    handleDescriptionChange(event) {
        this.orderData = { ...this.orderData, description: event.target.value };
    }
    handlePickupLocationChange(event) {
        this.orderData = { ...this.orderData, pickupLocation: event.detail.value };
    }
    handleDirectShipmentNameChange(event) {
        this.orderData = { ...this.orderData, shippingName: event.target.value };
    }
    handleDirectShipmentStreetChange(event) {
        this.orderData = { ...this.orderData, shippingStreet: event.target.value };
    }
    handleDirectShipmentPostalCodeChange(event) {
        this.orderData = { ...this.orderData, shippingPostalCode: event.target.value };
    }
    handleDirectShipmentCityChange(event) {
        this.orderData = { ...this.orderData, shippingCity: event.target.value };
    }
    handleDirectShipmentCountryChange(event) {
        this.orderData = { ...this.orderData, shippingCountry: event.detail.value };
    }

    handleShippingAddressChange(event) {
        const selectedId = event.detail.value;
        this.selectedShippingAddressId = selectedId;

        const selectedAddr = (this.shippingAddresses || []).find(a => a.Id === selectedId);
        this.setShippingAddressFields(selectedAddr ? selectedAddr.Address__c : null);
    }

    handleDifferentAddressToggle(event) {
        this.isDifferentShippingAddress = event.target.checked;
        this.selectedShippingAddressId = null;
        this.setShippingAddressFields(
            this.isDifferentShippingAddress ? null : this.recipientAccountData.shippingAddress
        );
    }

    handleShippingConditionChange(event) {
        this.orderData.shippingCondition = event.detail.value;
        if (!this.isCustomerPickup) {
            this.orderData = { ...this.orderData, pickupLocation: '' };
        }
    }

    handleSaveDraft() {
        if (!this.currentAccountId) {
            this.showNotification('error', 'Konto fehlt, Entwurf kann nicht gespeichert werden.');
            return;
        }

        saveOrderDraft({
            accountId: this.currentAccountId,
            orderData: this.buildOrderDataPayload(),
            orderItems: this.buildCartItemsPayload(),
            discounts: this.buildDiscountsPayload()
        })
            .then(result => {
                if (result != null && result.success === true) {
                    this.createdOrderId = result.orderId;
                    this.showNotification('info', 'Entwurf wurde gespeichert.');
                } else {
                    const errorMsg = result?.errorText || 'Entwurf konnte nicht gespeichert werden.';
                    this.showNotification('error', errorMsg);
                }
            })
            .catch(error => {
                console.error('Save Draft Apex failed:', error);
                const errorMsg = error?.body?.message || 'Systemfehler.';
                this.showNotification('error', errorMsg);
            });
    }

    todayIsoDate() {
        const d = new Date();
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    }

    loadRecipientContext(accountId) {
        if (!accountId) {
            this.recipientAccountId = null;
            this.recipientAccountData = { name: '', shippingAddress: null };
            this.shippingAddresses = [];
            this.resetRecipientAddressSelection();
            return;
        }
        getAccountContext({ recordId: accountId, objectApiName: 'Account' })
            .then(data => {
                this.recipientAccountId = accountId;

                const shippingAddr = {
                    street: data.accountRecord.ShippingStreet,
                    postalCode: data.accountRecord.ShippingPostalCode,
                    city: data.accountRecord.ShippingCity,
                    country: data.accountRecord.ShippingCountryCode
                };

                this.recipientAccountData = {
                    name: data.accountRecord.Name,
                    shippingAddress: (shippingAddr.street || shippingAddr.postalCode || shippingAddr.city)
                        ? shippingAddr
                        : null
                };
                this.shippingAddresses = (data.addresses || []).filter(
                    addr => addr.AddressType__c === 'Shipping'
                );
                this.resetRecipientAddressSelection(); 
            })
            .catch(error => {
                this.showNotification('error', 'Warenempfänger konnte nicht geladen werden.');
                console.error(error);
            });
    }

    resetRecipientAddressSelection() {
        this.isDifferentShippingAddress = false;
        this.selectedShippingAddressId = null;
        this.setShippingAddressFields(this.recipientAccountData.shippingAddress);
    }

    formatCompoundAddress(addr) {
        if (!addr) return '';
        
        const street = addr.street || addr.Street;
        const postalCode = addr.postalCode || addr.PostalCode;
        const city = addr.city || addr.City;
        
        const formatted = [street, postalCode, city].filter(Boolean).join(', ');
        return formatted;
    }

    handleRecipientAccountChange(event) {
        this.loadRecipientContext(event.detail.recordId);
    }
    /*
    fetchOrderSimulation() {
        if (!this.currentAccountId) {
            this.showNotification('error', 'Konto-ID fehlt.');
            return Promise.reject();
        }
        if (!this.cartItems || this.cartItems.length === 0) {
            this.showNotification('error', 'Warenkorb ist leer.');
            return Promise.reject();
        }

        const cleanOrderItemsPayload = this.buildCartItemsPayload();
        console.log('Sending this flat Map to Apex:', cleanOrderItemsPayload);

        this.isSimulating = true;

        sendToOrderSimulation({ accountId: this.currentAccountId, orderItems: cleanOrderItemsPayload}) //, requestedDate: this.orderData.requestedDeliveryDate 
            .then(result => {
                if(result != null){
                    //this.erpResponse = JSON.parse(JSON.stringify(result));
                    this.erpResponse = result;
                    if (result && result.order) {

                        const orderHeader = result.order;

                        this.shippingData = {
                            requestedDeliveryDate: orderHeader.RequestedDeliveryDate__c,
                            confirmedDeliveryDate: orderHeader.ConfirmedDeliveryDate__c,
                            shippingCondition: orderHeader.ShippingCondition__c,
                            preferredShippingCondition: orderHeader.PreferredShippingCondition__c,
                            shippingCosts: orderHeader.ShippingCosts__c ?? 0
                        };

                        this.summaryData = {
                            netTotal: orderHeader.TotalAmount,
                            taxTotal: orderHeader.TotalTaxAmount,
                            grandTotal: orderHeader.GrandTotalAmount,
                            currencyIsoCode: orderHeader.CurrencyIsoCode,
                            paymentTerms: orderHeader.PaymentTerms__c,
                            orderReference: orderHeader.OrderReferenceNumber,
                            taxRate: result.taxItems && result.taxItems.length > 0 ? result.taxItems[0].taxRate : 0,

                            orderType: orderHeader.Type,
                            salesOrganization: orderHeader.SalesOrganization__c,
                            distributionChannel: orderHeader.DistributionChannel__c,
                            organizationDivision: orderHeader.OrganizationDivision__c,
                            accountErpNumber: orderHeader.Account ? orderHeader.Account.ERPCustomerNumber__c : null,
                            soldToErpNumber: orderHeader.SoldTo__r ? orderHeader.SoldTo__r.ERPCustomerNumber__c : null
                        };

                        this.simulatedCartItems = [];
                        if (orderHeader.OrderItems && orderHeader.OrderItems.length > 0) {
                            this.simulatedCartItems = orderHeader.OrderItems.map(item => {
                                return {
                                    id: item.Product2?.Id || null,
                                    productCode: item.Product2?.ProductCode || '',
                                    unit: item.Product2?.QuantityUnitOfMeasure || '',
                                    lineNumber: item.LineNumber,
                                    quantity: item.Quantity,
                                    availableQuantity: item.AvailableQuantity,

                                    unitPrice: item.UnitPrice,               
                                    grossUnitPrice: item.GrossUnitPrice,      
                                    totalLineTaxAmount: item.TotalLineTaxAmount, 
                                    totalPrice: item.TotalPrice,             
                                    currencyIsoCode: item.CurrencyIsoCode
                                };
                            });
                        }

                        //console.log('Shipping data', this.shippingData);
                        //console.log('Summary data', this.summaryData);
                        console.log('ERP Response data' + JSON.stringify(this.erpResponse));
                        this.isSimulating = false;
                
                    }
                    if (this.erpResponse.hasPriceDifference || this.erpResponse.hasTotalPriceDifference) {
                        this.showNotification('info', 'Preise wurden nach SAP-Abgleich angepasst');
                    }
                    this.currentStep = 4;
                } else {
                    this.showNotification('error','Die Bestellung konnte nicht an das ERP-System übermittelt werden.')
                    //console.log('Order Simulation error');
                }
            })
            .catch(error => {
                console.error(error);
                console.log('Order Simulation failed');
                this.isSimulating = false; 
            });
            
    }
    */
    fetchOrderSimulation() {
        if (!this.currentAccountId) {
            this.showNotification('error', 'Konto-ID fehlt.');
            return Promise.reject(new Error('missing account'));
        }
        if (!this.cartItems || this.cartItems.length === 0) {
            this.showNotification('error', 'Warenkorb ist leer.');
            return Promise.reject(new Error('empty cart'));
        }

        this.isSimulating = true;

        return sendToOrderSimulation({
            accountId: this.currentAccountId,
            orderItems: this.buildCartItemsPayload(),
            orderData: this.buildOrderDataPayload()
        })
            .then(result => {
                if (result == null) {
                    throw new Error('simulation returned null');
                }

                this.erpResponse = result;

                console.log(JSON.stringify(result));

                if (result.order) {
                    const orderHeader = result.order;

                    this.shippingData = {
                        requestedDeliveryDate: orderHeader.RequestedDeliveryDate__c,
                        confirmedDeliveryDate: orderHeader.ConfirmedDeliveryDate__c,
                        shippingCondition: orderHeader.ShippingCondition__c,
                        preferredShippingCondition: orderHeader.PreferredShippingCondition__c,
                        shippingCosts: orderHeader.ShippingCosts__c ?? 0
                    };

                    this.summaryData = {
                        netTotal: orderHeader.TotalAmount,
                        taxTotal: orderHeader.TotalTaxAmount,
                        grandTotal: orderHeader.GrandTotalAmount,
                        currencyIsoCode: orderHeader.CurrencyIsoCode,
                        paymentTerms: orderHeader.PaymentTerms__c,
                        orderReference: orderHeader.OrderReferenceNumber,
                        taxRate: result.taxItems?.length > 0 ? result.taxItems[0].taxRate : 0,
                        orderType: orderHeader.Type,
                        salesOrganization: orderHeader.SalesOrganization__c,
                        distributionChannel: orderHeader.DistributionChannel__c,
                        organizationDivision: orderHeader.OrganizationDivision__c,
                        accountErpNumber: orderHeader.Account?.ERPCustomerNumber__c ?? null,
                        soldToErpNumber: orderHeader.SoldTo__r?.ERPCustomerNumber__c ?? null
                    };
                }

                if (result.hasPriceDifference || result.hasTotalPriceDifference) {
                    this.showNotification('info', 'Preise wurden nach SAP-Abgleich angepasst');
                }

                this.currentStep = 4;
            })
            /*.catch(error => {
                console.error('Order Simulation failed:', error?.body?.message || error);
                this.showNotification('error', 'Die Bestellung konnte nicht an das ERP-System übermittelt werden.');
                throw error;
            })*/
           .catch(error => {
                const details = {
                    name: error?.name ?? null,
                    message: error?.message ?? null,
                    apexMessage: Array.isArray(error?.body)
                        ? error.body.map(item => item?.message).filter(Boolean).join('; ')
                        : error?.body?.message ?? null,
                    status: error?.status ?? null,
                    statusText: error?.statusText ?? null,
                    errorType: error?.errorType ?? null,
                    pageErrors: error?.body?.pageErrors ?? null,
                    fieldErrors: error?.body?.fieldErrors ?? null,
                    outputErrors: error?.body?.output?.errors ?? null
                };

                console.error('Order Simulation failed:', details);

                this.showNotification(
                    'error',
                    details.apexMessage ||
                    details.message ||
                    'Die Bestellung konnte nicht an das ERP-System übermittelt werden.'
                );

                throw error;
            })
            .then(
                result => { this.isSimulating = false; return result; },
                error => { this.isSimulating = false; throw error; }
            );
    }

    createOrderApex() {
        createOrder({ 
            accountId: this.currentAccountId, 
            erpResponse: JSON.stringify(this.erpResponse), 
            orderData: this.buildOrderDataPayload(),
            discounts: this.buildDiscountsPayload() })
            .then(result => {
                if(result != null && result.success === true){
                    console.log(JSON.stringify(result));
                    this.createdOrderId = result.orderId;
                    this.currentStep = 5;
                    this.orderSent = true;
                } else {
                    console.error('Apex returned failure state payload:', JSON.stringify(result));
                    const errorMsg = result?.errorText || 'Unbekannter Fehler bei der Auftragserstellung.';
                    this.showNotification('error', errorMsg);
                }
            })
            .catch(error => {
                console.error('Create Order Apex failed:', error);
                const errorMsg = error?.body?.message || 'Systemfehler.';
                this.showNotification('error', errorMsg);
            });
    }

    buildCartItemsPayload() {
        const rawCartCopy = JSON.parse(JSON.stringify(this.cartItems || []));
        const payload = {};
        rawCartCopy.forEach(wrapper => {
            const prodId = Object.keys(wrapper)[0];
            const item = wrapper[prodId];
            payload[prodId] = {
                quantity: parseInt(item.quantity, 10) || 0,
                productId: item.productId,
                productCode: item.productCode,
                baseProductCode: item.baseProductCode,
                productName: item.productName,
                quantityUnitOfMeasure: item.quantityUnitOfMeasure,
                currencyIsoCode: item.currencyIsoCode
            };
        });
        return payload;
    }

    priceMap = {};
    executeProductSearch() {
        const searchText = (this.searchTerm || '').trim();
        if (searchText.length < 2) {
            this.foundProducts = [];
            return;
        }

        const requestId = ++this._searchRequestId;
        searchProducts({ searchText, accountId: this.currentAccountId, searchType: this.searchType })
            .then(result => {
                if (requestId !== this._searchRequestId) return;
                this.foundProducts = (result || [])
                    .map(wrapper => this.buildProductRow(wrapper))
                    .sort((a, b) => (b.available || 0) - (a.available || 0));
            })
            .catch(error => {
                if (requestId !== this._searchRequestId) return;
                this.foundProducts = [];
                console.error('Product search failed:', error);
                this.showNotification('error', error?.body?.message || 'Produktsuche fehlgeschlagen.');
            });
    }

    buildProductRow(wrapper) {
        let priceMap = wrapper.priceMap;
        const variations = wrapper.variations || [];
        variations.forEach(variation => {
            variation.price = priceMap[variation.Id] ?? 0;
        })
        const preferred = variations.find(v => v.QuantityUnitOfMeasure === 'ST') || variations[0];

        return this.decorateRow({
            key: wrapper.productCode,
            name: wrapper.productName,
            code: wrapper.productCode,
            variations,
            selectedId: preferred ? preferred.Id : null,
            quantity: '1',
            price: preferred.price,
            total: preferred.price
        });
    }

    decorateRow(row) {
        const selected = row.variations.find(v => v.Id === row.selectedId) || null;
        const qty = parseFloat(row.quantity) || 0;
        const price = selected?.price || 0;

        return {
            ...row,
            selected,
            available: selected?.AvailableQuantity__c ?? 0,
            unitLabel: this.unitLabel(selected),
            hasUnitChoice: row.variations.length > 1,
            unitOptions: row.variations.map(v => ({
                label: this.unitLabel(v) || v.ProductCode,
                value: v.Id
            })),
            price,
            total: qty * price,
            addDisabled: !selected
        };
    }
    /*
    unitLabel(prod) {
        return prod ? (prod.QuantityUnitOfMeasure || prod.ProductCode) : '';
    }*/

    unitLabel(prod) {
        if (!prod) return '';
        if (prod.QuantityUnitOfMeasure) return prod.QuantityUnitOfMeasure;

        const code = prod.ProductCode || '';
        const lastDash = code.lastIndexOf('-');
        if (lastDash === -1) return '';

        const suffix = code.substring(lastDash + 1);
        return /^[A-Za-z]+$/.test(suffix) ? suffix.toUpperCase() : '';
    }

    updateRow(key, changes) {
        if (!key) return;
        this.foundProducts = this.foundProducts.map(row =>
            row.key === key ? this.decorateRow({ ...row, ...changes }) : row
        );
    }

    findVariation(prodId) {
        for (const row of this.foundProducts) {
            const match = (row.variations || []).find(v => v.Id === prodId);
            if (match) return match;
        }
        return null;
    }

    handleDeliveryTextChange(event){
        this.orderData.deliveryText = event.detail.value;
    }

    handleCarrierNoteChange(event){
        this.orderData.carrierNote = event.detail.value;
    }

    handleQuantityChange(event) {
        this.updateRow(event.target.dataset.key, { quantity: event.target.value });
    }

    handleUnitChange(event) {
        this.updateRow(event.target.dataset.key, { selectedId: event.detail.value });
    }

    handleCartItemQuantityChange(event) {
        const prodId = event.target.dataset.id;
        let newQty = parseFloat(event.target.value);

        if (!newQty || newQty < 1) {
            newQty = 1; 
        }

        const itemIndex = this.cartItems.findIndex(wrapper => wrapper[prodId] !== undefined);
        
        if (itemIndex !== -1) {
            this.cartItems[itemIndex][prodId].quantity = newQty;
            
            this.cartItems = [...this.cartItems];
        }
    }

    handleDeleteCartItem(event) {
        const prodId = event.currentTarget.dataset.id;
        if (!prodId) return;
        this.cartItems = this.cartItems.filter(wrapper => wrapper[prodId] === undefined);
    }

    handleDeleteCartItemAndResimulate(event) {
        if (this.isSimulating) return;
        clearTimeout(this._qtyTimeout);
        const prodId = event.currentTarget.dataset.id;
        if (!prodId) return;

        const isLastItem = this.displayCartItems.length <= 1;
        if (!isLastItem && !this.freeShipping && !this.hasOtherChargeableItem(prodId)) {
            this.showNotification(
                'warning',
                'Mindestens eine Position muss berechnet werden. Bitte zuerst den Rabatt der übrigen Positionen entfernen oder die Auftragsart auf "Kostenlose Lieferung" (ZKLA) ändern.'
            );
            return;
        }

        const previousCart = this.cartItems;
        const previousDiscounts = this.lineDiscounts;

        const remaining = this.cartItems.filter(wrapper => wrapper[prodId] === undefined);
        this.cartItems = remaining;

        const nextDiscounts = { ...this.lineDiscounts };
        delete nextDiscounts[prodId];
        this.lineDiscounts = nextDiscounts;

        if (remaining.length === 0) {
            this.erpResponse = {};
            this.shippingData = {};
            this.summaryData = {};
            this.currentStep = 2;
            this.showNotification('info', 'Warenkorb ist leer. Bitte Produkte hinzufügen.');
            return;
        }

        this.fetchOrderSimulation()
            .catch(() => {
                this.cartItems = previousCart;
                this.lineDiscounts = previousDiscounts;
            });
    }

    handleSummaryQuantityChange(event) {
        const prodId = event.target.dataset.id;
        let newQty = parseInt(event.target.value, 10);
        if (!prodId || !newQty || newQty < 1) return;

        const index = this.cartItems.findIndex(wrapper => wrapper[prodId] !== undefined);
        if (index === -1) return;
        if (this.cartItems[index][prodId].quantity === newQty) return;

        const previousCart = JSON.parse(JSON.stringify(this.cartItems));

        const next = [...this.cartItems];
        next[index] = { [prodId]: { ...next[index][prodId], quantity: newQty } };
        this.cartItems = next;

        clearTimeout(this._qtyTimeout);
        this._qtyTimeout = setTimeout(() => {
            this.fetchOrderSimulation().catch(() => {
                this.cartItems = previousCart;
            });
        }, 800);
    }

    handleAddItem(event) {
        const key = event.currentTarget.dataset.key;
        const row = this.foundProducts.find(r => r.key === key);
        if (!row || !row.selected) return;

        const qty = parseFloat(row.quantity);
        if (!qty || qty <= 0) return;

        const prod = row.selected;
        const prodId = prod.Id;
        const existingIndex = this.cartItems.findIndex(item => item[prodId] !== undefined);

        if (existingIndex !== -1) {
            this.cartItems[existingIndex][prodId].quantity += qty;
            this.cartItems = [...this.cartItems];
        } else {
            this.cartItems = [...this.cartItems, {
                [prodId]: {
                    quantity: qty,
                    productId: prodId,
                    productCode: prod.ProductCode,
                    baseProductCode: prod.BaseProductCode__c,
                    productName: prod.Name,
                    quantityUnitOfMeasure: prod.QuantityUnitOfMeasure,
                    currencyIsoCode: prod.CurrencyIsoCode,
                    price: prod.price
                }
            }];
        }

        this.updateRow(key, { quantity: '1' });
        if (this.freeShipping) {
            this.lineDiscounts = { ...this.lineDiscounts, [prodId]: { isFree: true } };
        }
    }

    handleNext() {
        if (this.currentStep === 3) {
            console.log('current account', this.currentAccountId)
            this.fetchOrderSimulation().catch(() => {});
            return;
        }
        if (this.currentStep < 4) {
            this.currentStep++;
        }
    }

    setShippingAddressFields(addr) {
        this.orderData = {
            ...this.orderData,
            shippingStreet: addr?.street || addr?.Street || '',
            shippingCity: addr?.city || addr?.City || '',
            shippingPostalCode: addr?.postalCode || addr?.PostalCode || '',
            shippingCountry: addr?.countryCode || addr?.CountryCode || addr?.country || addr?.Country || ''
        };
    }

    handleBack() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
    }

    handleAccountChange(event) {
        const newAccountId = event.detail.recordId;

        if (!newAccountId) {
            this.currentAccountId = null;
            this.isFirstOrder = false;
            this.customerData = { name: '', customerNumber: '', erpNumber: '', billingAddress: '', creditLimit: 0 };
            this.shippingAddresses = [];
            this.billingAddresses = [];
            this.recipientAccountId = null;                                  
            this.recipientAccountData = { name: '', shippingAddress: null };  
            this.isDifferentShippingAddress = false;                          
            this.selectedShippingAddressId = null;                             
            this.orderData = { ...this.orderData, billingAddress: '', shippingName: '', shippingStreet: '', shippingCity: '', shippingPostalCode: '', shippingCountry: '' };
            return;
        }

        this.loadAccountContext(newAccountId, 'Account');
    }

    showNotification(type, message, linkText = null) {
        let icon = 'utility:info';
        let variant = 'info';

        if (type === 'warning') { 
            icon = 'utility:warning'; 
            variant = 'warning'; 
        } else if (type === 'error') { 
            icon = 'utility:error'; 
            variant = 'error'; 
        }

        this.customNotification = { type, message, linkText, icon, variant };

        if (this._activeTimerId) {
            clearTimeout(this._activeTimerId);
        }

        this._activeTimerId = setTimeout(() => {
            this.closeNotification();
        }, this.notificationDurationMs); 
    }

    closeNotification() {
        this.customNotification = null;
        if (this._activeTimerId) {
            clearTimeout(this._activeTimerId);
        }
    }

    disconnectedCallback() {
        this.removeInjectedHeaderStyle();
        clearTimeout(this._activeTimerId);
        clearTimeout(this.delayTimeout);
        clearTimeout(this._qtyTimeout);
        loadScript(this, removeStyle)
            .catch(error => console.error('Cleanup script failed', error));
    }

    removeInjectedHeaderStyle() {
        if (this.headerStyleElement) {
            this.headerStyleElement.remove();
        }
    }

    handleLineAction(event) {
        const action = event.detail.value;
        const prodId = event.target.dataset.id;
        if (!prodId) return;

        if (action === 'discount') {
            const item = this.displayCartItems.find(i => i.id === prodId);
            if (!item) return;
            const existing = this.lineDiscounts[prodId];
            this.discountModalProductId = prodId;
            this.discountModalItem = { name: item.name, quantity: item.quantity, originalUnitPrice: item.originalUnitPrice };
            this.discountType = existing && existing.absolute != null ? 'absolute' : 'percent';
            this.discountValue = (existing && !existing.isFree) ? String(existing.percent ?? existing.absolute) : '';
            this.isDiscountModalOpen = true;
        } else if (action === 'free') {
            if (!this.canMarkItemFree(prodId)) {
                this.showNotification(
                    'warning',
                    'Mindestens eine Position muss berechnet werden. Bitte zuerst die Auftragsart auf "Kostenlose Lieferung" (ZKLA) ändern.'
                );
                return;
            }
            this.lineDiscounts = { ...this.lineDiscounts, [prodId]: { isFree: true } };
        } else if (action === 'remove') {
            const next = { ...this.lineDiscounts };
            delete next[prodId];
            this.lineDiscounts = next;
        }
    }

    hasOtherChargeableItem(prodId) {
        return this.displayCartItems.some(i => i.id !== prodId && (i.unitPrice || 0) > 0);
    }

    canMarkItemFree(prodId) {
        if (this.freeShipping) return true;       
        return this.hasOtherChargeableItem(prodId);
    }

    handleCloseDiscountModal() {
        this.isDiscountModalOpen = false;
        this.discountModalProductId = null;
        this.discountValue = '';
        this.discountType = 'percent';
        this.discountModalItem = null;
    }

    handleDiscountTypeChange(event) {
        this.discountType = event.detail.value;
        this.discountValue = '';
    }

    handleDiscountValueChange(event) {
        this.discountValue = event.target.value;
    }

    handleApplyDiscount() {
        const value = parseFloat(this.discountValue);
        if (!value || value <= 0) return;
        if (this.discountLeavesNoChargeableItem) {
            this.showNotification(
                'warning',
                'Mindestens eine Position muss berechnet werden. Bitte zuerst die Auftragsart auf "Kostenlose Lieferung" (ZKLA) ändern.'
            );
            return;
        }
        const entry = this.discountType === 'percent' ? { percent: value } : { absolute: value };
        this.lineDiscounts = { ...this.lineDiscounts, [this.discountModalProductId]: entry };
        this.handleCloseDiscountModal();
    }

    buildDiscountsPayload() {
        const payload = {};
        Object.keys(this.lineDiscounts).forEach(prodId => {
            const d = this.lineDiscounts[prodId];
            payload[prodId] = {
                percent: d.percent != null ? d.percent : null,
                absolute: d.absolute != null ? d.absolute : null,
                isFree: d.isFree === true
            };
        });
        return payload;
    }

    defaultOrderData() {
        return {
            orderNumber: '',
            source: '',
            type: '',
            requestedDeliveryDate: '',
            orderStartDate: this.todayIsoDate(),
            reason: '',
            description: '',
            poNumber: '',
            billingAddress: '',
            shippingName: '',
            shippingStreet: '',
            shippingCity: '',
            shippingPostalCode: '',
            shippingCountry: '',
            shippingCondition: '',
            pickupLocation: '',
            deliveryText: '',
            carrierNote: ''
        };
    }

    handleBackToCustomer() {
        clearTimeout(this.delayTimeout);
        clearTimeout(this._qtyTimeout);
        this._searchRequestId++;                 

        this.currentStep = 1;
        this.isFirstOrder = false;
        this.orderSent = false;
        this.createdOrderId = null;
        this.isSimulating = false;

        this.cartItems = [];
        this.foundProducts = [];
        this.searchTerm = '';
        this.searchType = 'bought';
        this.lineDiscounts = {};

        this.erpResponse = {};
        this.shippingData = {};
        this.summaryData = {};

        this.handleCloseDiscountModal();
        this.closeNotification();

        this.orderData = this.defaultOrderData();

        this.currentAccountId = null;
        this.customerData = { name: '', customerNumber: '', erpNumber: '', creditLimit: 0 };
        this.shippingAddresses = [];
        this.billingAddresses = [];
        this.recipientAccountId = null;
        this.recipientAccountData = { name: '', shippingAddress: null };
        this.isDifferentShippingAddress = false;
        this.selectedShippingAddressId = null;

        this.loadAccountContext(this.recordId, this.objectApiName);
    }

    // GETTERS
    get isStepOne() { 
        return this.currentStep === 1; 
    }
    get isStepTwo() { 
        return this.currentStep === 2; 
    }
    get isStepThree() { 
        return this.currentStep === 3; 
    }
    get isStepFour() { 
        return this.currentStep === 4; 
    }
    get layoutHorizontalAlign() {
        return this.isStepFour ? 'center' : 'spread';
    }
    get accountDisplayFields() {
        return ['Name', 'AccountNumber'];
    }

    get orderNumber() {
        return this.orderData.orderNumber ? this.orderData.orderNumber : "Wird generiert"
    }

    get accountMatchingFields() {
        return ['Name', 'AccountNumber'];
    }
    get freeShipping(){
        return this.orderData.type === 'ZKLA';
    }
    get toastClasses() {
        return `custom-toast toast-${this.customNotification?.type}`;
    }
    get wizardSteps() {
        return [
            { id: 1, label: 'Kunde & Auftrag' },
            { id: 2, label: 'Produkte' },
            { id: 3, label: 'Lieferung' },
            { id: 4, label: 'Prüfung' }
        ].map(step => {
            const isActive = this.currentStep === step.id;
            const isCompleted = this.currentStep > step.id;

            return {
                id: step.id,
                label: step.label,
                text: isCompleted ? '✓' : step.id,
                labelClass: isActive ? 'label-active' : 'label-inactive',
                circleClass: `custom-step-circle ${isActive ? 'circle-active' : (isCompleted ? 'circle-completed' : 'circle-upcoming')}`
            };
        });
    }
    get progressWidthStyle() {
        if (this.currentStep === 1) return 'width: 0%;';
        if (this.currentStep === 2) return 'width: 33.33%;'; 
        if (this.currentStep === 3) return 'width: 66.66%;';
        if (this.currentStep === 4) return 'width: 100%;';
        return 'width: 0%;';
    }

    get currentAccount() {
        if (this.currentAccountId !== undefined) {
            return this.currentAccountId;
        }
        return this.objectApiName === 'Account' ? this.recordId : null;
    }

    get isStepOneValid() {
        const base = this.currentAccountId 
            && this.orderData.type 
            && this.orderData.source 
            && this.orderData.orderStartDate;

        if (this.freeShipping) {
            return base && this.orderData.reason;
        }
        return base;
    }

    get isStepTwoValid() {
        return this.cartItems && this.cartItems.length > 0;
    }

    get isStepThreeValid() {
        if (!this.orderData.shippingCondition) {
            return false;
        }
        if (this.isCustomerPickup && !this.orderData.pickupLocation) {
            return false;
        }

        if (this.isDirectShipmentOrder) {
            return !!(this.orderData.shippingName
                && this.orderData.shippingStreet
                && this.orderData.shippingPostalCode
                && this.orderData.shippingCity
                && this.orderData.shippingCountry);
        }

        if (!this.recipientAccountId) return false;
        if (this.isDifferentShippingAddress) return !!this.selectedShippingAddressId;
        return true;
    }

    get isNextDisabled() {
        if (this.isStepOne) return !this.isStepOneValid;
        if (this.isStepTwo) return !this.isStepTwoValid;
        if (this.isStepThree) return !this.isStepThreeValid;
        return false;
    }

    get recipientShippingAddressText() {
        if (this.isDifferentShippingAddress) {
            return 'Abweichende Lieferadresse ausgewählt';
        }
        return this.recipientAccountData.shippingAddress
            ? this.formatCompoundAddress(this.recipientAccountData.shippingAddress)
            : 'Keine Lieferadresse hinterlegt';
    }

    get isDirectShipmentOrder() {
        return this.orderData.type === 'ZTST';
    }

    get shippingAddressOptions() {
        return (this.shippingAddresses || []).map(addr => {
            const { street, postalCode, city } = addr.Address__c || {};
            const addressText = [street, postalCode, city].filter(Boolean).join(', ');

            return { label: addressText, value: addr.Id };
        });
    }

    get todayIso() {
        return this.todayIsoDate();
    }

    get effectiveRequestedDeliveryDate() {
        return this.orderData.requestedDeliveryDate || this.todayIso;
    }

    buildOrderDataPayload() {
        return JSON.stringify({
            ...this.orderData,
            requestedDeliveryDate: this.effectiveRequestedDeliveryDate,
            requiresApproval: this.requiresApproval
        });
    }

    get hasCartItems() {
        return this.cartItems && this.cartItems.length > 0;
    }

    get sidebarCartItems() {
        return (this.cartItems || []).map(wrapper => {
            const prodId = Object.keys(wrapper)[0];
            const item = wrapper[prodId];
            const isFree = this.lineDiscounts[prodId]?.isFree === true;

            return {
                id: prodId,
                name: item.productName,
                sku: item.productCode,
                quantity: item.quantity,
                lineTotal: (item.price || 0) * (item.quantity || 0),
                isFree,
                priceClass: isFree
                    ? 'slds-text-color_weak slds-m-top_xxx-small strikethrough-price'
                    : 'slds-text-color_weak slds-m-top_xxx-small',
                currency: item.currencyIsoCode
            };
        });
    }

    get cartTotalClass() {
        return this.freeShipping
            ? 'slds-text-heading_small slds-font-weight_bold cart-total-price strikethrough-price'
            : 'slds-text-heading_small slds-font-weight_bold cart-total-price';
    }
 
    get displayCartItems() {
        if (this.erpResponse && this.erpResponse.order && this.erpResponse.order.OrderItems) {
            return this.erpResponse.order.OrderItems.map(item => {
                const prodId = item.Product2?.Id;
                const productCode = item.Product2?.BaseProductCode__c || item.Product2?.ProductCode;
                const localItem = this.cartItems.find(wrapper => wrapper[prodId] !== undefined);
                const isShortStock = (item.AvailableQuantity || 0) < (item.Quantity || 0);

                const listUnitPrice = item.UnitPrice || 0;
                const qty = item.Quantity || 0;
                const discount = this.lineDiscounts[prodId];

                let unitPrice = listUnitPrice;
                let discountBadge = null;
                let isFree = false;

                if (discount) {
                    if (discount.isFree === true) {
                        isFree = true;
                        unitPrice = 0;
                        discountBadge = 'Ohne Berechnung';
                    } else if (discount.percent != null) {
                        unitPrice = Math.round(listUnitPrice * (1 - discount.percent / 100) * 100) / 100;
                        discountBadge = `Rabatt: -${discount.percent}%`;
                    } else if (discount.absolute != null) {
                        unitPrice = Math.round((listUnitPrice - discount.absolute) * 100) / 100;
                        discountBadge = `Rabatt: -${discount.absolute} EUR`;
                    }
                    if (unitPrice < 0) unitPrice = 0;
                }

                return {
                    id: prodId,
                    name: localItem ? localItem[prodId].productName : productCode,
                    sku: productCode,
                    dotStyle: isShortStock ? 'color: #ea001e;' : 'color: #2e844a;',
                    hasInfo: isShortStock,
                    quantity: qty,
                    unit: item.Product2?.QuantityUnitOfMeasure
                        || (localItem ? localItem[prodId].quantityUnitOfMeasure : ''),
                    unitPrice,
                    originalUnitPrice: listUnitPrice,
                    hasDiscount: !!discount,
                    isFree, 
                    discountBadge,
                    totalPrice: unitPrice * qty,
                    currency: item.CurrencyIsoCode
                };
            });
        }

        if (!this.cartItems || this.cartItems.length === 0) {
            return [];
        }
        
        return this.cartItems.map(wrapper => {
            const prodId = Object.keys(wrapper)[0];
            const item = wrapper[prodId];

            const localProd = this.findVariation(prodId);
            const availableQty = localProd ? (localProd.AvailableQuantity__c || 0) : 0;
            const requestedQty = item.quantity || 0;
            const isShortStock = requestedQty > availableQty;
            
            return {
                id: prodId,
                name: item.productName,
                sku: item.productCode,
                dotStyle: isShortStock ? 'color: #ea001e;' : 'color: #2e844a;',
                hasInfo: isShortStock,
                quantity: item.quantity,
                lineTotal: (item.price ?? 0) * (item.quantity ?? 0), 
                currency: item.currencyIsoCode
            };
        });
    }

    get cartTotal() {
        return this.sidebarCartItems.reduce((acc, item) => {
            acc.total += item.lineTotal;
            return acc;
        }, { total: 0 });
    }

    get isCustomerPickup() {
        return this.orderData.shippingCondition === 'KT' || this.orderData.shippingCondition === 'SA';
    }

    get discountedNetTotal() {
        return this.displayCartItems.reduce((sum, i) => sum + (i.totalPrice || 0), 0);
    }
    get discountedTaxTotal() {
        return this.discountedNetTotal * ((this.summaryData.taxRate || 0) / 100);
    }
    get discountedGrandTotal() {
        return this.discountedNetTotal + this.discountedTaxTotal + this.effectiveShippingCosts;
    }

    get discountTypeOptions() {
        return [
            { label: 'Prozent (%)', value: 'percent' },
            { label: 'Absolutbetrag (EUR)', value: 'absolute' }
        ];
    }

    get isPercentDiscount() {
        return this.discountType === 'percent';
    }

    get discountInputLabel() {
        return this.isPercentDiscount ? 'Rabatt in %' : 'Rabatt in EUR';
    }

    get discountPreview() {
        const item = this.discountModalItem;
        if (!item) return null;

        const listPrice = item.originalUnitPrice;
        const qty = item.quantity || 0;
        const value = parseFloat(this.discountValue) || 0;

        let newUnitPrice = this.isPercentDiscount
            ? Math.round(listPrice * (1 - value / 100) * 100) / 100
            : Math.round((listPrice - value) * 100) / 100;
        if (newUnitPrice < 0) newUnitPrice = 0;

        const savingPerUnit = listPrice - newUnitPrice;

        return {
            newUnitPrice,
            saving: -savingPerUnit,
            percentEquivalent: listPrice > 0 ? ((savingPerUnit / listPrice) * 100).toFixed(1) : '0.0',
            newLineTotal: newUnitPrice * qty
        };
    }
    
    get discountLeavesNoChargeableItem() {
        const preview = this.discountPreview;
        if (!preview || preview.newUnitPrice > 0) return false;
        if (this.freeShipping) return false;
        return !this.hasOtherChargeableItem(this.discountModalProductId);
    }

    get isApplyDiscountDisabled() {
        const value = parseFloat(this.discountValue);
        if (!value || value <= 0) return true;
        if (this.isPercentDiscount) {
            if (value > 100) return true;
        } else {
            const item = this.discountModalItem;
            if (!item || value > item.originalUnitPrice) return true;
        }
        return this.discountLeavesNoChargeableItem;
    }
    get productTabs() {
        return [
            { type: 'bought', label: 'Empfohlen' },
            { type: 'entitled', label: 'Meine Produkte' },
            { type: 'regular', label: 'Alle' }
        ].map(tab => ({
            ...tab,
            cssClass: this.searchType === tab.type ? 'pill-btn' : 'pill-btn-inactive',
            variant: this.searchType === tab.type ? 'brand' : 'neutral'
        }));
    }

    get activeTabLabel() {
        return this.productTabs.find(t => t.type === this.searchType)?.label || '';
    }

    get foundProductsCount() {
        return this.foundProducts.length;
    }

    get reasonOptions() {
        return [
            { label: 'Ersatz / Reklamation', value: 'Ersatz / Reklamation' },
            { label: 'Packfehler', value: 'Packfehler' },
            { label: 'Leihvereinbarung', value: 'Leihvereinbarung' }
        ];
    }
    get isExpressShipping() {
        const opt = this.preferredShippingConditionOptions.find(o => o.value === this.orderData.shippingCondition);
        return !!opt && /express/i.test(opt.label);
    }

    get approvalNetTotal() {
        return this.isStepFour ? this.discountedNetTotal : this.cartTotal.total;
    }

    get requiresApproval() {
        if (this.freeShipping) return true;
        if (this.isExpressShipping) return true;

        const net = this.approvalNetTotal;
        if (net > 10000) return true;
        return this.isFirstOrder && net > 5000;
    }
    get originalNetTotal() {
        return this.displayCartItems.reduce(
            (sum, i) => sum + ((i.originalUnitPrice || 0) * (i.quantity || 0)), 0
        );
    }
    get effectiveShippingCosts() {
        return this.freeShipping ? 0 : (this.shippingData.shippingCosts || 0);
    }

    get originalShippingCosts() {
        return this.shippingData.shippingCosts || 0;
    }
    get originalTaxTotal() {
        return this.originalNetTotal * ((this.summaryData.taxRate || 0) / 100);
    }
    get originalGrandTotal() {
        return this.originalNetTotal + this.originalTaxTotal + this.originalShippingCosts;
    }
}
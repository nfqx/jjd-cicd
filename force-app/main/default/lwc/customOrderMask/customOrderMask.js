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

// LABELS
import orderMaskAction from '@salesforce/label/c.OrderMaskAction';
import orderMaskActions from '@salesforce/label/c.OrderMaskActions';
import orderMaskAdd from '@salesforce/label/c.OrderMaskAdd';
import orderMaskAfterApprovalAutomaticTransmissionToSAP from '@salesforce/label/c.OrderMaskAfterApprovalAutomaticTransmissionToSAP';
import orderMaskAmount from '@salesforce/label/c.OrderMaskAmount';
import orderMaskApplyDiscount from '@salesforce/label/c.OrderMaskApplyDiscount';
import orderMaskApprovalBySalesManagerRequired from '@salesforce/label/c.OrderMaskApprovalBySalesManagerRequired';
import orderMaskApprovalRequired from '@salesforce/label/c.OrderMaskApprovalRequired';
import orderMaskArticleItem from '@salesforce/label/c.OrderMaskArticleItem';
import orderMaskAwaitingApproval from '@salesforce/label/c.OrderMaskAwaitingApproval';
import orderMaskBack from '@salesforce/label/c.OrderMaskBack';
import orderMaskBackToCustomer from '@salesforce/label/c.OrderMaskBackToCustomer';
import orderMaskCancel from '@salesforce/label/c.OrderMaskCancel';
import orderMaskChargeShippingCosts from '@salesforce/label/c.OrderMaskChargeShippingCosts';
import orderMaskClickOrTypeToSearchEnterInTheQuantityFieldAddsTheArticle from '@salesforce/label/c.OrderMaskClickOrTypeToSearchEnterInTheQuantityFieldAddsTheArticle';
import orderMaskClose from '@salesforce/label/c.OrderMaskClose';
import orderMaskCondition from '@salesforce/label/c.OrderMaskCondition';
import orderMaskConfirmedDate from '@salesforce/label/c.OrderMaskConfirmedDate';
import orderMaskCustNo from '@salesforce/label/c.OrderMaskCustNo';
import orderMaskCustomer from '@salesforce/label/c.OrderMaskCustomer';
import orderMaskCustomerInfo from '@salesforce/label/c.OrderMaskCustomerInfo';
import orderMaskCustomerMasterLookupTipNameOrCustomerNo from '@salesforce/label/c.OrderMaskCustomerMasterLookupTipNameOrCustomerNo';
import orderMaskCustomerOrder from '@salesforce/label/c.OrderMaskCustomerOrder';
import orderMaskCustomerPONo from '@salesforce/label/c.OrderMaskCustomerPONo';
import orderMaskCustomerPurchaseOrderNumber from '@salesforce/label/c.OrderMaskCustomerPurchaseOrderNumber';
import orderMaskCustomerSStoredAddresses from '@salesforce/label/c.OrderMaskCustomerSStoredAddresses';
import orderMaskDate from '@salesforce/label/c.OrderMaskDate';
import orderMaskDateOfOrderEntry from '@salesforce/label/c.OrderMaskDateOfOrderEntry';
import orderMaskDelivery from '@salesforce/label/c.OrderMaskDelivery';
import orderMaskDeliveryNotesOptional from '@salesforce/label/c.OrderMaskDeliveryNotesOptional';
import orderMaskDeliveryText from '@salesforce/label/c.OrderMaskDeliveryText';
import orderMaskDifferentDeliveryAddress from '@salesforce/label/c.OrderMaskDifferentDeliveryAddress';
import orderMaskDiscountType from '@salesforce/label/c.OrderMaskDiscountType';
import orderMaskDraft from '@salesforce/label/c.OrderMaskDraft';
import orderMaskEarliestPossible from '@salesforce/label/c.OrderMaskEarliestPossible';
import orderMaskEnterArticleNoOrDescription from '@salesforce/label/c.OrderMaskEnterArticleNoOrDescription';
import orderMaskFreeDeliverySampleOrderMandatoryFields from '@salesforce/label/c.OrderMaskFreeDeliverySampleOrderMandatoryFields';
import orderMaskFreeNoCharge from '@salesforce/label/c.OrderMaskFreeNoCharge';
import orderMaskFreeOfCharge from '@salesforce/label/c.OrderMaskFreeOfCharge';
import orderMaskGoodsRecipient from '@salesforce/label/c.OrderMaskGoodsRecipient';
import orderMaskGoodsValueNet from '@salesforce/label/c.OrderMaskGoodsValueNet';
import orderMaskGrantDiscount from '@salesforce/label/c.OrderMaskGrantDiscount';
import orderMaskInternalRemark from '@salesforce/label/c.OrderMaskInternalRemark';
import orderMaskLineItems from '@salesforce/label/c.OrderMaskLineItems';
import orderMaskListPrice from '@salesforce/label/c.OrderMaskListPrice';
import orderMaskMandatoryFieldSalesManagerMustKnowTheReason from '@salesforce/label/c.OrderMaskMandatoryFieldSalesManagerMustKnowTheReason';
import orderMaskNewAmount from '@salesforce/label/c.OrderMaskNewAmount';
import orderMaskNewOrder from '@salesforce/label/c.OrderMaskNewOrder';
import orderMaskNewPriceUnit from '@salesforce/label/c.OrderMaskNewPriceUnit';
import orderMaskNext from '@salesforce/label/c.OrderMaskNext';
import orderMaskNoLineItemsYet from '@salesforce/label/c.OrderMaskNoLineItemsYet';
import orderMaskNoteForCarrier from '@salesforce/label/c.OrderMaskNoteForCarrier';
import orderMaskNoteForCarrierPlaceholder from '@salesforce/label/c.OrderMaskNoteForCarrierPlaceholder';
import orderMaskNotesForSalesManagerOrColleagues from '@salesforce/label/c.OrderMaskNotesForSalesManagerOrColleagues';
import orderMaskNotTransmittedToTheCustomer from '@salesforce/label/c.OrderMaskNotTransmittedToTheCustomer';
import orderMaskOnlyRelevantForFreightShipping from '@salesforce/label/c.OrderMaskOnlyRelevantForFreightShipping';
import orderMaskOnlyRelevantForSelfPickup from '@salesforce/label/c.OrderMaskOnlyRelevantForSelfPickup';
import orderMaskOrderDate from '@salesforce/label/c.OrderMaskOrderDate';
import orderMaskOrderSentAwaitingApprovalBySalesManager from '@salesforce/label/c.OrderMaskOrderSentAwaitingApprovalBySalesManager';
import orderMaskOrderSource from '@salesforce/label/c.OrderMaskOrderSource';
import orderMaskOrderSuccessfullyTransmitted from '@salesforce/label/c.OrderMaskOrderSuccessfullyTransmitted';
import orderMaskOrderType from '@salesforce/label/c.OrderMaskOrderType';
import orderMaskPickupLocation from '@salesforce/label/c.OrderMaskPickupLocation';
import orderMaskPleaseSelect from '@salesforce/label/c.OrderMaskPleaseSelect';
import orderMaskPrice from '@salesforce/label/c.OrderMaskPrice';
import orderMaskPriceUnit from '@salesforce/label/c.OrderMaskPriceUnit';
import orderMaskPrintedOnTheDeliveryNote from '@salesforce/label/c.OrderMaskPrintedOnTheDeliveryNote';
import orderMaskPrintOrderConfirmation from '@salesforce/label/c.OrderMaskPrintOrderConfirmation';
import orderMaskProducts from '@salesforce/label/c.OrderMaskProducts';
import orderMaskQuantity from '@salesforce/label/c.OrderMaskQuantity';
import orderMaskQuantity2 from '@salesforce/label/c.OrderMaskQuantity2';
import orderMaskQuoteIsWithSalesManagementForApproval from '@salesforce/label/c.OrderMaskQuoteIsWithSalesManagementForApproval';
import orderMaskReasonFreeDelivery from '@salesforce/label/c.OrderMaskReasonFreeDelivery';
import orderMaskRecalculating from '@salesforce/label/c.OrderMaskRecalculating';
import orderMaskRecommendationBasedOnOrderWeight from '@salesforce/label/c.OrderMaskRecommendationBasedOnOrderWeight';
import orderMaskRemarkFreeDelivery from '@salesforce/label/c.OrderMaskRemarkFreeDelivery';
import orderMaskRemoveDiscount from '@salesforce/label/c.OrderMaskRemoveDiscount';
import orderMaskRequestedDeliveryDate from '@salesforce/label/c.OrderMaskRequestedDeliveryDate';
import orderMaskSaveDraft from '@salesforce/label/c.OrderMaskSaveDraft';
import orderMaskSaving from '@salesforce/label/c.OrderMaskSaving';
import orderMaskSelectAddress from '@salesforce/label/c.OrderMaskSelectAddress';
import orderMaskSelectDeliveryAddress from '@salesforce/label/c.OrderMaskSelectDeliveryAddress';
import orderMaskSendOrder from '@salesforce/label/c.OrderMaskSendOrder';
import orderMaskSendOrderConfirmation from '@salesforce/label/c.OrderMaskSendOrderConfirmation';
import orderMaskShipping from '@salesforce/label/c.OrderMaskShipping';
import orderMaskShippingMethod from '@salesforce/label/c.OrderMaskShippingMethod';
import orderMaskSource from '@salesforce/label/c.OrderMaskSource';
import orderMaskStateReason from '@salesforce/label/c.OrderMaskStateReason';
import orderMaskSummary from '@salesforce/label/c.OrderMaskSummary';
import orderMaskTextForDeliveryNote from '@salesforce/label/c.OrderMaskTextForDeliveryNote';
import orderMaskTotalGross from '@salesforce/label/c.OrderMaskTotalGross';
import orderMaskTotalNet from '@salesforce/label/c.OrderMaskTotalNet';
import orderMaskTransmittedToSAP from '@salesforce/label/c.OrderMaskTransmittedToSAP';
import orderMaskUnit from '@salesforce/label/c.OrderMaskUnit';
import orderMaskVAT from '@salesforce/label/c.OrderMaskVAT';
import expressCosts from '@salesforce/label/c.OrderMaskExpressCharge';

const ORDER_SOURCE_BY_CONTEXT = {
    Case: 'E-mail',
    Account: 'Telefon'
};
const round2 = (value) => Math.round(value * 100) / 100;
const PRODUCT_PAGE_SIZE = 50;
const MAX_PRODUCT_OFFSET = 2000;

export default class CustomOrderMask extends LightningElement {

    @api recordId;       
    @api objectApiName;

    label = {
        orderMaskAction,
        orderMaskActions,
        orderMaskAdd,
        orderMaskAfterApprovalAutomaticTransmissionToSAP,
        orderMaskAmount,
        orderMaskApplyDiscount,
        orderMaskApprovalBySalesManagerRequired,
        orderMaskApprovalRequired,
        orderMaskArticleItem,
        orderMaskAwaitingApproval,
        orderMaskBack,
        orderMaskBackToCustomer,
        orderMaskCancel,
        orderMaskChargeShippingCosts,
        orderMaskClickOrTypeToSearchEnterInTheQuantityFieldAddsTheArticle,
        orderMaskClose,
        orderMaskCondition,
        orderMaskConfirmedDate,
        orderMaskCustNo,
        orderMaskCustomer,
        orderMaskCustomerInfo,
        orderMaskCustomerMasterLookupTipNameOrCustomerNo,
        orderMaskCustomerOrder,
        orderMaskCustomerPONo,
        orderMaskCustomerPurchaseOrderNumber,
        orderMaskCustomerSStoredAddresses,
        orderMaskDate,
        orderMaskDateOfOrderEntry,
        orderMaskDelivery,
        orderMaskDeliveryNotesOptional,
        orderMaskDeliveryText,
        orderMaskDifferentDeliveryAddress,
        orderMaskDiscountType,
        orderMaskDraft,
        orderMaskEarliestPossible,
        orderMaskEnterArticleNoOrDescription,
        orderMaskFreeDeliverySampleOrderMandatoryFields,
        orderMaskFreeNoCharge,
        orderMaskFreeOfCharge,
        orderMaskGoodsRecipient,
        orderMaskGoodsValueNet,
        orderMaskGrantDiscount,
        orderMaskInternalRemark,
        orderMaskLineItems,
        orderMaskListPrice,
        orderMaskMandatoryFieldSalesManagerMustKnowTheReason,
        orderMaskNewAmount,
        orderMaskNewOrder,
        orderMaskNewPriceUnit,
        orderMaskNext,
        orderMaskNoLineItemsYet,
        orderMaskNoteForCarrier,
        orderMaskNoteForCarrierPlaceholder,
        orderMaskNotesForSalesManagerOrColleagues,
        orderMaskNotTransmittedToTheCustomer,
        orderMaskOnlyRelevantForFreightShipping,
        orderMaskOnlyRelevantForSelfPickup,
        orderMaskOrderDate,
        orderMaskOrderSentAwaitingApprovalBySalesManager,
        orderMaskOrderSource,
        orderMaskOrderSuccessfullyTransmitted,
        orderMaskOrderType,
        orderMaskPickupLocation,
        orderMaskPleaseSelect,
        orderMaskPrice,
        orderMaskPriceUnit,
        orderMaskPrintedOnTheDeliveryNote,
        orderMaskPrintOrderConfirmation,
        orderMaskProducts,
        orderMaskQuantity,
        orderMaskQuantity2,
        orderMaskQuoteIsWithSalesManagementForApproval,
        orderMaskReasonFreeDelivery,
        orderMaskRecalculating,
        orderMaskRecommendationBasedOnOrderWeight, 
        orderMaskRemarkFreeDelivery,
        orderMaskRemoveDiscount, 
        orderMaskRequestedDeliveryDate,
        orderMaskSaveDraft,
        orderMaskSaving,
        orderMaskSelectAddress,
        orderMaskSelectDeliveryAddress,
        orderMaskSendOrder,
        orderMaskSendOrderConfirmation,
        orderMaskShipping,
        orderMaskShippingMethod,
        orderMaskSource,
        orderMaskStateReason,
        orderMaskSummary,
        orderMaskTextForDeliveryNote,
        orderMaskTotalGross,
        orderMaskTotalNet,
        orderMaskTransmittedToSAP,
        orderMaskUnit,
        orderMaskVAT,
        expressCosts
    };

    productsHasMore = false;
    isLoadingProducts = false;
    _productOffset = 0;
    productsTotalCount = null;

    currentStep = 1;
    hasRendered = false;
    customNotification = null;
    @track searchType = 'entitled';  
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
        customerReference: '',
        source: this.defaultOrderSource,
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
    @track reasonOptions = [];
    @track pickupLocationOptions = [];
    @track preferredShippingConditionOptions = [];
    @track lineDiscounts = {};              // { prodId: { percent: 10 } | { absolute: 2 } }
    isDiscountModalOpen = false;
    discountModalProductId = null;
    discountType = 'percent';
    discountValue = '';
    @track discountModalItem = null;
    isDifferentShippingAddress = false;
    isShippingFree = false;
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
                    .map(item => ({ label: item.label, value: item.value }));
            }
            if (data.picklistFieldValues.PreferredShippingCondition__c) {
                this.preferredShippingConditionOptions = data.picklistFieldValues.PreferredShippingCondition__c.values.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }
            if (data.picklistFieldValues.FreeDeliveryReason__c) {
                this.reasonOptions = data.picklistFieldValues.FreeDeliveryReason__c.values.map(item => ({
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
        this.observeProductSentinel();
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
            billingAddress: '',
            source: this.orderData.source || this.defaultOrderSource
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
        this.searchTerm = event.target.value;
        window.clearTimeout(this.delayTimeout);
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
        this.orderData = { ...this.orderData, type: event.detail.value };

        if (this.isFreeDeliveryOrder) {
            this.markAllItemsFree();
        } else if (previousType === 'ZKLA') {
            this.lineDiscounts = {};
            this.orderData = { ...this.orderData, reason: '', description: '' };
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

    handleCustomerReferenceChange(event) {
        this.orderData = { ...this.orderData, customerReference: event.detail.value };
    }
    
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

                if(!result.success){
                    throw new Error('Error: ' + result.errorMessage + ', Error Logging ID: ' + result.errorLoggingId);
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
            discounts: this.buildDiscountsPayload(),
            isExpress: this.isExpressShipping
        })
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

    executeProductSearch(loadMore = false) {
        const term = (this.searchTerm || '').trim();
        const searchText = term.length >= 2 ? term : '';

        if (!loadMore) {
            this._searchRequestId++;
            this.productsTotalCount = null;
            this._productOffset = 0;
            this.foundProducts = [];
            this.isLoadingProducts = false;
            this.productsHasMore = !!this.currentAccountId;
        }
        if (!this.currentAccountId || !this.productsHasMore || this.isLoadingProducts) return;

        const requestId = this._searchRequestId;
        this.isLoadingProducts = true;
        searchProducts({ searchText, accountId: this.currentAccountId, searchType: this.searchType, offsetRows: this._productOffset })
            .then(page => {
                if (requestId !== this._searchRequestId) return;
                const rows = (page?.products || []).map(wrapper => this.buildProductRow(wrapper));
                if (page?.totalCount != null) this.productsTotalCount = page.totalCount;
                this.foundProducts = this.mergeProductRows(rows);
                this._productOffset += PRODUCT_PAGE_SIZE;
                this.productsHasMore = rows.length > 0
                    && this.foundProducts.length < (this.productsTotalCount ?? Infinity)
                    && this._productOffset <= MAX_PRODUCT_OFFSET;
            })
            .catch(error => {
                if (requestId !== this._searchRequestId) return;
                this.productsHasMore = false;
                console.error('Product search failed:', error);
                this.showNotification('error', error?.body?.message || 'Produktsuche fehlgeschlagen.');
            })
            .finally(() => {
                if (requestId !== this._searchRequestId) return;
                this.isLoadingProducts = false;
                // re-observing fires a fresh check, so a page that doesn't fill the screen loads the next one
                if (this._sentinel) {
                    this._productObserver.unobserve(this._sentinel);
                    this._productObserver.observe(this._sentinel);
                }
            });
    }

    mergeProductRows(newRows) {
        const merged = [...this.foundProducts];
        newRows.forEach(row => {
            const idx = merged.findIndex(r => r.key === row.key);
            if (idx === -1) { merged.push(row); return; }
            const known = new Set(merged[idx].variations.map(v => v.Id));
            const extra = row.variations.filter(v => !known.has(v.Id));
            if (extra.length) {
                merged[idx] = this.decorateRow({ ...merged[idx], variations: [...merged[idx].variations, ...extra] });
            }
        });
        return merged;
    }

    observeProductSentinel() {
        const sentinel = this.template.querySelector('.product-list-sentinel');
        if (sentinel === this._sentinel) return;
        this._productObserver?.disconnect();
        this._sentinel = sentinel;
        if (!sentinel) return;
        this._productObserver = new IntersectionObserver(
            entries => { if (entries[0].isIntersecting) this.executeProductSearch(true); },
            { rootMargin: '200px' }
        );
        this._productObserver.observe(sentinel);
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
            price: preferred?.price ?? 0, 
            total: preferred?.price ?? 0
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
        if (!isLastItem && !this.isFreeDeliveryOrder && !this.hasOtherChargeableItem(prodId)) {
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
        const index = this.cartItems.findIndex(wrapper => wrapper[prodId] !== undefined);
        if (!prodId || index === -1) return;

        const current = this.cartItems[index][prodId].quantity;
        const raw = event.target.value;

        if (raw === '' || raw == null) {
            this.refreshQuantityInput(prodId, current);
            return;
        }

        const newQty = parseInt(raw, 10);
        if (isNaN(newQty) || newQty < 1) {
            this.refreshQuantityInput(prodId, current);
            return;
        }
        if (newQty === current) return;

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

    handleQuantityKeyDown(event) {
        if (event.key === 'Enter') {
            event.target.blur();
        } else if (event.key === 'Escape') {
            const prodId = event.target.dataset.id;
            const index = this.cartItems.findIndex(wrapper => wrapper[prodId] !== undefined);
            if (index !== -1) {
                this.refreshQuantityInput(prodId, this.cartItems[index][prodId].quantity);
            }
            event.target.blur();
        }
    }

    refreshQuantityInput(prodId, value) {
        const input = this.template.querySelector(`lightning-input.qty-input[data-id="${prodId}"]`);
        if (input) input.value = value;
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
        if (this.isFreeDeliveryOrder) {
            this.lineDiscounts = { ...this.lineDiscounts, [prodId]: { isFree: true } };
        }
    }

    handleNext() {
        if (this.currentStep === 3) {
            this.fetchOrderSimulation().catch(() => {});
            return;
        }
        if (this.currentStep < 4) {
            this.currentStep++;
            if (this.currentStep === 2) {
                this.executeProductSearch();
            }
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
        this._productObserver?.disconnect();
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
            this.discountValue = (existing && !existing.isFree && existing.absolute > 0)
                ? String(existing.percent ?? existing.absolute)
                : (existing?.percent != null ? String(existing.percent) : '');
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

    handleShippingAction(event) {
        const action = event.detail.value;
        if (action === 'free') {
            this.isShippingFree = true;
        } else if (action === 'remove') {
            this.isShippingFree = false;
        }
    }

    hasOtherChargeableItem(prodId) {
        return this.displayCartItems.some(i => i.id !== prodId && (i.unitPrice || 0) > 0);
    }

    canMarkItemFree(prodId) {
        if (this.isFreeDeliveryOrder) return true;       
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
            source: this.defaultOrderSource,
            type: '',
            requestedDeliveryDate: '',
            orderStartDate: this.todayIsoDate(),
            reason: '',
            description: '',
            customerReference: '',
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
        this.searchType = 'entitled';
        this.lineDiscounts = {};
        this.isShippingFree = false;

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

    get accountMatchingFields() {
        return ['Name', 'AccountNumber'];
    }
    get isFreeDeliveryOrder(){
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
        const base = !!(this.currentAccountId
            && this.orderData.type
            && this.orderData.source
            && this.orderData.orderStartDate
            && (this.orderData.customerReference || '').trim());

        return this.isFreeDeliveryOrder ? base && !!this.orderData.reason : base;
    }

    get isStepTwoValid() {
        return this.cartItems && this.cartItems.length > 0;
    }

    get isStepThreeValid() {
        if (!this.orderData.shippingCondition) return false;
        if (this.isCustomerPickup && !this.orderData.pickupLocation) return false;
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
            freeShippingCosts: this.isShippingCostFree,
            requiresApproval: this.requiresApproval
        });
    }

    get hasCartItems() {
        return this.cartItems && this.cartItems.length > 0;
    }

    get defaultOrderSource() {
        return ORDER_SOURCE_BY_CONTEXT[this.objectApiName] || '';
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
        return this.isFreeDeliveryOrder
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
                        unitPrice = round2(listUnitPrice - discount.absolute);
                        discountBadge = discount.absolute > 0
                            ? `Rabatt: ${discount.absolute} EUR`
                            : `Aufschlag: ${Math.abs(discount.absolute)} EUR`;
                    }
                    if (unitPrice < 0) unitPrice = 0;
                }

                const priceChanged = round2(unitPrice - listUnitPrice) !== 0;

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
                    priceChanged,
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
        return this.sidebarCartItems.reduce((sum, item) => sum + item.lineTotal, 0);
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
        if (this.isFreeDeliveryOrder) return false;
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

    get foundProductsCount() { return this.productsTotalCount ?? this.foundProducts.length; }

    get isExpressShipping() {
        const opt = this.preferredShippingConditionOptions.find(o => o.value === this.orderData.shippingCondition);
        return !!opt && /express/i.test(opt.label);
    }
    get isExpressSaturdayShipping() {
        const opt = this.preferredShippingConditionOptions.find(o => o.value === this.orderData.shippingCondition);
        return !!opt && /express/i.test(opt.label) && /saturday/i.test(opt.label);
    }

    get approvalNetTotal() {
        if (this.isStepFour) return this.discountedNetTotal;
        return this.isFreeDeliveryOrder ? 0 : this.cartTotal;
    }

    get requiresApproval() {
        if (this.isShippingFree) return true;
        const net = this.approvalNetTotal;
        if (net > 10000) return true;
        return this.isFirstOrder && net > 5000;
    }

    get originalNetTotal() {
        return this.displayCartItems.reduce(
            (sum, i) => sum + ((i.originalUnitPrice || 0) * (i.quantity || 0)), 0
        );
    }

    get expressCosts(){
        return this.isExpressShipping ? parseFloat(this.label.expressCosts) : 0;
    }
    get originalShippingCosts() {
        return (this.shippingData.shippingCosts || 0) + this.expressCosts;
    }
    get originalTaxTotal() {
        return this.originalNetTotal * ((this.summaryData.taxRate || 0) / 100);
    }
    get originalGrandTotal() {
        return this.originalNetTotal + this.originalTaxTotal + this.originalShippingCosts;
    }
    get hasFoundProducts() { return this.foundProducts.length > 0 || this.isLoadingProducts; }
    get emptyProductsText() { return 'Keine Artikel gefunden.'; }

    handleUnitPriceChange(event) {
        const prodId = event.target.dataset.id;
        const item = this.displayCartItems.find(i => i.id === prodId);
        if (!prodId || !item) return;

        const raw = event.target.value;
        if (raw === '' || raw == null || isNaN(parseFloat(raw))) {
            this.refreshPriceInput(prodId, item.unitPrice);
            return;
        }

        const value = round2(parseFloat(event.target.value));
            if (value < 0) {
            this.refreshPriceInput(prodId, item.unitPrice);
            return;
        }

        if (value === 0 && !this.canMarkItemFree(prodId)) {
            this.showNotification(
                'warning',
                'Mindestens eine Position muss berechnet werden. Bitte zuerst die Auftragsart auf "Kostenlose Lieferung" (ZKLA) ändern.'
            );
            this.refreshPriceInput(prodId, item.unitPrice);
            return;
        }

        const delta = round2(item.originalUnitPrice - value);
        const next = { ...this.lineDiscounts };
        if (delta === 0) {
            delete next[prodId];                  // back at the ERP price = no adjustment
        } else {
            next[prodId] = { absolute: delta };   // positive = Rabatt, negative = Aufschlag
        }
        this.lineDiscounts = next;
    }

    handlePriceKeyDown(event) {
        if (event.key === 'Enter') {
            event.target.blur();   
        } else if (event.key === 'Escape') {
            const prodId = event.target.dataset.id;
            const item = this.displayCartItems.find(i => i.id === prodId);
            if (item) this.refreshPriceInput(prodId, item.unitPrice);
            event.target.blur();
        }
    }

    refreshPriceInput(prodId, value) {
        const input = this.template.querySelector(`lightning-input.price-input[data-id="${prodId}"]`);
        if (input) input.value = value;
    }

    get isPriceEditDisabled() {
        return this.isSimulating || this.isFreeDeliveryOrder;
    }

    get isShippingCostFree() {
        return this.isFreeDeliveryOrder || this.isShippingFree;
    }

    get effectiveShippingCosts() {
        return (this.isShippingCostFree ? 0 : (this.shippingData.shippingCosts || 0)) + this.expressCosts;
    }
}
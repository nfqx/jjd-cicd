import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle, loadScript  } from "lightning/platformResourceLoader";
import custommodalcss from "@salesforce/resourceUrl/custommodalcss";
import removeStyle from '@salesforce/resourceUrl/removeStyle';
import { stringIsNotBlank } from 'c/stringHelper';
import { getObjectInfo, getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import Id from '@salesforce/user/Id';

// APEX
import retrievePrefill from '@salesforce/apex/ReturnOrderController.retrievePrefill';
import reselectAddressesAndPricebook from '@salesforce/apex/ReturnOrderController.reselectAddressesAndPricebook';
import searchWithIds from '@salesforce/apex/LookupController.searchWithIds';
import searchWithIdsAndReference from '@salesforce/apex/LookupController.searchWithIdsAndReference';
import createReturnOrder from '@salesforce/apex/ReturnOrderController.createReturnOrder';
import reselectPositionsFromOrder from '@salesforce/apex/ReturnOrderController.reselectPositionsFromOrder';
import reselectPositionsFromInvoice from '@salesforce/apex/ReturnOrderController.reselectPositionsFromInvoice';
import getSinglePriceByOrderSimulation from '@salesforce/apex/ReturnOrderController.getSinglePriceByOrderSimulation';
import getProductVariations from '@salesforce/apex/ReturnOrderController.getProductVariations';

import accountDetails from '@salesforce/label/c.ReturnOrderMaskAccountDetails';
import add from '@salesforce/label/c.ReturnOrderMaskAdd';
import address from '@salesforce/label/c.ReturnOrderMaskAddress';
import allActiveDarbovenProducts from '@salesforce/label/c.ReturnOrderMaskAllActiveDarbovenProducts';
import allActiveProducts from '@salesforce/label/c.ReturnOrderMaskAllActiveProducts';
import allMatchingProductsAdded from '@salesforce/label/c.ReturnOrderMaskAllMatchingProductsAdded';
import amount from '@salesforce/label/c.ReturnOrderMaskAmount';
import amountLargerThanReference from '@salesforce/label/c.ReturnOrderMaskAmountLargerThanReference';
import andXMore from '@salesforce/label/c.ReturnOrderMaskAndXMore';
import answerGoodsOrCredit from '@salesforce/label/c.ReturnOrderMaskAnswerGoodsOrCredit';
import answerPreliminaryQuestion from '@salesforce/label/c.ReturnOrderMaskAnswerPreliminaryQuestion';
import answerRefundQuestion from '@salesforce/label/c.ReturnOrderMaskAnswerRefundQuestion';
import arrivalDate from '@salesforce/label/c.ReturnOrderMaskArrivalDate';
import appliesToEntireCase from '@salesforce/label/c.ReturnOrderMaskAppliesToEntireCase';
import backToEditing from '@salesforce/label/c.ReturnOrderMaskBackToEditing';
import backToReference from '@salesforce/label/c.ReturnOrderMaskBackToReference';
import cancel from '@salesforce/label/c.ReturnOrderMaskCancel';
import caseLabel from '@salesforce/label/c.ReturnOrderMaskCase';
import caseCategory from '@salesforce/label/c.ReturnOrderMaskCaseCategory';
import caseCategoryType from '@salesforce/label/c.ReturnOrderMaskCaseCategoryType';
import caseInvoice from '@salesforce/label/c.ReturnOrderMaskCaseInvoice';
import caseInformation from '@salesforce/label/c.ReturnOrderMaskCaseInformation';
import caseOrder from '@salesforce/label/c.ReturnOrderMaskCaseOrder';
import caseReason from '@salesforce/label/c.ReturnOrderMaskCaseReason';
import caseSelections from '@salesforce/label/c.ReturnOrderMaskCaseSelections';
import caseType from '@salesforce/label/c.ReturnOrderMaskCaseType';
import checkLabel from '@salesforce/label/c.ReturnOrderMaskCheck';
import changeAccount from '@salesforce/label/c.ReturnOrderMaskChangeAccount';
import changed from '@salesforce/label/c.ReturnOrderMaskChanged';
import changedAccountBody from '@salesforce/label/c.ReturnOrderMaskChangedAccountBody';
import changedAccountHeader from '@salesforce/label/c.ReturnOrderMaskChangedAccountHeader';
import changedAccountModalBody from '@salesforce/label/c.ReturnOrderMaskChangedAccountModalBody';
import changedAccountModalHeader from '@salesforce/label/c.ReturnOrderMaskChangedAccountModalHeader';
import chooseSelectionsFirst from '@salesforce/label/c.ReturnOrderMaskChooseSelectionsFirst';
import collectiveInvoiceFor from '@salesforce/label/c.ReturnOrderMaskCollectiveInvoiceFor';
import continueToEditing from '@salesforce/label/c.ReturnOrderMaskContinueToEditing';
import coreProductRange from '@salesforce/label/c.ReturnOrderMaskCoreProductRange';
import credit from '@salesforce/label/c.ReturnOrderMaskCredit';
import creditPosition from '@salesforce/label/c.ReturnOrderMaskCreditPosition';
import creditValue from '@salesforce/label/c.ReturnOrderMaskCreditValue';
import customer from '@salesforce/label/c.ReturnOrderMaskCustomer';
import customerNumber from '@salesforce/label/c.ReturnOrderMaskCustomerNumber';
import customerReceivesRefund from '@salesforce/label/c.ReturnOrderMaskCustomerReceivesRefund';
import customerShips from '@salesforce/label/c.ReturnOrderMaskCustomerShips';
import customerShipsGoodsText from '@salesforce/label/c.ReturnOrderMaskCustomerShipsGoodsText';
import darbovenArrangesTransport from '@salesforce/label/c.ReturnOrderMaskDarbovenArrangesTransport';
import dateLabel from '@salesforce/label/c.ReturnOrderMaskDate';
import datePlaceholder from '@salesforce/label/c.ReturnOrderMaskDatePlaceholder';
import deliveryAddress from '@salesforce/label/c.ReturnOrderMaskDeliveryAddress';
import derived from '@salesforce/label/c.ReturnOrderMaskDerived';
import derivedFromSelections from '@salesforce/label/c.ReturnOrderMaskDerivedFromSelections';
import destroyedAtCustomers from '@salesforce/label/c.ReturnOrderMaskDestroyedAtCustomers';
import details from '@salesforce/label/c.ReturnOrderMaskDetails';
import documentLinesBehavior from '@salesforce/label/c.ReturnOrderMaskDocumentLinesBehavior';
import editLabel from '@salesforce/label/c.ReturnOrderMaskEdit';
import editable from '@salesforce/label/c.ReturnOrderMaskEditable';
import editLineItems from '@salesforce/label/c.ReturnOrderMaskEditLineItems';
import emails from '@salesforce/label/c.ReturnOrderMaskEmails';
import errorLabel from '@salesforce/label/c.ReturnOrderMaskError';
import expectedArrivalDateHelp from '@salesforce/label/c.ReturnOrderMaskExpectedArrivalDateHelp';
import finalReviewInstructions from '@salesforce/label/c.ReturnOrderMaskFinalReviewInstructions';
import fromInvoice from '@salesforce/label/c.ReturnOrderMaskFromInvoice';
import fromOrder from '@salesforce/label/c.ReturnOrderMaskFromOrder';
import goodsAlreadyReceived from '@salesforce/label/c.ReturnOrderMaskGoodsAlreadyReceived';
import goodsAlreadyThereInfo from '@salesforce/label/c.ReturnOrderMaskGoodsAlreadyThereInfo';
import goodsBeingReturned from '@salesforce/label/c.ReturnOrderMaskGoodsBeingReturned';
import goodsMovement from '@salesforce/label/c.ReturnOrderMaskGoodsMovement';
import goodsReceivedWhen from '@salesforce/label/c.ReturnOrderMaskGoodsReceivedWhen';
import goodsWillBePickedUp from '@salesforce/label/c.ReturnOrderMaskGoodsWillBePickedUp';
import identified from '@salesforce/label/c.ReturnOrderMaskIdentified';
import identifiedFromCase from '@salesforce/label/c.ReturnOrderMaskIdentifiedFromCase';
import includedOrders from '@salesforce/label/c.ReturnOrderMaskIncludedOrders';
import inDocument from '@salesforce/label/c.ReturnOrderMaskInDocument';
import industry from '@salesforce/label/c.ReturnOrderMaskIndustry';
import inSAP from '@salesforce/label/c.ReturnOrderMaskInSAP';
import internalNote from '@salesforce/label/c.ReturnOrderMaskInternalNote';
import internalNotePlaceholder from '@salesforce/label/c.ReturnOrderMaskInternalNotePlaceholder';
import invoice from '@salesforce/label/c.ReturnOrderMaskInvoice';
import invoiceFor from '@salesforce/label/c.ReturnOrderMaskInvoiceFor';
import invoiceReset from '@salesforce/label/c.ReturnOrderMaskInvoiceReset';
import itemsFromProductSearch from '@salesforce/label/c.ReturnOrderMaskItemsFromProductSearch';
import itemsInTableBelow from '@salesforce/label/c.ReturnOrderMaskItemsInTableBelow';
import lineItem from '@salesforce/label/c.ReturnOrderMaskLineItem';
import lineItems from '@salesforce/label/c.ReturnOrderMaskLineItems';
import lineItemType from '@salesforce/label/c.ReturnOrderMaskLineItemType';
import manual from '@salesforce/label/c.ReturnOrderMaskManual';
import manually from '@salesforce/label/c.ReturnOrderMaskManually';
import mode from '@salesforce/label/c.ReturnOrderMaskMode';
import multipleTypesPossibleInfo from '@salesforce/label/c.ReturnOrderMaskMultipleTypesPossibleInfo';
import newAccount from '@salesforce/label/c.ReturnOrderMaskNewAccount';
import noDocumentReason from '@salesforce/label/c.ReturnOrderMaskNoDocumentReason';
import noDocumentReasonExample from '@salesforce/label/c.ReturnOrderMaskNoDocumentReasonExample';
import noDocumentReasonHelp from '@salesforce/label/c.ReturnOrderMaskNoDocumentReasonHelp';
import noGoodsReturned from '@salesforce/label/c.ReturnOrderMaskNoGoodsReturned';
import noGoodsValueCreditInfo from '@salesforce/label/c.ReturnOrderMaskNoGoodsValueCreditInfo';
import noLineItemsYet from '@salesforce/label/c.ReturnOrderMaskNoLineItemsYet';
import noneLabel from '@salesforce/label/c.ReturnOrderMaskNone';
import noNotices from '@salesforce/label/c.ReturnOrderMaskNoNotices';
import noPriceFoundProductNotAdded from '@salesforce/label/c.ReturnOrderMaskNoPriceFoundProductNotAdded';
import noReturnOrderWithoutGoods from '@salesforce/label/c.ReturnOrderMaskNoReturnOrderWithoutGoods';
import notInCustomerListing from '@salesforce/label/c.ReturnOrderMaskProductNotInCustomerListing';
import notInReference from '@salesforce/label/c.ReturnOrderMaskProductNotInReference';
import noValueCreditOnly from '@salesforce/label/c.ReturnOrderMaskNoValueCreditOnly';
import noWithoutCredit from '@salesforce/label/c.ReturnOrderMaskNoWithoutCredit';
import notChosenYet from '@salesforce/label/c.ReturnOrderMaskNotChosenYet';
import openLabel from '@salesforce/label/c.ReturnOrderMaskOpen';
import optional from '@salesforce/label/c.ReturnOrderMaskOptional';
import orderLabel from '@salesforce/label/c.ReturnOrderMaskOrder';
import orderDocument from '@salesforce/label/c.ReturnOrderMaskOrderDocument';
import orderReset from '@salesforce/label/c.ReturnOrderMaskOrderReset';
import orders from '@salesforce/label/c.ReturnOrderMaskOrders';
import otherClearance from '@salesforce/label/c.ReturnOrderMaskOtherClearance';
import outsideDocumentProducts from '@salesforce/label/c.ReturnOrderMaskOutsideDocumentProducts';
import picklistChangedReason from '@salesforce/label/c.ReturnOrderMaskPicklistChangedReason';
import picklistValuesNote from '@salesforce/label/c.ReturnOrderMaskPicklistValuesNote';
import pickupAddressHelp from '@salesforce/label/c.ReturnOrderMaskPickupAddressHelp';
import pickupLocation from '@salesforce/label/c.ReturnOrderMaskPickupLocation';
import pleaseSelect from '@salesforce/label/c.ReturnOrderMaskPleaseSelect';
import price from '@salesforce/label/c.ReturnOrderMaskPrice';
import product from '@salesforce/label/c.ReturnOrderMaskProduct';
import productCode from '@salesforce/label/c.ReturnOrderMaskProductCode';
import productListing from '@salesforce/label/c.ReturnOrderMaskProductListing';
import productsAvailable from '@salesforce/label/c.ReturnOrderMaskProductsAvailable';
import productSearchHelp from '@salesforce/label/c.ReturnOrderMaskProductSearchHelp';
import productSearchPlaceholder from '@salesforce/label/c.ReturnOrderMaskProductSearchPlaceholder';
import quantity from '@salesforce/label/c.ReturnOrderMaskQuantity';
import readyForRetrieval from '@salesforce/label/c.ReturnOrderMaskReadyForRetrieval';
import reason from '@salesforce/label/c.ReturnOrderMaskReason';
import refundAbove100Notice from '@salesforce/label/c.ReturnOrderMaskRefundAbove100Notice';
import refundNo from '@salesforce/label/c.ReturnOrderMaskRefundNo';
import refundYes from '@salesforce/label/c.ReturnOrderMaskRefundYes';
import referenceLabel from '@salesforce/label/c.ReturnOrderMaskReference';
import referenceRelation from '@salesforce/label/c.ReturnOrderMaskReferenceRelation';
import registerArrivalDate from '@salesforce/label/c.ReturnOrderMaskRegisterArrivalDate';
import remainWithCustomer from '@salesforce/label/c.ReturnOrderMaskRemainWithCustomer';
import requestedPickupDate from '@salesforce/label/c.ReturnOrderMaskRequestedPickupDate';
import requestedPickupDateHelp from '@salesforce/label/c.ReturnOrderMaskRequestedPickupDateHelp';
import returnLabel from '@salesforce/label/c.ReturnOrderMaskReturn';
import returnShippingMethodHelp from '@salesforce/label/c.ReturnOrderMaskReturnShippingMethodHelp';
import reviewAndComplete from '@salesforce/label/c.ReturnOrderMaskReviewAndComplete';
import searchAccount from '@salesforce/label/c.ReturnOrderMaskSearchAccount';
import searchAddress from '@salesforce/label/c.ReturnOrderMaskSearchAddress';
import searchInvoice from '@salesforce/label/c.ReturnOrderMaskSearchInvoice';
import searchOrder from '@salesforce/label/c.ReturnOrderMaskSearchOrder';
import searchProduct from '@salesforce/label/c.ReturnOrderMaskSearchProduct';
import selectCaseReason from '@salesforce/label/c.ReturnOrderMaskSelectCaseReason';
import selectGoodsMovement from '@salesforce/label/c.ReturnOrderMaskSelectGoodsMovement';
import selectReference from '@salesforce/label/c.ReturnOrderMaskSelectReference';
import selectReferenceDocument from '@salesforce/label/c.ReturnOrderMaskSelectReferenceDocument';
import selectShippingMethod from '@salesforce/label/c.ReturnOrderMaskSelectShippingMethod';
import shippingMethod from '@salesforce/label/c.ReturnOrderMaskShippingMethod';
import shipToAddressDifferent from '@salesforce/label/c.ReturnOrderMaskShipToAddressDifferent';
import sourceLabel from '@salesforce/label/c.ReturnOrderMaskSource';
import standardDeliveryAddress from '@salesforce/label/c.ReturnOrderMaskStandardDeliveryAddress';
import statusLabel from '@salesforce/label/c.ReturnOrderMaskStatus';
import stillOpen from '@salesforce/label/c.ReturnOrderMaskStillOpen';
import subject from '@salesforce/label/c.ReturnOrderMaskSubject';
import submitSAPGoodsReceiptInfo from '@salesforce/label/c.ReturnOrderMaskSubmitSAPGoodsReceiptInfo';
import submitSAPStartsPickupInfo from '@salesforce/label/c.ReturnOrderMaskSubmitSAPStartsPickupInfo';
import submitToSAP from '@salesforce/label/c.ReturnOrderMaskSubmitToSAP';
import subtype from '@salesforce/label/c.ReturnOrderMaskSubtype';
import successLabel from '@salesforce/label/c.ReturnOrderMaskSuccess';
import successMessage from '@salesforce/label/c.ReturnOrderMaskSuccessMessage';
import tableNotices from '@salesforce/label/c.ReturnOrderMaskTableNotices';
import totalGoodsValue from '@salesforce/label/c.ReturnOrderMaskTotalGoodsValue';
import typeLabel from '@salesforce/label/c.ReturnOrderMaskType';
import unannouncedReturnReceived from '@salesforce/label/c.ReturnOrderMaskUnannouncedReturnReceived';
import unit from '@salesforce/label/c.ReturnOrderMaskUnit';
import valueCredit from '@salesforce/label/c.ReturnOrderMaskValueCredit';
import valueGoodwill from '@salesforce/label/c.ReturnOrderMaskValueGoodwill';
import valueLabel from '@salesforce/label/c.ReturnOrderMaskValue';
import valuePriceError from '@salesforce/label/c.ReturnOrderMaskValuePriceError';
import valueQualityClaim from '@salesforce/label/c.ReturnOrderMaskValueQualityClaim';
import valueQuantityCorrection from '@salesforce/label/c.ReturnOrderMaskValueQuantityCorrection';
import valueWrongGoodsDestroyed from '@salesforce/label/c.ReturnOrderMaskValueWrongGoodsDestroyed';
import valuesLabel from '@salesforce/label/c.ReturnOrderMaskValues';
import warningOnePosition from '@salesforce/label/c.ReturnOrderMaskWarningOnePosition';
import warningSelectReference from '@salesforce/label/c.ReturnOrderMaskWarningSelectReference';
import warnings from '@salesforce/label/c.ReturnOrderMaskWarnings';
import withCredit from '@salesforce/label/c.ReturnOrderMaskWithCredit';
import withLabel from '@salesforce/label/c.ReturnOrderMaskWith';
import withoutCredit from '@salesforce/label/c.ReturnOrderMaskWithoutCredit';
import without from '@salesforce/label/c.ReturnOrderMaskWithout';
import whoMovesGoodsHelp from '@salesforce/label/c.ReturnOrderMaskWhoMovesGoodsHelp';
import whereAreGoods from '@salesforce/label/c.ReturnOrderMaskWhereAreGoods';
import withoutDocument from '@salesforce/label/c.ReturnOrderMaskWithoutDocument';
import withoutDocumentLower from '@salesforce/label/c.ReturnOrderMaskWithoutDocumentLower';
import yesCreditOnlyCase from '@salesforce/label/c.ReturnOrderMaskYesCreditOnlyCase';
import yesGoodsReturned from '@salesforce/label/c.ReturnOrderMaskYesGoodsReturned';
import yesWithCredit from '@salesforce/label/c.ReturnOrderMaskYesWithCredit';

/* SCHEMA */
import PRODUCT2_OBJECT from '@salesforce/schema/Product2';
import RETURN_ORDER_OBJECT from '@salesforce/schema/ReturnOrder';
import QUANTITY_UNIT_OF_MEASURE_FIELD from '@salesforce/schema/Product2.QuantityUnitOfMeasure';
import RETURN_ORDER_TYPE_FIELD from '@salesforce/schema/ReturnOrder.ReturnOrderType__c';
import SHIPPING_CONDITION_FIELD from '@salesforce/schema/ReturnOrder.ShippingCondition__c';
import RETURN_REASON_FIELD from '@salesforce/schema/ReturnOrder.ReturnReason__c';

export default class ReturnOrderMaskInner extends LightningElement {

    userId = Id;
    @api recordId;
    useExtendedProductLookup = true; //this.userId == '0059O000017BrTbQAK' || this.userId == '0059O000017BrTb';

    label = {
        accountDetails,
        add,
        address,
        allActiveDarbovenProducts,
        allActiveProducts,
        allMatchingProductsAdded,
        amount,
        amountLargerThanReference,
        andXMore,
        answerGoodsOrCredit,
        answerPreliminaryQuestion,
        answerRefundQuestion,
        appliesToEntireCase,
        arrivalDate,
        backToEditing,
        backToReference,
        cancel,
        caseLabel,
        caseCategory,
        caseCategoryType,
        caseInformation,
        caseInvoice,
        caseOrder,
        caseReason,
        caseSelections,
        caseType,
        changeAccount,
        changed,
        changedAccountBody,
        changedAccountHeader,
        changedAccountModalBody,
        changedAccountModalHeader,
        checkLabel,
        chooseSelectionsFirst,
        collectiveInvoiceFor,
        continueToEditing,
        coreProductRange,
        credit,
        creditPosition,
        creditValue,
        customer,
        customerNumber,
        customerReceivesRefund,
        customerShips,
        customerShipsGoodsText,
        darbovenArrangesTransport,
        dateLabel,
        datePlaceholder,
        deliveryAddress,
        derived,
        derivedFromSelections,
        destroyedAtCustomers,
        details,
        documentLinesBehavior,
        editLabel,
        editable,
        editLineItems,
        emails,
        errorLabel,
        expectedArrivalDateHelp,
        finalReviewInstructions,
        fromInvoice,
        fromOrder,
        goodsAlreadyReceived,
        goodsAlreadyThereInfo,
        goodsBeingReturned,
        goodsMovement,
        goodsReceivedWhen,
        goodsWillBePickedUp,
        identified,
        identifiedFromCase,
        includedOrders,
        inDocument,
        industry,
        inSAP,
        internalNote,
        internalNotePlaceholder,
        invoice,
        invoiceFor,
        invoiceReset,
        itemsFromProductSearch,
        itemsInTableBelow,
        lineItem,
        lineItems,
        lineItemType,
        manual,
        manually,
        mode,
        multipleTypesPossibleInfo,
        newAccount,
        noDocumentReason,
        noDocumentReasonExample,
        noDocumentReasonHelp,
        noGoodsReturned,
        noGoodsValueCreditInfo,
        noLineItemsYet,
        noneLabel,
        noNotices,
        noPriceFoundProductNotAdded,
        noReturnOrderWithoutGoods,
        notInCustomerListing,
        notInReference,
        noValueCreditOnly,
        noWithoutCredit,
        notChosenYet,
        openLabel,
        optional,
        orderLabel,
        orderDocument,
        orderReset,
        orders,
        otherClearance,
        outsideDocumentProducts,
        picklistChangedReason,
        picklistValuesNote,
        pickupAddressHelp,
        pickupLocation,
        pleaseSelect,
        price,
        product,
        productCode,
        productListing,
        productsAvailable,
        productSearchHelp,
        productSearchPlaceholder,
        quantity,
        readyForRetrieval,
        reason,
        refundAbove100Notice,
        refundYes,
        refundNo,
        referenceLabel,
        referenceRelation,
        registerArrivalDate,
        remainWithCustomer,
        requestedPickupDate,
        requestedPickupDateHelp,
        returnLabel,
        returnShippingMethodHelp,
        reviewAndComplete,
        searchAccount,
        searchAddress,
        searchInvoice,
        searchOrder,
        searchProduct,
        selectCaseReason,
        selectGoodsMovement,
        selectReference,
        selectReferenceDocument,
        selectShippingMethod,
        shippingMethod,
        shipToAddressDifferent,
        sourceLabel,
        standardDeliveryAddress,
        statusLabel,
        stillOpen,
        subject,
        submitSAPGoodsReceiptInfo,
        submitSAPStartsPickupInfo,
        submitToSAP,
        subtype,
        successLabel,
        successMessage,
        tableNotices,
        totalGoodsValue,
        typeLabel,
        unannouncedReturnReceived,
        unit,
        valueCredit,
        valueGoodwill,
        valueLabel,
        valuePriceError,
        valueQualityClaim,
        valueQuantityCorrection,
        valueWrongGoodsDestroyed,
        valuesLabel,
        warningOnePosition,
        warningSelectReference,
        warnings,
        whereAreGoods,
        whoMovesGoodsHelp,
        withCredit,
        withLabel,
        withoutCredit,
        without,
        withoutDocument,
        withoutDocumentLower,
        yesCreditOnlyCase,
        yesGoodsReturned,
        yesWithCredit
    }

    /* TRACKED */
    @track priceError = null;
    @track addressRequestVersion = 0;
    @track addressRequestPending = false;
    @track addressNeedsRefresh = false;
    @track isLoading = false;
    @track page4success = false;
    @track page4error = null;
    @track returnOrderCreatedId = null;
    @track existingReturnOrderId = null;
    @track lastHandledAccountId = null;
    @track committedAccountId = null;
    @track committedAccountName = null;
    @track temporaryAccount = null;
    @track temporaryAccountName = null;
    @track step = 1;
    @track stepOneLevelOne = 1;
    @track stepOneLevelTwo = 1;
    @track preloadData = {};
    @track loaded = false;
    @track unitPicklistValues = [];
    @track returnOrderTypeOptions = [];
    @track returnOrderTypeMap = {};
    @track returnReasonOptions = [];
    @track returnReasonMap = {};
    @track returnShippingConditionOptions = [];
    @track returnShippingConditionMap = {};
    @track customerPricebook = {};
    @track customerPricebookSaved = {};
    @track params = {
        'goodsReturn': null,
        'goodsMovement': null,
        'internalNote': null,
        'reasonNoReference': null,
        'refund': null,
        'caseReason': null,
        'arrivalDate': null,
        'shippingMethod': null,
        'reference': null,
        'caseType': 'ZREA',
        'whereAreGoods': null
    };
    @track showAccountDetails = false;
    @track selectedAccountId = null;
    @track selectedAccountName = null;
    @track selectedOrderId = null;
    @track selectedAddressId = null;
    @track selectedInvoiceId = null;
    @track accountPrefill = null;
    @track orderPrefill = null;
    @track invoicePrefill = null;
    @track addressPrefill = null;
    @track accountPrefillSaved = null;
    @track orderPrefillSaved = null;
    @track invoicePrefillSaved = null;
    @track addressPrefillSaved = null;
    @track prefillOrderPositions = [];
    @track prefillInvoicePositions = [];
    @track lastOrderPositions = [];
    @track lastInvoicePositions = [];
    @track manualPricesByProductId = {};
    @track lastOrderSelection = null;
    @track lastInvoiceSelection = null;
    @track lastOrderId = null;
    @track lastInvoiceId = null;
    @track orderRequestVersion = 0;
    @track invoiceRequestVersion = 0;
    @track variationRequestVersionsByRowId = {};
    @track prefillReturnOrderItems = [];
    @track positions = [];
    @track positionProductIds = [];
    @track totalValue = 0;
    @track totalGoodsValue = 0;
    @track shipToNotEqualsBillTo = false;
    @track stepTwoSeen = false;
    @track stepThreeSeen = false;
    @track showAccountChangeModal = false;    
    @track invoiceCreatedDate = null;
    @track invoiceTotal = null;
    @track invoiceStatus = null;
    @track invoiceType = null;
    @track invoiceSubtext = null;        
    @track orderCreatedDate = null;
    @track orderTotal = null;
    @track orderStatus = null;
    @track orderSubtext = null;
    @track invoiceOrders = [];
    @track invoiceOrdersSaved = [];
    @track productWarnings = [];
    @track customerListingProductIds = [];
    @track customerListingProductIdsSaved = [];
    @track customerListingLoaded = false;
    @track coreAssortmentProducts = [];
    @track coreAssortmentProductsSaved = [];
    @track listedProducts = [];
    @track listedProductsSaved = [];
    

    /* PICKLISTS */

    caseReasonOptionsLite = [
        {value: 'priceError', label: this.label.valuePriceError},
        {value: 'wrongGoodsDestroyed', label: this.label.valueWrongGoodsDestroyed},
        {value: 'qualityClaim', label: this.label.valueQualityClaim},
        {value: 'goodwill', label: this.label.valueGoodwill},
        {value: 'quantityCorrection', label: this.label.valueQuantityCorrection},
    ];

    goodsMovementOptions = [
        {value: 'pickup', label: this.label.goodsWillBePickedUp + '\r\n' + this.label.darbovenArrangesTransport},
        {value: 'shipping', label: this.label.customerShips + '\r\n' + this.label.customerShipsGoodsText},
        {value: 'received', label: this.label.goodsAlreadyReceived + '\r\n' + this.label.unannouncedReturnReceived},
    ];

    creditIssuancePicklistValues = [
        {value: 'WITH', label: this.label.withCredit},
        {value: 'WITHOUT', label: this.label.withoutCredit}
    ];

    whereAreGoodsOptions = [
        {value: 'remain', label: this.label.remainWithCustomer},
        {value: 'destroy', label: this.label.destroyedAtCustomers},
        {value: 'other', label: this.label.otherClearance}
    ]

    goodsMovementLabelMap = {
        'pickup': this.label.goodsWillBePickedUp,
        'shipping': this.label.customerShips,
        'received': this.label.goodsAlreadyReceived
    };

    referenceLabelMap = {
        'ORDER': this.label.orderLabel,
        'INVOICE': this.label.invoice,
        'NONE': this.label.withoutDocumentLower
    };

    /* TABLE COLUMNS */ 

    viewColumns = [
        {label: null, fieldName: 'rowStateDisplay', type: 'text', cellAttributes: {class: {fieldName: 'rowStateClass'}, alignment: 'center'}, sortable: false, hideDefaultActions: true, fixedWidth: 24},
        {label: this.label.product, fieldName: 'name', type: 'productSimple', typeAttributes: {title: {fieldName: 'name'}, subtitle: {fieldName: 'description'}}, sortable: false, hideDefaultActions: true, wrapText: true},
        {label: this.label.quantity, fieldName: 'quantity', sortable: false, hideDefaultActions: true},
        {label: this.label.unit, fieldName: 'quantityUnitOfMeasure', sortable: false, hideDefaultActions: true},
        {label: this.label.price, fieldName: 'priceDisplay', sortable: false, hideDefaultActions: true},
        {label: this.label.lineItemType, fieldName: 'creditIssuanceDisplay', sortable: false, hideDefaultActions: true},
        {label: this.label.reason, fieldName: 'returnReasonLong', sortable: false, hideDefaultActions: true},
        {label: this.label.valueLabel, fieldName: 'totalPriceDisplay', sortable: false, hideDefaultActions: true},
    ];

    editColumnsOne = [
        {label: null, fieldName: 'rowStateDisplay', type: 'text', cellAttributes: {class: {fieldName: 'rowStateClass'}, alignment: 'center'}, sortable: false, hideDefaultActions: true, fixedWidth: 24},
        {label: this.label.product, fieldName: 'name', type: 'product', typeAttributes: {title: {fieldName: 'name'}, subtitle: {fieldName: 'originDisplay'}, productCode: {fieldName: 'productCode'}, origin: {fieldName: 'originDisplay'}, manual: {fieldName: 'isManual'}, recognized: {fieldName: 'recognizedInReference'}, notice: {fieldName: 'notice'}}, sortable: false, hideDefaultActions: true, wrapText: true},
        {label: this.label.quantity, fieldName: 'quantity', type: 'editNum', typeAttributes: { field: "quantity", rowid: {fieldName: 'productId'}, value: {fieldName: 'quantity'}, digits: 0}, sortable: false, hideDefaultActions: true},
        {label: this.label.unit, fieldName: 'quantityUnitOfMeasure', type: 'picklist', typeAttributes: { field: "quantityUnitOfMeasure", rowid: {fieldName: 'productId'}, value: {fieldName: 'productId'}, picklist: {fieldName: 'variations'}}, sortable: false, hideDefaultActions: true},
        {label: this.label.price, fieldName: 'price', type: 'editNum', typeAttributes: { field: "price", rowid: {fieldName: 'productId'}, value: {fieldName: 'price'}, digits: 2}, sortable: false, hideDefaultActions: true},
        {label: this.label.valueLabel, fieldName: 'totalPriceDisplay', sortable: false, hideDefaultActions: true}
    ];
    editColumnsTwo = [
        {label: this.label.reason, fieldName: 'returnReason', type: 'picklist', typeAttributes: { field: "returnReason", rowid: {fieldName: 'productId'}, value: {fieldName: 'returnReason'}, picklist: this.returnReasonOptions}, sortable: false, hideDefaultActions: true},
        {label: null, fieldName: 'productId',  type: 'deleteRow', typeAttributes: { rowid: {fieldName: 'productId'}}, sortable: false, hideDefaultActions: true, fixedWidth: 24},
    ];
    editColumn = [        
        {label: this.label.lineItemType, fieldName: 'creditIssuanceVal', type: 'picklist', typeAttributes: { field: "creditIssuanceVal", rowid: {fieldName: 'productId'}, value: {fieldName: 'creditIssuanceVal'}, picklist: this.creditIssuancePicklistValues}, sortable: false, hideDefaultActions: true},
    ]
    editColumnAlt = [        
        {label: this.label.mode, fieldName: 'creditIssuanceVal', type: 'badge', typeAttributes: { value: this.label.creditPosition}, sortable: false, hideDefaultActions: true},
    ]

    editColumns = this.editColumnsOne.concat(this.editColumn).concat(this.editColumnsTwo);
    editColumnsAlt = this.editColumnsOne.concat(this.editColumnAlt).concat(this.editColumnsTwo);

    orderProductColumns = [
        {label: this.label.product, fieldName: 'Product2Name',  sortable: false, hideDefaultActions: true},
        {label: this.label.productCode, fieldName: 'Product2ProductCode', sortable: false, hideDefaultActions: true},
        {label: this.label.quantity, fieldName: 'Quantity', sortable: false, hideDefaultActions: true},
        {label: this.label.unit, fieldName: 'Product2QuantityUnitOfMeasure', sortable: false, hideDefaultActions: true},
        {label: this.label.price, fieldName: 'TotalPrice', sortable: false, hideDefaultActions: true}
    ]

    /* LIFECYCLE */

    connectedCallback(){
        loadStyle(this, custommodalcss);
        retrievePrefill({recordId: this.recordId})
        .then(result => {
            this.preloadData = result;
            this.customerPricebook = this.preloadData.pricebookMap;
            this.customerPricebookSaved = JSON.parse(JSON.stringify(this.customerPricebook));
            this.shipToNotEqualsBillTo = this.preloadData.differentAddresses;
            this.customerListingProductIds = this.preloadData.customerListingProductIds ?? [];
            this.customerListingProductIdsSaved = [...this.customerListingProductIds];
            this.customerListingLoaded = true;
            this.coreAssortmentProducts = this.preloadData.coreAssortmentProducts ?? [];
            this.coreAssortmentProductsSaved = JSON.parse(JSON.stringify(this.coreAssortmentProducts));
            this.listedProducts = this.preloadData.listedProducts ?? [];
            this.listedProductsSaved = JSON.parse(JSON.stringify(this.listedProducts));
            if(this.preloadData.returnOrder != null){        
                this.params.caseType = this.preloadData.returnOrder.ReturnOrderType__c;
                this.params.refund = this.preloadData.returnOrder.CreditIssuance__c == 'WITH' ? true : false;
                this.params.reference = this.preloadData.returnOrder.ReferenceType__c;
                this.params.reasonNoReference = this.preloadData.returnOrder.NoDocumentReason__c;
                this.params.shippingMethod = this.preloadData.returnOrder.ShippingCondition__c;
                this.params.arrivalDate = this.preloadData.returnOrder.RequestedPickupDate__c != null ? Date.parse(this.preloadData.returnOrder.RequestedPickupDate__c) : null;
            }
            if(this.preloadData.returnOrderItems != null && this.preloadData.returnOrderItems.length > 0){
                this.prefillReturnOrderItems = JSON.parse(JSON.stringify(this.preloadData.returnOrderItems));
                this.prefillOrderPositions = [];
                this.prefillInvoicePositions = [];
                this.positions = JSON.parse(JSON.stringify(this.preloadData.returnOrderItems));
                this.prefillReturnOrderItems.forEach(item => {
                    if(stringIsNotBlank(item.Description) && !stringIsNotBlank(this.params.internalNote)){
                        this.params.internalNote = item.Description;
                    }
                })
            } else {
                this.prefillReturnOrderItems = [];
                this.prefillOrderPositions = this.preloadData.orderPositions != null ? JSON.parse(JSON.stringify(this.preloadData.orderPositions)) : [];
                this.prefillInvoicePositions = this.preloadData.invoicePositions != null ? JSON.parse(JSON.stringify(this.preloadData.invoicePositions)) : [];
                this.positions = [];
            }
            
            if(this.preloadData.prefillAccount != null){
                this.selectedAccountId = this.preloadData.prefillAccount.Id;
                this.selectedAccountName = this.preloadData.prefillAccount.Name;
                this.accountPrefill = {
                    id: this.preloadData.prefillAccount.Id,
                    title: this.preloadData.prefillAccount.Name,
                    icon: 'standard:Account'
                };
                this.accountPrefillSaved = JSON.parse(JSON.stringify(this.accountPrefill));
            }
            if(this.preloadData.prefillAddress != null){
                this.selectedAddressId = this.preloadData.prefillAddress.Id;
                this.addressPrefill = {
                    id: this.preloadData.prefillAddress.Id,
                    title: this.preloadData.prefillAddress.Name,
                    icon: 'standard:Location'
                };
                this.addressPrefillSaved = JSON.parse(JSON.stringify(this.addressPrefill));
            }
            if(this.preloadData.prefillOrder != null){
                this.params.reference = 'ORDER';
                this.selectedOrderId = this.preloadData.prefillOrder.Id;
                this.orderCreatedDate = this.preloadData.prefillOrder.CreatedDate;
                this.orderTotal = this.preloadData.prefillOrder.TotalAmount;
                this.orderStatus = this.preloadData.prefillOrder.Status;
                this.orderSubtext = this.preloadData.orderSubtext;
                this.orderPrefill = {
                    id: this.preloadData.prefillOrder.Id,
                    title: this.preloadData.prefillOrder.OrderNumber,
                    icon: 'standard:Order'
                };
                this.orderPrefillSaved = JSON.parse(JSON.stringify(this.orderPrefill));
            }
            if(this.preloadData.prefillInvoice != null){
                this.params.reference = 'INVOICE';
                this.selectedInvoiceId = this.preloadData.prefillInvoice.Id;
                this.invoiceCreatedDate = this.preloadData.prefillInvoice.CreatedDate;
                this.invoiceTotal = this.preloadData.prefillInvoice.TotalAmount;
                this.invoiceStatus = this.preloadData.prefillInvoice.Status;
                this.invoiceType = this.preloadData.prefillInvoice.InvoicType__c;
                this.invoiceSubtext = this.preloadData.invoiceSubtext;
                this.invoiceOrders = this.preloadData.invoiceOrders ? JSON.parse(JSON.stringify(this.preloadData.invoiceOrders)) : [];
                this.invoiceOrders.forEach(invoiceOrder => {
                    invoiceOrder.numberOfItems = invoiceOrder.OrderItems ? invoiceOrder.OrderItems.length : 0;
                    invoiceOrder.numberLabel = invoiceOrder.numberOfItems == 1 ? this.label.lineItem : this.label.lineItems;
                    invoiceOrder.OrderItems.forEach(orderItem => {
                        orderItem.Product2Name = orderItem.Product2?.Name;
                        orderItem.Product2QuantityUnitOfMeasure = orderItem.Product2?.QuantityUnitOfMeasure;
                        orderItem.Product2ProductCode = orderItem.Product2?.ProductCode;
                    })
                })
                this.invoiceOrdersSaved = JSON.parse(JSON.stringify(this.invoiceOrders));
                this.invoicePrefill = {
                    id: this.preloadData.prefillInvoice.Id,
                    title: this.preloadData.prefillInvoice.DocumentNumber,
                    icon: 'standard:Invoice'
                };
                this.invoicePrefillSaved = JSON.parse(JSON.stringify(this.invoicePrefill));
            }
            this.selectedAccountId = this.preloadData.prefillAccount != null ? this.preloadData.prefillAccount.Id : null;
            this.selectedAccountName = this.preloadData.prefillAccount != null ? this.preloadData.prefillAccount.Name : null;
            this.selectedAddressId = this.preloadData.prefillAddress != null ? this.preloadData.prefillAddress.Id : null;
            this.selectedOrderId = this.preloadData.prefillOrder != null ? this.preloadData.prefillOrder.Id : null;
            this.selectedInvoiceId = this.preloadData.prefillInvoice != null ? this.preloadData.prefillInvoice.Id : null;
            this.lastOrderId = this.selectedOrderId;
            this.lastInvoiceId = this.selectedInvoiceId;
            this.lastOrderSelection = this.orderPrefill ? {...this.orderPrefill} : null;
            this.lastInvoiceSelection = this.invoicePrefill ? {...this.invoicePrefill} : null;
            this.lastOrderPositions = this.prefillOrderPositions.map(position => ({...position}));
            this.lastInvoicePositions = this.prefillInvoicePositions.map(position => ({...position}));
            if(!this.hasReturnOrder){
                this.applyReferencePositions();
            } else {
                this.populatePositionProductIds();
            }
            this.lastHandledAccountId = this.selectedAccountId ?? null;
            this.committedAccountId = this.selectedAccountId ?? null;
            this.committedAccountName = this.selectedAccountName;
            this.loaded = true;
        });
    }

    disconnectedCallback(){
        loadScript(this, removeStyle);
    }

    @wire(getObjectInfo, { objectApiName: RETURN_ORDER_OBJECT })
    objectInfo;
    @wire(getObjectInfo, { objectApiName: PRODUCT2_OBJECT })
    productInfo;

    @wire(getPicklistValuesByRecordType, {
        objectApiName: PRODUCT2_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    wiredProductPicklistValues({ data, error }) {
        if (data) {
            let quantityObj = this.transformPicklist(data, QUANTITY_UNIT_OF_MEASURE_FIELD.fieldApiName);
            this.unitPicklistValues = quantityObj.options;
            this.error = undefined;
        } else if (error) {
            this.unitPicklistValues = [];
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: RETURN_ORDER_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    wiredPicklistValues({ data, error }) {
        if (data) {
            let returnOrderType = this.transformPicklist(data, RETURN_ORDER_TYPE_FIELD.fieldApiName);
            let shippingCondition = this.transformPicklist(data, SHIPPING_CONDITION_FIELD.fieldApiName);
            let returnReason = this.transformPicklist(data, RETURN_REASON_FIELD.fieldApiName);
            this.returnOrderTypeOptions = returnOrderType.options;
            this.returnOrderTypeMap = returnOrderType.labelsByValue;
            this.returnShippingConditionOptions = shippingCondition.options;
            this.returnShippingConditionMap = shippingCondition.labelsByValue;
            this.returnReasonOptions = returnReason.options;
            this.returnReasonMap = returnReason.labelsByValue;
            this.updatePicklistColumn('returnReason', this.returnReasonOptions);
            this.error = undefined;
        } else if (error) {
            this.returnOrderTypeOptions = [];
            this.returnOrderTypeMap = {};
            this.returnReasonOptions = [];
            this.returnReasonMap = {};
            this.returnShippingConditionOptions = [];
            this.returnShippingConditionMap = {};
        }
    }

    transformPicklist(data, fieldApiName) {
        let values = data.picklistFieldValues[fieldApiName]?.values ?? [];
        let options = values.map(({ value, label }) => ({
            value,
            label: `${value} - ${label}`
        }));
        let labelsByValue = Object.fromEntries(options.map(option => [option.value, option.label]));
        return { options, labelsByValue};
    }

    /* GETTERS */

    get _editColumns(){
        return this.params.goodsReturn === true ? this.editColumns : this.editColumnsAlt;
    }

    get showExtendedProductLookup(){
        return this.useExtendedProductLookup;
    }

    get hasProductWarnings(){
        return this.productWarnings.length > 0;
    }

    get productWarningCount(){
        return this.productWarnings.length;
    }

    get hasPriceError(){
        return stringIsNotBlank(this.priceError);
    }

    get hasReturnOrder(){
        return this.preloadData?.returnOrder != null;
    }

    get hasPrefillReturnOrderItems(){
        return this.prefillReturnOrderItems != null && this.prefillReturnOrderItems.length > 0;
    }

    get stepThreeSeenAndHasPositions(){
        return this.stepThreeSeen && !this.hasNoPositions;
    }

    get warningTextsAll(){
        let warnings = this.warningTexts;
        if(!stringIsNotBlank(this.params.reference) || (this.params.reference == 'INVOICE' && this.selectedInvoiceId == null) || (this.params.reference == 'ORDER' && this.selectedOrderId == null) || (this.isNoneReference && !stringIsNotBlank(this.params.reasonNoReference))){
            warnings.push(this.label.warningSelectReference);
        }
        if(this.hasNoPositions){
            warnings.push(this.label.warningOnePosition);
        }
        return warnings;
    }

    get warningTextsAllLength(){
        return this.warningTextsAll.length;
    }

    get headerWarningDisplay(){
        return this.warningTextsAllLength > 0 ? 
        (this.warningTextsAllLength.toString() + ' ' + this.label.openLabel + '<br />' + this.warningTextsAll[0]) : 
        this.label.noneLabel;
    }

    get warningTexts(){
        let warnings = [];
        if(this.goodsReturnNotSelected){
            warnings.push(this.label.answerGoodsOrCredit);
        }
        if(this.params.goodsReturn === true){
            if(this.goodsMovementNotSelected){
                warnings.push(this.label.selectGoodsMovement);
            }
            if(this.refundNotSelected){
                warnings.push(this.label.answerRefundQuestion);
            }
            if(this.isGoodsMovementReceived){
                if(!stringIsNotBlank(this.params.arrivalDate)){
                    warnings.push(this.label.registerArrivalDate);
                }
                if(!stringIsNotBlank(this.params.caseReason)){
                    warnings.push(this.label.selectCaseReason);
                }
            } else if(this.isGoodsMovementShipping){
                if(!stringIsNotBlank(this.params.caseReason)){
                    warnings.push(this.label.selectCaseReason);
                }
            } else if(this.isGoodsMovementPickup){
                if(!stringIsNotBlank(this.params.shippingMethod)){
                    warnings.push(this.label.selectShippingMethod);
                }
                if(!stringIsNotBlank(this.params.caseReason)){
                    warnings.push(this.label.selectCaseReason);
                }
            }
        } else {
            if(!stringIsNotBlank(this.params.caseReason)){
                warnings.push(this.label.selectCaseReason);
            }
        }
        return warnings;
    }

    get goodsMovementDisplay(){
        return this.goodsMovementNotSelected ? 
            this.label.stillOpen :
            this.goodsMovementLabelMap[this.params.goodsMovement];
    }

    get referenceDisplay(){
        if(stringIsNotBlank(this.params.reference)){
            return this.referenceLabelMap[this.params.reference] ?? this.label.notChosenYet;
        }
        return this.label.notChosenYet;
    }

    get caseCategoryDisplay(){
        return this.goodsReturnNotSelected ? '' : 
            (this.params.goodsReturn === true ? this.label.returnLabel : this.label.valueCredit);
    }

    get caseTypeDisplay(){
        return stringIsNotBlank(this.params.caseType) ? 
            this.returnOrderTypeMap[this.params.caseType] : '';
    }

    get caseCategoryTypeDisplay(){
        if(stringIsNotBlank(this.caseCategoryDisplay) && stringIsNotBlank(this.caseTypeDisplay)){
            return this.caseCategoryDisplay + '<br />' + this.caseTypeDisplay;
        } else if(stringIsNotBlank(this.caseCategoryDisplay)){
            return this.caseCategoryDisplay;
        } else if(stringIsNotBlank(this.caseTypeDisplay)){
            return this.caseTypeDisplay;
        } else {
            return this.label.stillOpen;
        }
    }

    get positionsCountDisplay(){
        return this.positions.length.toString();
    }

    get actualRefundValue(){
        return (this.params.refund === true || this.params.goodsReturn === false) ? this.totalValue : 0;
    }

    get actualRefundPureDisplay(){
        return this.positions.length > 0 ? 
            (new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.actualRefundValue)) :
            this.label.stillOpen;
    }

    get actualRefundDisplay(){
        return this.positions.length > 0 ? 
            (new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.actualRefundValue) + '<br />' + this.label.creditValue) :
            this.label.stillOpen;
    }

    get goodsValuePureDisplay(){
        return this.positions.length > 0 ? 
            (new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.totalGoodsValue)) :
            this.label.stillOpen;
    }

    get valuesDisplay(){
        return this.positions.length > 0 ? 
            (new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.totalValue) + '<br />' + this.label.creditValue) :
            this.label.stillOpen;
    }

    get warningText(){
        return this.warningTexts.length > 0 ? this.warningTexts[0] : '';
    }

    get hasWarningText(){
        return stringIsNotBlank(this.warningText);
    }

    get valueAboveHundred(){
        return this.actualRefundValue >= 100;
    }

    get isStepOne(){
        return this.step == 1;
    }

    get isStepTwo(){
        return this.step == 2;
    }

    get isStepThree(){
        return this.step == 3;
    }

    get isStepTwoOrThree(){
        return this.step == 2 || this.step == 3;
    }

    get isStepTwoOrThreeAndValueAboveHundred(){
        return this.isStepTwoOrThree && this.valueAboveHundred;
    }

    get isStepFour(){
        return this.step == 4;
    }

    get stepOneDisabled(){
        return this.warningTexts.length > 0;
    }

    get stepTwoDisabled(){
        return this.warningTextsAll.length > 0;
    }

    get hasNoPositions(){
        return this.positions.length == 0;
    }

    get oneOrChecked(){
        return this.isStepOne ? '1' : '✓';
    }

    get twoOrChecked(){
        return !this.isStepThree && !this.isStepFour ? '2' : '✓';
    }

    get threeOrChecked(){
        return !this.isStepFour ? '3' : '✓';
    }

    get progressBarClassesOne(){
        return this.isStepOne ?  'progress-bar-item progress-bar-item-in-progress' : 'progress-bar-item progress-bar-item-finished';
    }

    get progressBarClassesTwo(){
        if(this.isStepOne){
            return 'progress-bar-item';
        } else if(this.isStepTwo){
            return 'progress-bar-item progress-bar-item-in-progress';
        } else {
            return 'progress-bar-item progress-bar-item-finished';
        }
    }

    get progressBarClassesThree(){
        return this.isStepThree ?  'progress-bar-item progress-bar-item-in-progress' : 'progress-bar-item';
    }

    get goodsReturnClassLeft(){
        return this.params.goodsReturn === true ? 'select-box select-box-selected' : 'select-box';
    }

    get goodsReturnClassRight(){
        return this.params.goodsReturn === false ? 'select-box select-box-selected' : 'select-box';
    }

    get refundClassLeft(){
        return this.params.refund === true ? 'select-box select-box-selected' : 'select-box';
    }

    get refundClassRight(){
        return this.params.refund === false ? 'select-box select-box-selected' : 'select-box';
    }

    get hasInvoiceOrders(){
        return this.invoiceOrders.length > 0;
    }

    get hasInvoiceStatusAndType(){
        return stringIsNotBlank(this.invoiceStatus) && stringIsNotBlank(this.invoiceType);
    }

    get hasInvoiceOrdersAndIsInvoiceTab(){
        return this.hasInvoiceOrders && this.isInvoiceReference;
    }

    get isOrderReference(){
        return this.params.reference === 'ORDER';
    }

    get hasOrderId(){
        return stringIsNotBlank(this.selectedOrderId);
    }

    get hasInvoiceId(){
        return stringIsNotBlank(this.selectedInvoiceId);
    }

    get isInvoiceReference(){
        return this.params.reference === 'INVOICE'
    }

    get isNoneReference(){
        return this.params.reference === 'NONE';
    }

    get isNoReference(){
        return !stringIsNotBlank(this.params.reference);
    }

    get referenceClassLeft(){
        return this.isOrderReference ? 'select-box select-box-selected' : 'select-box';
    }

    get referenceClassCenter(){
        return this.isInvoiceReference ? 'select-box select-box-selected' : 'select-box';
    }

    get referenceClassRight(){
        return this.isNoneReference ? 'select-box select-box-selected' : 'select-box';
    }

    get refundNotSelected(){
        return this.params.refund == null;
    }

    get goodsReturnNotSelected(){
        return this.params.goodsReturn == null;
    }

    get goodsMovementNotSelected(){
        return this.params.goodsMovement == null;
    }

    get goodsReturnOrMovementNotSelected(){
        return this.goodsReturnNotSelected || (this.params.goodsReturn === true && this.goodsMovementNotSelected);
    }

    get isGoodsMovementPickup(){
        return this.params.goodsMovement == 'pickup';
    }

    get isGoodsMovementShipping(){
        return this.params.goodsMovement == 'shipping';
    }

    get isGoodsMovementReceived(){
        return this.params.goodsMovement == 'received';
    }

    get isGoodsMovementShippingOrReceived(){
        return this.isGoodsMovementShipping || this.isGoodsMovementReceived;
    }

    get isNotPreselectedAccount(){
        return this.accountPrefillSaved != null ? this.accountPrefillSaved.id != this.selectedAccountId : false;
    }

    get notOriginalAccountAndNoOrder(){
        return this.isNotPreselectedAccount && !stringIsNotBlank(this.selectedOrderId);
    }

    get notOriginalAccountAndNoInvoice(){
        return this.isNotPreselectedAccount && !stringIsNotBlank(this.selectedInvoiceId);
    }

    get isNoneReferenceAndNoReason(){
        return this.isNoneReference && !stringIsNotBlank(this.params.reasonNoReference);
    }

    get isStandardDeliveryAddress(){
        return this.addressPrefill != null && this.selectedAddressId == this.addressPrefill.id;
    }

    get progressBarOneClass(){
        return this.step != 1 && this.step != 4 ? 'clickable' : '';
    }

    get progressBarTwoClass(){
        return this.stepTwoSeen && this.step != 2 && this.step != 4 && this.warningTexts.length == 0 ? 'clickable' : '';
    }

    get progressBarThreeClass(){
        return this.stepThreeSeenAndHasPositions && this.step != 3 && this.step != 4 ? 'clickable' : '';
    }


    /* HANDLERS */ 
    handleClickProgressBarOne(){
        if(this.step != 1 && this.step != 4){
            this.handleGoToStepOne();
        }
    }

    handleClickProgressBarTwo(){
        if(this.stepTwoSeen && this.step != 2 && this.step != 4 && this.warningTexts.length == 0){
            this.step = 2;
        }
    }

    handleClickProgressBarThree(){
        if(this.stepThreeSeenAndHasPositions && this.step != 3 && this.step != 4 && this.warningTextsAll.length == 0){
            this.step = 3;
        }
    }

    handleGoToStepOne(){
        this.accountPrefill = {
            id: this.selectedAccountId,
            title: this.selectedAccountName,
            icon: 'standard:Location'
        };
        this.step = 1;
    }

    handleGoToStepTwo(){
        this.step = 2;
        this.stepTwoSeen = true;
    }

    handleGoToStepThree(){
        if(this.params.goodsReturn === false){
            // BUGFIX AGAINST PRELOAD
            this.positions.forEach(position => {
                position.creditIssuance = true;
                position.creditIssuanceVal = 'WITH';
                position.creditIssuanceDisplay = this.label.refundYes;
            });
        }
        this.step = 3;
        this.stepThreeSeen = true;
    }

    handleSubmitToSAP(){
        this.isLoading = true;
        createReturnOrder({
            recordId: this.recordId,
            existingReturnOrderId: this.existingReturnOrderId,
            accountId: this.selectedAccountId,
            orderId: this.selectedOrderId,
            invoiceId: this.selectedInvoiceId,
            addressId: this.selectedAddressId,
            positions: JSON.stringify(this.positions),
            params: this.params 
        }).then(result => {
            this.step = 4;
            this.page4success = result.success;
            this.page4error = result.error;
            this.returnOrderCreatedId = result.recordId;
            this.isLoading = false;
        })
    }

    toggleAccountDetails(){
        this.showAccountDetails = !this.showAccountDetails;
    }
    
    handleSetRefund(){
        this.params.refund = true;
    }
    
    handleSetNoRefund(){
        this.params.refund = false;
    }
    
    handleSetGoodsReturn(){
        this.params.goodsReturn = true;
    }
    
    handleSetNoGoodsReturn(){
        this.params.goodsReturn = false;
    }

    handleChangeInternalNote(event){
        this.params.internalNote = event.target.value;
    }

    handleChangeGoodsMovement(event){
        this.params.goodsMovement = event.target.value;
    }

    handleChangeCaseReason(event){
        this.params.caseReason = event.target.value;
    }

    handleChangeCaseType(event){
        this.params.caseType = event.target.value;
    }

    handleChangeArrivalDate(event){
        this.params.arrivalDate = event.target.value;
    }

    handleChangeShippingMethod(event){
        this.params.shippingMethod = event.target.value;
    }

    handleChangeWhereAreGoods(event){
        this.params.whereAreGoods = event.target.value;
    }

    handleSetReferenceOrder(){
        this.setReferenceTab('ORDER');
    }

    handleSetReferenceInvoice(){
        this.setReferenceTab('INVOICE');
    }

    handleSetReferenceNoDocument(){
        this.setReferenceTab('NONE');
    }

    setReferenceTab(reference){
        if(this.params.reference != reference){
            this.params.reference = reference;
            if(reference === 'ORDER' && !this.selectedOrderId && this.lastOrderSelection){
                this.selectedOrderId = this.lastOrderId;
                this.orderPrefill = {...this.lastOrderSelection};
            } else if(reference === 'INVOICE' && !this.selectedInvoiceId && this.lastInvoiceSelection){
                this.selectedInvoiceId = this.lastInvoiceId;
                this.invoicePrefill = {...this.lastInvoiceSelection};
            }
            if(!this.hasReturnOrder){
                this.applyReferencePositions();
            } else {
                this.repriceManualPositions(reference);
            }
        }
    }

    handleChangeReasonNoReference(event){
        this.params.reasonNoReference = event.target.value;
    }

    handleAccountLookupSearch(event){
        let searchParam = {
            parentObjectApiName: "Contact",
            lookupApiName: "AccountId",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: null,
            additionalFields: ['ERPCustomerNumber__c', 'Industry', 'ShippingPostalCode', 'ShippingCity'],
            listIds: [],
            listIdsExclude: [this.selectedAccountId],
            displayField: 'Name'
        };
        searchWithIds(searchParam)
        .then(results => {
            this.template.querySelector('[data-field="Account"]').setSearchResults(results);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleAddressLookupSearch(event){
        let searchParam = {
            parentObjectApiName: "ReturnOrder",
            lookupApiName: "Address__c",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'CustomAddress__c', filter : 'IsValid__c = TRUE AND AddressType__c = \'Shipping\' AND Account__c = \'' + this.selectedAccountId + '\''}],
            additionalFields: ['Address__Street__s', 'Address__PostalCode__s'],
            listIds: [],
            listIdsExclude: [],
            displayField: 'Name'
        };
        searchWithIds(searchParam)
        .then(results => {
            this.template.querySelector('[data-field="Address"]').setSearchResults(results);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleInvoiceLookupSearch(event){
        let searchParam = {
            parentObjectApiName: "ReturnOrder",
            lookupApiName: "LegacyInvoice__c",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'Invoice', filter : 'BillingAccountId = \'' + this.selectedAccountId + '\''}],
            additionalFields: ['CreatedDate', 'TotalAmount', 'Status', 'InvoiceType__c'],
            listIds: [],
            listIdsExclude: [],
            displayField: 'DocumentNumber'
        };
        searchWithIds(searchParam)
        .then(results => {
            this.template.querySelector('[data-field="Invoice"]').setSearchResults(results);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleOrderLookupSearch(event){
        let searchParam = {
            parentObjectApiName: "ReturnOrder",
            lookupApiName: "OrderId",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'Order', filter : 'AccountId = \'' + this.selectedAccountId + '\''}],
            additionalFields: ['CreatedDate', 'TotalAmount', 'Status'],
            listIds: [],
            listIdsExclude: [],
            displayField: 'OrderNumber'
        };
        searchWithIds(searchParam)
        .then(results => {
            this.template.querySelector('[data-field="Order"]').setSearchResults(results);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleProductLookupSearch(event){
        let lookup = event.target;
        let requestId = event.detail.requestId;
        let searchParam = {
            parentObjectApiName: "PricebookEntry",
            lookupApiName: "Product2Id",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'Product2', filter : 'IsActive = TRUE AND ProductClass IN (\'Variation\', \'Simple\') AND ProductGroup__c != NULL AND (NOT Name LIKE \'Produktgruppe%\') AND (NOT Name LIKE \'Produkt-Untergruppe%\')'}],
            additionalFields: ['ProductCode', 'QuantityUnitOfMeasure', 'CurrencyIsoCode', 'BaseProductCode__c', 'Factor__c', 'ProductGroupName__c'],
            listIds: [],
            listIdsExclude: this.positionProductIds,
            displayField: 'Name',
            reference: (this.params.reference == 'INVOICE' && stringIsNotBlank(this.selectedInvoiceId)) ? this.selectedInvoiceId : (this.params.reference == 'ORDER' && stringIsNotBlank(this.selectedOrderId) ? this.selectedOrderId : null)
        };
        searchWithIdsAndReference(searchParam)
        .then(results => {
            lookup.setSearchResults(results, requestId);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleAccountLookupChange(event){
        if (event.target.selection && event.target.selection.length > 0) {
            let selectedAccount = null;
            event.target.selection.forEach(selection => {
                selectedAccount = selection;
            })
            if(selectedAccount != null){
                if(selectedAccount.id === this.committedAccountId){
                    this.selectedAccountId = selectedAccount.id;
                    this.selectedAccountName = selectedAccount.title;
                    this.accountPrefill = {
                        id: this.selectedAccountId,
                        title: this.selectedAccountName,
                        icon: 'standard:Account'
                    };
                    return;
                }
                let filteredPositions = this.positions.filter(position => position.status !== 'pristine');
                if(filteredPositions.length > 0){
                    this.showAccountChangeModal = true;
                    this.temporaryAccount = selectedAccount;
                    this.temporaryAccountName = selectedAccount.title;
                } else {
                    this.selectedAccountId = selectedAccount.id;
                    this.selectedAccountName = selectedAccount.title;
                    this.accountPrefill = {
                        id: this.selectedAccountId,
                        title: this.selectedAccountName,
                        icon: 'standard:Account'
                    };
                }
            }
        } else {
            this.selectedAccountId = null;
        }
    }

    handleConfirmAccountChangeModal(){
        this.selectedAccountId = this.temporaryAccount.id;
        this.selectedAccountName = this.temporaryAccount.title;
        this.showAccountChangeModal = false;
        this.accountPrefill = JSON.parse(JSON.stringify(this.temporaryAccount));
        this.temporaryAccount = null;
        this.temporaryAccountName = null;
        this.handlePrefillsAndAddresses();
    }

    handleCloseAccountChangeModal(){
        this.showAccountChangeModal = false;
        this.selectedAccountId = this.committedAccountId;
        this.selectedAccountName = this.committedAccountName;
        let committed = {
            id: this.committedAccountId,
            title: this.committedAccountName,
            icon: 'standard:Account'
        };
        this.accountPrefill = this.committedAccountId != null ? committed : null;
        this.temporaryAccount = null;
        this.temporaryAccountName = null;
        return this.handlePrefillsAndAddresses();
    }

    handleAccountLookupFocusOut(){
        if(this.showAccountChangeModal == false){
            if(this.selectedAccountId == null && this.committedAccountId != null){
                this.selectedAccountId = this.committedAccountId;
                this.selectedAccountName = this.committedAccountName;
                this.accountPrefill = {
                    id: this.committedAccountId,
                    title: this.committedAccountName,
                    icon: 'standard:Account'
                };
            }
            return this.handlePrefillsAndAddresses();
        }
    }

    handlePrefillsAndAddresses(){        
        let accountId = this.selectedAccountId ?? null;
        if(accountId === this.lastHandledAccountId){
            if(this.addressNeedsRefresh && !this.addressRequestPending && accountId != null){
                return this.refreshAccountAddress(accountId);
            }
            return;
        }
        // Invalidate requests for the previous account, including a later return to the same ID.
        this.addressRequestVersion++;
        this.addressRequestPending = false;
        this.addressNeedsRefresh = false;
        this.lastHandledAccountId = accountId;
        this.committedAccountId = accountId;
        this.committedAccountName = this.selectedAccountName;
        this.orderRequestVersion++;
        this.invoiceRequestVersion++;
        if(this.accountPrefillSaved != null && accountId === this.accountPrefillSaved.id){
            this.invoicePrefill = this.invoicePrefillSaved ? {...this.invoicePrefillSaved} : null;
            this.orderPrefill = this.orderPrefillSaved ? {...this.orderPrefillSaved} : null;
            this.addressPrefill = this.addressPrefillSaved ? {...this.addressPrefillSaved} : null;
            this.customerPricebook = {...(this.customerPricebookSaved ?? {})};
            this.customerListingProductIds = [...this.customerListingProductIdsSaved];
            this.customerListingLoaded = true;
            this.coreAssortmentProducts = JSON.parse(JSON.stringify(this.coreAssortmentProductsSaved));
            this.listedProducts = JSON.parse(JSON.stringify(this.listedProductsSaved));
            this.selectedInvoiceId = this.invoicePrefill?.id ?? null;
            this.selectedOrderId = this.orderPrefill?.id ?? null;
            this.selectedAddressId = this.addressPrefill?.id ?? null;
            this.lastInvoiceId = this.selectedInvoiceId;
            this.lastOrderId = this.selectedOrderId;
            this.lastInvoiceSelection = this.invoicePrefill ? {...this.invoicePrefill} : null;
            this.lastOrderSelection = this.orderPrefill ? {...this.orderPrefill} : null;
            this.lastInvoicePositions = this.prefillInvoicePositions.map(position => ({...position}));
            this.lastOrderPositions = this.prefillOrderPositions.map(position => ({...position}));
            if(!this.hasReturnOrder) {
                this.applyReferencePositions();
            } else {
                this.populatePositionProductIds();
            }
        } else {
            this.invoicePrefill = null;
            this.orderPrefill = null;
            this.selectedInvoiceId = null;
            this.selectedOrderId = null;
            this.lastInvoiceId = null;
            this.lastOrderId = null;
            this.lastInvoiceSelection = null;
            this.lastOrderSelection = null;
            this.lastInvoicePositions = [];
            this.lastOrderPositions = [];
            this.addressPrefill = null;
            this.selectedAddressId = null;
            this.customerListingProductIds = [];
            this.customerListingLoaded = false;
            this.coreAssortmentProducts = [];
            this.listedProducts = [];
            if(!this.hasReturnOrder) {
                this.applyReferencePositions();
            } else {
                this.populatePositionProductIds();
            }
            if(accountId != null) {
                return this.refreshAccountAddress(accountId);
            }
        }
    }

    refreshAccountAddress(accountId){
        let requestVersion = ++this.addressRequestVersion;
        this.addressRequestPending = true;
        this.addressNeedsRefresh = true;
        return reselectAddressesAndPricebook({recordId: accountId})
        .then(result => {
            if(requestVersion !== this.addressRequestVersion || accountId !== this.selectedAccountId){
                return;
            }
            if(result != null){
                if(result.address == null){
                    this.addressPrefill = null;
                    this.selectedAddressId = null;
                } else {
                    this.addressPrefill = {
                        id: result.address.Id,
                        title: result.address.Name,
                        icon: 'standard:location'
                    };
                    this.selectedAddressId = result.address.Id;
                }
                this.customerPricebook = result.pricebookMap;
                this.customerListingProductIds = result.customerListingProductIds ?? [];
                this.customerListingLoaded = true;
                this.coreAssortmentProducts = result.coreAssortmentProducts ?? [];
                this.listedProducts = result.listedProducts ?? [];
                this.populatePositionProductIds();
            }
            this.addressNeedsRefresh = false;
        })
        .catch(error => {
            if(requestVersion === this.addressRequestVersion){
                console.error(error);
            }
        })
        .finally(() => {
            if(requestVersion === this.addressRequestVersion){
                this.addressRequestPending = false;
            }
        });
    }

    handleAddressLookupChange(event){
        let selection = event.target.selection?.at(-1);
        this.selectedAddressId = selection?.id ?? null;
    }

    handleAddressLookupFocusOut(event){
        if(event?.target?.selection?.length || this.selectedAddressId != null || !this.addressPrefill) {
            return;
        }
        this.selectedAddressId = this.addressPrefill.id;
        this.restoreLookupSelection(event.target, this.addressPrefill);
    }

    handleInvoiceLookupChange(event){
        let selection = event.target.selection?.at(-1);
        let requestVersion = ++this.invoiceRequestVersion;
        if(selection?.id && selection.id !== this.lastInvoiceId){
            this.lastInvoicePositions = [];
        }
        this.selectedInvoiceId = selection?.id ?? null;
        if(!selection){
            this.invoicePrefill = null;
            return;
        }
        this.invoicePrefill = {...selection};
        this.lastInvoiceSelection = {...selection};
        this.lastInvoiceId = selection.id;
        this.invoiceCreatedDate = selection.additionalFieldMap?.CreatedDate ?? null;
        this.invoiceTotal = selection.additionalFieldMap?.TotalAmount ?? null;
        this.invoiceStatus = selection.additionalFieldMap?.Status ?? null;
        this.invoiceType = selection.additionalFieldMap?.InvoiceType__c ?? null;
        if(this.params.reference === 'INVOICE' && !this.hasReturnOrder) {
            this.applyReferencePositions();
        }
        this.loadInvoicePositions(selection.id, requestVersion);
    }

    handleInvoiceLookupFocusOut(event){
        let saved = this.accountPrefillSaved?.id === this.selectedAccountId ? this.invoicePrefillSaved : null;
        if(event?.target?.selection?.length || this.selectedInvoiceId != null || !saved){
            return;
        } 
        this.selectedInvoiceId = saved.id;
        this.invoicePrefill = {...saved};
        this.lastInvoiceId = saved.id;
        this.lastInvoiceSelection = {...saved};
        this.lastInvoicePositions = this.prefillInvoicePositions.map(position => ({...position}));
        this.invoiceCreatedDate = this.preloadData?.prefillInvoice?.CreatedDate ?? null;
        this.invoiceTotal = this.preloadData?.prefillInvoice?.TotalAmount ?? null;
        this.invoiceStatus = this.preloadData?.prefillInvoice?.Status ?? null;
        this.invoiceType = this.preloadData?.prefillInvoice?.InvoiceType__c ?? null;
        this.invoiceSubtext = this.preloadData?.invoiceSubtext ?? null;
        this.invoiceOrders = this.invoiceOrdersSaved.map(order => ({...order}));
        this.restoreLookupSelection(event.target, saved);
        if(this.params.reference === 'INVOICE' && !this.hasReturnOrder) {
            this.applyReferencePositions();
        }
        else if(this.params.reference === 'INVOICE'){
            this.repriceManualPositions('INVOICE');
        } 
    }

    handleOrderLookupChange(event){
        let selection = event.target.selection?.at(-1);
        let requestVersion = ++this.orderRequestVersion;
        if(selection?.id && selection.id !== this.lastOrderId){
            this.lastOrderPositions = [];
        }
        this.selectedOrderId = selection?.id ?? null;
        if(!selection){
            this.orderPrefill = null;
            return;
        }
        this.orderPrefill = {...selection};
        this.lastOrderSelection = {...selection};
        this.lastOrderId = selection.id;
        this.orderCreatedDate = selection.additionalFieldMap?.CreatedDate ?? null;
        this.orderTotal = selection.additionalFieldMap?.TotalAmount ?? null;
        this.orderStatus = selection.additionalFieldMap?.Status ?? null;
        if(this.params.reference === 'ORDER' && !this.hasReturnOrder) {
            this.applyReferencePositions();
        }
        this.loadOrderPositions(selection.id, requestVersion);
    }

    handleOrderLookupFocusOut(event){
        let saved = this.accountPrefillSaved?.id === this.selectedAccountId ? this.orderPrefillSaved : null;
        if(event?.target?.selection?.length || this.selectedOrderId != null || !saved) {
            return;
        }
        this.selectedOrderId = saved.id;
        this.orderPrefill = {...saved};
        this.lastOrderId = saved.id;
        this.lastOrderSelection = {...saved};
        this.lastOrderPositions = this.prefillOrderPositions.map(position => ({...position}));
        this.orderCreatedDate = this.preloadData?.prefillOrder?.CreatedDate ?? null;
        this.orderTotal = this.preloadData?.prefillOrder?.TotalAmount ?? null;
        this.orderStatus = this.preloadData?.prefillOrder?.Status ?? null;
        this.orderSubtext = this.preloadData?.orderSubtext ?? null;
        this.restoreLookupSelection(event.target, saved);
        if(this.params.reference === 'ORDER' && !this.hasReturnOrder) this.applyReferencePositions();
        else if(this.params.reference === 'ORDER') {
            this.repriceManualPositions('ORDER');
        }
    }

    restoreLookupSelection(lookup, selection){
        if(lookup && selection) lookup.selection = {...selection};
    }

    loadInvoicePositions(invoiceId, requestVersion){
        if(this.invoicePrefillSaved?.id === invoiceId && this.accountPrefillSaved?.id === this.selectedAccountId){
            this.lastInvoicePositions = this.prefillInvoicePositions.map(position => ({...position}));
            this.invoiceSubtext = this.preloadData?.invoiceSubtext ?? null;
            this.invoiceOrders = this.invoiceOrdersSaved.map(order => ({...order}));
            if(this.params.reference === 'INVOICE'){
                if(!this.hasReturnOrder) {
                    this.applyReferencePositions();
                } else {
                    this.repriceManualPositions('INVOICE');
                }
            }
            return;
        }
        let accountId = this.selectedAccountId;
        reselectPositionsFromInvoice({recordId: invoiceId})
            .then(result => {
                if(requestVersion !== this.invoiceRequestVersion || invoiceId !== this.selectedInvoiceId || accountId !== this.selectedAccountId) {
                    return;
                }
                this.lastInvoicePositions = (result?.positions ?? []).map(position => ({...position}));
                this.invoiceSubtext = result?.invoiceSubtext ?? null;
                this.invoiceOrders = (result?.invoiceOrders ?? []).map(invoiceOrder => ({
                    ...invoiceOrder,
                    numberOfItems: invoiceOrder.OrderItems?.length ?? 0,
                    numberLabel: invoiceOrder.OrderItems?.length === 1 ? this.label.lineItem : this.label.lineItems,
                    OrderItems: (invoiceOrder.OrderItems ?? []).map(orderItem => ({
                        ...orderItem,
                        Product2Name: orderItem.Product2?.Name,
                        Product2QuantityUnitOfMeasure: orderItem.Product2?.QuantityUnitOfMeasure,
                        Product2ProductCode: orderItem.Product2?.ProductCode
                    }))
                }));
                if(this.params.reference === 'INVOICE'){
                    if(!this.hasReturnOrder) {
                        this.applyReferencePositions();
                    } else {
                        this.repriceManualPositions('INVOICE');
                    } 
                }
            })
            .catch(error => console.error(error));
    }

    loadOrderPositions(orderId, requestVersion){
        if(this.orderPrefillSaved?.id === orderId && this.accountPrefillSaved?.id === this.selectedAccountId){
            this.lastOrderPositions = this.prefillOrderPositions.map(position => ({...position}));
            this.orderSubtext = this.preloadData?.orderSubtext ?? null;
            if(this.params.reference === 'ORDER'){
                if(!this.hasReturnOrder){
                    this.applyReferencePositions();
                } else {
                    this.repriceManualPositions('ORDER');
                }
            }
            return;
        }
        let accountId = this.selectedAccountId;
        reselectPositionsFromOrder({recordId: orderId})
            .then(result => {
                if(requestVersion !== this.orderRequestVersion ||
                   orderId !== this.selectedOrderId || accountId !== this.selectedAccountId) return;
                this.lastOrderPositions = (result?.positions ?? []).map(position => ({...position}));
                this.orderSubtext = result?.orderSubtext ?? null;
                if(this.params.reference === 'ORDER'){
                    if(!this.hasReturnOrder) {
                        this.applyReferencePositions();
                    } else {
                        this.repriceManualPositions('ORDER');
                    }
                }
            })
            .catch(error => console.error(error));
    }

    getReferencePositions(reference){
        if(reference === 'ORDER' && this.selectedOrderId != null && this.lastOrderId === this.selectedOrderId){
            return this.lastOrderPositions;
        }
        if(reference === 'INVOICE' && this.selectedInvoiceId != null && this.lastInvoiceId === this.selectedInvoiceId){
            return this.lastInvoicePositions;
        }
        return null; // No current selection: preserve the manual row's current price.
    }

    getReferenceNumber(reference){
        if(reference === 'ORDER' && this.selectedOrderId != null){
            return this.lastOrderSelection?.title ?? this.orderPrefill?.title ?? '';
        }
        if(reference === 'INVOICE' && this.selectedInvoiceId != null){
            return this.lastInvoiceSelection?.title ?? this.invoicePrefill?.title ?? '';
        }
        return '';
    }

    getPositionFactor(position){
        let factor = Number(position?.factor);
        return Number.isFinite(factor) && factor > 0 ? factor : 1;
    }

    getPositionBaseProductKey(position){
        return stringIsNotBlank(position?.baseProductCode) ? position.baseProductCode : position?.productId;
    }

    getReferencePositionsByProduct(reference){
        let source = this.getReferencePositions(reference);
        if(source == null){
            return null;
        }
        let positionsByProduct = new Map();
        source.forEach(position => {
            let productKey = this.getPositionBaseProductKey(position);
            let quantity = Number(position.quantity) || 0;
            let factoredQuantity = quantity * this.getPositionFactor(position);
            let existing = positionsByProduct.get(productKey);
            if(existing == null){
                positionsByProduct.set(productKey, {
                    ...position,
                    quantity,
                    factoredQuantity,
                    originalQuantity: quantity,
                    originalFactoredQuantity: factoredQuantity
                });
            } else {
                positionsByProduct.set(productKey, {
                    ...existing,
                    quantity: (Number(existing.quantity) || 0) + quantity,
                    factoredQuantity: (Number(existing.factoredQuantity) || 0) + factoredQuantity,
                    originalQuantity: (Number(existing.originalQuantity) || 0) + quantity,
                    originalFactoredQuantity: (Number(existing.originalFactoredQuantity) || 0) + factoredQuantity
                });
            }
        });
        return positionsByProduct;
    }

    adjustManualPrice(position, reference, referenceByProduct){
        let manualPrice = this.manualPricesByProductId[position.productId] ?? position.price;
        this.manualPricesByProductId[position.productId] = manualPrice;
        let referencePrice = referenceByProduct?.get(position.productId)?.price;
        return {
            ...position,
            price: reference === 'NONE' ? manualPrice : (referencePrice ?? position.price)
        };
    }

    repriceManualPositions(reference){
        let source = this.getReferencePositions(reference);
        let byProduct = source == null ? null : new Map(source.map(item => [item.productId, item]));
        this.positions = this.positions.map(
            position => position.status === 'manual' ? this.adjustManualPrice(position, reference, byProduct) : position
        );
        this.populatePositionProductIds();
    }

    applyReferencePositions(){
        if(this.hasReturnOrder) {
            return;
        }
        let reference = this.params.reference;
        let source = this.getReferencePositions(reference);
        let byProduct = source == null ? null : new Map(source.map(item => [item.productId, item]));
        let manual = this.positions.filter(position => position.status === 'manual').map(position => this.adjustManualPrice(position, reference, byProduct));
        let manualIds = new Set(manual.map(position => position.productId));
        let referenceNumber = this.getReferenceNumber(reference);
        let auto = (source ?? []).filter(position => !manualIds.has(position.productId)).map(position => ({
            ...position,
            status: 'pristine',
            originReferenceNumber: referenceNumber
        }));
        this.positions = [...manual, ...auto];
        this.populatePositionProductIds();
    }

    handleProductLookupChange(event){
        this.priceError = null;
        let lookup = event.target;
        let selectedProduct = null;
        if (event.target.selection && event.target.selection.length > 0) {
            event.target.selection.forEach(selection => {
                selectedProduct = selection;
            })
            if(selectedProduct != null && selectedProduct.id && selectedProduct.additionalFieldMap && !this.positionProductIds.includes(selectedProduct.id)){
                /* {"additionalFieldMap":{"ProductCode":"1017501-12-01","QuantityUnitOfMeasure":"ST","CurrencyIsoCode":"EUR"},"icon":"standard:product2","id":"01t9O00000VsDYIQA3",
                "sObjectType":"Product2","subtitle":"1017501-12-01","title":"Idee Kaffee entcof. 500g gemahlen SB","titleFormatted":"Idee <strong>Kaffee</strong> entcof. 500g gemahlen SB","subtitleFormatted":"1017501-12-01"}*/
                let fieldMap = selectedProduct.additionalFieldMap;
                let hasFieldMapPrice = Object.keys(fieldMap).includes('price') && fieldMap.price != null; // Price from Order or Invoice
                let hasUnitPrice = hasFieldMapPrice ? true : Object.keys(this.customerPricebook).includes(selectedProduct.id);
                let unitPrice = hasFieldMapPrice ? parseFloat(fieldMap.price) : (hasUnitPrice ? parseFloat(this.customerPricebook[selectedProduct.id]) : 0);
                let productObj = {
                    'productId': selectedProduct.id,
                    'name': selectedProduct.title,
                    'productCode': fieldMap.ProductCode,
                    'factor': fieldMap.Factor__c ?? 1,
                    'baseProductCode': fieldMap.BaseProductCode__c,
                    'description': fieldMap.ProductCode,
                    'quantityUnitOfMeasure': fieldMap.QuantityUnitOfMeasure,
                    'currencyIsoCode': fieldMap.CurrencyIsoCode,
                    'quantity': 1,
                    'price': unitPrice,
                    'totalPrice': unitPrice,
                    'priceDisplay': new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(unitPrice),
                    'totalPriceDisplay': new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(unitPrice),
                    'returnReason': 'R18',
                    'creditIssuance': this.params.refund === true || this.params.goodsReturn === false,
                    'creditIssuanceVal': (this.params.refund === true || this.params.goodsReturn === false) ? 'WITH' : 'WITHOUT',
                    'creditIssuanceDisplay': (this.params.refund === true || this.params.goodsReturn === false) ? this.label.refundYes : this.label.refundNo,
                    'status': 'manual',
                }
                if(!hasUnitPrice){
                    getSinglePriceByOrderSimulation({
                        productObj: JSON.stringify(productObj),
                        accountId: this.selectedAccountId
                    })
                    .then(result => {
                        if(result != null){
                            unitPrice = result;
                            productObj.price = result;
                            productObj.totalPrice = result;
                            productObj.priceDisplay = new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(result);
                            productObj.totalPriceDisplay = new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(result);
                            getProductVariations({ productIds: [productObj.productId] })
                            .then(innerResult => {
                                if(innerResult != null && typeof innerResult == 'object' && Object.keys(innerResult).includes(productObj.productId)){
                                    productObj.variations = innerResult[productObj.productId];
                                    this.manualPricesByProductId[selectedProduct.id] = unitPrice;
                                    this.positions = [...this.positions, productObj];
                                    this.populatePositionProductIds();
                                    lookup.selection = null;
                                } else {
                                    this.priceError = 'General Error';
                                    lookup.selection = null;
                                }
                            });
                        } else {
                            this.priceError = this.label.noPriceFoundProductNotAdded;
                            lookup.selection = null;
                        }
                    })
                } else {
                    getProductVariations({ productIds: [productObj.productId] })
                    .then(innerResult => {
                        if(innerResult != null && typeof innerResult == 'object' && Object.keys(innerResult).includes(productObj.productId)){
                            productObj.variations = innerResult[productObj.productId];
                            this.manualPricesByProductId[selectedProduct.id] = unitPrice;
                            this.positions = [...this.positions, productObj];
                            this.populatePositionProductIds();
                            lookup.selection = null;
                        } else {
                            this.priceError = 'General Error';
                            lookup.selection = null;
                        }
                    });
                }
            }
        }
    }

    handleDeletePosition(event){
        let recordid = event.detail.rowid;
        this.variationRequestVersionsByRowId[recordid] = (this.variationRequestVersionsByRowId[recordid] ?? 0) + 1;
        delete this.manualPricesByProductId[recordid];
        this.positions = this.positions.filter(
            position => position.productId !== recordid
        );
        this.populatePositionProductIds();
    }

    getNumericPrice(value){
        if(stringIsNotBlank(value)){
            let price = Number(value);
            return Number.isFinite(price) ? price : null;
        }
        return null;
    }

    getPriceForPosition(position){
        let referencePosition = (this.getReferencePositions(this.params.reference) ?? []).find(item => item.productId === position.productId);
        let referencePrice = this.getNumericPrice(referencePosition?.price);
        if(referencePrice != null){
            return Promise.resolve(referencePrice);
        }
        let pricebookPrice = this.getNumericPrice(this.customerPricebook?.[position.productId]);
        if(pricebookPrice != null){
            return Promise.resolve(pricebookPrice);
        }
        if(this.selectedAccountId == null){
            return Promise.resolve(null);
        }
        return getSinglePriceByOrderSimulation({
            productObj: JSON.stringify(position),
            accountId: this.selectedAccountId
        }).then(result => {
            return this.getNumericPrice(result);
        });
    }

    resetPositionVariation(rowid){
        this.positions = this.positions.map(position => position.productId === rowid ? {...position} : position);
        this.populatePositionProductIds();
    }

    handleQuantityUnitOfMeasureChange(rowid, value){
        let position = this.positions.find(item => item.productId === rowid);
        let variation = position?.variations?.find(item => item.value === value || item.label === value);
        if(position == null || variation == null){
            return;
        }
        let requestVersion = (this.variationRequestVersionsByRowId[rowid] ?? 0) + 1;
        this.variationRequestVersionsByRowId[rowid] = requestVersion;
        if(variation.value === position.productId){
            this.resetPositionVariation(rowid);
            return;
        }
        if(this.positions.some(item => item.productId === variation.value)){
            this.resetPositionVariation(rowid);
            return;
        }

        let factor = Number(variation.factor);
        let changedPosition = {
            ...position,
            productId: variation.value,
            name: variation.name,
            productCode: variation.productCode,
            description: variation.productCode,
            factor: Number.isFinite(factor) && factor > 0 ? factor : 1,
            baseProductCode: variation.baseProductCode,
            quantityUnitOfMeasure: variation.label,
            currencyIsoCode: variation.currencyIsoCode ?? position.currencyIsoCode
        };

        this.priceError = null;
        this.getPriceForPosition(changedPosition)
        .then(price => {
            if(this.variationRequestVersionsByRowId[rowid] !== requestVersion){
                return;
            }
            let currentPosition = this.positions.find(item => item.productId === rowid);
            if(price == null || currentPosition == null || this.positions.some(item => item.productId === variation.value)){
                if(price == null){
                    this.priceError = this.label.noPriceFoundProductNotAdded;
                }
                this.resetPositionVariation(rowid);
                return;
            }
            let updatedPosition = {
                ...currentPosition,
                productId: variation.value,
                name: variation.name,
                productCode: variation.productCode,
                description: variation.productCode,
                factor: Number.isFinite(factor) && factor > 0 ? factor : 1,
                baseProductCode: variation.baseProductCode,
                quantityUnitOfMeasure: variation.label,
                currencyIsoCode: variation.currencyIsoCode ?? currentPosition.currencyIsoCode,
                price,
                status: currentPosition.status === 'manual' ? 'manual' : 'modified'
            };
            if(updatedPosition.status === 'manual'){
                this.manualPricesByProductId[updatedPosition.productId] = price;
            }
            this.positions = this.positions.map(item => item.productId === rowid ? updatedPosition : item);
            this.populatePositionProductIds();
        })
        .catch(error => {
            if(this.variationRequestVersionsByRowId[rowid] === requestVersion){
                console.error(error);
                this.priceError = this.label.noPriceFoundProductNotAdded;
                this.resetPositionVariation(rowid);
            }
        });
    }

    handleChangePosition(event){
        let { rowid, field, value } = event.detail;
        if(field === 'quantityUnitOfMeasure'){
            this.handleQuantityUnitOfMeasureChange(rowid, value);
            return;
        }
        if(field === 'price' && this.positions.some(position => position.productId === rowid && position.status === 'manual')){
            this.manualPricesByProductId[rowid] = value;
        }

        this.positions = this.positions.map(position =>
            position.productId === rowid
                ? {
                    ...position,
                    [field]: value,
                    status: position.status === 'manual' ? 'manual' : 'modified'
                } : position
        );
        this.populatePositionProductIds();
    }

    /* INTERNAL FUNCTIONS */
    populatePositionProductIds() {
        let currency = new Intl.NumberFormat('de-DE', {style: 'currency', currency: 'EUR'});
        let totalValue = 0;
        let totalGoodsValue = 0;
        let referencePositionsByProduct = this.getReferencePositionsByProduct(this.params.reference);
        let referenceNumber = this.getReferenceNumber(this.params.reference);
        let productWarnings = [];
        this.positions = this.positions.map(position => {
            let totalPrice = (position.quantity ?? 0) * (position.price ?? 0);
            let creditIssuance = position.creditIssuanceVal === 'WITH';
            let presentation = this.buildPositionPresentation(position, referencePositionsByProduct, referenceNumber);
            if(stringIsNotBlank(presentation.notice)){
                productWarnings.push(presentation.notice);
            }
            let updated = {
                ...position,
                ...presentation,
                totalPrice,
                priceDisplay: currency.format(position.price ?? 0),
                totalPriceDisplay: currency.format(totalPrice),
                creditIssuance,
                creditIssuanceDisplay: position.creditIssuanceVal === 'WITH' ? this.label.refundYes : (position.creditIssuanceVal === 'WITHOUT' ? this.label.refundNo : ''),
                returnReasonLong: this.returnReasonMap[position.returnReason] ?? ''
            };
            if (this.params.goodsReturn === false || (this.params.refund === true && creditIssuance)) {
                totalValue += totalPrice;
            }
            totalGoodsValue += totalPrice;
            return updated;
        });
        this.productWarnings = productWarnings;
        this.positionProductIds = this.positions.map(position => position.productId);
        this.totalValue = totalValue;
        this.totalGoodsValue = totalGoodsValue;
    }

    buildPositionPresentation(position, referencePositionsByProduct, referenceNumber){
        let referencePosition = referencePositionsByProduct?.get(this.getPositionBaseProductKey(position));
        let factoredQuantity = (Number(position.quantity) || 0) * this.getPositionFactor(position);
        let hasReference = referencePositionsByProduct != null && (this.isOrderReference || this.isInvoiceReference);
        let isNotInCustomerListing = this.customerListingLoaded && !this.customerListingProductIds.includes(position.productId);
        let isAmountLargerThanReference = hasReference && referencePosition != null && factoredQuantity > (Number(referencePosition.originalFactoredQuantity) || 0);
        let isNotInReference = hasReference && referencePosition == null;
        let notice = '';
        if(isNotInCustomerListing){
            notice = this.label.notInCustomerListing;
        } else if(isAmountLargerThanReference){
            notice = this.label.amountLargerThanReference + ' (' + referencePosition.quantity + ')';
        } else if(isNotInReference){
            notice = this.label.notInReference;
        }

        let isManual = position.status === 'manual' || this.isNoneReference;
        let originReferenceNumber = position.originReferenceNumber ?? referenceNumber;
        let origin = isManual ? this.label.manual : (position.status === 'modified' ? '✎ ' : '') + originReferenceNumber;
        let recognizedInReference = referencePosition != null;
        let productCode = position.productCode ?? position.description ?? '';

        return {
            originReferenceNumber,
            originDisplay: origin,
            isManual,
            recognizedInReference,
            productCode,
            factoredQuantity,
            originalQuantity: referencePosition?.originalQuantity ?? null,
            originalFactoredQuantity: referencePosition?.originalFactoredQuantity ?? null,
            isNotInCustomerListing,
            isAmountLargerThanReference,
            isNotInReference,
            notice,
            rowStateDisplay: '●',
            rowStateClass: stringIsNotBlank(notice) ? 'slds-text-color_warning' : 'slds-text-color_success'
        };
    }

    updatePicklistColumn(field, options) {
        this.editColumns = this.editColumns.map(column =>
            column.fieldName === field ? {
                ...column, typeAttributes: {
                    ...column.typeAttributes,
                    picklist: options
                }
            } : column
        );
        this.editColumnsAlt = this.editColumnsAlt.map(column =>
            column.fieldName === field ? {
                ...column, typeAttributes: {
                    ...column.typeAttributes,
                    picklist: options
                }
            } : column
        );
    }
}
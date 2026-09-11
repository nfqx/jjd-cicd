import { LightningElement, api, track } from 'lwc';

// APEX
import retrievePrefill from '@salesforce/apex/ReturnOrderController.retrievePrefill';
import lookupSearchOrder from '@salesforce/apex/ReturnOrderController.lookupSearchOrder';
import lookupSearchInvoice from '@salesforce/apex/ReturnOrderController.lookupSearchInvoice';
import searchProducts from '@salesforce/apex/ReturnOrderController.searchProducts';
import createCase from '@salesforce/apex/ReturnOrderController.createCase';

import accountDetails from '@salesforce/label/c.ReturnOrderMaskAccountDetails';
import add from '@salesforce/label/c.ReturnOrderMaskAdd';
import address from '@salesforce/label/c.ReturnOrderMaskAddress';
import allActiveDarbovenProducts from '@salesforce/label/c.ReturnOrderMaskAllActiveDarbovenProducts';
import allActiveProducts from '@salesforce/label/c.ReturnOrderMaskAllActiveProducts';
import allMatchingProductsAdded from '@salesforce/label/c.ReturnOrderMaskAllMatchingProductsAdded';
import amount from '@salesforce/label/c.ReturnOrderMaskAmount';
import answerGoodsOrCredit from '@salesforce/label/c.ReturnOrderMaskAnswerGoodsOrCredit';
import answerPreliminaryQuestion from '@salesforce/label/c.ReturnOrderMaskAnswerPreliminaryQuestion';
import answerRefundQuestion from '@salesforce/label/c.ReturnOrderMaskAnswerRefundQuestion';
import appliesToEntireCase from '@salesforce/label/c.ReturnOrderMaskAppliesToEntireCase';
import backToEditing from '@salesforce/label/c.ReturnOrderMaskBackToEditing';
import backToReference from '@salesforce/label/c.ReturnOrderMaskBackToReference';
import caseLabel from '@salesforce/label/c.ReturnOrderMaskCase';
import caseCategory from '@salesforce/label/c.ReturnOrderMaskCaseCategory';
import caseInvoice from '@salesforce/label/c.ReturnOrderMaskCaseInvoice';
import caseOrder from '@salesforce/label/c.ReturnOrderMaskCaseOrder';
import caseReason from '@salesforce/label/c.ReturnOrderMaskCaseReason';
import caseSelections from '@salesforce/label/c.ReturnOrderMaskCaseSelections';
import caseType from '@salesforce/label/c.ReturnOrderMaskCaseType';
import chooseSelectionsFirst from '@salesforce/label/c.ReturnOrderMaskChooseSelectionsFirst';
import collectiveInvoiceFor from '@salesforce/label/c.ReturnOrderMaskCollectiveInvoiceFor';
import continueToEditing from '@salesforce/label/c.ReturnOrderMaskContinueToEditing';
import coreProductRange from '@salesforce/label/c.ReturnOrderMaskCoreProductRange';
import credit from '@salesforce/label/c.ReturnOrderMaskCredit';
import creditValue from '@salesforce/label/c.ReturnOrderMaskCreditValue';
import customer from '@salesforce/label/c.ReturnOrderMaskCustomer';
import customerNumber from '@salesforce/label/c.ReturnOrderMaskCustomerNumber';
import customerReceivesRefund from '@salesforce/label/c.ReturnOrderMaskCustomerReceivesRefund';
import customerShips from '@salesforce/label/c.ReturnOrderMaskCustomerShips';
import customerShipsGoodsText from '@salesforce/label/c.ReturnOrderMaskCustomerShipsGoodsText';
import darbovenArrangesTransport from '@salesforce/label/c.ReturnOrderMaskDarbovenArrangesTransport';
import dateLabel from '@salesforce/label/c.ReturnOrderMaskDate';
import deliveryAddress from '@salesforce/label/c.ReturnOrderMaskDeliveryAddress';
import derived from '@salesforce/label/c.ReturnOrderMaskDerived';
import derivedFromSelections from '@salesforce/label/c.ReturnOrderMaskDerivedFromSelections';
import details from '@salesforce/label/c.ReturnOrderMaskDetails';
import documentLinesBehavior from '@salesforce/label/c.ReturnOrderMaskDocumentLinesBehavior';
import editLAbel from '@salesforce/label/c.ReturnOrderMaskEdit';
import editable from '@salesforce/label/c.ReturnOrderMaskEditable';
import emails from '@salesforce/label/c.ReturnOrderMaskEmails';
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
import identifiedFromCase from '@salesforce/label/c.ReturnOrderMaskIdentifiedFromCase';
import includedOrders from '@salesforce/label/c.ReturnOrderMaskIncludedOrders';
import inDocument from '@salesforce/label/c.ReturnOrderMaskInDocument';
import industry from '@salesforce/label/c.ReturnOrderMaskIndustry';
import inSAP from '@salesforce/label/c.ReturnOrderMaskInSAP';
import internalNote from '@salesforce/label/c.ReturnOrderMaskInternalNote';
import internalNotePlaceholder from '@salesforce/label/c.ReturnOrderMaskInternalNotePlaceholder';
import invoice from '@salesforce/label/c.ReturnOrderMaskInvoice';
import itemsFromProductSearch from '@salesforce/label/c.ReturnOrderMaskItemsFromProductSearch';
import itemsInTableBelow from '@salesforce/label/c.ReturnOrderMaskItemsInTableBelow';
import lineItems from '@salesforce/label/c.ReturnOrderMaskLineItems';
import lineItemType from '@salesforce/label/c.ReturnOrderMaskLineItemType';
import manually from '@salesforce/label/c.ReturnOrderMaskManually';
import multipleTypesPossibleInfo from '@salesforce/label/c.ReturnOrderMaskMultipleTypesPossibleInfo';
import noDocumentReason from '@salesforce/label/c.ReturnOrderMaskNoDocumentReason';
import noDocumentReasonExample from '@salesforce/label/c.ReturnOrderMaskNoDocumentReasonExample';
import noDocumentReasonHelp from '@salesforce/label/c.ReturnOrderMaskNoDocumentReasonHelp';
import noGoodsReturned from '@salesforce/label/c.ReturnOrderMaskNoGoodsReturned';
import noGoodsValueCreditInfo from '@salesforce/label/c.ReturnOrderMaskNoGoodsValueCreditInfo';
import noLineItemsYet from '@salesforce/label/c.ReturnOrderMaskNoLineItemsYet';
import noneLabel from '@salesforce/label/c.ReturnOrderMaskNone';
import noNotices from '@salesforce/label/c.ReturnOrderMaskNoNotices';
import noReturnOrderWithoutGoods from '@salesforce/label/c.ReturnOrderMaskNoReturnOrderWithoutGoods';
import notInCustomerListing from '@salesforce/label/c.ReturnOrderMaskNotInCustomerListing';
import noValueCreditOnly from '@salesforce/label/c.ReturnOrderMaskNoValueCreditOnly';
import noWithoutCredit from '@salesforce/label/c.ReturnOrderMaskNoWithoutCredit';
import optional from '@salesforce/label/c.ReturnOrderMaskOptional';
import orderLabel from '@salesforce/label/c.ReturnOrderMaskOrder';
import orderDocument from '@salesforce/label/c.ReturnOrderMaskOrderDocument';
import orders from '@salesforce/label/c.ReturnOrderMaskOrders';
import outsideDocumentProducts from '@salesforce/label/c.ReturnOrderMaskOutsideDocumentProducts';
import picklistChangedReason from '@salesforce/label/c.ReturnOrderMaskPicklistChangedReason';
import picklistValuesNote from '@salesforce/label/c.ReturnOrderMaskPicklistValuesNote';
import pickupAddressHelp from '@salesforce/label/c.ReturnOrderMaskPickupAddressHelp';
import pickupLocation from '@salesforce/label/c.ReturnOrderMaskPickupLocation';
import pleaseSelect from '@salesforce/label/c.ReturnOrderMaskPleaseSelect';
import price from '@salesforce/label/c.ReturnOrderMaskPrice';
import product from '@salesforce/label/c.ReturnOrderMaskProduct';
import productListing from '@salesforce/label/c.ReturnOrderMaskProductListing';
import productsAvailable from '@salesforce/label/c.ReturnOrderMaskProductsAvailable';
import productSearchHelp from '@salesforce/label/c.ReturnOrderMaskProductSearchHelp';
import productSearchPlaceholder from '@salesforce/label/c.ReturnOrderMaskProductSearchPlaceholder';
import quantity from '@salesforce/label/c.ReturnOrderMaskQuantity';
import readyForRetrieval from '@salesforce/label/c.ReturnOrderMaskReadyForRetrieval';
import reason from '@salesforce/label/c.ReturnOrderMaskReason';
import referenceLabel from '@salesforce/label/c.ReturnOrderMaskReference';
import referenceRelation from '@salesforce/label/c.ReturnOrderMaskReferenceRelation';
import requestedPickupDate from '@salesforce/label/c.ReturnOrderMaskRequestedPickupDate';
import requestedPickupDateHelp from '@salesforce/label/c.ReturnOrderMaskRequestedPickupDateHelp';
import returnShippingMethodHelp from '@salesforce/label/c.ReturnOrderMaskReturnShippingMethodHelp';
import reviewAndComplete from '@salesforce/label/c.ReturnOrderMaskReviewAndComplete';
import searchProduct from '@salesforce/label/c.ReturnOrderMaskSearchProduct';
import selectCaseReason from '@salesforce/label/c.ReturnOrderMaskSelectCaseReason';
import selectGoodsMovement from '@salesforce/label/c.ReturnOrderMaskSelectGoodsMovement';
import selectReferenceDocument from '@salesforce/label/c.ReturnOrderMaskSelectReferenceDocument';
import selectShippingMethod from '@salesforce/label/c.ReturnOrderMaskSelectShippingMethod';
import shippingMethod from '@salesforce/label/c.ReturnOrderMaskShippingMethod';
import sourceLabel from '@salesforce/label/c.ReturnOrderMaskSource';
import statusLabel from '@salesforce/label/c.ReturnOrderMaskStatus';
import subject from '@salesforce/label/c.ReturnOrderMaskSubject';
import submitSAPGoodsReceiptInfo from '@salesforce/label/c.ReturnOrderMaskSubmitSAPGoodsReceiptInfo';
import submitSAPStartsPickupInfo from '@salesforce/label/c.ReturnOrderMaskSubmitSAPStartsPickupInfo';
import submitToSAP from '@salesforce/label/c.ReturnOrderMaskSubmitToSAP';
import subtype from '@salesforce/label/c.ReturnOrderMaskSubtype';
import tableNotices from '@salesforce/label/c.ReturnOrderMaskTableNotices';
import totalGoodsValue from '@salesforce/label/c.ReturnOrderMaskTotalGoodsValue';
import typeLabel from '@salesforce/label/c.ReturnOrderMaskType';
import unannouncedReturnReceived from '@salesforce/label/c.ReturnOrderMaskUnannouncedReturnReceived';
import unit from '@salesforce/label/c.ReturnOrderMaskUnit';
import valueLabel from '@salesforce/label/c.ReturnOrderMaskValue';
import valuesLabel from '@salesforce/label/c.ReturnOrderMaskValues';
import warnings from '@salesforce/label/c.ReturnOrderMaskWarnings';
import whoMovesGoodsHelp from '@salesforce/label/c.ReturnOrderMaskWhoMovesGoodsHelp';
import withLabel from '@salesforce/label/c.ReturnOrderMaskWith';
import without from '@salesforce/label/c.ReturnOrderMaskWithout';
import withoutDocument from '@salesforce/label/c.ReturnOrderMaskWithoutDocument';
import withoutDocumentLower from '@salesforce/label/c.ReturnOrderMaskWithoutDocumentLower';
import yesCreditOnlyCase from '@salesforce/label/c.ReturnOrderMaskYesCreditOnlyCase';
import yesGoodsReturned from '@salesforce/label/c.ReturnOrderMaskYesGoodsReturned';
import yesWithCredit from '@salesforce/label/c.ReturnOrderMaskYesWithCredit';


export default class ReturnOrderMask extends LightningElement {

    label = {
        accountDetails,
        add,
        address,
        allActiveDarbovenProducts,
        allActiveProducts,
        allMatchingProductsAdded,
        amount,
        answerGoodsOrCredit,
        answerPreliminaryQuestion,
        answerRefundQuestion,
        appliesToEntireCase,
        backToEditing,
        backToReference,
        caseLabel,
        caseCategory,
        caseInvoice,
        caseOrder,
        caseReason,
        caseSelections,
        caseType,
        chooseSelectionsFirst,
        collectiveInvoiceFor,
        continueToEditing,
        coreProductRange,
        credit,
        creditValue,
        customer,
        customerNumber,
        customerReceivesRefund,
        customerShips,
        customerShipsGoodsText,
        darbovenArrangesTransport,
        dateLabel,
        deliveryAddress,
        derived,
        derivedFromSelections,
        details,
        documentLinesBehavior,
        editLAbel,
        editable,
        emails,
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
        identifiedFromCase,
        includedOrders,
        inDocument,
        industry,
        inSAP,
        internalNote,
        internalNotePlaceholder,
        invoice,
        itemsFromProductSearch,
        itemsInTableBelow,
        lineItems,
        lineItemType,
        manually,
        multipleTypesPossibleInfo,
        noDocumentReason,
        noDocumentReasonExample,
        noDocumentReasonHelp,
        noGoodsReturned,
        noGoodsValueCreditInfo,
        noLineItemsYet,
        noneLabel,
        noNotices,
        noReturnOrderWithoutGoods,
        notInCustomerListing,
        noValueCreditOnly,
        noWithoutCredit,
        optional,
        orderLabel,
        orderDocument,
        orders,
        outsideDocumentProducts,
        picklistChangedReason,
        picklistValuesNote,
        pickupAddressHelp,
        pickupLocation,
        pleaseSelect,
        price,
        product,
        productListing,
        productsAvailable,
        productSearchHelp,
        productSearchPlaceholder,
        quantity,
        readyForRetrieval,
        reason,
        referenceLabel,
        referenceRelation,
        requestedPickupDate,
        requestedPickupDateHelp,
        returnShippingMethodHelp,
        reviewAndComplete,
        searchProduct,
        selectCaseReason,
        selectGoodsMovement,
        selectReferenceDocument,
        selectShippingMethod,
        shippingMethod,
        sourceLabel,
        statusLabel,
        subject,
        submitSAPGoodsReceiptInfo,
        submitSAPStartsPickupInfo,
        submitToSAP,
        subtype,
        tableNotices,
        totalGoodsValue,
        typeLabel,
        unannouncedReturnReceived,
        unit,
        valueLabel,
        valuesLabel,
        warnings,
        whoMovesGoodsHelp,
        withLabel,
        without,
        withoutDocument,
        withoutDocumentLower,
        yesCreditOnlyCase,
        yesGoodsReturned,
        yesWithCredit
    }
}
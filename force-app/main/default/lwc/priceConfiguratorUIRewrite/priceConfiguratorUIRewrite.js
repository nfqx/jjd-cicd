import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import custommodalcss from "@salesforce/resourceUrl/custommodalcss";
import removeStyle from '@salesforce/resourceUrl/removeStyle';
import { loadStyle, loadScript  } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex
import checkIfNewCustomer from '@salesforce/apex/PriceConfiguratorController.checkIfNewCustomer';
import checkIfNewCustomerLite from '@salesforce/apex/PriceConfiguratorController.checkIfNewCustomerLite';
import createOffer from '@salesforce/apex/PriceConfiguratorController.createOffer';
import getAuxiliaryTables from '@salesforce/apex/PriceConfiguratorController.getAuxiliaryTables';
import getStandardPricebookEntries from '@salesforce/apex/PriceConfiguratorController.getStandardPricebookEntries';
import getSubgroupCount from '@salesforce/apex/PriceConfiguratorController.getSubgroupCount';
import preloadQuoteData from '@salesforce/apex/PriceConfiguratorController.preloadQuoteData';


// Custom Fields
import CLOSED_FIELD from "@salesforce/schema/Opportunity.IsClosed";

// Custom Labels
import interval from '@salesforce/label/c.PriceConfiguratorInterval';
import firstCheck from '@salesforce/label/c.PriceConfiguratorFirstCheck';
import settingRequested from '@salesforce/label/c.PriceConfiguratorSettingRequested';
import yes from '@salesforce/label/c.GeneralYes';
import no from '@salesforce/label/c.GeneralNo';
import discount from '@salesforce/label/c.GeneralDiscount';
import rebate from '@salesforce/label/c.GeneralRebate';
import specialDiscount from '@salesforce/label/c.GeneralSpecialDiscount';
import price from '@salesforce/label/c.GeneralPrice';
import basePrice from '@salesforce/label/c.GeneralBasePrice';
import offerPrice from '@salesforce/label/c.GeneralOfferPrice';
import quantity from '@salesforce/label/c.GeneralQuantity';
import sum from '@salesforce/label/c.GeneralSum';
import product from '@salesforce/label/c.GeneralProduct';
import productType from '@salesforce/label/c.GeneralProductType';
import allItems from '@salesforce/label/c.GeneralAllItems';
import individual from '@salesforce/label/c.GeneralIndividual';
import closedOpp from '@salesforce/label/c.PriceConfiguratorClosedOpp';
import newCustomerWithInheritedWarning from '@salesforce/label/c.PriceConfiguratorNewCustomer';
import branch from '@salesforce/label/c.PriceConfiguratorBranch';
import conditionProducts from '@salesforce/label/c.PriceConfiguratorConditionProducts';
import digitalRequired from '@salesforce/label/c.PriceConfiguratorDigitalOrderRequired';
import numCocoaTypes from '@salesforce/label/c.PriceConfiguratorHowManyCocoaTypes';
import numCoffeeTypes from '@salesforce/label/c.PriceConfiguratorHowManyCoffeeTypes';
import numOtherTypes from '@salesforce/label/c.PriceConfiguratorHowManyOtherTypes';
import numTeaTypes from '@salesforce/label/c.PriceConfiguratorHowManyTeaTypes';
import amtCocoa from '@salesforce/label/c.PriceConfiguratorHowMuchCocoa';
import amtCoffee from '@salesforce/label/c.PriceConfiguratorHowMuchCoffee';
import amtOther from '@salesforce/label/c.PriceConfiguratorHowMuchOther';
import amtTea from '@salesforce/label/c.PriceConfiguratorHowMuchTea';
import howPresent from '@salesforce/label/c.PriceConfiguratorHowWillCustomerPresent';
import createAndContinue from '@salesforce/label/c.PriceConfiguratorCreateOfferAndContinueConfiguring';
import createAndClose from '@salesforce/label/c.PriceConfiguratorCreateOfferAndCloseConfigurator';
import updateAndClose from '@salesforce/label/c.PriceConfiguratorUpdateOfferAndCloseConfigurator';
import growthInPercent from '@salesforce/label/c.PriceConfiguratorGrowthInPercent';
import simulate from '@salesforce/label/c.PriceConfiguratorSimulate';
import simulateGrowth from '@salesforce/label/c.PriceConfiguratorSimulateGrowth';
import simulatedRevenue from '@salesforce/label/c.PriceConfiguratorSimulatedTurnover';
import downstreamConditions from '@salesforce/label/c.PriceConfiguratorDownstreamConditions';
import teaDiscount from '@salesforce/label/c.PriceConfiguratorTeaDiscount';
import initialEquipment from '@salesforce/label/c.PriceConfiguratorInitialEquipment';
import initialEquipmentAndSurcharge from '@salesforce/label/c.PriceConfiguratorInitialEquipmentAndSurcharge';
import previewPrice from '@salesforce/label/c.PriceConfiguratorPreviewPrice';
import markForInitialOrder from '@salesforce/label/c.PriceConfiguratorMarkForInitialOrder';
import discountBank from '@salesforce/label/c.PriceConfiguratorDiscountBank';
import discount0To10 from '@salesforce/label/c.PriceConfiguratorDiscount0To10';
import discount10plus from '@salesforce/label/c.PriceConfiguratorDiscount10plus';
import discountBankEN from '@salesforce/label/c.PriceConfiguratorDoNotTranslateDiscountBank';
import discount0To10EN from '@salesforce/label/c.PriceConfiguratorDoNotTranslateDiscount0To10';
import discount10plusEN from '@salesforce/label/c.PriceConfiguratorDoNotTranslateDiscount10plus';
import wkz from '@salesforce/label/c.PriceConfiguratorWKZ';
import roastedCoffeeInKg from '@salesforce/label/c.PriceConfiguratorRoastedCoffeeInKg';
import totalValueInEuro from '@salesforce/label/c.PriceConfiguratorTotalValueInL';
import runtimeInMonths from '@salesforce/label/c.PriceConfiguratorRuntimeInMonths';
import menuLogo from '@salesforce/label/c.PriceConfiguratorMenuLogo';
import productSpecificRefund from '@salesforce/label/c.PriceConfiguratorProductSpecificRefund';
import purchaseDuringRuntime from '@salesforce/label/c.PriceConfiguratorPurchaseDuringRuntime';
import kgChargeCalculated from '@salesforce/label/c.PriceConfiguratorKgChargeCalculated';
import offerOnTable from '@salesforce/label/c.PriceConfiguratorOfferOnTable';
import offerInProperty from '@salesforce/label/c.PriceConfiguratorOfferInProperty';
import cancel from '@salesforce/label/c.GeneralCancel';
import addRow from '@salesforce/label/c.GeneralAddRow';
import simRev2000 from '@salesforce/label/c.PriceConfigurator2000Below';
import simRev10000below from '@salesforce/label/c.PriceConfigurator10000Below';
import simRev10000above from '@salesforce/label/c.PriceConfigurator10000Above';
import growth0 from '@salesforce/label/c.PriceConfigurator0To5';
import growth5 from '@salesforce/label/c.PriceConfigurator5To10';
import growth10 from '@salesforce/label/c.PriceConfigurator10To15';
import growth15 from '@salesforce/label/c.PriceConfigurator15Above';
import warningTemplate from '@salesforce/label/c.PriceConfiguratorWarningTemplate';
import deleteLabel from '@salesforce/label/c.GeneralDelete';
import refund from '@salesforce/label/c.GeneralRefund';
import refundPercent from '@salesforce/label/c.GeneralRefundPercent';
import simulatedPrice from '@salesforce/label/c.GeneralSimulatedPrice';
import errorMsg from '@salesforce/label/c.WebshopGeneralError';
import success from '@salesforce/label/c.GeneralSuccess';
import seeItHere from '@salesforce/label/c.GeneralSeeItHere';
import quoteCreated from '@salesforce/label/c.GeneralQuoteCreated';
import subgroup from '@salesforce/label/c.GeneralSubgroup';
import indexCondition from '@salesforce/label/c.GeneralIndexCondition';
import indexConditionPre from '@salesforce/label/c.GeneralIndexConditionPre';
import none from '@salesforce/label/c.GeneralNone';
import initialEquipmentError from '@salesforce/label/c.PriceConfiguratorInitialEquipmentError';
import totalAddition from '@salesforce/label/c.PriceConfiguratorTotalAddition';
import totalAdditionHelp from '@salesforce/label/c.PriceConfiguratorTotalAdditionHelp';
import chainWarning from '@salesforce/label/c.PriceConfiguratorChainWarning';
import additionalAgreements from '@salesforce/label/c.PriceConfiguratorAdditionalAgreements';
import additionalAgreementsQualityVisit from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsQualityVisit';
import additionalAgreementsFrame from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsFrameCheckbox';
import additionalAgreementsFrameRich from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsFrameRichText';
import additionalAgreementsFrameRichPrefill from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsFrameRichTextPrefill';
import additionalAgreementsOfferFinancing from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsOfferFinancing';
import additionalAgreementsOfferTasting from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsOfferTasting';
import additionalAgreementsOfferTraining from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsOfferTraining';
import additionalAgreementsOther from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsOther';
import additionalAgreementsOtherRich from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsOtherRich';
import industry from '@salesforce/label/c.GeneralIndustry';
import machineConfigurator from '@salesforce/label/c.MachineConfigurator';
import openMachineConfigurator from '@salesforce/label/c.MachineConfiguratorOpen';
import closeMachineConfigurator from '@salesforce/label/c.MachineConfiguratorClose';
import machineAlreadyConfigured from '@salesforce/label/c.MachineConfiguratorAlreadyConfigured';
import refundCoffee from '@salesforce/label/c.PriceConfiguratorRefundCoffee';
import refundCoffeeLevel from '@salesforce/label/c.PriceConfiguratorRefundCoffeeLevel';
import refundCoffeeType from '@salesforce/label/c.PriceConfiguratorRefundCoffeeType';
import refundCoffeeWkz from '@salesforce/label/c.PriceConfiguratorRefundCoffeeWKZ';
import refundInEuro from '@salesforce/label/c.PriceConfiguratorRefundInEuro';
import refundTea from '@salesforce/label/c.PriceConfiguratorRefundTea';
import refundTeaLevel from '@salesforce/label/c.PriceConfiguratorRefundTeaLevel';
import refundTeaType from '@salesforce/label/c.PriceConfiguratorRefundTeaType';
import refundTeaWkz from '@salesforce/label/c.PriceConfiguratorRefundTeaWKZ';
import refundVolumeEuro from '@salesforce/label/c.PriceConfiguratorRefundVolumeEuro';
import refundVolumeKg from '@salesforce/label/c.PriceConfiguratorRefundVolumeKg';
import refundWkzAnnual from '@salesforce/label/c.PriceConfiguratorRefundWKZAnnual';
import refundWkzAnnualCoffee from '@salesforce/label/c.PriceConfiguratorRefundWKZAnnualCoffee';
import refundWkzAnnualTea from '@salesforce/label/c.PriceConfiguratorRefundWKZAnnualTea';
import refundWkzOneTime from '@salesforce/label/c.PriceConfiguratorRefundWKZOneTime';
import refundWkzOneTimeCoffee from '@salesforce/label/c.PriceConfiguratorRefundWKZOneTimeCoffee';
import refundWkzOneTimeTea from '@salesforce/label/c.PriceConfiguratorRefundWKZOneTimeTea';
import revenue from '@salesforce/label/c.GeneralRevenueGerman';
import purchase from '@salesforce/label/c.GeneralPurchaseGerman';
import addMachineLeasing from '@salesforce/label/c.PriceConfiguratorAddMachineLeasing';
import machineLeasingEnabled from '@salesforce/label/c.PriceConfiguratorDoNotTranslateMachineLeasingEnabled';
import machineLeasingWarning from '@salesforce/label/c.PriceConfiguratorMachineLeasingWarning';
import coffeeSurchargeMachine from '@salesforce/label/c.PriceConfiguratorCoffeeSurchargeMachine';
import onlyAppliedToCoffee from '@salesforce/label/c.PriceConfiguratorOnlyAppliedToCoffee';
import indexConditionFirstWarning from '@salesforce/label/c.PriceConfiguratorIndexConditionFirstWarning';
import indexConditionSecondWarning from '@salesforce/label/c.PriceConfiguratorIndexConditionSecondWarning';
import basicInformation from '@salesforce/label/c.PriceConfiguratorBasicInformation';
import productPurchase from '@salesforce/label/c.PriceConfiguratorProductPurchase';
import productPurchaseInherit from '@salesforce/label/c.PriceConfiguratorProductPurchaseInherit';
import brandVisibility from '@salesforce/label/c.PriceConfiguratorBrandVisibility';
import annualRefund from '@salesforce/label/c.PriceConfiguratorAnnualRefundInEuro';
import oneTimeRefund from '@salesforce/label/c.PriceConfiguratorOneTimeRefundInEuro';
import refundSection from '@salesforce/label/c.PriceConfiguratorRefundSection';
import additionalAgreementsSection from '@salesforce/label/c.PriceConfiguratorAdditionalAgreementsSection';
import simulationSection from '@salesforce/label/c.PriceConfiguratorSimulationSection';
import priceConfiguratorHeader from '@salesforce/label/c.PriceConfiguratorHeader';
import quantityMismatchWarning from '@salesforce/label/c.PriceConfiguratorQuantityMismatchWarning';
import errorMissingCocoa from '@salesforce/label/c.PriceConfiguratorErrorMissingCocoa';
import errorMissingCoffee from '@salesforce/label/c.PriceConfiguratorErrorMissingCoffee';
import errorMissingOther from '@salesforce/label/c.PriceConfiguratorErrorMissingOther';
import errorMissingTea from '@salesforce/label/c.PriceConfiguratorErrorMissingTea';
import errorEnterCocoa from '@salesforce/label/c.PriceConfiguratorErrorEnterCocoa';
import errorEnterCoffee from '@salesforce/label/c.PriceConfiguratorErrorEnterCoffee';
import errorEnterOther from '@salesforce/label/c.PriceConfiguratorErrorEnterOther';
import errorEnterTea from '@salesforce/label/c.PriceConfiguratorErrorEnterTea';
import errorNoProducts from '@salesforce/label/c.PriceConfiguratorErrorNoProducts';
import errorNotZeroOrEmpty from '@salesforce/label/c.PriceConfiguratorErrorNotZeroOrEmpty';
import validFrom from '@salesforce/label/c.PriceConfiguratorValidFrom';
import inheritedIndexCondition from '@salesforce/label/c.PriceConfiguratorInheritedIndexCondition';
import individualConditions from '@salesforce/label/c.PriceConfiguratorIndividualConditions';
import inheritedConditions from '@salesforce/label/c.PriceConfiguratorInheritedConditions';
import discountLabel from '@salesforce/label/c.PriceConfiguratorDiscountLabel';
import productPurchaseHelpText from '@salesforce/label/c.PriceConfiguratorProductPurchaseHelpText';
import coffeeVolumeDiscountLabel from '@salesforce/label/c.PriceConfiguratorCoffeeVolumeDiscountLabel';
import teaVolumeDiscountLabel from '@salesforce/label/c.PriceConfiguratorTeaVolumeDiscountLabel';
import cocoaVolumeDiscountLabel from '@salesforce/label/c.PriceConfiguratorCocoaVolumeDiscountLabel';
import otherGoodsVolumeDiscountLabel from '@salesforce/label/c.PriceConfiguratorOtherGoodsVolumeDiscountLabel';

export default class PriceConfiguratorUIRewrite extends NavigationMixin(LightningElement) {

    // System
    @api recordId;
    @track opportunityId = null;
    @track quoteId = null;
    @track machineOfferToEdit = null;
    @track isQuoteContext = false;
    @track oppLoaded = false;
    @track quoteIsDraft = false;
    @track firstTabStyle = '';
    @track secondTabStyle = 'height: 0px; opacity: 0; z-index: -1; position: relative;';
    @track isFirstTab = true;
    @track isSecondTab = false;
    // Reset from here
    @track newCustomer = 0; // 0 = totally new customer, 1 = customer with own set (no inheritance), 2 = new customer but with inherited data
    @track showSimulation = false;
    @track showRefund = false;
    @track pristine = true;
    @track showInitialEquipment = false;
    @track standardPricebookEntries = {};
    @track isLoaded = false;
    @track isLoading = false;
    @track industry = '';
    @track auxiliaryTables = {};
    @track maxConditionNumber = 2;
    @track maxInitialNumber = 2;
    @track showTeaColumn = false;
    @track showRefundColumn = false;
    @track showRefundAllItemsField = true;
    @track showInitialEquipmentTable = false;
    @track showInitialEquipmentError = false;
    @track subgroupCount = {};
    @track existingRows = [];
    @track existingRowsInitial = [];
    @track showMachineConfigurator = false;
    @track showMachineConfiguratorWarning = false;
    @track showMachineConfiguratorActual = false;
    @track machineConfiguratorFinalized = false;
    @track machineSurchargeCalculation = false;
    @track coffeeSurchargeMachine = 0;
    @track typeLoaded = false;
    @track conditionProductData = [];
    @track roastedCoffeeInKg = 0;
    @track totalValueInEuro = 0;
    @track indexConditionFromParams = null;
    @track hasIndexConditionFromParams = false;
    @track showIndexConditionSecondWarning = false;
    @track indexConditionPreset = null;
    @track machineConfiguratorStep = 1;
    @track activeSections = [];

    DISPLAY_ERRORS = {
        coffeeSelectionNoQuantity: false,
        teaSelectionNoQuantity: false,
        cocoaSelectionNoQuantity: false,
        otherSelectionNoQuantity: false,
        coffeeQuantityNoSelection: false,
        teaQuantityNoSelection: false,
        cocoaQuantityNoSelection: false,
        otherQuantityNoSelection: false,
        coffeeAmountZero : false,
        coffeeQuantityZero : false,
        teaAmountZero : false,
        teaQuantityZero : false,
        otherAmountZero : false,
        otherQuantityZero : false,
        cocoaAmountZero : false,
        cocoaQuantityZero : false,
        noCoffeeSelected : false,
        noCocoaSelected : false,
        noOtherSelected : false,
        noTeaSelected : false,
        noCoffeeQuantity : false,
        noCocoaQuantity : false,
        noOtherQuantity : false,
        noTeaQuantity : false,
        quantityMismatch : false,
        noProductsSelected : false
    }

    // Labels
    label = {
        individualConditions,
        inheritedConditions,
        interval,
        firstCheck,
        settingRequested,
        onlyAppliedToCoffee,
        yes,
        no,
        machineAlreadyConfigured,
        openMachineConfigurator,
        closeMachineConfigurator,
        discount,
        rebate,
        cancel,
        specialDiscount,
        price,
        quantity,
        sum,
        basePrice,
        offerPrice,
        product,
        productType,
        newCustomerWithInheritedWarning,
        closedOpp,
        simulatedPrice,
        branch,
        conditionProducts,
        digitalRequired,
        numCocoaTypes,
        numCoffeeTypes,
        numOtherTypes,
        numTeaTypes,
        amtCocoa,
        amtCoffee,
        amtOther,
        amtTea,
        howPresent,
        createAndContinue,
        createAndClose,
        updateAndClose,
        growthInPercent,
        simulate,
        simulateGrowth,
        simulatedRevenue,
        downstreamConditions,
        teaDiscount,
        roastedCoffeeInKg,
        initialEquipment,
        initialEquipmentAndSurcharge,
        previewPrice,
        markForInitialOrder,
        discountBank,
        discount0To10,
        discount10plus,
        discountBankEN,
        discount0To10EN,
        discount10plusEN,
        wkz,
        totalValueInEuro,
        runtimeInMonths,
        menuLogo,
        productSpecificRefund,
        purchaseDuringRuntime,
        offerOnTable,
        offerInProperty,
        allItems,
        individual,
        addRow,
        simRev2000,
        simRev10000below,
        simRev10000above,
        growth0,
        growth5,
        growth10,
        growth15,
        none,
        kgChargeCalculated,
        warningTemplate,
        deleteLabel,
        refund,
        refundPercent,
        errorMsg,
        success,
        quoteCreated,
        seeItHere,
        subgroup,
        initialEquipmentError,
        totalAddition,
        totalAdditionHelp,
        chainWarning,
        industry,
        machineConfigurator,
        additionalAgreements,
        additionalAgreementsFrame,
        additionalAgreementsFrameRich,
        additionalAgreementsFrameRichPrefill,
        additionalAgreementsOfferFinancing,
        additionalAgreementsOfferTasting,
        additionalAgreementsOfferTraining,
        additionalAgreementsOther,
        additionalAgreementsOtherRich,
        additionalAgreementsQualityVisit,
        refundCoffee,
        refundCoffeeLevel,
        refundCoffeeType,
        refundCoffeeWkz,
        refundInEuro,
        refundTea,
        refundTeaLevel,
        refundTeaType,
        refundTeaWkz,
        refundVolumeEuro,
        refundVolumeKg,
        refundWkzAnnual,
        refundWkzAnnualCoffee,
        refundWkzAnnualTea,
        refundWkzOneTime,
        refundWkzOneTimeCoffee,
        refundWkzOneTimeTea,
        revenue,
        purchase,
        indexCondition,
        indexConditionPre,
        addMachineLeasing,
        machineLeasingEnabled,
        machineLeasingWarning,
        coffeeSurchargeMachine,
        indexConditionFirstWarning,
        indexConditionSecondWarning,
        basicInformation,
        productPurchase,
        productPurchaseInherit,
        brandVisibility,
        annualRefund,
        oneTimeRefund,
        refundSection,
        additionalAgreementsSection,
        simulationSection,
        priceConfiguratorHeader,
        quantityMismatchWarning,
        errorMissingCocoa,
        errorMissingCoffee,
        errorMissingOther,
        errorMissingTea,
        errorEnterCocoa,
        errorEnterCoffee,
        errorEnterOther,
        errorEnterTea,
        errorNoProducts,
        errorNotZeroOrEmpty,
        validFrom,
        inheritedIndexCondition,
        discountLabel,
        productPurchaseHelpText,
        coffeeVolumeDiscountLabel,
        teaVolumeDiscountLabel,
        cocoaVolumeDiscountLabel,
        otherGoodsVolumeDiscountLabel
    };

    get indexConditionPresetYes(){
        return this.indexConditionPreset == this.label.yes;
    }
    get indexConditionFirstWarningLabel(){
        return this.label.indexConditionFirstWarning.replace('{0}', this.indexConditionFromParams.toString());
    }
    get indexConditionPicklistStyle(){
        return this.hasIndexConditionFromParamsAndNoChain ? 'display: none;' : '';
    }
    get dynamicIndexConditionLabel() {
        return this.isDependentChainMember ? this.label.inheritedIndexCondition : this.label.onlyAppliedToCoffee;
    }

    // Inputs
    PARAMS = {
        purchaseDuringRuntime : 0,
        purchaseDuringRuntimeDisplay : 0,
        hasOfferOnTable : this.label.no,
        hasMenuLogo : this.label.no,
        hasOfferInProperty : this.label.no,
        hasDigitalRequired : this.label.no,
        subgroupHasPrice: false,
        discount : '0',
        runtimeMonths : 12,
        simulatedRevenue : '0',
        growthPercent : '0',
        kgChargeCalculated : 0,
        kgChargeCalculatedDisplay : 0,
        maxWarning: 0,
        totalTeaDiscount: 0,
        maxTeaDiscount: 0,
        maxTeaDiscountViolated: false,
        maxTeaDiscountValue: 0,
        coffeeQuantityDiscountTotal: 0,
        coffeeSelectionDiscountTotal: 0,
        teaQuantityDiscountTotal: 0,
        teaSelectionDiscountTotal: 0,
        cocoaQuantityDiscountTotal: 0,
        cocoaSelectionDiscountTotal: 0,
        otherQuantityDiscountTotal: 0,
        otherSelectionDiscountTotal: 0,
        brandingTableDiscountTotal: 0,
        brandingMenuDiscountTotal : 0,
        brandingPropertyDiscountTotal : 0,
        brandingDigitalDiscountTotal: 0,
        simRebateDiscountTotal : 0,
        simRefundDiscountTotal : 0,
        simGrowthDiscountTotal : 0,
        coffeeBaseDiscountTotal : 0,
        teaBaseDiscountTotal : 0,
        cocoaBaseDiscountTotal : 0,
        otherBaseDiscountTotal : 0,
        baseConditionDiscountTotal : 0,
        coffeeSurchargeMachine : 0,
        customerType: 'none', // CRM-1335: none, Kette, Einkaufsgesellschaft MUSS, Einkaufsgesellschaft KANN,
        isChainMember: false,
        isTopAccountCondition: false,
        hasOwnConfiguration : false,
        showAdditionalAgreements : false,
        additionalOfferTasting: false,
        additionalOfferFinancing: false,
        additionalOfferTraining: false,
        additionalFrameLease: false,
        additionalFrameLeaseText: this.label.additionalAgreementsFrameRichPrefill,
        additionalOther: false,
        additionalOtherText: null,
        additionalQualityVisit: false,
        additionalQualityVisitInterval: null,
        additionalQualityVisitInitial: null,
        additionalQualityVisitSettingRequested: false,
        tableware: false,
        coffeeRefundType: null,
        coffeeRefundLevel: 0,
        coffeeWkzRuntime: 0,
        coffeeWkzOneTimeAmount: 0,
        coffeeWkzOneTimeRefund: 0,
        coffeeWkzAnnualRefund: 0,
        teaRefundType: null,
        teaRefundLevel: 0,
        teaWkzRuntime: 0,
        teaWkzOneTimeAmount: 0,
        teaWkzOneTimeRefund: 0,
        teaWkzAnnualRefund: 0,
        indexCondition: 0,
        validFrom: new Date().toJSON().slice(0, 10)
    };
    
    MACHINE_BASE_PARAMS = {        
        offerValidUntil: new Date(Date.now() + 12096e5).toISOString().slice(0, 10),
        totalNetAmount: 0,
        totalNetAmountMachine: 0,
        totalNetAmountAccessories: 0,
        totalNetAmountNoDiscount: 0,
        totalNetAmountNoDiscountMachine: 0,
        totalNetAmountNoDiscountAccessories: 0,
        totalDiscount: 0,
        totalDiscountPercent: 0,
        totalProducerDiscount: 0,
        totalProducerDiscountPercent: 0,
        totalRoasterDiscount: 0,
        vatAmount: 0,
        totalGrossAmount: 0,
        adjustmentAmount: 0, // Aufschlag
        adjustmentAmountDisplay: 0.00, // Aufschlag
        downpaymentPercent: 0,
        downpaymentAmount: 0,
        downpaymentVatAmount: 0,
        financingAmount: 0,
        runtimeInMonths: 0,
        monthlyRateAmount: 0,
        totalNetAmountDisplay : 0.00,
        totalNetAmountMachineDisplay : 0.00,
        totalNetAmountAccessoriesDisplay : 0.00,
        totalNetAmountNoDiscountDisplay : 0.00,
        totalNetAmountNoDiscountMachineDisplay : 0.00,
        totalNetAmountNoDiscountAccessoriesDisplay : 0.00,
        totalDiscountDisplay : 0.00,
        totalGrossAmountDisplay : 0.00,
        totalDiscountPercentDisplay : 0.00,
        financingAmountDisplay: 0.00,
        monthlyRateAmountDisplay: 0.00,
        vatAmountDisplay : 0.00,
        downpaymentAmountDisplay: 0.00,
        downpaymentVatAmountDisplay : 0.00,
        discountViolationReason: null,
        downPaymentViolationReason: null,
        discountViolationCampaign: null,
        hasAccessoireDiscountViolation: false
    }
    BASE_MACHINE = {
        title: null,
        id: null,
        description: null,
        price: 0,
        specialMachinePrice: 0,
        priceDisplay: 0.00,
        icon: null,
        productSeries: null,
        brandId: null,
        subtitle: null,
        sObjectType: null,
        discountable: false,
        quantity: 1,
        discount: 0,
        discountAmount: 0,
        specialDiscount: 0,
        salePrice: 0,
        rowTotal: 0,
        rowTotalAllDiscount: null,
        discountAmountDisplay: 0.00,
        salePriceDisplay: 0.00,
        rowTotalDisplay: 0.00,
        maxDiscountOne: null,
        hasMaxDiscountOne: false,
        hasMaxDiscountOneViolation: false,
        maxDiscountOneString: null,
        maxDiscountTwo: null,
        hasMaxDiscountTwo: false,
        hasMaxDiscountTwoViolation: false,
        maxDiscountTwoString: false,
        secondDiscountPossible: false,
        discountCorrespondsToBaseDevice: false,
        hasAccessoires: false,
        accessoires: [],
        accessoiresPre: {},
        components: [],
        index: null
    };
    INITIAL_EQUIPMENT_DATA = [{
        rownumber: 1,
        product: '',
        previewPrice: 0,
        previewPriceDisplay: 0,
        quantity: 1,
        sum: 0,
        sumDisplay: 0,
        markForInitialOrder: this.label.no,
        teaDiscount: 0,
        teaDiscountPercent: 0,
        productGroup: '',
        productSubgroup: '',
        productName: '',
        isSubgroup: false,
        showTeaColumn: false
    }];

    INITIAL_NUMTYPES = {
        'coffeeInherit' : {
            label: 'Röstkaffee',
            selection: null,
            selectionDisplay: 0,
            quantities: null,
            quantitiesDisplay: 0
        },
        'teaInherit' : {
            label: 'Tee',
            selection: null,
            selectionDisplay: 0,
            quantities: null,
            quantitiesDisplay: 0
        },
        'cocoaInherit' : {
            label: 'Trinkschokolade',
            selection: null,
            selectionDisplay: 0,
            quantities: null,
            quantitiesDisplay: 0
        },
        'otherInherit' : {
            label: 'Sonstige Waren',
            selection: null,
            selectionDisplay: 0,
            quantities: null,
            quantitiesDisplay: 0
        },
        'coffee' : {
            label: 'Röstkaffee',
            selection: 0,
            selected: 0,
            quantities: 0
        },
        'tea' : {
            label: 'Tee',
            selection: 0,
            selected: 0,
            quantities: 0
        },
        'cocoa' : {
            label: 'Trinkschokolade',
            selection: 0,
            selected: 0,
            quantities: 0
        },
        'other' : {
            label: 'Sonstige Waren',
            selection: 0,
            selected: 0,
            quantities: 0
        },
    };

    EMPTY_CONDITION_DATA = {
        rownumber: 1,
        individualCondition: true,
        producttype: this.label.product,
        product: '',
        productName: '',
        productGroup: '',
        productSubgroup: '',
        basePrice: 0,
        basePricePre: 0,
        rebate: 0,
        offerPrice: 0,
        simulationPrice: 0,
        basePriceDisplay: 0,
        rebateDisplay: 0,
        offerPriceDisplay: 0,
        simulationPriceDisplay: 0,
        specialRebate: 0,
        specialRebatePercent: 0,
        refundAmount: 0,
        refundPercent: 0,
        totalAddition : 0,
        warningLevel : 0,
        freeFromSurcharge : false,
        lowestConditionSalesAreaManager : 0,
        lowestConditionSalesManager : 0,
        minimumPrice : 0,
        coffeeKgCharge: 0,
        coffeeQuantityDiscount: 0,
        coffeeSelectionDiscount: 0,
        teaQuantityDiscount: 0,
        teaSelectionDiscount: 0,
        cocoaQuantityDiscount: 0,
        cocoaSelectionDiscount: 0,
        otherQuantityDiscount: 0,
        otherSelectionDiscount: 0,
        brandingTableDiscount : 0,
        brandingMenuDiscount : 0,
        brandingPropertyDiscount : 0,
        brandingDigitalDiscount: 0,
        simRebateDiscount : 0,
        simRefundDiscount : 0,
        simGrowthDiscount : 0,
        coffeeBaseDiscount : 0,
        teaBaseDiscount : 0,
        cocoaBaseDiscount : 0,
        otherBaseDiscount : 0,
        baseConditionDiscount : 0,
        productBasedDiscount : 0,
        individualCondition: true
    };

    @track numTypes = JSON.parse(JSON.stringify(this.INITIAL_NUMTYPES));
    @track initialEquipmentData = JSON.parse(JSON.stringify(this.INITIAL_EQUIPMENT_DATA));
    @track storedInitialEquipmentData = JSON.parse(JSON.stringify(this.INITIAL_EQUIPMENT_DATA));
    @track emptyConditionProductData = JSON.parse(JSON.stringify(this.EMPTY_CONDITION_DATA));
    @track params = JSON.parse(JSON.stringify(this.PARAMS));
    @track machineParams = JSON.parse(JSON.stringify(this.MACHINE_BASE_PARAMS));
    @track machines = [JSON.parse(JSON.stringify(this.BASE_MACHINE))];
    @track specialMachines = [JSON.parse(JSON.stringify(this.BASE_MACHINE))];
    @track displayErrors = JSON.parse(JSON.stringify(this.DISPLAY_ERRORS));

    // Options
    intervalOptions = [
        {label: this.label.none, value: '0', selected: true},
        {label: '1x', value:  '1x', selected: true},
        {label: '2x', value:  '2x', selected: true},
        {label: '3x', value:  '3x', selected: true},
        {label: '4x', value:  '4x', selected: true},
        {label: '5x', value:  '5x', selected: true},
        {label: '6x', value:  '6x', selected: true},
    ]
    discountOptions = [
        {label: this.label.none, value: '0', selected: true},
        {label: this.label.discountBank, value: this.label.discountBankEN, selected: false},
        {label: this.label.discount0To10, value: this.label.discount0To10EN, selected: false},
        {label: this.label.discount10plus, value: this.label.discount10plusEN, selected: false}
    ]
    itemOptions = [
        {label: this.label.allItems, value: this.label.allItems, selected: true},
        {label: this.label.individual, value: this.label.individual, selected: false}
    ]
    yesNoOptions = [
        {label: this.label.yes, value: this.label.yes, selected: false},
        {label: this.label.no, value: this.label.no, selected: true}
    ]
    simRevOptions = [
        {label: this.label.none, value: '0', selected: true},
        {label: this.label.simRev2000, value: '1999', selected: false},
        {label: this.label.simRev10000below, value: '9999', selected: false},
        {label: this.label.simRev10000above, value: '10000', selected: false}
    ]
    growthOptions = [
        {label: this.label.none, value:  '0', selected: true},
        {label: this.label.growth0, value: '1', selected: false},
        {label: this.label.growth5, value: '5', selected: false},
        {label: this.label.growth10, value: '10', selected: false},
        {label: this.label.growth15, value: '15', selected: false}
    ]
    coffeeTypeOptions = [
        {label: this.label.none, value: '', selected: true},
        {label: this.label.revenue, value: this.label.revenue, selected: false},
        {label: this.label.purchase, value: this.label.purchase, selected: false}
    ]
    teaTypeOptions = [
        {label: this.label.none, value: '', selected: true},
        {label: this.label.revenue, value: this.label.revenue, selected: false}
    ]

    // Adapters
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        loadStyle(this, custommodalcss);
        this.isLoading = true;
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            getStandardPricebookEntries({recordId: this.recordId})
            .then(outerResult => {
                this.standardPricebookEntries = outerResult;
                getAuxiliaryTables({type: this.label.initialEquipment})
                .then(midResult => {
                    this.auxiliaryTables = midResult;
                    if(this.recordId.startsWith('006')){
                        this.opportunityId = this.recordId;
                        this.isQuoteContext = false;
                        this.oppLoaded = true;
                        checkIfNewCustomer({opportunityId: this.opportunityId})
                        .then(result => {
                            console.log('result: ' + JSON.stringify(result));
                            this.handlePrefill(result);
                        })
                    } else {
                        this.quoteId = this.recordId;
                        this.isQuoteContext = true;
                        preloadQuoteData({quoteId: this.quoteId})
                        .then(outerResult => {
                            if(outerResult != null){
                                this.handlePrefillQuote(outerResult);
                            }
                        });
                    }
                });
            })
        }
    }


    handleSwitchToFirstTab(){
        this.firstTabStyle = '';
        this.secondTabStyle = 'height: 0px; opacity: 0; z-index: -1; position: relative;';
        this.isFirstTab = true;
        this.isSecondTab = false;
    }

    handleSwitchToSecondTab(){
        this.secondTabStyle = '';
        this.firstTabStyle = 'height: 0px; opacity: 0; z-index: -1; position: relative;';
        this.isFirstTab = false;
        this.isSecondTab = true;
    }

    handlePrefillQuote(outerResult){
        this.opportunityId = outerResult.OpportunityId;
        this.oppLoaded = true;
        checkIfNewCustomerLite({opportunityId: this.opportunityId})
        .then(innerResult => {
            let result = outerResult.quote;
            // Basics
            this.newCustomer = innerResult.newCustomer;
            this.params.customerType = innerResult.customerType;
            this.industry = innerResult.industry;
            this.hasIndexConditionFromParams = false;
            this.params.isChainMember = innerResult.isChainMember; 
            this.params.isTopAccountCondition = innerResult.isTopAccountCondition;
            // Populate from Resulting Quote record - revert PriceConfiguratorController.createOffer(...)
            this.quoteIsDraft = result.Status == 'Draft';
            this.params.indexCondition = result.DiscountIndexCondition__c;
            this.indexConditionPreset = stringIsNotBlank(this.params.indexCondition) && this.params.indexCondition != 0 ? this.label.yes : this.label.no;
            this.showSimulation = result.Simulation__c;
            this.showRefund = result.Refund__c;
            this.params.runtimeMonths = result.Lifetime__c ?? 0;
            this.machineParams.runtimeInMonths = result.Lifetime__c ?? 0;
            this.params.showAdditionalAgreements = result.AdditionalAgreements__c;
            this.params.tableware = result.DishSales__c;
            this.params.validFrom = result.ValidFrom__c ?? new Date().toJSON().slice(0, 10);

            // Parameters
            if(
                result.PurchaseQuantityCoffeeStatistical__c != null ||
                result.PurchaseQuantityTeaStatistical__c != null ||
                result.PurchaseQuantityHotChocStatistical__c != null ||
                result.PurchaseQuantityOtherStatistical__c != null ||
                result.PurchaseQuantityCoffee__c != null ||
                result.PurchaseQuantityTea__c != null ||
                result.PurchaseQuantityHotChoc__c != null ||
                result.PurchaseQuantityOther__c != null ||
                result.NrOfDifferentCoffeePreps__c != null ||
                result.NrOfDifferentTeaProducts__c != null ||
                result.NrOfDifferentHotChocProducts__c != null ||
                result.NrOfDifferentOtherProducts__c != null
            ){
                this.numTypes.coffee.quantities = (result.PurchaseQuantityCoffeeStatistical__c ?? result.PurchaseQuantityCoffee__c) ?? 0;
                this.numTypes.tea.quantities = (result.PurchaseQuantityTeaStatistical__c ?? result.PurchaseQuantityTea__c) ?? 0;
                this.numTypes.cocoa.quantities = (result.PurchaseQuantityHotChocStatistical__c ?? result.PurchaseQuantityHotChoc__c) ?? 0;
                this.numTypes.other.quantities = (result.PurchaseQuantityOtherStatistical__c ?? result.PurchaseQuantityOther__c) ?? 0;
                this.numTypes.coffee.selection = result.NrOfDifferentCoffeePreps__c ?? 0;
                this.numTypes.tea.selection = result.NrOfDifferentTeaProducts__c ?? 0;
                this.numTypes.cocoa.selection = result.NrOfDifferentHotChocProducts__c ?? 0;
                this.numTypes.other.selection = result.NrOfDifferentOtherProducts__c ?? 0;
            } else if(innerResult.preloadChild != null){
                this.numTypes.coffee.quantities = innerResult.preloadChild.VolumeRoastCoffeeQty__c ?? 0;
                this.numTypes.tea.quantities = innerResult.preloadChild.VolumeCocoaQty__c ?? 0;
                this.numTypes.cocoa.quantities = innerResult.preloadChild.VolumeTeaQty__c ?? 0;
                this.numTypes.other.quantities = innerResult.preloadChild.VolumeOtherQty__c ?? 0;
                this.numTypes.coffee.selection = innerResult.preloadChild.AssortmentRoastCoffeeCount__c ?? 0;
                this.numTypes.tea.selection = innerResult.preloadChild.AssortmentTeaCount__c ?? 0;
                this.numTypes.cocoa.selection = innerResult.preloadChild.AssortmentCocoaCount__c ?? 0;
                this.numTypes.other.selection = innerResult.preloadChild.AssortmentOtherCount__c ?? 0;
            }
            
            if(innerResult.preloadParent != null){
                this.numTypes.coffeeInherit.quantities = innerResult.preloadParent.VolumeRoastCoffeeQty__c ?? 0;
                this.numTypes.teaInherit.quantities = innerResult.preloadParent.VolumeCocoaQty__c ?? 0;
                this.numTypes.cocoaInherit.quantities = innerResult.preloadParent.VolumeTeaQty__c ?? 0;
                this.numTypes.otherInherit.quantities = innerResult.preloadParent.VolumeOtherQty__c ?? 0;
                this.numTypes.coffeeInherit.selection = innerResult.preloadParent.AssortmentRoastCoffeeCount__c ?? 0;
                this.numTypes.teaInherit.selection = innerResult.preloadParent.AssortmentTeaCount__c ?? 0;
                this.numTypes.cocoaInherit.selection = innerResult.preloadParent.AssortmentCocoaCount__c ?? 0;
                this.numTypes.otherInherit.selection = innerResult.preloadParent.AssortmentOtherCount__c ?? 0;
                this.numTypes.coffeeInherit.quantitiesDisplay = this.numTypes.coffeeInherit.quantities != null ? this.numTypes.coffeeInherit.quantities.toFixed(2) : 0; 
                this.numTypes.teaInherit.quantitiesDisplay = this.numTypes.teaInherit.quantities != null ? this.numTypes.teaInherit.quantities.toFixed(2) : 0;
                this.numTypes.cocoaInherit.quantitiesDisplay = this.numTypes.cocoaInherit.quantities != null ? this.numTypes.cocoaInherit.quantities.toFixed(2) : 0;
                this.numTypes.otherInherit.quantitiesDisplay = this.numTypes.otherInherit.quantities != null ? this.numTypes.otherInherit.quantities.toFixed(2) : 0;
                this.numTypes.coffeeInherit.selectionDisplay = this.numTypes.coffeeInherit.selection != null ? this.numTypes.coffeeInherit.selection.toFixed(0) : 0;
                this.numTypes.teaInherit.selectionDisplay = this.numTypes.teaInherit.selection != null ? this.numTypes.teaInherit.selection.toFixed(0) : 0;
                this.numTypes.cocoaInherit.selectionDisplay = this.numTypes.cocoaInherit.selection != null ? this.numTypes.cocoaInherit.selection.toFixed(0) : 0;
                this.numTypes.otherInherit.selectionDisplay = this.numTypes.otherInherit.selection != null ? this.numTypes.otherInherit.selection.toFixed(0) : 0;
            }

            this.params.hasOfferOnTable = result.BrandDisplayTable__c ? this.label.yes : this.label.no;
            this.params.hasOfferInProperty = result.BrandDisplayLocation__c ? this.label.yes : this.label.no;
            this.params.hasMenuLogo = result.BrandDisplayMenu__c ? this.label.yes : this.label.no;
            this.params.hasDigitalRequired = result.DigitalWayOfOrdering__c ? this.label.yes : this.label.no;
            this.params.discount = result.SimulatedDiscount__c ?? '0';            
            this.params.simRebateDiscountTotal = (stringIsNotBlank(this.params.discount) && Object.keys(this.auxiliaryTables).includes('discount') && Object.keys(this.auxiliaryTables.discount).includes(this.params.discount) ?  this.auxiliaryTables.discount[this.params.discount] : 0);


            // Additional Agreements
            if(this.params.showAdditionalAgreements){
                this.activeSections.push('AdditionalAgreements');
                //this.params.additionalOfferTasting = result.OfferTasting__c;
                //this.params.additionalOfferFinancing = result.OfferFinancing__c;
                //this.params.additionalOfferTraining = result.OfferTraining__c;
                //this.params.additionalFrameLease = result.Leihgestellung_angeboten__c;
                this.params.additionalOther = result.OtherAdditionalAggreeementsSpecified__c;
                //this.params.additionalFrameLeaseText = result.Leihgestellung_Details__c;
                this.params.additionalOtherText = result.OtherAdditionalAggreeementsDetails__c;
                this.params.additionalQualityVisit = result.QualityCheck__c;
                this.params.additionalQualityVisitInterval = result.Interval__c;
                this.params.additionalQualityVisitInitial = result.InitialReview__c;
                this.params.additionalQualityVisitSettingRequested = result.ProfessionalSetupRequested__c;
            }

            // Condition Products 
            this.conditionProductData = [];
            let rownumberCondition = 1;
            if(result.QuoteLineItems && result.QuoteLineItems != null){
                result.QuoteLineItems.forEach(element => {
                    if(element.IsSubgroup__c || Object.keys(this.standardPricebookEntries).includes(element.Product2Id)){
                        let conditionObj = {};
                        conditionObj.rownumber = rownumberCondition;
                        conditionObj.product = element.Product2Id;
                        conditionObj.producttype = element.IsSubgroup__c ? this.label.subgroup : this.label.product;
                        conditionObj.productName = stringIsNotBlank(element.Product2.QuoteName__c) ? element.Product2.QuoteName__c : element.Product2.Name;
                        conditionObj.specialRebate = element.SpecialDiscount__c ?? 0;
                        conditionObj.specialRebatePercent = element.SpecialDiscountInPercent__c ?? 0;
                        //conditionObj.refundPercent = element.R_ckverg_tung_Rabatt_in__c ?? 0;
                        //conditionObj.refundAmount = element.R_ckverg_tung_Rabatt_in_Euro__c ?? 0;
                        conditionObj.productGroup = element.ProductGroup__c;
                        conditionObj.productSubgroup = element.ProductSubgroup__c;
                        //conditionObj.totalAddition = element.Aufschlag_Gesamt_alt__c ?? 0;
                        conditionObj.lowestConditionSalesAreaManager = element.Product2.LowestConditionForSalesAreaManager__c ?? 0;
                        conditionObj.lowestConditionSalesManager = element.Product2.LowestConditionForSalesManager__c ?? 0;
                        //conditionObj.minimumPrice = element.Product2.Minimum_Price__c ?? 0;
                        conditionObj.freeFromSurcharge = element.Product2.ExemptFromSurcharges__c;
                        conditionObj.individualCondition = element.IndividualCondition__c;
                        if(!element.IsSubgroup__c){
                            let unitPrice = this.standardPricebookEntries[element.Product2Id];
                            conditionObj.basePricePre = unitPrice;
                        } else {
                            if(Object.keys(this.standardPricebookEntries).includes(element.Product2Id) && parseFloat(this.standardPricebookEntries[element.Product2Id]) > 0){
                                let unitPrice = this.standardPricebookEntries[element.Product2Id];
                                conditionObj.basePricePre = unitPrice;
                                conditionObj.subgroupHasPrice = true;
                            } else {
                                conditionObj.subgroupHasPrice = false;
                            }
                        }
                        this.conditionProductData.push(conditionObj);
                        rownumberCondition++;
                    }
                });
                if(!this.isMuss){
                    this.emptyConditionProductData.rownumber = this.conditionProductData.length + 1;
                    this.conditionProductData.push(this.emptyConditionProductData);
                    this.maxConditionNumber = this.conditionProductData.length + 2;
                }
            }

            // Initial Equipment
            this.initialEquipmentData = [];
            /*let rownumber = 1;
            if(result.Erstausstattungen__r && result.Erstausstattungen__r != null){
                result.Erstausstattungen__r.forEach(initialEquipment => {
                    let equipmentObj = {};
                    equipmentObj.rownumber = rownumber;
                    equipmentObj.product = initialEquipment.Produkt__c;
                    equipmentObj.productName = stringIsNotBlank(initialEquipment.Produkt__r.QuoteName__c) ? initialEquipment.Produkt__r.QuoteName__c : initialEquipment.Produkt__r.Name;
                    equipmentObj.previewPrice = initialEquipment.Produkt__r.PreviewPrice__c ?? 0;
                    equipmentObj.quantity = initialEquipment.Menge__c;
                    equipmentObj.sum = (equipmentObj.previewPrice ?? 0) * (equipmentObj.quantity ?? 0);
                    equipmentObj.teaDiscount = initialEquipment.GrantedTeaDiscount__c;
                    equipmentObj.markForInitialOrder = initialEquipment.F_r_Erstbestellung_markiert__c ? this.label.yes : this.label.no;
                    this.initialEquipmentData.push(equipmentObj);
                    rownumber++;
                })
            }
            if(this.showInitialEquipment){
                this.activeSections.push('Simulation');
            }*/
            this.showInitialEquipment =  this.initialEquipmentData.length > 0;
            let initialEquipmentData = JSON.parse(JSON.stringify(this.INITIAL_EQUIPMENT_DATA[0]));
            initialEquipmentData.rownumber = this.rownumber;
            this.initialEquipmentData.push(initialEquipmentData);
            this.maxInitialNumber = this.initialEquipmentData.length + 1;

            // Machine Configurator
            /*if(this.machineLeasingEnabled){
                if(stringIsNotBlank(result.LinkedMachineOffer__c)){
                    if(this.quoteIsDraft){
                        this.machineOfferToEdit = result.LinkedMachineOffer__c;
                    }
                    // Prefill data of machine configurator 
                    this.machineSurchargeCalculation = result.Verlinktes_Maschinenangebot__r.Maschine_Aufschlagsberechnung__c;
                    // Populate machine params
                    this.params.coffeeWkzRuntime = result.Verlinktes_Maschinenangebot__r.Maschine_Laufzeit_in_Monaten__c;
                    this.machineParams.runtimeInMonths = result.Verlinktes_Maschinenangebot__r.Maschine_Laufzeit_in_Monaten__c ?? 0;
                    this.machineParams.downpaymentPercent = result.Verlinktes_Maschinenangebot__r.Maschine_AnzahlungInPercentMaschine__c ?? 0;
                    // Populate machine and accessories
                    this.machines = [];
                    this.specialMachines = [];
                    let accessoires = {};
                    if(result.Verlinktes_Maschinenangebot__r.QuoteLineItems && result.Verlinktes_Maschinenangebot__r.QuoteLineItems != null){
                        //this.machine.x = y;
                        result.Verlinktes_Maschinenangebot__r.QuoteLineItems.forEach(element => {
                            let machine = {};
                            if(Object.keys(this.standardPricebookEntries).includes(element.Product2Id)){
                                if(element.MachineType__c == 'Machine'){
                                    machine.sObjectType = 'Product2';
                                    machine.icon = 'standard:product';
                                    machine.id = element.Product2Id;
                                    machine.title = element.Product2.Name;
                                    machine.discountable = !element.Product2.NotDiscountable__c;
                                    machine.description = element.Product2.Description__c;
                                    machine.subtitle = element.Product2.BrandWebshop__r?.Name;
                                    machine.quantity = parseInt(element.Quantity ?? 0);
                                    machine.price = this.standardPricebookEntries[element.Product2Id];
                                    machine.rowTotal = parseFloat(element.Product2.CustomTotalPrice__c ?? 0);
                                    machine.discount = parseFloat(element.Discount_Regular__c ?? 0);
                                    machine.specialDiscount = parseFloat(element.Discount_Special__c ?? 0);
                                    machine.accessoires = [];
                                } else {
                                    let machineId = element.ParentMachine__c;
                                    if(stringIsNotBlank(machineId)){
                                        let accessoire = {};
                                        accessoire.sObjectType = 'Product2';
                                        accessoire.icon = 'standard:product';
                                        accessoire.id = element.Product2Id;
                                        accessoire.title = element.Product2.Name;
                                        accessoire.discountable = !element.Product2.NotDiscountable__c;
                                        accessoire.description = element.Product2.Description__c;
                                        accessoire.subtitle = element.Product2.BrandWebshop__r?.Name;
                                        accessoire.quantity = parseInt(element.Quantity ?? 0);
                                        accessoire.price = this.standardPricebookEntries[element.Product2Id];
                                        accessoire.rowTotal = parseFloat(element.Product2.CustomTotalPrice__c ?? 0);
                                        accessoire.discount = parseFloat(element.Discount_Regular__c ?? 0);
                                        accessoire.specialDiscount = parseFloat(element.Discount_Special__c ?? 0);
                                        let innerList = Object.keys(accessoires).includes(machineId) ? accessoires[machineId] : [];
                                        innerList.push(accessoire);
                                        accessoires[machineId] = innerList;
                                    }
                                }
                            }
                        });
                        this.machines.forEach(machine => {
                            if(Object.keys(accessoires).includes(machine.id)){
                                machine.accessoires = accessoires[machine.id];
                            }
                        })
                    } else {
                        this.machines = [JSON.parse(JSON.stringify(this.BASE_MACHINE))];
                    }
                    // Prefill step of machine configurator
                    this.machineConfiguratorStep = 4;
                    this.showMachineConfigurator = true;
                    this.machineConfiguratorFinalized = true;
                    this.handleMachineConfiguratorNumTypeChange();
                }
            }*/
            this.resetChildrenExistingIds();
            this.inheritToChildren();
        })
    }

    handlePrefill(result){
        // Preload
        this.newCustomer = result.resultNo;
        this.industry = result.industry;
        this.indexConditionFromParams = result.indexDiscount ?? 0;
        this.params.indexCondition = this.indexConditionFromParams;
        this.hasIndexConditionFromParams = this.indexConditionFromParams != 0;
        this.params.customerType = result.customerType;
        if(this.params.customerType != 'none'){
            this.indexConditionPreset = this.hasIndexConditionFromParams ? this.label.yes : this.label.no;
        }
        this.params.hasOwnConfiguration = result.hasOwnConfiguration;
        this.params.isChainMember = result.isChainMember;
        this.params.isTopAccountCondition = result.isTopAccountCondition;
        this.numTypes.coffee.quantities = result.preloadQuantities.Röstkaffee ?? 0;
        this.numTypes.tea.quantities = result.preloadQuantities.Tee ?? 0;
        this.numTypes.cocoa.quantities = result.preloadQuantities.Trinkschokolade ?? 0;
        this.numTypes.other.quantities = result.preloadQuantities.Sonstiges ?? 0;
        this.numTypes.coffee.selection = result.preloadNum.Röstkaffee ?? 0;
        this.numTypes.tea.selection = result.preloadNum.Tee ?? 0;
        this.numTypes.cocoa.selection = result.preloadNum.Trinkschokolade ?? 0;
        this.numTypes.other.selection = result.preloadNum.Sonstiges ?? 0;
        
        this.numTypes.coffeeInherit.quantities = result.preloadQuantitiesInherit.Röstkaffee;
        this.numTypes.coffeeInherit.quantitiesDisplay = this.numTypes.coffeeInherit.quantities != null ? this.numTypes.coffeeInherit.quantities.toFixed(2) : 0;  
        this.numTypes.teaInherit.quantities = result.preloadQuantitiesInherit.Tee;
        this.numTypes.teaInherit.quantitiesDisplay = this.numTypes.teaInherit.quantities != null ? this.numTypes.teaInherit.quantities.toFixed(2) : 0;
        this.numTypes.cocoaInherit.quantities = result.preloadQuantitiesInherit.Trinkschokolade;
        this.numTypes.cocoaInherit.quantitiesDisplay = this.numTypes.cocoaInherit.quantities != null ? this.numTypes.cocoaInherit.quantities.toFixed(2) : 0;
        this.numTypes.otherInherit.quantities = result.preloadQuantitiesInherit.Sonstiges;
        this.numTypes.otherInherit.quantitiesDisplay = this.numTypes.otherInherit.quantities != null ? this.numTypes.otherInherit.quantities.toFixed(2) : 0;
        this.numTypes.coffeeInherit.selection = result.preloadNumInherit.Röstkaffee;
        this.numTypes.coffeeInherit.selectionDisplay = this.numTypes.coffeeInherit.selection != null ? this.numTypes.coffeeInherit.selection.toFixed(2) : 0;
        this.numTypes.teaInherit.selection = result.preloadNumInherit.Tee;
        this.numTypes.teaInherit.selectionDisplay = this.numTypes.teaInherit.selection != null ? this.numTypes.teaInherit.selection.toFixed(2) : 0;
        this.numTypes.cocoaInherit.selection = result.preloadNumInherit.Trinkschokolade;
        this.numTypes.cocoaInherit.selectionDisplay = this.numTypes.cocoaInherit.selection != null ? this.numTypes.cocoaInherit.selection.toFixed(2) : 0;
        this.numTypes.otherInherit.selection = result.preloadNumInherit.Sonstiges;
        this.numTypes.otherInherit.selectionDisplay = this.numTypes.otherInherit.selection != null ? this.numTypes.otherInherit.selection.toFixed(2) : 0;

        this.params.hasOfferOnTable = result.preloadBool.offerOnTable;
        this.params.hasMenuLogo = result.preloadBool.menuLogo;
        this.params.hasOfferInProperty = result.preloadBool.offerInProperty;
        this.params.hasDigitalRequired = result.preloadBool.digitalRequired;
        // CRM-1377
        this.params.discount = result.preloadSimulation.skonto;            
        this.params.simRebateDiscountTotal = (stringIsNotBlank(this.params.discount) && Object.keys(this.auxiliaryTables).includes('discount') && Object.keys(this.auxiliaryTables.discount).includes(this.params.discount) ?  this.auxiliaryTables.discount[this.params.discount] : 0);
        this.params.growthPercent = result.preloadSimulation.growthPercent;
        this.params.simulatedRevenue = result.preloadSimulation.growthRevenue;
        this.params.simGrowthDiscountTotal = 
            stringIsNotBlank(this.params.simulatedRevenue) && stringIsNotBlank(this.params.growthPercent) && Object.keys(this.auxiliaryTables).includes('simulationAndGrowth') && Object.keys(this.auxiliaryTables.simulationAndGrowth).includes(this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()) ? 
            this.auxiliaryTables.simulationAndGrowth[this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()] :
            0;
        this.params.showAdditionalAgreements = result.preloadAgreementsBool.load;
        if(this.params.showAdditionalAgreements){
            this.activeSections.push('AdditionalAgreements');
        }
        this.params.additionalFrameLease = result.preloadAgreementsBool.frame;
        this.params.additionalOfferTasting = result.preloadAgreementsBool.tasting;
        this.params.additionalOfferFinancing = result.preloadAgreementsBool.financing;
        this.params.additionalOfferTraining = result.preloadAgreementsBool.training;
        this.params.additionalOther = result.preloadAgreementsBool.other;
        this.params.additionalQualityVisit = result.preloadAgreementsBool.quality;
        if(this.params.additionalFrameLease == true){
            this.params.additionalFrameLeaseText = result.preloadAgreements.frame;
        }
        if(this.params.additionalOther == true){
            this.params.additionalOtherText = result.preloadAgreements.other;
        }
        if(this.params.additionalQualityVisit == true){
            this.params.additionalQualityVisitSettingRequested = result.preloadAgreementsBool.qualitySetting;
            this.params.additionalQualityVisitInterval = result.preloadAgreements.qualityInterval;
            this.params.additionalQualityVisitInitial = result.preloadAgreements.qualityInitial;
        }

        let preloadProducts = JSON.parse(JSON.stringify(result.conditionProductDataPre));
        this.conditionProductData = [];
        preloadProducts.forEach(element => {
            if(element.producttype != this.label.subgroup){
                if(Object.keys(this.standardPricebookEntries).includes(element.product)){
                    let unitPrice = this.standardPricebookEntries[element.product];
                    element.basePricePre = unitPrice;
                    element.offerPrice = unitPrice - element.specialRebate;
                    this.conditionProductData.push(element);
                } 
            } else {
                if(Object.keys(this.standardPricebookEntries).includes(element.product) && parseFloat(this.standardPricebookEntries[element.product]) > 0){
                    let unitPrice = this.standardPricebookEntries[element.product];
                    element.basePricePre = unitPrice;
                    element.offerPrice = unitPrice - element.specialRebate;
                    element.subgroupHasPrice = true;
                    this.conditionProductData.push(element);
                } else {
                    element.subgroupHasPrice = false;
                    this.conditionProductData.push(element);
                }
            }
        });
        this.emptyConditionProductData.rownumber = preloadProducts.length + 1;
        this.maxConditionNumber = preloadProducts.length + 2;
        if(!this.isMuss){
            this.conditionProductData.push(this.emptyConditionProductData);
        }
        this.resetChildrenExistingIds();
        this.inheritToChildren();
        this.calcMaxDiscounts();
    }

    @wire(getRecord, { recordId: "$recordId", fields: [CLOSED_FIELD] })
    opportunity;

    // Lifecycle and Inbound Handlers
    disconnectedCallback(){
        loadScript(this, removeStyle);
    }
    inheritToChildren(){
        this.calcMaxWarning();
        this.calcMaxDiscounts();
        this.calcNumTypesDiscrepancyWarnings();
        getSubgroupCount({standardPricebookEntriesIds: Object.keys(this.standardPricebookEntries), recordId: self.recordId})
        .then(midResult => {
            this.subgroupCount = JSON.parse(JSON.stringify(midResult));
            this.isLoaded = true;
            this.isLoading = false;
            this.typeLoaded = true;
            this.inheritInitialParams();
            this.inheritParams(1);
        })
    }
    handleRejectIndexConditionFromParams(event){
        this.hasIndexConditionFromParams = false;
        this.showIndexConditionSecondWarning = true;
        this.indexConditionPreset = this.label.yes;
        this.params.indexCondition = this.indexConditionFromParams;
        this.inheritParams(2);
    }
    handleAcceptIndexConditionFromParams(event){
        this.hasIndexConditionFromParams = false;
        this.showIndexConditionSecondWarning = true;
        this.indexConditionPreset = null;
        this.params.indexCondition = null;
        this.inheritParams(3);
    }
    handleConfirmMachines(event){
        this.machines = event.detail.machines;
        this.specialMachines = event.detail.specialMachines;
        this.machineParams = event.detail.params;
        this.machineSurchargeCalculation = event.detail.surchargeCalculation;
        this.machineConfiguratorFinalized = true;
        this.params.coffeeSurchargeMachine = this.machineSurchargeCalculation == true ? this.machineParams.adjustmentAmount : 0;
        this.inheritParams(4);
    }
    handleConditionProductDelete(event){
        this.pristine = false;
        let rownumber = event.detail;
        this.conditionProductData.forEach(row => {
            if(row.rownumber == rownumber){
                let index = this.conditionProductData.indexOf(row);
                if (index > -1) { 
                    this.conditionProductData.splice(index, 1); 
                }
            }
        });
        this.calcMaxWarning();
        this.calcMaxDiscounts();
        this.calcNumTypesDiscrepancyWarnings();
        this.resetChildrenExistingIds();
        this.inheritParams(5);
    }
    
    handlePromoteToIndividual(event){
        this.pristine = false;
        const updatedRow = event.detail;
        if (!updatedRow || updatedRow.rownumber == null) return;
        this.conditionProductData.forEach(row => {
            if(row.rownumber === updatedRow.rownumber){
                const index = this.conditionProductData.indexOf(row);
                // Welle 2.9.7: Snapshot der Inherited-Werte vor dem Promote.
                // Wird vom Trash-Handler genutzt um die Row zurueckzusetzen
                // (nicht komplett zu loeschen) wenn der User es sich anders
                // ueberlegt — damit die Cascade vom Parent weiterhin greift.
                const enriched = Object.assign({}, updatedRow, {
                    _wasInherited: true,
                    _inheritedSnapshot: {
                        specialRebate: row.specialRebate,
                        specialRebatePercent: row.specialRebatePercent,
                        refundAmount: row.refundAmount,
                        refundPercent: row.refundPercent
                    }
                });
                this.conditionProductData[index] = enriched;
            }
        });
        this.calcMaxWarning();
        this.calcMaxDiscounts();
        this.calcNumTypesDiscrepancyWarnings();
    }

    handleConditionProductChange(event){
        this.pristine = false;
        let rownumber = event.detail.rownumber;
        this.conditionProductData.forEach(row => {
            if(row.rownumber == rownumber){
                let index = this.conditionProductData.indexOf(row);
                this.conditionProductData[index] = event.detail;
            }
        });
        this.calcMaxWarning();
        this.calcMaxDiscounts();
        this.calcNumTypesDiscrepancyWarnings();
        this.checkQuantitySelectionMismatch();
        this.resetChildrenExistingIds();
        let self = this;
        setTimeout(() => {
            self.template.querySelectorAll('c-price-configurator-condition-product-row').forEach(row => {
                row.existingRows = self.existingRows;
            })
        }, 250);
    }
    handleInitialEquipmentDelete(event){
        let rownumber = event.detail;
        let sumAmount = 0;
        this.initialEquipmentData.forEach(row => {
            if(row.rownumber == rownumber){
                let index = this.initialEquipmentData.indexOf(row);
                if (index > -1) { 
                    this.initialEquipmentData.splice(index, 1); 
                }
            } else {
                sumAmount += row.sum != null ? parseFloat(row.sum) : 0;
            }
        })
        this.totalValueInEuro = parseFloat(sumAmount.toFixed(2));
        this.recalcKgCharge();
        this.resetChildrenInitialExistingIds();
        this.inheritParams(7);
        this.inheritInitialParams();
    }
    handleInitialEquipmentChange(event){
        let rownumber = event.detail.rownumber;
        let sumAmount = 0;
        this.params.tableware = false;
        this.initialEquipmentData.forEach(row => {
            if(row.rownumber == rownumber){
                let index = this.initialEquipmentData.indexOf(row);
                this.initialEquipmentData[index] = event.detail;
                sumAmount += event.detail.sum != null ? parseFloat(event.detail.sum) : 0;
            } else {
                sumAmount += row.sum != null ? parseFloat(row.sum) : 0;
            }
            if(row.productSubgroup == 'Servierartikel für Kaffee' || row.productSubgroup == 'Servierartikel für Tee'){
                this.params.tableware = true;
            }
        });
        this.totalValueInEuro = parseFloat(sumAmount.toFixed(2));
        this.recalcKgCharge();
        this.recalcTeaDiscount();
        this.resetChildrenInitialExistingIds();
        
        let self = this;
        setTimeout(() => {
            self.template.querySelectorAll('c-price-configurator-condition-product-row').forEach(row => {
                row.params = self.params;
                row.existingRows = self.existingRows;
            })
        }, 250);
        setTimeout(() => {
            self.template.querySelectorAll('c-price-configurator-initial-equipment-row').forEach(row => {
                row.maxTeaDiscountViolated = self.params.maxTeaDiscountViolated;
                row.maxTeaDiscountValue = self.params.maxTeaDiscountValue;
                row.existingRowsInitial = self.existingRowsInitial;
            })
        }, 250);
    }

    // Component Handlers
    handleChangeValidFrom(event){
        this.params.validFrom = event.target.value;
    }
    handleChangeIndexConditionPre(event){
        this.indexConditionPreset = event.target.value;
        if(this.indexConditionPreset == this.label.no){
            this.params.indexCondition = 0;
        }
        this.inheritToChildren();
    }
    handleChangeIndexCondition(event){
        this.showIndexConditionSecondWarning = false;
        this.params.indexCondition = stringIsNotBlank(event.target.value) ? parseFloat(event.target.value) : 0;
        this.inheritToChildren();
    }
    handleChangeHasInitialEquipment(event){
        this.showInitialEquipment = event.target.checked;
        if(!this.showInitialEquipment){
            this.storedRuntime = this.params.runtimeMonths;
            this.params.runtimeMonths = 12;
            this.storedInitialEquipmentData = JSON.parse(JSON.stringify(this.initialEquipmentData));
            this.initialEquipmentData = [];
        } else {
            this.params.runtimeMonths = this.storedRuntime;
            this.initialEquipmentData = JSON.parse(JSON.stringify(this.storedInitialEquipmentData));
        }
        this.recalcKgCharge();
        this.inheritParams(8);
    }
    handleMachineConfiguratorNumTypeChange(){
        if(this.showMachineConfigurator == true){
            // Check Coffee Volume
            if(this.numTypes.coffee.quantities > 0 && this.numTypes.coffee.selection > 0){
                if(stringIsNotBlank(this.params.coffeeWkzRuntime)){
                    this.showMachineConfiguratorActual = true;
                    let self = this;
                    setTimeout(() => {
                        self.template.querySelectorAll('c-machine-configurator-inner').forEach(element => {
                            element.runtimeInMonths = this.params.coffeeWkzRuntime;
                        });
                    }, 250);
                }
            } else {
                this.showMachineConfiguratorWarning = true;
            }
        }
    }
    handleParamChange(event){
        let fieldName = event.target.dataset.fieldname;
        this.params[fieldName] = stringIsNotBlank(event.target.value) ? parseInt(event.target.value) : 0;
        if(fieldName == 'coffeeWkzRuntime'){
            this.handleMachineConfiguratorNumTypeChange();
        }
        this.inheritParams(9);
    }
    handleChangeTeaType(event){
        this.params.teaRefundType = event.target.value;
        this.inheritParams(10);
    }
    handleChangeCoffeeType(event){
        this.params.coffeeRefundType = event.target.value;
        this.inheritParams(11);
    }
    handleChangeRuntimeMonths(event){
        this.params.runtimeMonths = parseInt(event.target.value);
        this.recalcKgCharge();
        this.inheritParams(12);
    }
    handleChangeSimulatedRevenue(event){
        this.params.simulatedRevenue = event.target.value;
        this.params.simGrowthDiscountTotal = 
            stringIsNotBlank(this.params.simulatedRevenue) && stringIsNotBlank(this.params.growthPercent) && Object.keys(this.auxiliaryTables).includes('simulationAndGrowth') && Object.keys(this.auxiliaryTables.simulationAndGrowth).includes(this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()) ? 
            this.auxiliaryTables.simulationAndGrowth[this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()] :
            0;
        this.inheritParams(13);
    }
    handleChangeGrowthPercent(event){
        this.params.growthPercent = event.target.value;
        this.params.simGrowthDiscountTotal = 
            stringIsNotBlank(this.params.simulatedRevenue) && stringIsNotBlank(this.params.growthPercent) && Object.keys(this.auxiliaryTables).includes('simulationAndGrowth') && Object.keys(this.auxiliaryTables.simulationAndGrowth).includes(this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()) ? 
            this.auxiliaryTables.simulationAndGrowth[this.params.simulatedRevenue.toString() + this.params.growthPercent.toString()] :
            0;
        this.inheritParams(14);
    }
    handleChangeFrameLease(event){
        this.params.additionalFrameLease = event.target.checked;
    }
    handleChangeOfferTasting(event){
        this.params.additionalOfferTasting = event.target.checked;
    }
    handleChangeOfferFinancing(event){
        this.params.additionalOfferFinancing = event.target.checked;
    }
    handleChangeOfferTraining(event){
        this.params.additionalOfferTraining = event.target.checked;
    }
    handleChangeAdditionalOther(event){
        this.params.additionalOther = event.target.checked;
    }
    handleChangeAdditionalQualityVisit(event){
        this.params.additionalQualityVisit = event.target.checked;
    }
    handleChangeFrameLeaseText(event){
        this.params.additionalFrameLeaseText = event.target.value;
    }
    handleChangeAdditionalOtherText(event){
        this.params.additionalOtherText = event.target.value;
    }
    handleChangeAdditionalQualityVisitInterval(event){
        this.params.additionalQualityVisitInterval = event.target.value;
    }
    handleChangeAdditionalQualityVisitInitial(event){
        this.params.additionalQualityVisitInitial = event.target.value;
    }
    handleChangeAdditionalQualityVisitSettingRequested(event){
        this.params.additionalQualityVisitSettingRequested = event.target.checked;
    }
    handleSectionToggle(event) {
        this.activeSections = event.detail.openSections;
        this.showInitialEquipment = this.activeSections.includes("InitialEquipment");
        this.showRefund = this.activeSections.includes("Refund");
        this.showSimulation = this.activeSections.includes("Simulation");
        this.params.showAdditionalAgreements = this.activeSections.includes("AdditionalAgreements");
        if(this.activeSections.includes("MachineConfigurator")){
            this.showMachineConfigurator =  true;
            // Check Coffee Volume
            this.handleMachineConfiguratorNumTypeChange();
        } else {
            this.showMachineConfigurator =  false;
            this.showMachineConfiguratorActual =  false;
            this.showMachineConfiguratorWarning =  false;
        }
        this.inheritParams(15);
    }
    handleOfferOnTable(event){
        this.params.hasOfferOnTable = event.target.value;
        this.inheritParams(16);
    }
    handleMenuLogo(event){
        this.params.hasMenuLogo = event.target.value;
        this.inheritParams(17);
    }
    handleOfferInProperty(event){
        this.params.hasOfferInProperty = event.target.value;
        this.inheritParams(18);
    }
    handleDigitalRequired(event){
        this.params.hasDigitalRequired = event.target.value;
        this.inheritParams(19);
    }
    handleDiscount(event){
        this.params.discount = event.target.value;            
        this.params.simRebateDiscountTotal = (stringIsNotBlank(this.params.discount) && Object.keys(this.auxiliaryTables).includes('discount') && Object.keys(this.auxiliaryTables.discount).includes(this.params.discount) ?  this.auxiliaryTables.discount[this.params.discount] : 0);
        console.log(JSON.stringify(this.auxiliaryTables));
        console.log(this.params.discount);
        console.log(this.params.simRebateDiscountTotal);
        this.inheritParams(20);
    }
    handleQuantityChange(event){
        this.pristine = false;
        let datatype = event.target.dataset.datatype;
        let val = stringIsNotBlank(event.target.value) ? event.target.value : 0;
        this.numTypes[datatype].quantities = parseInt(val);
        this.recalcKgCharge();
        this.handleMachineConfiguratorNumTypeChange();
        this.calcNumTypesDiscrepancyWarnings();
        this.checkQuantitySelectionMismatch();
        this.inheritInitialParams();
        this.inheritParams(21);
    }
    handleNumTypesChange(event){
        this.pristine = false;
        let datatype = event.target.dataset.datatype;
        let val = stringIsNotBlank(event.target.value) ? event.target.value : 0;
        this.numTypes[datatype].selection = parseInt(val);
        this.recalcKgCharge();
        this.handleMachineConfiguratorNumTypeChange();
        this.calcNumTypesDiscrepancyWarnings();
        this.checkQuantitySelectionMismatch();
        this.inheritInitialParams();
        this.inheritParams(22);
    }
    addInitialEquipmentRow(){
        let initialEquipmentData = JSON.parse(JSON.stringify(this.INITIAL_EQUIPMENT_DATA[0]));
        initialEquipmentData.rownumber = this.maxInitialNumber;
        initialEquipmentData.showTeaColumn = this.showTeaColumn;
        this.initialEquipmentData.push(initialEquipmentData);
        this.maxInitialNumber++;
        this.inheritInitialParams();
    }
    addConditionProductRow(){
        let conditionProductData = JSON.parse(JSON.stringify(this.EMPTY_CONDITION_DATA));
        conditionProductData.rownumber = this.maxConditionNumber;
        this.conditionProductData.push(conditionProductData);
        this.maxConditionNumber++;
        this.resetChildrenExistingIds();
        this.inheritParams(23);
    }
    handleCancel(event) {
        loadScript(this, removeStyle)
        .then(result => {
            this.reset();
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }
    handleCreate(){
        this.createRecord(false);
    }
    handleCreateAndClose(){
        this.createRecord(true);
    }
  
    // Handler Helpers
    inheritParams(number){
        this.pristine = false;
        let self = this;
        setTimeout(() => {
            self.template.querySelectorAll('c-price-configurator-condition-product-row').forEach(row => {
                row.existingRows = self.existingRows;
                row.numTypes = self.numTypes;
                row.params = self.params;
            })
        }, 250);
    }
    checkQuantitySelectionMismatch(){
        this.displayErrors = JSON.parse(JSON.stringify(this.DISPLAY_ERRORS));
        this.displayErrors.coffeeSelectionNoQuantity = this.numTypes.coffee.selection > 0 && this.numTypes.coffee.quantities == 0;
        this.displayErrors.teaSelectionNoQuantity = this.numTypes.tea.selection > 0 && this.numTypes.tea.quantities == 0;
        this.displayErrors.cocoaSelectionNoQuantity = this.numTypes.cocoa.selection > 0 && this.numTypes.cocoa.quantities == 0;
        this.displayErrors.otherSelectionNoQuantity = this.numTypes.other.selection > 0 && this.numTypes.other.quantities == 0;
        this.displayErrors.coffeeQuantityNoSelection = this.numTypes.coffee.quantities > 0 && this.numTypes.coffee.selection == 0;
        this.displayErrors.teaQuantityNoSelection = this.numTypes.tea.quantities > 0 && this.numTypes.tea.selection == 0;
        this.displayErrors.cocoaQuantityNoSelection = this.numTypes.cocoa.quantities > 0 && this.numTypes.cocoa.selection == 0;
        this.displayErrors.otherQuantityNoSelection = this.numTypes.other.quantities > 0 && this.numTypes.other.selection == 0;
        this.displayErrors.coffeeAmountZero = this.numTypes.coffee.selected > 0 && parseInt(this.numTypes.coffee.selection) == 0;
        this.displayErrors.coffeeQuantityZero = this.numTypes.coffee.selected > 0 && parseInt(this.numTypes.coffee.quantities) == 0;
        this.displayErrors.teaAmountZero = this.numTypes.tea.selected > 0 && parseInt(this.numTypes.tea.selection) == 0;
        this.displayErrors.teaQuantityZero = this.numTypes.tea.selected > 0 && parseInt(this.numTypes.tea.quantities) == 0;
        this.displayErrors.otherAmountZero = this.numTypes.other.selected > 0 && parseInt(this.numTypes.other.selection) == 0;
        this.displayErrors.otherQuantityZero = this.numTypes.other.selected > 0 && parseInt(this.numTypes.other.quantities) == 0;
        this.displayErrors.cocoaAmountZero = this.numTypes.cocoa.selected > 0 && parseInt(this.numTypes.cocoa.selection) == 0;
        this.displayErrors.cocoaQuantityZero = this.numTypes.cocoa.selected > 0 && parseInt(this.numTypes.cocoa.quantities) == 0;
        this.displayErrors.noCoffeeSelected = this.numTypes.coffee.selection > 0 && parseInt(this.numTypes.coffee.selected) == 0;
        this.displayErrors.noCocoaSelected = this.numTypes.cocoa.selection > 0 && parseInt(this.numTypes.cocoa.selected) == 0;
        this.displayErrors.noOtherSelected = this.numTypes.other.selection > 0 && parseInt(this.numTypes.other.selected) == 0;
        this.displayErrors.noTeaSelected = this.numTypes.tea.selection > 0 && parseInt(this.numTypes.tea.selected) == 0;
        this.displayErrors.noCoffeeQuantity = this.numTypes.coffee.quantities > 0 && parseInt(this.numTypes.coffee.selected) == 0;
        this.displayErrors.noCocoaQuantity = this.numTypes.cocoa.quantities > 0 && parseInt(this.numTypes.cocoa.selected) == 0;
        this.displayErrors.noOtherQuantity = this.numTypes.other.quantities > 0 && parseInt(this.numTypes.other.selected) == 0;
        this.displayErrors.noTeaQuantity = this.numTypes.tea.quantities > 0 && parseInt(this.numTypes.tea.selected) == 0;
        this.displayErrors.noProductsSelected = this.numTypes.cocoa.selected == 0 && this.numTypes.coffee.selected == 0 && this.numTypes.other.selected == 0 && this.numTypes.tea.selected == 0;
        this.displayErrors.quantityMismatch =
        (
            this.displayErrors.coffeeSelectionNoQuantity ||
            this.displayErrors.teaSelectionNoQuantity ||
            this.displayErrors.cocoaSelectionNoQuantity ||
            this.displayErrors.otherSelectionNoQuantity ||
            this.displayErrors.coffeeQuantityNoSelection ||
            this.displayErrors.teaQuantityNoSelection ||
            this.displayErrors.cocoaQuantityNoSelection ||
            this.displayErrors.otherQuantityNoSelection ||
            this.displayErrors.otherAmountZero ||
            this.displayErrors.otherQuantityZero ||
            this.displayErrors.cocoaAmountZero ||
            this.displayErrors.cocoaQuantityZero ||
            this.displayErrors.coffeeAmountZero ||
            this.displayErrors.coffeeQuantityZero ||
            this.displayErrors.teaAmountZero ||
            this.displayErrors.teaQuantityZero ||
            this.displayErrors.otherAmountZero ||
            this.displayErrors.otherQuantityZero ||
            this.displayErrors.cocoaAmountZero ||
            this.displayErrors.cocoaQuantityZero ||
            this.displayErrors.noCoffeeSelected ||
            this.displayErrors.noCocoaSelected ||
            this.displayErrors.noTeaSelected ||
            this.displayErrors.noOtherSelected ||
            this.displayErrors.noCoffeeQuantity ||
            this.displayErrors.noCocoaQuantity ||
            this.displayErrors.noTeaQuantity ||
            this.displayErrors.noOtherQuantity
        );
    }
    inheritInitialParams(){
        this.calcInitialEquipmentRendering();
        this.recalcTeaDiscount();
        this.initialEquipmentData.forEach(row => {
            row.showTeaColumn = this.showTeaColumn;
        });
        let self = this;
        setTimeout(() => {
            self.template.querySelectorAll('c-price-configurator-initial-equipment-row').forEach(row => {
                row.maxTeaDiscountViolated = self.params.maxTeaDiscountViolated;
                row.maxTeaDiscountValue = self.params.maxTeaDiscountValue;
                row.existingRowsInitial = self.existingRowsInitial;
            })
        }, 250);
    }
    recalcKgCharge(){ 
        this.params.purchaseDuringRuntime = (stringIsNotBlank(this.numTypes.coffee.quantities) && stringIsNotBlank(this.params.runtimeMonths)) ? ((parseInt(this.numTypes.coffee.quantities) / 12) * parseInt(this.params.runtimeMonths)) : 0;    
        this.params.purchaseDuringRuntimeDisplay = this.params.purchaseDuringRuntime != null ? this.params.purchaseDuringRuntime.toFixed(2) : 0;  
        this.params.kgChargeCalculated = this.showInitialEquipment ? (this.totalValueInEuro && this.totalValueInEuro != null ? (this.params.purchaseDuringRuntime != null && this.params.purchaseDuringRuntime > 0 ? parseFloat(this.totalValueInEuro) / parseFloat(this.params.purchaseDuringRuntime) : 0) : 0) : 0;  
        this.params.kgChargeCalculatedDisplay = this.params.kgChargeCalculated != null ? this.params.kgChargeCalculated.toFixed(2) : 0;  
    }
    recalcTeaDiscount(){
        this.params.totalTeaDiscount = 0;
        this.params.maxTeaDiscountValue = 0;
        this.initialEquipmentData.forEach(row => {
            if(stringIsNotBlank(row.product)){
                this.params.totalTeaDiscount += parseInt(row.teaDiscount) ?? 0;
            }
        });
        if(this.numTypes.tea.quantities > 0 && parseFloat(this.params.maxTeaDiscount) > 0){
            this.params.maxTeaDiscountValue = (this.numTypes.tea.quantities * parseFloat(this.params.maxTeaDiscount)) / 100;
            this.params.maxTeaDiscountViolated = this.params.totalTeaDiscount > parseFloat(this.params.maxTeaDiscountValue);
        }
    }
    calcMaxDiscounts(){
        this.params.coffeeQuantityDiscountTotal = 0;
        this.params.coffeeSelectionDiscountTotal = 0;
        this.params.teaQuantityDiscountTotal = 0;
        this.params.teaSelectionDiscountTotal = 0;
        this.params.cocoaQuantityDiscountTotal = 0;
        this.params.cocoaSelectionDiscountTotal = 0;
        this.params.otherQuantityDiscountTotal = 0;
        this.params.otherSelectionDiscountTotal = 0;
        this.params.brandingTableDiscountTotal = 0;
        this.params.brandingMenuDiscountTotal  = 0;
        this.params.brandingPropertyDiscountTotal  = 0;
        this.params.brandingDigitalDiscountTotal = 0;
        this.params.simRefundDiscountTotal  = 0;
        this.params.coffeeBaseDiscountTotal  = 0;
        this.params.teaBaseDiscountTotal  = 0;
        this.params.cocoaBaseDiscountTotal  = 0;
        this.params.otherBaseDiscountTotal  = 0;
        this.params.baseConditionDiscountTotal = 0;
        this.conditionProductData.forEach(row => {
            if(parseInt(row.coffeeQuantityDiscount) > this.params.coffeeQuantityDiscountTotal){
                this.params.coffeeQuantityDiscountTotal = parseInt(row.coffeeQuantityDiscount);
            }
            if(parseInt(row.coffeeSelectionDiscount) > this.params.coffeeSelectionDiscountTotal){
                this.params.coffeeSelectionDiscountTotal = parseInt(row.coffeeSelectionDiscount);
            }
            if(parseInt(row.teaQuantityDiscount) > this.params.teaQuantityDiscountTotal){
                this.params.teaQuantityDiscountTotal = parseInt(row.teaQuantityDiscount);
            }
            if(parseInt(row.teaSelectionDiscount) > this.params.teaSelectionDiscountTotal){
                this.params.teaSelectionDiscountTotal = parseInt(row.teaSelectionDiscount);
            }
            if(parseInt(row.cocoaQuantityDiscount) > this.params.cocoaQuantityDiscountTotal){
                this.params.cocoaQuantityDiscountTotal = parseInt(row.cocoaQuantityDiscount);
            }
            if(parseInt(row.cocoaSelectionDiscount) > this.params.cocoaSelectionDiscountTotal){
                this.params.cocoaSelectionDiscountTotal = parseInt(row.cocoaSelectionDiscount);
            }
            if(parseInt(row.otherQuantityDiscount) > this.params.otherQuantityDiscountTotal){
                this.params.otherQuantityDiscountTotal = parseInt(row.otherQuantityDiscount);
            }
            if(parseInt(row.otherSelectionDiscount) > this.params.otherSelectionDiscountTotal){
                this.params.otherSelectionDiscountTotal = parseInt(row.otherSelectionDiscount);
            }
            if(parseInt(row.brandingTableDiscount) > this.params.brandingTableDiscountTotal){
                this.params.brandingTableDiscountTotal = parseInt(row.brandingTableDiscount);
            }
            if(parseInt(row.brandingMenuDiscount) > this.params.brandingMenuDiscountTotal){
                this.params.brandingMenuDiscountTotal = parseInt(row.brandingMenuDiscount);
            }
            if(parseInt(row.brandingPropertyDiscount) > this.params.brandingPropertyDiscountTotal){
                this.params.brandingPropertyDiscountTotal = parseInt(row.brandingPropertyDiscount);
            }
            if(parseInt(row.brandingDigitalDiscount) > this.params.brandingDigitalDiscountTotal){
                this.params.brandingDigitalDiscountTotal = parseInt(row.brandingDigitalDiscount);
            }
            if(parseInt(row.coffeeBaseDiscount) > this.params.coffeeBaseDiscountTotal){
                this.params.coffeeBaseDiscountTotal = parseInt(row.coffeeBaseDiscount);
            }
            if(parseInt(row.teaBaseDiscount) > this.params.teaBaseDiscountTotal){
                this.params.teaBaseDiscountTotal = parseInt(row.teaBaseDiscount);
            }
            if(parseInt(row.cocoaBaseDiscount) > this.params.cocoaBaseDiscountTotal){
                this.params.cocoaBaseDiscountTotal = parseInt(row.cocoaBaseDiscount);
            }
            if(parseInt(row.otherBaseDiscount) > this.params.otherBaseDiscountTotal){
                this.params.otherBaseDiscountTotal = parseInt(row.otherBaseDiscount);
            }
            if(parseInt(row.baseConditionDiscount) > this.params.baseConditionDiscountTotal){
                this.params.baseConditionDiscountTotal = parseInt(row.baseConditionDiscount);
            }
        });
    }
    calcMaxWarning(){
        this.params.maxWarning = 0;
        this.conditionProductData.forEach(row => {
            if(row.warningLevel > this.params.maxWarning){
                this.params.maxWarning = parseInt(row.warningLevel);
            }
        })
    }
    calcNumTypesDiscrepancyWarnings(){
        this.numTypes.coffee.selected = 0;
        this.numTypes.tea.selected = 0;
        this.numTypes.cocoa.selected = 0;
        this.numTypes.other.selected = 0;
        this.conditionProductData.forEach(row => {
            if(row.productGroup == this.numTypes.coffee.label){
                if(row.producttype == this.label.subgroup){
                    if(Object.keys(this.subgroupCount).includes(row.product)){
                        this.numTypes.coffee.selected += this.subgroupCount[row.product];
                    }
                } else {
                    this.numTypes.coffee.selected++;
                }
            } else if(row.productGroup == this.numTypes.tea.label){
                if(row.producttype == this.label.subgroup){
                    if(Object.keys(this.subgroupCount).includes(row.product)){
                        this.numTypes.tea.selected += this.subgroupCount[row.product];
                    }

                } else {
                    this.numTypes.tea.selected++;
                }
            } else if(row.productGroup == this.numTypes.cocoa.label){
                if(row.producttype == this.label.subgroup){
                    if(Object.keys(this.subgroupCount).includes(row.product)){
                        this.numTypes.cocoa.selected += this.subgroupCount[row.product];
                    }
                } else {
                    this.numTypes.cocoa.selected++;
                }
            } else if(stringIsNotBlank(row.product) && stringIsNotBlank(row.productGroup)){
                if(row.producttype == this.label.subgroup){
                    if(Object.keys(this.subgroupCount).includes(row.product)){
                        this.numTypes.other.selected += this.subgroupCount[row.product];
                    }
                } else {
                    this.numTypes.other.selected++;
                }
            }
        });
    }
    calcInitialEquipmentRendering(){
        this.showInitialEquipmentTable = (stringIsNotBlank(this.numTypes.coffee.quantities) && parseInt(this.numTypes.coffee.quantities) != 0) || (stringIsNotBlank(this.numTypes.cocoa.quantities) && parseInt(this.numTypes.cocoa.quantities) != 0);
        this.showTeaColumn = (!stringIsNotBlank(this.numTypes.coffee.quantities) || parseInt(this.numTypes.coffee.quantities) == 0) && stringIsNotBlank(this.numTypes.tea.quantities) && parseInt(this.numTypes.tea.quantities) != 0;
        this.showInitialEquipmentError = ((!stringIsNotBlank(this.numTypes.coffee.quantities) || parseInt(this.numTypes.coffee.quantities) == 0)
         && (!stringIsNotBlank(this.numTypes.tea.quantities) || parseInt(this.numTypes.tea.quantities) == 0 )
         && (!stringIsNotBlank(this.numTypes.cocoa.quantities) || parseInt(this.numTypes.cocoa.quantities) == 0 )
         && (!stringIsNotBlank(this.numTypes.other.quantities) || parseInt(this.numTypes.other.quantities) == 0) );
    }
    reset(){        
        this.pristine = true;
        this.isLoading = false;
        this.showSimulation = false;
        this.showRefund = false;
        this.activeSections = [];
        this.showInitialEquipment = false;
        this.params.showAdditionalAgreements = false;
        this.numTypes = JSON.parse(JSON.stringify(this.INITIAL_NUMTYPES));
        this.initialEquipmentData = JSON.parse(JSON.stringify(this.INITIAL_EQUIPMENT_DATA));
        this.storedInitialEquipmentData = JSON.parse(JSON.stringify(this.INITIAL_EQUIPMENT_DATA));
        this.conditionProductData = [];
        this.emptyConditionProductData = JSON.parse(JSON.stringify(this.EMPTY_CONDITION_DATA));
        this.params = JSON.parse(JSON.stringify(this.PARAMS));
        this.totalValueInEuro = 0;
        this.roastedCoffeeInKg = 0;
        this.maxConditionNumber = 2;
        this.maxInitialNumber = 2;
        this.showTeaColumn = false;
        this.showRefundColumn = false;
        this.showRefundAllItemsField = true;
        this.showInitialEquipmentTable = false;
        this.showInitialEquipmentError = false;
        this.existingRows = [];
        this.existingRowsInitial = [];
        this.showMachineConfigurator = false;
        this.showMachineConfiguratorWarning = false;
        this.showMachineConfiguratorActual = false;
        this.machineConfiguratorFinalized = false;
        this.machineSurchargeCalculation = false;
        this.machines = [JSON.parse(JSON.stringify(this.BASE_MACHINE))];
        this.specialMachines = [JSON.parse(JSON.stringify(this.BASE_MACHINE))];
        this.machineParams = JSON.parse(JSON.stringify(this.MACHINE_BASE_PARAMS));
        this.coffeeSurchargeMachine = 0;
    }
    resetChildrenInitialExistingIds(){
        this.existingRowsInitial = [];
        this.initialEquipmentData.forEach(row => {
            this.existingRowsInitial.push(row.product);
        });
    }
    resetChildrenExistingIds(){
        this.existingRows = [];
        this.conditionProductData.forEach(row => {
            this.existingRows.push(row.product);
        });
    }

    // Getters
    get createAndCloseLabel(){
        return !this.isQuoteContext || !this.quoteIsDraft ? this.label.createAndClose : this.label.updateAndClose;
    }
    get showMachineConfiguratorStyle(){
        return this.showMachineConfigurator ? '' : 'display: none;';
    }
    get showMachineConfiguratorActualStyle(){
        return this.showMachineConfiguratorActual ? '' : 'display: none;';
    }
    get showMachineConfiguratorWarningStyle(){
        return this.showMachineConfiguratorWarning ? '' : 'display: none;';
    }
    get showMachineConfiguratorWarningStyleReverse(){
        return this.showMachineConfiguratorWarning ? 'display: none;' : '';
    }
    get machineLeasingEnabled(){
        return this.label.machineLeasingEnabled == 'true';
    }
    get isKann(){
        return this.params && this.params.customerType && this.params.customerType == 'Einkaufsgesellschaft KANN';
    }
    get isMuss(){
        return this.params && this.params.customerType && this.params.customerType == 'Einkaufsgesellschaft MUSS';
    }
    get isKannMuss(){
        return this.isKann || this.isMuss;
    }
    get isChain(){
        return this.params && this.params.customerType && this.params.customerType == 'Kette';
    }
    get isChainKannMuss(){
        return this.isChain || this.isKann || this.isMuss;
    }
    get hasIndexConditionFromParamsAndNoChain(){
        return this.hasIndexConditionFromParams && !this.isDependentChainMember; //removed !this.isChainKannMuss
    }
    //get indexConditionMissing(){
    //    return !this.isChainKannMuss && (this.hasIndexConditionFromParams || (!this.hasIndexConditionFromParams && (!stringIsNotBlank(this.indexConditionPreset) || (this.indexConditionPreset == this.label.yes && (!stringIsNotBlank(this.params.indexCondition) || parseInt(this.params.indexCondition) == 0)))));
    //}
    get indexConditionMissing(){
        if (this.isDependentChainMember) {
            return false;
        }
        return this.hasIndexConditionFromParams || 
               (!this.hasIndexConditionFromParams && 
                 (!stringIsNotBlank(this.indexConditionPreset) || 
                 (this.indexConditionPreset == this.label.yes && (!stringIsNotBlank(this.params.indexCondition) || parseInt(this.params.indexCondition) == 0))));
    }
    get showIndexConditionInput() {
        return this.indexConditionPresetYes || this.isDependentChainMember;
    }
    get createDisabled(){
        return this.pristine || this.params.maxTeaDiscountViolated || this.agreementNoComment || this.qualityNoIntervalOrDate || this.refundTypeNoStep || this.wkzNotMatching || this.indexConditionMissing || this.displayErrors.quantityMismatch || this.displayErrors.noProductsSelected;
    }
    get refundTypeNoStep(){
        return (stringIsNotBlank(this.params.coffeeRefundType) && (!stringIsNotBlank(this.params.coffeeRefundLevel) || parseInt(this.params.coffeeRefundLevel) == 0)) ||
        (stringIsNotBlank(this.params.teaRefundType) && (!stringIsNotBlank(this.params.teaRefundLevel) || parseInt(this.params.teaRefundLevel) == 0));
    }
    get agreementNoComment(){
        return this.params.showAdditionalAgreements && 
        (
            (this.params.additionalFrameLease && !stringIsNotBlank(this.params.additionalFrameLeaseText)) ||
            (this.params.additionalOther && !stringIsNotBlank(this.params.additionalOtherText))
        );
    }
    get qualityNoIntervalOrDate(){
        return this.params.showAdditionalAgreements && this.params.additionalQualityVisit &&
        ( !stringIsNotBlank(this.params.additionalQualityVisitInterval) || !stringIsNotBlank(this.params.additionalQualityVisitInitial) );
    }
    get productColumnSize(){
        return this.showTeaColumn ? '2' : '3';
    }
    get productColumnSizeConfig(){
        return this.isMuss ? '5' : '4';
    }
    get existingCustomer() {
        return this.newCustomer == 0;
    }
    get newCustomer() {
        return this.newCustomer == 1;
    }
    get newCustomerWithInherited() {
        return this.newCustomer == 2;
    }
    get hasCocoaOrCoffeeQuantities() {
        return (stringIsNotBlank(this.numTypes.coffee.quantities) && parseInt(this.numTypes.coffee.quantities) > 0) || (stringIsNotBlank(this.numTypes.cocoa.quantities) && parseInt(this.numTypes.cocoa.quantities) > 0);
    }
    get hasTeaQuantities() {
        return stringIsNotBlank(this.numTypes.tea.quantities) && parseInt(this.numTypes.tea.quantities) > 0;
    }
    get hasNoCocoaCoffeeButTeaQuantities() {
        return !this.hasCocoaOrCoffeeQuantities && this.hasTeaQuantities;
    }
    get hasCocoaCoffeeTeaQuantities() {
        return this.hasCocoaOrCoffeeQuantities && this.hasTeaQuantities;
    }
    get hasTeaRV() {
      return stringIsNotBlank(this.params.teaRefundType);
    }
    get hasCoffeeRV() {
      return stringIsNotBlank(this.params.coffeeRefundType);
    }
    get hasTeaType() {
      return this.hasTeaQuantities;
    }
    get hasCoffeeType() {
      return this.hasCocoaOrCoffeeQuantities;
    }
    get hasAnyType() {
      return this.hasTeaQuantities || this.hasCocoaOrCoffeeQuantities;
    }
    get hasCoffeeAndTeaType() {
      return this.hasTeaType && this.hasCoffeeType;
    }
    get hasTeaNoCoffeeType() {
      return this.hasTeaType && !this.hasCoffeeType;
    }
    get oppClosed() {
      return getFieldValue(this.opportunity.data, CLOSED_FIELD);
    }
    get openMachineConfiguratorDisabled(){
        return !stringIsNotBlank(this.params.runtimeMonths) || this.params.runtimeMonths == 0 || !stringIsNotBlank(this.numTypes.coffee.quantities) || this.numTypes.coffee.quantities == 0;
    }
    get individualConditionProducts() {
        return this.conditionProductData.filter(item => item.individualCondition);
    }

    get standardConditionProducts() {
        return this.conditionProductData.filter(item => !item.individualCondition);
    }

    get hasIndividualProducts() {
        return this.individualConditionProducts && this.individualConditionProducts.length > 0;
    }

    get hasStandardProducts() {
        return this.standardConditionProducts && this.standardConditionProducts.length > 0;
    }
    get isChainHead() {
        return this.params && this.params.isChainMember === true && this.params.isTopAccountCondition === true;
    }
    get isSingleCustomer() {
        return this.params && this.params.isChainMember === false;
    }
    get isSingleCustomerOrChainHead() {
        return this.isSingleCustomer || this.isChainHead;
    }
    get isChainHead() {
        return this.params && this.params.isChainMember === true && this.params.isTopAccountCondition === true;
    }
    get isDependentChainMember() {
        return this.params && this.params.isChainMember === true && this.params.isTopAccountCondition === false;
    }
    
    // Apex Connectors
    createRecord(close){
        this.pristine = true;
        this.isLoading = true;
        createOffer({
            opportunityId: this.opportunityId,
            quoteId: this.quoteId,
            params : this.params,
            machineParams : this.machineParams,
            numTypes: JSON.stringify(this.numTypes),
            initialEquipmentData: this.convertToBoolean(JSON.stringify(this.initialEquipmentData)),
            conditionProductData: JSON.stringify(this.conditionProductData),
            hasMachineData: this.showMachineConfigurator && this.showMachineConfiguratorActual && this.machineConfiguratorFinalized,
            machineData: JSON.stringify(this.machines),
            specialMachineData: JSON.stringify(this.specialMachines),
            industry: this.industry,
            showSimulation: this.showSimulation,
            showRefund: this.showRefund,
            machineOfferQuoteId: this.machineOfferToEdit,
            machineSurchargeCalculation: this.machineSurchargeCalculation,
            isDependentChainMember: this.isDependentChainMember
        })
        .then(resp => {
            console.log('resp: ' + resp);
            if(resp != null){
                if(!resp.includes('Error')){
                    const evt = new ShowToastEvent({
                    title: this.label.success,
                    message: this.label.quoteCreated,
                    messageData: [{
                        url: '/' + resp,
                        label: this.label.seeItHere
                    }],
                    variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    if(close){
                        loadScript(this, removeStyle)
                        .then(innerResult => {
                            this.reset();
                            let self = this;
                            setTimeout(() => {
                                self[NavigationMixin.Navigate]({
                                    type: "standard__recordPage",
                                    attributes: {
                                        recordId: self.isQuoteContext ? self.quoteId : self.opportunityId,
                                        objectApiName: self.isQuoteContext ? "Quote" : "Opportunity",
                                        actionName: "view",
                                    },
                                });
                            }, 500);
                        });
                    } else {
                        this.isLoading = false;
                    }
                } else {
                    this.pristine = false;
                    this.isLoading = false;
                    const evt = new ShowToastEvent({
                        title: this.label.errorMsg,
                        message: resp,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
            } else {
                this.pristine = false;
                this.isLoading = false;
                const evt = new ShowToastEvent({
                  title: this.label.errorMsg,
                  message: this.label.errorMsg,
                  variant: 'error',
                });
                this.dispatchEvent(evt);
            }
        })
        .catch(error => {
            this.pristine = false;
            this.isLoading = false;
            const evt = new ShowToastEvent({
              title: this.label.errorMsg,
              message: error,
              variant: 'error',
            });
            this.dispatchEvent(evt);
        });
    }

    // Utils
    convertToBoolean(value){
        return value.replaceAll('"' + this.label.yes + '"', 'true').replaceAll('"' + this.label.no + '"', 'false');
    }
    convertJsonToBoolean(value){
        return value == this.label.yes;
    }
}
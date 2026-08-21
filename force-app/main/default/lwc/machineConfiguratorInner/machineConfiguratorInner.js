import { LightningElement, api, track } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {  NavigationMixin } from 'lightning/navigation';

import quoteUpdatedRefreshing from '@salesforce/label/c.MachineConfiguratorQuoteUpdatedRefreshing';
import addNewBaseMachineLabel from '@salesforce/label/c.MachineConfiguratorAddNewBaseMachine';
import addAnotherLabel from '@salesforce/label/c.MachineConfiguratorAddAnother';
import machineConfigurator from '@salesforce/label/c.MachineConfigurator';
import adjustmentAmount from '@salesforce/label/c.MachineConfiguratorAdjustmentAmount';
import baseMachine from '@salesforce/label/c.MachineConfiguratorBaseMachine';
import baseComponents from '@salesforce/label/c.MachineConfiguratorBaseComponent';
import purchasePrice from '@salesforce/label/c.GeneralPurchasePrice';
import calculateNow from '@salesforce/label/c.MachineConfiguratorCalculateNow';
import coffeeMachineConfiguration from '@salesforce/label/c.MachineConfiguratorCoffeeMachineConfiguration';
import coffeePerYear from '@salesforce/label/c.MachineConfiguratorCoffeePerYear';
import continueWithoutAccessoires from '@salesforce/label/c.MachineConfiguratorContinueWithoutAccessories';
import discountable from '@salesforce/label/c.MachineConfiguratorDiscountable';
import discountInPercent from '@salesforce/label/c.MachineConfiguratorDiscountInPercent';
import downPaymentInPercent from '@salesforce/label/c.MachineConfiguratorDownPaymentInPercent';
import enterFreeText from '@salesforce/label/c.MachineConfiguratorEnterFreeText';
import financingAmount from '@salesforce/label/c.MachineConfiguratorFinancingAmount';
import modelName from '@salesforce/label/c.MachineConfiguratorModelName';
import monthlyRateInEuro from '@salesforce/label/c.MachineConfiguratorMonthlyRateInEuro';
import finalMonthlyRateInEuro from '@salesforce/label/c.MachineConfiguratorMonthlyRateInEuroFinal';
import netAmountAccessoires from '@salesforce/label/c.MachineConfiguratorNetAmountAccessories';
import netAmountMachine from '@salesforce/label/c.MachineConfiguratorNetAmountMachine';
import netAmountNoDiscount from '@salesforce/label/c.MachineConfiguratorNetAmountNoDiscount';
import netAmountNoDiscountAccessoires from '@salesforce/label/c.MachineConfiguratorNetAmountNoDiscountAccessories';
import netAmountNoDiscountMachine from '@salesforce/label/c.MachineConfiguratorNetAmountNoDiscountMachine';
import noAccessories from '@salesforce/label/c.MachineConfiguratorNoAccessories';
import noAccessoriesAvailable from '@salesforce/label/c.MachineConfiguratorNoAccessoriesAvailable';
import noProducts from '@salesforce/label/c.MachineConfiguratorNoProducts';
import noComponents from '@salesforce/label/c.MachineConfiguratorNoComponents';
import offerValidUntil from '@salesforce/label/c.MachineConfiguratorOfferValidUntil';
import priceInEuro from '@salesforce/label/c.MachineConfiguratorPriceInEuro';
import producerSearch from '@salesforce/label/c.MachineConfiguratorProducerSearch';
import runtimeInMonths from '@salesforce/label/c.MachineConfiguratorRuntimeInMonths';
import salePrice from '@salesforce/label/c.MachineConfiguratorSalePrice';
import minDownPayment from '@salesforce/label/c.MachineConfiguratorDoNotTranslateMinDownPayment';
import minDownPaymentText from '@salesforce/label/c.MachineConfiguratorMinDownPaymentText';
import selectAccessoiresAndComponents from '@salesforce/label/c.MachineConfiguratorSelectAccessoriesAndComponents';
import selectAccessoires from '@salesforce/label/c.MachineConfiguratorSelectAccessories';
import selectComponents from '@salesforce/label/c.MachineConfiguratorSelectComponents';
import specialDiscountInPercent from '@salesforce/label/c.MachineConfiguratorSpecialDiscountInPercent';
import surchargeCalculation from '@salesforce/label/c.MachineConfiguratorSurchargeCalculation';
import vat19percent from '@salesforce/label/c.MachineConfiguratorVat19percent';
import producerSelection from '@salesforce/label/c.MachineConfiguratorProducerSelection'
import calculation from '@salesforce/label/c.MachineConfiguratorCalculation'
import summary from '@salesforce/label/c.GeneralSummary'
import accessoires from '@salesforce/label/c.GeneralAccessories';
import additionalDiscount from '@salesforce/label/c.GeneralAdditionalDiscount';
import additionalDiscounts from '@salesforce/label/c.GeneralAdditionalDiscounts';
import temporaryDiscount from '@salesforce/label/c.GeneralTemporaryDiscount';
import backLabel from '@salesforce/label/c.GeneralBack';
import cancel from '@salesforce/label/c.GeneralCancel';
import error from '@salesforce/label/c.WebshopGeneralError';
import dateLabel from '@salesforce/label/c.GeneralDate';
import description from '@salesforce/label/c.GeneralDescription';
import downpaymentAmount from '@salesforce/label/c.GeneralDownpaymentAmount';
import downpaymentVat from '@salesforce/label/c.GeneralDownpaymentVatAmount';
import downpaymentTotal from '@salesforce/label/c.GeneralDownpaymentTotal';
import finishLabel from '@salesforce/label/c.GeneralFinish';
import grossAmount from '@salesforce/label/c.GeneralGrossAmount';
import listPrice from '@salesforce/label/c.GeneralListPrice';
import progress from '@salesforce/label/c.GeneralProgress';
import runtimeLabel from '@salesforce/label/c.GeneralRuntime';
import quantity from '@salesforce/label/c.GeneralQuantity';
import quoteCreated from '@salesforce/label/c.GeneralQuoteCreated';
import seeItHere from '@salesforce/label/c.GeneralSeeItHere';
import subtotal from '@salesforce/label/c.GeneralSubtotal';
import success from '@salesforce/label/c.GeneralSuccess';
import totalDiscount from '@salesforce/label/c.GeneralTotalDiscount';
import totalDiscountPercent from '@salesforce/label/c.GeneralTotalDiscountPercent';
import totalNetAmount from '@salesforce/label/c.GeneralTotalNetAmount';
import maxDiscount from '@salesforce/label/c.GeneralMaxDiscount';
import maxDiscountWarning from '@salesforce/label/c.MachineConfiguratorMaxDiscountWarning';
import directlyToCalculation from '@salesforce/label/c.GeneralDirectlyToCalculation';
import enterReason from '@salesforce/label/c.MachineConfiguratorEnterReason';
import minDownPaymentWarning from '@salesforce/label/c.MachineConfiguratorMinDownPaymentWarning';
import save from '@salesforce/label/c.GeneralSave';
import enterDownPaymentReason from '@salesforce/label/c.MachineConfiguratorEnterDownPaymentReason';
import productSeries from '@salesforce/label/c.MachineConfiguratorProductSeries';
import producer from '@salesforce/label/c.MachineConfiguratorProducer';
import productName from '@salesforce/label/c.WebshopProductName';
import addSpecialMachine from '@salesforce/label/c.MachineConfiguratorAddSpecialMachine';
import specialMachines from '@salesforce/label/c.MachineConfiguratorSpecialMachines';

import VAT_PERCENT from '@salesforce/label/c.MachineConfiguratorDoNotTranslateVATRate';
import INTEREST_PERCENT from '@salesforce/label/c.MachineConfiguratorDoNotTranslateInterestRate';

// Apex
import getOppInfo from '@salesforce/apex/MachineConfiguratorController.getOppInfo';
import searchWithIds from '@salesforce/apex/LookupController.searchWithIds';
import getStandardPricebookEntries from '@salesforce/apex/MachineConfiguratorController.getStandardPricebookEntries';
import getBrandsDropdown from '@salesforce/apex/MachineConfiguratorController.getBrandsDropdown';
import getProductsByBrand from '@salesforce/apex/MachineConfiguratorController.getProductsByBrand';
import getAccessoiresByMachine from '@salesforce/apex/MachineConfiguratorController.getAccessoiresByMachine';
import createOffer from '@salesforce/apex/MachineConfiguratorController.createOffer';
import getPrefillFromQuote from '@salesforce/apex/MachineConfiguratorController.getPrefillFromQuote';


export default class MachineConfiguratorInner extends NavigationMixin(LightningElement) {
    BASE_PARAMS = {
        offerValidUntil: new Date(Date.now() + 12096e5).toISOString().slice(0, 10),
        totalNetAmount: 0,
        totalNetAmountMachine: 0,
        totalNetAmountAccessoires: 0,
        totalNetAmountNoDiscount: 0,
        totalNetAmountNoDiscountMachine: 0,
        totalNetAmountNoDiscountAccessoires: 0,
        totalDiscount: 0,
        totalDiscountPercent: 0,
        totalProducerDiscount: 0,
        totalProducerDiscountPercent: 0,
        totalRoasterDiscount: 0,
        vatAmount: 0,
        totalGrossAmount: 0,
        adjustmentAmount: 0, // Aufschlag
        adjustmentAmountDisplay: "0,00 €", // Aufschlag
        downpaymentPercent: 0,
        downpaymentAmount: 0,
        downpaymentVatAmount: 0,
        financingAmount: 0,
        runtimeInMonths: 0,
        monthlyRateAmount: 0,
        finalMonthlyRateAmount: 0,
        totalNetAmountDisplay : "0,00 €",
        totalNetAmountMachineDisplay : "0,00 €",
        totalNetAmountAccessoiresDisplay : "0,00 €",
        totalNetAmountNoDiscountDisplay : "0,00 €",
        totalNetAmountNoDiscountMachineDisplay : "0,00 €",
        totalNetAmountNoDiscountAccessoiresDisplay : "0,00 €",
        totalDiscountDisplay : "0,00 €",
        totalGrossAmountDisplay : "0,00 €",
        totalDiscountPercentDisplay : "0,00 %",
        financingAmountDisplay: "0,00 €",
        finalMonthlyRateAmountDisplay: "0,00 €",
        vatAmountDisplay : "0,00 €",
        downpaymentAmountDisplay: "0,00 €",
        downpaymentVatAmountDisplay : "0,00 €",
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
        priceDisplay: "0,00 €",
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
        discountAmountDisplay: "0,00 €",
        salePriceDisplay: "0,00 €",
        rowTotalDisplay: "0,00 €",
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
    label = {
        maxDiscount,
        offerValidUntil,
        quoteUpdatedRefreshing,
        progress,
        baseComponents,
        purchasePrice,
        addNewBaseMachineLabel,
        enterDownPaymentReason,
        minDownPaymentWarning,
        addAnotherLabel,
        machineConfigurator,
        adjustmentAmount,
        coffeeMachineConfiguration,
        dateLabel,
        coffeePerYear,
        runtimeLabel,
        producerSearch,
        enterFreeText,
        baseMachine,
        modelName,
        description,
        priceInEuro,
        discountable,
        quantity,
        listPrice,
        discountInPercent,
        specialDiscountInPercent,
        salePrice,
        subtotal,
        accessoires,
        grossAmount,
        downPaymentInPercent,
        vat19percent,
        financingAmount,
        runtimeInMonths,
        monthlyRateInEuro,
        finalMonthlyRateInEuro,
        surchargeCalculation,
        cancel,
        selectAccessoiresAndComponents,
        selectAccessoires,
        selectComponents,
        continueWithoutAccessoires,
        calculateNow,
        finishLabel,
        backLabel,
        noProducts,
        noComponents,
        noAccessories,
        noAccessoriesAvailable,
        success,
        save,
        error,
        quoteCreated,
        seeItHere,
        downpaymentAmount,
        downpaymentVat,
        totalDiscount,
        totalDiscountPercent,
        netAmountMachine,
        netAmountNoDiscountMachine,
        netAmountAccessoires,
        netAmountNoDiscountAccessoires,
        netAmountNoDiscount,
        totalNetAmount,
        downpaymentVat,
        downpaymentTotal,
        maxDiscountWarning,
        directlyToCalculation,
        enterReason,
        minDownPayment,
        minDownPaymentText,
        additionalDiscount,
        additionalDiscounts,
        temporaryDiscount,
        productSeries,
        producer,
        productName,
        addSpecialMachine,
        specialMachines,
    }
    @api recordId;
    @api fromConfigurator = false;
    @api coffeeAnnual = 0;
    @api step = 1;
    @api paramsAlt = JSON.parse(JSON.stringify(this.BASE_PARAMS));
    @api surchargeCalculation = false;
    @api machinesAlt = [];

    @api set runtimeInMonths(value){
        this.params.runtimeInMonths = value;
    }
    get runtimeInMonths(){
        return this.params.runtimeInMonths;
    }

    @track standardPricebookEntries = {};
    @track isLoading = false;
    @track oppInfo;
    @track brandId = null;
    @track tableData = [];
    @track tableDataComponents = [];
    @track tableDataAccessories = [];
    @track machineLookup = true;
    @track brandOptions = [];
    @track params = JSON.parse(JSON.stringify(this.BASE_PARAMS));
    @track lastMachine = JSON.parse(JSON.stringify(this.BASE_MACHINE));
    @track machines = [];
    @track specialMachines = [];
    @track lastIndex = 0;
    @track showReasonModal = false;
    @track hasExtraDiscount = false;
    @track showExtraDiscountModal = false;
    @track showSpecialMachineModal = false;
    @track showSpecialMachinesTwoModal = false;
    @track specialMachineName = null;
    @track specialMachineDescription = null;
    @track specialMachinePrice = null;
    @track opportunityId = null;
    @track quoteId = null;
    @track fromQuote = false;
    @track selectedAccessoires = [];

    @track additionalDiscountBaseMachine = null;
    @track additionalDiscountBaseComponent = null;
    @track additionalDiscountAccessories = null;
    @track temporaryDiscountBaseMachine = null;
    @track temporaryDiscountBaseComponent = null;
    @track temporaryDiscountAccessories = null;
    @track specialMachinesPurchasePrice = null;
    @track machineMaxDiscount = null;

    reset(){
        this.standardPricebookEntries = {};
        this.isLoading = false;
        this.oppInfo;
        this.brandId = null;
        this.tableData = [];
        this.tableDataComponents = [];
        this.tableDataAccessories = [];
        this.machineLookup = true;
        this.brandOptions = [];
        this.params = JSON.parse(JSON.stringify(this.BASE_PARAMS));
        this.lastMachine = JSON.parse(JSON.stringify(this.BASE_MACHINE));
        this.machines = [];
        this.specialMachines = [];
        this.lastIndex = 0;
        this.showReasonModal = false;
        this.showExtraDiscountModal = false;
        this.showSpecialMachineModal = false;
        this.showSpecialMachinesTwoModal = false;
        this.specialMachineName = null;
        this.specialMachineDescription = null;
        this.specialMachinePrice = null;
    }

    columns = [
        { label: this.label.productSeries, fieldName: 'productSeries' },
        { label: this.label.modelName, fieldName: 'title' },
        { label: this.label.description, fieldName: 'description', wrapText: true },
        { label: this.label.priceInEuro, fieldName: 'price', type: 'currency' },
        { label: this.label.discountable, fieldName: 'discountable', type: 'boolean' },
    ];
    columnsAlt = [
        { label: this.label.modelName, fieldName: 'title' },
        { label: this.label.description, fieldName: 'description', wrapText: true },
        { label: this.label.priceInEuro, fieldName: 'price', type: 'currency' },
        { label: this.label.discountable, fieldName: 'discountable', type: 'boolean' },
    ];


    connectedCallback(){
        this.isLoading = true;
        if(this.paramsAlt && this.paramsAlt != null){
            this.params = JSON.parse(JSON.stringify(this.paramsAlt));
        }
        if(this.machinesAlt && this.machinesAlt.length > 0){
            this.machines = JSON.parse(JSON.stringify(this.machinesAlt));
        }
        if (stringIsNotBlank(this.recordId)) {
            if(this.recordId.substring(0, 3) == '006'){
                this.opportunityId = this.recordId;
                this.processOppData();
            } else {
                this.quoteId = this.recordId;
                this.fromQuote = true;
                getPrefillFromQuote({quoteId: this.quoteId})
                .then(result => {
                    this.machines = result.machines;
                    this.specialMachines = result.specialMachines;
                    this.lastIndex = this.machines.length + this.specialMachines.length;
                    Object.keys(result.params).forEach(param => {
                        this.params[param] = result.params[param];
                    })
                    this.params.discountViolationReason = result.discountViolationReason;
                    this.params.downPaymentViolationReason = result.downPaymentViolationReason;
                    this.params.discountViolationCampaign = result.discountViolationCampaign;
                    
                    this.additionalDiscountBaseMachine = result.additionalDiscountBaseMachine;
                    this.additionalDiscountBaseComponent = result.additionalDiscountBaseComponent;
                    this.additionalDiscountAccessories = result.additionalDiscountAccessories;
                    this.temporaryDiscountBaseMachine = result.temporaryDiscountBaseMachine;
                    this.temporaryDiscountBaseComponent = result.temporaryDiscountBaseComponent;
                    this.temporaryDiscountAccessories = result.temporaryDiscountAccessories;
                    this.specialMachinesPurchasePrice = result.specialMachinesPurchasePrice;
                    this.hasExtraDiscount = this.additionalDiscountBaseMachine != null ||
                                            this.additionalDiscountBaseComponent != null ||
                                            this.additionalDiscountAccessories != null ||
                                            this.temporaryDiscountBaseMachine != null ||
                                            this.temporaryDiscountBaseComponent != null ||
                                            this.temporaryDiscountAccessories != null;
                    this.machineMaxDiscount = result.machineMaxDiscount;

                    this.opportunityId = result.opportunityId;
                    this.processOppData();
                    this.recalcBaseMachineGeneral(false, null, null, null);
                    this.recalcSpecialMachineGeneral(null, null, null);
                    this.recalcTotal();
                    this.step = 3;
                });
            }
        }
    }

    processOppData(){
        getOppInfo({opportunityId: this.opportunityId})
        .then(result => {
            this.oppInfo = result;
            if(Object.keys(this.standardPricebookEntries).length > 0){
                this.processBrandsDropdown();
            } else {
                getStandardPricebookEntries({opportunityId: this.opportunityId})
                .then(innerResult => {
                    this.standardPricebookEntries = innerResult;
                    this.processBrandsDropdown();
                });
            }
        })
    }

    processBrandsDropdown(){
        getBrandsDropdown({})
        .then(innermostResult => {
            this.brandOptions = innermostResult;
            this.recalcBaseMachineGeneral(true, null, null, null);            
            if(this.fromConfigurator && this.step == 4){
                const changeEvent = new CustomEvent('confirm', {
                    detail: {
                        machines: this.machines,
                        specialMachines: this.specialMachines,
                        surchargeCalculation: this.surchargeCalculation,
                        params: this.params
                    }
                });
                this.dispatchEvent(changeEvent);
            }
            this.isLoading = false;
        });
    }

    get isStepOne(){
        return this.step == 1;
    }
    get isStepTwo(){
        return this.step == 2;
    }
    get isStepOneTwo(){
        return this.step == 1 || this.step == 2;
    }
    get isStepThree(){
        return this.step == 3;
    }
    get isStepFour(){
        return this.step == 4;
    }
    get isStepFive(){
        return this.step == 5;
    }
    get isStepThreeFour(){
        return this.step == 3 || this.step == 4;
    }
    get isStepFourFive(){
        return this.step == 4 || this.step == 5;
    }
    get isStepThreeFourFive(){
        return this.step == 3 || this.step == 4  || this.step == 5;
    }
    get stepOneDisabled(){
        return !stringIsNotBlank(this.lastMachine.id);
    }
    get stepOneDisabledAlt(){
        return stringIsNotBlank(this.lastMachine.id) ? false : this.machines.length == 0;
    }
    get runtimeMonthsEmpty(){
        return this.fromConfigurator && (!stringIsNotBlank(this.params.runtimeInMonths) || this.params.runtimeInMonths == 0);
    }
    get reasonModalDisabled(){
        return (this.showReasonModal &&
            (this.params.hasAccessoireDiscountViolation && (!stringIsNotBlank(this.params.discountViolationReason) && !stringIsNotBlank(this.params.discountViolationCampaign))) ||
            (this.minDownPaymentBelow && !stringIsNotBlank(this.params.downPaymentViolationReason))
        ) || (this.showSpecialMachinesTwoModal && !stringIsNotBlank(this.specialMachinesPurchasePrice));
    }
    get specialMachineModalDisabled(){
        return !stringIsNotBlank(this.specialMachineDescription) || !stringIsNotBlank(this.specialMachineName) || !stringIsNotBlank(this.specialMachinePrice)
    }
    get stepOneDisabledOrMonthsEmpty(){
        return this.stepOneDisabledAlt || this.runtimeMonthsEmpty;
    }
    get hasTableData(){
        return this.tableData.length > 0;
    }
    get hasTableDataComponents(){
        return this.tableDataComponents.length > 0;
    }
    get hasTableDataAccessories(){
        return this.tableDataAccessories.length > 0;
    }
    get formattedDate(){
        let date = new Date();
        return `${("0" + date.getDate()).slice(-2)}.${("0" + (date.getMonth() + 1)).slice(-2)}.${date.getFullYear()}`;
    }
    get stepThreeDisabled(){
        if(this.machines.length == 0 && this.specialMachines.length == 0){
            return true;
        }
        this.machines.forEach(machine => {
            if(machine.hasMaxDiscountOneViolation || machine.hasMaxDiscountTwoViolation){
                return true;
            }
        })
        return false;
    }
    get minDownPaymentBelow(){
        return parseFloat(this.params.downpaymentPercent) < parseFloat(this.label.minDownPayment);
    }
    get minDownPaymentBelowWidth(){
        return this.minDownPaymentBelow ? '10' : '12';
    }
    get minDownPaymentWarning(){
        return this.label.minDownPaymentWarning + ' ' + this.label.minDownPayment + '%';
    }
    get hasSpecialMachines(){
        return this.specialMachines.length > 0;
    }

    /* Progress Indicator */

    get progressPercentage() {
        return (this.step - 1) * (100 / 3); 
    }

    get progressBarStyle() {
        const percentage = this.progressPercentage;
        if (typeof percentage === 'number' && percentage >= 0 && percentage <= 100) {
            return `width: ${percentage}%; height:100%; background-color: #0070d2; border-radius: 2px;`;
        }
        return 'width: 0%'; // fallback default
    } 

    get minDownPayment(){
        return parseFloat(this.label.minDownPayment);
    }
    
    // Progress Step Status (for 4 steps)
    get stepStatuses() {
        const labels = [producerSelection, accessoires, calculation, summary];
        return [1, 2, 3, 4].map((stepNum, index) => {
            return {
                key: stepNum,
                label: labels[index],
                isCompleted: this.step > stepNum,
                isActive: this.step === stepNum,
                itemClass:
                    'slds-progress__item_content' +
                    (this.step > stepNum ? ' slds-is-completed' : '') +
                    (this.step === stepNum ? ' slds-is-active' : ''),
                markerClass:
                    this.step > stepNum
                        ? 'slds-progress__marker slds-progress__marker_icon slds-progress__marker_icon-success'
                        : 'slds-progress__marker'
            };
        });
    }
    get showReasonOrSpecialMachinesTwoOrExtraDiscountModal(){
        return this.showReasonModal || this.showSpecialMachinesTwoModal || this.showExtraDiscountModal;
    }

    handleCancel(event) {
        this.close();
    }

    close(){
        this.reset();
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    /* Fields */ 
    changeCoffeeAnnual(event){
        this.coffeeAnnual = parseInt(event.target.value);
    }
    changeOfferValidUntil(event){
        this.params.offerValidUntil = event.target.value;
    }
    changeRuntimeMonths(event){
        this.params.runtimeInMonths = parseInt(event.target.value);
        this.recalcParams();
    }
    changeSurchargeCalculation(event){
        this.surchargeCalculation = event.target.checked;
    }
    changeMachineLookup(event){
        this.tableData = [];
        this.tableDataComponents = [];
        this.tableDataAccessories = [];
        this.lastMachine = JSON.parse(JSON.stringify(this.BASE_MACHINE));
        this.machineLookup = event.target.checked;
    }
    changeParam(event){
        let fieldName = event.target.dataset.field;
        this.params[fieldName] = stringIsNotBlank(event.target.value) ? event.target.value : 0;
        this.recalcParams();
    }
    recalcParams(){
        // Calculate VAT, Net Amount
        this.params.vatAmount = this.params.totalNetAmount * (parseInt(VAT_PERCENT) / 100);
        this.params.totalGrossAmount = parseFloat((this.params.totalNetAmount + this.params.vatAmount).toFixed(2));
        this.params.adjustmentAmount = 0;
        if(this.surchargeCalculation && this.params.runtimeInMonths > 0 && this.coffeeAnnual > 0){
            this.params.adjustmentAmount = this.params.totalNetAmount / ((this.params.runtimeInMonths * this.coffeeAnnual) / 12);
        }

        // Calculate Percent Downpayment and Financing Amount
        this.params.downpaymentAmount = this.params.totalNetAmount * (parseInt(this.params.downpaymentPercent) / 100);
        this.params.downpaymentVatAmount = this.params.downpaymentAmount  + this.params.vatAmount;
        this.params.financingAmount = this.params.totalNetAmount - this.params.downpaymentAmount;

        // Calculate Financing
        let interestRate = parseInt(INTEREST_PERCENT);
        let totalWithinterest = this.calculateInterest(this.params.financingAmount, this.params.runtimeInMonths / 12, interestRate);
        this.params.monthlyRateAmount = this.params.runtimeInMonths == 0 ? 0 : Math.ceil(totalWithinterest / this.params.runtimeInMonths);
        this.params.finalMonthlyRateAmount = this.params.runtimeInMonths == 0 ? 0 : (totalWithinterest - (this.params.monthlyRateAmount * (this.params.runtimeInMonths - 1)));
        /*this.params.monthlyRateAmount = this.params.runtimeInMonths == 0 ? 0 : Math.ceil(this.params.financingAmount / this.params.runtimeInMonths);
        this.params.finalMonthlyRateAmount = this.params.runtimeInMonths == 0 ? 0 : (this.params.financingAmount - (this.params.monthlyRateAmount * (this.params.runtimeInMonths - 1)));*/

        // Displayed Values
        this.params.vatAmountDisplay = this.twoDigitize(this.params.vatAmount);
        this.params.totalGrossAmountDisplay = this.twoDigitize(this.params.totalGrossAmount);
        this.params.financingAmountDisplay = this.twoDigitize(this.params.financingAmount);
        this.params.monthlyRateAmountDisplay = this.twoDigitize(this.params.monthlyRateAmount);
        this.params.finalMonthlyRateAmountDisplay = this.twoDigitize(this.params.finalMonthlyRateAmount);
        this.params.adjustmentAmountDisplay = this.twoDigitize(this.params.adjustmentAmount);
        this.params.downpaymentAmountDisplay = this.twoDigitize(this.params.downpaymentAmount);
        this.params.downpaymentVatAmountDisplay = this.twoDigitize(this.params.downpaymentVatAmount);
    }
    calculateInterest(total, years, ratePercent) {
        let interestRate = ((ratePercent / 100) + 1);
        return parseFloat((total * Math.pow(interestRate, years)).toFixed(2));
      }
      
    recalcSpecialMachine(event){
        let field = event.target.dataset.field;
        let index = event.target.dataset.index;
        let value = event.target.value;
        this.recalcSpecialMachineGeneral(index, field, value);
    }
    recalcSpecialMachineGeneral(index, field, value){
        this.specialMachines.forEach(machine => {
            if(index == null || machine.index == index){
                if(stringIsNotBlank(field) && stringIsNotBlank(value)){
                    machine[field] = stringIsNotBlank(value) ? value : 0;
                }
                machine.hasMaxDiscountOneViolation = false;
                machine.hasMaxDiscountTwoViolation = false;
                machine.price = machine.price ?? 0;
                machine.discount = machine.discount ?? 0;
                machine.specialDiscount = machine.specialDiscount ?? 0;
                machine.quantity = machine.quantity ?? 1;
                machine.discountAmount = (parseFloat(machine.price) * ((parseFloat(machine.discount) / 100))) + ((parseFloat(machine.price) * (1 - (parseFloat(machine.discount) / 100))) * (parseFloat(machine.specialDiscount) / 100) );
                let discountAmountHypothetical = (parseFloat(machine.price) * ((parseFloat(machine.maxDiscountOne ?? 0) / 100))) + 
                                                    (machine.secondDiscountPossible ? ((parseFloat(machine.price) * (1 - (parseFloat(machine.maxDiscountOne ?? 0) / 100))) * (parseFloat(machine.maxDiscountTwo ?? 0) / 100) ) : 0);
                machine.salePrice = machine.price - machine.discountAmount;
                let salePriceHypothetical = machine.price - discountAmountHypothetical;
                machine.rowTotal = machine.salePrice * parseInt(machine.quantity);
                machine.rowTotalAllDiscount = salePriceHypothetical * parseInt(machine.quantity);
                machine.priceDisplay = this.twoDigitize(machine.price);
                machine.salePriceDisplay = this.twoDigitize(machine.salePrice);
                machine.rowTotalDisplay = this.twoDigitize(machine.rowTotal);
                machine.discountAmountDisplay = this.twoDigitize(machine.discountAmount);
            }
        });
    }
    recalcBaseMachine(event){
        let field = event.target.dataset.field;
        let index = event.target.dataset.index;
        this.recalcBaseMachineGeneral(true, index, field, event.target.value);
    }
    recalcBaseMachineGeneral(withRecalcAll, index, field, value){
        this.machines.forEach(machine => {
            if(index == null || machine.index == index){
                if(stringIsNotBlank(field) && stringIsNotBlank(value)){
                    machine[field] = stringIsNotBlank(value) ? value : 0;
                }

                if(machine.discountable || this.additionalDiscountBaseMachine != null || this.temporaryDiscountBaseMachine != null){
                    this.machineMaxDiscount = machine.hasMaxDiscountOne ? machine.maxDiscountOne : null;
                    machine.hasMaxDiscountOneViolation = machine.hasMaxDiscountOne && stringIsNotBlank(machine.discount) && parseFloat(machine.discount) > machine.maxDiscountOne;
                    machine.hasMaxDiscountTwoViolation = machine.hasMaxDiscountTwo && stringIsNotBlank(machine.specialDiscount) && parseFloat(machine.specialDiscount) > machine.maxDiscountTwo;
                    this.params.hasAccessoireDiscountViolation = this.params.hasAccessoireDiscountViolation === true || machine.hasMaxDiscountOneViolation === true || machine.hasMaxDiscountTwoViolation === true;
                    
                    machine.discountAmount = (parseFloat(machine.price ?? 0) * ((parseFloat(machine.discount ?? 0) / 100))) + ((parseFloat(machine.price ?? 0) * (1 - (parseFloat(machine.discount ?? 0) / 100))) * (parseFloat(machine.specialDiscount ?? 0) / 100) );
                    let discountAmountHypothetical = this.temporaryDiscountBaseMachine != null && this.temporaryDiscountBaseMachine > 0 ? 
                        (parseFloat(machine.price ?? 0) * (parseFloat(this.temporaryDiscountBaseMachine ?? 0) / 100)) :
                        (parseFloat(machine.price ?? 0) * (parseFloat(machine.maxDiscountOne ?? 0) / 100)) + 
                        (parseFloat(machine.price ?? 0) * (1 - (parseFloat(machine.maxDiscountOne ?? 0) / 100)) * (parseFloat(machine.maxDiscountTwo ?? 0) / 100) ) +
                        (parseFloat(machine.price ?? 0) * (1 - (parseFloat(machine.maxDiscountOne ?? 0) / 100)) *  (1 - (parseFloat(machine.maxDiscountTwo ?? 0) / 100)) ) * (parseFloat(this.additionalDiscountBaseMachine ?? 0) / 100);
                    machine.salePrice = machine.price - machine.discountAmount;
                    let salePriceHypothetical = machine.price - discountAmountHypothetical;
                    machine.rowTotal = machine.salePrice * parseInt(machine.quantity);
                    machine.rowTotalAllDiscount = salePriceHypothetical * parseInt(machine.quantity);
                    machine.priceDisplay = this.twoDigitize(machine.price);
                } else {
                    machine.hasMaxDiscountOneViolation = false;
                    machine.hasMaxDiscountTwoViolation = false;
                    machine.discountAmount = 0;
                    machine.salePrice = row.price;
                    machine.rowTotal = row.price * parseInt(row.quantity);
                    machine.rowTotalAllDiscount = row.price * parseInt(row.quantity);
                }
                machine.salePriceDisplay = this.twoDigitize(machine.salePrice);
                machine.rowTotalDisplay = this.twoDigitize(machine.rowTotal);
                machine.discountAmountDisplay = this.twoDigitize(machine.discountAmount);
                machine.accessoires.forEach(row => {
                    if(row != null){
                        if(row.discountable && row.discountCorrespondsToBaseDevice){
                            if(row.discount != machine.discount){
                                row.discount = machine.discount;
                            }
                            if(row.secondDiscountPossible && row.specialDiscount != machine.specialDiscount){
                                row.specialDiscount = machine.specialDiscount;
                            }
                        }
                        if(field == 'quantity'){
                            changed = true;
                            row.quantity = machine.quantity;
                        }
                    }
                });
                this.recalcAccessoiresGeneral(withRecalcAll, machine.index);
            }
        });
    }
    recalcAccessoires(event){
        let productid = event.target.dataset.productid;
        let field = event.target.dataset.field;
        let index = event.target.dataset.index;
        let i = 0;
        this.machines.forEach(machine => {
            if(machine.index == index){
                machine.accessoires.forEach(row => {
                    if(row != null){
                        if(row.id == productid){
                            row[field] = stringIsNotBlank(event.target.value) ? event.target.value : 0;
                            this.recalcAccessoiresGeneral(true, machine.index);
                            return;
                        }
                    }
                });
            }
            i++;
        });
    }
    recalcAccessoiresGeneral(withRecalcAll, machineIndex){
        this.machines.forEach(machine => {
            if(machineIndex == null || machine.index == machineIndex){
                machine.accessoires.forEach(row => {
                    if(row != null){
                        if(
                            row.discountable || 
                            (row.isComponent && (this.additionalDiscountBaseComponent != null || this.temporaryDiscountBaseComponent != null)) ||
                            (!row.isComponent && (this.additionalDiscountAccessories != null || this.temporaryDiscountAccessories != null))
                        ){
                            row.hasMaxDiscountOneViolation = row.hasMaxDiscountOne && stringIsNotBlank(row.discount) && parseFloat(row.discount) > row.maxDiscountOne;
                            row.hasMaxDiscountTwoViolation = row.hasMaxDiscountTwo && stringIsNotBlank(row.specialDiscount) && parseFloat(row.specialDiscount) > row.maxDiscountTwo;
                            this.params.hasAccessoireDiscountViolation = this.params.hasAccessoireDiscountViolation === true || row.hasMaxDiscountOneViolation === true || row.hasMaxDiscountTwoViolation === true;
                            
                            row.discountAmount = (parseFloat(row.price ?? 0) * ((parseFloat(row.discount ?? 0) / 100))) + ((parseFloat(row.price ?? 0) * (1 - (parseFloat(row.discount ?? 0) / 100))) * (parseFloat(row.specialDiscount ?? 0) / 100) );
                            let discountAmountHypothetical = 0;
                            if(row.isComponent){
                                discountAmountHypothetical = this.temporaryDiscountBaseComponent != null && this.temporaryDiscountBaseComponent > 0 ? 
                                    (parseFloat(row.price ?? 0) * (parseFloat(this.temporaryDiscountBaseComponent  ?? 0) / 100)) :
                                    (parseFloat(row.price ?? 0) * ((parseFloat(machine.maxDiscountOne ?? 0) / 100))) + 
                                    (machine.secondDiscountPossible && row.secondDiscountPossible ? ((parseFloat(row.price ?? 0) * (1 - (parseFloat(machine.maxDiscountOne ?? 0) / 100))) * (parseFloat(machine.maxDiscountTwo ?? 0) / 100) ) : 0) +
                                    (parseFloat(row.price ?? 0) * (1 - (parseFloat(machine.maxDiscountOne ?? 0) / 100)) *  (machine.secondDiscountPossible && row.secondDiscountPossible ? (1 - (parseFloat(machine.maxDiscountTwo ?? 0) / 100)) : 1) ) * (parseFloat(this.additionalDiscountBaseComponent ?? 0) / 100);
                            } else {
                                discountAmountHypothetical = this.temporaryDiscountAccessories != null && this.temporaryDiscountAccessories > 0 ? 
                                    (parseFloat(row.price ?? 0) * (parseFloat(this.temporaryDiscountAccessories  ?? 0) / 100)) :
                                    (parseFloat(row.price ?? 0) * ((parseFloat(machine.maxDiscountOne ?? 0) / 100))) + 
                                    (machine.secondDiscountPossible && row.secondDiscountPossible ? ((parseFloat(row.price ?? 0) * (1 - (parseFloat(machine.maxDiscountOne ?? 0) / 100))) * (parseFloat(machine.maxDiscountTwo ?? 0) / 100) ) : 0) +
                                    (parseFloat(row.price ?? 0) * (1 - (parseFloat(machine.maxDiscountOne ?? 0) / 100)) *  (machine.secondDiscountPossible && row.secondDiscountPossible ? (1 - (parseFloat(machine.maxDiscountTwo ?? 0) / 100)) : 1) ) * (parseFloat(this.additionalDiscountAccessories ?? 0) / 100);
                            }
                
                            row.salePrice = row.price - row.discountAmount;
                            let salePriceHypothetical = row.price - discountAmountHypothetical;
                            row.rowTotal = row.salePrice * parseInt(row.quantity);
                            row.rowTotalAllDiscount = salePriceHypothetical * parseInt(row.quantity);
                        } else {
                            row.hasMaxDiscountOneViolation = false;
                            row.hasMaxDiscountTwoViolation = false;
                            row.discountAmount = 0;
                            row.salePrice = row.price;
                            row.rowTotal = row.price * parseInt(row.quantity);
                            row.rowTotalAllDiscount = row.price * parseInt(row.quantity);
                        }
                        row.priceDisplay = this.twoDigitize(row.price);
                        row.salePriceDisplay = this.twoDigitize(row.salePrice);
                        row.rowTotalDisplay = this.twoDigitize(row.rowTotal);
                    }
                });
            }
        });
        if(withRecalcAll){
            this.recalcTotal();
        }
    }
    recalcTotal(){
        let totalNetAmount = 0;
        let totalNetAmountAllDiscount = 0;
        let totalNetAmountMachine = 0;
        let totalNetAmountAccessoires = 0;
        let totalNetAmountNoDiscount = 0;
        let totalNetAmountNoDiscountMachine = 0;
        let totalNetAmountNoDiscountAccessoires = 0;
        this.machines.forEach(machine => {
            let machineTotalNetAmount = 0;
            totalNetAmount += parseFloat(machine.rowTotal ?? 0);
            machineTotalNetAmount += parseFloat(machine.rowTotal ?? 0);
            totalNetAmountAllDiscount += parseFloat(machine.rowTotalAllDiscount ?? 0);
            totalNetAmountNoDiscount += parseFloat(machine.price ?? 0) * parseInt(machine.quantity ?? 0);
            machine.accessoires.forEach(accessoire => {
                if(accessoire != null){
                    totalNetAmount += parseFloat(accessoire.rowTotal ?? 0);
                    machineTotalNetAmount += parseFloat(accessoire.rowTotal ?? 0);
                    totalNetAmountAccessoires += parseFloat(accessoire.rowTotal ?? 0);
                    totalNetAmountAllDiscount += parseFloat(accessoire.rowTotalAllDiscount ?? 0);
                    totalNetAmountNoDiscount += parseFloat(accessoire.price ?? 0) * parseInt(accessoire.quantity ?? 0);
                    totalNetAmountNoDiscountAccessoires += parseFloat(accessoire.price ?? 0) * parseInt(accessoire.quantity ?? 0);
                }
            });
            machine.totalNetAmount = machineTotalNetAmount;
            machine.totalNetAmountDisplay = this.twoDigitize(machine.totalNetAmount);
        });
        this.specialMachines.forEach(specialMachine => {
            let machineTotalNetAmount = 0;
            totalNetAmount += parseFloat(specialMachine.rowTotal ?? 0);
            machineTotalNetAmount += parseFloat(specialMachine.rowTotal ?? 0);
            totalNetAmountAllDiscount += parseFloat(specialMachine.rowTotalAllDiscount ?? 0);
            totalNetAmountNoDiscount += parseFloat(specialMachine.price ?? 0) * parseInt(specialMachine.quantity ?? 0);
            specialMachine.totalNetAmount = machineTotalNetAmount;
            specialMachine.totalNetAmountDisplay = this.twoDigitize(specialMachine.totalNetAmount);
        });
        this.params.totalNetAmount = totalNetAmount;
        this.params.totalNetAmountDisplay = this.twoDigitize(this.params.totalNetAmount);
        this.params.totalNetAmountMachine = totalNetAmountMachine;
        this.params.totalNetAmountMachineDisplay = this.twoDigitize(this.params.totalNetAmountMachine);
        this.params.totalNetAmountAccessoires = totalNetAmountAccessoires;
        this.params.totalNetAmountAccessoiresDisplay = this.twoDigitize(this.params.totalNetAmountAccessoires);
        this.params.totalNetAmountNoDiscount = totalNetAmountNoDiscount;
        this.params.totalNetAmountNoDiscountDisplay = this.twoDigitize(this.params.totalNetAmountNoDiscount);
        this.params.totalNetAmountNoDiscountMachine = totalNetAmountNoDiscountMachine;
        this.params.totalNetAmountNoDiscountMachineDisplay = this.twoDigitize(this.params.totalNetAmountNoDiscountMachine);
        this.params.totalNetAmountNoDiscountAccessoires = totalNetAmountNoDiscountAccessoires;
        this.params.totalNetAmountNoDiscountAccessoiresDisplay = this.twoDigitize(this.params.totalNetAmountNoDiscountAccessoires);
        this.params.totalDiscount = totalNetAmountNoDiscount - totalNetAmount;
        this.params.totalDiscountDisplay = this.twoDigitize(this.params.totalDiscount);
        this.params.totalDiscountPercent = totalNetAmountNoDiscount > 0 ? ((this.params.totalDiscount / totalNetAmountNoDiscount) * 100) : 0;
        this.params.totalRoasterDiscount = totalNetAmount - totalNetAmountAllDiscount;
        this.params.totalProducerDiscount = totalNetAmountNoDiscount - totalNetAmountAllDiscount;
        this.params.totalProducerDiscountPercent = totalNetAmountNoDiscount > 0 ? ((this.params.totalProducerDiscount / totalNetAmountNoDiscount) * 100) : 0;
        this.params.totalDiscountPercentDisplay = this.twoDigitizePercent(this.params.totalDiscountPercent);
        this.recalcParams();
    }
    
    handleBrandSearch(event){
        let searchParam = {
            parentObjectApiName: "Product2",
            lookupApiName: "BrandWebshop__c",
            searchTerm: event.detail.searchTerm,
            limitToObjectTypes: [],
            selectedIds: [],
            lookupFilters: [{objectType : 'WebshopBrand__c', filter : 'IsMachineBrand__c = TRUE'}],
            additionalFields: [],
            listIds: [],
            listIdsExclude: [],
            displayField: null
        };
        searchWithIds(searchParam)
        .then(results => {
            this.template
                .querySelector('[data-field="product"]')
                .setSearchResults(results);
        })
        .catch(error => {
            console.log(JSON.stringify(error, null, '\t'));
        });
    }

    handleBrandComboboxChange(event){
        this.brandId = stringIsNotBlank(event.target.value) && event.target.value != '-' ? event.target.value : null;
        this.recalcTableData();
    }

    handleBrandChange(event){
        if (event.target.selection && event.target.selection.length > 0) {
            event.target.selection.forEach(selection => {
                this.brandId = selection.id;
            })
        } else {
            this.brandId = null;
        }
        this.recalcTableData();
    }

    recalcTableData(){
        this.tableData = [];
        this.tableDataComponents = [];
        this.tableDataAccessories = [];
        if(stringIsNotBlank(this.brandId)){
            getProductsByBrand({brandId: this.brandId, standardPricebookEntries: this.standardPricebookEntries})
            .then(result => {
                this.tableData = result;
            })
        }
    }

    getAccessoiresByMachine(forwardToStepTwo){
        this.tableData = [];
        this.tableDataComponents = [];
        this.tableDataAccessories = [];
        if(stringIsNotBlank(this.lastMachine.id)){
            getAccessoiresByMachine({brandId: this.lastMachine.brandId, productSeries: this.lastMachine.productSeries, machineId: this.lastMachine.id, standardPricebookEntries: this.standardPricebookEntries, selectedItems: []})
            .then(result => {
                this.tableDataComponents = result.components;
                this.tableDataAccessories = result.accessories;
                if(forwardToStepTwo){
                    this.step = 2;
                }
            })
        }
    }

    handleChangeSpecialMachineField(event){
        let specialMachineIndex = event.target.dataset.index;
        let field = event.target.dataset.field;
        for(let i = 0; i < this.specialMachines.length; i++){
            if(this.specialMachines[i].index == specialMachineIndex){
                this.specialMachines[i][field] = event.target.value;
            }
        }
    }

    handleChangeAdditionalDiscountBaseMachine(event){
        this.additionalDiscountBaseMachine = event.target.value;
        this.temporaryDiscountBaseMachine = null;
    }

    handleChangeAdditionalDiscountBaseComponent(event){
        this.additionalDiscountBaseComponent = event.target.value;
        this.temporaryDiscountBaseComponent = null;
    }

    handleChangeAdditionalDiscountAccessories(event){
        this.additionalDiscountAccessories = event.target.value;
        this.temporaryDiscountAccessories = null;
    }
    
    handleChangeTemporaryDiscountBaseMachine(event){
        this.temporaryDiscountBaseMachine = event.target.value;
        this.additionalDiscountBaseMachine = null;
    }

    handleChangeTemporaryDiscountBaseComponent(event){
        this.temporaryDiscountBaseComponent = event.target.value;
        this.additionalDiscountBaseComponent = null;
    }

    handleChangeTemporaryDiscountAccessories(event){
        this.temporaryDiscountAccessories = event.target.value;
        this.additionalDiscountAccessories = null;
    }

    handleChangeSpecialMachinesPurchasePrice(event){
        this.specialMachinesPurchasePrice = event.target.value;
    }

    handleEditMachine(event){
        let machineIndex = event.target.dataset.index;
        let selectedAccessoires = [];
        for(let i = 0; i < this.machines.length; i++){
            if(this.machines[i].index == machineIndex){
                this.lastMachine = JSON.parse(JSON.stringify(this.machines[i]));
                this.machines.splice(i, 1);
                break;
            }
        }
        this.recalcTotal();
        if(stringIsNotBlank(this.lastMachine.id)){
            this.lastMachine.accessoires.forEach(accessoire => {
                if(accessoire.id){
                    selectedAccessoires.push(accessoire.id);
                }
            })
            this.lastMachine.accessoires = [];
            getAccessoiresByMachine({brandId: this.lastMachine.brandId, productSeries: this.lastMachine.productSeries, machineId: this.lastMachine.id, standardPricebookEntries: this.standardPricebookEntries, selectedItems: selectedAccessoires})
            .then(result => {
                this.tableDataComponents = result.components;
                this.tableDataAccessories = result.accessories;
                this.step = 2;
            })
        }
        this.step = 2;
    }

    handleDeleteMachine(event){
        let machineIndex = event.target.dataset.index;
        for(let i = 0; i < this.machines.length; i++){
            if(this.machines[i].index == machineIndex){
                this.machines.splice(i, 1);
                break;
            }
        }
        this.recalcTotal();
    }

    handleDeleteSpecialMachine(event){
        let machineIndex = event.target.dataset.index;
        for(let i = 0; i < this.specialMachines.length; i++){
            if(this.specialMachines[i].index == machineIndex){
                this.specialMachines.splice(i, 1);
                break;
            }
        }
        this.recalcTotal();
    }

    handleDeleteAccessoire(event){
        let machineIndex = event.target.dataset.index;
        let accessoireId = event.target.dataset.productid;
        for(let i = 0; i < this.machines.length; i++){
            if(this.machines[i].index == machineIndex){
                for(let j = 0; j < this.machines[i].accessoires.length; j++){
                    if(this.machines[i].accessoires[j].id == accessoireId){
                        this.machines[i].accessoires.splice(j, 1);
                        break;
                    }
                }
            }
        }
        this.recalcTotal();
    }

    handleRowSelection(event){
        this.lastMachine = event.detail.selectedRows.length > 0 ? event.detail.selectedRows[0] : JSON.parse(JSON.stringify(this.BASE_MACHINE));
        this.lastMachine.salePrice = this.lastMachine.price;
        this.lastMachine.rowTotal = this.lastMachine.salePrice;
        this.lastMachine.priceDisplay = this.twoDigitize(this.lastMachine.price);
        this.lastMachine.salePriceDisplay = this.twoDigitize(this.lastMachine.salePrice);
        this.lastMachine.rowTotalDisplay = this.twoDigitize(this.lastMachine.rowTotal);
        this.recalcTotal();
    }

    handleRowSelectionAccessoires(event){
        let accessoireSection = event.target.dataset.section;
        let machineAccessoires = JSON.parse(JSON.stringify(event.detail.selectedRows));
        this.lastMachine.accessoiresPre[accessoireSection] = [];
        machineAccessoires.forEach(row => {
            if(row != null){
                row.salePrice = row.price;
                row.rowTotal = row.salePrice;
                row.priceDisplay = this.twoDigitize(row.price);
                row.salePriceDisplay = this.twoDigitize(row.salePrice);
                row.rowTotalDisplay = this.twoDigitize(row.rowTotal);
                row.isComponent = false;
                this.lastMachine.accessoiresPre[accessoireSection].push(row);
            }
        });
        this.lastMachine.hasAccessoires = this.lastMachine.components && this.lastMachine.components.length > 0;
        if(!this.lastMachine.hasAccessoires){
            Object.keys(this.lastMachine.accessoiresPre).forEach(key => {
                if(this.lastMachine.accessoiresPre[key].length > 0){
                    this.lastMachine.hasAccessoires = true;
                }
            })
        }
    }

    handleRowSelectionComponents(event){
        let machineComponents = JSON.parse(JSON.stringify(event.detail.selectedRows));
        machineComponents.forEach(row => {
            row.salePrice = row.price;
            row.rowTotal = row.salePrice;
            row.priceDisplay = this.twoDigitize(row.price);
            row.salePriceDisplay = this.twoDigitize(row.salePrice);
            row.rowTotalDisplay = this.twoDigitize(row.rowTotal);
            row.isComponent = true;
        });
        this.lastMachine.components = machineComponents;
        this.lastMachine.hasAccessoires = this.lastMachine.components.length > 0;
        if(!this.lastMachine.hasAccessoires){
            Object.keys(this.lastMachine.accessoiresPre).forEach(key => {
                if(this.lastMachine.accessoiresPre[key].length > 0){
                    this.lastMachine.hasAccessoires = true;
                }
            })
        }
    }

    commitLastMachine(){
        this.lastIndex++;
        this.lastMachine.index = this.lastIndex;
        if(this.lastMachine.components){
            this.lastMachine.accessoires = JSON.parse(JSON.stringify(this.lastMachine.components));
        }
        if(this.lastMachine.accessoiresPre){
            Object.keys(this.lastMachine.accessoiresPre).forEach(key => {
                this.lastMachine.accessoires = this.lastMachine.accessoires.concat(this.lastMachine.accessoiresPre[key]);
            });
        }
        this.machines.push(this.lastMachine);
        this.lastMachine = JSON.parse(JSON.stringify(this.BASE_MACHINE));
        this.recalcBaseMachineGeneral(true, null, null, null);
    }

    /* Buttons */
    handleGoToStepTwo(event){
        this.getAccessoiresByMachine(true);
    }
    handleGoToStepOne(event){
        if(stringIsNotBlank(this.lastMachine.id)){
            this.commitLastMachine();
        }
        this.recalcTotal();
        this.tableData = [];
        this.tableDataComponents = [];
        this.tableDataAccessories = [];
        this.step = 1;
    }
    handleGoToStepThree(event){
        if(stringIsNotBlank(this.lastMachine.id)){
            this.commitLastMachine();
        }
        this.recalcTotal();        
        console.log(JSON.stringify(this.machines));
        console.log(JSON.stringify(this.specialMachines));
        this.step = 3;
    }
    handleGoToStepFour(event){
        if(this.params.hasAccessoireDiscountViolation || this.minDownPaymentBelow){
            this.showReasonModal = true;
        } 
        if(this.hasSpecialMachines){
            this.showSpecialMachinesTwoModal = true;
        } 
        if(this.hasExtraDiscount){
            this.showExtraDiscountModal = true;
        } 
        if(!this.showReasonModal && !this.showSpecialMachinesTwoModal && !this.showExtraDiscountModal) {
            this.step = 4;
        }
    }
    handleChangeExtraDiscount(event){
        this.hasExtraDiscount = event.target.checked;
    }
    handleChangeCampaign(event){
        this.params.discountViolationCampaign = event.target.value;
    }
    handleChangeDownPaymentReason(event){
        this.params.downPaymentViolationReason = event.target.value;
    }
    handleChangeReason(event){
        this.params.discountViolationReason = event.target.value;
    }
    handleOpenSpecialMachineModal(){
        this.specialMachineName = null;
        this.specialMachineDescription = null;
        this.specialMachinePrice = null;
        this.showSpecialMachineModal = true;
    }
    handleChangeSpecialMachineName(event){
        this.specialMachineName = event.target.value;
    }
    handleChangeSpecialMachineDescription(event){
        this.specialMachineDescription = event.target.value;
    }
    handleChangeSpecialMachinePrice(event){
        this.specialMachinePrice = event.target.value;
    }
    handleCloseSpecialMachineModal(){
        this.showSpecialMachineModal = false;
    }
    handleSaveSpecialMachineModal(){
        let specialMachine = JSON.parse(JSON.stringify(this.BASE_MACHINE));
        specialMachine.title = this.specialMachineName;
        specialMachine.description = this.specialMachineDescription;
        specialMachine.discountable = true;
        specialMachine.secondDiscountPossible = true;
        specialMachine.price = parseFloat(this.specialMachinePrice);
        specialMachine.specialMachinePrice = parseFloat(this.specialMachinePrice);
        this.specialMachines.push(specialMachine);
        this.recalcSpecialMachineGeneral(null, null, null);
        this.recalcTotal();
        this.specialMachineName = null;
        this.specialMachineDescription = null;
        this.specialMachinePrice = null;
        this.showSpecialMachineModal = false;
        this.step = 3;
    }
    handleCloseReasonModal(){
        this.additionalDiscountBaseMachine = null;
        this.additionalDiscountBaseComponent = null;
        this.additionalDiscountAccessories = null;
        this.temporaryDiscountBaseMachine = null;
        this.temporaryDiscountBaseComponent = null;
        this.temporaryDiscountAccessories = null;
        this.specialMachinesPurchasePrice = null;
        this.showReasonModal = false;
        this.showExtraDiscountModal = false;
        this.showSpecialMachinesTwoModal = false;
    }
    handleSaveReasonModal(){        
        this.recalcBaseMachineGeneral(true, null, null, null);
        this.showReasonModal = false;
        this.showExtraDiscountModal = false;
        this.showSpecialMachinesTwoModal = false;
        this.step = 4;
    }
    handleFinish(event){
        if(this.fromConfigurator){
            const changeEvent = new CustomEvent('confirm', {
                detail: {
                    machines: this.machines,
                    specialMachines: this.specialMachines,
                    surchargeCalculation: this.surchargeCalculation,
                    params: this.params
                }
            });
            this.dispatchEvent(changeEvent);
            this.step++;
        } else {
            createOffer({
                opportunityId: this.opportunityId,
                machines: JSON.stringify(this.machines),
                specialMachines: JSON.stringify(this.specialMachines),
                params: this.params,
                existingQuoteId: this.quoteId,
                surchargeCalculation: this.surchargeCalculation,
                additionalDiscountBaseMachine: stringIsNotBlank(this.additionalDiscountBaseMachine) ? this.additionalDiscountBaseMachine : null,
                additionalDiscountBaseComponent: stringIsNotBlank(this.additionalDiscountBaseComponent) ? this.additionalDiscountBaseComponent : null,
                additionalDiscountAccessories: stringIsNotBlank(this.additionalDiscountAccessories) ? this.additionalDiscountAccessories : null,
                temporaryDiscountBaseMachine: stringIsNotBlank(this.temporaryDiscountBaseMachine) ? this.temporaryDiscountBaseMachine : null,
                temporaryDiscountBaseComponent: stringIsNotBlank(this.temporaryDiscountBaseComponent) ? this.temporaryDiscountBaseComponent : null,
                temporaryDiscountAccessories: stringIsNotBlank(this.temporaryDiscountAccessories) ? this.temporaryDiscountAccessories : null,
                specialMachinesPurchasePrice: this.specialMachinesPurchasePrice
            }).then(result => {
                if(result != null){
                    if(this.fromQuote && stringIsNotBlank(this.quoteId) && this.quoteId.includes(result)){
                        const evt = new ShowToastEvent({
                            title: this.label.success,
                            message: this.label.quoteUpdatedRefreshing,
                            variant: 'success',
                        });
                        this.dispatchEvent(evt);
                        this.reset();
                        this.close();
                        let self = this;
                        setTimeout(() => {
                            self[NavigationMixin.Navigate]({
                                type: "standard__recordPage",
                                attributes: {
                                    recordId: self.quoteId,
                                    objectApiName: "Quote",
                                    actionName: "view",
                                },
                            });
                        }, 500);
                    } else {
                        this.close();
                        const evt = new ShowToastEvent({
                            title: this.label.success,
                            message: this.label.quoteCreated,
                            messageData: [{
                                url: '/' + result,
                                label: this.label.seeItHere
                            }],
                            variant: 'success',
                        });
                        this.dispatchEvent(evt);
                    }
                } else {
                    const evt = new ShowToastEvent({
                      title: this.label.error,
                      message: this.label.error,
                      variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
            })
        }
    }

    twoDigitizeOptions = {
        style: "currency",
        currency: "EUR"
    };
    twoDigitizeOptionsAlt = {
        style: "percent",
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    };

    twoDigitize(value){
        return parseFloat(parseFloat(value).toFixed(2)).toLocaleString("de-DE", this.twoDigitizeOptions);
    }

    twoDigitizePercent(value){
        return parseFloat(parseFloat(value / 100).toFixed(4)).toLocaleString("de-DE", this.twoDigitizeOptionsAlt);
    }
}
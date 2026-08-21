import { LightningElement, api, track } from 'lwc';

// LABELS
import noProducts from '@salesforce/label/c.WebshopCartNoProducts';
import shippingProductCodes from '@salesforce/label/c.ShippingProductCodes';
import checkout from '@salesforce/label/c.WebshopCheckout';
import errorDesc from '@salesforce/label/c.WebshopOrderConfirmationErrorDesc';
import shipping from '@salesforce/label/c.WebshopOrderConfirmationShipping';
import subtotal from '@salesforce/label/c.WebshopOrderConfirmationSubtotal';
import totalTax from '@salesforce/label/c.WebshopOrderConfirmationTotalTax';
import total from '@salesforce/label/c.WebshopOrderConfirmationTotal';
import free from '@salesforce/label/c.GeneralFree';
import emptyCart from '@salesforce/label/c.WebshopEmptyCart';
import genericPaymentTerms from '@salesforce/label/c.WebshopGenericPaymentTerms';
import shippingCostsWithPricesOne from '@salesforce/label/c.WebshopShippingCostsWithPricesOne';
import shippingCostsWithPricesTwo from '@salesforce/label/c.WebshopShippingCostsWithPricesTwo';
import shippingCostsWithoutPrices from '@salesforce/label/c.WebshopShippingCostsWithoutPrices';
import shippingCost from '@salesforce/label/c.WebshopDoNotTranslateShippingCost';
import shippingFreeThreshold from '@salesforce/label/c.WebshopDoNotTranslateShippingFreeThreshold';
import promotions from '@salesforce/label/c.GeneralPromotions';
import maxBoxCount from '@salesforce/label/c.WebshopDoNotTranslateMaxBoxCount';
import maxPaletteCount from '@salesforce/label/c.WebshopDoNotTranslateMaxPaletteCount';
import box from '@salesforce/label/c.GeneralBox';
import boxes from '@salesforce/label/c.GeneralBoxes';
import palette from '@salesforce/label/c.GeneralPalette';
import palettes from '@salesforce/label/c.GeneralPalettes';
import piece from '@salesforce/label/c.GeneralPiece';
import paymentTerms from '@salesforce/label/c.WebshopPaymentTerms';
import paymentTermsLineOne from '@salesforce/label/c.WebshopPaymentTermsLineOne';
import paymentTermsLineTwo from '@salesforce/label/c.WebshopPaymentTermsLineTwo';
import amountPayableEarly from '@salesforce/label/c.WebshopPaymentTermsAmountPayableEarly';
import quantity from '@salesforce/label/c.WebshopQuantity';

export default class WebshopOrderSimulationSummary extends LightningElement {

    label = {
        noProducts,
        checkout,
        shippingProductCodes,
        shipping,
        subtotal,
        total,
        free,
        emptyCart,
        shippingCostsWithPricesOne,
        shippingCostsWithPricesTwo,
        shippingCostsWithoutPrices,
        shippingCost,
        shippingFreeThreshold,
        promotions,
        maxBoxCount,
        maxPaletteCount,
        box,
        boxes,
        palette,
        palettes,
        piece,
        totalTax,
        paymentTerms,
        paymentTermsLineOne,
        paymentTermsLineTwo,
        amountPayableEarly,
        errorDesc,
        genericPaymentTerms,
        quantity
    }

    @api erpResult;
    @api showPrices;

    @track erpFailed = false;
    @track erpSucceeded = false;
    @track paymentTermsLineOne = null;
    @track paymentTermsLineTwo = null;
    @track errorLoggingId = null;
    @track readyLoaded = false;
    @track hasPromotions = false;
    @track promotionsTotal = 0;
    @track _erpResult = {};

    roundToTwo(value) {
        // Return as-is if null or not a number
        if (value === null || typeof value !== "number" || !isFinite(value)) {
            return value;
        }

        return new Intl.NumberFormat(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    connectedCallback(){
        this._erpResult = JSON.parse(JSON.stringify(this.erpResult));
        this.erpSucceeded = this._erpResult.success === true;
        this.erpFailed = this._erpResult.success === false;
        this.errorLoggingId = this._erpResult.errorLoggingId;
        if(this.erpSucceeded){
            this._erpResult.TotalCartAmountRounded = this.roundToTwo(this._erpResult.totalCartAmount);
            if(this._erpResult.hasSuccessfulItems){
                this._erpResult.order.ShippingCostsRounded = this.roundToTwo(this._erpResult.order.ShippingCosts__c);
                this._erpResult.order.TotalAmountRounded = this.roundToTwo(this._erpResult.order.TotalAmount);
                this._erpResult.order.GrandTotalAmountRounded = this.roundToTwo(this._erpResult.order.GrandTotalAmount);
                this._erpResult.order.TotalTaxAmountRounded = this.roundToTwo(this._erpResult.order.TotalTaxAmount);
                this._erpResult.order.GrandTotalAmountDiscount = 0;
                this._erpResult.order.GrandTotalAmountDiscountRounded = 0;
                this._erpResult.order.GrandTotalAmountAfterDiscount = this._erpResult.order.GrandTotalAmount;
                this._erpResult.order.GrandTotalAmountAfterDiscountRounded = this._erpResult.order.GrandTotalAmountRounded;
                if(this._erpResult.hasPaymentTerms){
                    this._erpResult.order.GrandTotalAmountDiscount = (this._erpResult.paymentTermsPercent / 100) * this._erpResult.order.GrandTotalAmount;
                    this._erpResult.order.GrandTotalAmountDiscountRounded = this.roundToTwo(this._erpResult.order.GrandTotalAmountDiscount);
                    this._erpResult.order.GrandTotalAmountAfterDiscount = this._erpResult.order.GrandTotalAmount - this._erpResult.order.GrandTotalAmountDiscount;
                    this._erpResult.order.GrandTotalAmountAfterDiscountRounded = this.roundToTwo(this._erpResult.order.GrandTotalAmountAfterDiscount);
                }
                this.paymentTermsLineOne = this.label.paymentTermsLineOne.replace('xxxxx', (this._erpResult.paymentTermsPercent ?? 0).toString()).replace('yyyyy', (this._erpResult.paymentTermsDays ?? 0).toString())
                this.paymentTermsLineTwo = this.label.paymentTermsLineTwo.replace('xxxxx', (this._erpResult.paymentTermsPercent ?? 0).toString()).replace('yyyyy', this._erpResult.order.GrandTotalAmountRounded).replace('zzzzz', this._erpResult.order.CurrencyIsoCode);
                this._erpResult.successfulItems.forEach(item => {
                    if(item.cartItem){
                        item.cartItem.TotalLineAmountRounded = 0;
                        if(item.cartItem.TotalLineAmount){
                            item.cartItem.TotalLineAmountRounded = this.roundToTwo(item.cartItem.TotalLineAmount);
                        }
                        if(item.cartItem.TotalPromoAdjustmentAmount != null && item.cartItem.TotalPromoAdjustmentAmount < 0){
                            this.promotionsTotal += (item.cartItem.TotalPromoAdjustmentAmount * -1);
                            this.hasPromotions = true;
                        }
                    } 
                    if(item.orderItem){
                        item.orderItem.TotalPriceRounded = 0;
                        item.orderItem.UnitPriceRounded = 0;
                        if(item.orderItem.TotalPrice){
                            item.orderItem.TotalPriceRounded = this.roundToTwo(item.orderItem.TotalPrice);
                        }
                        if(item.orderItem.UnitPrice && item.orderItem.UnitPrice != null){
                            item.orderItem.UnitPriceRounded = this.roundToTwo(item.orderItem.UnitPrice);
                        }
                    }
                })
                this._erpResult.taxItems.forEach(item => {
                    item.hasTax = item.taxTotalAmount > 0;
                    if(item.taxRate){
                        item.taxRateRounded = this.roundToTwo(item.taxRate);
                    }
                    if(item.taxTotalAmount){
                        item.taxTotalAmountRounded = this.roundToTwo(item.taxTotalAmount);
                    }
                })
            }
        }
        this.readyLoaded = true;
    }
}
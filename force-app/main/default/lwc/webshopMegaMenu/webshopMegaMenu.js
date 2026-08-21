import { LightningElement, api, track } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// APEX
import getMegaMenu from '@salesforce/apex/WebshopDataController.getMegaMenu';
import getInterimMegaMenu from '@salesforce/apex/WebshopDataController.getInterimMegaMenu';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Labels
import perColumn from '@salesforce/label/c.WebshopMegaMenuRowsPerColumn';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMegaMenu extends LightningElement {
    @api megaMenuName;
    @track accountId;
    @track megaMenuElements = [];
    @track brands = [];
    @track hasBrands = false;
    @track isTemporary = true;

    handleHoverSecondLevel(event) {
        const targetId = event.currentTarget.dataset.recordid;
         // Find all <li> elements within the second-level menu
         const allItems = this.template.querySelectorAll('.mega-menu-second-level .show');

         // Remove the class from all <li> elements
         allItems.forEach(item => {
             item.classList.remove('category-label-active');
             item.classList.add('category-label');
         });
 
         // Add the class to the parent <li> of the hovered <a> element
         const hoveredItem = event.currentTarget.closest('li');
         if (hoveredItem) {
             hoveredItem.classList.add('category-label-active');
             hoveredItem.classList.remove('category-label');
         } 

        this.template.querySelectorAll('.mega-menu-third-level-main').forEach(element => {
            element.style.display = 'none';
        });
        this.template.querySelectorAll('.mega-menu-third-level-featured').forEach(element => {
            element.style.display = 'none';
        });
        this.template.querySelectorAll('.third-level-featured-ad').forEach(element => {
            element.style.display = 'none';
        });
        this.template.querySelectorAll('[data-thirdmain="' + targetId + '"]').forEach(element => {
            element.style.display = '';
        });
        this.template.querySelectorAll('[data-thirdfeatured="' + targetId + '"]').forEach(element => {
            element.style.display = '';
        });
        this.template.querySelectorAll('[data-thirdad="' + targetId + '"]').forEach(element => {
            element.style.display = '';
        });
    }

    @api
    closeDropdown(){
        this.template.querySelectorAll('.dropdown').forEach(element => {
            element.style.display = 'none';
        });
        this.template.querySelector('.overlay').style.display = 'none';
    }

    handleDropdown(event){
        // Prevent event from bubbling up if it's a click on the icon
        event.stopPropagation();
        const targetId = event.currentTarget.dataset.recordid;
        this.template.querySelectorAll('.dropdown').forEach(element => {
            element.style.display = 'none';
        });
        this.template.querySelectorAll('[data-dropdownid="' + targetId + '"]').forEach(element => {
            element.style.display = '';
        });
        this.template.querySelector('.overlay').style.display = '';
    }
    
    label = {
        perColumn,
        generalError,
        generalErrorMsg
    }

    get brandStyle() {
        if (window.innerWidth < 992) {
            return '';
        }

        const columns = Math.ceil(this.brands.length / parseInt(this.label.perColumn));
        const width = columns < 4 ? `${columns * 25}%` : '100%';

        return `height: 20rem; overflow: hidden; columns: ${columns}; max-width: 100% !important; width: ${width} !important; flex: unset;`;

       
    }    

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;                
                let headerData = sessionStorage.getItem('darboven_headerData');
                if(!stringIsNotBlank(headerData)){
                    getInterimMegaMenu({megaMenuName : this.megaMenuName, accountId: this.accountId})
                    .then(outerResult => {
                        this.megaMenuElements = outerResult.wrappers;
                        this.brands = outerResult.brands;
                        this.hasBrands = outerResult.hasBrands;
                        getMegaMenu({
                            megaMenuName : this.megaMenuName,
                            accountId: this.accountId,
                            prefix: '/category/',
                            prefixNew: '/category-new-products?categoryid=',
                            prefixFeatured: '/category-featured-products?categoryid=',
                            prefixBrand: '/webshopbrand/'
                        })
                        .then(result => {
                            sessionStorage.setItem('darboven_headerData', JSON.stringify(result));
                            this.initData(result);
                        })
                        .catch(error => {
                            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                                title: this.label.generalError,
                                message: this.label.generalErrorMsg + ': ' + error,
                                variant: 'error',
                            };
                            this.template.querySelector('c-webshop-toast').show = true;}); 
                        });
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
                    this.initData(JSON.parse(headerData));
                }
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
    initData(result){
        if(result != null){
            this.megaMenuElements = result.wrappers;
            this.brands = result.brands;
            this.hasBrands = result.hasBrands;
            this.isTemporary = false;
        } else {
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        }
    }
}
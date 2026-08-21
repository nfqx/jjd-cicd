import { LightningElement , api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';


// Labels
import home from '@salesforce/label/c.GeneralHome';

export default class WebshopBreadcrumbs extends NavigationMixin(LightningElement) {
    @api path;
    @api lastElement;

    label = {
        home
    };

    handleClickHome(){
        window.location.assign('/');
    }
    connectedCallback(){
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
    }

    handleForward(event){
        let type = event.currentTarget.dataset.type;
        let target = event.currentTarget.dataset.target;
        if(type == 'Category'){
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    recordId: target,
                    objectApiName: "ProductCategory",
                    actionName: "view",
                },
            })
            .then(url => {
                window.location.replace(url);
            });
        } else if(type == 'Brand'){
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    recordId: target,
                    objectApiName: "WebshopBrand__c",
                    actionName: "view",
                },
            })
            .then(url => {
                window.location.replace(url);
            });
        } 
    }
}
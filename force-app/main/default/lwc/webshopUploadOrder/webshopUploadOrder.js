import { LightningElement, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Core
import { getSessionContext } from 'commerce/contextApi';

// Labels
import uploadOrder from '@salesforce/label/c.WebshopUploadOrder';
import uploadOrderDetail from '@salesforce/label/c.WebshopUploadOrderDetail';

// Apex
import uploadCsvFile from '@salesforce/apex/WebshopDataController.uploadCsvFile';

export default class WebshopUploadOrder extends LightningElement {
    @track isLoading = false;
    @track accountId = null;

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
            } else {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
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

    label = {
        uploadOrder,
        uploadOrderDetail
    };

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) {
            return;
        }
        if (!file.name.toLowerCase().endsWith('.csv')) {
            // Optional: show toast instead
            console.error('Please select a CSV file.');
            return;
        }
        this.readFile(file);
    }

    readFile(file) {
        const reader = new FileReader();
        reader.onload = async () => {
            const csvContent = reader.result;
            this.isLoading = true;
            try {
                const result = await uploadCsvFile({
                    accountId: this.accountId,
                    csvContent: csvContent
                });
                console.log('Upload successful', result);
            } catch (error) {
                console.error('Upload failed', error);
            } finally {
                this.isLoading = false;
            }
        };
        reader.onerror = () => {
            console.error('Failed to read file.');
        };
        reader.readAsText(file);
    }
}
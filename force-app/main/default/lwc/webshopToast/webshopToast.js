import { LightningElement, track, api } from 'lwc';

export default class WebshopToast extends LightningElement {
    @track _show = false;  
    @track _toast = {
        title: 'Title',
        message: 'Message',
        variant: 'error'
    };

    @api
    get toast() {
        return this._toast;
    }
    set toast(value) {
        this._toast = value;
    }

    @api
    get show() {
        return this._show;
    }
    set show(value) {
        this._show = value;
        if(value == true){
            let self = this;
            setTimeout(() => {
                self._show = false;
            }, 3000);
        }
    }

    get toastStyle(){
        return this._toast.variant == 'error' ? 'slds-notify slds-notify_toast slds-theme_error' : 'slds-notify slds-notify_toast slds-theme_success';
    }
}
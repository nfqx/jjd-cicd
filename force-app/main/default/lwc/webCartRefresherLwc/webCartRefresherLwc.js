import { LightningElement, track } from 'lwc';
import checkLetterCustomer from '@salesforce/apex/WebCartTriggerHandler.checkLetterCustomer';

export default class WebCartRefresherLwc extends LightningElement {
    isWebshopCustomer = null;
    connectedCallback() {
        if(this.isWebshopCustomer == null){
            checkLetterCustomer()
            .then(result => {
                this.isWebshopCustomer = result;
                if(result == true){
                    window.setTimeout(function(){
                        eval("$A.get('e.force:refreshView').fire()");
                    }, 5000);
                }
            })
        } else if(this.isWebshopCustomer == true){
            window.setTimeout(function(){
                eval("$A.get('e.force:refreshView').fire()");
            }, 5000);
        }
    }
 
    /*
    handleSubscribe() {
        const messageCallback = function (response) {
            console.log('New message received 1: ', JSON.stringify(response));
        };
 
        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }
    */

}
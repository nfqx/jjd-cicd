import { LightningElement, api, track } from 'lwc';

import rightGranted from '@salesforce/label/c.ChainRightsGranted';
import rightEndsHere from '@salesforce/label/c.ChainRightsEndsHere';
import rightRemoved from '@salesforce/label/c.ChainRightsRemoved';
import rightLockedByChain from '@salesforce/label/c.ChainRightsLockedByChain';
import rightInheritedByParent from '@salesforce/label/c.ChainRightsInheritedByParent';
import rightNotAllowed from '@salesforce/label/c.ChainRightsNotAllowed';

export default class ChainRightsCell extends LightningElement {
    @api right;
    @api type;
    @api accountid;
    @track currentRight = [];
    @track originalRight = [];
    @track ischanged = false;

    connectedCallback(){
        this.currentRight = JSON.parse(JSON.stringify(this.right));
        this.originalRight = JSON.parse(JSON.stringify(this.right));
        this.loaded = true;
    }

    label = {
        rightGranted,
        rightEndsHere,
        rightRemoved,
        rightLockedByChain,
        rightInheritedByParent,
        rightNotAllowed
    }

    get rightsAltText(){
        if(this.currentRight.granted){
            return this.label.rightGranted;
        } else if(this.currentRight.endshere){
            return this.label.rightEndsHere;
        } else if(this.currentRight.removed){
            return this.label.rightRemoved;
        } else if(this.currentRight.lockedbychain){
            return this.label.rightLockedByChain;
        } else if(this.currentRight.inheritedbyparent){
            return this.label.rightInheritedByParent;
        } else if(this.currentRight.notallowed){
            return this.label.rightNotAllowed;
        }
    }

    handleClickCell(){
        if(this.currentRight.clickable){
            let newstatus = null;
            if(this.currentRight.granted){
                newstatus = 'endshere';
            } else if(this.currentRight.endshere){
                newstatus = 'removed';
            } else if(this.currentRight.removed){
                newstatus = 'granted';
            }
            const event = new CustomEvent('rightschange', {
                detail: { 
                    accountid : this.accountid,
                    type: this.type,
                    newstatus: newstatus
                },
                composed: true,
                bubbles: true
            });
            this.dispatchEvent(event);
        }
    }
}
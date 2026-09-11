import { LightningElement, api, track } from 'lwc';

import rightGranted from '@salesforce/label/c.ChainRightsGranted';
import rightEndsHere from '@salesforce/label/c.ChainRightsEndsHere';
import rightRemoved from '@salesforce/label/c.ChainRightsRemoved';
import rightLockedByChain from '@salesforce/label/c.ChainRightsLockedByChain';
import rightInheritedByParent from '@salesforce/label/c.ChainRightsInheritedByParent';
import rightNotAllowed from '@salesforce/label/c.ChainRightsNotAllowed';

const ICONS = {
    listing: 'utility:list',
    condition: 'utility:percent',
    rebate: 'utility:money',
    wkz: 'utility:announcement',
    index: 'utility:trending',
    sampling: 'utility:kanban'
};

export default class ChainRightsCell extends LightningElement {
    @api ownRight;
    @api inheritedRight;
    @api type;
    @api accountid;
    @api owner;
    @track currentRight = [];
    @track originalRight = [];

    connectedCallback(){
        this.currentRight = this.inheritedRight && this.inheritedRight != null && Object.keys(this.inheritedRight).includes(this.type) ? 
            (this.inheritedRight[this.type].granted ? JSON.parse(JSON.stringify(this.ownRight[this.type])) : JSON.parse(JSON.stringify(this.inheritedRight[this.type]))) : 
            JSON.parse(JSON.stringify(this.ownRight[this.type]));
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

    get iconName() {
        const typeKey = this.type ? this.type.toLowerCase() : '';
        return ICONS[typeKey] || 'utility:info';
    }

    get isNotClickable() {
        return !this.currentRight.removed && !this.currentRight.endshere && !this.currentRight.granted;
    }

    get cellClass() {
        let cls = 'slds-button slds-button_icon cell-button';
        
        if (this.currentRight.notallowed) {
            cls += ' status-not-allowed';
        } else if (this.currentRight.lockedbychain || this.currentRight.inheritedbyparent) {
            cls += ' status-locked';
        } else if (this.currentRight.removed) {
            cls += ' status-removed';
        } else if (this.currentRight.endshere) {
            cls += ' status-ends-here';
        } else if (this.currentRight.granted) {
            cls += ' status-granted';
        }

        if (this.currentRight.ischanged) {
            cls += ' is-changed';
        }

        return cls;
    }

    handleClickCell(){
        if(!this.isNotClickable && this.owner){
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
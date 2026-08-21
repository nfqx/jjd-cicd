import { LightningElement, api, wire, track } from 'lwc';
// Apex
import retrieveData from '@salesforce/apex/ChainRightsPassController.retrieveData';
import saveChanges from '@salesforce/apex/ChainRightsPassController.saveChanges';

import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import objectKeysToLowerCase from "c/utils";

// Labels
import accountTreeActiveInactiveAccs from '@salesforce/label/c.AccountTreeActiveInactiveAccs';
import accountTreeEverybodysAccs from '@salesforce/label/c.AccountTreeEverybodysAccs';
import accountTreeExportAsXls from '@salesforce/label/c.AccountTreeExportAsXls';
import accountTreeExportModalMessage from '@salesforce/label/c.AccountTreeExportModalMessage';
import accountTreeExportModalTitle from '@salesforce/label/c.AccountTreeExportModalTitle';
import accountTreeOnlyActiveAccs from '@salesforce/label/c.AccountTreeOnlyActiveAccs';
import accountTreeOnlyMyAccs from '@salesforce/label/c.AccountTreeOnlyMyAccs';
import accountTreeExpandAll from '@salesforce/label/c.AccountTreeExpandAll';
import accountTreeUnexpandAll from '@salesforce/label/c.AccountTreeUnexpandAll';

export default class chainsRightPass extends LightningElement {

    label = {
        accountTreeActiveInactiveAccs,
        accountTreeEverybodysAccs,
        accountTreeExportAsXls,
        accountTreeExportModalMessage,
        accountTreeExportModalTitle,
        accountTreeOnlyActiveAccs,
        accountTreeOnlyMyAccs,
        accountTreeExpandAll,
        accountTreeUnexpandAll
    }

    gridData;
    _selectedRows = [];
    _isLoading = false;
    @api recordId;
    @api relationField;
    @api gridColumns;
    selectedAccountId;
    initialLoadingDone = false;
    currentExpanded = [];
    @track onlyActiveAccToggleVal = true;
    //@track onlyMyAccToggleVal = false;
    @track csvButtonDisabled = false;
    @track hasData = false;
    accountData = {};
    originalExpansionTree;
    
    gridColumns = [
        {
            label: 'Account',
            fieldName: 'href',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'accountname' },
                target: '_blank'
            }
        },
        {
            label: 'Description',
            fieldName: 'description',
            type: 'text'
        },
        {
            label: 'listing',
            fieldName: 'listing',
            type: 'chainRightsCell',
            typeAttributes: {
                type: 'listing',
                right: { fieldName: 'listing' },
                accountid: { fieldName: 'id' },
            }
        },
        {
            label: 'condition',
            fieldName: 'condition',
            type: 'chainRightsCell',
            typeAttributes: {
                type: 'condition',
                right: { fieldName: 'condition' },
                accountid: { fieldName: 'id' },
            }
        },
        {
            label: 'rebate',
            fieldName: 'rebate',
            type: 'chainRightsCell',
            typeAttributes: {
                type: 'rebate',
                right: { fieldName: 'rebate' },
                accountid: { fieldName: 'id' },
            }
        },
        {
            label: 'wkz',
            fieldName: 'wkz',
            type: 'chainRightsCell',
            typeAttributes: {
                type: 'wkz',
                right: { fieldName: 'wkz' },
                accountid: { fieldName: 'id' },
            }
        },
        {
            label: 'index',
            fieldName: 'index',
            type: 'chainRightsCell',
            typeAttributes: {
                type: 'index',
                right: { fieldName: 'index' },
                accountid: { fieldName: 'id' },
            }
        },
        {
            label: 'sampling',
            fieldName: 'sampling',
            type: 'chainRightsCell',
            typeAttributes: {
                type: 'sampling',
                right: { fieldName: 'sampling' },
                accountid: { fieldName: 'id' },
            }
        },
    ];

    actionColumn = {
        type: 'action', 
        typeAttributes: { 
            rowActions: [
                {
                    label: this.label.accountTreeExportAsXls, 
                    name: 'exportxls'
                }
            ]
        }
    };

    set isLoading(value) {
        this._isLoading = value;
    }

    get isLoading() {
        return this._isLoading;
    }

    set selectedRows(value) {
        this._selectedRows = value;
    }

    get selectedRows() {
        return this._selectedRows;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            //case 'exportxls':
            //    this.handleExportXls(row);
            //    break;
        }
    }

    /*
    handleExportXls(row){
        exportData({recordId: row.id})
        .then(result => {
            const event = new ShowToastEvent({
                title: this.label.accountTreeExportModalTitle,
                message:
                this.label.accountTreeExportModalMessage,
            });
            this.dispatchEvent(event);
        });
    }
    */

    @wire(retrieveData, {
        accountId: '$recordId',
        onlyActive: '$onlyActiveAccToggleVal',
        //onlyMine: '$onlyMyAccToggleVal'
    }) wiredAccount({error, data}) {
        this.accountData = {error, data};
        if (!error && !data) {
            this.isLoading = true;
        } else if (data) {
            if(data.items){
                this.gridData = this.parseData(data.items);
                this.hasData = this.gridData.length > 0;
                this.parentChildMap = data.parentChildMap;
                this.currentExpanded = data.expansionTree;
                this.originalExpansionTree = data.expansionTree;
                this.error = undefined;
                this.isLoading = false;
            } else {
                this.record = undefined;
                error('Error!', 'Error loading data')
                this.isLoading = false;
            }
        } else if (error) {
            this.error = error;
            this.record = undefined;
            console.error('Error!', this.error)
        }
    }

    changeOnlyActiveAccToggle(event){
        this.isLoading = true;
        this.onlyActiveAccToggleVal = event.target.checked;
        refreshApex( this.accountData );
    }

    /*changeOnlyMyAccToggle(event){
        this.isLoading = true;
        this.onlyMyAccToggleVal = event.target.checked;
        refreshApex( this.accountData );
    }*/

    @track isExpandedAll = false;
    get _expandAll(){
        return this.isExpandedAll ? this.label.accountTreeUnexpandAll : this.label.accountTreeExpandAll;
    }

    handleExpandAll(event){
        this.isLoading = true;
        let self = this;
        if(!self.isExpandedAll){
            setTimeout(() => {
                const grid = self.template.querySelector('lightning-tree-grid');
                grid.expandAll();
                self.isExpandedAll = !self.isExpandedAll;
                self.isLoading = false;
            }, 500);
        } else {
            let tempGridData = JSON.parse(JSON.stringify(this.gridData));
            let tempCurrentExpanded = JSON.parse(JSON.stringify(this.currentExpanded));
            self.gridData = [];
            self.currentExpanded = [];
            setTimeout(() => {
                self.gridData = JSON.parse(JSON.stringify(tempGridData));
                self.currentExpanded = JSON.parse(JSON.stringify(tempCurrentExpanded));
                self.isExpandedAll = !self.isExpandedAll;
                self.isLoading = false;
            }, 500);
        }
    }

    handleSelectRow(event) {
        let allSelectedRows = event.detail.selectedRows;
        let lastSelectedRowId = event.detail.config.value;

        if (allSelectedRows.length > 1) {
            this.template.querySelector('lightning-tree-grid').selectedRows = [lastSelectedRowId];
        }
        this.selectedAccountId = lastSelectedRowId;
    }

    parseData(data) {
        let a = JSON.parse(JSON.stringify(data)
            .replaceAll(',"childItems":[]', '')
            .replaceAll('childItems', '_children')
        );
        return objectKeysToLowerCase(a);
    }

    changeList = {};
    changedRecordsSelf = {};
    changedRecordsInherited = {};
    inheritingAuthorities = {};
    @track showSave = false;

    handleRightsChange(event) {
        const grid = this.template.querySelector("c-custom-tree-grid");
        this.currentExpanded = grid.getCurrentExpandedRows();
        this.hasData = false;
        let accountid = event.detail.accountid;
        let newStatus = event.detail.newstatus;
        let type = event.detail.type;
        // Clone because the objects are plain JSON data
        const updatedData = JSON.parse(JSON.stringify(this.gridData));

        // Find the target node
        const searchStack = [...updatedData];
        let targetNode;
        while (searchStack.length > 0) {
            const currentNode = searchStack.pop();            
            if (currentNode.id === accountid) {
                targetNode = currentNode;
                break;
            }
            if (currentNode._children?.length) {
                searchStack.push(...currentNode._children);
            }
        }

        if (!targetNode) {
            console.warn(`Account not found: ${accountid}`);
            return;
        }
        let ischanged = this.setChangedRecord(targetNode, accountid, accountid, newStatus, type, true);
        
        if(ischanged){
            let innerList = Object.keys(this.changeList).includes(accountid) ? this.changeList[accountid] : [];
            innerList.push(type + 'own');
            this.changeList[accountid] = innerList;
        } else {
            if(this.changeList.includes(accountid)){
                let index = this.changeList[accountid].indexOf(type + 'own');
                if (index > -1) {
                    this.changeList[accountid].splice(index, 1); 
                }
                if(this.changeList[accountid].length  === 0) {
                    delete this.changeList[accountid];
                }
            }
        } 

        // Propagate to all descendants
        const descendantStack = (targetNode._children ?? []).map(child => ({
            node: child,
            depth: 1
        }));

        while (descendantStack.length > 0) {
            const { node, depth } = descendantStack.pop();
            ischanged = this.setChangedRecord(node, node.id, accountid, newStatus, type, false);
            if(ischanged){
                let innerList = Object.keys(this.changeList).includes(node.id) ? this.changeList[node.id] : [];
                innerList.push(type + 'inh');
                this.changeList[node.id] = innerList;
            } else {
                if(this.changeList.includes(node.id)){
                    let index = this.changeList[node.id].indexOf(type + 'inh');
                    if (index > -1) {
                        this.changeList[node.id].splice(index, 1); 
                    }
                    if(this.changeList[node.id].length  === 0) {
                        delete this.changeList[node.id];
                    }
                }
            }
            if (node._children?.length) {
                descendantStack.push(
                    ...node._children.map(child => ({
                        node: child,
                        depth: depth + 1
                    }))
                );
            }
        }

        // Assign a new reference so the LWC rerenders
        this.showSave = Object.keys(this.changeList).length > 0;
        this.gridData = updatedData;
        setTimeout(() => {
            this.hasData = this.gridData.length > 0;
        }, 0);
    }

    setChangedRecord(node, accountid, inheritingAccountId, newStatus, type, isParent){  
        let ischanged = false;      
        if(newStatus == 'granted'){
            if(!node.originaldata[type].granted){
                node.ischanged = true;
                ischanged = true;
            }
            node[type].granted = true;
            node[type].endshere = false;
            node[type].removed = false;
            node[type].lockedbychain = false;
            node[type].notallowed = false;
            node[type].inheritedbyparent = false;
            node[type].clickable = true;
        } else if(newStatus == 'endshere'){
            if(!node.originaldata[type].endshere){
                node.ischanged = true;
                ischanged = true;
            }
            node[type].granted = false;
            node[type].endshere = isParent;
            node[type].removed = false;
            node[type].lockedbychain = !isParent;
            node[type].notallowed = false;
            node[type].inheritedbyparent = false;
            node[type].clickable = isParent;
        } else if(newStatus == 'removed'){
            if(!node.originaldata[type].removed){
                node.ischanged = true;
                ischanged = true;
            }
            node[type].granted = false;
            node[type].endshere = false;
            node[type].removed = isParent;
            node[type].lockedbychain = !isParent;
            node[type].notallowed = false;
            node[type].inheritedbyparent = false;
            node[type].clickable = isParent;
        }

        if(isParent){
            let innerObj = Object.keys(this.changedRecordsSelf).includes(accountid) ? this.changedRecordsSelf[accountid] : {};
            innerObj[type] = translateStatusParent(newStatus);
            this.changedRecordsSelf[accountid] = innerObj;
        } else {
            let innerObj = Object.keys(this.changedRecordsInherited).includes(accountid) ? this.changedRecordsInherited[accountid] : {};
            innerObj[type] = translateStatusChild(newStatus); //newStatus == 'granted' ? 'Agreed' : 'CappedByChain';
            this.changedRecordsInherited[accountid] = innerObj;
            let innerObjParent = Object.keys(this.inheritingAuthorities).includes(accountid) ? this.inheritingAuthorities[accountid] : {};
            innerObjParent[type] = inheritingAccountId;
            this.inheritingAuthorities[accountid] = innerObjParent;
        }
        return ischanged;
    }

    translateStatusParent(status){
        return status == 'granted' ? 'Agreed' : (status == 'endshere' ? 'AgreedAccountOnly' : 'Locked');
    }
    translateStatusChild(status){
        return status == 'granted' ? 'Agreed' : 'CappedByChain';
    }

    handleSaveChanges(){
        console.log(JSON.stringify(this.changedRecordsSelf));
        console.log(JSON.stringify(this.changedRecordsInherited));
        console.log(JSON.stringify(this.inheritingAuthorities));
        /*saveChanges({
            ownChanges: this.changedRecordsSelf,
            inheritedChanges: this.changedRecordsInherited,
            inheritedBy: this.inheritingAuthorities
        })
        .then(result => {
            this.isLoading = true;
            refreshApex( this.accountData );
        })*/
    }
}
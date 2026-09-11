import { LightningElement, api, wire, track } from 'lwc';

// Apex
import retrieveData from '@salesforce/apex/ChainRightsPassController.retrieveData';
import saveChanges from '@salesforce/apex/ChainRightsPassController.saveChanges';

import { refreshApex } from '@salesforce/apex';
import { loadStyle } from 'lightning/platformResourceLoader';
import rightspasscss from '@salesforce/resourceUrl/rightspasscss';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import objectKeysToLowerCase from 'c/utils';

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
import accountsChanged from '@salesforce/label/c.AccountTreeAccountsChanged';
import viewCondition from '@salesforce/label/c.AccountTreeViewCondition';
import viewStatistics from '@salesforce/label/c.AccountTreeViewStatistics';
import rightGranted from '@salesforce/label/c.ChainRightsGranted';
import rightEndsHere from '@salesforce/label/c.ChainRightsEndsHere';
import rightRemoved from '@salesforce/label/c.ChainRightsRemoved';
import rightLockedByChain from '@salesforce/label/c.ChainRightsLockedByChain';
import rightNotAllowed from '@salesforce/label/c.ChainRightsNotAllowed';
import internalDepartments from '@salesforce/label/c.ChainRightsInternalDepartments';
import cancel from '@salesforce/label/c.GeneralCancel'
import save from '@salesforce/label/c.GeneralSave'

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
        accountTreeUnexpandAll,
        accountsChanged,
        viewCondition,
        viewStatistics,
        rightGranted,
        rightEndsHere,
        rightRemoved,
        rightLockedByChain,
        rightNotAllowed,
        cancel,
        save,
        internalDepartments
    };

    @track gridData;
    @track gridDataOriginal;

    _selectedRows = [];
    _isLoading = false;

    @api recordId;
    @api relationField;

    selectedAccountId;
    initialLoadingDone = false;
    currentExpanded = [];

    @track onlyActiveAccToggleVal = true;
    @track internalDepartmentsToggleVal = true;
    // @track onlyMyAccToggleVal = false;
    @track csvButtonDisabled = false;
    @track hasData = false;
    @track hasNoInactive = true;
    @track hasNoInternalDepartments = true;

    accountData = {};

    @track timestamp = Date.now();

    originalExpansionTree;

    connectedCallback() {
        loadStyle(this, rightspasscss);
    }

    viewOptions = [
        {
            label: this.label.viewCondition,
            value: 'all',
            selected: true
        },
        {
            label: this.label.viewStatistics,
            value: 'alt',
            selected: false
        }
    ];

    gridColumnsAlt = [
        {
            label: 'Account',
            fieldName: 'href',
            type: 'linkwithcategory',
            typeAttributes: {
                label: { fieldName: 'accountname' },
                href: { fieldName: 'href' },
                category: { fieldName: 'category' },
                style: { fieldName: 'style' },
                target: '_blank'
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        }
    ];

    gridColumns = [
        {
            label: 'Account',
            fieldName: 'href',
            type: 'linkwithcategory',
            typeAttributes: {
                label: { fieldName: 'accountname' },
                href: { fieldName: 'href' },
                category: { fieldName: 'category' },
                style: { fieldName: 'style' },
                target: '_blank'
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        },
        {
            label: 'listing',
            fieldName: 'listing',
            type: 'chainRightsCell',
            initialWidth: 80,
            typeAttributes: {
                type: 'listing',
                ownright: { fieldName: 'selfdatacurrent' },
                inheritedright: { fieldName: 'inheriteddatacurrent' },
                accountid: { fieldName: 'id' },
                owner: { fieldName: 'isowner' }
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        },
        {
            label: 'condition',
            fieldName: 'condition',
            type: 'chainRightsCell',
            initialWidth: 80,
            typeAttributes: {
                type: 'condition',
                ownright: { fieldName: 'selfdatacurrent' },
                inheritedright: { fieldName: 'inheriteddatacurrent' },
                accountid: { fieldName: 'id' },
                owner: { fieldName: 'isowner' }
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        },
        {
            label: 'rebate',
            fieldName: 'rebate',
            type: 'chainRightsCell',
            initialWidth: 80,
            typeAttributes: {
                type: 'rebate',
                ownright: { fieldName: 'selfdatacurrent' },
                inheritedright: { fieldName: 'inheriteddatacurrent' },
                accountid: { fieldName: 'id' },
                owner: { fieldName: 'isowner' }
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        },
        {
            label: 'wkz',
            fieldName: 'wkz',
            type: 'chainRightsCell',
            initialWidth: 80,
            typeAttributes: {
                type: 'wkz',
                ownright: { fieldName: 'selfdatacurrent' },
                inheritedright: { fieldName: 'inheriteddatacurrent' },
                accountid: { fieldName: 'id' },
                owner: { fieldName: 'isowner' }
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        },
        {
            label: 'index',
            fieldName: 'index',
            type: 'chainRightsCell',
            wrapText: true,
            initialWidth: 80,
            typeAttributes: {
                type: 'index',
                ownright: { fieldName: 'selfdatacurrent' },
                inheritedright: { fieldName: 'inheriteddatacurrent' },
                accountid: { fieldName: 'id' },
                owner: { fieldName: 'isowner' }
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        },
        {
            label: 'sampling',
            fieldName: 'sampling',
            type: 'chainRightsCell',
            wrapText: false,
            initialWidth: 80,
            typeAttributes: {
                type: 'sampling',
                ownright: { fieldName: 'selfdatacurrent' },
                inheritedright: { fieldName: 'inheriteddatacurrent' },
                accountid: { fieldName: 'id' },
                owner: { fieldName: 'isowner' }
            },
            cellAttributes: {
                style: { fieldName: 'description' }
            }
        }
    ];

    @track gridColumnsUsed = this.gridColumns;

    switchGridColumns(event) {
        this.gridColumnsUsed =
            event.target.value === 'alt'
                ? this.gridColumnsAlt
                : this.gridColumns;
    }

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
            // case 'exportxls':
            //     this.handleExportXls(row);
            //     break;
        }
    }

    /*
    handleExportXls(row) {
        exportData({ recordId: row.id })
            .then(result => {
                const event = new ShowToastEvent({
                    title: this.label.accountTreeExportModalTitle,
                    message: this.label.accountTreeExportModalMessage
                });

                this.dispatchEvent(event);
            });
    }
    */

    @wire(retrieveData, {
        accountId: '$recordId',
        includingInternalDepartments: '$internalDepartmentsToggleVal',
        onlyActive: '$onlyActiveAccToggleVal',
        timestamp: '$timestamp'
        // onlyMine: '$onlyMyAccToggleVal'
    })
    wiredAccount({ error, data }) {
        this.accountData = { error, data };

        if (!error && !data) {
            this.isLoading = true;
        } else if (data) {
            if (data.items) {
                this.hasNoInactive = !data.hasInactive;
                this.hasNoInternalDepartments = !data.hasInternalDepartments;
                this.gridData = this.parseData(data.items);
                this.gridDataOriginal = JSON.parse(
                    JSON.stringify(this.gridData)
                );

                this.hasData = this.gridData.length > 0;
                this.parentChildMap = data.parentChildMap;
                this.currentExpanded = data.expansionTree;
                this.originalExpansionTree = data.expansionTree;
                this.error = undefined;
                this.isLoading = false;
            } else {
                this.record = undefined;
                error('Error!', 'Error loading data');
                this.isLoading = false;
            }
        } else if (error) {
            this.error = error;
            this.record = undefined;
            console.error('Error!', this.error);
        }
    }

    changeInternalDepartmentsToggle(event) {
        this.isLoading = true;
        this.internalDepartmentsToggleVal = event.target.checked;
        refreshApex(this.accountData);
    }

    changeOnlyActiveAccToggle(event) {
        this.isLoading = true;
        this.onlyActiveAccToggleVal = event.target.checked;
        refreshApex(this.accountData);
    }

    /*
    changeOnlyMyAccToggle(event) {
        this.isLoading = true;
        this.onlyMyAccToggleVal = event.target.checked;
        refreshApex(this.accountData);
    }
    */

    @track isExpandedAll = false;

    get _expandAll() {
        return this.isExpandedAll
            ? this.label.accountTreeUnexpandAll
            : this.label.accountTreeExpandAll;
    }

    handleExpandAll(event) {
        this.isLoading = true;
        const self = this;

        if (!self.isExpandedAll) {
            setTimeout(() => {
                const grid = self.template.querySelector('c-custom-tree-grid');
                grid.expandAll();
                self.isExpandedAll = !self.isExpandedAll;
                self.isLoading = false;
            }, 500);
        } else {
            const tempGridData = JSON.parse(
                JSON.stringify(this.gridData)
            );
            const tempCurrentExpanded = JSON.parse(
                JSON.stringify(this.currentExpanded)
            );

            self.gridData = [];
            self.currentExpanded = [];

            setTimeout(() => {
                self.gridData = JSON.parse(
                    JSON.stringify(tempGridData)
                );
                self.currentExpanded = JSON.parse(
                    JSON.stringify(tempCurrentExpanded)
                );

                self.isExpandedAll = !self.isExpandedAll;
                self.isLoading = false;
            }, 500);
        }
    }

    parseData(data) {
        const parsedData = JSON.parse(
            JSON.stringify(data)
                .replaceAll(',"childItems":[]', '')
                .replaceAll('childItems', '_children')
        );

        return objectKeysToLowerCase(parsedData);
    }

    changeList = {};
    changedRecordsSelf = {};
    changedRecordsInherited = {};
    inheritingAuthorities = {};

    @track showSave = false;

    async replaceGridData(data) {
        this.hasData = false;

        // Allows LWC to remove the current grid before continuing,
        // but normally completes before the browser paints.
        await Promise.resolve();

        this.gridData = data;
        this.hasData = data.length > 0;
    }

    async handleRightsChange(event) {
        this.hasData = false;

        const grid = this.template.querySelector(
            'c-custom-tree-grid'
        );

        this.currentExpanded = grid.getCurrentExpandedRows();

        const accountid = event.detail.accountid;
        const newStatus = event.detail.newstatus;
        const type = event.detail.type;

        const updatedData = JSON.parse(
            JSON.stringify(this.gridData)
        );

        // Find the target node.
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
            this.hasData = this.gridData.length > 0;
            return;
        }

        let ischanged = this.setChangedRecord(
            targetNode,
            accountid,
            accountid,
            newStatus,
            type,
            true
        );

        if (ischanged) {
            const innerList =
                Object.keys(this.changeList).includes(accountid)
                    ? this.changeList[accountid]
                    : [];

            if (!innerList.includes(type + 'own')) {
                innerList.push(type + 'own');
                this.changeList[accountid] = innerList;
            }
        } else if (accountid in this.changeList) {
            const index = this.changeList[accountid].indexOf(
                type + 'own'
            );

            if (index > -1) {
                this.changeList[accountid].splice(index, 1);
            }

            if (this.changeList[accountid].length === 0) {
                delete this.changeList[accountid];
            }
        }

        /*
         * Propagate to all descendants.
         *
         * The propagation is path-dependent:
         *
         * - "granted" continues down the hierarchy.
         * - A nearer "endshere" or "removed" becomes the new cap.
         * - Once capped, a lower "granted" cannot reopen that branch.
         * - inheritingAuthorityId always identifies the account which
         *   actually introduced the active cap.
         */
        const descendantStack = (
            targetNode._children ?? []
        ).map(child => ({
            node: child,
            inheritedStatus: newStatus,
            inheritingAuthorityId:
                newStatus === 'granted'
                    ? 'none'
                    : accountid
        }));

        while (descendantStack.length > 0) {
            const {
                node,
                inheritedStatus,
                inheritingAuthorityId
            } = descendantStack.pop();

            ischanged = this.setChangedRecord(
                node,
                node.id,
                inheritingAuthorityId,
                inheritedStatus,
                type,
                false
            );

            if (ischanged) {
                const innerList =
                    Object.keys(this.changeList).includes(node.id)
                        ? this.changeList[node.id]
                        : [];

                if (!innerList.includes(type + 'inh')) {
                    innerList.push(type + 'inh');
                    this.changeList[node.id] = innerList;
                }
            } else if (node.id in this.changeList) {
                const index = this.changeList[node.id].indexOf(
                    type + 'inh'
                );

                if (index > -1) {
                    this.changeList[node.id].splice(index, 1);
                }

                if (this.changeList[node.id].length === 0) {
                    delete this.changeList[node.id];
                }
            }

            if (node._children?.length) {
                let childStatus = inheritedStatus;
                let childInheritingAuthorityId =
                    inheritingAuthorityId;

                /*
                 * Only a branch which is still granted can encounter
                 * a new cap.
                 *
                 * If the branch was already capped above this node,
                 * its own status cannot reopen the branch.
                 */
                if (inheritedStatus === 'granted') {
                    const ownStatus =
                        this.getOwnPropagationStatus(node, type);

                    if (
                        ownStatus === 'endshere' ||
                        ownStatus === 'removed'
                    ) {
                        childStatus = ownStatus;
                        childInheritingAuthorityId = node.id;
                    }
                }

                descendantStack.push(
                    ...node._children.map(child => ({
                        node: child,
                        inheritedStatus: childStatus,
                        inheritingAuthorityId:
                            childInheritingAuthorityId
                    }))
                );
            }
        }

        this.showSave =
            Object.keys(this.changeList).length > 0;

        await this.replaceGridData(updatedData);
    }

    getOwnPropagationStatus(node, type) {
        const ownRight = node.selfdatacurrent?.[type];

        if (ownRight?.endshere) {
            return 'endshere';
        }

        if (ownRight?.removed) {
            return 'removed';
        }

        return 'granted';
    }

    get changeListLength() {
        return Object.keys(this.changeList).length;
    }

    setChangedRecord(
        node,
        accountid,
        inheritingAuthorityId,
        newStatus,
        type,
        isParent
    ) {
        let ischanged = false;

        if (isParent) {
            if (!node.selfdataoriginal[type].notallowed){
                if (newStatus === 'granted') {
                    if (!node.selfdataoriginal[type].granted) {
                        node.selfdatacurrent[type].ischanged = true;
                        ischanged = true;
                    } else {
                        node.selfdatacurrent[type].ischanged = false;
                    }

                    node.selfdatacurrent[type].granted = true;
                    node.selfdatacurrent[type].endshere = false;
                    node.selfdatacurrent[type].removed = false;
                    node.selfdatacurrent[type].lockedbychain = false;
                    node.selfdatacurrent[type].notallowed = false;
                } else if (newStatus === 'endshere') {
                    if (!node.selfdataoriginal[type].endshere) {
                        node.selfdatacurrent[type].ischanged = true;
                        ischanged = true;
                    } else {
                        node.selfdatacurrent[type].ischanged = false;
                    }

                    node.selfdatacurrent[type].granted = false;
                    node.selfdatacurrent[type].endshere = true;
                    node.selfdatacurrent[type].removed = false;
                    node.selfdatacurrent[type].lockedbychain = false;
                    node.selfdatacurrent[type].notallowed = false;
                } else if (newStatus === 'removed') {
                    if (!node.selfdataoriginal[type].removed) {
                        node.selfdatacurrent[type].ischanged = true;
                        ischanged = true;
                    } else {
                        node.selfdatacurrent[type].ischanged = false;
                    }

                    node.selfdatacurrent[type].granted = false;
                    node.selfdatacurrent[type].endshere = false;
                    node.selfdatacurrent[type].removed = true;
                    node.selfdatacurrent[type].lockedbychain = false;
                    node.selfdatacurrent[type].notallowed = false;
                }
            }
        } else {
            if (!node.inheriteddataoriginal[type].notallowed){
                if (newStatus === 'granted') {
                    if (!node.inheriteddataoriginal[type].granted) {
                        node.inheriteddatacurrent[type].ischanged = true;
                        ischanged = true;
                    } else {
                        node.inheriteddatacurrent[type].ischanged = false;
                    }

                    node.inheriteddatacurrent[type].granted = true;
                    node.inheriteddatacurrent[type].endshere = false;
                    node.inheriteddatacurrent[type].removed = false;
                    node.inheriteddatacurrent[type].lockedbychain = false;
                    node.inheriteddatacurrent[type].notallowed = false;
                } else if (newStatus === 'endshere') {
                    if (!node.inheriteddataoriginal[type].endshere) {
                        node.inheriteddatacurrent[type].ischanged = true;
                        ischanged = true;
                    } else {
                        node.inheriteddatacurrent[type].ischanged = false;
                    }

                    node.inheriteddatacurrent[type].granted = false;
                    node.inheriteddatacurrent[type].endshere = false;
                    node.inheriteddatacurrent[type].removed = false;
                    node.inheriteddatacurrent[type].lockedbychain = true;
                    node.inheriteddatacurrent[type].notallowed = false;
                } else if (newStatus === 'removed') {
                    if (!node.inheriteddataoriginal[type].removed) {
                        node.inheriteddatacurrent[type].ischanged = true;
                        ischanged = true;
                    } else {
                        node.inheriteddatacurrent[type].ischanged = false;
                    }

                    node.inheriteddatacurrent[type].granted = false;
                    node.inheriteddatacurrent[type].endshere = false;
                    node.inheriteddatacurrent[type].removed = false;
                    node.inheriteddatacurrent[type].lockedbychain = true;
                    node.inheriteddatacurrent[type].notallowed = false;
                }
            }
        }

        /*
         * Keep the Apex payload maps synchronized with the actual
         * pending changes.
         *
         * Reverted values are removed instead of leaving stale
         * statuses or authority IDs in the save payload.
         */
        if (ischanged) {
            if (isParent) {
                this.setPendingChange(
                    this.changedRecordsSelf,
                    accountid,
                    type,
                    this.translateStatusParent(newStatus)
                );
            } else {
                this.setPendingChange(
                    this.changedRecordsInherited,
                    accountid,
                    type,
                    this.translateStatusChild(newStatus)
                );

                this.setPendingChange(
                    this.inheritingAuthorities,
                    accountid,
                    type,
                    inheritingAuthorityId
                );
            }
        } else if (isParent) {
            this.removePendingChange(
                this.changedRecordsSelf,
                accountid,
                type
            );
        } else {
            this.removePendingChange(
                this.changedRecordsInherited,
                accountid,
                type
            );

            this.removePendingChange(
                this.inheritingAuthorities,
                accountid,
                type
            );
        }

        return ischanged;
    }

    setPendingChange(changeMap, accountid, type, value) {
        const accountChanges = changeMap[accountid] ?? {};

        accountChanges[type] = value;
        changeMap[accountid] = accountChanges;
    }

    removePendingChange(changeMap, accountid, type) {
        if (!changeMap[accountid]) {
            return;
        }

        delete changeMap[accountid][type];

        if (Object.keys(changeMap[accountid]).length === 0) {
            delete changeMap[accountid];
        }
    }

    translateStatusParent(status) {
        return status === 'granted'
            ? 'Agreed'
            : (
                status === 'endshere'
                    ? 'AgreedAccountOnly'
                    : 'Locked'
            );
    }

    translateStatusChild(status) {
        return status === 'granted'
            ? 'Agreed'
            : 'CappedByChain';
    }

    async handleCancel() {
        this.changeList = {};
        this.changedRecordsSelf = {};
        this.changedRecordsInherited = {};
        this.inheritingAuthorities = {};
        this.showSave = false;

        const originalData = JSON.parse(
            JSON.stringify(this.gridDataOriginal)
        );

        await this.replaceGridData(originalData);
    }

    handleSaveChanges() {
        this.isLoading = true;
        this.showSave = false;

        saveChanges({
            ownChanges: this.changedRecordsSelf,
            inheritedChanges: this.changedRecordsInherited,
            inheritedBy: this.inheritingAuthorities
        })
            .then(result => {
                if(result == 'success'){
                    this.changeList = {};
                    this.changedRecordsSelf = {};
                    this.changedRecordsInherited = {};
                    this.inheritingAuthorities = {};
                    this.timestamp = Date.now();

                    return refreshApex(this.accountData);
                } else {
                    // Error Handling
                    console.log(result);
                    this.isLoading = false;
                }
            });
    }
}
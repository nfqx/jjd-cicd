import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import startProductMigration from '@salesforce/apex/MigrationOrchestrator.startMigration';
import startCategoryMigration from '@salesforce/apex/MigrationCategoryController.startMigration';
import startProductEntitlementMigration from '@salesforce/apex/MigrationProductEntitlementController.startMigration';
import startContactsAndUsersMigration from '@salesforce/apex/MigrationContactsAndUsersController.startMigration';
import startProductGroupMigration from '@salesforce/apex/MigrationProductGroupController.startMigration';
import startPuKMigration from '@salesforce/apex/MigrationPuKController.startMigration';
import startImageMigration from '@salesforce/apex/MigrationImageController.startMigration';

export default class MigrationAdmin extends LightningElement {

    startImageMigration() {
        startImageMigration()
            .then(() => {
                this.showToast('Success', 'Image migration started.', 'success');
            })
            .catch(e => this.handleError(e));
    }

    startCategoryMigration() {
        startCategoryMigration()
            .then(() => {
                this.showToast('Success', 'Category migration started.', 'success');
            })
            .catch(e => this.handleError(e));
    }

    startPuKMigration() {
        startPuKMigration()
            .then(() => {
                this.showToast('Success', 'PuK migration started.', 'success');
            })
            .catch(e => this.handleError(e));
    }

    startProductMigration() {
        startProductMigration()
            .then(() => {
                this.showToast('Success', 'Product migration started.', 'success');
            })
            .catch(e => this.handleError(e));
    }

    startProductEntitlementMigration() {
        startProductEntitlementMigration()
            .then(() => {
                this.showToast('Success', 'Product entitlement migration started.', 'success');
            })
            .catch(e => this.handleError(e));
    }

    startContactUserMigration() {
        startContactsAndUsersMigration()
            .then(() => {
                this.showToast('Success','Contact migration started', 'success');
            })
            .catch(e => this.handleError(e));
    }

    startProductGroupMigration(){
        startProductGroupMigration()
            .then(() => {
                this.showToast('Success','Product Group and Subgroup migration started', 'success');
            })
            .catch(e => this.handleError(e));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    handleError(error) {
        const message = error?.body?.message || error.message;
        this.toast('Error', message, 'error');
    }
}
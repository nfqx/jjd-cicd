import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getAllTeamMembers from '@salesforce/apex/WebshopDataController.getAllTeamMembers';
import checkCurrentUserIsManager from '@salesforce/apex/WebshopDataController.checkCurrentUserIsManager';
import handleChangeManager from '@salesforce/apex/WebshopDataController.handleChangeManager';
import handleChangeAssortmentExtensionExclusion from '@salesforce/apex/WebshopDataController.handleChangeAssortmentExtensionExclusion';
import handleChangeWebshopCustomer from '@salesforce/apex/WebshopDataController.handleChangeWebshopCustomer';
import checkPriceInvisible from '@salesforce/apex/WebshopDataController.checkPriceInvisible';
import handleChangePriceVisible from '@salesforce/apex/WebshopDataController.handleChangePriceVisible';
import editUserDetails from '@salesforce/apex/WebshopDataController.editUserDetails';
import deactivateUser from '@salesforce/apex/WebshopDataController.deactivateUser';
import createDelegatedAccount from '@salesforce/apex/WebshopDataController.createDelegatedAccount';
import checkShowGLPage from '@salesforce/apex/WebshopRegisterController.checkShowGLPage';
import createActivationRequiredUser from '@salesforce/apex/WebshopDataController.createActivationRequiredUser';
import checkIfAssortmentExtended from '@salesforce/apex/WebshopDataController.checkIfAssortmentExtended';
import Id from '@salesforce/user/Id';

// Labels

import selectOption from '@salesforce/label/c.GeneralSelectOption';
import grantAccess from '@salesforce/label/c.WebshopGrantAccessToOtherAccounts';
import accessGrantedTo from '@salesforce/label/c.WebshopGrantAccessToOtherAccountsDetail';
import priceVisibleWarning from '@salesforce/label/c.WebshopWarningUserSeesPrices';
import priceInvisibleInfo from '@salesforce/label/c.WebshopPriceInvisibleInfo';
import backToShop from '@salesforce/label/c.WebshopBackToShop';
import teamMember from '@salesforce/label/c.WebshopTeamMember';
import teamMemberCap from '@salesforce/label/c.WebshopTeamMemberCap';
import teamMembers from '@salesforce/label/c.WebshopTeamMembers';
import teamMembersCap from '@salesforce/label/c.WebshopTeamMembersCap';
import teamMembersSubtitle from '@salesforce/label/c.WebshopTeamMembersSubtitle';
import userRole from '@salesforce/label/c.WebshopUserRole';
import action from '@salesforce/label/c.GeneralAction';
import addTeamMembers from '@salesforce/label/c.WebshopAddTeamMember';
import addTeamMembersAlt from '@salesforce/label/c.WebshopAddTeamMemberAlt';
import searchPeople from '@salesforce/label/c.WebshopSearchPeople';
import manager from '@salesforce/label/c.WebshopManager';
import regularUser from '@salesforce/label/c.WebshopRegularUser';
import delegated from '@salesforce/label/c.WebshopDelegated';
import notWebshopActivated from '@salesforce/label/c.WebshopNotWebshopActivated';
import addTeamMembersModalBody from '@salesforce/label/c.WebshopAddTeamMembersModalBody';
import email from '@salesforce/label/c.GeneralEmail';
import cancel from '@salesforce/label/c.GeneralCancel';
import generalSuccess from '@salesforce/label/c.WebshopGeneralSuccess';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import priceVisible from '@salesforce/label/c.WebshopPriceVisible';
import assortmentExtensionExclusion from '@salesforce/label/c.WebshopAssortmentExtensionExclusion';
import editUser from '@salesforce/label/c.WebshopEditUser';
import editUserBody from '@salesforce/label/c.WebshopEditUserBody';
import functionLabel from '@salesforce/label/c.GeneralFunction';
import webshopCustomer from '@salesforce/label/c.WebshopCustomer';
import firstName from '@salesforce/label/c.GeneralFirstName';
import lastName from '@salesforce/label/c.GeneralLastName';
import roleName from '@salesforce/label/c.WebshopUserRole';
import phoneNumber from '@salesforce/label/c.GeneralPhone';
import userActivationAsap from '@salesforce/label/c.WebshopUserActivationAsap';
import generalDelete from '@salesforce/label/c.GeneralDelete';
import deleteUser from '@salesforce/label/c.WebshopDeleteUser';
import deleteUserMessage from '@salesforce/label/c.WebshopDeleteUserMessage';
import youAreRegisteredAs from '@salesforce/label/c.WebshopRegisteredAs';
import accountSwitcher from '@salesforce/label/c.GeneralAccountSwitcher';
import registeredUser from '@salesforce/label/c.GeneralRegisteredUser';

export default class WebshopMyTeam extends NavigationMixin(LightningElement) {
    userId = Id;
    @track accountId;
    @track teamMembers = [];
    @track teamMembersDisplayed = [];
    @track teamMemberCount = 0;
    @track isLoading = false;
    @track isManager = false;
    @track forwardToGLPage = false;
    @track showEmailModal = false;
    @track showEditModal = false;
    @track currentUserName = '';
    @track currentUserFunction = '';
    @track currentUserIsSwitcher = false;
    @track emailaddressModal = '';
    @track firstNameModal = '';
    @track lastNameModal = '';
    @track phoneNumberModal = '';
    @track roleNameModal = '';
    @track selectedUserName = '';
    @track selectedUserId = '';
    @track selectedUserEmail = '';
    @track selectedUserFunction = '';
    @track selectedUserHasUserId = false;
    @track priceInvisible = false;
    @track selectedUserContactId = '';
    @track showDeleteModal= false;
    @track assortmentExtended = false;

    label = {
        registeredUser,
        accountSwitcher,
        youAreRegisteredAs,
        selectOption,
        grantAccess,
        accessGrantedTo,
        backToShop,
        teamMember,
        teamMemberCap,
        teamMembers,
        teamMembersCap,
        teamMembersSubtitle,
        userRole,
        action,
        addTeamMembers,
        addTeamMembersAlt,
        searchPeople,
        manager,
        regularUser,
        delegated,
        notWebshopActivated,
        addTeamMembersModalBody,
        email,
        firstName,
        lastName,
        roleName,
        phoneNumber,
        cancel,
        generalError,
        generalSuccess,
        generalErrorMsg,
        priceVisible,
        editUser,
        editUserBody,
        functionLabel,
        webshopCustomer,
        priceVisibleWarning,
        assortmentExtensionExclusion,
        priceInvisibleInfo,
        userActivationAsap,
        generalDelete,
        deleteUser,
        deleteUserMessage
    }

    changeSearchTerm(event){
        this.isLoading = true;
        let searchTerm = event.target.value;
        let allTeamMembers = JSON.parse(JSON.stringify(this.teamMembers));
        if(stringIsNotBlank(searchTerm)){
            allTeamMembers = allTeamMembers.filter((member) => ((stringIsNotBlank(member.FirstName) ? member.FirstName + ' ' : '') + member.LastName).includes(searchTerm) || (stringIsNotBlank(member.Email) && member.Email.includes(searchTerm) ) );
        }
        this.teamMembersDisplayed = JSON.parse(JSON.stringify(allTeamMembers));
        this.teamMemberCount = this.teamMembersDisplayed.length;
        this.isLoading = false;
    }

    get teamMemberString(){
        return this.teamMemberCount == 1 ? this.label.teamMember : this.label.teamMembers;
    }

    get hasFunction(){
        return stringIsNotBlank(this.currentUserFunction);
    }

    get currentUserStatus(){
        return this.currentUserIsSwitcher ? this.label.accountSwitcher : this.label.registeredUser;
    }

    connectedCallback() {
        this.isLoading = true;
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;
                checkPriceInvisible({accountId: this.accountId})
                .then(outermostResult => {
                    this.priceInvisible = outermostResult;
                    checkCurrentUserIsManager({accountId: this.accountId})
                    .then(outerResult => {
                        if(outerResult != null){
                            this.isManager = outerResult.isManager;
                            this.currentUserName = outerResult.name;
                            this.currentUserFunction = outerResult.function;
                            this.currentUserIsSwitcher = outerResult.isSwitcher;
                            this.getTeamMembers();
                        } else {
                            this.isLoading = false;
                            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                                title: this.label.generalError,
                                message: this.label.generalErrorMsg,
                                variant: 'error',
                            };
                            this.template.querySelector('c-webshop-toast').show = true;});
                        }
                    })
                    .catch(error => {
                        this.isLoading = false;
                        setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                            title: this.label.generalError,
                            message: this.label.generalErrorMsg + ': ' + error,
                            variant: 'error',
                        };
                        this.template.querySelector('c-webshop-toast').show = true;}); 
                    });
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
                checkIfAssortmentExtended({accountId: this.accountId})
                .then(outerResult => {
                    this.assortmentExtended = outerResult;
                });
            } else {
                this.isLoading = false;
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
        })
        .catch(error => {
            this.isLoading = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }

    @track showCreateDelegateModal = false;
    @track delegateModalAccount = null;
    @track delegateModalAccountName = null;
    @track delegateModalUser = null;
    @track delegateModalUserName = null;
    @track modalPriceVisibleSet = false;
    @track modalAssortmentExtensionExclusionSet = false;
    @track modalManagerSet = false;

    openDelegateModal(event){
        this.showCreateDelegateModal = true;    
        this.delegateModalAccount = event.currentTarget.dataset.accountid;
        this.delegateModalAccountName = event.currentTarget.dataset.accountname;
        this.delegateModalUser = event.currentTarget.dataset.userid;
        this.delegateModalUserName = event.currentTarget.dataset.username;
    }
    closeDelegateModal(event){
        this.showCreateDelegateModal = false;
        this.modalPriceVisibleSet = false;
        this.modalAssortmentExtensionExclusionSet = false;
        this.modalManagerSet = false;        
        this.delegateModalAccount = null;  
        this.delegateModalAccountName = null;
        this.delegateModalUser = null;     
        this.delegateModalUserName = null;     
    }
    changeDelegateModalManager(event){
        this.modalManagerSet = event.target.checked;
        this.modalPriceVisibleSet = event.target.checked;
    }
    changeDelegateModalPriceVisible(event){
        this.modalPriceVisibleSet = event.target.checked;
    }
    changeDelegateModalAssortmentExtensionExclusion(event){
        this.modalAssortmentExtensionExclusionSet = event.target.checked;
    }
    submitDelegateModal(){
        createDelegatedAccount({
            accountId: this.delegateModalAccount,
            userId: this.delegateModalUser,
            isManager: this.modalManagerSet,
            priceVisible: this.modalPriceVisibleSet,
            extensionExclusion: this.modalAssortmentExtensionExclusionSet
        })
        .then(result => {
            this.getTeamMembers();
            this.closeDelegateModal();
        })
    }
    
    getTeamMembers(){
        this.teamMembers = [];
        this.teamMembersDisplayed = [];
        this.teamMemberCount = 0;
        getAllTeamMembers({accountId: this.accountId})
        .then(result => {
            if(result != null){
                this.teamMembers = JSON.parse(JSON.stringify(result));
                this.teamMembersDisplayed = JSON.parse(JSON.stringify(this.teamMembers));
                this.teamMemberCount = this.teamMembersDisplayed.length;
                checkShowGLPage()
                .then(innerResult => {
                    if(innerResult != null){
                        this.forwardToGLPage = innerResult;
                        this.isLoading = false;
                    } else {
                        this.isLoading = false;
                        setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                            title: this.label.generalError,
                            message: this.label.generalErrorMsg,
                            variant: 'error',
                        };
                        this.template.querySelector('c-webshop-toast').show = true;});
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else {
                this.isLoading = false;
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
        })
        .catch(error => {
            this.isLoading = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }

    handleClickBackToShop(){
        window.location.assign('/');
    }

    handleConfirmDelete() {
        this.showDeleteModal = false;

        deactivateUser({
            userId: this.deleteUserId,
            accountId: this.accountId
        })
        .then(result => {
            if (result != false) {
                this.getTeamMembers();
            } else {
                setTimeout(() => {
                    this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;
                });
            }
        })
        .catch(error => {
            setTimeout(() => {
                this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;
            });
        });
    }

    handleChangeWebshopCustomer(event){
        let contactId = event.currentTarget.dataset.contactid;
        let checked = event.target.checked;
        handleChangeWebshopCustomer({contactId: contactId, checked: checked})
        .then(result => {
            if(result == false){
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

    handleChangeManager(event){
        let contactId = event.currentTarget.dataset.contactid;
        let checked = event.target.checked;
        handleChangeManager({contactId: contactId, accountId: this.accountId, checked: checked})
        .then(result => {
            if(result == false){
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

    handleChangePriceVisible(event){
        let contactId = event.currentTarget.dataset.contactid;
        let checked = event.target.checked;
        handleChangePriceVisible({contactId: contactId, accountId: this.accountId, checked: checked})
        .then(result => {
            if(result == false){
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

    handleChangeAssortmentExtensionExclusion(event){
        let contactId = event.currentTarget.dataset.contactid;
        let checked = event.target.checked;
        handleChangeAssortmentExtensionExclusion({contactId: contactId, accountId: this.accountId, checked: checked})
        .then(result => {
            if(result == false){
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

    handleOpenEditModal(event){
        this.selectedUserId = event.currentTarget.dataset.recordid;
        this.selectedUserName = event.currentTarget.dataset.recordname;
        this.selectedUserEmail = event.currentTarget.dataset.email;
        this.selectedUserFunction = event.currentTarget.dataset.function;
        this.selectedUserHasUserId = event.currentTarget.dataset.hasuserid == 'true';
        this.selectedUserContactId = event.currentTarget.dataset.contactid;
        this.showEditModal = true;
    }

    handleChangeSelectedUserFunction(event){
        this.selectedUserFunction = event.target.value;
    }

    handleChangeSelectedUserEmail(event){
        this.selectedUserEmail = event.target.value;
    }

    handleChangeEmailAddress(event){
        this.emailaddressModal = event.target.value;
    }

    handleChangeFirstName(event){
        this.firstNameModal = event.target.value;
    }

    handleChangeLastName(event){
        this.lastNameModal = event.target.value;
    }

    handleChangePhoneNumber(event){
        this.phoneNumberModal = event.target.value;
    }

    handleChangeRoleName(event){
        this.roleNameModal = event.target.value;
    }

    handleClose(){
        this.showEmailModal = false;
    }

    handleCloseEditModal(){
        this.showEditModal = false;
    }

    get editUserDisabled(){
        return (this.selectedUserHasUserId && !stringIsNotBlank(this.selectedUserEmail)) || !stringIsNotBlank(this.selectedUserFunction);
    }

    get addMembersNonGLDisabled(){
        return !stringIsNotBlank(this.firstNameModal) || !stringIsNotBlank(this.lastNameModal) || !stringIsNotBlank(this.emailaddressModal) || !stringIsNotBlank(this.phoneNumberModal) || !stringIsNotBlank(this.roleNameModal);
    }

    handleEditUser(){
        this.showEditModal = false;
        editUserDetails({
            userid: this.selectedUserId,
            email: this.selectedUserEmail,
            contactid : this.selectedUserContactId,
            function: this.selectedUserFunction
        })
        .then(result => {
            if(result == true){
                this.getTeamMembers();
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

    handleAddMembersNonGL(){
        this.showEmailModal = false;
        createActivationRequiredUser({
            accountId: this.accountId,
            firstName: this.firstNameModal,
            lastName: this.lastNameModal,
            email: this.emailaddressModal,
            phone: this.phoneNumberModal,
            roleName: this.roleNameModal
        })
        .then(result => {
            if(result == 'success'){
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalSuccess,
                    message: this.label.userActivationAsap,
                    variant: 'success',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            } else {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: result.replace('error: ', ''),
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

    handleAddMembers(){
        this.showEmailModal = true;
    }

    handleOpenDeleteModal(event) {
    this.deleteUserId = event.currentTarget.dataset.userid;
    this.showDeleteModal = true;
    }
    
    handleCloseDeleteModal(){
        this.showDeleteModal = false;
    }

}
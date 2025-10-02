import { LightningElement, api, track } from 'lwc';
import { FlowNavigationFinishEvent, FlowNavigationPauseEvent, FlowNavigationNextEvent, FlowNavigationBackEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

import { NavigationMixin } from 'lightning/navigation';

export default class SearchComponent extends NavigationMixin(LightningElement) {

    /* values for an existing selected record */
    @api valueId;
    @api valueName;
    @api disabled;
    @api required;
    @api MainFlow;

    @api objName       = 'Account';
    @api iconName      = 'standard:account';
    @api labelName;
    @api currentRecordId;
    @api placeholder   = 'Search';
    @api fields        = ['Name'];
    @api where;
    @api displayFields = 'Name, Rating, AccountNumber';
    @api showLabel     = false;
    @api parentAPIName = 'ParentId';
    @api createRecord  = false;
    @api isOnFlow  = false;

    /* values to be passed to create the new record */
    @api recordTypeId;
    @api fieldsToCreate = [];
    @api selectedRecord;

    @track showError = false;

    get disabledNext(){
        return this.required && this.selectedRecord === undefined;
    }

    connectedCallback(){
        if(this.valueId){
            this.selectedRecord = {
                                    "Id": this.valueId, 
                                    "Name": this.valueName
                                };
        }
    }

    handleLookup(event){
        if(event.detail.data.record){
            this.selectedRecord = event.detail.data.record;
            console.log(JSON.stringify(this.selectedRecord));
            this.showError = false;
        }else{
            this.selectedRecord = undefined;
        }
    }

    handleNext() {
        if(this.disabledNext){
            this.showError = true;
        }else{
            const attributeChangeEvent = new FlowAttributeChangeEvent(this.objName, this.selectedRecord);
            this.dispatchEvent(attributeChangeEvent);
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    handlePrevious() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    @api
    validate() {
        if (this.required && !this.selectedRecord) {
            this.showError = true;
            return {
                isValid: false,
                errorMessage: 'Necesitas seleccionar un transportista.'
            };
        }
        return { isValid: true };
    }
}
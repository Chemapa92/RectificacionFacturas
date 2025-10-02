import { LightningElement,api } from 'lwc';
import getResponse from '@salesforce/apex/UpdateOrderScreenFlowController.callOutA3';
import {
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';

export default class LwcPauseScreenFlow extends LightningElement {
    @api getRecordList = [];
    @api currentRecord ;
    @api returnStatusCode;
    pauseProccess = false;
    renderSpinner = true;

    connectedCallback(){
        console.log(this.currentRecord);
        console.log('this.getRecordList:', JSON.stringify(this.getRecordList));
        console.log('url:', window.location.href);
        console.log('url condition: '+window.location.href.includes('dev'));
        let credentialToUse;
        if(window.location.href.includes('dev')){
            credentialToUse = 'DEV_mod';
        }
        getResponse({ord:this.currentRecord,listOrderItems:this.getRecordList,credentialToUse:credentialToUse}) 
            .then((result) => {
                console.log('send res: '+result);
                if(result == 200 || result == 201){
                    
                    this.returnStatusCode = result;
                    this.renderSpinner = false;
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }else if(result == 'error'){
                    console.log('resul else if: '+result);
                    this.returnStatusCode = result;
                    this.renderSpinner = false;
                    

                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }
            })
            .catch((error) => {
                this.returnStatusCode = result + error;
                this.renderSpinner = false;
            });
    }
    
    handlePrevious(){
        const navigateNextEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}
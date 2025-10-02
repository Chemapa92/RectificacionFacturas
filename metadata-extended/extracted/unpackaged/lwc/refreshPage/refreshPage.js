import { LightningElement } from 'lwc';

export default class RefreshPage extends LightningElement {


    connectedCallback(){
        
        setTimeout(
            
            function() {
                
                window.location.href = window.location.href.split('/lightning')[0]+'/lightning/o/Order__c/list?filterName=Recent';
            }, 3000);
        
    }
    
}
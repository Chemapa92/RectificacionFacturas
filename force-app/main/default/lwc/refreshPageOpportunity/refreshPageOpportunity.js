import { LightningElement } from 'lwc';

export default class RefreshPageOpportunity extends LightningElement {
    connectedCallback(){
        
        setTimeout(
            
            function() {
                
                window.location.href = window.location.href.split('/lightning')[0]+'/lightning/o/Opportunity/list?filterName=Recent';
            }, 1500);
        
    }
}
import { LightningElement, api, track} from 'lwc';
import { FlowNavigationFinishEvent, FlowNavigationPauseEvent, FlowNavigationNextEvent, FlowNavigationBackEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';
import {loadStyle} from 'lightning/platformResourceLoader';
import STYLE from '@salesforce/resourceUrl/ProductPriceSelectorStyle';

import getAllProducts from '@salesforce/apex/ProductsSelectorController.getPricebookEntries';

export default class ProductsSelector extends LightningElement {
    @api preSelectedRows;
    @api selAccountStore;
    @api fromLWC;
    @track listProducts;
    @track selectedRows;
    @track isLoaded = false;
    @track showError = false;
    error;

    @track columns = [
        { label: 'Producto', fieldName: 'Name', type: 'text', sortable: true, wrapText: true},
        { label: 'Código', fieldName: 'ProductCode', type: 'text', sortable: true},
        { label: '€/Litro', fieldName: 'UnitPrice', type: 'currency', sortable: true, typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 4 } }
    ];

    connectedCallback() {
        this.isLoaded = false;
		this.loadProducts();
	}

    renderedCallback(){ 
        loadStyle(this, STYLE).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the style")
        })
    }

	loadProducts() {
		getAllProducts({ store : this.selAccountStore, pageSize : 50, pageNum : 1, searchText : null})
			.then(result => {
				this.listProducts = result;
                this.isLoaded = true;
			})
			.catch(error => {
				this.error = error;
			});
	}

    handleNext() {
        this.selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        this.preSelectedRows = [];
        if(this.selectedRows.length > 0){
            this.getSelectedIds();
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        } else {
            this.showError = true;
        }
    }

    getSelectedIds() {
        this.selectedRows.forEach(currentItem => {
            this.preSelectedRows.push(currentItem.Id);
        });
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedIds', this.preSelectedRows);
        this.dispatchEvent(attributeChangeEvent);
    }

    handlePrevious() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }
}
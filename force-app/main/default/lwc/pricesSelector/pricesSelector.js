import { LightningElement, api, track} from 'lwc';
import { FlowNavigationFinishEvent, FlowNavigationPauseEvent, FlowNavigationNextEvent, FlowNavigationBackEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { NavigationMixin } from "lightning/navigation";
import {loadStyle} from 'lightning/platformResourceLoader';
import STYLE from '@salesforce/resourceUrl/ProductPriceSelectorStyle';
import getAllProducts from '@salesforce/apex/ProductsSelectorController.getSelectedPricebookEntries';
import createOrder from '@salesforce/apex/ProductsSelectorController.createOrder';
import createOpp from '@salesforce/apex/ProductsSelectorController.createOpp';
import createProformaBorrador from '@salesforce/apex/ProductsSelectorController.createProformaBorrador';
import getSelectedShippingAddress from '@salesforce/apex/ProductsSelectorController.getSelectedShippingAddress';
import getSelectedCarrier from '@salesforce/apex/ProductsSelectorController.getSelectedCarrier';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProductsSelector extends NavigationMixin(LightningElement) {
    @api selProducts;
    @api newOrder;
    @api TipoPedido;
    @api CrearOrder;
    @api selAccountStore;
    @api AccountId;
    @api ShippingAddressId;
    @api Pedido;
    @api Paymethod;
    @api orderStartDate;
    @api closeDate;
    @api CarrierId;
    @api cuentaPrincipal;
    @track listProducts;
    @track listInitialProducts;
    @track isLoaded = false;
    @track showQuantityError = false;
    @track limitMessage = false;
    @track showLimitMessage = false;
    @track enableRowNumber = false;
    @track isEditing = false;
    @track isSaving = false;
    @track resumen = false;
    @track shippingAddressInfo;
    @track runFlow = false;
    @track viewPriceTable = true;
    @track CarrierInfo;
    @track ArrayPedidos = [];
    @track ListPedidos = [];
    @track nuevoPedido = false;

    error;

    @track columns = [
        { label: 'Producto', fieldName: 'Name', type: 'text', sortable: true, wrapText: true},
        { label: 'Cantidad(litros)', fieldName: 'Quantity', type: 'number', sortable: true, editable: true},
        { label: '€/l', fieldName: 'UnitPrice', type: 'number', sortable: true, editable: true, typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 4 } }
    ];

    @track columns2 = [
        { label: 'Pedido', fieldName: 'Pedido', type: 'text', sortable: true, wrapText: true},
        { label: 'Producto', fieldName: 'Name', type: 'text', sortable: true, wrapText: true},
        { label: 'Cantidad(litros)', fieldName: 'Quantity', type: 'number', sortable: true, editable: false},
        { label: '€/l', fieldName: 'UnitPrice', type: 'number', sortable: true, editable: false, typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 4 } },
        { label: 'Direccion de Entrega', fieldName: 'shippingAddress', type: 'text', sortable: true, wrapText: true},
        { label: 'Alias', fieldName: 'Alias', type: 'text', sortable: true, wrapText: true}
    ];

    connectedCallback() {
        this.isLoaded = false;
		this.loadProducts();
        this.getShippingInfo();
        this.getCurrentInfo();
	}

    renderedCallback(){ 
        loadStyle(this, STYLE).then(()=>{
        }).catch(error=>{ 
        })
    }

    Callmodal(){
        this.nuevoPedido = true;
    }

    closeModalPreview(){
        this.nuevoPedido = false;
    }

    get canNotSave() {
        return this.isEditing || this.isSaving;
	}

    getShippingInfo() {
        getSelectedShippingAddress({ AccId : this.ShippingAddressId})
        .then(result => {
            this.shippingAddressInfo = result;
        })
        .catch(error => {
            this.error = error;
        });
    }

    getCurrentInfo() {
        getSelectedCarrier({ CarrierId : this.CarrierId})
        .then(result => {
            this.CarrierInfo = result;
        })
        .catch(error => {
            this.error = error;
        });
    }

	loadProducts() {
		getAllProducts({ lSelected : this.selProducts})
			.then(result => {
                result.forEach(currentItem => {
                    currentItem.Quantity = 1;
                });
				this.listProducts = result;
                console.log(JSON.stringify(this.listProducts));
				this.listInitialProducts = result;
                this.isLoaded = true;
			})
			.catch(error => {
				this.error = error;
			});
	}

    handleKeyUp(event){
        this.isEditing = true;
    }

    handleCellChange(event){
        this.isEditing = false;
    }

    get inputVariables() {
        return [
            {
                name: 'fromLWC',
                type: 'Boolean',
                value: true
            },
            {
                name: 'AccountId',
                type: 'SObject', 
                value: this.AccountId,
            },
            {
                name: 'recordId',
                type: 'SObject', 
                value: this.AccountId,
            },
            {
                name: 'AccountStore',
                type: 'String', 
                value:  this.selAccountStore
            },
            {
                name: 'WhereAccAccount',
                type: 'String', 
                value:  "RecordType.DeveloperName = 'Cuenta_Direccion' and ParentId= '"+this.AccountId+"'"
            },
            {
                name: 'PayMethodfromlwc',
                type: 'String', 
                value:  this.Paymethod
            },
            {
                name: 'SelectedCarrierId',
                type: 'String', 
                value:  this.TipoPedido == 'Operador' ? '' : this.CarrierId != null ? this.CarrierId : ''
            },
            {
                name: 'TipoPedido',
                type: 'String', 
                value:  this.TipoPedido
            },
            {
                name: 'newOrder',
                type: 'SObject', 
                value: this.newOrder
            },
            {
                name: 'Pedido',
                type: 'SObject', 
                value: this.ArrayPedidos
            },
            {
                name: 'orderStartDate',
                type: 'DateTime', 
                value: this.orderStartDate,
            },
            {
                name: 'closeDate',
                type: 'DateTime', 
                value: this.closeDate,
            }
        ];
    }

    BackToFlow(){
        this.nuevoPedido = false;
        this.resumen = false;
        this.runFlow = true;
    }

    handleNext() {
        this.isSaving = true;
        if(this.TipoPedido == 'Retail'){
            this.checkQuantity();
        }
        else {
            this.showLimitMessage = false;
            this.showQuantityError = false;
        }
        
        this.checkPriceLimits();
        
        if(this.cuentaPrincipal == false){
            
            if(!this.showQuantityError && !this.showLimitMessage){
                this.checkMinValAndFinsish();
            }else{
                this.isSaving = false;
            }
        }

        else if(this.cuentaPrincipal == true){
            if(!this.showQuantityError && !this.showLimitMessage) {
                this.viewPriceTable = false;
                this.resumen = true;
                this.runFlow = false;
                let NPedido;
                let NumPedido;

                if(this.Pedido == undefined){
                    this.ArrayPedidos = this.listProducts;
                    this.ListPedidos = this.listProducts;
                    this.listProducts.forEach(element => {
                        element.Pedido = 'Pedido 1';
                        if(this.shippingAddressInfo.length > 0){
                            element.shippingAddress = this.shippingAddressInfo[0].hasOwnProperty('Name') ? this.shippingAddressInfo[0].Name : '';
                            element.shippingAddressId = this.shippingAddressInfo[0].hasOwnProperty('Id') ? this.shippingAddressInfo[0].Id : '';
                            element.Alias = this.shippingAddressInfo[0].hasOwnProperty('Alias__c') ? this.shippingAddressInfo[0].Alias__c : '';
                        }
                        else {
                            element.shippingAddress = '';
                            element.Alias = '';
                        }
                        if(this.CarrierInfo.length > 0){
                            element.CarrierId = this.TipoPedido != 'Operador' ? this.CarrierInfo[0].Id : '';
                        }
                        else {
                            element.CarrierId = '';
                        }
                        
                    });
                }
                else {
                    this.listProducts.forEach(ele => {
                        this.ArrayPedidos.push(ele);
                    });
                    this.Pedido.forEach(element => {
                        this.ArrayPedidos.push(element);
                    });
                    this.ArrayPedidos = [...this.ArrayPedidos];
                    this.ListPedidos.push(this.Pedido);
                    this.ListPedidos.push(this.listProducts);
                    NPedido = this.ListPedidos[0][0].Pedido.split(" ");
                    NumPedido = parseInt(NPedido[1]) + 1;
                    this.listProducts.forEach(element => {
                        element.Pedido = 'Pedido '+NumPedido+'';
                        if(this.shippingAddressInfo.length > 0){
                            element.shippingAddress = this.shippingAddressInfo[0].hasOwnProperty('Name') ? this.shippingAddressInfo[0].Name : '';
                            element.shippingAddressId = this.shippingAddressInfo[0].hasOwnProperty('Id') ? this.shippingAddressInfo[0].Id : '';
                            element.Alias = this.shippingAddressInfo[0].hasOwnProperty('Alias__c') ? this.shippingAddressInfo[0].Alias__c : '';
                        }
                        else {
                            element.shippingAddress = '';
                            element.Alias = '';
                        }
                        if(this.CarrierInfo.length > 0){
                            element.CarrierId = this.TipoPedido != 'Operador' ? this.CarrierInfo[0].Id : '';
                        }
                        else {
                            element.CarrierId = '';
                        }
                    });
                    
                }
            }
            else{
                this.isSaving = false;
            }
        }
    }


    CreateProforma(pedido, oppId){
        var listOfEntryIds = pedido.map(function(obj) { return obj.Id; });
         createProformaBorrador({ listPrices : pedido, listEntryIds : listOfEntryIds, selAccountStore : this.selAccountStore, AccountId: this.AccountId, oppId: oppId, Paymethod: this.Paymethod, TipoPedido: this.TipoPedido, closeDate: this.closeDate, orderStartDate: this.orderStartDate})
			.then(result => {
			})
			.catch(error => {
				this.error = error;
                this.isSaving = false;
			});
    }


     CreateOpp(pedido){
         createOpp({ listPrices : pedido, selAccountStore : this.selAccountStore, AccountId: this.AccountId, Paymethod: this.Paymethod, Type: this.TipoPedido, closeDate: this.closeDate, orderStartDate: this.orderStartDate})
			 .then(result => {

                let oppId = result;
                const PedidosIndividualesObjeto = Object.groupBy(this.ArrayPedidos, ({Pedido}) => Pedido);
                var PedidosIndividualesArreglo = Object.values(PedidosIndividualesObjeto);
                PedidosIndividualesArreglo.forEach(ele => {
                    this.CreateProforma(ele, oppId);
                    let title = `Proforma creadas de manera exitosa!!`
                    this.toast(title, 'success');
                    this.handleNavigateOpp(oppId);
                    });
			})
			.catch(error => {
				this.error = error;
                this.isSaving = false;

			});
    }

    handleSaveListPedidos(){
        this.CreateOpp(this.ArrayPedidos);
    }

    handleFinish() {
        const navigateFinishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateFinishEvent);
    }

    handlePrevious() {
        this.limitMessage = false;
    }

    handlePreviousScreenFlow() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

	createOrderJS() {
        this.isSaving = true;
        this.listProducts.forEach(element => {
            element.CarrierId = this.CarrierId;
        });
        console.log(JSON.stringify(this.listProducts));
        if(this.CrearOrder == true){
            var listOfEntryIds = this.listProducts.map(function(obj) { return obj.Id; });
            createOrder({ listPrices : this.listProducts, listEntryIds : listOfEntryIds, newOrder: this.newOrder, closeDate: this.closeDate, orderStartDate: this.orderStartDate})
			.then(result => {
                this.handleNavigate(result);
			})
			.catch(error => {
				this.error = error;
                this.isSaving = false;
			});
        }
        else {
            createOpp({ listPrices : this.listProducts, selAccountStore : this.selAccountStore, AccountId: this.AccountId, Paymethod: this.Paymethod, Type: this.TipoPedido, closeDate: this.closeDate, orderStartDate: this.orderStartDate})
			.then(result => {
                this.handleNavigateOpp(result);
                this.handleFinish();
			})
			.catch(error => {
				this.error = error;
                this.isSaving = false;
			});
        }
	}

    checkQuantity(){
        let listProducts = this.template.querySelector('lightning-datatable').draftValues;
        let totalQuantity = 0;
        for(const element of listProducts) {
            totalQuantity += Number(element.Quantity);
        }
        if(totalQuantity < 1000 || totalQuantity > 35000){
            this.showQuantityError = true;
        }else{
            this.showQuantityError = false;
        }
    }

    checkMinValAndFinsish(){
        this.listProducts = this.template.querySelector('lightning-datatable').draftValues;
        let decreasePrice = [];
        for(const element of this.listProducts) {
            element.UnitPrice = Number(element.UnitPrice);
            let initial = this.listInitialProducts.filter(ini => element.Id === ini.Id);
            if(initial[0].UnitPrice > element.UnitPrice){
                decreasePrice.push(element);
            }
        }

        if(decreasePrice.length > 0){
            this.limitMessage = true;
            this.isSaving = false;
        }else{
            this.createOrderJS();
        }
    }

    checkPriceLimits(){
        this.listProducts = this.template.querySelector('lightning-datatable').draftValues;
        let productLimits = [];
        for(const element of this.listProducts) {
            element.UnitPrice = Number(element.UnitPrice);
            if(element.UnitPrice < 0.5 || element.UnitPrice > 3){
                productLimits.push(element);
            }
        }

        if(productLimits.length > 0){
            this.showLimitMessage = true;
        }else{
            this.showLimitMessage = false;
        }
    }

    handleNavigate(newOrderId) {
        const config = {
          type: "standard__recordPage",
          attributes: {
            recordId: newOrderId,
            objectApiName: "Order__c",
            actionName: "view"
          }
        };
        this[NavigationMixin.Navigate](config);
      }

      handleNavigateAccount(AccountId) {
        const config = {
          type: "standard__recordPage",
          attributes: {
            recordId: AccountId,
            objectApiName: "Account",
            actionName: "view"
          }
        };
        this[NavigationMixin.Navigate](config);
      }

      handleNavigateOpp(OppId) {
        const config = {
          type: "standard__recordPage",
          attributes: {
            recordId: OppId,
            objectApiName: "Opportunity",
            actionName: "view"
          }
        };
        this[NavigationMixin.Navigate](config);
      }

      toast(title, variant){
        const toastEvent = new ShowToastEvent({
            title, 
            variant: variant
        })
        this.dispatchEvent(toastEvent)
    }
}
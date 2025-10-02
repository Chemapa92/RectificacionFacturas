import { LightningElement ,api , track} from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import getOrderItems from '@salesforce/apex/LwcOrderItemTable.getOrderItems';
import {
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';

export default class LwcOrderItemTable extends LightningElement {
    @api records ;
    @api updateRecords;
    @api orderId;
    @api listWithRecordUpdate = [];
    jsonObject = [];
    recordsForTable = [];


    noModified = true;
    isEditing;
    errors;
    rowOffset = 0;
    cantidad =  0;
    renderButton = false;    
    renderMessageTotal = false;
    renderMessageEuLit = false;
    @api fieldColumns = [
        { label: 'Nombre', fieldName: 'Name', editable: false },
        { label: 'Descripción del Producto', fieldName: 'ProductDescription', editable: false },
        { label: 'Precio €/l', fieldName: 'UnitPrice', editable: true,sortable: true},
        { label: 'Cantidad(l)', fieldName: 'Quantity', editable: true,sortable: true},
        
        ];
   
    
    connectedCallback(){
        
        console.log('this.listWithRecordUpdate:', this.listWithRecordUpdate);
        this.recordTable();
        //this.recordsForTable = this.recordTable();
        
        
    }

    onCellChange(){
        this.renderButton = false;
        this.noModified = false;
        console.log(this.noModified);
    }
    
    async saveHandleAction(event) {
            
            
            this.fldsItemValues = event.detail.draftValues;
            const inputsItems = this.fldsItemValues.slice().map(draft => {
                const fields = Object.assign({}, draft);
                console.log(fields);
                return { fields };
            });

            var myMap = new Map();
            var myMapCurrentValues = new Map();

            this.renderMessageEuLit = false;
            for(let x = 0;x<inputsItems.length;x++){
                console.log('inp Id4: '+inputsItems[x].fields.Id_Salesforce);
                myMap.set(inputsItems[x].fields.Id_Salesforce,inputsItems[x].fields);
            }
            this.cantidad = 0;

            for(let x = 0;x<this.recordsForTable.length;x++){
                myMapCurrentValues.set(this.recordsForTable[x].Id_Salesforce,this.recordsForTable[x]);
                console.log('myMapCurrentValues:', myMapCurrentValues.size);
                if(myMap.get(this.recordsForTable[x].Id_Salesforce) == null){
                    
                    if(!isNaN(parseFloat(this.recordsForTable[x].Quantity))){
                        this.cantidad+= parseFloat(this.recordsForTable[x].Quantity);
                    }
                    
                    if((parseFloat(this.recordsForTable[x].UnitPrice) < 0.5 || parseFloat(this.recordsForTable[x].UnitPrice) > 3) &&!isNaN(this.recordsForTable[x].UnitPrice)){
                        this.renderMessageEuLit = true;
                    }
                    console.log(this.renderMessageEuLit);
                }else{
                    try {
                        if(!isNaN(parseFloat(myMap.get(this.recordsForTable[x].Id_Salesforce).Quantity))){
                            this.cantidad+= parseFloat(myMap.get(this.recordsForTable[x].Id_Salesforce).Quantity);
                            console.log('dentro de try_1: '+this.cantidad);
                        }else if(!isNaN(parseFloat(this.recordsForTable[x].Quantity))){
                            this.cantidad+= parseFloat(this.recordsForTable[x].Quantity);
                        }
                        
                    } catch (error) {
                        if(!isNaN(parseFloat(this.recordsForTable[x].Quantity))){
                            this.cantidad+= parseFloat(this.recordsForTable[x].Quantity);
                        }
                        console.log('dentro de catch_1: '+this.cantidad);
                    }
                    try {
                        console.log(myMap.get(this.recordsForTable[x].Id_Salesforce).UnitPrice);
                        console.log(isNaN(parseFloat(myMap.get(this.recordsForTable[x].Id_Salesforce).UnitPrice)));
                        if(!isNaN(parseFloat(myMap.get(this.recordsForTable[x].Id_Salesforce).UnitPrice))&&(parseFloat(myMap.get(this.recordsForTable[x].Id_Salesforce).UnitPrice) < 0.5 || parseFloat(myMap.get(this.recordsForTable[x].Id_Salesforce).UnitPrice) > 3)){
                            this.renderMessageEuLit = true;
                        }
                        
                        console.log('Render Eu try2+' +this.renderMessageEuLit);

                    } catch (error) {
                        console.log(error);
                        if((parseFloat(this.recordsForTable[x].UnitPrice) < 0.5 || parseFloat(this.recordsForTable[x].UnitPrice) > 3) &&!isNaN(this.recordsForTable[x].UnitPrice)){
                            this.renderMessageEuLit = true;
                        }
                        console.log('Render Eu catch2+' +this.renderMessageEuLit);
                        
                    }
                    
                }
                
                
            }
            console.log('antes de entrar bucle map '+ myMapCurrentValues.size);
            console.log('this.cantidad: '+this.cantidad);
            console.log('this.renderMessageEuLit: '+this.renderMessageEuLit);
            this.renderMessageTotal = false;
            if(this.cantidad>35000 || this.cantidad < 1000){
                this.renderMessageTotal = true;
            }else{
                this.renderMessageTotal = false;
            }
            if(this.renderMessageTotal == false && this.renderMessageEuLit == false){
                this.jsonObject = [];
                for(let x = 0; x<inputsItems.length;x++){
                    console.log('tamaño map: '+myMapCurrentValues.size);
                    if(myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce)!= null){
                        //this.listWithRecordUpdate.push(inputsItems[x].fields);
                        console.log('jsonObject: '+this.jsonObject);
                        if(inputsItems[x].fields.Quantity != null && inputsItems[x].fields.UnitPrice != null){
                            this.jsonObject.push({
                                "Id":inputsItems[x].fields.Id_Salesforce,
                                "Name":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).Name,
                                "Quantity__c":inputsItems[x].fields.Quantity,
                                "UnitPrice__c":inputsItems[x].fields.UnitPrice,
                                "ProductDescription__r.Name":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).ProductDescription
                            });
                        }else if(inputsItems[x].fields.Quantity != null && inputsItems[x].fields.UnitPrice == null){
                            this.jsonObject.push({
                                "Id":inputsItems[x].fields.Id_Salesforce,
                                "Name":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).Name,
                                "Quantity__c":inputsItems[x].fields.Quantity,
                                "UnitPrice__c":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).UnitPrice,
                                "ProductDescription__r.Name":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).ProductDescription
                            });
                        }else if(inputsItems[x].fields.UnitPrice != null && inputsItems[x].fields.Quantity == null){
                            this.jsonObject.push({
                                "Id":inputsItems[x].fields.Id_Salesforce,
                                "Name":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).Name,
                                "Quantity__c":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).Quantity,
                                "UnitPrice__c":inputsItems[x].fields.UnitPrice,
                                "ProductDescription__r.Name":myMapCurrentValues.get(inputsItems[x].fields.Id_Salesforce).ProductDescription
                            });
                        }
                        
                    }
                    myMapCurrentValues.delete(inputsItems[x].fields.Id_Salesforce);
                    

                    
                    this.listWithRecordUpdate = this.jsonObject;
                }
                if(myMapCurrentValues.size > 0){
                    console.log('myMapCurrentValues2:', myMapCurrentValues.size);
                    for(var [key, value] of myMapCurrentValues){
                        
                        console.log('key: '+myMapCurrentValues.get(key));
                        this.jsonObject.push({
                            "Id":key,
                            "Name":value.Name,
                            "Quantity__c":value.Quantity,
                            "UnitPrice__c":value.UnitPrice,
                            "ProductDescription__r.Name":value.ProductDescription
                        });
                        this.listWithRecordUpdate = this.jsonObject;
                    }
                    
                }
                console.log('List test: '+JSON.stringify(this.listWithRecordUpdate));
                console.log('List test size: '+this.listWithRecordUpdate.length);
            //this.recordTable();
            }
        this.renderButton = true;
        this.saveHandleAction();
        if(this.renderMessageTotal == false && this.renderMessageEuLit == false){
            this.handleNext();
        }
        
    }
    handleKeyUp(event){
        this.isEditing = true;
    }
    recordTable(){
        var array = [];
        for(let x =0;this.records.length>x;x++){
            array.push(this.records[x].Id);
        }
        if(array.length>0){
            getOrderItems({listIds:array})
            .then((result) => {
                console.log(result);
                console.log('recorda table result : '+JSON.stringify(result));
                this.recordsForTable = result;
                console.log(result);
                this.renderMessageEuLit = false;
                this.cantidad = 0;
                //this.recordTable();
                //this.record = this.recordTable();
                //console.log('record: '+this.record);
                
                console.log('connectedCallback 1: '+this.recordsForTable);
                if(this.recordsForTable.length>0){
                    console.log('connectedCallBack 2: '+JSON.stringify(this.recordsForTable));
                    console.log('connectedCallBack 2: '+JSON.stringify(this.recordsForTable));
                    for(let x = 0;x<this.recordsForTable.length;x++){
                        this.cantidad+= parseFloat(this.recordsForTable[x].Quantity);
                        if(parseFloat(this.recordsForTable[x].UnitPrice) < 0.5 || parseFloat(this.recordsForTable[x].UnitPrice) > 3 ){
                            this.renderMessageEuLit = true;
                        }
                    }
                    console.log(this.cantidad);
                    if(this.cantidad>35000 || this.cantidad < 1000){
                        this.renderMessageTotal = true;
                    }else{
                        this.renderMessageTotal = false;
                    }
                }
            })
            .catch((error) => {
                this.error = error;
                console.log(this.error);
            });
        }
        
    }
    
    handleNext() {
        this.saveHandleAction();
        const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
    }

    handlePrevious() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }
    handleCancel(){
        this.noModified = true;
    }

}
public with sharing class LwcOrderItemTable {
    
    @AuraEnabled
    public static List<wrapperData> getOrderItems(List<String> listIds){
        List<OrderItem__c> newListOrderItems = [SELECT Name,BasePrice__c,MinimalPrice__c,UnitPrice__c,Quantity__c,ProductDescription__r.Name FROM OrderItem__c WHERE ID in:listIds Order by ProductDescription__r.Name asc];
        List<wrapperData> listWrp = new List<wrapperData>();
        for(OrderItem__c ord: newListOrderItems){
            wrapperData wrp = new wrapperData(ord);
            
            listWrp.add(wrp);
        }
        System.debug('listWrp: ' + listWrp);
        return listWrp;
    }


    public class wrapperData{
        @AuraEnabled public String Id_Salesforce { get; set;}
        @AuraEnabled public String Name { get; set;}
        @AuraEnabled public Decimal Quantity { get; set;}
        @AuraEnabled public Decimal UnitPrice  { get; set;}
        @AuraEnabled public String ProductDescription{get;set;}
        public  wrapperData(OrderItem__c ord){
            Id_Salesforce = ord.Id;
            Name = ord.Name;
            Quantity = ord.Quantity__c;
            UnitPrice = ord.UnitPrice__c;
            ProductDescription = ord.ProductDescription__r.Name;
            
        }
        
    }
}
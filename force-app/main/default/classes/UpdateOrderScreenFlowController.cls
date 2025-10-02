public with sharing class UpdateOrderScreenFlowController {
    @AuraEnabled
    public static String callOutA3(Order__c ord ,List<OrderItem__c> listOrderItems,String credentialToUse) {
        System.debug('llega callOutA3: ');
        Portal_Configuration__mdt metadata = Portal_Configuration__mdt.getInstance('Default');
        
        A3_Integration_Credential__mdt credentials = [SELECT MasterLabel,Support__c, URL__c,ModifyOrder__c,DeleteOrder__c, Username__c, Password__c, Service_Auth__c, Energy__c , Distribution__c, Service_Create_Account__c, Service_Create_Order__c FROM A3_Integration_Credential__mdt WHERE DeveloperName = :metadata.Credential_to_use__c];
        String result = handleConnections(ord,listOrderItems,credentials);
        return result;
            
    }

    private static String handleConnections (Order__c ord, List<OrderItem__c> listOrderItems,A3_Integration_Credential__mdt credentials){
        Account relatedAcc = [SELECT Business__c FROM Account WHERE id=:ord.Account__c];
        String bbService = ''; 
        if(relatedAcc.Business__c == 'Energía'){
            bbService = credentials.Energy__c;
        }else if(relatedAcc.Business__c == 'Suministro'){
            bbService = credentials.Support__c;
        }
        System.debug('llega handleConnections: '+listOrderItems);
        HttpResponse responseToken = getA3AuthToken(50000,credentials,bbService);
        System.debug('llega responseToken'+responseToken);
        //System.debug(statusCode);
        
        if(responseToken.getStatusCode() == 200 ||responseToken.getStatusCode() == 204){
            String token = responseToken.getBody();
            if(token != null){
                HttpResponse tryModifiedOrder = modifiedOrder(ord,listOrderItems,token,credentials,bbService);
                Integer statusModified = tryModifiedOrder.getStatusCode();
                if(tryModifiedOrder.getStatusCode() == 200){
                    return String.valueof(statusModified);
                }else{
                    return 'Error';
                }
            }else{
                return 'Error';
            }
            
            
        }else{
            return 'Error';
        }

    }

    
    private static HttpResponse getA3AuthToken(Integer timeOut,A3_Integration_Credential__mdt credentials,String bbService){
        
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(credentials.URL__c+credentials.Service_Auth__c.replace('{{company}}', bbService));
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        AuthBodyWrapper authObj = new AuthBodyWrapper(credentials.Username__c,credentials.Password__c);
        request.setBody(authObj.getBody());
        if(timeOut != null){
            request.setTimeout(timeOut);
        }
        System.debug('getA3AuthToken request: ' + request);
        System.debug('getA3AuthToken request.getBody() ' + request.getBody());
        Http http = new Http();
        HttpResponse response = Test.isRunningTest()?MockTest.mockTokenOk():http.send(request);
        System.debug('getA3AuthToken response: ' + response);
        System.debug('response.getBody(): ' + response.getBody());
		return response;
	}

    public class AuthBodyWrapper{
        public String Username { get; set;}
        public String Password  { get; set;}
        public AuthBodyWrapper(String name, String pass){
            Username = name;
            Password = pass;
        }
        public String getBody(){
            return 'Username='+EncodingUtil.urlEncode(Username,'UTF-8')+
                    '&Password='+EncodingUtil.urlEncode(Password,'UTF-8');
        }
    }

    private static HttpResponse modifiedOrder(Order__c ord , List<OrderItem__c> listOrderItems,String token,A3_Integration_Credential__mdt credentials,String bbService){
        
		
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        System.debug('credentials: ' + credentials);
        request.setEndpoint(credentials.URL__c+credentials.ModifyOrder__c.replace('{{company}}', bbService));
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', token.replace('"', ''));
        System.debug('token: ' + token.replace('"', ''));
        System.debug('listOrderItems: ' + listOrderItems);
        OrderBodyWrapper orderBody = new OrderBodyWrapper(ord,listOrderItems);
        request.setBody(JSON.serialize(orderBody));
        
        System.debug('getA3AuthToken request: ' + request);
        System.debug('getA3AuthToken request.getBody() ' + request.getBody());
        Http http = new Http();
        HttpResponse response = Test.isRunningTest()?MockTest.mockTokenOk():http.send(request);
        System.debug('getA3AuthToken response: ' + response);
        System.debug('response.getBody(): ' + response.getBody());
		return response;
    }

    public class OrderBodyWrapper{
        public String Id_Salesforce { get; set;}
        public String AccountCodeA3 { get; set;}
        public Date OrderDate  { get; set;}
        public Date ExpirationDate  { get; set;}
        public String Carrier  { get; set;}
        public String Store  { get; set;}
        public String OwnerId  { get; set;}
        public String Sale15  { get; set;}
        public String PaymentMethod  { get; set;}
        public List<LineOrderBodyWrapper> lineas  { get; set;}

        public OrderBodyWrapper(Order__c ord,List<OrderItem__c> lineItems){
            Account selectRelatedRecords = [SELECT ClientCodeA3__c,RepresentativeCode__c FROM Account where Id=:ord.Account__c];
            Carrier__c selectRelatedRecords2 = [SELECT CarrierCode__c FROM Carrier__c WHERE ID=: ord.Carrier__c];
            Id_Salesforce = ord.id;
            AccountCodeA3 = selectRelatedRecords.ClientCodeA3__c==null?'':selectRelatedRecords.ClientCodeA3__c;
            Store = ord.Store__c;
            Carrier = selectRelatedRecords2.CarrierCode__c ;
            OrderDate = ord.OrderDate__c!=null?date.newinstance(ord.OrderDate__c.year(), ord.OrderDate__c.month(), ord.OrderDate__c.day()):null;
            ExpirationDate = ord.ExpirationDateTime__c!=null?date.newinstance(ord.ExpirationDateTime__c.year(), ord.ExpirationDateTime__c.month(), ord.ExpirationDateTime__c.day()):null;
            Sale15 = ord.Sale15__c?'T':'F';

            OwnerId = selectRelatedRecords.RepresentativeCode__c;
            PaymentMethod = ord.PaymentMethod__c == null?'':ord.PaymentMethod__c;

            List<LineOrderBodyWrapper> orderItems = new List<LineOrderBodyWrapper>();
            
            Set<Id> allIdsProduct = new Set<Id>();
            for(OrderItem__c item : lineItems){
                allIdsProduct.add(item.Id);
                
            }
            System.debug('allIdsProduct: ' + allIdsProduct);
            List<OrderItem__c> getProductDescription = [SELECT ID ,ProductDescription__c, ProductDescription__r.Name FROM OrderItem__c WHERE ID IN:(allIdsProduct)];
            Map<String,OrderItem__c> mapNameProducts = new Map<String,OrderItem__c>();
            for(OrderItem__c odr: getProductDescription){
                    mapNameProducts.put(odr.Id,odr);
            }
            System.debug('mapNameProducts: ' + mapNameProducts);
            System.debug('getProductDescription: ' + getProductDescription);
            for(OrderItem__c item : lineItems){
                System.debug('mapNameProducts.get(item.Id): ' + mapNameProducts.get(item.Id));
                System.debug('item: ' + item);
                orderItems.add(new LineOrderBodyWrapper(item,mapNameProducts.get(item.Id)));
            }
            
            lineas = orderItems;
        }
    }

    public class LineOrderBodyWrapper{
        public String Id_Salesforce { get; set;}
        public String ProductCode { get; set;}
        public String ProductDescription { get; set;}
        public Decimal Quantity  { get; set;}
        public Decimal UnitPrice  { get; set;}

        public LineOrderBodyWrapper(OrderItem__c orderItem,OrderItem__c Product){
            Id_Salesforce = orderItem.id;
            ProductCode = orderItem.ProductDescription__c == null ? Product.ProductDescription__c :  orderItem.ProductDescription__c;
            ProductDescription = orderItem.ProductDescription__r.Name==null?Product.ProductDescription__r.Name:orderItem.ProductDescription__r.Name;
            Quantity = orderItem.Quantity__c;
            UnitPrice = orderItem.UnitPrice__c;
        }
    }

    @InvocableMethod(label='Delete Order From A3')
    public static List<String> getAccountNames(List<String> data) {
        String[] dataArray = data[0].split(';');
        Order__c currentOrder = [SELECT Account__r.Id FROM Order__c WHERE ID=:dataArray[1]];
        Account relatedAcc = [SELECT Business__c FROM Account WHERE id=:currentOrder.Account__r.Id];
        Portal_Configuration__mdt metadata = Portal_Configuration__mdt.getInstance('Default');

        A3_Integration_Credential__mdt credentials = [SELECT MasterLabel,DeleteOrder__c, URL__c, Username__c, Password__c, Service_Auth__c, Energy__c , Support__c, Service_Create_Account__c, Service_Create_Order__c FROM A3_Integration_Credential__mdt WHERE DeveloperName = :metadata.Credential_to_use__c];
        String bbService = ''; 
        if(relatedAcc.Business__c == 'Energía'){
            bbService = credentials.Energy__c;
        }else if(relatedAcc.Business__c == 'Suministro'){
            bbService = credentials.Support__c;
        }
        HttpResponse responseToken = getA3AuthToken(50000,credentials,bbService);
        if(responseToken.getStatusCode() == 200 || responseToken.getStatusCode() == 201){
            String token = responseToken.getBody();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(credentials.URL__c+credentials.DeleteOrder__c.replace('{{company}}', bbService));
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', token.replace('"', ''));
            System.debug('token: ' + token.replace('"', ''));
            wrapperIdsToDelete deleteIds = new wrapperIdsToDelete(dataArray[1]);
            request.setBody(JSON.serialize(deleteIds));
            
            System.debug('getA3AuthToken request: ' + request);
            System.debug('getA3AuthToken request.getBody() ' + request.getBody());
            Http http = new Http();
            HttpResponse response = Test.isRunningTest()?MockTest.mockTokenOk():http.send(request);
            System.debug('getA3AuthToken response: ' + response);
            return new List<String>{String.valueOf(response.getStatusCode())};
        }else{
            return new List<String>{'Error'};
        }
    }

    public class wrapperIdsToDelete{
        public String Id_Salesforce { get; set;}

        public wrapperIdsToDelete(String Id){
            Id_Salesforce = Id;
        }
    }

}
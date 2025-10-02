public without sharing class A3IntegrationService {

    /**
	* @description Gets the response from selected Named Credential
	* @param credential credential to get on metadata
	* @param method method type
	* @param serviceText type of request
	* @param acc account to send
	* @param timeOut waiting time
	* @return HttpResponse
	**/
	public static String getRequestWithBody(String method, String serviceText, sObject obj, Integer timeOut){
        
        String responseA3Service;
        Portal_Configuration__mdt metadata = Portal_Configuration__mdt.getInstance('Default');

        List<A3_Integration_Credential__mdt> credentials = [SELECT MasterLabel, URL__c, Username__c, Password__c, Service_Auth__c, Support__c, Energy__c , Distribution__c, Service_Create_Account__c, Service_Create_Order__c FROM A3_Integration_Credential__mdt WHERE DeveloperName = :metadata.Credential_to_use__c];
		
        //If find credential
        if(credentials != null || !credentials.isEmpty()){

            A3_Integration_Credential__mdt credential = credentials.get(0);
            String service;
            String companyService;
            String serializeObj;

            //Get specific data depend of service
            if(serviceText == 'Client'){
                Account acc = (Account) obj;
                service = credential.Service_Create_Account__c;
                companyService = getBBService(credential, acc.Business__c);
                serializeObj = JSON.serialize(new AccBodyWrapper(acc, acc.Business__c));
            }
            else if(serviceText == 'Order'){
                Order__c order = (Order__c) obj;
                service = credential.Service_Create_Order__c;
                companyService = getBBService(credential, order.Account__r.Business__c);
                serializeObj = JSON.serialize(new OrderBodyWrapper(order, order.Account__r.Business__c));
                System.debug('serializeObj: ' + serializeObj);
            }

            //Call A3 WS AUTH
            HttpResponse authResponse = getA3AuthToken(credential, companyService, timeOut);
            
            //If has token
            if(authResponse.getStatusCode() == 200 || authResponse.getStatusCode() == 204) {
                
                //Call A3 WS CREATE
                HttpResponse response = getA3WS(credential, authResponse, method, serializeObj, service, companyService, timeOut);

                ReponseWrapper responseObj;

                //If Inserted
                if(response.getStatusCode() == 200 || response.getStatusCode() == 204) {
                    responseObj = (ReponseWrapper) JSON.deserialize(response.getBody(), ReponseWrapper.class);
                    if(String.isBlank(responseObj.error.message)){
                        responseA3Service = 'INSERT ' + serviceText + ': '+responseObj.data;
                    }else{
                        responseA3Service = 'ERROR INSERT ' + serviceText + ': '+responseObj.error.message;
                    }
                }
                else if(response.getStatusCode() == 503 || response.getStatusCode() == 500){
                    responseA3Service = 'ERROR INSERT ' + serviceText + ': '+response.getStatus()+' - '+response.getBody();
                }
                else{
                    responseObj = (ReponseWrapper) JSON.deserialize(response.getBody(), ReponseWrapper.class);
                    responseA3Service = 'ERROR INSERT ' + serviceText + ': '+response.getStatus()+'-'+responseObj.error.message;
                }
            }
            else{
                responseA3Service = 'ERROR AUTH: '+authResponse.getStatus()+' - '+authResponse.getBody();
            }
        }
        
        System.debug('getRequestWithBody responseA3Service: ' + responseA3Service);
		return responseA3Service;
	}

	private static String getBBService(A3_Integration_Credential__mdt credential, String company){
        String bbService='';
        if(company == 'Energía'){
            bbService = credential.Energy__c;
        }else if(company == 'Distribución'){
            bbService = credential.Distribution__c;
        }else if(company == 'Suministro'){
            bbService = credential.Support__c;
        }
		return bbService;
	}

	private static HttpResponse getA3AuthToken(A3_Integration_Credential__mdt credential, String bbService, Integer timeOut){

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(credential.URL__c+credential.Service_Auth__c.replace('{{company}}', bbService));
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        AuthBodyWrapper authObj = new AuthBodyWrapper(credential.Username__c,credential.Password__c);
        request.setBody(authObj.getBody());
        if(timeOut != null){
            request.setTimeout(timeOut);
        }
        System.debug('getA3AuthToken request: ' + request);
        System.debug('getA3AuthToken request.getBody() ' + request.getBody());
        Http http = new Http();
        
        HttpResponse response = Test.isRunningTest()?MockTest.mockTokenOk():http.send(request);
        System.debug('getA3AuthToken response: ' + response);
		return response;
	}

	private static HttpResponse getA3WS(A3_Integration_Credential__mdt credential, HttpResponse authResponse, String method, String bodyText, String service, String companyService, Integer timeOut){

        String token = 'Bearer ' + authResponse.getBody().replace('"', '');
        System.debug('getA3WS token: ' + token);

        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(credential.URL__c + service.replace('{{company}}', companyService));
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', token);
        request.setBody(bodyText);
        if(timeOut != null){
            request.setTimeout(timeOut);
        }
        System.debug('getA3WS request: ' + request);
        System.debug('getA3WS request.getBody() ' + request.getBody());
        Http http = new Http();
        HttpResponse response = Test.isRunningTest()?MockTest.mockCreate():http.send(request);
        System.debug('getA3WS response: ' + response);
        System.debug('getA3WS response.getBody(): ' + response.getBody());
		return response;
	}

	public static void sendEmail(Boolean error, Id recordId){
        Portal_Configuration__mdt metadata = Portal_Configuration__mdt.getInstance('Default');
        String[] toAddresses = metadata.Email_A3__c.split(';');
        EmailTemplate template = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Client_information_created' LIMIT 1];
       
        if(error){
            template = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Client_information_created_ws_error' LIMIT 1];
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setTemplateId(template.Id);
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setWhatId(recordId);
        mail.setSaveAsActivity(false);
        System.debug('mail: ' + mail);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

	}

    public class ReponseWrapper{
        public String data { get; set;}
        public ErrorWrapper error  { get; set;}
        public ReponseWrapper(String data, ErrorWrapper error){
            this.data = data;
            this.error = error;
        }
    }

    public class ErrorWrapper{
        public String message { get; set;}
        public Integer code  { get; set;}
        public ErrorWrapper(String message, Integer code){
            this.message = message;
            this.code = code;
        }
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

    public class AccBodyWrapper{
        public String Id_Salesforce { get; set;}
        public String Name { get; set;}
        public String Cif  { get; set;}
        public String BillingStreet  { get; set;}
        public String BillingPostalCode  { get; set;}
        public String BillingCountry  { get; set;}
        public String BillingState  { get; set;}
        public String BillingCity  { get; set;}
        public String Email  { get; set;}
        public String Phone  { get; set;}
        public String TaxRate  { get; set;}
        public String Representante  { get; set;}

        public AccBodyWrapper(Account acc, String company){
            Id_Salesforce = acc.id;
            Name = acc.Name;
            Cif = acc.CIF__c;
            BillingStreet = acc.BillingStreet;
            BillingPostalCode = acc.BillingPostalCode;
            BillingState = acc.BillingState;
            BillingCity = acc.BillingCity;
            Email = acc.Email__c;
            Phone = acc.Phone;
            TaxRate = acc.TaxRate__c;

            BillingCountry = acc.BillingCountry;
            if(!String.isBlank(acc.BillingCountry)){
                for(Country__mdt country : [SELECT DeveloperName FROM Country__mdt WHERE Label = :acc.BillingCountry]){
                    BillingCountry = country.DeveloperName;
                }
            }


            List<Lead> lLeadConverted = [SELECT Id, OwnerId FROM Lead WHERE ConvertedAccountId = :acc.id];
            if(!lLeadConverted.isEmpty()){
                User userOwner = [SELECT Id, DistributionUserCode__c, EnergyUserCode__c, SupportUserCode__c FROM User WHERE id = :lLeadConverted.get(0).OwnerId];
                Representante = userOwner.DistributionUserCode__c;
                if(company == 'Energía'){
                    Representante = userOwner.EnergyUserCode__c;
                }else if(company == 'Suministro'){
                    Representante = userOwner.SupportUserCode__c;
                }
            }
        }
    }

    public class OrderBodyWrapper{
        public String Id_Salesforce { get; set;}
        public String AccountCodeA3 { get; set;}
        public DateTime OrderDate  { get; set;}
        public DateTime ExpirationDate  { get; set;}
        public String Carrier  { get; set;}
        public String Store  { get; set;}
        public String OwnerId  { get; set;}
        public String Sale15  { get; set;}
        public String PaymentMethod  { get; set;}
        public List<LineOrderBodyWrapper> lineas  { get; set;}

        public OrderBodyWrapper(Order__c ord, String company){
            Id_Salesforce = ord.id;
            AccountCodeA3 = ord.Account__r.ClientCodeA3__c;
            Store = ord.Store__c;
            Carrier = ord.Carrier__r.CarrierCode__c;
            OrderDate = (ord.OrderDate__c != null) ? ord.OrderDate__c : null;
            ExpirationDate = (ord.ExpirationDateTime__c != null) ? ord.ExpirationDateTime__c : null;
            // OrderDate = ord.OrderDate__c!=null?date.newinstance(ord.OrderDate__c.year(), ord.OrderDate__c.month(), ord.OrderDate__c.day()):null;
            // ExpirationDate = ord.ExpirationDateTime__c!=null?date.newinstance(ord.ExpirationDateTime__c.year(), ord.ExpirationDateTime__c.month(), ord.ExpirationDateTime__c.day()):null;
            Sale15 = ord.Sale15__c?'T':'F';
            if(ord.Account__r.Parent!=NULL){
            	OwnerId = ord.Account__r.Parent.RepresentativeCode__c;
            }else{
                OwnerId=ord.Account__r.RepresentativeCode__c;
            }
            PaymentMethod = ord.PaymentMethod__c;

            List<LineOrderBodyWrapper> orderItems = new List<LineOrderBodyWrapper>();
            for(OrderItem__c item : ord.Lineas_de_pedido__r){
                orderItems.add(new LineOrderBodyWrapper(item));
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

        public LineOrderBodyWrapper(OrderItem__c orderItem){
            Id_Salesforce = orderItem.id;
            ProductCode = orderItem.ProductDescription__r.Id;
            ProductDescription = orderItem.ProductDescription__r.Name;
            Quantity = orderItem.Quantity__c;
            UnitPrice = orderItem.UnitPrice__c;
        }
    }
}
public without sharing class ProductsSelectorController {
	/**
	 * Method to get all products and prices from selected pricebook
	 * @param pricebookId current pricebook
	 * @param pageSize max records per page
	 * @param pageNum current page
	 * @param searchText text to filter products
	 * @return pricebook entries list
	 */
	@AuraEnabled
	public static List<PricebookEntry> getPricebookEntries(String store, Integer pageSize, Integer pageNum, String searchText){
		List<PricebookEntry> lPrices;
		List<String> myPicklist = new List<String>();
      	Schema.DescribeFieldResult field = PriceBookEntry.Store__c.getDescribe();
		Integer count = 0;
		for (Schema.PicklistEntry f : field.getPicklistValues()){
			if(f.getValue()== store && f.getLabel().contains('CLH')){
				count++;
			}
			
		}
		
		String query;
		if(count>0){
			query = 'SELECT Id, Name, Product2.Name, ProductCode, UnitPrice FROM PricebookEntry WHERE Store__c = \'ALBUIXEC\' AND IsActive = true';
		}else{
			query = 'SELECT Id, Name, Product2.Name, ProductCode, UnitPrice FROM PricebookEntry WHERE Store__c = :store AND IsActive = true';
		}
		
		if(searchText != null && searchText != ''){
			searchText = '%'+searchText+'%';
			query += ' AND Product2.Name LIKE :searchText';
			query += ' AND Product2.ProductCode LIKE :searchText ';
			
		}
		query += ' ORDER BY Product2.Name ASC ';
		if(pageNum < 1){
			query += ' OFFSET ' + pageSize*(pageNum-1);
		}
		query += ' LIMIT ' + pageSize;
		lPrices = Database.query(query);
		return lPrices;
	}

	/**
	 * Method to get all products and prices from selected ids
	 * @param pricebookId current pricebook
	 * @return pricebook entries list
	 */
	@AuraEnabled
	public static List<Account> getSelectedShippingAddress(Id AccId){
		List<Account> ShippingAddressInfo = [SELECT Id, Name, Alias__c FROM Account WHERE Id=: AccId];
		return ShippingAddressInfo;
	}

	@AuraEnabled
	public static List<Carrier__c> getSelectedCarrier(Id CarrierId){
		List<Carrier__c> car = [SELECT Id, Name FROM Carrier__c WHERE Id=: CarrierId];
		return car;
	}


	@AuraEnabled
	public static List<PricebookEntry> getSelectedPricebookEntries(List<String> lSelected){
		List<PricebookEntry> lPrices = [SELECT Id, Name, Product2Id, Product2.Name, ProductCode, UnitPrice FROM PricebookEntry WHERE id IN :lSelected order by Name asc];
		System.debug('lPrices: ' + lPrices);
		return lPrices;
	}

	/**
	 * Method to get all products and create opp and opplineItems
	 * @param listPrices selected prices
	 * @param selAccountStore selected store
	 * @param AccountId Account Id
	 * @return record Id
	 */
	@AuraEnabled
	public static String createOpp(List<Map<String, String>> listPrices, String selAccountStore, String AccountId, string Paymethod, string Type, Datetime closeDate, Datetime orderStartDate){		
		
		Account acc = [SELECT Id, OwnerId, Name, ParentId, TaxRate__c FROM Account WHERE id =:AccountId LIMIT 1];
		String RecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Operador/Retail').getRecordTypeId();
		Carrier__c Transportista = [SELECT Id, name FROM Carrier__c where CarrierCode__c= '0' and Business__c='Energía'];
		string Carrier;

		system.debug(listPrices[0].get('CarrierId'));

		if(listPrices[0].get('CarrierId') == '' || listPrices[0].get('CarrierId') == null){
				Carrier = Transportista.Id;
			}
		else {
				Carrier = listPrices[0].get('CarrierId');
			}

		Opportunity newopp = new Opportunity(
			Name = acc.Name,
			AccountId = AccountId,
			Carrier__c = Carrier,
			Type_of_opportunity__c = Type,
			CloseDate = Date.today(),
			OrderExpirationDateTime__c = closeDate,
			OrderStartDateTime__c = orderStartDate,
			Store__c = selAccountStore,
			OwnerId = acc.OwnerId,
			StageName = 'Pendiente Pago',
			RecordTypeId = RecordTypeID,
            TaxRate__c = acc.TaxRate__c, 
            PaymentMethod__c= Paymethod, 
            ParentId__c = acc.ParentId  
		);

		insert newopp;
		
		Opportunity Opp = [Select OpportunityNumber__c from Opportunity where Id=: newopp.Id limit 1];

		Opp.Name = Opp.OpportunityNumber__c;
		update Opp;

		List<OpportunityLineItem> listOppLines = new List<OpportunityLineItem>();
		for(Map<String, String> newPrice : listPrices){
			listOppLines.add(
				new OpportunityLineItem(
					OpportunityId = newopp.Id,
					Alias__c = newPrice.get('Alias'),
					OrderNumber__c = newPrice.get('Pedido'),
					Product2Id = newPrice.get('Id'),
					Quantity = decimal.valueOf(newPrice.get('Quantity')),
					UnitPrice = decimal.valueOf(newPrice.get('UnitPrice'))
				)
			);
		}
		insert listOppLines;
		
		return newopp.Id;
	}



	@AuraEnabled
	public static String createProformaBorrador(List<Map<String, String>> listPrices, List<String> listEntryIds, String selAccountStore, String AccountId, string oppId, string Paymethod, Datetime closeDate, Datetime orderStartDate){		
		
		Map<String, PricebookEntry> mapEntryProd = new Map<String, PricebookEntry>();
		for(PricebookEntry price : [SELECT Id, Product2Id, MinimalPrice__c, UnitPrice FROM PricebookEntry WHERE Id = :listEntryIds ORDER BY Product2.Name ASC]){
			mapEntryProd.put(price.Id, price);
		}

		Account acc = [SELECT Id, OwnerId, Name, ParentId, TaxRate__c FROM Account WHERE id =:AccountId LIMIT 1];
		String RecordTypeID = Schema.SObjectType.Proforma_Borrador__c.getRecordTypeInfosByName().get('Operador').getRecordTypeId();
		Carrier__c Transportista = [SELECT Id, name FROM Carrier__c where CarrierCode__c= '0' and Business__c='Energía'];
		string Carrier;
		string IdCuenta;

		if(listPrices[0].get('CarrierId') == '' || listPrices[0].get('CarrierId') == null){
				Carrier = Transportista.Id;
			}
		else {
				Carrier = listPrices[0].get('CarrierId');
			}
		
		if(listPrices[0].get('shippingAddressId') == '' || listPrices[0].get('shippingAddressId') == null){
			IdCuenta = AccountId;
		}
		else {
			IdCuenta = listPrices[0].get('shippingAddressId');
		}
		
		Proforma_Borrador__c newopp = new Proforma_Borrador__c(
			Name = acc.Name,
			AccountId__c = IdCuenta,
			Carrier__c = Carrier,
			ProformaId__c = oppId,
			CloseDate__c = Date.today(),
			OrderExpirationDateTime__c = closeDate,
			OrderStartDateTime__c = orderStartDate,
			Store__c = selAccountStore,
			OwnerId = acc.OwnerId,
			StageName__c = 'Pendiente Pago',
			RecordTypeId = RecordTypeID,
            TaxRate__c = acc.TaxRate__c, 
            PaymentMethod__c= Paymethod, 
            ParentId__c = acc.ParentId  
		);

		insert newopp;

	
		List<Line_Proforma__c> listOppLines = new List<Line_Proforma__c>();
		for(Map<String, String> newPrice : listPrices){
			listOppLines.add(
				new Line_Proforma__c(
					Proforma_Borrador__c = newopp.Id,
					Product2Id__c = mapEntryProd.get(newPrice.get('Id')).Product2Id,
					Quantity__c = decimal.valueOf(newPrice.get('Quantity')),
					UnitPrice__c = decimal.valueOf(newPrice.get('UnitPrice'))
				)
			);
		}
		insert listOppLines;
		
		return newopp.Id;
	}

	/**
	 * Method to get all products and prices from selected pricebook
	 * @param listPrices selected prices
	 * @param newOrder selected new order
	 * @return record Id
	 */
	@AuraEnabled
	public static String createOrder(List<Map<String, String>> listPrices, List<String> listEntryIds, Order__c newOrder){		
		Map<String, PricebookEntry> mapEntryProd = new Map<String, PricebookEntry>();
		for(PricebookEntry price : [SELECT Id, Product2Id, MinimalPrice__c, UnitPrice FROM PricebookEntry WHERE Id = :listEntryIds ORDER BY Product2.Name ASC]){
			mapEntryProd.put(price.Id, price);
		}

		Account acc = [SELECT Id, OwnerId FROM Account WHERE id = :newOrder.Account__c LIMIT 1];
		//newOrder.OwnerId = acc.OwnerId;
		insert newOrder;

		List<OrderItem__c> listOrderLines = new List<OrderItem__c>();
		for(Map<String, String> newPrice : listPrices){
			listOrderLines.add(
				new OrderItem__c(
					Pedido__c = newOrder.Id,
					ProductDescription__c = mapEntryProd.get(newPrice.get('Id')).Product2Id,
					UnitPrice__c = decimal.valueOf(newPrice.get('UnitPrice')),
					Quantity__c = decimal.valueOf(newPrice.get('Quantity')),
					BasePrice__c = mapEntryProd.get(newPrice.get('Id')).UnitPrice,
					MinimalPrice__c = mapEntryProd.get(newPrice.get('Id')).MinimalPrice__c
				)
			);
		}
		insert listOrderLines;
		
		createOrderOnA3(newOrder.Id);
		return newOrder.Id;
	}

	@AuraEnabled
	public static void createOrderOnA3(String recordId){

        sObject obj = [SELECT id,PaymentMethod__c,Name,Account__r.Business__c,Account__r.ClientCodeA3__c,Account__r.Parent.RepresentativeCode__c, Account__r.RepresentativeCode__c , OrderNumber__c,Store__c,Carrier__r.CarrierCode__c,Sale15__c,OrderDate__c,ExpirationDateTime__c,OwnerId,
        (
            SELECT id,ProductDescription__r.Id,ProductDescription__r.Name,ProductDescription__r.ProductCode,ProductDescription__r.Description,Quantity__c,UnitPrice__c 
            FROM Lineas_de_pedido__r
        ) 
        FROM Order__c 
        WHERE id = :recordId Order by Name asc];
		
		QueueCallA3Service newQueue = new QueueCallA3Service(recordId, 'POST', 'Order', obj, 50000);
		System.enqueueJob(newQueue);
    }

}
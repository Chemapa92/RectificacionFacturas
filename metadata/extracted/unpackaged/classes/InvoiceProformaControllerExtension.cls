public class InvoiceProformaControllerExtension {
	private final Opportunity opp;
    public InvoiceProformaControllerExtension(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
    }

    public String getAlmacen(){
    	String almacen = 'default';
    	List<Schema.Picklistentry> fieldResult = Opportunity.Store__c.getDescribe().getPicklistValues();
    	for(Schema.PicklistEntry f : fieldResult) {
        	if (f.getValue() == opp.Store__c) {
            	almacen = f.getLabel();
        	}
    	}
    	return almacen;
	}

}
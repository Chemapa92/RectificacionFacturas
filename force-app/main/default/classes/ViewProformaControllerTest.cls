@isTest
private class ViewProformaControllerTest {

    @TestSetup
    private static void makeData(){
        Opportunity opp = new Opportunity(
            Name = 'unittest',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        ); 
        insert opp;
    }

    @IsTest
    public static void getInvoiceNameTest() {
        Test.startTest();
            Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1]; 
            String result = ViewProformaController.getProformaName(opp.Id); 
            System.assert(result.contains(opp.Name), 'Error: no contiene el nombre de la oportunidad'); 
            
            System.assert(result.startsWith('Proforma'), 'Error: no comienza con "Proforma"');
            
            String expectedDate = Date.today().day() + '/' + Date.today().month() + '/' + Date.today().year();
            System.assert(result.contains(expectedDate), 'Error: no contiene la fecha de hoy');
        Test.stopTest();
    }
}
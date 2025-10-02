public with sharing class ViewProformaController {
    @AuraEnabled
    public static String getProformaName(String recordId){
        String proformaName = 'Proforma';
        List<Opportunity> lProforma = [SELECT Id, Name FROM Opportunity WHERE id = :recordId];
        if(lProforma != null && !lProforma.isEmpty()){
            proformaName += ' ' + lProforma.get(0).Name;
        }
        proformaName += ' ' + Date.today().day() + '/' + Date.today().month() + '/' + Date.today().year(); 
        return proformaName;
    }
}
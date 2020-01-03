
public with sharing class EmailTemplateSelector extends Selector {

    public EmailTemplateSelector() {
        super(new List<SObjectField>{
                EmailTemplate.Id,
                EmailTemplate.Name,
                EmailTemplate.DeveloperName
        }, EmailTemplate.SObjectType);
    }


    public EmailTemplateSelector withBody() {
        this.query.selectField(EmailTemplate.Body);
        return this;
    }


    /**
     * @param names List<String> or (Iterable<String>) Set<String> of Email Template names
     * @return Email Templates with given names
     */
    public Account[] byNames(Iterable<String> names) {
        query.setWhere('Name IN :names');
        return Database.query(query.build());
    }


    /**
     * @param developerName Developer Name of Email Template
     * @return Email Template with given name or null
     */
    public Account byDeveloperName(String developerName) {
        query.setWhere('Name = :developerName');
        return (Account) firstOrNull(Database.query(query.build()));
    }

    /**
     * @param developerNames List<String> or (Iterable<String>) Set<String> of Email Template developer names
     * @return Email Templates with given names
     */
    public Account[] byDeveloperNames(Iterable<String> developerNames) {
        query.setWhere('Name IN :developerNames');
        return Database.query(query.build());
    }
}
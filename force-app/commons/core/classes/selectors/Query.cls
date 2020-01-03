/**
 *
 */
public inherited sharing class Query {
    public final static AccountSelector Accounts { get {return new AccountSelector();} }
    public final static BusinessHoursSelector BusinessHours { get {return new BusinessHoursSelector();} }
    public final static ContactSelector Contacts { get {return new ContactSelector();} }
    public final static QueueSelector Groups { get {return new QueueSelector();} }
    public final static LeadSelector Leads { get {return new LeadSelector();} }
    public final static OpportunitySelector Opportunities { get {return new OpportunitySelector();} }
    public final static PermissionSetSelector PermissionSets { get {return new PermissionSetSelector();} }
    public final static PricebookSelector Pricebooks { get {return new PricebookSelector();} }
    public final static ProfileSelector Profiles { get {return new ProfileSelector();} }
    public final static RecordTypeSelector RecordTypes { get {return new RecordTypeSelector();} }
    public final static UserRoleSelector UserRoles { get {return new UserRoleSelector();} }
    public final static UserSelector Users { get {return new UserSelector();} }

    public static ShareSelector RecordShares(SObjectType shareSObjectType) {
        return new ShareSelector(shareSObjectType);
    }

    public static HistorySelector RecordHistory(SObjectType shareSObjectType) {
        return new HistorySelector(shareSObjectType);
    }
}
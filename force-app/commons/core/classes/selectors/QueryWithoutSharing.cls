/**
 *
 */
public without sharing class QueryWithoutSharing {
    public final static AccountSelector Accounts { get {return new AccountSelector();} }
    public final static UserSelector Users = new UserSelector();
    public final static ProfileSelector Profiles = new ProfileSelector();
}
public class DMLOptionsBuilder {
    private Database.DMLOptions dmlOptions = new Database.DMLOptions();


    /**
     * For a duplicate rule, when the Alert option is enabled, bypass alerts and save duplicate records by setting this property to true.
     * Prevent duplicate records from being saved by setting this property to false.
     */
    public DMLOptionsBuilder allowDuplicates(Boolean allowDuplicates) {
        dmlOptions.DuplicateRuleHeader.allowSave = allowDuplicates;
        return this;
    }

    /**
     * Make sure that sharing rules for the current user are enforced when duplicate rules run by setting this property to true.
     * Use the sharing rules specified in the class for the request by setting this property to false.
     * If no sharing rules are specified, Apex code runs in system context and sharing rules for the current user are not enforced.
     */
    public DMLOptionsBuilder runDuplicateRulesAsCurrentUser(Boolean runAsCurrentUser) {
        dmlOptions.DuplicateRuleHeader.runAsCurrentUser = runAsCurrentUser;
        return this;
    }


    /**
     * Specifies the ID of a specific assignment rule to run for the case or lead. The assignment rule can be active or inactive.
     */
    public DMLOptionsBuilder assignmentRuleID(Id assignmentRuleId) {
        dmlOptions.AssignmentRuleHeader.useDefaultRule = false;
        dmlOptions.AssignmentRuleHeader.assignmentRuleID = assignmentRuleId;
        return this;

    }

    /**
     * If specified as true for a case or lead, the system uses the default (active) assignment rule for the case or lead.
     * If specified, do not specify an assignmentRuleId.
     */
    public DMLOptionsBuilder useDefaultRule() {
        dmlOptions.AssignmentRuleHeader.useDefaultRule = true;
        dmlOptions.AssignmentRuleHeader.assignmentRuleID = null;
        return this;

    }


    /**
     * Indicates whether to trigger auto-response rules (true) or not (false), for leads and cases.
     */
    public DMLOptionsBuilder triggerAutoResponseEmail(Boolean doTrigger) {
        this.dmlOptions.EmailHeader.triggerAutoResponseEmail = doTrigger;
        return this;
    }

    /**
     * Indicates whether to trigger email outside the organization (true) or not (false).
     */
    public DMLOptionsBuilder triggerOtherEmail(Boolean doTrigger) {
        this.dmlOptions.EmailHeader.triggerOtherEmail = doTrigger;
        return this;
    }

    /**
     * Indicates whether to trigger email that is sent to users in the organization (true) or not (false).
     */
    public DMLOptionsBuilder triggerUserEmail(Boolean doTrigger) {
        this.dmlOptions.EmailHeader.triggerUserEmail = doTrigger;
        return this;
    }


    /**
     * Specifies whether the DMLs allows for partial success.
     */
    public DMLOptionsBuilder allOrNone(Boolean allOrNone) {
        this.dmlOptions.OptAllOrNone = allOrNone;
        return this;
    }


    /**
     * Specifies whether the DMLs allows for partial success.
     */
    public DMLOptionsBuilder allowFieldTruncation(Boolean allowFieldTruncation) {
        this.dmlOptions.allowFieldTruncation = allowFieldTruncation;
        return this;
    }


    public Database.DMLOptions build() {
        return this.dmlOptions;
    }
}
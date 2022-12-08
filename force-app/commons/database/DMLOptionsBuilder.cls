/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
/**
* Convenient builder class for DML options
* @see DMLOptionsBuilderTest
* */
public class DMLOptionsBuilder {
    private Database.DMLOptions dmlOptions = new Database.DMLOptions();


    /**
     * For a duplicate rule, when the Alert option is enabled, bypass alerts and save duplicate records by setting this property to true.
     * Prevent duplicate records from being saved by setting this property to false.
     */
    public DMLOptionsBuilder allowDuplicates(Boolean allowDuplicates) {
        dmlOptions.duplicateRuleHeader.allowSave = allowDuplicates;
        return this;
    }

    /**
     * Make sure that sharing rules for the current user are enforced when duplicate rules run by setting this property to true.
     * Use the sharing rules specified in the class for the request by setting this property to false.
     * If no sharing rules are specified, Apex code runs in system context and sharing rules for the current user are not enforced.
     */
    public DMLOptionsBuilder runDuplicateRulesAsCurrentUser(Boolean runAsCurrentUser) {
        dmlOptions.duplicateRuleHeader.runAsCurrentUser = runAsCurrentUser;
        return this;
    }


    /**
     * Specifies the ID of a specific assignment rule to run for the case or lead. The assignment rule can be active or inactive.
     */
    public DMLOptionsBuilder assignmentRuleID(Id assignmentRuleId) {
        dmlOptions.assignmentRuleHeader.useDefaultRule = false;
        dmlOptions.assignmentRuleHeader.assignmentRuleId = assignmentRuleId;
        return this;

    }

    /**
     * If specified as true for a case or lead, the system uses the default (active) assignment rule for the case or lead.
     * If specified, do not specify an assignmentRuleId.
     */
    public DMLOptionsBuilder useDefaultAssignmentRule() {
        dmlOptions.assignmentRuleHeader.useDefaultRule = true;
        dmlOptions.assignmentRuleHeader.assignmentRuleId = null;
        return this;

    }


    /**
     * Indicates whether to trigger auto-response rules (true) or not (false), for leads and cases.
     */
    public DMLOptionsBuilder triggerAutoResponseEmail(Boolean doTrigger) {
        this.dmlOptions.emailHeader.triggerAutoResponseEmail = doTrigger;
        return this;
    }

    /**
     * Indicates whether to trigger email outside the organization (true) or not (false).
     */
    public DMLOptionsBuilder triggerOtherEmail(Boolean doTrigger) {
        this.dmlOptions.emailHeader.triggerOtherEmail = doTrigger;
        return this;
    }

    /**
     * Indicates whether to trigger email that is sent to users in the organization (true) or not (false).
     */
    public DMLOptionsBuilder triggerUserEmail(Boolean doTrigger) {
        this.dmlOptions.emailHeader.triggerUserEmail = doTrigger;
        return this;
    }


    /**
     * Specifies whether the DMLs allows for partial success.
     */
    public DMLOptionsBuilder allOrNone(Boolean allOrNone) {
        this.dmlOptions.optAllOrNone = allOrNone;
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
// SPDX-License-Identifier: MIT
// Copyright 2025 Piotr Kożuchowski

/**
 * Interface for implementing reusable trigger logic that can be executed by TriggerHandler.
 *
 * Classes implementing this interface encapsulate specific business logic that should be executed
 * during trigger execution. This promotes modularity and reusability of trigger logic across
 * different trigger contexts and SObject types.
 *
 * @example Basic implementation
 * public class AccountAddressPopulator implements TriggerHandler.Action {
 *     public void execute(List<Account> records, TriggerContext ctx) {
 *         for (Account acc : records) {
 *             if (String.isBlank(acc.BillingCountry)) {
 *                 acc.BillingCountry = 'USA';
 *             }
 *         }
 *     }
 * }
 *
 * @example Usage in TriggerHandler
 * public class AccountTriggerHandler extends TriggerHandler {
 *     public override List<Action> beforeUpdate(List<SObject> triggerNew, TriggerContext tc) {
 *         return new List<Action>{
 *             new AccountAddressPopulator()
 *         };
 *     }
 * }
 *
 * @see TriggerHandler
 * @see TriggerContext
 * @see TriggerDispatcher
 */
public interface TriggerAction {

    /**
     * Execute the action against the provided records and trigger context.
     *
     * @param triggerNew the list of SObject records currently being processed
     *                   by the trigger (may be the "new" values for insert/update)
     * @param ctx the {@link TriggerContext} containing trigger metadata, old/new
     *            maps and execution state
     */
    void execute(List<SObject> triggerNew, TriggerContext ctx);
}
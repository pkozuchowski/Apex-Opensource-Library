// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

/**
 * Base abstract class that enforces a uniform approach to handling triggers.
 * Triggers for specific SObject types should provide a concrete handler by
 * extending this class and overriding only the lifecycle methods they need.
 *
 * This handler includes special handling for workflow field updates. Normally
 * Salesforce executes triggers with the original "old" map, but this handler
 * can use the "new" map from the previous trigger run to surface only the
 * changes caused by workflow field updates to business logic.
 *
 * Usage:
 * - Create a class that extends TriggerHandler and override the lifecycle
 *   methods required for that SObject.
 */
@SuppressWarnings('PMD.EmptyStatementBlock')
public virtual inherited sharing class TriggerHandler {
    @TestVisible
    private static List<TriggerExceptionHandler> exceptionHandlers;

    /**
     * Initialization method called at the start of trigger processing.
     *
     * Default implementation does nothing. Override in subclasses to set up
     * any necessary state or perform pre-processing before other lifecycle
     * methods are invoked.
     */
    public virtual void initialize(List<SObject> triggerNew, TriggerContext ctx) {}

    /**
     * Called before records are inserted (before insert).
     *
     * Default implementation does nothing. Override in subclasses to apply
     * validation or initialization logic before insert.
     *
     * @return List of actions to execute before insert
     */
    public virtual List<TriggerAction> beforeInsert(List<SObject> triggerNew, TriggerContext ctx) {
        return new List<TriggerAction>();
    }

    /**
     * Called after records are inserted (after insert).
     *
     * Default implementation does nothing. Override to perform post-insert
     * processing such as related updates or async work.
     *
     * @return List of actions to execute after insert
     */
    public virtual List<TriggerAction> afterInsert(List<SObject> triggerNew, TriggerContext ctx) {
        return new List<TriggerAction>();
    }

    /**
     * Called before records are updated (before update).
     *
     * Default implementation does nothing. Override to validate or modify
     * records prior to update.
     *
     * @return List of actions to execute before update
     */
    public virtual List<TriggerAction> beforeUpdate(List<SObject> triggerNew, TriggerContext ctx) {
        return new List<TriggerAction>();
    }

    /**
     * Called after records are updated (after update).
     *
     * Default implementation does nothing. Override to perform post-update
     * processing such as recalculations or notifications.
     *
     * @return List of actions to execute after update
     */
    public virtual List<TriggerAction> afterUpdate(List<SObject> triggerNew, TriggerContext ctx) {
        return new List<TriggerAction>();
    }

    /**
     * Called before records are deleted (before delete).
     *
     * Default implementation does nothing. Override to enforce deletion
     * prevention logic or related cleanup preparations.
     *
     * @return List of actions to execute before delete
     */
    public virtual List<TriggerAction> beforeDelete(List<SObject> triggerOld, TriggerContext ctx) {
        return new List<TriggerAction>();
    }

    /**
     * Called after records are deleted (after delete).
     *
     * Default implementation does nothing. Override to perform cascading
     * cleanup, audit logging, or other post-delete actions.
     *
     * @return List of actions to execute after delete
     */
    public virtual List<TriggerAction> afterDelete(List<SObject> triggerOld, TriggerContext ctx) {
        return new List<TriggerAction>();
    }

    /**
     * Called after records are undeleted (after undelete).
     *
     * Default implementation does nothing. Override to restore related state
     * or re-evaluate business rules after undelete.
     *
     * @return List of actions to execute after undelete
     */
    public virtual List<TriggerAction> afterUndelete(List<SObject> triggerNew, TriggerContext ctx) {
        return new List<TriggerAction>();
    }

    /**
     * Called when an exception occurs during trigger processing.
     *
     * Default implementation does nothing. Override to implement custom error
     * handling such as logging, notifications or compensating actions.
     *
     * @param ex the exception that was thrown
     * @param triggerNew list of SObject records that were being processed
     * @param ctx trigger context containing error and execution state
     */
    public virtual void onException(List<SObject> triggerNew, TriggerContext ctx, Exception ex) {}

    /**
     * Finalization method called after trigger processing is complete.
     *
     * Default implementation does nothing. Override to perform any necessary
     * cleanup or final actions after all trigger logic has executed.
     */
    public virtual void finalize(List<SObject> triggerNew, TriggerContext ctx) {}


    /**
     * Main entry point to execute the trigger handler. Runs the handler using the default trigger context.
     * This method delegates to the run(TriggerContext) method with a newly created context.
     */
    public void run() {
        run(getTriggerContext());
    }

    /**
     * @return the trigger context for this handler. Protected method that can be overridden
     * by subclasses to provide custom trigger context with trigger specific properties.
     */
    protected virtual TriggerContext getTriggerContext() {
        return TriggerContext.newContext();
    }

    @TestVisible
    private void run(TriggerContext ctx) {
        List<SObject> records = ctx.getRecords();
        try {
            if (TriggerSettings.shouldRun(ctx)) {
                initialize(ctx.getRecords(), ctx);

                List<TriggerAction> triggerActions = getActions(ctx);
                executeActions(triggerActions, records, ctx);
            }
        } catch (Exception ex) {
            onException(records, ctx, ex);
            handleException(records, ctx, ex);
            throw ex;
        } finally {
            finalize(records, ctx);
        }
    }

    /** Returns list of Trigger Actions to be executed for given Trigger Context */
    protected virtual List<TriggerAction> getActions(TriggerContext ctx) {
        List<SObject> records = ctx.getRecords();

        switch on ctx.operationType {
            when BEFORE_INSERT {
                return beforeInsert(records, ctx);
            }
            when BEFORE_UPDATE {
                return beforeUpdate(records, ctx);
            }
            when BEFORE_DELETE {
                return beforeDelete(records, ctx);
            }
            when AFTER_INSERT {
                return afterInsert(records, ctx);
            }
            when AFTER_UPDATE {
                return afterUpdate(records, ctx);
            }
            when AFTER_DELETE {
                return afterDelete(records, ctx);
            }
            when AFTER_UNDELETE {
                return afterUndelete(records, ctx);
            }
        }
        return new List<TriggerAction>();
    }

    protected void executeActions(List<TriggerAction> triggerActions, List<SObject> records, TriggerContext ctx) {
        for (Integer i = 0; i < triggerActions.size(); i++) {
            TriggerAction action = triggerActions[i];
            String actionName = getActionName(action);

            if (TriggerSettings.isActionEnabled(actionName)) {
                ctx.setCurrentAction(actionName);
                action.execute(records, ctx);
            }
        }
    }

    /** Invokes all registered Trigger Exception Handlers */
    private void handleException(List<SObject> records, TriggerContext ctx, Exception ex) {
        for (TriggerExceptionHandler handler : getExceptionHandlers()) {
            handler?.onException(records, ctx, ex);
        }
    }

    /**
     * Returns a list of initialized TriggerExceptionHandlers for handling exceptions during trigger execution.
     * 
     * This method queries for and initializes concrete implementations of the TriggerExceptionHandler
     * interface. The handlers are cached after first initialization to avoid repeated queries.
     *
     * @return List of initialized TriggerExceptionHandler instances
     */
    private List<TriggerExceptionHandler> getExceptionHandlers() {
        if (exceptionHandlers != null) {
            return exceptionHandlers;
        } else {
            exceptionHandlers = new List<TriggerExceptionHandler>();
            List<ApexTypeImplementor> handlers = [
                SELECT ClassName
                FROM ApexTypeImplementor
                WHERE InterfaceName = 'TriggerExceptionHandler'
                AND IsConcrete = TRUE
                WITH SYSTEM_MODE
            ];

            for (ApexTypeImplementor implementor : handlers) {
                try {
                    Type handlerType = Type.forName(implementor.ClassName);
                    exceptionHandlers.add((TriggerExceptionHandler) handlerType?.newInstance());
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Failed to initialize TriggerExceptionHandler');
                    System.debug(LoggingLevel.ERROR, e);
                }
            }
            return exceptionHandlers;
        }
    }

    private static String getActionName(Object action) {
        try {
            return ((Account) action)?.Id;
        } catch (Exception e) {
            return e.getMessage().substringBetween(
                'Invalid conversion from runtime type ',
                ' to Account'
            );
        }
    }
}
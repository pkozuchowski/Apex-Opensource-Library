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
    private static Integer stackDepth = 0;

    @TestVisible
    private static Map<Integer, Object> sharedStates = new Map<Integer, Object>();

    @TestVisible
    private static List<ExceptionHandler> exceptionHandlers;

    /**
     * Interface for implementing reusable trigger logic that can be executed by TriggerHandler.
     *
     * Classes implementing this interface encapsulate specific business logic that should be executed
     * during trigger execution.
     */
    public virtual interface Action {

        /**
         * Execute the action against the provided records and trigger context.
         *
         * @param records the list of SObject records currently being processed
         *                   by the trigger (may be the "new" values for insert/update)
         * @param ctx the {@link TriggerContext} containing trigger metadata, old/new
         *            maps and execution state
         */
        void execute(List<SObject> records, TriggerContext ctx);
    }


    /**
     * Interface for handling exceptions that occur during trigger processing.
     * Implement this interface to define custom behavior when exceptions are thrown
     * in trigger handlers, for example error logging.
     *
     * Framework will query all implementations of this interface and invoke the
     * onException method when an exception occurs.
     */
    public interface ExceptionHandler {
        void onException(List<SObject> records, TriggerContext ctx, Exception ex);
    }


    /**
     * Main entry point to execute the trigger handler. Runs the handler using the default trigger context.
     * This method delegates to the run(TriggerContext) method with a newly created context.
     */
    public void run() {
        run(getTriggerContext());
    }

    /**
     * Initialization method called at the start of trigger processing for each batch (200 records) in the trigger.
     */
    protected virtual void initialize(List<SObject> triggerNew, TriggerContext ctx) {}

    /**
     * Called before records are inserted (before insert).
     * @return List of actions to execute before insert
     */
    protected virtual List<Action> beforeInsert() {
        return new List<Action>();
    }

    /**
     * Called after records are inserted (after insert).
     * @return List of actions to execute after insert
     */
    protected virtual List<Action> afterInsert() {
        return new List<Action>();
    }

    /**
     * Called before records are updated (before update).
     * @return List of actions to execute before update
     */
    protected virtual List<Action> beforeUpdate() {
        return new List<Action>();
    }

    /**
     * Called after records are updated (after update).
     * @return List of actions to execute after update
     */
    protected virtual List<Action> afterUpdate() {
        return new List<Action>();
    }

    /**
     * Called before records are deleted (before delete).
     * @return List of actions to execute before delete
     */
    protected virtual List<Action> beforeDelete() {
        return new List<Action>();
    }

    /**
     * Called after records are deleted (after delete).
     * @return List of actions to execute after delete
     */
    protected virtual List<Action> afterDelete() {
        return new List<Action>();
    }

    /**
     * Called after records are undeleted (after undelete).
     * @return List of actions to execute after undelete
     */
    protected virtual List<Action> afterUndelete() {
        return new List<Action>();
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
    protected virtual void onException(List<SObject> triggerNew, TriggerContext ctx, Exception ex) {}

    /**
     * Finalization method called after trigger processing is complete.
     *
     * Default implementation does nothing. Override to perform any necessary
     * cleanup or final actions after all trigger logic has executed.
     */
    protected virtual void finalize(List<SObject> triggerNew, TriggerContext ctx) {}


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
            if (shouldRun(ctx)) {
                if (ctx.isBefore || ctx.operationType == TriggerOperation.AFTER_UNDELETE) {
                    initialize(ctx.getRecords(), ctx);
                    stackDepth++;
                    sharedStates.put(stackDepth, ctx.getSharedState());
                } else {
                    ctx.setSharedState(sharedStates.get(stackDepth));
                }

                List<Action> triggerActions = getActions(ctx);
                executeActions(triggerActions, records, ctx);

                if (ctx.isAfter) {
                    finalize(records, ctx);
                    sharedStates.remove(stackDepth);
                    stackDepth--;
                }
            }
        } catch (Exception ex) {
            onException(records, ctx, ex);
            handleException(records, ctx, ex);
            throw ex;
        } finally {
            finalize(records, ctx);
        }
    }

    /** Determines if the trigger handler should run based on the Trigger Context */
    protected virtual Boolean shouldRun(TriggerContext ctx) {
        return TriggerSettings.shouldRun(ctx);
    }

    /** Returns list of Trigger Actions to be executed for given Trigger Context */
    protected virtual List<Action> getActions(TriggerContext ctx) {
        switch on ctx.operationType {
            when BEFORE_INSERT {
                return beforeInsert();
            }
            when BEFORE_UPDATE {
                return beforeUpdate();
            }
            when BEFORE_DELETE {
                return beforeDelete();
            }
            when AFTER_INSERT {
                return afterInsert();
            }
            when AFTER_UPDATE {
                return afterUpdate();
            }
            when AFTER_DELETE {
                return afterDelete();
            }
            when AFTER_UNDELETE {
                return afterUndelete();
            }
        }
        return new List<Action>();
    }

    /**
     * Executes Trigger Actions
     */
    protected void executeActions(List<Action> triggerActions, List<SObject> records, TriggerContext ctx) {
        for (Integer i = 0; i < triggerActions.size(); i++) {
            Action action = triggerActions[i];
            String actionName = getActionName(action);

            if (TriggerSettings.isActionEnabled(actionName)) {
                ctx.setCurrentAction(actionName);
                action.execute(records, ctx);
            }
        }
    }

    /** Invokes all registered Trigger Exception Handlers */
    private void handleException(List<SObject> records, TriggerContext ctx, Exception ex) {
        for (ExceptionHandler handler : getExceptionHandlers()) {
            handler?.onException(records, ctx, ex);
        }
    }

    /**
     * Returns a list of initialized TriggerHandler.ExceptionHandlers for handling exceptions during trigger execution.
     *
     * This method queries for and initializes concrete implementations of the TriggerHandler.ExceptionHandler
     * interface. The handlers are cached after first initialization to avoid repeated queries.
     *
     * @return List of initialized TriggerHandler.ExceptionHandler instances
     */
    private List<ExceptionHandler> getExceptionHandlers() {
        if (exceptionHandlers != null) {
            return exceptionHandlers;
        } else {
            exceptionHandlers = new List<ExceptionHandler>();
            List<ApexTypeImplementor> handlers = [
                SELECT ClassName
                FROM ApexTypeImplementor
                WHERE InterfaceName = 'TriggerHandler.ExceptionHandler'
                AND IsConcrete = TRUE
                WITH SYSTEM_MODE
            ];

            for (ApexTypeImplementor implementor : handlers) {
                try {
                    Type handlerType = Type.forName(implementor.ClassName);
                    exceptionHandlers.add((ExceptionHandler) handlerType?.newInstance());
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Failed to initialize TriggerHandler.ExceptionHandler');
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
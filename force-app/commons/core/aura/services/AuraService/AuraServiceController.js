({
    handleShowElement: function (cmp, event, helper) {
        const auraId = event.getParam('arguments').auraId;
        const component = event.getParam('arguments').component;

        $A.util.removeClass(component.find(auraId), "slds-hide");
    },

    handleHideElement: function (cmp, event, helper) {
        const auraId = event.getParam('arguments').auraId;
        const component = event.getParam('arguments').component;

        $A.util.addClass(component.find(auraId), "slds-hide");
    },

    handleToggleElement: function (cmp, event, helper) {
        const auraId = event.getParam('arguments').auraId;
        const component = event.getParam('arguments').component;

        $A.util.toggleClass(component.find(auraId), "slds-hide");
    },

    handleSetTimeout: function (cmp, event, helper) {
        const callback = event.getParam('arguments').callback;
        const timeout = event.getParam('arguments').timeout;

        window.setTimeout($A.getCallback(callback), timeout);
    },

    handleSetInterval: function (cmp, event, helper) {
        const callback = event.getParam('arguments').callback;
        const interval = event.getParam('arguments').interval;

        window.setInterval($A.getCallback(callback), interval);
    },

    handleApex: function (cmp, event, helper) {
        const args = event.getParam('arguments');

        return helper.callApex(args.component, args.method, args.params, args.background);
    },

    handleCopy: function (cmp, event, helper) {
        const params = event.getParam('arguments');
        return helper.copy(params.object);
    }
})

({
    handleShowElement: function (cmp, event, helper) {
        const auraId = event.getParam('arguments').auraId;
        const component = event.getParam('arguments').component;

        console.log(auraId, component, JSON.stringify(event.getParam('arguments')));

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

        helper.setTimeout(callback, timeout);
    },

    handleApex: function (cmp, event, helper) {
        const config = event.getParam('arguments').config;

        return helper.callApex(config);
    },

    handleCopy: function (cmp, event, helper) {
        const params = event.getParam('arguments');
        return helper.copy(params.object);
    },

    handleDownload: function (cmp, event, helper) {
        const params = event.getParam('arguments');
        const config = params.config;

        return helper.download(config);
    }
})

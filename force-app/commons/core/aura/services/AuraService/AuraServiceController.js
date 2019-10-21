({
    handleShowElement: function (cmp, event, helper) {
        const component = cmp.get("v.component");
        const auraId = event.getParam('arguments').auraId;

        helper.cssClass($A.util.removeClass, component.find(auraId), "slds-hide");
    },

    handleHideElement: function (cmp, event, helper) {
        const component = cmp.get("v.component");
        const auraId = event.getParam('arguments').auraId;

        helper.cssClass($A.util.addClass, component.find(auraId), "slds-hide");
    },

    handleToggleElement: function (cmp, event, helper) {
        const component = cmp.get("v.component");
        const auraId = event.getParam('arguments').auraId;

        helper.cssClass($A.util.toggleClass, component.find(auraId), "slds-hide");
    },

    handleSetTimeout: function (cmp, event, helper) {
        const params = event.getParam('arguments');
        const callback = params.callback;
        const timeout = params.timeout;

        helper.setTimeout(callback, timeout);
    },

    handleApex: function (cmp, event, helper) {
        const params = event.getParam('arguments');
        const config = params.config;

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

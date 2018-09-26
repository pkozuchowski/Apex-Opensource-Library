({
    handleInit: function (component, event, helper) {
        const accounts = [];

        const accountGenerator = new helper.AccountGenerator(helper);
        for (var i = 0; i < 100; i++) {
            accounts.push(accountGenerator.generate());
        }
        component.set("v.accounts", accounts);
    },

    handleInputChange: function (component, event, helper) {
        let totalRevenue = 0;
        let totalEmployees = 0,
            accounts = component.get("v.accounts");

        for (let i = 0, j = accounts.length; i < j; i++) {
            if (accounts[i].AnnualRevenue) {
                totalRevenue += Number(accounts[i].AnnualRevenue);
            }
            if (accounts[i].NumberOfEmployees) {
                totalEmployees += Number(accounts[i].NumberOfEmployees);
            }
        }

        component.set("v.totalRevenue", totalRevenue);
        component.set("v.totalEmployees", totalEmployees);
    },

    handleAddNewAccount: function (component, event, helper) {

    },

    handleDeleteAccount: function (component, event, helper) {
        const accountId = event.getSource().get("v.name");
        const accounts = component.get("v.accounts").slice();
        const accountIndex = accounts.findIndex(acc => acc.Id === accountId);

        accounts.splice(accountIndex, 1);
        component.set("v.accounts", accounts);

    },

    handleUpdateAccount: function (component, event, helper) {

    },
})
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
        const newAccounts = component.get("v.newAccounts").slice();
        newAccounts.push({});
        component.set("v.newAccounts", newAccounts);
    },

    handleDeleteAccount: function (component, event, helper) {
        const accountId = event.getSource().get("v.name");
        const accounts = component.get("v.accounts").slice();
        const accountIndex = accounts.findIndex(acc => acc.Id === accountId);

        accounts.splice(accountIndex, 1);
        component.set("v.accounts", accounts);
    },

    handleSaveNewAccounts: function (component, event, helper) {
        const accounts = [...component.get("v.accounts").slice(), ...component.get("v.newAccounts").slice()];
        component.set("v.accounts", accounts);
        component.set("v.newAccounts", []);
    },

    handleRemoveNewAccount: function (component, event, helper) {
        const index = event.getSource().get("v.name");
        const newAccounts = component.get("v.newAccounts").slice();

        newAccounts.splice(index, 1);
        component.set("v.newAccounts", newAccounts);
    }
})
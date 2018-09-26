({
    getLastPage: function (component) {
        //var isSearched = component.get("v.isSearched");
        var pageSize = component.get("v.pageSize");
        var itemsLength = component.get("v.itemsLength");

        return Math.ceil(itemsLength / pageSize) - 1;
    },

    getPaginationItems: function (component) {
        var currentPage = component.get("v.page"),
            paginationItems = [],
            lastPage = this.getLastPage(component),

            min = Math.max(currentPage - 2, 0),
            max = Math.min(currentPage + 2, lastPage);

        if (min != 0) {
            paginationItems.push({label: '...', value: min - 1});
        }

        for (; min <= max; min++) {
            paginationItems.push({label: min + 1, value: min});
        }

        if (max != lastPage) {
            paginationItems.push({label: '...', value: max + 1});
        }
        component.set("v.paginationItems", paginationItems);
    },
})
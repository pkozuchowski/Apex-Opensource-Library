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
({
    handleSort: function (component, event, helper) {
        const items = component.get("v.items").slice(),
            comparator = event.getParam("sortComparator"),
            sortField = event.getParam("sortField"),
            sortDir = event.getParam("sortDir");


        if (comparator) {
            items.sort((a, b) => (comparator(a, b)) * sortDir);

        } else if (sortField) {

            items.sort((a, b) => {
                return ('' + a[sortField]).localeCompare(b[sortField], undefined, {numeric: true}) * sortDir;
            });
        }

        component.set("v.items", items);
        event.stopPropagation();
    },

    handlePagination: function (component, event, helper) {
        component.set("v.page", event.getParam("paginationPage"));
        component.set("v.pageSize", event.getParam("paginationPageSize"));
        event.stopPropagation();
    }
})
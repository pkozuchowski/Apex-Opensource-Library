# Custom Labels
*Organize Custom Labels used in components*

---
# Documentation

Custom Labels in LWC have a tendency to significantly obscure main component's code if there are many imported.
Elegant way to handle the custom labels is to separate them to separate file:
* myComponent
    * myComponent.html
    * myComponent.js
    * myComponentLabels.js

**Note**: Naming it `"labels.js"` on every component will make it harder to find in IDE file search.
It's better to prefix the filename with component's name.

myComponentLabels.js:
```javascript
import success from '@salesforce/label/c.Success';
import error from '@salesforce/label/c.Error';
import submit from '@salesforce/label/c.Submit';
/*... other labels*/

const labels = {
    success, error, submit //...other labels
}
export {labels};

```

myComponent.js
```javascript
import {labels} from "./myTabLabels";

export default class MyComponent extends LightningElement {
    label = labels;
}
```
Custom labels can be referenced in HTML using syntax `{label.success}`
```html
<lightning-button label={label.submit}></lightning-button>
```
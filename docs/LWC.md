# LWC Patterns and Utils

## Commons Module
Easy way to create single module for common utils is to have "commons" service
and separate utils into different files.

commons.js should look like this:
```javascript
export * from "./toastUtils"
export * from "./dateUtils"
export * from "./sObjectUtils"
```

Then each file can export a class with static methods:
```javascript
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export class DateUtils {

    static formatDate() {
        /*...*/
    }
}
```

or number of function exports:
```javascript
export function formatDate(){
    
}
```

## Toast Utils
Shorthands for showing toasts.
```javascript
ToastUtil.showUnexpectedErrorToast(this)
ToastUtil.showErrorToast(this, title, message, messageData, mode)
ToastUtil.showWarningToast(this, title, message, messageData, mode)
ToastUtil.showInfoToast(this, title, message, messageData, mode)
ToastUtil.showSuccessToast(this, title, message, messageData, mode)
ToastUtil.showToast(this, variant, title, message, messageData, mode)
```

```javascript
import {LightningElement} from 'lwc';
import {ToastUtils} from "c/commons";

export default class Mytab extends LightningElement {

    handleClick(ev) {
        try {
            doSomething();
            ToastUtils.showSuccessToast(this, "Record Updated!");

        } catch (e) {
            ToastUtils.showUnexpectedErrorToast(this);
        }
    }
}
```


## Custom Labels
Custom Labels in LWC have tendency to significantly obscure main's component code.  
Elegant way to handle labels is to separate them to separate file:
* myComponent
  * myComponent.html
  * myComponent.js
  * myComponentLabels.js

I'd advise against naming it "labels.js" on every component, because it will be hard to find anything in IDE's file search.  

myComponentLabels.js:
```javascript
import success from '@salesforce/label/c.Success';
import error from '@salesforce/label/c.Error';
/*... other labels*/

const labels = {
    success, error //...other labels
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
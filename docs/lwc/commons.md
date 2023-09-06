# Commons Module
*Organize common utilities and methods.*

---
## Documentation
An easy way to organize common utils is to have "commons.js" service, which will aggregate all exports, and organize utilities thematically in different files.

commons.js should look like this:
```javascript
export * from "./toastUtils"
export * from "./dateUtils"
export * from "./sObjectUtils"
```

Then each file in the same folder can export a class with static methods:
```javascript
export class DateUtils {

    static formatDate() {/*...*/}
}
```

or number of function exports:
```javascript
export function formatDate() {}
```

Client code can import classes or methods from commons as follows:
```javascript
import {Toasts} from "c/commons";

export default class Mytab extends LightningElement {

    handleClick(ev) {
        try {
            doSomething();
            Toasts.showSuccessToast(this, "Record Updated!");

        } catch (e) {
            Toasts.showUnexpectedErrorToast(this);
        }
    }
}
```
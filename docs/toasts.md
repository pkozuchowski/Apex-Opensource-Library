# Toasts
*Shorthands for showing toasts.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/lwc/commons/toasts.js)
```bash
sf project deploy start -d force-app/commons/lwc/commons -o sfdxOrg
```

---
# Documentation
Utility class that exposes one-liner methods for displaying toasts.

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

Methods:
```javascript
Toasts.showUnexpectedErrorToast(this);
Toasts.showErrorToast(this, title, message, messageData, mode);
Toasts.showWarningToast(this, title, message, messageData, mode);
Toasts.showInfoToast(this, title, message, messageData, mode);
Toasts.showSuccessToast(this, title, message, messageData, mode);
Toasts.showToast(this, variant, title, message, messageData, mode);
```
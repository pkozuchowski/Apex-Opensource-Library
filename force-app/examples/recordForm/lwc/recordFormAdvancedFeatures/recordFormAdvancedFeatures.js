import { LightningElement, track, api } from "lwc";

export default class RecordFormAdvancedFeatures extends LightningElement {
    @track account = {};
    @track opportunity;
    show = "123";
    editMode = false;
    labelOverrides = {
        Name: "Client Name"
    };
    density = "comfy";

    condition = false;

    get isViewMode() {
        return !this.editMode;
    }

    get isCompactDensity() {
        return this.density === "compact";
    }

    get densityButtonLabel() {
        return this.isCompactDensity ? "Use Comfy Density" : "Use Compact Density";
    }

    get showProspectFields() {
        return !!this.account.Type;
    }

    edit() {
        this.editMode = true;
    }

    handleFormEditModeChange(event) {
        this.editMode = event.detail.editMode;
    }

    toggleDensity() {
        this.density = this.isCompactDensity ? "comfy" : "compact";
    }

    reportValidity() {
        let reportValidity = this.refs.recordForm.reportValidity();
        console.log("reportValidity", JSON.stringify(reportValidity, null, 2));
    }

    onRecordChange(ev) {
        this.account = ev.detail.value;
        this.refs.recordForm.setCustomValidityForField("LastName", "");
        this.refs.recordForm.setCustomValidityForField("Website", "");
        console.log("this.handleChange", JSON.stringify(ev.detail.value, null, 2));
    }

    handleValidate() {
        this.refs.recordForm.setCustomValidityForField("LastName", "Please enter the customer's business name.");
        this.refs.recordForm.setCustomValidityForField(
            "Website",
            "Enter a valid company website URL, such as https://example.com."
        );
        this.refs.recordForm.reportValidity();
    }
}

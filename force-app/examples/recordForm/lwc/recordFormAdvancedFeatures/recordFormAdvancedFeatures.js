import { LightningElement, track, api } from "lwc";

export default class RecordFormAdvancedFeatures extends LightningElement {
    @api recordId = "";
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

    edit() {
        this.editMode = true;
    }

    handleFormEditModeChange(event) {
        this.editMode = event.detail.editMode;
    }

    handleDensityChange(event) {
        this.density = event.target.checked ? "compact" : "comfy";
    }

    reportValidity() {
        let reportValidity = this.refs.recordForm.reportValidity();
        console.log("reportValidity", JSON.stringify(reportValidity, null, 2));
    }

    reportValidityWebsite() {
        let reportValidity = this.refs.recordForm.reportValidityForField("Website");
        console.log("reportValidity", JSON.stringify(reportValidity, null, 2));
    }

    onRecordChange(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        try {
            Object.assign(this.account, ev.detail.value);
            console.log("this.handleChange", JSON.stringify(ev.detail.value, null, 2));
        } catch (e) {
            console.log(e, e.message, e.detail);
        }
    }

    showFields = true;

    showExtraFields() {
        this.showFields = !this.showFields;
    }

    handleValidate() {
        this.refs.recordForm.setCustomValidityForField("Name", "Please enter the customer's business name.");
        this.refs.recordForm.setCustomValidityForField(
            "Website",
            "Enter a valid company website URL, such as https://example.com."
        );
        this.refs.recordForm.reportValidityForField("Website");
        this.refs.recordForm.reportValidity();
    }
}

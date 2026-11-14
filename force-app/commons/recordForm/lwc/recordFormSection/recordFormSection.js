import { LightningElement, api } from "lwc";

export default class FoLayoutSection extends LightningElement {
  static nextContentId = 0;

  /** Title displayed when no content is provided in the title slot. */
  @api title;

  /** Number of columns used to display fields. Supported values are 1 and 2; defaults to 2. */
  @api columns = 2;

  _expanded = true;
  contentId;

  @api
  get expanded() {
    return this._expanded;
  }

  set expanded(value) {
    this._expanded = value === undefined ? true : value === true || value === "true";
  }

  constructor() {
    super();
    this.contentId = `layout-section-content-${++FoLayoutSection.nextContentId}`;
  }

  get sectionClass() {
    return `slds-section section-layout-container${this.expanded ? " slds-is-open" : ""}`;
  }

  get contentHidden() {
    return !this.expanded;
  }

  handleToggle() {
    this._expanded = !this.expanded;
  }
}

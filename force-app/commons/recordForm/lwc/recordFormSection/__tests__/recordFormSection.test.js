import { createElement } from "lwc";
import RecordFormSection from "c/recordFormSection";

describe("c-record-form-section", () => {
    afterEach(() => {
        document.body.textContent = "";
    });

    function createSection(properties = {}) {
        const element = createElement("c-record-form-section", { is: RecordFormSection });
        Object.assign(element, properties);
        document.body.appendChild(element);
        return element;
    }

    it("defaults to two columns", () => {
        const element = createSection();
        const content = element.shadowRoot.querySelector(".section-content");

        expect(element.columns).toBe(2);
        expect(content.getAttribute("data-columns")).toBe("2");
    });

    it.each([
        [1, "1"],
        [2, "2"],
        ["1", "1"]
    ])("sets the column data attribute for a %s-column layout", (columns, expectedColumns) => {
        const element = createSection({ columns });
        const content = element.shadowRoot.querySelector(".section-content");

        expect(content.getAttribute("data-columns")).toBe(expectedColumns);
    });

    it("uses the title attribute when no title slot content is supplied", () => {
        const element = createSection({ title: "Account Details" });
        const titleSlot = element.shadowRoot.querySelector('slot[name="title"]');

        expect(titleSlot.textContent).toBe("Account Details");
        expect(element.shadowRoot.querySelector(".slds-truncate").title).toBe("Account Details");
    });

    it("renders title content from the named slot", () => {
        const element = createElement("c-record-form-section", { is: RecordFormSection });
        const title = document.createElement("span");
        title.slot = "title";
        title.textContent = "Details";
        element.appendChild(title);
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('slot[name="title"]')).not.toBeNull();
        expect(title.slot).toBe("title");
    });
});

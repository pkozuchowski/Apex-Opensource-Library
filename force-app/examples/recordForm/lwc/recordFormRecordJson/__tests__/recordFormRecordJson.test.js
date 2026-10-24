// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import { createElement } from "lwc";
import RecordFormRecordJson from "c/recordFormRecordJson";

describe("c-record-form-record-json", () => {
    afterEach(() => {
        document.body.innerHTML = "";
    });

    it("renders its record as formatted JSON", () => {
        const element = createElement("c-record-form-record-json", { is: RecordFormRecordJson });
        element.record = { Id: "001xx000003DGb2AAG", Name: "Acme" };
        document.body.appendChild(element);

        expect(element.querySelector("pre").textContent).toBe(
            JSON.stringify({ Id: "001xx000003DGb2AAG", Name: "Acme" }, null, 2)
        );
    });
});

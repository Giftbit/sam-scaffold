import * as chai from "chai";
import * as index from "./";

describe("helloWorld", () => {
    describe("handler()", () => {
        it("returns 'Hello World'", async() => {
            const msg = await index.handler({});
            chai.assert.equal(msg, "Hello world");
        });
    });
});

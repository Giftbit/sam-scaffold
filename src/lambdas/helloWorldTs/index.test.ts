import * as chai from "chai";
import * as index from "./";

describe("helloWorldTs", () => {
    describe("handlerAsync()", () => {
        it("returns 'Hello World'", async() => {
            const msg = await index.handlerAsync({});
            chai.assert.equal(msg, "Hello world");
        });
    });
});

import * as cassava from "cassava";
import * as chai from "chai";
import {router} from "./index";

describe("/robots", () => {
    it("can list robots", async () => {
        const res = await cassava.testing.testRouter(router, cassava.testing.createTestProxyEvent("/robots", "GET"));
        chai.assert.equal(res.statusCode, 200);
        chai.assert.deepEqual(JSON.parse(res.body), [
            {
                name: "Robby",
                film: "Forbidden Planet"
            }, {
                name: "Gort",
                film: "The Day the Earth Stood Still"
            }
        ]);
    });

    it("can add a robot", async () => {
        const res = await cassava.testing.testRouter(router, cassava.testing.createTestProxyEvent("/robots/maschinenmensch", "PUT", {
            body: JSON.stringify({
                name: "Maschinenmensch",
                film: "Metropolis"

            })
        }));
        chai.assert.equal(res.statusCode, 204);
    });

    it("can get the added robot", async () => {
        const res = await cassava.testing.testRouter(router, cassava.testing.createTestProxyEvent("/robots/maschinenmensch", "GET"));
        chai.assert.equal(res.statusCode, 200);
        chai.assert.deepEqual(JSON.parse(res.body), {
            name: "Maschinenmensch",
            film: "Metropolis"
        });
    });

    it("can delete a robot", async () => {
        const res = await cassava.testing.testRouter(router, cassava.testing.createTestProxyEvent("/robots/robby", "DELETE"));
        chai.assert.equal(res.statusCode, 204);
    });

    it("can not get the deleted robot", async () => {
        const res = await cassava.testing.testRouter(router, cassava.testing.createTestProxyEvent("/robots/robby", "GET"));
        chai.assert.equal(res.statusCode, 404);
    });
});

import * as cassava from "cassava";

/**
 * A Database of movie robots.
 */
const robots = {
    robby: {
        name: "Robby",
        film: "Forbidden Planet"
    },
    gort: {
        name: "Gort",
        film: "The Day the Earth Stood Still"
    }
};

/**
 * Export the router so it's accessible for testing.
 */
export const router = new cassava.Router();

router.route("/robots")
    .method("GET")
    .handler(evt => {
        return {
            body: Object.keys(robots).map(key => robots[key])
        }
    });

router.route("/robots/{robot}")
    .method("GET")
    .handler(evt => {
        if (robots[evt.pathParameters["robot"]]) {
            return {
                body: robots[evt.pathParameters["robot"]]
            };
        }
        throw new cassava.RestError(cassava.httpStatusCode.clientError.NOT_FOUND);
    });

router.route("/robots/{robot}")
    .method("PUT")
    .handler(evt => {
        // Body validation.
        evt.validateBody({
            properties: {
                name: {
                    type: "string",
                    minLength: 1
                },
                film: {
                    type: "string",
                    minLength: 1
                }
            },
            required: ["name", "film"]
        });

        robots[evt.pathParameters["robot"]] = evt.body;

        return {
            statusCode: cassava.httpStatusCode.success.NO_CONTENT,
            body: null
        }
    });

router.route("/robots/{robot}")
    .method("DELETE")
    .handler(evt => {
        if (!robots[evt.pathParameters["robot"]]) {
            throw new cassava.RestError(cassava.httpStatusCode.clientError.NOT_FOUND);
        }

        delete robots[evt.pathParameters["robot"]];

        return {
            statusCode: cassava.httpStatusCode.success.NO_CONTENT,
            body: null
        }
    });

/**
 * Export the handler so it can be called.
 */
export const handler = router.getLambdaHandler();

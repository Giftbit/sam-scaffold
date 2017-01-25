/**
 * Example hello world Lambda function.  This is the function AWS will invoke.
 * Exceptions raised in this function are not well reported, so it's best
 * not to do any actual work in here.
 */
export function handler(evt, ctx, callback) {
    console.log("event", JSON.stringify(evt, null, 2));
    handlerAsync(evt)
        .then(res => {
            callback(undefined, res);
        }, err => {
            console.error(JSON.stringify(err, null, 2));
            callback(err);
        });
}

/**
 * Async/await style programming is easier to work on and exceptions here
 * are well reported.  This is where the real work starts.
 */
export async function handlerAsync() {
    // Write biz logic and get paid.
    return "Hello world";
}

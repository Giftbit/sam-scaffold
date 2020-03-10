module.exports = {
    root: true,
    parser: "@typescript-eslint/parser",
    plugins: [
        "@typescript-eslint",
    ],
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/eslint-recommended",
        "plugin:@typescript-eslint/recommended",
    ],
    rules: {
        "@typescript-eslint/explicit-function-return-type": ["error", {
            allowExpressions: true,
            allowTypedFunctionExpressions: true
        }],
        "@typescript-eslint/member-delimiter-style": ["error", {
            multiline: {
                delimiter: "semi",
                requireLast: true
            },
            singleline: {
                delimiter: "comma",
                requireLast: false
            }
        }],
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-inferrable-types": ["error", {
            ignoreParameters: true
        }],
        "@typescript-eslint/no-use-before-define": ["error", {
            functions: false
        }],
        "no-constant-condition": ["error", {
            checkLoops: false
        }]
    }
};

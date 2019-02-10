module.exports = {
    "parser": "@typescript-eslint/parser",
    "plugins": ["@typescript-eslint"],
    "extends": ["plugin:@typescript-eslint/recommended"],
    "rules": {
        "@typescript-eslint/no-explicit-any": "off"
    },
    "overrides": [
        {
            "files": "*.js",
            "rules": {
                "@typescript-eslint/no-var-requires": "off"}
        }
    ]
};

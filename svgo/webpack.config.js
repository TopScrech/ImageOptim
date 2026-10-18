"use strict";
const path = require("path");

module.exports = {
    cache: true,
    context: __dirname,
    entry: "./index.js",
    output: {
        path: path.join(__dirname, "prebuilt"),
        filename: "svgo.js",
    },
    target: "node",
    mode: "production",
    optimization: {
        minimize: true,
    },
};

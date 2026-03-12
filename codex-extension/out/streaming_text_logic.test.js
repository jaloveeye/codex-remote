"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const node_test_1 = __importDefault(require("node:test"));
const strict_1 = __importDefault(require("node:assert/strict"));
const streaming_text_logic_1 = require("./streaming_text_logic");
(0, node_test_1.default)("combineExtractedParts drops duplicated alternatives", () => {
    const result = (0, streaming_text_logic_1.combineExtractedParts)(["hello", "hello", "hello"]);
    strict_1.default.equal(result, "hello");
});
(0, node_test_1.default)("combineExtractedParts prefers superset text when available", () => {
    const result = (0, streaming_text_logic_1.combineExtractedParts)(["hello", "hello world", "world"]);
    strict_1.default.equal(result, "hello world");
});
(0, node_test_1.default)("mergeStreamingAccumulator treats cumulative delta as replace", () => {
    const merged = (0, streaming_text_logic_1.mergeStreamingAccumulator)({
        current: "hello",
        incoming: "hello again",
    });
    strict_1.default.equal(merged.next, "hello again");
    strict_1.default.equal(merged.isReplace, true);
    strict_1.default.equal(merged.emittedText, "hello again");
});
(0, node_test_1.default)("mergeStreamingAccumulator appends by overlap", () => {
    const merged = (0, streaming_text_logic_1.mergeStreamingAccumulator)({
        current: "hello ",
        incoming: " world",
    });
    strict_1.default.equal(merged.next, "hello world");
    strict_1.default.equal(merged.isReplace, false);
    strict_1.default.equal(merged.emittedText, "world");
});
(0, node_test_1.default)("mergeStreamingAccumulator ignores duplicated chunk", () => {
    const merged = (0, streaming_text_logic_1.mergeStreamingAccumulator)({
        current: "hello",
        incoming: "hello",
    });
    strict_1.default.equal(merged.next, "hello");
    strict_1.default.equal(merged.isReplace, false);
    strict_1.default.equal(merged.emittedText, "");
});
(0, node_test_1.default)("mergeStreamingAccumulator ignores incoming chunk already contained in current", () => {
    const merged = (0, streaming_text_logic_1.mergeStreamingAccumulator)({
        current: "hello world",
        incoming: "world",
    });
    strict_1.default.equal(merged.next, "hello world");
    strict_1.default.equal(merged.isReplace, false);
    strict_1.default.equal(merged.emittedText, "");
});
//# sourceMappingURL=streaming_text_logic.test.js.map
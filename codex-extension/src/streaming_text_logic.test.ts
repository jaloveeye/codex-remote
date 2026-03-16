import test from "node:test";
import assert from "node:assert/strict";

import {
  combineExtractedParts,
  mergeStreamingAccumulator,
} from "./streaming_text_logic";

test("combineExtractedParts drops duplicated alternatives", () => {
  const result = combineExtractedParts(["hello", "hello", "hello"]);
  assert.equal(result, "hello");
});

test("combineExtractedParts prefers superset text when available", () => {
  const result = combineExtractedParts(["hello", "hello world", "world"]);
  assert.equal(result, "hello world");
});

test("mergeStreamingAccumulator treats cumulative delta as replace", () => {
  const merged = mergeStreamingAccumulator({
    current: "hello",
    incoming: "hello again",
  });

  assert.equal(merged.next, "hello again");
  assert.equal(merged.isReplace, true);
  assert.equal(merged.emittedText, "hello again");
});

test("mergeStreamingAccumulator appends by overlap", () => {
  const merged = mergeStreamingAccumulator({
    current: "hello ",
    incoming: " world",
  });

  assert.equal(merged.next, "hello world");
  assert.equal(merged.isReplace, false);
  assert.equal(merged.emittedText, "world");
});

test("mergeStreamingAccumulator ignores duplicated chunk", () => {
  const merged = mergeStreamingAccumulator({
    current: "hello",
    incoming: "hello",
  });

  assert.equal(merged.next, "hello");
  assert.equal(merged.isReplace, false);
  assert.equal(merged.emittedText, "");
});


test("mergeStreamingAccumulator ignores incoming chunk already contained in current", () => {
  const merged = mergeStreamingAccumulator({
    current: "hello world",
    incoming: "world",
  });

  assert.equal(merged.next, "hello world");
  assert.equal(merged.isReplace, false);
  assert.equal(merged.emittedText, "");
});

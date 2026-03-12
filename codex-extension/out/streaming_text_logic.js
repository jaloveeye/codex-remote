"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.suffixPrefixOverlapLength = suffixPrefixOverlapLength;
exports.combineExtractedParts = combineExtractedParts;
exports.mergeStreamingAccumulator = mergeStreamingAccumulator;
function suffixPrefixOverlapLength(base, suffixCandidate) {
    const max = Math.min(base.length, suffixCandidate.length);
    for (let i = max; i > 0; i--) {
        if (base.slice(base.length - i) === suffixCandidate.slice(0, i)) {
            return i;
        }
    }
    return 0;
}
function combineExtractedParts(parts) {
    const nonEmpty = parts.filter((part) => part.length > 0);
    if (nonEmpty.length === 0)
        return "";
    if (nonEmpty.length === 1)
        return nonEmpty[0];
    const deduped = [];
    for (const part of nonEmpty) {
        if (deduped.length === 0 || deduped[deduped.length - 1] !== part) {
            deduped.push(part);
        }
    }
    if (deduped.length === 1)
        return deduped[0];
    const sortedByLength = [...deduped].sort((a, b) => b.length - a.length);
    const superset = sortedByLength.find((candidate) => deduped.every((part) => candidate.includes(part)));
    if (superset)
        return superset;
    return deduped.join("");
}
function mergeStreamingAccumulator({ current, incoming, }) {
    if (!incoming) {
        return { next: current, emittedText: "", isReplace: false };
    }
    if (!current) {
        return { next: incoming, emittedText: incoming, isReplace: true };
    }
    if (incoming === current) {
        return { next: current, emittedText: "", isReplace: false };
    }
    if (incoming.startsWith(current)) {
        return { next: incoming, emittedText: incoming, isReplace: true };
    }
    if (current.startsWith(incoming) ||
        current.endsWith(incoming) ||
        current.includes(incoming)) {
        return { next: current, emittedText: "", isReplace: false };
    }
    const overlap = suffixPrefixOverlapLength(current, incoming);
    if (overlap >= incoming.length) {
        return { next: current, emittedText: "", isReplace: false };
    }
    const appended = incoming.slice(overlap);
    return {
        next: current + appended,
        emittedText: appended,
        isReplace: false,
    };
}
//# sourceMappingURL=streaming_text_logic.js.map
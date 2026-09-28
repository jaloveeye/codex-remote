"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AsyncSingleFlightCache = void 0;
exports.resolveRequestedModel = resolveRequestedModel;
class AsyncSingleFlightCache {
    constructor(ttlMs, now = Date.now) {
        this.ttlMs = ttlMs;
        this.now = now;
        this.cached = null;
        this.inFlight = null;
    }
    get(loader, shouldCache = () => true) {
        if (this.cached && this.cached.expiresAt > this.now()) {
            return Promise.resolve(this.cached.value);
        }
        if (this.inFlight) {
            return this.inFlight;
        }
        const request = loader().then((value) => {
            if (shouldCache(value)) {
                this.cached = {
                    value,
                    expiresAt: this.now() + this.ttlMs,
                };
            }
            return value;
        });
        this.inFlight = request;
        request.then(() => {
            if (this.inFlight === request)
                this.inFlight = null;
        }, () => {
            if (this.inFlight === request)
                this.inFlight = null;
        });
        return request;
    }
    invalidate() {
        this.cached = null;
    }
}
exports.AsyncSingleFlightCache = AsyncSingleFlightCache;
function resolveCatalogDefault(catalog) {
    const requestedDefault = (catalog.defaultModel ?? "").trim();
    if (requestedDefault &&
        requestedDefault !== "auto" &&
        catalog.models.some((item) => item.model === requestedDefault)) {
        return requestedDefault;
    }
    return (catalog.models.find((item) => item.isDefault)?.model ||
        catalog.models[0]?.model ||
        "auto");
}
function resolveRequestedModel(rawRequestedModel, catalog) {
    const requestedModel = rawRequestedModel?.trim() || "auto";
    const catalogReady = catalog.ready && catalog.models.length > 0;
    const effectiveDefault = catalogReady
        ? resolveCatalogDefault(catalog)
        : "auto";
    if (!catalogReady) {
        return {
            requestedModel,
            selectedModel: undefined,
            effectiveModel: "auto",
            fallbackReason: requestedModel.toLowerCase() === "auto"
                ? "auto_requested"
                : "catalog_unavailable",
        };
    }
    if (requestedModel.toLowerCase() === "auto") {
        return {
            requestedModel: "auto",
            selectedModel: undefined,
            effectiveModel: effectiveDefault,
            fallbackReason: "auto_requested",
        };
    }
    if (catalog.models.some((item) => item.model === requestedModel)) {
        return {
            requestedModel,
            selectedModel: requestedModel,
            effectiveModel: requestedModel,
            fallbackReason: null,
        };
    }
    return {
        requestedModel,
        selectedModel: undefined,
        effectiveModel: effectiveDefault,
        fallbackReason: "unsupported_model",
    };
}
//# sourceMappingURL=runtime_capability_policy.js.map
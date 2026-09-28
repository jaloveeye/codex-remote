export type CapabilityCachePredicate<T> = (value: T) => boolean;

export class AsyncSingleFlightCache<T> {
  private cached: { value: T; expiresAt: number } | null = null;
  private inFlight: Promise<T> | null = null;

  constructor(
    private readonly ttlMs: number,
    private readonly now: () => number = Date.now
  ) {}

  get(
    loader: () => Promise<T>,
    shouldCache: CapabilityCachePredicate<T> = () => true
  ): Promise<T> {
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
    request.then(
      () => {
        if (this.inFlight === request) this.inFlight = null;
      },
      () => {
        if (this.inFlight === request) this.inFlight = null;
      }
    );
    return request;
  }

  invalidate(): void {
    this.cached = null;
  }
}

export interface RuntimeModelCatalog {
  ready: boolean;
  models: Array<{ model: string; isDefault?: boolean }>;
  defaultModel?: string;
}

export type ModelFallbackReason =
  | "auto_requested"
  | "unsupported_model"
  | "catalog_unavailable";

export interface ModelResolution {
  requestedModel: string;
  selectedModel: string | undefined;
  effectiveModel: string;
  fallbackReason: ModelFallbackReason | null;
}

function resolveCatalogDefault(catalog: RuntimeModelCatalog): string {
  const requestedDefault = (catalog.defaultModel ?? "").trim();
  if (
    requestedDefault &&
    requestedDefault !== "auto" &&
    catalog.models.some((item) => item.model === requestedDefault)
  ) {
    return requestedDefault;
  }
  return (
    catalog.models.find((item) => item.isDefault)?.model ||
    catalog.models[0]?.model ||
    "auto"
  );
}

export function resolveRequestedModel(
  rawRequestedModel: string | undefined,
  catalog: RuntimeModelCatalog
): ModelResolution {
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
      fallbackReason:
        requestedModel.toLowerCase() === "auto"
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

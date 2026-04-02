export function SetToGlobalThis(key: string, obj: unknown): void {
  globalThis[key] = obj;
}

export function GetFromGlobalThis(key: string) {
  return globalThis[key];
}

export function InitGlobalThisContext(data, PlayerPrefs, TuanjieInternet, TuanjiePermissions) {
  globalThis.context = data;
  globalThis.context.PlayerPrefs = PlayerPrefs;
    globalThis.context.TuanjieInternet = TuanjieInternet;
    globalThis.context.TuanjiePermissions = TuanjiePermissions;
}

export function SetToGlobalThisContext(key, value) {
  globalThis.context[key] = value;
}

export function GetFromGlobalThisContext(key) {
  return globalThis.context[key];
}

export function encodeAsset(ticker:string){return ticker.toUpperCase().padEnd(32,'\\0')}
export function decodeAsset(asset:string){return asset.replaceAll('\\0','')}

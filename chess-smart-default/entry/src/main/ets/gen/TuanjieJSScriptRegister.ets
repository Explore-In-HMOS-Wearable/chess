

import { RegisterGalleryManager } from '../utils/GalleryManager'; 
import { RegisterWebviewControl } from '../utils/WebviewControl'      
import { TuanjieLog } from '../common/TuanjieLog';

function register(tuanjieJSClasses:Record<string, Object>, functionName :Function) {
  let exportObj:Record<string, Object> = functionName();
  for (let key of Object.keys(exportObj)) {
    if(tuanjieJSClasses[key] !== undefined){
        TuanjieLog.error('Duplicate keys detected when exporting TypeScript module to C#: ' + key + '. This might cause overwrite exists module.');
    }
    tuanjieJSClasses[key] = exportObj[key];
  }
}

export function registerJSScriptToCSharp() {
  let tuanjieJSClasses:Record<string, Object> = {};
  register(tuanjieJSClasses, RegisterGalleryManager);
  register(tuanjieJSClasses, RegisterWebviewControl);

  return tuanjieJSClasses;
}
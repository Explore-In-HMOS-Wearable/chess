// import { POST_MESSAGE } from './WorkerProxy';
// import { TuanjieLog } from '../common/TuanjieLog';
// import { Tuanjie } from '../utils/TuanjieNative';

function dummy(name: string) {
  console.error(`${name} NOT INITIALIZED YET.`);
}

let POST_MESSAGE: ESObject = (obj: ESObject) => {
  dummy("POST_MESSAGE");
}

let TuanjieLog: ESObject = {
  info () {
    dummy("TuanjieLog");
  },
  warn() {
    dummy("TuanjieLog");
  },
  error() {
    dummy("TuanjieLog");
  },

};

let Tuanjie: ESObject = {
  nativeInvokeJSResult() {
    dummy("Tuanjie");
  },
};

export function Init(pm: ESObject, tjl: ESObject, tj: ESObject) {
  POST_MESSAGE = pm;
  TuanjieLog = tjl;
  Tuanjie = tj;
}

export interface Message {
  type: string,
  funcName: string, // moduleName.methodName
  args: ESObject,
  timeoutMs: number,
  userData: ESObject | undefined,
  modulePath: string | undefined,
  callback: ESObject | undefined,
  callbackFuncName: string | undefined,// callback 注册的名字(默认值等于 funcName); 如果 callback 为 undefined, 此字段无意义
};

export class MessageProcessor {
  name: string;
  m_builtinModules: Record<string, ESObject> = {};
  m_customModules: Record<string, ESObject> | undefined = undefined;
  m_customHandlers: Record<string, ESObject> | undefined = undefined;

  constructor(name: string) {
    this.name = name;
  }

  processMessage(msg: Message, builtinMsg: boolean = true) {
    const tokens: ESObject = msg.funcName.split(".");
    let mod: ESObject = undefined;
    if (builtinMsg) {
      mod = this.m_builtinModules[tokens[0]];
    } else if (!!this.m_customModules) {
      mod = this.m_customModules[tokens[0]];
    }

    if (!mod) {
      TuanjieLog.error('%{public}s', "No module with name=" + tokens[0]);
      Tuanjie.nativeInvokeJSResult(false, msg.userData, "No module with name=" + tokens[0]);
      return;
    }

    const func: ESObject = mod[tokens[1]];
    if (!func) {
      TuanjieLog.error('%{public}s', "No funcname with name=" + msg.funcName);
      Tuanjie.nativeInvokeJSResult(false, msg.userData, "No funcname with name=" + msg.funcName);
      return;
    }

    let argsArr: Array<ESObject> = msg.args;
    if (msg.timeoutMs >= 0) { // async
      this.InvokeAsync(mod, func, argsArr, msg);
    } else { // data.timeoutMs < 0, sync
      this.InvokeSync(mod, func, argsArr, msg);
    }
  }

  async processCustomMessage(msg: Message) {
    if (!!msg.modulePath) {
      const moduleName: ESObject = msg.funcName.split(".")[0]; // extract module name from funcName
      await this.loadModule(moduleName, msg.modulePath);
    }
    this.processMessage(msg, false);
  }

  processHandler(msg: Message) {
    if (!this.m_customHandlers) {
      return;
    }

    try {
      let func: ESObject = this.m_customHandlers[msg.funcName];
      if (!!func) {
        let args: Array<ESObject> = msg.args;
        func(...args);
      } else {
        TuanjieLog.warn("No callback with name=%{public}s", msg.funcName);
      }
    } catch (err) {
      TuanjieLog.error('Error occurred while calling callback=%{public}s, err=%{public}s', msg.funcName, err);
    }
  }

  InvokeAsync(mod: ESObject, func: ESObject, argsArr: Array<ESObject>, msg: Message) {
    let timeout: Promise<number> = new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error("Async call timeout"));
      }, msg.timeoutMs);
    });
    let succ: ESObject = func.apply(mod, argsArr);
    Promise.race([succ, timeout]).then((result: ESObject) => {
      if (!!msg.callbackFuncName) { // remote, post result back
        POST_MESSAGE({'type': kCustomHandler, 'funcName': msg.callbackFuncName, 'args': result});
      } else { // local
        Tuanjie.nativeInvokeJSResult(true, msg.userData, result);
      }
    }).catch((err: ESObject) => {
      let errMsg = JSON.stringify(err) ?? "unknown error";
      errMsg = "Error calling " + msg.funcName + "err=" + errMsg;
      TuanjieLog.error('%{public}s', errMsg);
      if (!msg.callbackFuncName)
        Tuanjie.nativeInvokeJSResult(false, msg.userData, err);
    });
  }

  InvokeSync(mod: ESObject, func: ESObject, argsArr: Array<ESObject>, msg: Message) {
    try {
      let result: ESObject = func.apply(mod, argsArr);
      if (!!msg.callbackFuncName) { // remote, post result back
        TuanjieLog.info('Call user extra module function : ' + msg.callbackFuncName + ' success');
        POST_MESSAGE({ 'type': kCustomHandler, 'funcName': msg.callbackFuncName, 'args': result});
      } else {
        Tuanjie.nativeInvokeJSResult(true, msg.userData, result);
      }
    } catch (err) {
      let errMsg = JSON.stringify(err) ?? "unknown error";
      errMsg = "Error calling " + msg.funcName + "err=" + errMsg;
      TuanjieLog.error('%{public}s', errMsg);
      if (!msg.callbackFuncName)
        Tuanjie.nativeInvokeJSResult(false, msg.userData, errMsg);
    }
  }

  registerBuiltinModule(module: ESObject): boolean {
    let name: string = module.name || module.constructor.name;
    const curModule: ESObject = this.m_builtinModules[name];
    if (!!curModule) {
      TuanjieLog.error('Duplicated message=%{public}s handler', name);
      return false;
    }

    this.m_builtinModules[name] = module;
    return true;
  }

  unregisterBuiltinModule(module: ESObject) {
    let name: string = module.name || module.constructor.name;
    const curModule: ESObject = this.m_builtinModules[name];
    if (!!curModule) {
      this.m_builtinModules.deleteKey(name);
    }
  }

  registerModule(handler: ESObject): boolean {
    if (!this.m_customModules) {
      this.m_customModules = {};
    }
    let name: string = handler.name || handler.constructor.name;
    const curHandler: ESObject = this.m_customModules[name];
    if (!!curHandler) {
      TuanjieLog.error('Duplicated message=%{public}s handler', name);
      return false;
    }

    this.m_customModules[name] = handler;
    return true;
  }

  unregisterModule(name: string) {
    if (!!this.m_customModules) {
      const handler: ESObject = this.m_customModules[name];
      if (!!handler) {
        this.m_customModules.deleteKey(name);
      }
    }
  }

  async loadModule(moduleName: string, modulePath: string) {
    if (!this.m_customModules) {
      this.m_customModules = {};
    }
    const mod: ESObject = this.m_customModules[moduleName];
    if (!!mod) {
      TuanjieLog.info(`Message=${moduleName} handler/module already exists.`);
    }

    const self = this;
    await import(modulePath).then((mod: ESObject) => {
      TuanjieLog.info(`Load module ${moduleName} Successfully.`);
      if (!!self.m_customModules)
        self.m_customModules[moduleName] = mod[moduleName];
    }).catch((reason: ESObject) => {
      TuanjieLog.error(`Failed to load user extra module=${moduleName}`);
    });
  }

  unloadModule(moduleName: string) {
    this.unregisterModule(moduleName);
  }

  registerHandler(name: string, callback: ESObject) {
    if (!this.m_customHandlers) {
      this.m_customHandlers = {};
    }
    this.m_customHandlers[name] = callback;
  }

  unregisterHandler(name: string) {
    if (!!this.m_customHandlers) {
      const handler: ESObject = this.m_customHandlers[name];
      if (!!handler) {
        this.m_customHandlers.deleteKey(name);
      }
    }
  }
}

export const kCustomHandler: string = "CustomHandler";

export enum MSG_RECEIVER {
  HOST_UI = 0,
  WORKER_TUANJIE,
};

const gMsgProcessors: Array<MessageProcessor> = [
  new MessageProcessor("Host.UI"),          // Host: Run on UI thread
  new MessageProcessor("Worker.Tuanjie"),   // Worker: Run on Tuanjie thread
];

export function REGISTER_BUILTIN_MODULE(receiver: MSG_RECEIVER, module: ESObject) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`REGISTER_BUILTIN_MODULE| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].registerBuiltinModule(module);
}

export function UNREGISTER_BUILTIN_MODULE(receiver: MSG_RECEIVER, module: ESObject) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`UNREGISTER_BUILTIN_MODULE| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].unregisterBuiltinModule(module);
}

export function REGISTER_MODULE(receiver: MSG_RECEIVER, module: ESObject) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`REGISTER_MODULE| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].registerModule(module);
}

export async function UNREGISTER_MODULE(receiver: MSG_RECEIVER, moduleName: string) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`UNREGISTER_MODULE| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].unregisterModule(moduleName);
}

export async function LOAD_MODULE(receiver: MSG_RECEIVER, moduleName: string, modulePath: string) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`LOAD_MODULE| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].loadModule(moduleName, modulePath);
}

export async function UNLOAD_MODULE(receiver: MSG_RECEIVER, moduleName: string) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`UNLOAD_MODULE| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].unloadModule(moduleName);
}

export function REGISTER_HANDLER(receiver: MSG_RECEIVER, name: string, handler: ESObject) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`REGISTER_HANDLER| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].registerHandler(name, handler);
}

export function UNREGISTER_HANDLER(receiver: MSG_RECEIVER, handlerName: string) {
  if (receiver >= gMsgProcessors.length)
    TuanjieLog.error(`UNREGISTER_HANDLER| Unknown message receiver=%{public}d`, receiver);
  else
    gMsgProcessors[receiver].unregisterHandler(handlerName);
}

// accessible api proxy
export function PROCESS_UI_BUILTIN_MESSAGE(msg: Message) {
  gMsgProcessors[MSG_RECEIVER.HOST_UI].processMessage(msg, true);
}

export async function PROCESS_UI_MESSAGE(msg: Message) {
  gMsgProcessors[MSG_RECEIVER.HOST_UI].processCustomMessage(msg);
}

export function PROCESS_UI_HANDLER(msg: Message) {
  gMsgProcessors[MSG_RECEIVER.HOST_UI].processHandler(msg);
}

export function PROCESS_TUANJIE_BUILTIN_MESSAGE(msg: Message) {
  gMsgProcessors[MSG_RECEIVER.WORKER_TUANJIE].processMessage(msg, true);
}

export function PROCESS_TUANJIE_MESSAGE(msg: Message) {
  gMsgProcessors[MSG_RECEIVER.WORKER_TUANJIE].processCustomMessage(msg);
}

export function PROCESS_TUANJIE_HANDLER(msg: Message) {
  gMsgProcessors[MSG_RECEIVER.WORKER_TUANJIE].processHandler(msg);
}

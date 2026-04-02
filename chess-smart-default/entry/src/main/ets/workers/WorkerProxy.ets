/**
 * @desc Run on UI/main thread, process message from worker thread and postMessage to worker thread
 */
import worker, { MessageEvents } from '@ohos.worker';

import { Constants } from '../common/Constants';
import { TuanjieLog } from '../common/TuanjieLog';
import { Tuanjie } from '../utils/TuanjieNative';
import { PROCESS_UI_BUILTIN_MESSAGE, PROCESS_UI_HANDLER, PROCESS_UI_MESSAGE, kCustomHandler } from './MessageProcessor';
import "../gen/BuiltinHostMsgRegistration";

export class WorkerProxy {
  public threadWorker: worker.ThreadWorker;
  public mModules: Record<string, ESObject> = {
  };

  public mUserExtraModules: Record<string, ESObject> = { };

  private constructor() {
    TuanjieLog.debug('%{public}s', 'WorkerProxy.constructor');
    this.threadWorker = new worker.ThreadWorker("./TuanjieMainWorker.ets");
    this.threadWorker.onerror = (e) => {
      let msg = e.message;
      let filename = e.filename;
      let lineno = e.lineno;
      let colno = e.colno;
      TuanjieLog.error(`TuanjieMainWorker Error ${msg} ${filename} ${lineno} ${colno}`);
    }

    const self = this;
    this.threadWorker.onmessage = (msg) => {
      msg.data.src = "Worker.TuanjieMain";
      if (msg.data.type == "RUN_ON_UI_THREAD") {
        Tuanjie.nativeProcessUIThreadMessage();
      } else if (msg.data.type == "RUN_ON_UI_THREAD_JS") {
        PROCESS_UI_BUILTIN_MESSAGE(msg.data)
      } else if (msg.data.type == "RUN_ON_UI_THREAD_USER_EVENT") {
        PROCESS_UI_MESSAGE(msg.data);
      } else if (msg.data.type == kCustomHandler) {
        PROCESS_UI_HANDLER(msg.data);
      } else {
        TuanjieLog.warn("Unknown UI message type=%{public}s", msg.type);
      }
    }
  }

  public static Instance(): WorkerProxy {
    let tuanjieMainWorker = AppStorage.get<WorkerProxy>(Constants.APP_KEY_TUANJIE_MAIN_WORKER);
    if (tuanjieMainWorker == null) {
      tuanjieMainWorker = new WorkerProxy();
      AppStorage.setOrCreate(Constants.APP_KEY_TUANJIE_MAIN_WORKER, tuanjieMainWorker);
    }
    return tuanjieMainWorker;
  }

  public static getInstance(): worker.ThreadWorker {
    return WorkerProxy.Instance().threadWorker;
  }

  /**
   * post message to worker thread. For now we have only one worker - TuanjieMainWorker
   * @param msg
   */
  public static postMessage(msg: ESObject, targetWorker: string | undefined) {
    if (targetWorker === undefined)
      WorkerProxy.Instance().threadWorker.postMessage(msg);
    // for now we have only worker
  }
}

export function POST_MESSAGE(msg: ESObject) {
  POST_MESSAGE_TO_WORKER(msg, undefined)
}

export function POST_MESSAGE_TO_WORKER(msg: ESObject, targetWorker: string | undefined) {
  if (!msg.type)
    msg.type = "RUN_ON_UI_THREAD_USER_EVENT";
  WorkerProxy.postMessage(msg, targetWorker);
}


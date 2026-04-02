/**
 * @desc Run on TuanjieMain worker thread, process message from UI thread and postMessage to UI thread
 */
import { Tuanjie } from '../utils/TuanjieNative';
import { TuanjieLog } from '../common/TuanjieLog';
import { registerJSScriptToCSharp } from '../gen/TuanjieJSScriptRegister';
import { TuanjieInternet } from '../utils/TuanjieInternet';
import { TuanjiePermissions } from '../utils/TuanjiePermissions';
import { PlayerPrefs } from '../common/PlayerPrefs'
import {
  InitGlobalThisContext,
  GetFromGlobalThis,
  SetToGlobalThisContext,
  SetToGlobalThis,
  GetFromGlobalThisContext
} from '../common/GlobalThisUtil';
import { TuanjieDisplayInfo } from '../utils/DisplayInfoManager';
import { TuanjieBatteryInfo } from '../utils/TuanjieBatteryInfo';
import { TuanjieBundleInfo } from '../utils/TuanjieBundleInfo';
import { Message, REGISTER_HANDLER, MSG_RECEIVER,
  PROCESS_TUANJIE_BUILTIN_MESSAGE, PROCESS_TUANJIE_HANDLER,
  kCustomHandler,
  PROCESS_TUANJIE_MESSAGE
} from "./MessageProcessor";
import "../gen/BuiltinWorkerMsgRegistration";

import geoLocationManager from '@ohos.geoLocationManager';
import worker from '@ohos.worker';

interface Location {
  latitude: number,
  longitude: number,
  altitude: number,
  accuracy: number,
  speed: number,
  timeStamp: number,
  direction: number,
  timeSinceBoot: number,
}

export class HostProxy {
  async SetGlobalThisContext(msg: ESObject) {
    InitGlobalThisContext(msg.data,PlayerPrefs,TuanjieInternet,TuanjiePermissions);
    SetToGlobalThisContext("tuanjieJSScript", registerJSScriptToCSharp());
    SetToGlobalThisContext("bundleInfo", await TuanjieBundleInfo.instance() as ESObject);
    SetToGlobalThisContext("batteryInfo", new TuanjieBatteryInfo() as ESObject);
    GetFromGlobalThisContext('TuanjieInternet').Subscribe();
  }

  Loop(msg: ESObject) {
    console.log("message from main thread received!");
  }

  SetDisplayInfo(msg: ESObject) {
    let defaultDisplay: TuanjieDisplayInfo = msg.data;
    SetToGlobalThis('defaultDisplay', defaultDisplay);
    Tuanjie.nativeOnDisplayChanged();
  }

  SoftInput_onTextChange (msg: ESObject) {
    SetToGlobalThis("softInputMsg", msg.data);
    TuanjieLog.debug("CustomDialogController worker thread SoftInput_onTextChange " + msg.data);
    Tuanjie.nativeSetInputString();
  }

  SoftInput_onTextSelectionChange(msg: ESObject) {
    Tuanjie.nativeSetInputSelection(msg.start, msg.length);
  }

  SoftInput_accept(msg: ESObject) {
    TuanjieLog.debug("CustomDialogController worker thread SoftInput_accept " + msg.data);
    Tuanjie.nativeSoftInputClosed();
  }

  SoftInput_cancel(msg: ESObject) {
    // todo call tuanjie native api
  }

  GetPermissionRequestResult(msg: ESObject) {
    Tuanjie.nativeGetPermissionRequestResult(msg.permissions, msg.results, msg.onGranted, msg.onDenied);
  }

  GetPermissionAuthorizeResult(msg: ESObject) {
    Tuanjie.nativeGetPermissionAuthorizeResult(msg.permission, msg.result, msg.onAuthorized, msg.onUnauthorized);
  }

  OnLocation(msg: ESObject) {
    let locationData: geoLocationManager.Location = msg.location;
    let location: Location = {
      latitude: 0,
      longitude: 0,
      altitude: 0,
      accuracy: 0,
      speed: 0,
      timeStamp: 0,
      direction: 0,
      timeSinceBoot: 0
    }; //default value
    location.latitude = locationData.latitude;
    location.longitude = locationData.longitude;
    location.altitude = locationData.altitude;
    location.accuracy = locationData.accuracy;
    location.speed = locationData.speed;
    location.timeStamp = locationData.timeStamp;
    location.direction = locationData.direction;
    location.timeSinceBoot = locationData.timeSinceBoot;
    Tuanjie.nativeOnLocationChange(location);
  }

  InternetSubscribe(msg: ESObject) {
    GetFromGlobalThisContext('TuanjieInternet').Subscribe();
  }

  PlayerPrefsLocalSave(msg: ESObject) {
    GetFromGlobalThisContext('PlayerPrefs').LocalSave();
  }

  WebControllerAttached(msg: ESObject) {
  }
}

let gHostProxy = new HostProxy();
export function GetHostProxy(): HostProxy {
  return gHostProxy;
}

export function PROCESS_WORKER_MESSAGE(msg: Message): number {
  let handlers: ESObject = GetHostProxy();
  const func: ESObject = handlers[msg.type];
  if (msg.type == "SetGlobalThisContext") { // async 函数特殊处理
    handlers.SetGlobalThisContext(msg);
    return 0;
  }
  if (!!func) {
    func.apply(handlers,[msg]);
    return 0;
  } else if (msg.type == "RUN_ON_TUANJIEMAIN_THREAD_JS") {
    PROCESS_TUANJIE_BUILTIN_MESSAGE(msg); // 自动注册的处理函数
  } else if (msg.type == "RUN_ON_TUANJIEMAIN_THREAD_USER_EVENT") {
    PROCESS_TUANJIE_MESSAGE(msg);
  } else if (msg.type == kCustomHandler) {
    PROCESS_TUANJIE_HANDLER(msg);
  } else {
    TuanjieLog.warn("Unknown message type=%{public}s", msg.type);
  }
  return -1;
}

export function POST_MESSAGE(msg: ESObject) {
  POST_MESSAGE_TO_HOST(msg);
}

export function POST_MESSAGE_TO_HOST(msg: ESObject) {
  if (!msg.type)
    msg.type = "RUN_ON_UI_THREAD_USER_EVENT";
  if (!!msg.callback) {
    if (!msg.callbackFuncName)
      msg.callbackFuncName = msg.funcName;
    REGISTER_HANDLER(MSG_RECEIVER.WORKER_TUANJIE, msg.callbackFuncName, msg.callback);
    msg.callback = undefined;
  }
  worker.workerPort.postMessage(msg);
}

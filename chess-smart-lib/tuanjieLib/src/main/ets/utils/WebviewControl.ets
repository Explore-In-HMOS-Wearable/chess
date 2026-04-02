import worker from '@ohos.worker';
import { POST_MESSAGE_TO_HOST } from '../workers/HostProxy';

const workerPort = worker.workerPort;

export class WebviewControl {
  private messageStateCallback: Function | null = null;
  private messageEventCallback: Function | null = null;

  public constructor() {
    globalThis.workerPort.addEventListener("message", async (e: ESObject) => {
      let msg: ESObject = JSON.parse(JSON.stringify(e));
      switch (msg.data.type) {
        case "WebviewStateCallback":
          if (this.messageStateCallback != null) {
            this.messageStateCallback(
              msg.data.index,
              msg.data.state);
          }
          break;
        case "WebviewEventCallback":
          if (this.messageEventCallback != null) {
            this.messageEventCallback(
              msg.data.index,
              msg.data.event,
              msg.data.errorMsg);
          }
          break;
        default:
          break;
      }
    });
  }

  static _instance: WebviewControl;

  static getInstance(): WebviewControl {
    if (!WebviewControl._instance) {
      WebviewControl._instance = new WebviewControl();
    }
    return WebviewControl._instance;
  }

  public InitializeCallback(stateCallback: () => void, eventCallback: () => void) {
    this.messageStateCallback = stateCallback;
    this.messageEventCallback = eventCallback;
  }

  public LoadHTMLString(index: number, contents: string, baseUrl: string): void {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.LoadHTMLString",
      args: [index, contents, baseUrl]
    });
  }

  public LoadData(index: number, contents: string, mimeType: string, encoding: string, baseUrl: string): void {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.LoadData",
      args: [index, contents, mimeType, encoding, baseUrl]
    });
  }

  public EvaluateJS(index: number, jsContents: string): void {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.EvaluateJS",
      args: [index, jsContents]
    });
  }

  public Reload(index: number): void {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.Reload",
      args: [index]
    });
  }

  public StopLoading(index: number): void {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.StopLoading",
      args: [index]
    });
  }

  public GoForward(index: number): void {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.GoForward",
      args: [index]
    });
  }

  public GoBack(index: number): void {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.GoBack",
      args: [index]
    });
  }

  public SyncWebviewInfos(webviewInfosJson: string) {
    POST_MESSAGE_TO_HOST({
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "WebviewUtils.SyncWebviewInfos",
      args: [webviewInfosJson]
    });
  }
}

export function RegisterWebviewControl() {
  let register: Record<string, Object> = {};
  register["WebviewControl"] = WebviewControl;
  return register;
}


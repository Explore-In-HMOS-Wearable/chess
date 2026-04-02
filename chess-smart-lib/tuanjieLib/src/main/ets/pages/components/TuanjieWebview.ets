import web_webview from '@ohos.web.webview'
import { TuanjieLog } from '../../common/TuanjieLog';
import { POST_MESSAGE } from '../../workers/WorkerProxy';

@Component
export struct TuanjieWebview {
  @Link viewInfos: Array<WebviewInfo>;
  @Link controllers: Array<web_webview.WebviewController>;

  build() {
    if (this.viewInfos && this.viewInfos.length > 0) {
      ForEach(this.viewInfos, (info: WebviewInfo) => {
        if (info.valid) {
          Web({
            src: info.url,
            controller: this.controllers[info.index]
          })
            .position({ x: px2vp(info.x), y: px2vp(info.y) })
            .width(px2vp(info.w))
            .height(px2vp(info.h))
            .border({ width: 1 })
            .domStorageAccess(true)
            .databaseAccess(true)
            .imageAccess(true)
            .javaScriptAccess(true)
            .visibility(info.visible ? Visibility.Visible : Visibility.Hidden)
            .onControllerAttached(() => {
              POST_MESSAGE({
                'type': 'WebviewStateCallback',
                'index': info.index,
                'state': WebviewState.Initialized,
              })
            })
            .onPageEnd((event) => {
              POST_MESSAGE({
                'type': 'WebviewStateCallback',
                'index': info.index,
                'state': WebviewState.Loaded,
              })
            })
            .onHttpErrorReceive((event) => {
              if (event) {
                const errorMsg: string = 'Response Code: ' + event.response.getResponseCode();
                POST_MESSAGE({
                  'type': 'WebviewEventCallback',
                  'event': "HttpError",
                  'index': info.index,
                  'errorMsg': errorMsg
                })
              }
            })
            .onErrorReceive((event) => {
              if (event) {
                const errorMsg: string =
                  'Error Code: ' + event.error.getErrorCode() + ". Error Info: " + event.error.getErrorInfo();
                POST_MESSAGE({
                  'type': 'WebviewEventCallback',
                  'event': "Error",
                  'index': info.index,
                  'errorMsg': errorMsg
                })
              }
            })
        }
      })
    }
  }
}

export enum WebviewState {
  Invalid = -1,
  Initing = 0,
  Initialized = 1,
  Loading = 2,
  Loaded = 3,
}

export class WebviewInfo {
  public index = -1;
  public valid = false;
  // position
  public x: number = 0;
  public y: number = 0;
  // size
  public w: number = 0;
  public h: number = 0;
  // url
  public url: string = '';
  public visible: boolean = false;
  public controller: web_webview.WebviewController = new web_webview.WebviewController()

  constructor(index: number, x: number, y: number, w: number, h: number) {
    this.index = index;
    this.valid = true;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  public reset() {
    this.valid = false;
    this.x = 0;
    this.y = 0;
    this.w = 0;
    this.h = 0;
    this.url = '';
    this.visible = false;
  }
}
import web_webview from '@ohos.web.webview'
import { WebviewInfo } from '../pages/components/TuanjieWebview';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';


export class WebviewUtils {
  private static _webviewInfos: WebviewInfo[]; // Backing field for the static property

  public static get webviewInfos(): WebviewInfo[] {
    return AppStorage.get("webviewInfos") as WebviewInfo[]
  }

  public static set webviewInfos(value: WebviewInfo[]) {
    AppStorage.setOrCreate("webviewInfos", value);
  }

  private static _controllers: web_webview.WebviewController[];

  public static get controllers(): web_webview.WebviewController[] {
    return AppStorage.get("controllers") as web_webview.WebviewController[]
  }

  public static set controllers(value: web_webview.WebviewController[]) {
    AppStorage.setOrCreate("controllers", value);
  }

  LoadHTMLString(index: number, contents: string, baseUrl: string) {
    WebviewUtils.controllers[index].loadData(contents, "text/html", "UTF-8", baseUrl);
  }

  LoadData(index: number, contents: string, mimeType: string, encoding: string, baseUrl: string) {
    WebviewUtils.controllers[index].loadData(contents, mimeType, encoding, baseUrl);
  }

  EvaluateJS(index: number, jsContents: string) {
    try {
      WebviewUtils.controllers[index].runJavaScript(jsContents).then((result: ESObject) => {
        if (result) {
          console.info(`The return value is: ${result}`)
        }
      })
    } catch (error) {
      console.error('Failed to evaluate JavaScript. Cause: ' + JSON.stringify(error));
    }
  }

  Reload(index: number) {
    WebviewUtils.controllers[index].refresh();
  }

  StopLoading(index: number) {
    WebviewUtils.controllers[index].stop();
  }

  GoForward(index: number) {
    if (WebviewUtils.controllers[index].accessForward()) {
      WebviewUtils.controllers[index].forward()
    }
  }

  GoBack(index: number) {
    if (WebviewUtils.controllers[index].accessBackward()) {
      WebviewUtils.controllers[index].backward()
    }
  }

  SyncWebviewInfos(webviewInfosJson: string) {
    let webviews: WebviewInfo[] = JSON.parse(webviewInfosJson) as WebviewInfo[];
    while (WebviewUtils.controllers.length < webviews.length) {
      WebviewUtils.controllers.push(new web_webview.WebviewController());
    }
    WebviewUtils.webviewInfos = webviews;
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, new WebviewUtils())
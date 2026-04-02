import { uiObserver, UIObserver } from '@kit.ArkUI';
import web_webview from '@ohos.web.webview'
import { APP_KEY_ORIENTATION_CHANGE } from '../../common/Constants';
import { DebuggerDialog } from './DebuggerDialog';
import { SoftInputDialog } from './SoftInputDialog'
import { TuanjieView } from './TuanjieView';
import { StaticSplashScreen } from './StaticSplashScreen';
import { WebviewInfo, TuanjieWebview } from "./TuanjieWebview"
import { VideoPlayer } from './VideoPlayer'
import { SetToGlobalThis } from '../../common/GlobalThisUtil';
import { TuanjieLog } from '../../common/TuanjieLog';
import { WindowUtils } from '../../utils/WindowUtils';
import { POST_MESSAGE } from '../../workers/WorkerProxy';
import { DebuggerDialogInfo } from '../../utils/DebuggerDialogInfo';
import { Tuanjie } from '../../utils/TuanjieNative';

@Component
export struct TuanjiePlayerView {
  @StorageLink('webviewInfos') webviewInfos: WebviewInfo[] = [];
  @StorageLink('controllers') controllers: web_webview.WebviewController[] = [];
  @StorageProp(APP_KEY_ORIENTATION_CHANGE) @Watch('updateOrientation') orientation: number = 0;
  @State debuggerDialogInfo : DebuggerDialogInfo = new DebuggerDialogInfo("","","",false);
  @State vAlign: FlexAlign = FlexAlign.End;
  @State hAlign: FlexAlign = FlexAlign.End;
  @Link displayIndex: number;

  listener: (info: uiObserver.RouterPageInfo) => void = (info: uiObserver.RouterPageInfo) => {
    let routerInfo: uiObserver.RouterPageInfo | undefined = this.queryRouterPageInfo();
    if (info.pageId == routerInfo?.pageId) {
      if (info.state == uiObserver.RouterPageState.ON_PAGE_SHOW) {
        this.onShow();
      } else if (info.state == uiObserver.RouterPageState.ON_PAGE_HIDE) {
        this.onHide();
      }
    }
  }

  updateOrientation() {
    // portrait upside down
    this.vAlign = this.orientation == 2 ? FlexAlign.Start : FlexAlign.End;
    // landscape right
    this.hAlign = this.orientation == 1 ? FlexAlign.Start : FlexAlign.End;
    TuanjieLog.info('%{public}s', "updateOrientation");
  }

  dialogController = new CustomDialogController({
    builder: SoftInputDialog({
      // showMessage: this.showMessage,
      onTextChange: (msg: string) => {
        TuanjieLog.debug("CustomDialogController onTextChange " + msg);
        POST_MESSAGE({ type: 'SoftInput_onTextChange', data: msg });
      },
      onTextSelectionChange: (start: number, end: number) => {
        TuanjieLog.debug("CustomDialogController onTextSelectionChange start: " + start.toString() + ", end: " + end.toString());
        POST_MESSAGE({ type: 'SoftInput_onTextSelectionChange', start: start, length: end - start });
      },
      accept: (msg: string) => {
        TuanjieLog.debug("CustomDialogController accept" + msg);
        POST_MESSAGE({ type: 'SoftInput_accept', data: msg });
      },
    }),
    cancel: () => {
      TuanjieLog.debug("CustomDialogController cancel");
      POST_MESSAGE({ type: 'SoftInput_accept', data: null });
    },
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true,
  })

  onShow() {
    TuanjieLog.info('%{public}s', 'onShow');

    this.updateOrientation();
    WindowUtils.getInstance().setXComponentSizeWithSafeArea(0, 0, Tuanjie.nativeGetIsRenderOutsizeSafeArea());
    SetToGlobalThis('dialogController', this.dialogController);
    SetToGlobalThis(DebuggerDialogInfo.DebuggerDialogInfoKey, this.debuggerDialogInfo);

    let ctx: UIContext = this.getUIContext();
    SetToGlobalThis('UIContext',ctx);
  }

  onHide() {
    TuanjieLog.info('%{public}s', 'onHide');
  }

  onPageShow() {
    TuanjieLog.info('%{public}s', 'onPageShow -111');
    this.onShow();
  }

  onPageHide() {
    TuanjieLog.info('%{public}s', 'onPageHide');
    this.onHide();
  }

  aboutToAppear(): void {
    let uiOb: UIObserver = this.getUIContext().getUIObserver();
    uiOb.on("routerPageUpdate", this.listener);
  }

  aboutToDisappear(): void {
    let uiOb: UIObserver = this.getUIContext().getUIObserver();
    uiOb.off("routerPageUpdate", this.listener);
  }

  build() {
    Row() {
      Column() {
        Stack() {
          TuanjieView({displayIndex: this.displayIndex});

          TuanjieWebview({viewInfos: this.webviewInfos, controllers: this.controllers});

          StaticSplashScreen()
          VideoPlayer()
          if (this.debuggerDialogInfo.Showing) {
            DebuggerDialog({debuggerDialogInfo: this.debuggerDialogInfo})
          }
        }
      }
      .height('100%')
      .backgroundColor('#ff000000')
      .justifyContent(this.vAlign)
    }
    .width('100%')
    .backgroundColor('#ff000000')
    .justifyContent(this.hAlign)
  }
}

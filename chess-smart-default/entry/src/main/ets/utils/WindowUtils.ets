import window from '@ohos.window';
import pasteboard from '@ohos.pasteboard';
import { GetFromGlobalThis } from '../common/GlobalThisUtil';
import { TuanjieLog } from '../common/TuanjieLog';
import { DebuggerDialogInfo } from './DebuggerDialogInfo';
import { APP_KEY_SAFEAREA_RECT } from '../common/Constants';
import { Tuanjie } from '../utils/TuanjieNative';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';
import { BusinessError } from '@ohos.base';
import { TuanjiePermissions } from '../utils/TuanjiePermissions';

// These MUST be synchronized with ScreenManager.h
enum ScreenOrientation {
  kScreenOrientationUnknown,

  kPortrait,
  kPortraitUpsideDown,
  kLandscapeLeft,
  kLandscapeRight,

  kAutoRotation,

  kScreenOrientationCount
};

export class WindowUtils {
  readonly MainWindowKey = "TuanjieMainWindow";
  systemBarState: Array<'status' | 'navigation'> | null = null;
  nativeToOpenHarmonyOrientationMap: Map<number, window.Orientation> = (() => {
    let orientationMap = new Map<number, window.Orientation>();
    orientationMap.set(ScreenOrientation.kScreenOrientationUnknown, window.Orientation.UNSPECIFIED);
    orientationMap.set(ScreenOrientation.kPortrait, window.Orientation.PORTRAIT);
    orientationMap.set(ScreenOrientation.kPortraitUpsideDown, window.Orientation.PORTRAIT_INVERTED);
    orientationMap.set(ScreenOrientation.kLandscapeLeft, window.Orientation.LANDSCAPE);
    orientationMap.set(ScreenOrientation.kLandscapeRight, window.Orientation.LANDSCAPE_INVERTED);
    orientationMap.set(ScreenOrientation.kAutoRotation, window.Orientation.AUTO_ROTATION);
    return orientationMap;
  })();
  static _instance: WindowUtils;

  static getInstance(): WindowUtils {
    if (!WindowUtils._instance) {
      WindowUtils._instance = new WindowUtils();
    }

    return WindowUtils._instance;
  }

  getMainWindow(): window.Window {
    return GetFromGlobalThis(this.MainWindowKey);
  }

  setWindowSizeChangeCallback() {
    let windowClass: window.Window = this.getMainWindow();
    try {
      windowClass.on('windowSizeChange', (size) => {
        this.setXComponentSizeWithSafeArea(size.width, size.height, Tuanjie.nativeGetIsRenderOutsizeSafeArea());
      })
    } catch (err) {
      TuanjieLog.error('setWindowSizeChangeCallback failed, reason: ' + JSON.stringify(err))
    }
  }

  setWindowAvoidAreaChangeCallBack() {
    let windowClass: window.Window = this.getMainWindow();
    try {
      windowClass.on('avoidAreaChange', (data) => {
        let safeArea = this.getSafeAreaWithNativeFormat(Tuanjie.nativeGetIsRenderOutsizeSafeArea());
        Tuanjie.nativeGetIsAvoidAreaChange(safeArea);
        this.setXComponentSizeWithSafeArea(0, 0, Tuanjie.nativeGetIsRenderOutsizeSafeArea());
      })
    } catch (err) {
      TuanjieLog.error('setWindowAvoidAreaChangeCallBack failed, reason: ' + JSON.stringify(err))
    }
  }

  setSystemBarState(systemBars: Array<string>) {
    let requestedBars: ("status" | "navigation")[] = systemBars as ("status" | "navigation")[];
    if (this.systemBarState != null &&
      JSON.stringify(this.systemBarState) === JSON.stringify(requestedBars)) {
      return;
    }

    let windowClass: window.Window = this.getMainWindow();
    windowClass.setWindowSystemBarEnable(requestedBars).then(() => {
      TuanjieLog.info('Succeeded in setting the system bar to be invisible.');
      this.systemBarState = requestedBars;
    }).catch((err: ESObject) => {
      TuanjieLog.error('Failed to set the system bar to be invisible. Cause:' + JSON.stringify(err));
    })
  }

  setOrientation(orientNum: number) {
    if (!this.nativeToOpenHarmonyOrientationMap.has(orientNum)) {
      return;
    }
    let orientation: window.Orientation | undefined = this.nativeToOpenHarmonyOrientationMap.get(orientNum);
    let windowClass: window.Window = this.getMainWindow();
    windowClass.setPreferredOrientation(orientation).then(() => {
      TuanjieLog.info('Succeeded in setting the window orientation.');
    }).catch((err: ESObject) => {
      TuanjieLog.error('Failed to set the window orientation. Cause: ' + JSON.stringify(err));
    })
  }

  getWindowAvoidArea(avoidAreaType: window.AvoidAreaType) {
    let windowClass: window.Window = this.getMainWindow();
    if (windowClass == null || windowClass == undefined) {
      return null;
    }
    return windowClass.getWindowAvoidArea(avoidAreaType);
  }

  getSafeArea(width: number, height: number): window.Rect | null {
    let cutoutAvoidArea: window.AvoidArea | null = this.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
    let systemAvoidArea: window.AvoidArea | null = this.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);

    if (cutoutAvoidArea == null) {
      return null;
    }

    let cutoutSafeAreaLeft = cutoutAvoidArea.leftRect.left + cutoutAvoidArea.leftRect.width;
    let cutoutSafeAreaTop = cutoutAvoidArea.topRect.top + cutoutAvoidArea.topRect.height;
    let cutoutSafeAreaRight = cutoutAvoidArea.rightRect.left || width;
    let cutoutSafeAreaBottom = cutoutAvoidArea.bottomRect.top || height;

    if (systemAvoidArea == null) {
      return {
        left: cutoutSafeAreaLeft,
        top: cutoutSafeAreaTop,
        width: cutoutSafeAreaRight - cutoutSafeAreaLeft,
        height: cutoutSafeAreaBottom - cutoutSafeAreaTop
      };
    }

    let systemSafeAreaLeft = systemAvoidArea.leftRect.left + systemAvoidArea.leftRect.width;
    let systemSafeAreaTop = systemAvoidArea.topRect.top + systemAvoidArea.topRect.height;
    let systemSafeAreaRight = systemAvoidArea.rightRect.left || width;
    let systemSafeAreaBottom = systemAvoidArea.bottomRect.top || height;

    let safeAreaLeft = Math.max(cutoutSafeAreaLeft, systemSafeAreaLeft);
    let safeAreaTop = Math.max(cutoutSafeAreaTop, systemSafeAreaTop);
    let safeAreaRight = Math.min(cutoutSafeAreaRight, systemSafeAreaRight);
    let safeAreaBottom = Math.min(cutoutSafeAreaBottom, systemSafeAreaBottom);

    if (safeAreaRight <= safeAreaLeft || safeAreaBottom <= safeAreaTop) {
      return null;
    }

    return {
      left: safeAreaLeft,
      top: safeAreaTop,
      width: safeAreaRight - safeAreaLeft,
      height: safeAreaBottom - safeAreaTop
    };
  }

  calculateSafeArea(width: number, height: number): window.Rect | null {
    let safeAreaRect: window.Rect | null = this.getSafeArea(width, height);
    if (safeAreaRect == null) {
      return null;
    }
    return {
      left: safeAreaRect.left,
      top: height - safeAreaRect.top - safeAreaRect.height,
      width: safeAreaRect.width,
      height: safeAreaRect.height
    };
  }

  getSafeAreaWithNativeFormat(renderOutside: boolean) {
    let windowRect = this.getMainWindow().getWindowProperties().windowRect;
    let safeArea = this.calculateSafeArea(windowRect.width, windowRect.height);
    if (safeArea == null) {
      return [0, 0, 0, 0];
    }
    if (!renderOutside) {
      return [0, 0, safeArea.width, safeArea.height];
    }
    return [safeArea.left, safeArea.top, safeArea.width, safeArea.height];
  }

  setXComponentSizeWithSafeArea(width: number, height: number, renderOutside: boolean) {
    if (width == 0 || height == 0) {
      let properties = this.getMainWindow().getWindowProperties();
      width = properties.windowRect.width;
      height = properties.windowRect.height;
    }
    let safeAreaWidth: number, safeAreaHeight: number, safeAreaXOffset: number, safeAreaYOffset: number;
    if (renderOutside) {
      safeAreaWidth = width;
      safeAreaHeight = height;
      safeAreaXOffset = 0;
      safeAreaYOffset = 0;
    } else {
      let safeArea = this.getSafeArea(width, height);
      if (safeArea == null) {
        return;
      }
      safeAreaWidth = safeArea.width;
      safeAreaHeight = safeArea.height;
      safeAreaXOffset = safeArea.left;
      safeAreaYOffset = safeArea.top;
    }
    AppStorage.setOrCreate<window.Rect>(APP_KEY_SAFEAREA_RECT, {
      left: safeAreaXOffset,
      top: safeAreaYOffset,
      width: safeAreaWidth,
      height: safeAreaHeight
    });
  }

  fillCutoutArray(uint16Array: Uint16Array, rect: window.Rect, startIdx: number) {
    uint16Array[startIdx++] = rect.left;
    uint16Array[startIdx++] = rect.top;
    uint16Array[startIdx++] = rect.width;
    uint16Array[startIdx++] = rect.height;
    return startIdx;
  }

  getCutouts(arrayBuffer: ArrayBuffer) {
    let avoidArea: window.AvoidArea | null = this.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
    if (avoidArea == null) {
      return null;
    }
    let uint16Array = new Uint16Array(arrayBuffer);
    let startIndex: number = 0;
    startIndex = this.fillCutoutArray(uint16Array, avoidArea.leftRect, startIndex);
    startIndex = this.fillCutoutArray(uint16Array, avoidArea.topRect, startIndex);
    startIndex = this.fillCutoutArray(uint16Array, avoidArea.rightRect, startIndex);
    startIndex = this.fillCutoutArray(uint16Array, avoidArea.bottomRect, startIndex);
    return arrayBuffer;
  }

  setScreenOn(value: boolean) {
    let windowClass: window.Window = this.getMainWindow();
    // only kNeverSleep & kSystemSetting are supported like other platforms
    windowClass.setWindowKeepScreenOn(value);
  }

  moveTaskToBack() {
    let windowClass: window.Window = this.getMainWindow();
    windowClass.minimize((err: ESObject) => {
      const errCode: number = err.code;
      if (errCode) {
        TuanjieLog.error(`Failed to minimize the window. Cause code: ${err.code}, message: ${err.message}`);
        return;
      }
      TuanjieLog.info('Succeeded in minimizing the window.');
    });
  }

  getPasteboard() {
    let enableReadPasteboard : boolean = TuanjiePermissions.checkAccessToken('ohos.permission.READ_PASTEBOARD');
    if(!enableReadPasteboard)
    {
      TuanjieLog.error('No permission \'ohos.permission.READ_PASTEBOARD\' to read the pasteboard.');
      return "";
    }

    let sysPasteBoard = pasteboard.getSystemPasteboard();
    let pasteData = sysPasteBoard.getDataSync();
    if (pasteData) {
      try
      {
        let number = pasteData.getRecordCount();
        if (number == 0)
        {
          TuanjieLog.info('Failed to get text from the empty pasteboard.');
          return "";
        }

        let record = pasteData.getPrimaryText();
        TuanjieLog.info('Succeeded in reading the pasteboard.');
        return record;
      }
      catch (err)
      {
        TuanjieLog.error('Failed to read the pasteboard. ', 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
        return "";
      }
    }
    return "";
  }

  setPasteboard(content: string) {
    let sysPasteBoard = pasteboard.getSystemPasteboard();
    let hasData = sysPasteBoard.hasDataSync();
    if (hasData) {
      let pasteData = sysPasteBoard.getDataSync();
      let record = pasteboard.createRecord(pasteboard.MIMETYPE_TEXT_PLAIN, content);
      let number = pasteData.getRecordCount();
      if (number == 0) {
        pasteData.addRecord(record)
      } else {
        pasteData.replaceRecord(0, record);
      }
      sysPasteBoard.setDataSync(pasteData);
    } else {
      let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
      sysPasteBoard.setDataSync(pasteData);
    }
    return true;
  }

  showSingleButtonDialog(dialogTitle: string, dialogMessage: string, dialogButtonText = "OK") {
    DebuggerDialogInfo.setDebuggerDialogInfo(dialogTitle, dialogMessage, dialogButtonText, true);
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, WindowUtils.getInstance());

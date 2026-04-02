import { TuanjieLog } from '../common/TuanjieLog';
import display from '@ohos.display';
import { POST_MESSAGE } from '../workers/WorkerProxy'
import { APP_KEY_ORIENTATION_CHANGE } from '../common/Constants';

export class TuanjieDisplayInfo {
  displayID: number = 0;
  width: number = 0;
  height: number = 0;
  rotation: number = 0;
  refreshRate: number = 0;
  densityDPI: number = 0;
}

export class DisplayInfoManager {
  // make rotation index consistent with android
  static readonly openHarmonyToNativeRotationMap: Record<number, number> = {
    0: 0,
    1: 3,
    2: 2,
    3: 1
  };

  // todo ohos: don't support multi displayi now
  defaultDisplay: TuanjieDisplayInfo;
  private static instance = new DisplayInfoManager();

  private constructor() {
    TuanjieLog.debug('%{public}s', 'OhosSysInfo.constructor');
    this.defaultDisplay = new TuanjieDisplayInfo();
  }

  public initialize(): void {
    this.updateDisplayInfo();
    this.enableDisplayChangeCallback();
  }

  private enableDisplayChangeCallback(): void {
    let callback = (data: ESObject) => {
      TuanjieLog.info('Listening enabled. Data: ' + JSON.stringify(data));
      this.updateDisplayInfo();
    };
    try {
      display.on("change", callback);
    } catch (exception) {
      TuanjieLog.error('Failed to register callback. Code: ' + JSON.stringify(exception));
    }
  }

  private updateDisplayInfo(): void {
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
      this.defaultDisplay.displayID = displayClass.id;
      this.defaultDisplay.width = displayClass.width;
      this.defaultDisplay.height = displayClass.height;
      this.defaultDisplay.rotation = DisplayInfoManager.openHarmonyToNativeRotationMap[displayClass.rotation];
      this.defaultDisplay.refreshRate = displayClass.refreshRate;
      this.defaultDisplay.densityDPI = displayClass.densityDPI;

      AppStorage.setOrCreate<number>(APP_KEY_ORIENTATION_CHANGE, displayClass.rotation);

      POST_MESSAGE({
        type: 'SetDisplayInfo',
        data: this.defaultDisplay
      });
    }
    catch (err) {
      TuanjieLog.error('Failed to obtain the default display object. Code: ' + JSON.stringify(err));
    }
  }

  public static getInstance(): DisplayInfoManager {
    return DisplayInfoManager.instance;
  }
}

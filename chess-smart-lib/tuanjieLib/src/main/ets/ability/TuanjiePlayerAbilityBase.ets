import window from '@ohos.window';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import UIAbility from '@ohos.app.ability.UIAbility';
import { BusinessError } from '@kit.BasicServicesKit';

import '../workers/Init';
import { DisplayInfoManager } from '../utils/DisplayInfoManager'
import { GetFromGlobalThis, SetToGlobalThis } from '../common/GlobalThisUtil';
import { Tuanjie } from '../utils/TuanjieNative';
import { TuanjieLog } from '../common/TuanjieLog';
import { POST_MESSAGE } from '../workers/WorkerProxy';
import { WindowUtils } from '../utils/WindowUtils'
import { VideoPlayerProxy } from '../utils/VideoPlayerProxy'

export class TuanjiePlayerAbilityBase extends UIAbility {
  pageUri: string = "pages/Index";
  windowStage: window.WindowStage | undefined = undefined;

  setPageUri(uri: string): void {
    this.pageUri = uri;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    TuanjieLog.info('%{public}s', 'TuanjiePlayerAbility onCreate, bundleCodeDir:' + this.context.bundleCodeDir);
    if (this.context.resourceManager.getNumber(GetFromGlobalThis("showStaticSplash"))) {
      globalThis.showStaticSplashScreen = true;
    }

    Tuanjie.nativeOnCreate();
    if (typeof want.parameters !== "undefined") {
      globalThis.CommandLineArguments = want.parameters["unity"]?.toString();
    }
    POST_MESSAGE({
      type: 'SetGlobalThisContext', data: this.context
    });
    globalThis.AbilityContext = this.context;
    DisplayInfoManager.getInstance().initialize();
    AppStorage.setOrCreate("backButtonLeavesApp", false);
  }

  onDestroy(): void {
    TuanjieLog.info('%{public}s', 'TuanjiePlayerAbility onDestroy');

    Tuanjie.nativeOnDestroy();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    TuanjieLog.info('%{public}s', 'TuanjiePlayerAbility onWindowStageCreate');
    this.windowStage = this.windowStage;

    // set full screen at first
    let windowClass = windowStage.getMainWindowSync();
    try {
      SetToGlobalThis(WindowUtils.getInstance().MainWindowKey, windowClass);
      WindowUtils.getInstance().setWindowSizeChangeCallback();
      WindowUtils.getInstance().setWindowAvoidAreaChangeCallBack();
      windowClass.setWindowLayoutFullScreen(true, (err, data) => {
        if (err.code) {
          console.error('Failed to enable the full-screen mode. Cause: ' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in enabling the full-screen mode. Data: ' + JSON.stringify(data));
      });
    } catch (err) {
      console.error('Failed to obtain the main window. Cause: ' + JSON.stringify(err));
    }

    // this.pageUri = 'pages/TuanjiePlayerAbilityIndex';
    windowStage.loadContent(this.pageUri, (err, data) => {
      if (err.code) {
        TuanjieLog.error('Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      TuanjieLog.info('Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });

    // set callback
    windowStage.on('windowStageEvent', (data) => {
      let stageEventType: window.WindowStageEventType = data;
      switch (stageEventType) {
        case window.WindowStageEventType.ACTIVE:
          TuanjieLog.info('windowStage active.');
          Tuanjie.nativeOnWindowStageActive();
          break;
        case window.WindowStageEventType.INACTIVE:
          TuanjieLog.info('windowStage inactive.');
          Tuanjie.nativeOnWindowStageInActive();
          break;
        case window.WindowStageEventType.RESUMED:
          TuanjieLog.info('windowStage resumed.');
          this.onResume();
          break;
        case window.WindowStageEventType.PAUSED:
          TuanjieLog.info('windowStage paused.');
          this.onPause();
          break;
        default:
          break;
      }
    })
  }

  onWindowStageDestroy(): void {
    TuanjieLog.info('%{public}s', 'TuanjiePlayerAbility onWindowStageDestroy');
     try {
       if (this.windowStage) {
         this.windowStage.off('windowStageEvent');
       }
    } catch (err) {
       let code = (err as BusinessError).code;
       let errMsg = (err as BusinessError).message;
       TuanjieLog.error(`Failed to disable listener for windowStageEvent. code=${code} errmsg=${errMsg}`);
    }
  }

  onForeground(): void {
    TuanjieLog.info('%{public}s', 'TuanjiePlayerAbility onForeground');
    this.onResume();
  }

  onBackground(): void {
    TuanjieLog.info('%{public}s', 'TuanjiePlayerAbility onBackground');
    this.onPause();
  }

  private onResume(): void {
    if (VideoPlayerProxy.getInstance().IsPlaying()) {
      VideoPlayerProxy.getInstance().OnResume();
    }
    else {
      Tuanjie.nativeOnResume();
    }
    POST_MESSAGE({
      type: 'InternetSubscribe', data: null
    });
  }

  private onPause(): void {
    if (VideoPlayerProxy.getInstance().IsPlaying()) {
      VideoPlayerProxy.getInstance().OnPause();
    }
    else {
      Tuanjie.nativeOnPause();
    }
  }
}

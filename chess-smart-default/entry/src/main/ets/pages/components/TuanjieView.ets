import { TuanjieLog } from '../../common/TuanjieLog';
import Tuanjie from 'libtuanjie.so'

class TuanjieViewInfo {
  private surfaceId: number;
  private displayIndex: number;
  private xComponentId: number;
  private windowId: number;

  constructor(surfaceId: number, index: number) {
    this.surfaceId = surfaceId;
    this.displayIndex = index;
    this.xComponentId = 0;
    this.windowId = 0;
  }

  DisplayIndex(): number {
    return this.displayIndex;
  }

  UpdateDisplayIndex(displayIndex: number) {
    this.displayIndex = displayIndex;
    Tuanjie.nativeUpdateDisplay(displayIndex, this.xComponentId, this.windowId);
  }

  XComponentId(): number {
    return this.xComponentId;
  }

  WindowId(): number {
    return this.windowId;
  }

  UpdateWindowInfo(componentId: number, windowId: number) {
    this.xComponentId = componentId;
    this.windowId = windowId;
  }

  toString(): string {
    return `TuanjieViewInfo:${this.surfaceId}-${this.displayIndex}-${this.xComponentId}-${this.windowId}`;
  }
}

class TuanjieViewController extends XComponentController  {
  static getSurfaceDisplayIndexSet: boolean = false;
  static surface2DisplayIndex: Record<number, TuanjieViewInfo> = {};

  static getDisplayIndex(xcomponentId: number, windowId: number, surfaceId: number) {
    console.log(`getDisplayIndex| surfaceId=${surfaceId}`);
    let info: TuanjieViewInfo = TuanjieViewController.surface2DisplayIndex[surfaceId];
    if (info != undefined) {
      info.UpdateWindowInfo(xcomponentId, windowId);
      return info.DisplayIndex();
    }
    return -1;
  }

  onDidBuild(displayIndex: number) {
    let strSurfaceId: string = this.getXComponentSurfaceId();
    let surfaceId : number = parseInt(strSurfaceId, 10);
    TuanjieLog.info('%{public}s', `onDidBuild| surfaceId=${surfaceId} displayIndex=${displayIndex}}`);
    TuanjieViewController.surface2DisplayIndex[surfaceId] = new TuanjieViewInfo(surfaceId, displayIndex);

    if (!TuanjieViewController.getSurfaceDisplayIndexSet) {
      Tuanjie.nativeSetGetSurfaceDisplayIndexFunc(TuanjieViewController.getDisplayIndex);
      TuanjieViewController.getSurfaceDisplayIndexSet = true;
    }
  }

  updateDisplayIndex(displayIndex: number) {
    let strSurfaceId: string = this.getXComponentSurfaceId();
    let surfaceId : number = parseInt(strSurfaceId, 10);
    let info: TuanjieViewInfo = TuanjieViewController.surface2DisplayIndex[surfaceId];
    if (info != undefined) {
      TuanjieLog.info('%{public}s', `updateDisplayIndex| ${info} new displayindex=${displayIndex}`);
      info.UpdateDisplayIndex(displayIndex);
    } else {
      TuanjieLog.warn('%{public}s', `updateDisplayIndex| No window info with surfaceId=${strSurfaceId}`);
    }
  }
}

@Component
export struct TuanjieView {
  @Prop index: number = 0;
  @Link @Watch("onDisplayIndexChanged") displayIndex: number;
  private controller: XComponentController = new TuanjieViewController();

  build() {
    Stack() {
      XComponent({ id: 'TuanjiePlayer', type: 'surface', libraryname: 'tuanjie', controller: this.controller })
        .onLoad(() => {
          TuanjieLog.info('%{public}s', `XComponent ${this.displayIndex} onLoad`);
        })
        .onDestroy(() => {
          TuanjieLog.info('%{public}s', `XComponent ${this.displayIndex} onDestroy`);
        })
        .onAppear(() => {
          TuanjieLog.info('%{public}s', `XComponent ${this.displayIndex} onAppear`);
        })
        .onDisAppear(() => {
          TuanjieLog.info('%{public}s', `XComponent ${this.displayIndex} onDisAppear`);
        })
        .defaultFocus(true)
        .focusable(true)
        .width('100%')
        .height('100%');
    }
  }

  onDidBuild(): void {
    TuanjieLog.info('%{public}s', `XComponent onDidBuild surfaceId=${this.controller.getXComponentSurfaceId()} displayIndex=${this.displayIndex}}`);
    if (this.displayIndex != -1) {
      let ctrl: TuanjieViewController = this.controller as TuanjieViewController;
      ctrl?.onDidBuild(this.displayIndex);
    }
  }

  onDisplayIndexChanged() {
    let ctrl: TuanjieViewController = this.controller as TuanjieViewController;
    ctrl?.updateDisplayIndex(this.displayIndex);
  }
}

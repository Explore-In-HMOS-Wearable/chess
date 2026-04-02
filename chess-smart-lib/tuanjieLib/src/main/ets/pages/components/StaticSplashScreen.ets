import resourceManager from '@ohos.resourceManager';

import { GetFromGlobalThis } from '../../common/GlobalThisUtil';

@Component
export struct StaticSplashScreen {
  @State showStaticSplashScreen: boolean = GetFromGlobalThis('showStaticSplashScreen');
  @State resConf: Resource = GetFromGlobalThis('staticSplashScreenFit');
  @State imageRes: Resource = GetFromGlobalThis('appSplash');
  @State imageFit: ImageFit = 0;

  async aboutToAppear() {
    let resourceManager = getContext(this).resourceManager;
    let resource: resourceManager.Resource = {
      bundleName: this.resConf.bundleName,
      moduleName: this.resConf.moduleName,
      id: this.resConf.id
    }
    this.imageFit = await resourceManager.getNumber(resource);
    setTimeout(() => {
      this.showStaticSplashScreen = false
    }, 2600)
  }

  build() {
    Stack() {
      if (this.showStaticSplashScreen) {
        Image(this.imageRes).objectFit(this.imageFit)
      }
    }
  }
}
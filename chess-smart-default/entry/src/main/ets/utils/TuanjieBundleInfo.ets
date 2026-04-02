import { TuanjieLog } from '../common/TuanjieLog';
import { bundleManager } from '@kit.AbilityKit';


export class TuanjieBundleInfo {
  versionCode: number = -1;
  versionName: string = "";
  vendor: string = "";

  static async instance(): Promise<ESObject> {
    const bundleInfo = new TuanjieBundleInfo();
    try {
      const data = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT
      );

      bundleInfo.versionCode = data.versionCode;
      bundleInfo.versionName = data.versionName;
      bundleInfo.vendor = data.vendor;

      return bundleInfo;

    } catch (err) {
      TuanjieLog.error("getBundleInfoForSelf failed. Cause: " + err.message);
      return null;
    }
  }
}
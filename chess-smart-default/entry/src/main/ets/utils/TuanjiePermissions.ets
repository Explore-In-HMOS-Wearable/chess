import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';
import { TuanjieLog } from '../common/TuanjieLog';
import { POST_MESSAGE } from '../workers/WorkerProxy';

import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';

// Matches enum in PermissionCallback.h
class PermissionResult {
  static readonly Success: number = 0;
  static readonly Failed: number = 1;
  static readonly Error: number = 2;
}

export class TuanjiePermissions {
  public static requestUserPermissions(permissionList: string, onGranted: number, onDenied: number): void {

    let permissionsStr: Array<string> = permissionList.split(',');

    TuanjieLog.info('requestUserPermissions enter.');
    const atManager = abilityAccessCtrl.createAtManager();
    let context: ESObject = globalThis.AbilityContext;

    let permissions: Array<Permissions> = [];
    permissionsStr.forEach(element => {
      permissions.push(element as Permissions);
    });

    let permissionsSize: number = permissions.length;
    let permissionResults: Array<number> = new Array(permissionsSize);
    permissionResults.fill(PermissionResult.Error);

    atManager.requestPermissionsFromUser(context, permissions, (err, data) => {
      if (err) {
        TuanjieLog.error('Failed to requestPermission. Cause: %{public}s',
          JSON.stringify(err) ?? '');
      } else {
        TuanjieLog.info('Succeeded in requestPermission. Data: %{public}s',
          JSON.stringify(data) ?? '');
        for (let i = 0; i < permissionsSize; i++) {
          if (data.authResults[i] == 0) {
            permissionResults[i] = PermissionResult.Success;
          } else {
            permissionResults[i] = PermissionResult.Failed;
          }
        }
      }
      POST_MESSAGE({
        type: 'GetPermissionRequestResult',
        permissions: data.permissions,
        results: permissionResults,
        onGranted: onGranted,
        onDenied: onDenied
      });
    })
  }

  public static checkAccessToken(permission: Permissions) : boolean{
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = -1;

    // Obtain the access token ID of the application.
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (err) {
      TuanjieLog.error('Failed to getBundleInfoForSelfSync. Cause: %{public}s',
        JSON.stringify(err) ?? '');
    }

    // Check whether the user has granted the permission.
    try {
      grantStatus = atManager.checkAccessTokenSync(tokenId, permission);
    } catch (err) {
      TuanjieLog.error('Failed to checkAccessTokenSync. Cause: %{public}s',
        JSON.stringify(err) ?? '');
    }

    return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  public static hasPermission(permissionsStr: string): boolean {
    console.log(`hasPermission=${permissionsStr}`);
    let permission = permissionsStr as Permissions;
    let grantStatus = TuanjiePermissions.checkAccessToken(permission);
    return grantStatus;
  }

  public static checkPermission(permissionsStr: string, onAuthorized: number, onUnauthorized: number): void {
    let permission = permissionsStr as Permissions;
    let checkResult = PermissionResult.Error;
    try {
      let grantStatus: boolean = TuanjiePermissions.checkAccessToken(permission);
      if (grantStatus) {
        checkResult = PermissionResult.Success;
      } else {
        checkResult = PermissionResult.Failed;
      }
    } catch (err) {
      TuanjieLog.error('Failed to checkPermission. Cause: %{public}s',
        JSON.stringify(err) ?? '');
    } finally {
      POST_MESSAGE({
        type: 'GetPermissionAuthorizeResult',
        permission: permission,
        result: checkResult,
        onAuthorized: onAuthorized,
        onUnauthorized: onUnauthorized
      });
    }
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, TuanjiePermissions);

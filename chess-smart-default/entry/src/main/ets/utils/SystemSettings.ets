import settings from '@ohos.settings';
import { GetFromGlobalThis } from '../common/GlobalThisUtil';
import { Context } from '@ohos.abilityAccessCtrl';
import { TuanjieLog } from '../common/TuanjieLog';
import connection from '@ohos.bluetooth.connection';
import { BusinessError } from '@ohos.base';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';

export class SystemSettings {
  isAutoRotationLocked(): boolean {
    let context: Context = GetFromGlobalThis('AbilityContext');
    if (context == null || context == undefined) {
      TuanjieLog.warn('can not get context from globalThis');
      return true;
    }
    return settings.getValueSync(context, settings.general.ACCELEROMETER_ROTATION_STATUS, '0') === '0';
  }

  getDeviceName(): string {
    try {
      let localName: string = connection.getLocalName();
      return localName == "" ? "<unknown>" :localName;
    } catch (err) {
      console.error('failed to get the device name from the \'ohos.bluetooth.connection\'. ', 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return "";
    }
  }

  getCommandLineArguments()
  {
    let cmdLine : string = GetFromGlobalThis("CommandLineArguments")
    if(cmdLine == undefined)
      return ""
    return cmdLine
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, new SystemSettings());
!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, AppStorage);
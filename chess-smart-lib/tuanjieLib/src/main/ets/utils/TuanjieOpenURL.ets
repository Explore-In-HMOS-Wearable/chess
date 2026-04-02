import common from '@ohos.app.ability.common';
import { TuanjieLog } from '../common/TuanjieLog';
import uri from '@ohos.uri';
import Want from '@ohos.app.ability.Want';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';

export class TuanjieOpenURL {

  OpenURL(urlStr: string){
    let abilityContext: ESObject = globalThis.AbilityContext;
    let context = abilityContext as common.UIAbilityContext;
    const url = new uri.URI(urlStr);
    let result = url.scheme == null? `https://${urlStr}` : urlStr;
    let wantInfo: Want = {
      'action': 'ohos.want.action.viewData',
      'entities': ['entity.system.browsable'],
      'uri':result
    }
    context.startAbility(wantInfo).then(() => {
    }).catch((err: ESObject) => {
      TuanjieLog.error("OpenURL failed, err: " + err);
    })
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, new TuanjieOpenURL());

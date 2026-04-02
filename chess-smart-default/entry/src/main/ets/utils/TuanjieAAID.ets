import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';
import { GetFromGlobalThis } from '../common/GlobalThisUtil';
import { Context } from '@ohos.abilityAccessCtrl';
import util from '@ohos.util';
import dataPreferences from '@ohos.data.preferences';

class TuanjieAAID {
  GetAAID() {
    let context: Context = GetFromGlobalThis('AbilityContext');
    let options: dataPreferences.Options = { name: 'tuanjieStore' };
    let preferences = dataPreferences.getPreferencesSync(context, options);
    let cachedKey = "tuanjie-cached-random-uuid";

    if (preferences.hasSync(cachedKey)) {
      return preferences.getSync(cachedKey, '');
    }

    let uuid = util.generateRandomUUID(true);
    preferences.putSync(cachedKey, uuid);

    preferences.flush((err) => {
      if (err) {
        console.error("Failed to flush. code =" + err);
        return;
      }
    })

    return uuid;
  }
}
!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, new TuanjieAAID());

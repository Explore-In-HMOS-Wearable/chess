import vibrator from '@ohos.vibrator';
import { TuanjieLog } from '../common/TuanjieLog';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';

export class TuanjieVibrate {
  vibrate(vibrateMs: number) {
    try {
      vibrator.startVibration({ type: 'time', duration: vibrateMs }, { id: 0, usage: 'alarm' }, (error) => {
        if (error) {
          console.error('Vibrate fail, error.code: ' + error.code + 'error.message: ${error.message}');
          return;
        }
        console.log('Callback returned to indicate a successful vibration.');
      });
    } catch (err) {
      console.error('errCode: ' + err.code + ' ,msg: ' + err.message);
    }

    TuanjieLog.info("Trigger Vibrate");
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, new TuanjieVibrate())
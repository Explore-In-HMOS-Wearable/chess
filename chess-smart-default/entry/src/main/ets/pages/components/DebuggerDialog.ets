import promptAction from '@ohos.promptAction';

import { SetToGlobalThis } from '../../common/GlobalThisUtil';
import { TuanjieLog } from '../../common/TuanjieLog';
import { DebuggerDialogInfo } from '../../utils/DebuggerDialogInfo'
import { Tuanjie } from '../../utils/TuanjieNative';

@Component
export struct DebuggerDialog {
  @Link debuggerDialogInfo: DebuggerDialogInfo;

  build() {}

  aboutToAppear()
  {
      promptAction.showDialog({
      title: this.debuggerDialogInfo.Title,
      message: this.debuggerDialogInfo.Message,
      buttons: [
        {
          text: this.debuggerDialogInfo.buttonText,
          color: "#000000"
        }
      ]
    }).then( data => {
        Tuanjie.nativeDebuggerDialogClosed();
        this.debuggerDialogInfo.Showing = false;
      });
  }
};
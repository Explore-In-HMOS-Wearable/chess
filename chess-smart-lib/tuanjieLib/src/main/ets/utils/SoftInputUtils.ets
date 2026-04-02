import { TuanjieLog } from '../common/TuanjieLog';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';

export class SoftInputUtils {

    public showSoftInput(initialText: string): void {

		globalThis.inputInitialText = initialText;
		globalThis.dialogController.open();

		TuanjieLog.info("Show softInput " + initialText);
    }

		public hideSoftInput(): void {

			globalThis.dialogController.close();

			TuanjieLog.info("Hide softInput");
		}
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, new SoftInputUtils());
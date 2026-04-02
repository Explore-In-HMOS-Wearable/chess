import { SetToGlobalThis } from '../common/GlobalThisUtil';
import { TuanjieLog } from '../common/TuanjieLog';
import { PROCESS_WORKER_MESSAGE } from "./HostProxy";
import { Tuanjie } from '../utils/TuanjieNative';

import worker from '@ohos.worker';

TuanjieLog.debug("tuanjie.nativeSetWorker");
Tuanjie.nativeSetWorker();

const workerPort = worker.workerPort
// This line makes workerPort available for native code
// not sure why, maybe compiler will optimize `const`
//globalThis.workerPort = workerPort;
SetToGlobalThis("workerPort", workerPort);

workerPort.onmessage = async (e) => {
  PROCESS_WORKER_MESSAGE(e.data);
}
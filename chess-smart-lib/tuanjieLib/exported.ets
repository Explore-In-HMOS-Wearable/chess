// Exported object from Tuanjie library

export { TuanjiePlayerAbilityBase } from './src/main/ets/ability/TuanjiePlayerAbilityBase'
export { TuanjiePlayerView } from './src/main/ets/pages/components/TuanjiePlayerView'

export { POST_MESSAGE_TO_HOST } from './src/main/ets/workers/HostProxy'     // send message to host(aka ui or main) thread
export { POST_MESSAGE_TO_WORKER } from './src/main/ets/workers/WorkerProxy' // send message to worker(tuanjie main) thread

export { APP_KEY_SAFEAREA_RECT } from './src/main/ets/common/Constants'

export { GetFromGlobalThis, SetToGlobalThis } from './src/main/ets/common/GlobalThisUtil'

export { MSG_RECEIVER,
  LOAD_MODULE, UNLOAD_MODULE,
  REGISTER_MODULE, UNREGISTER_MODULE,
  REGISTER_HANDLER, UNREGISTER_HANDLER,
} from './src/main/ets/workers/MessageProcessor'

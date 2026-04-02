import { POST_MESSAGE } from './WorkerProxy';
import { TuanjieLog } from '../common/TuanjieLog';
import { Tuanjie } from '../utils/TuanjieNative';
import { Init } from './MessageProcessor';

Init(POST_MESSAGE, TuanjieLog, Tuanjie);

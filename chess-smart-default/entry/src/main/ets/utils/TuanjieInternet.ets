import network from '@system.network';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';

enum NetworkReachability {
  NotReachable,
  ReachableViaCarrierDataNetwork,
  ReachableViaLocalAreaNetwork
}
  
export class TuanjieInternet {

  static  internetState = NetworkReachability.NotReachable;

  static Subscribe() {
    network.subscribe({
      success: (data) => {
        console.log('network type change type:' + data.type);
        if (data.metered) {
          TuanjieInternet.internetState = NetworkReachability.ReachableViaCarrierDataNetwork;
        }
        else if (data.type == "WiFi") {
          TuanjieInternet.internetState = NetworkReachability.ReachableViaLocalAreaNetwork;
        }
        else {
          TuanjieInternet.internetState = NetworkReachability.NotReachable;
        }
      },
      fail: (data: ESObject, code) => {
        console.log('fail to subscribe network, code:' + code + ', data:' + data);
      },
    });
  }

  static GetInternetReachability() {
      return TuanjieInternet.internetState;
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, TuanjieInternet);

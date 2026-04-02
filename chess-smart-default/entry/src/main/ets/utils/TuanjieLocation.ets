import geoLocationManager from '@ohos.geoLocationManager';
import { TuanjieLog } from '../common/TuanjieLog';
import sensor from '@ohos.sensor'
import { POST_MESSAGE } from '../workers/WorkerProxy';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';

class TuanjieLocation {
  requestLocationUpdates(timeInterval: number, distanceInterval: number, accuracy: number) {
    let requestInfo:geoLocationManager.LocationRequest = {'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX, 'scenario': geoLocationManager.LocationRequestScenario.UNSET,
      'timeInterval': timeInterval, 'distanceInterval': distanceInterval, 'maxAccuracy': accuracy};

    let locationChange = (location: geoLocationManager.Location):void => {
      TuanjieLog.info('Update Location. Data: %{public}s',
        JSON.stringify(location) ?? '');
      POST_MESSAGE({
        type: 'OnLocation',
        location: location
      });
    };

    try {
      geoLocationManager.on('locationChange', requestInfo, locationChange);
    } catch (err) {
      TuanjieLog.error('Update Location Failed. Error: %{public}s',
        JSON.stringify(err) ?? '');
    }
  }

  removeUpdates() {
    try {
      geoLocationManager.off('locationChange');
    } catch (err) {
      TuanjieLog.error('Remove Updates Failed. Error: %{public}s',
        JSON.stringify(err) ?? '');
    }
  }

  async getDeclination(latitude: number, longitude: number, altitude: number, timestamp: number) {
    let geoInfo = await sensor.getGeomagneticInfo({ latitude: latitude, longitude: longitude, altitude: altitude }, timestamp);
    return geoInfo.deflectionAngle;
  }

  getLastKnownLocation() {
    let loc = geoLocationManager.getLastLocation();
    return [
      loc.latitude,
      loc.longitude,
      loc.altitude,
      loc.accuracy,
      loc.speed,
      loc.timeStamp,
      loc.direction,
      loc.timeSinceBoot,
      ];
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, new TuanjieLocation())
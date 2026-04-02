import { batteryInfo } from '@kit.BasicServicesKit';

export class TuanjieBatteryInfo {
  get batterySOC(): number {
    return batteryInfo.batterySOC;
  }

  get chargingStatus(): number {
    return batteryInfo.chargingStatus;
  }
}
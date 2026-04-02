import hilog from '@ohos.hilog';

export class TuanjieLog {
  private static readonly DOMAIN = 0x0001;
  private static readonly TUANJIE_TAG = "Tuanjie";

  public static debug(format: string, ...args: ESObject[]): void {
    hilog.debug(TuanjieLog.DOMAIN, TuanjieLog.TUANJIE_TAG, format, args);
  }

  public static info(format: string, ...args: ESObject[]): void {
    hilog.info(TuanjieLog.DOMAIN, TuanjieLog.TUANJIE_TAG, format, args);
  }

  public static warn(format: string, ...args: ESObject[]): void {
    hilog.warn(TuanjieLog.DOMAIN, TuanjieLog.TUANJIE_TAG, format, args);
  }

  public static error(format: string, ...args: ESObject[]): void {
    hilog.error(TuanjieLog.DOMAIN, TuanjieLog.TUANJIE_TAG, format, args);
  }

  public static fatal(format: string, ...args: ESObject[]): void {
    hilog.fatal(TuanjieLog.DOMAIN, TuanjieLog.TUANJIE_TAG, format, args);
  }
}

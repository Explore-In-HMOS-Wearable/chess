import fs from '@ohos.file.fs';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';
import { GetFromGlobalThis } from './GlobalThisUtil';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class PlayerPrefs {
  public static directoryInt : Map<string, number> = new Map<string, number>();
  public static directoryFloat : Map<string, number>= new Map<string, number>();
  public static directoryString : Map<string, string>= new Map<string, string>();

  private static  intPreference: preferences.Preferences | null = null;
  private static  floatPreference: preferences.Preferences | null = null;
  private static  stringPreference: preferences.Preferences | null = null;

  public static Init(filePathPrefix : string) {
    if (PlayerPrefs.intPreference)
      return;

    let context: common.Context = GetFromGlobalThis('context');
    PlayerPrefs.intPreference = preferences.getPreferencesSync(context, { name: "tj_intPreference" });
    PlayerPrefs.floatPreference = preferences.getPreferencesSync(context, { name: "tj_floatPreference" });
    PlayerPrefs.stringPreference = preferences.getPreferencesSync(context, { name: "tj_stringPreference" });

    // compatible with older versions, if PlayerPreference.txt exists, read from it.
    let filePath = filePathPrefix + "/PlayerPreference.txt";
    if (fs.accessSync(filePath)) {
      PlayerPrefs.LoadFormFile(filePath);
    }
    else {
      let intKV = PlayerPrefs.intPreference?.getAllSync() as Map<string, number>;
      let keys = Object.keys(intKV);
      keys.forEach((key) =>
      {
        PlayerPrefs.directoryInt[key] = intKV[key];
      });

      let floatKV = PlayerPrefs.floatPreference?.getAllSync() as Map<string, number>;
      keys = Object.keys(floatKV);
      keys.forEach((key) =>
      {
        PlayerPrefs.directoryFloat[key] = floatKV[key];
      });

      let stringKV = PlayerPrefs.stringPreference?.getAllSync() as Map<string, string>;
      keys = Object.keys(stringKV);
      keys.forEach((key) =>
      {
        PlayerPrefs.directoryString[key] = stringKV[key];
      });
    }
  }

  private static LoadFormFile(filePath: string) {
    let file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
    fs.closeSync(file);

    let jsonInt = "{}";
    let jsonFloat = "{}";
    let jsonString = "{}";

    let str = fs.readTextSync(filePath);
    if (str != "") {
      let arr = str.split('\n');
      jsonInt = arr[0];
      jsonFloat = arr[1];
      jsonString = arr[2];
    }

    let directoryInt:Map<string, string | number | boolean> = JSON.parse(jsonInt);
    let directoryFloat:Map<string, string | number | boolean> = JSON.parse(jsonFloat);
    let directoryString:Map<string, string | number | boolean> = JSON.parse(jsonString);

    let keys = Object.keys(directoryInt);
    keys.forEach((element) =>
    {
      PlayerPrefs.directoryInt[element] = directoryInt[element];
      PlayerPrefs.intPreference?.put(element, directoryInt[element]);
    });
    keys = Object.keys(directoryFloat);
    keys.forEach((element) =>
    {
      PlayerPrefs.directoryFloat[element] = directoryFloat[element];
      PlayerPrefs.floatPreference?.put(element, directoryFloat[element]);
    });
    keys = Object.keys(directoryString);
    keys.forEach((element) =>
    {
      PlayerPrefs.directoryString[element] = directoryString[element];
      PlayerPrefs.stringPreference?.put(element, directoryString[element]);
    });

    PlayerPrefs.intPreference?.flush();
    PlayerPrefs.floatPreference?.flush();
    PlayerPrefs.stringPreference?.flush();

    fs.unlinkSync(filePath);
  }

  public static SetInt(name:string, value:number) {
    PlayerPrefs.directoryInt[name] = value;
    PlayerPrefs.intPreference?.put(name, value);
    PlayerPrefs.intPreference?.flush();
  }

  public static SetFloat(name:string, value:number) {
    PlayerPrefs.directoryFloat[name] = value;
    PlayerPrefs.floatPreference?.put(name, value);
    PlayerPrefs.floatPreference?.flush();
  }

  public static SetString(name:string, value:string) {
    PlayerPrefs.directoryString[name] = value;
    PlayerPrefs.stringPreference?.put(name, value);
    PlayerPrefs.stringPreference?.flush();
  }

  public static GetInt(name:string, def:number) : number {
    if (PlayerPrefs.directoryInt[name] == null)
      return def;

    return PlayerPrefs.directoryInt[name];
  }

  public static GetFloat(name:string, def:number) : number{
    if (PlayerPrefs.directoryFloat[name] == null)
      return def;

    return PlayerPrefs.directoryFloat[name];
  }

  public static GetString(name:string, def : string) :string{
    if (PlayerPrefs.directoryString[name] == null)
      return def;

    return PlayerPrefs.directoryString[name];
  }

  public static HasKey(name:string) : boolean {
    if (PlayerPrefs.directoryString[name] != null)
      return true;
    if (PlayerPrefs.directoryFloat[name] != null)
      return true;
    if (PlayerPrefs.directoryInt[name] != null)
      return true;

    return false;
  }

  public static DeleteKey(name:string) {

    if (PlayerPrefs.directoryString[name] != null) {
      PlayerPrefs.directoryString[name] = null;
      PlayerPrefs.stringPreference?.delete(name);
      PlayerPrefs.stringPreference?.flush();
    }
    if (PlayerPrefs.directoryFloat[name] != null){
      PlayerPrefs.directoryFloat[name] = null;
      PlayerPrefs.floatPreference?.delete(name);
      PlayerPrefs.floatPreference?.flush();
    }
    if (PlayerPrefs.directoryInt[name] != null){
      PlayerPrefs.directoryInt[name] = null;
      PlayerPrefs.intPreference?.delete(name);
      PlayerPrefs.intPreference?.flush();
    }
  }

  public static DeleteAll() {
    let intkeys = Object.keys(PlayerPrefs.directoryInt);
    intkeys.forEach((element) => PlayerPrefs.directoryInt[element] = null);

    let floatkeys = Object.keys(PlayerPrefs.directoryFloat);
    floatkeys.forEach((element) => PlayerPrefs.directoryFloat[element] = null);

    let stringkeys = Object.keys(PlayerPrefs.directoryString);
    stringkeys.forEach((element) => PlayerPrefs.directoryString[element] = null);

    PlayerPrefs.intPreference?.clearSync();
    PlayerPrefs.intPreference?.flushSync();

    PlayerPrefs.floatPreference?.clearSync();
    PlayerPrefs.floatPreference?.flushSync();

    PlayerPrefs.stringPreference?.clearSync();
    PlayerPrefs.stringPreference?.flushSync();
  }

  public static Save() {
    PlayerPrefs.intPreference?.flushSync();
    PlayerPrefs.floatPreference?.flushSync();
    PlayerPrefs.stringPreference?.flushSync();
  }

  public static LocalSave() {
    PlayerPrefs.Save();
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, PlayerPrefs);
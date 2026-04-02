import { POST_MESSAGE_TO_HOST } from '../workers/HostProxy'

export function RegisterGalleryManager() {
  const register: Record<string, Object> = {};
  register["GalleryManager"] = GalleryManager;
  return register;
}

export class GalleryManager {
  public SelectPicture(callback: (state: string, path: string, msg: string) => void, pweight: number, pheight: number,
    maxSelectNumber: number, isPhotoTakingSupported: boolean) {
    const param: Array<ESObject> = [pweight, pheight, maxSelectNumber, isPhotoTakingSupported]
    let msg: ESObject = {
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "GalleryHandler.GallerySelector",
      args: param,
      callback: callback,
      timeoutMs: 100000,
    }
    POST_MESSAGE_TO_HOST(msg);
  }

  public async AddToGallery(albumName: Array<string>, callback: (params: Array<ESObject>) => void) {
    const param: Array<ESObject> = [albumName]
    let msg: ESObject = {
      type: "RUN_ON_UI_THREAD_JS",
      funcName: "GalleryHandler.AddToGallery",
      args: param,
      callback: callback,
      timeoutMs: 100000,
    }
    POST_MESSAGE_TO_HOST(msg);
  }

  static _instance: GalleryManager;

  public static getInstance(): GalleryManager {
    if (GalleryManager._instance == null) {
      GalleryManager._instance = new GalleryManager();
    }
    return GalleryManager._instance
  }
}

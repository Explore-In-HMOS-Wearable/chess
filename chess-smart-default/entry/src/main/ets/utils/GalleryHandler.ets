import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { PickerOptions, ReminderMode, } from '@ohos.file.PhotoPickerComponent';

import { GetFromGlobalThis } from '../common/GlobalThisUtil';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';
import { TuanjieLog } from '../common/TuanjieLog';

enum GalleryOperationResult {
  Success,
  Failure,
  Canceled
}

export class GalleryHandler {
  public static sandBoxPath: string = "/data/storage/el2/base/haps/entry/files/";

  public async GallerySelector(height: number, width: number, maxSelectNumber: number,
    isPhotoTakingSupported: boolean): Promise<Array<ESObject>> {
    try {
      let PhotoSelectOptions: PickerOptions = new PickerOptions();
      PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      PhotoSelectOptions.isPhotoTakingSupported = isPhotoTakingSupported;
      PhotoSelectOptions.maxSelectedReminderMode = ReminderMode.TOAST;
      PhotoSelectOptions.maxSelectNumber = maxSelectNumber;

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const PhotoSelectResult: photoAccessHelper.PhotoSelectResult = await photoPicker.select(PhotoSelectOptions);
      const galleryArray: string[] = PhotoSelectResult.photoUris;

      const result: Array<ESObject> = await Promise.all(
        galleryArray.map((uri) =>
        GalleryHandler.handleImage(uri, height, width))
      );
      return result.flat();
    } catch (error) {
      TuanjieLog.error('PhotoViewPicker failed with err: ' + error.message);
      return [GalleryOperationResult.Failure, null,
        'PhotoViewPicker failed with err: ' + error.message];
    }
  }

  public async AddToGallery(fileUris: Array<string>): Promise<Array<ESObject>> {
    try {
      const context = GetFromGlobalThis('AbilityContext') as common.UIAbilityContext;
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);

      let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = fileUris.map(
        (fileUri): photoAccessHelper.PhotoCreationConfig => {
          const pos = fileUri.lastIndexOf('/');
          const str = fileUri.substring(pos + 1);
          const fileName = str.substring(0, str.lastIndexOf('.'));
          const fileExtension = fileUri.substring(fileUri.lastIndexOf('.') + 1);
          return {
            title: fileName,
            fileNameExtension: fileExtension,
            photoType: photoAccessHelper.PhotoType.IMAGE,
            subtype: photoAccessHelper.PhotoSubtype.DEFAULT,
          };
        });

      const resultPaths = await phAccessHelper.showAssetsCreationDialog(fileUris, photoCreationConfigs);

      if (!resultPaths?.length) {
        TuanjieLog.error('Show AssetsCreationDialog Canceled.');
        return [GalleryOperationResult.Canceled, null,
          "Show AssetsCreationDialog canceled."];
      }
      return await GalleryHandler.handleMultipleImages(fileUris, resultPaths);

    } catch (error) {
      TuanjieLog.error('Show AssetsCreationDialog failed:' + error.message);
      return [GalleryOperationResult.Failure, null,
        "Show AssetsCreationDialog failed:" + error.message];
    }
  }

  static async handleImage(uri: string, height: number, width: number): Promise<Array<ESObject>> {
    let srcFile: fs.File | undefined = undefined;
    let destFile: fs.File | undefined = undefined;
    try {
      srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY);

      let imageSource: image.ImageSource = image.createImageSource(srcFile.fd);
      let decodingOptions: image.DecodingOptions = {
        sampleSize: 1,
        desiredSize: {
          height: height,
          width: width
        }
      };

      const pixelMap = await imageSource.createPixelMap(decodingOptions);
      const imagePackerApi = image.createImagePacker();
      const fileExtension = uri.substring(uri.lastIndexOf('.') + 1);
      const imageFormat = fileExtension === 'png' ? 'image/png' : 'image/jpeg';
      const packOpts: image.PackingOption = { format: imageFormat, quality: 100 };
      const data = await imagePackerApi.packing(pixelMap, packOpts);

      const picPath: string = GalleryHandler.sandBoxPath + `${new Date().getTime().toString()}.jpg`;
      destFile = fs.openSync(picPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(destFile.fd, data);

      const result: Array<ESObject> = [GalleryOperationResult.Success, picPath.toString(), null]
      return result;
    } catch (error) {
      TuanjieLog.error("Failed to handleImage: err: %{public}s", error.message);
      return [GalleryOperationResult.Failure, null,
        "Failed to handleImage: err: " + error.message];
    } finally {
      if (srcFile) {
        fs.closeSync(srcFile);
      }
      if (destFile) {
        fs.closeSync(destFile);
      }
    }
  }

  private static async processAndSaveImage(fileUri: string, destPath: string, fileExtension: string): Promise<void> {
    let srcFile: fs.File | undefined;
    let destFile: fs.File | undefined;

    try {
      srcFile = fs.openSync(fileUri, fs.OpenMode.READ_ONLY);
      const imageSource = image.createImageSource(srcFile.fd);

      const decodingOptions: image.DecodingOptions = {
        sampleSize: 1,
        desiredSize: { height: 0, width: 0 }
      };

      const pixelMap = await imageSource.createPixelMap(decodingOptions);
      const imageFormat = fileExtension === 'png' ? 'image/png' : 'image/jpeg';
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = { format: imageFormat, quality: 100 };

      const data = await imagePackerApi.packing(pixelMap, packOpts);

      destFile = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(destFile.fd, data);
    } finally {
      if (srcFile) {
        fs.closeSync(srcFile);
      }
      if (destFile) {
        fs.closeSync(destFile);
      }
    }
  }

  private static async handleMultipleImages(fileUris: Array<string>,
    resultPaths: Array<string>): Promise<Array<ESObject>> {
    const results: Array<ESObject> = [];

    for (let i = 0; i < fileUris.length; i++) {
      const fileUri = fileUris[i];
      const destPath = resultPaths[i];
      const pos = fileUri.lastIndexOf('/');
      const str = fileUri.substring(pos + 1);
      const fileName = str.substring(0, str.lastIndexOf('.'));
      const fileExtension = fileUri.substring(fileUri.lastIndexOf('.') + 1);

      try {
        await GalleryHandler.processAndSaveImage(fileUri, destPath, fileExtension);
        results.push([GalleryOperationResult.Success, destPath.toString(), null]);
      } catch (error) {
        TuanjieLog.error(`Image processing failed for ${fileUri}:` + error.message);
        results.push([GalleryOperationResult.Failure, null,
          `Image processing failed for ${fileUri}:` + error.message]);
        throw error as Error;
      }
    }
    return results.flat();
  }

  static Instance: GalleryHandler;

  public static getInstance(): GalleryHandler {
    if (GalleryHandler.Instance == null) {
      GalleryHandler.Instance = new GalleryHandler();
    }
    return GalleryHandler.Instance;
  }
}

!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, GalleryHandler.getInstance());
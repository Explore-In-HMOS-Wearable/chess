import { Tuanjie } from '../utils/TuanjieNative';
import { REGISTER_BUILTIN_MODULE, MSG_RECEIVER } from '../workers/MessageProcessor';

export enum EVideoStatus {
    None = -1,
    Play,
    Pause,
    Stop
}

export class VideoInfo {
    public url: string = ""
    public bgColor: number = 0
    public controlMode: number = 0
    public scalingMode: number = 0
    public isPlaying: boolean = false

    Init(url: string, bgColor: number, controlMode: number, scalingMode: number) {
        this.url = url
        this.bgColor = bgColor
        this.controlMode = controlMode
        this.scalingMode = scalingMode
        this.isPlaying = true
    }
}

export class VideoPlayerProxy {
    static _instance:VideoPlayerProxy;

    static getInstance() : VideoPlayerProxy {
        if(!VideoPlayerProxy._instance)
        {
            VideoPlayerProxy._instance = new VideoPlayerProxy();
        }

        return VideoPlayerProxy._instance;
    }

    ShowVideoPlayer(path: string, backgroundColor: number, controlMode: number,  scalingMode: number) {
        let videoInfo = new VideoInfo()
        videoInfo.Init(path, backgroundColor, controlMode, scalingMode)
        AppStorage.setOrCreate('VideoInfo', videoInfo);
        return true;
    }

    OnVideoStart() {
        Tuanjie.nativeOnPause();
    }

    OnVideoStop() {
        Tuanjie.nativeOnResume();
    }

    IsPlaying()
    {
        let info = AppStorage.get('VideoInfo') as VideoInfo;
        return info && info.isPlaying;
    }

    OnResume()
    {
        AppStorage.setOrCreate('VideoStatus', EVideoStatus.Play);
    }

    OnPause()
    {
        AppStorage.setOrCreate('VideoStatus', EVideoStatus.Pause);
    }
}
!!REGISTER_BUILTIN_MODULE && REGISTER_BUILTIN_MODULE(MSG_RECEIVER.HOST_UI, VideoPlayerProxy.getInstance());

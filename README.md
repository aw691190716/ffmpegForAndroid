本项目是将FFmpeg移植到Android平台，NDK需要设定或export为各自的android ndk路径，当前支持ffmpeg 2.3版本,后续继续更新支持ffmpeg其他版本
build_x264.sh 用于编译x264,该项目没有集成
RUN：
  ./android_build.sh                   #没有ffmpeg代码的话，则获取最新的ffmpeg代码，有的ffmpeg代码，不更新到ffmpeg最新代码
  ./android_build.sh  update           #没有ffmpeg代码的话，则获取最新的ffmpeg代码，有的ffmpeg代码，便更新到ffmpeg最新代码



## License

    Copyright 2014 aw691190716@gmail.com

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

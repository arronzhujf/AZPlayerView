# AZPlayerView

一款iOS视频播放组件(UIView中嵌入AVPlayer),支持本地url和网络url,网络资源目前只支持mp4。

Usage:

就像初始化UIView一样初始化AZPlayerView。

本地资源在初始化后直接设置URL;
网络资源需要先设置cacheUrl再设置url(顺序不能乱)。

AZPlayerView支持动态设置url，更方便嵌入UITableViewCell。

AZPlayerView接口提供了各种操作：
播放，暂停，任意指定时间点播放，获取任意时间点的缩略图

提供了获取视频各种属性的接口：
current, duration,progress,rate,volume,gravity等

同时AZPlayerView的delegate也十分简洁。


开始使用吧！

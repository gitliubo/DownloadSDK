Pod::Spec.new do |s|

  s.name         = "DownloadSDK"
  s.version      = "1.0.0"
  s.summary      = "采用OC语言，使用NSURLSeesion实现网络数据下载，具体调用请查看库文件。"

  s.homepage     = "https://github.com/gitliubo/DownloadSDK"

  s.license      = "MIT"

  s.author             = { "Yesky" => "nevergiveupliubo@163.com" }
  s.platform     = :ios
  s.ios.deployment_target = "7.0"
  s.source       = { :git => "https://github.com/gitliubo/DownloadSDK.git",:branch => "master", :tag => "1.0.0" }
  s.requires_arc = true
  s.source_files  = "DownloadSDK/**/*.{h,m}"

  s.framework  = "UIKit","Foundation"

end

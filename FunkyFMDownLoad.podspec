
Pod::Spec.new do |s|
  s.name             = 'FunkyFMDownLoad'
  s.version          = '0.1.0'
  s.summary          = 'FunkyFMDownLoad'

  s.description      = <<-DESC
FunkyFMDownLoad 是FunkyFM 的下载资源组件，可以根据传人的url，下载url对应的资源文件
                       DESC

  s.homepage         = 'https://github.com/funkyHS/FunkyFMDownLoad'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'funkyHS' => 'hs1024942667@163.com' }
  s.source           = { :git => 'https://github.com/funkyHS/FunkyFMDownLoad.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'FunkyFMDownLoad/Classes/**/*'
  
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

    s.dependency 'FunkyFMBase/Tool'
end

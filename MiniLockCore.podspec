Pod::Spec.new do |s|
  s.name             = 'MiniLockCore'
  s.version          = '0.9.1'
  s.summary          = 'Swift implementation of miniLock\'s core functionalities.'

  s.description      = <<-DESC
The library is a swift implementation of miniLock's core functionalities.
It was originally written for the SwiftLock app, but can be used as a plugin
system in any other app wanting to use the modern and future-proof encryption
scheme of miniLock.
                       DESC

  s.homepage         = 'https://github.com/mohakshah/MiniLockCore'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mohak Shah' => 'mohak@mohakshah.in' }
  s.source           = { :git => 'https://github.com/mohakshah/MiniLockCore.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MiniLockCore/Classes/**/*'

  s.dependency 'libsodium', '~> 1.0'
  s.dependency 'libb2s', '~> 1.0'
  s.dependency 'libbase58', '~> 0.1'
  s.dependency 'ObjectMapper', '~> 2.2'
end

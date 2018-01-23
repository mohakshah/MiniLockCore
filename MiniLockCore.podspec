Pod::Spec.new do |s|
  s.name             = 'MiniLockCore'
  s.version          = '1.0.0'
  s.summary          = 'Swift implementation of miniLock\'s core functionalities.'

  s.description      = <<-DESC
The library is an implementation of miniLock's core functionalities in Swift.
It provides a modern Swift API to miniLock tasks such as user key management,
file encryption, decryption, etc. There are also methods which allow encrypting
data from memory and decrypting data to memory to completely avoid writing
plain text to the disk. It was originally written for the SwiftLock app on iOS,
but it can be used as a plugin component in any other app wanting to use
miniLock's modern and future-proof encryption scheme.
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
  s.dependency 'ObjectMapper', '~> 3.0'
end

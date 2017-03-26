#
# Be sure to run `pod lib lint MiniLockCore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MiniLockCore'
  s.version          = '0.1.0'
  s.summary          = 'A library with swift implementation of miniLock\'s core functionalities.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
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
end

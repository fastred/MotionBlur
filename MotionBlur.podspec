Pod::Spec.new do |s|
  s.name             = "MotionBlur"
  s.version          = "0.2.0"
  s.summary          = "MotionBlur allows you to add motion blur effect to iOS animations."
  s.homepage         = "https://github.com/fastred/MotionBlur"
  s.license          = 'MIT'
  s.author           = { "Arkadiusz Holko" => "fastred@fastred.org" }
  s.social_media_url = "https://twitter.com/arekholko"
  s.source           = { :git => "https://github.com/fastred/MotionBlur.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.source_files = 'Classes'
  s.public_header_files = 'Classes/*.h'
end

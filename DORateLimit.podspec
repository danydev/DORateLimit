Pod::Spec.new do |s|
  s.name = "DORateLimit"
  s.version = "0.1.2"
  s.summary = "Rate limit your functions with throttling and debouncing"
  s.homepage = "https://github.com/danydev/DORateLimit"
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.source = { :git => "https://github.com/danydev/DORateLimit.git", :tag => s.version.to_s }
  s.author = { "Daniele Orrù" => "daniele.orru.dev@gmail.com" }

  s.platform = :ios, '8.0'
  s.osx.deployment_target = '10.9'
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'

  s.source_files = 'DORateLimit/*.swift'
end

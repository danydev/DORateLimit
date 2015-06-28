Pod::Spec.new do |s|
  s.name             = "DORateLimit"
  s.version          = "0.1.0"
  s.summary          = "Rate limit your functions with throttling and debouncing"
  s.homepage         = "https://github.com/danydev/DORateLimit"
  s.license          = 'MIT'
  s.author           = { "Daniele Orrù" => "daniele.orru.dev@gmail.com" }
  s.source           = { :git => "https://github.com/danydev/DORateLimit.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'DORateLimit/*.swift'
end

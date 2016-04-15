Pod::Spec.new do |s|
  s.name         = "TVPhotoViewer"
  s.version      = "0.0.1"
  s.summary      = "An Interactive photo viewer for iOS written in Swift."
  s.homepage     = "http://EXAMPLE/TVPhotoViewer"
  s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "Tai Vuong" => "vhuutai@gmail.com" }
  s.authors            = { "Tai Vuong" => "vhuutai@gmail.com" }
  s.social_media_url   = "http://twitter.com/Tai Vuong"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/untouchable741/TVPhotoViewer.git", :tag => "0.0.1" }

  s.source_files  = "Source/*.{h,m}"
  s.dependency "Alamofire", "~> 3.3.1"
end

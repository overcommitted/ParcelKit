Pod::Spec.new do |s|
  s.name         = "ParcelKit"
  s.version      = "2.1.2"
  s.summary      = "ParcelKit integrates Core Data with Dropbox using the Dropbox Datastore API."
  s.homepage     = "http://github.com/overcommitted/ParcelKit"
  s.license      = 'MIT'
  s.author       = { "Jonathan Younger" => "jonathan@daikini.com", "Andy Geers" => "andy.geers@googlemail.com" }
  s.source       = { :git => "https://github.com/overcommitted/ParcelKit.git", :tag => s.version.to_s }
  s.platform     = :ios, '6.1'
  s.source_files = 'ParcelKit/*.{h,m}'
  s.frameworks   = 'CoreData', 'Dropbox'
  s.requires_arc = true
  s.dependency 'Dropbox-Sync-API-SDK', '~> 3.1.2'
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '"${PODS_ROOT}/Dropbox-Sync-API-SDK/dropbox-ios-sync-sdk-3.1.2"' }
end

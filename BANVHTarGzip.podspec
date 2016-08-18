Pod::Spec.new do |s|
  s.name             = "BANVHTarGzip"
  s.version          = "1.0.2"
  s.summary          = "A library to handle .tgz and .tar.gz files on iOS, forked from https://github.com/nvh/NVHTarGzip"
  s.description      = <<-DESC
                      Unpack and pack tarred and gzipped files with ease. Features:
                       * Low memory footprint
                       * Asynchronous and synchronous and API's
                       DESC
  s.homepage         = "https://github.com/nvh/NVHTarGzip"
  s.license          = 'MIT'
  s.author           = { "Niels van Hoorn" => "nvh@nvh.io" }
  s.source           = { :git => "https://github.com/IAG-Digital/BANVHTarGzip.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nvh'

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Classes/*'

  s.library = 'z'

end

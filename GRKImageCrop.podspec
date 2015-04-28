Pod::Spec.new do |s|
  s.name         = "GRKImageCrop"
  s.version      = "1.0"
  s.summary      = "A UIImage category which provides \"visible\" pixel cropping capabilities."
  s.description  = <<-DESC
A UIImage category which provides "visible" pixel cropping capabilities.
A given image can be rectangularly cropped based on calculated insets to "visible" pixels.
Visible pixels are those whose alpha component are greater than or equal to a given alpha
threshold.
    DESC
  s.homepage     = "https://github.com/levigroker/GRKImageCrop"
  s.license      = 'Creative Commons Attribution 3.0 Unported License'
  s.author       = { "Levi Brown" => "levigroker@gmail.com" }
  s.social_media_url = 'https://twitter.com/levigroker'
  s.source       = { :git => "https://github.com/levigroker/GRKImageCrop.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.3'
  s.ios.deployment_target = '7.0'
  s.source_files = 'GRKImageCrop/**/*.{h,m}'
  s.requires_arc = true
end

Pod::Spec.new do |spec|
    spec.name         = "AppBoxSDK"
    spec.version      = "1.0.0"
    spec.summary      = "iOS framework to get the automatic update for development/ad-hoc/enterprises apps uploaded via AppBox."

    spec.description  = <<-DESC
    iOS framework to get the automatic update for development/ad-hoc/enterprises apps uploaded via AppBox.
    https://getappbox.com/
    DESC

    spec.homepage     = "https://github.com/getappbox/AppBox-iOS-SDK"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    spec.author       = { "Vineet Choudhary" => "vineetchoudhary@live.in" }

    spec.ios.deployment_target = "10.0"
    spec.swift_version = "4.2"

    spec.source        = { :git => "https://github.com/getappbox/AppBox-iOS-SDK.git", :tag => "#{spec.version}" }
    spec.source_files  = "AppBox/AppBox/**/*.{h,m,swift}"
end

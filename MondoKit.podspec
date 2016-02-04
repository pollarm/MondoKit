Pod::Spec.new do |spec|
spec.name = "MondoKit"
spec.version = "0.1.6"
spec.summary = "MondoKit is a Swift framework wrapping the Mondo API at https://getmondo.co.uk/docs/"
spec.homepage = "https://github.com/pollarm/MondoKit"
spec.license = { type: 'MIT', file: 'LICENSE' }
spec.authors = { "Mike Pollard" => 'mikeypollard@me.com' }
spec.social_media_url = "http://twitter.com/mikeypollard1"

spec.platform = :ios, "9.0"
spec.requires_arc = true
spec.source = { git: "https://github.com/pollarm/MondoKit.git", tag: spec.version }
spec.source_files = "MondoKit/**/*.{h,swift}"

spec.dependency "SwiftyJSON", "~> 2.3"
spec.dependency "SwiftyJSONDecodable", "~> 0.1"
spec.dependency "Alamofire", "~> 3.0"
spec.dependency "KeychainAccess"

end

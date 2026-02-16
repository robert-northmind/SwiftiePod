Pod::Spec.new do |s|
    s.name         = 'SwiftiePod'
    s.version      = '1.1.1'
    s.summary      = 'A Dependency Injection library for Swift'
    s.description  = 'SwiftiePod is a lightweight and easy-to-use Dependency Injection (DI) library for Swift. It is designed to be straightforward, efficient, and most importantly safe!'
    s.homepage     = 'https://github.com/robert-northmind/SwiftiePod'
    s.license      = { :type => 'MIT', :file => 'LICENSE' }
    s.author       = { 'Robert Magnusson' => 'robert@northmind.io' }
    s.platforms    = { :ios => '11.0', :osx => '10.13', :tvos => '11.0', :watchos => '4.0' }
    s.source       = { :git => 'https://github.com/robert-northmind/SwiftiePod.git', :tag => s.version.to_s }
    s.source_files = 'Sources/SwiftiePod/**/*.{swift}'
    s.swift_version = '5.8'
end
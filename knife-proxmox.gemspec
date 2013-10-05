# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-proxmox/version"

Gem::Specification.new do |s|
  s.name        = "knife-proxmox"
  s.version     = Knife::Proxmox::VERSION
  s.has_rdoc = false
  s.authors     = ["Jorge Moratilla", "Sergio Galvan"]
  s.email       = ["jorge@moratilla.com","sergalma@gmail.com"]
  s.homepage = "https://bitbucket.org/jmoratilla/knife-proxmox"
  s.summary = "ProxmoxVE Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.md", "LICENSE","TODO","CHANGELOG" ]

  s.files         = Dir['lib/**/*.rb'] + Dir['./*']
  s.add_dependency "chef", ">= 0.10.10"
  s.add_dependency "rest-client", ">=1.6.7"
  s.add_dependency "json", ">=1.5.4"
  s.require_paths = ["lib"]

end

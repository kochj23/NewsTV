#!/usr/bin/env ruby
# Configure App Groups and entitlements for NewsTV
# Created by Jordan Koch

require 'xcodeproj'

project_path = '/Volumes/Data/xcode/NewsTV/NewsTV.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Configuring App Groups for NewsTV..."

# Configure main app target
main_target = project.targets.find { |t| t.name == 'NewsTV' }
if main_target
  main_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'NewsTV/NewsTV.entitlements'
  end
  puts "Main app entitlements configured"
end

# Configure Top Shelf target
topshelf_target = project.targets.find { |t| t.name == 'NewsTVTopShelf' }
if topshelf_target
  topshelf_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'NewsTVTopShelf/NewsTVTopShelf.entitlements'
  end
  puts "Top Shelf entitlements configured"
end

# Add TopShelfDataManager.swift to the project
services_group = nil
project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.name == 'Services'
    services_group = child
    break
  end
end

if services_group && main_target
  existing = services_group.files.find { |f| f.path&.include?('TopShelfDataManager.swift') }
  unless existing
    file_ref = services_group.new_file('TopShelfDataManager.swift')
    main_target.source_build_phase.add_file_reference(file_ref)
    puts "TopShelfDataManager.swift added to project"
  end
end

# Add entitlements file references
newstv_group = project.main_group.children.find { |c| c.name == 'NewsTV' }
if newstv_group
  existing = newstv_group.files.find { |f| f.path&.include?('entitlements') }
  unless existing
    newstv_group.new_file('NewsTV/NewsTV.entitlements')
    puts "Main app entitlements file added"
  end
end

topshelf_group = project.main_group.children.find { |c| c.name == 'NewsTVTopShelf' }
if topshelf_group
  existing = topshelf_group.files.find { |f| f.path&.include?('entitlements') }
  unless existing
    topshelf_group.new_file('NewsTVTopShelf/NewsTVTopShelf.entitlements')
    puts "Top Shelf entitlements file added"
  end
end

project.save
puts "App Groups configuration completed for NewsTV!"

#!/usr/bin/env ruby
# frozen_string_literal: true

# Adds the `PrayerWidget` WidgetKit extension target to Runner.xcodeproj.
#
# The project uses classic (non-filesystem-synchronised) groups, so a new
# target is a few hundred lines of pbxproj. Rather than hand-editing them, this
# script does it through the `xcodeproj` gem CocoaPods already installs:
#
#     ruby ios/scripts/add_prayer_widget_target.rb
#
# It is idempotent — run it again after a clean checkout or if the target was
# removed, and it is a no-op when the target already exists. What it wires:
#
#   * an app-extension target `PrayerWidget` (bundle id com.zikr.mapp.PrayerWidget,
#     iOS 15.0, Swift 5) built from ios/PrayerWidget/*.swift + Assets.xcassets;
#   * Info.plist, entitlements (App Group group.com.zikr.mapp), team + automatic
#     signing, and Flutter/Generated.xcconfig as the base configuration so the
#     extension carries the app's FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER;
#   * WidgetKit + SwiftUI in the Frameworks phase;
#   * a Runner → PrayerWidget dependency and an "Embed Foundation Extensions"
#     copy phase on Runner, so the extension ships inside the app bundle.
#
# Not done here (one-time, in the Apple developer portal or via Xcode's
# automatic signing): enabling the App Groups capability for BOTH App IDs.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
TARGET_NAME = 'PrayerWidget'
BUNDLE_ID = 'com.zikr.mapp.PrayerWidget'
DEPLOYMENT_TARGET = '15.0'
TEAM = 'C958H28PV6'
SOURCES = %w[PrayerWidgetBundle.swift PrayerWidget.swift PrayerWidgetView.swift PrayerSnapshot.swift].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)

if project.targets.any? { |t| t.name == TARGET_NAME }
  puts "#{TARGET_NAME} target already present — nothing to do."
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'
generated_xcconfig = project.files.find { |f| f.path == 'Flutter/Generated.xcconfig' } or abort 'Flutter/Generated.xcconfig reference not found'

# ── Target ──────────────────────────────────────────────────────────────────
target = project.new_target(:app_extension, TARGET_NAME, :ios, DEPLOYMENT_TARGET)

# ── Files ───────────────────────────────────────────────────────────────────
group = project.main_group.new_group(TARGET_NAME, TARGET_NAME)
source_refs = SOURCES.map { |name| group.new_file(name) }
assets_ref = group.new_file('Assets.xcassets')
group.new_file('Info.plist')
group.new_file("#{TARGET_NAME}.entitlements")

target.add_file_references(source_refs)
target.resources_build_phase.add_file_reference(assets_ref)

%w[WidgetKit SwiftUI].each do |framework|
  ref = project.frameworks_group.new_file("System/Library/Frameworks/#{framework}.framework", :sdk_root)
  target.frameworks_build_phase.add_file_reference(ref)
end

# ── Build settings ──────────────────────────────────────────────────────────
target.build_configurations.each do |config|
  config.base_configuration_reference = generated_xcconfig
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  s['INFOPLIST_FILE'] = "#{TARGET_NAME}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{TARGET_NAME}/#{TARGET_NAME}.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = TEAM
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['SWIFT_VERSION'] = '5.0'
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  s['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  s['VERSIONING_SYSTEM'] = 'apple-generic'
  s['CLANG_ENABLE_MODULES'] = 'YES'
  s['SWIFT_OPTIMIZATION_LEVEL'] = config.name == 'Debug' ? '-Onone' : '-O'
  s['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) DEBUG' if config.name == 'Debug'
  s.delete('CODE_SIGN_IDENTITY')
end

# ── Embed in Runner ─────────────────────────────────────────────────────────
runner.add_dependency(target)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:plug_ins]
embed.dst_path = ''
build_file = embed.add_file_reference(target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Keep the embed step after the app's own Sources/Frameworks/Resources phases
# and before Flutter's "Thin Binary" script, which expects the bundle complete.
phases = runner.build_phases
thin = phases.find { |ph| ph.respond_to?(:name) && ph.name == 'Thin Binary' }
if thin
  phases.delete(embed)
  phases.insert(phases.index(thin), embed)
end

project.root_object.attributes['TargetAttributes'] ||= {}
project.root_object.attributes['TargetAttributes'][target.uuid] = { 'CreatedOnToolsVersion' => '15.0' }

project.save
puts "Added #{TARGET_NAME} target (#{BUNDLE_ID}) and embedded it in Runner."

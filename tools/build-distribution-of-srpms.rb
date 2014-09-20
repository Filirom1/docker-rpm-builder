#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'colorize'

script_dir = File.dirname(__FILE__)
srpm_dir = ARGV[0]
build_dir = ARGV[1]

abort "Usage: build.rb <srpms_dir> <build_dir>" unless srpm_dir and build_dir

# load the list of previously built rpms
success_file = "#{build_dir}/success.json"

success=nil
begin
  success = JSON.parse(File.read(success_file))
rescue
  success = []
end

# list all the srpms
srpm = Dir["#{srpm_dir}/*"]

# loop until no more compilation is needed
built=-1
until built==0 do
  built=0

  # skip srpm already built
  srpm.select! do |filename|
    !success.include? filename
  end

  #for each file not in the success list
  srpm.each do |filename|
    puts "Build #{filename}".green

    # clean the build dir
    Dir["#{build_dir}/*.src.rpm"].each do |oldFilename|
      File.delete(oldFilename)
    end

    # build the srpm
    FileUtils.cp(filename, build_dir);
    system "#{script_dir}/../docker-build-binary-rpm-from-dir.sh docker-rpm-builder #{build_dir}"
    if $? == 0
      # on success append the filename in the success_file
      success << filename
      File.open(success_file,"w") do |f|
          f.write(JSON.pretty_generate(success))
      end
      built += 1
    else
      puts "Failure for #{filename}".red
    end

  end
end

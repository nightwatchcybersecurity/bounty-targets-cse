#!/usr/bin/env ruby

INPUT_PATH = './bounty-targets-data/data/'
OUTPUT_PATH = './cse-data/'

require 'CSV'
require 'json'
require 'optparse'

# This function was copied from:
# https://github.com/arkadiyt/bounty-targets/blob/master/lib/bounty-targets/cli.rb
# Copyright (c) 2017 Arkadiy Tetelman. Licensed under the MIT License.
def parse_all_uris(uris)
  domains = []

  uris.each do |uri|
    uri.split(',').each do |target|
      next unless target.include?('.')

      uri = parse_uri(target)
      uri = parse_uri("http://#{target}") if uri&.host.nil?

      next unless valid_uri?(uri)

      domains << "#{uri.host.downcase}/*"
    end
  end

  domains.uniq
end

# This function was copied from:
# https://github.com/arkadiyt/bounty-targets/blob/master/lib/bounty-targets/cli.rb
# Copyright (c) 2017 Arkadiy Tetelman. Licensed under the MIT License.
def parse_uri(str)
  URI(str)
rescue URI::InvalidURIError
  nil
end

# This function was copied from:
# https://github.com/arkadiyt/bounty-targets/blob/master/lib/bounty-targets/cli.rb
# Copyright (c) 2017 Arkadiy Tetelman. Licensed under the MIT License.
def valid_uri?(uri)
  return false unless uri&.host

  # iOS/Android/FireOS mobile app links
  return false if %w[itunes.apple.com play.google.com www.amazon.com].include?(uri.host)

  # Executable files
  return false if uri.host.end_with?('.exe')

  # Links to source code (except exactly github.com/gitlab.com, which are scopes on hackerone)
  return false if %w[github.com gitlab.com].include?(uri.host) && !['', '/'].include?(uri.path)

  # Additions for CSE #
  # CSE doesn't like wildcards in the middle of the hostname
  return false if uri.host.index('*', 1)

  true
end

# ---------- Main code starts here ---------------
params = {}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: targets2cse.rb [options]"

  opts.on("-tag", "--cse_tag CSE_TAG",
      "CSE tag to use for file generation") do |tag|
    params[:tag] = tag
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

# Check parameters
opt_parser.parse!
if !params[:tag]
  puts "-tag parameter is required to run this script"
  exit
else
  print "Using tag: #{params[:tag]}\n\n"
end

# Loading json
@bugcrowd_data  = JSON.parse(File.read("#{INPUT_PATH}/bugcrowd_data.json"))
@federacy_data  = JSON.parse(File.read("#{INPUT_PATH}/federacy_data.json"))
@hackerone_data = JSON.parse(File.read("#{INPUT_PATH}/hackerone_data.json"))

print "Programs in BugCrowd : #{@bugcrowd_data.count}\n"
print "Programs in Federacy : #{@federacy_data.count}\n"
print "Programs in HackerOne: #{@hackerone_data.count}\n\n"

# Extract URIs
@bugcrowd_uris = @bugcrowd_data.flat_map do |program|
    program['targets']['in_scope']
  end.select do |scope|
    ['', 'api', 'other', 'website'].include?(scope['type'])
  end.map do |scope|
    scope['target']
  end

@federacy_uris = @federacy_data.flat_map do |program|
    program['targets']['in_scope']
  end.select do |scope|
    scope['type'] == 'website'
  end.map do |scope|
    scope['target']
  end

@hackerone_uris = @hackerone_data.flat_map do |program|
    program['targets']['in_scope']
  end.select do |scope|
    scope['asset_type'] == 'URL'
  end.map do |scope|
    scope['asset_identifier']
  end

@yahoo_uris = @hackerone_data.find do |program|
    program['handle'] == 'oath'
end['targets']['in_scope'].flat_map do |scope|
    URI.extract(scope['instruction'] + "\n" + scope['instruction'].scan(/\(([^)]*)\)/).flatten.join(' '))
end

@hackerone_uris.concat @yahoo_uris

# Output uris
@bugcrowd_domains = parse_all_uris(@bugcrowd_uris).uniq.sort
@federacy_domains = parse_all_uris(@federacy_uris).uniq.sort
@hackerone_domains = parse_all_uris(@hackerone_uris).uniq.sort

print "Domains in BugCrowd : #{@bugcrowd_domains.count}\n"
print "Domains in Federacy : #{@federacy_domains.count}\n"
print "Domains in HackerOne: #{@hackerone_domains.count}\n\n"

# Write output files
CSV.open("#{OUTPUT_PATH}/bugcrowd.tsv", "wb", {:col_sep => "\t"}) do |csv|
  csv << ["URL", "Label", "Label"]
  @bugcrowd_domains.each{|domain| csv << [domain, "_cse_#{params[:tag]}", 'BugCrowd']}
end

CSV.open("#{OUTPUT_PATH}/federacy.tsv", "wb", {:col_sep => "\t"}) do |csv|
  csv << ["URL", "Label", "Label"]
  @federacy_domains.each{|domain| csv << [domain, "_cse_#{params[:tag]}", 'Federacy']}
end

CSV.open("#{OUTPUT_PATH}/hackerone.tsv", "wb", {:col_sep => "\t"}) do |csv|
  csv << ["URL", "Label", "Label"]
  @hackerone_domains.each{|domain| csv << [domain, "_cse_#{params[:tag]}", 'HackerOne']}
end

# Write file to exclude sites with a lot of user content
@user_content_paths = [
  '*.en.9apps.com/*',
  'bitbucket.org/*',
  'community.ubnt.com/*',
  'community.withairbnb.com/*',
  'finance.yahoo.com/*',
  'gist.github.com/*',
  'github.com/*',
  'gitlab.com/*',
  '*.hubspot.net/hubfs/*',
  'sports.yahoo.com/*',
  'twitter.com/*',
  'wordpress.org/plugins/*',
  'wordpress.org/support/*',
  'www.indeed.com/*',
  'www.quora.com/*',
  'www.urbandictionary.com/define.php*',
  '*.zendesk.com/hc/*',
]
CSV.open("#{OUTPUT_PATH}/user_content.tsv", "wb", {:col_sep => "\t"}) do |csv|
  csv << ["URL", "Label"]
  @user_content_paths.each{|path| csv << [path, "_cse_exclude_#{params[:tag]}"]}
end

exit

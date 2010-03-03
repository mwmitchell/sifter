require 'rubygems'
require 'marc'
require 'open-uri'
require 'rsolr'
require 'rsolr-direct'
require 'blacklight_sample'

RSolr.load_java_libs

marc_file = "http://github.com/projectblacklight/blacklight-data/raw/master/test_data.utf8.mrc"

mapper = BlacklightSample.new(MARC::Reader.new open(marc_file))

RSolr.connect :direct, :solr_home => '../../blacklight/jetty/solr' do |solr|
  solr.connection.direct # trigger solr startup
  s = Time.now
  mapper.process { |solr_doc|
    solr.add solr_doc
  }
  solr.commit
  puts "\n\n************************* #{Time.now - s}\n\n"
end
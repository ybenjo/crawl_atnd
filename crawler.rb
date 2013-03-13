require 'yaml'
require 'mongo'
require "#{File.expand_path(File.dirname(__FILE__))}/atnd.rb"

if __FILE__ == $0
  start_id = (ARGV[0] || 1).to_i
  end_id = (ARGV[1] || 1).to_i

  conf = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/config.yaml")
  m = Mongo::Connection.new(conf['address']).db(conf['db'])[conf['collection']]
  wait = conf['wait']
  ua = conf['UA']

  start_id.upto end_id do |id|
    data = get_atnd(id, ua)
    m.insert({_id: id, data: data})
    sleep(wait)
  end
end

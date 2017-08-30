require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'dotenv'
  gem 'elasticsearch-model', github: 'elastic/elasticsearch-rails', branch: '5.x'
  gem 'multi_json'
  # gem 'pg'
  gem 'mysql2'
  gem 'pry'
  gem 'oj'
  gem 'sequel'
end

require 'json'

def format_date(hash)
  hash.each do |key, value|
    if value.is_a?(Time)
      hash.merge!({key => value.strftime("%FT%T")})
    end
  end
end

Dotenv.load

DB = Sequel.connect(adapter: :mysql2, user: ENV['DB_USER'],
                    password: ENV['DB_PASSWORD'], host: ENV['DB_HOST'], port: ENV['DB_PORT'],
                    database: ENV['DB_NAME'], max_connections: 10, logger: Logger.new('log/db.log'))
ds = DB.from(ENV['TABLE_NAME'])
data_set = ds.extension(:pagination)

if ENV['ELASTIC_USERNAME'].empty?
  credentials = ''
else
  credentials = "#{ENV['ELASTIC_USERNAME']}:#{URI.escape(ENV['ELASTIC_PASSWORD'], '@')}@"
end

Elasticsearch::Model.client = Elasticsearch::Client.new url: "http://#{credentials}#{ENV['ELASTICSEARCH_HOST']}"

data_set.each_page(ENV['PAGE_SIZE'].to_i) do |row|
  post_result = Elasticsearch::Model.client.bulk(
      index: ENV['INDEX_NAME'],
      type: ENV['INDEX_TYPE'],
      body: row.map do |body|
      { index: { _id: body[:id], data: format_date(body) } }
    end
    )
  if post_result['errors']
    puts "There are errors while indexing the #{ENV['TABLE_NAME']}"
  end
end
require 'sinatra'
require 'sqlite3'
require 'erb'
require 'ostruct'

set :public_folder, __dir__
set :views, __dir__

def query(sql_statement, *args)
  result = SQLite3::Database.open('tunes.db', { results_as_hash: true, readonly: true }) do |db|
    query_result = db.execute(sql_statement, *args)
                     &.map{ |u| OpenStruct.new(u) }

    query_result || []
  end 
  return result
end

def write(sql_statement, *args)
  SQLite3::Database.open('tunes.db') do |db|
    db.execute(sql_statement, *args)
  end 
end

def rebuild
  @username = query(
    <<-SQL
      select * from users
    SQL
  ).first[:username]

  @tracks = query <<-SQL
    select * 
    from tracks 
    order by created_at desc
  SQL

  html = erb :tunes

  File.write('../build/index.html', html)
end

def with(hash)
  hash
end
def reload(options = {})
  case options
  in message:
    redirect to "/?message=#{message}"
  else
    redirect to '/'
  end
end

get '/' do
  @user = query(
    <<-SQL
      select * from users
    SQL
  ).first
  @tracks = query <<-SQL
    select * 
    from tracks 
    order by created_at desc
  SQL

  case params
  in message:
    @message = message
  else
  end

  erb :cms
end

post '/user/edit' do
  update = <<-SQL
    update users 
    set username = ?,
         api_key = ?
    where users.id = 1
  SQL
  write update, [params[:username], params[:api_key]]
  rebuild
  reload with message: "Credentials Saved."
end

post '/track/new' do
  track = <<-SQL
    insert into tracks
    values (?,?,?,?,?,?)
  SQL
  write track, [
    nil,
    params[:yt_id],
    params[:title],
    params[:artist],
    nil,
    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  ]
  rebuild
  reload
end

post '/track/edit' do
  edit = <<-SQL
    update tracks
    set title = ?,
       artist = ?
    where id = ? 
  SQL
  write edit, [
    params[:title],
    params[:artist],
    params[:id]
  ]
  rebuild
  reload
end

post '/track/delete' do
  delete = <<-SQL
    delete from tracks
    where id = ?
  SQL
  write delete, [ params[:id] ]
  rebuild
  reload
end

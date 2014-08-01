require 'rake'
require 'twitter'
require 'json'

client = Twitter::REST::Client.new do |config|
  config.consumer_key = "KIXDfc6CFZZQfFH4QZ6pA"
  config.consumer_secret = "VmXgzLHdtjNpRKGFiCh4MBcn0zzJQF4Ov40L8D8"
  config.access_token = "15574548-SpXzyUaLZznFEJGJZoVZEIxgvyNftmYDnQrZL4I14"
  config.access_token_secret = "UQtthHKiz77VGcLhcglmgwrcWp9cHn9aEUkUIGVXc"
end

namespace :data do
  desc "Seed data from Twitter"
  task :seed do
    friend_ids = client.friend_ids('riblah').to_a
    friends = client.users(friend_ids)
    data = []

    friends.each do |friend|
      puts "What gender is #{friend.name}?"
      gender = STDIN.gets.chomp
      puts "gender is #{gender}"

      friend_data = {
        :name =>      friend.name,
        :username =>  friend.screen_name,
        :image =>     friend.profile_image_url,
        :gender =>    gender
      }
      data << friend_data
    end

    File.open("public/data/riblah.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  desc "Seed data from Twitter"
  task :redo_seed do
    friend_ids = client.friend_ids('riblah').to_a
    friends = client.users(friend_ids)
    old_data = JSON.parse(File.read("public/data/riblah4.json"))
    data = []

    friends.each do |friend|
      existing_friend = old_data.detect {|f| f["username"] == friend.screen_name }

      if (existing_friend.nil?)
        puts "What gender is #{friend.name}?"
        gender = STDIN.gets.chomp
        puts "gender is #{gender}"
      else
        gender = existing_friend["gender"]
      end

      friend_data = {
        :id =>        friend.id,
        :name =>      friend.name,
        :username =>  friend.screen_name,
        :image =>     friend.profile_image_url,
        :tweets =>    friend.statuses_count,
        :gender =>    gender,
        :protected => friend.protected
      }
      data << friend_data
    end

    data.each do |friend|
      if friend_ids.include?(friend[:id])
        if friend[:protected] == true
          data.delete friend
        end
      end
    end

    File.open("public/data/riblah5.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  desc "Get friends of friends"
  task :friends_of_friends do
    friends = JSON.parse(File.read("public/data/riblah5.json"))
    done = JSON.parse(File.read("public/data/riblah_ff5.json"))
    data = []
    p friends.length
    friends.each do |friend|
      # existing_friend = done.detect {|f| f["username"] == friend["username"] }
      existing_friend = nil
      if (existing_friend.nil?)
        begin
          friends_of_friends_ids = client.friend_ids(friend["id"]).to_a
          friend["friends"] = friends_of_friends_ids
          data << friend
          puts friend
        rescue Twitter::Error::TooManyRequests => error
          puts 'too many requests'
          puts 'sleeping'
          sleep(15*60) # minutes * 60 seconds
          retry
        rescue Twitter::Error::NotFound
          puts "#{friend} not found"
        rescue Twitter::Error::ClientError
          sleep 5
          retry
        end
      end
    end

    File.open("public/data/riblah_ff6.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  desc "move from done to ff"
  task :move_done do 
    data = []
    current = JSON.parse(File.read("public/data/riblah_ff.json"))
    File.readlines("public/data/done.txt").each do |line|
      data << eval(line)
    end
    all_data = data + current
    File.open("public/data/riblah_ff.json", "w") do |f|
      f.write(all_data.to_json)
    end
  end

  desc "append file to another"
  task :append do 
    data = []
    file1 = JSON.parse(File.read("public/data/riblah_ff4.json"))
    file2 = JSON.parse(File.read("public/data/riblah_ff5.json"))
    puts file1.length
    puts file2.length
    result = file1.concat file2
    puts result.length
    File.open("public/data/riblah_ff6.json", "w") do |f|
      f.write(result.to_json)
    end
  end

  desc "generate nodes and links"
  task :gen_nodes_and_links do
    require 'set'

    friends = JSON.parse(File.read("public/data/riblah_ff6.json"))
    friendsParsed = friends.select { |f| f["gender"] == 'female' or f["gender"] == 'male' }
    nodes = Hash.new { |h, k| h[k] = {} }
    me = nodes[15574548] = {
      :id =>       15574548,
      :name =>     "Ri Liu",
      :username => "riblah",
      :image =>    "http://pbs.twimg.com/profile_images/458458978171645952/6VHFgMig_normal.jpeg",
      :tweets =>   6886,
      :gender =>   "female",
      :index =>    0
    }
    links = Set.new

    friendsParsed.each_with_index do |friend, i|
      add_friends(friend, nodes, links, i + 1)
      links << { source: me[:index], target: i + 1, type: "fto#{friend["gender"][0]}" }
    end

    friendsParsed.each_with_index do |friend, i|
      add_friends_of_friends(friend, nodes, links, i + 1)
    end

    data = {
      :nodes => nodes.values,
      :links => links.to_a
    }
    File.open("public/data/data4.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  def add_friends(friend, nodes, links, index)
    friend_obj = {
      :id =>       friend["id"],    
      :name =>     friend["name"],
      :username => friend["username"],
      :image =>    friend["image"],
      :tweets =>   friend["tweets"],
      :gender =>   friend["gender"],
      :index =>    index
    }

    nodes[friend_obj[:id]].merge!(friend_obj)
  end

  def add_friends_of_friends(friend, nodes, links, index)
    friend["friends"].each do |friend_id|
      # p friend_id
      # nodes[friend_id].merge! id: friend_id
      friend_of_friend = nodes.fetch(friend_id, nil)
      if friend_of_friend
        links << {
          :source => index,
          :target => friend_of_friend[:index],
          :type   => "#{friend['gender'][0]}to#{friend_of_friend[:gender][0]}"
        }
      end
    end
  end
end
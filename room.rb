#!ruby -Ku

require 'rubygems'
require 'pit'
require 'active_resource'
class RedmineModule

  class RedmineIssue < ActiveResource::Base
  end

  def initialize
    pit = Pit.get('redmine', :require => {'server'=>'', 'username'=>'', 'password'=>''})
    RedmineIssue.site = pit['server']
    RedmineIssue.user = pit['user']
    RedmineIssue.password = pit['password']
  end

  # これは割と普通に見える。
  # room は @room でいいかもしらん
  # あるいはメソッドか
  def find(room, id)
    id = (id < 5000) ? id+10000 : id
    room.say RedmineIssue.site + "/issues/#{id}"
    issue = RedmineIssue.find(id) 
    room.say issue.subject.to_s
  end

  # hooksはつまりcontrollerなのか?
  def hooks(room)
    [
      {:matcher => /^#(\d+)$/, :action => proc{|m| self.find room, m[1].to_i }},
    ]
  end
end


class Echo
  def echo(room, msg)

    # ここでnickを使いたい
    # msg.value msg.talker みたいに分ける? 
    # msg.room でもいいわけだなぁ
    # hooksが受け取るのではなく、actionにroom, msg, talker などの環境情報を渡すだけでいいのでは?
    # hooksに渡されたroomの使いドコロってsayのレシーバとしてだけだよね　つまりアクションに発火しない限りは不要なのだ。
    # hooksはマッチャだけでいい
    # まっちゃも関数でいいんじゃないか? :matcher => proc{|room, talker, msg| msg =~ // }
    # よさげ
    # そうするとhooksは規制配列である必要はやっぱりなくって
    # よろずeventを受け付けて必要なものにだけ応答するcontrollerなんだなぁ
    
    room.say msg
  end

  # モジュールを登録する際に呼ばれる。
  # どんなときにイベントを送付して欲しいか?
  # モジュールの生成パラメータによって、その内容は異なってくるだろう
  # モジュールの respond_to? で勝手に判断でもいいか。on_mention, on_direct_message, on_update_timeline, on_file, on_timer, on_invite, on_kick
  # on_timerを返されるときは更に詳細を聞く
  def timer_detail 
    "* * * * *"
  end
  def __hooks
    [
      :mention,  # 話しかけられた (話者、場所、時間をパラメータとして持つ)
      :dm,       # 秘話で話しかけられた (話者、時間)
      :timeline, # その場で誰かが発言した (話者、場所、時間）
      :file,     # ファイルを受け取った (from, room, time, file)
      :timer,    # cron的な意味で 
    ]
  end

  def __notify(event)
    event.type
    event.room
    event.creater
    event.message
  end

  def hooks(room)
    [
      {:matcher => /.*/, :action => proc{|m| self.echo room, m[0] }},
    ]
  end
end


require './dumb_kvs'
class Dic
  #include Artemis::Plugin # 環境情報が取得できるようになる。sayメソッドもサポートされる

  def initialize(kvs, command = 'dic')
    @kvs = kvs
    @command = command
  end

  def hooks(room)
    [
      {:matcher => /^#{@command}\.add ([\w_-]+) (.*)$/, :action => proc{|m|
          dummy, name, value = m.to_a
          @kvs.set name, value
          room.say 'saved #{name} => #{value}'
      }},
      {:matcher => /^#{@command} ([\w_-]+)$/, :action => proc{|m|
          name = m[1]
          v = @kvs.get name
          room.say(v ? v : 'not found.')
      }},
      {:matcher => /^#{@command}\.(del|rm|delete|remove) ([\w_-]+)$/, :action => proc{|m|
          dummy, command, name = m
          value = @kvs.get name
          @kvs.delete name
          room.say "deleted #{name} => #{value}."
      }},
      {:matcher => /^bookmark\.random$/, :action => proc{|m|
          room.say @kvs.values.choice
      }},
    ]
  end

end

class Room
end

class OperationConsole < Room

  def say(msg)
    puts msg
  end

  def shout(msg)
    puts "*** #{msg} ***"
  end

  def get
    print "console> "
    gets.chomp
  end
end

class Artemis

  def run
    room = OperationConsole.new # irc_server.room('#ceweb') / irc_server.any_room
    kvs = DumbKvs.new

    # ここ一気に読み込みたいところだけど、パラメータをとるものがある...
    # botに応じたレシピになるところか
    modules = [
      RedmineModule.new,
      Echo.new,
      Dic.new(kvs),
    ]

    # 監視対象イベントを予め登録する?
     # 
     # 

    # イベントループ
    loop do

      # 入力の受領。イベントループであれば次のイベントの取得
      # 何かが起きた
      event = room.get

      # それを待ち受ける様々なマッチャとのマッチング
      modules.each do |mod|
        begin
          r = mod.__notify(event)
        rescue
          puts [$!.inspect].concat($@).join("\n\t")
        end
      end

    end
  end
end

# "部屋" はそこからの入力、そこへの入力、その他の状況を持つ
# ここでは端末を使う
Artemis.new.run
exit


# 部屋とモジュールを組み合わせる
# モジュールは、己の結びつく部屋がなんであるかは関知しないだろう
# 特定の部屋で起こったことのみに反応するか、
# ある部屋群(例えばサーバに結びついた全ての部屋)
# どの部屋で反応するかの設定は、つまり検索式だ

__END__
- module: irc
on: hoge_server
at: #room
keyword



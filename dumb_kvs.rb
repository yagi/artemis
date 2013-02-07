
# 指定されたファイルにハッシュをYAMLで保存するだけのKVS
# 何の信頼性もない
# どうかと思うけどデフォルトでDropbox同期
class DumbKvs

  def initialize(filename = ENV['HOME'] + '/Dropbox/.dumb_kvs.yaml')
    @filename = filename
    @dic = (YAML.load_file(@filename) rescue {})
  end

  def save
    File.open(@filename, 'w') do |h|
      h.print @dic.to_yaml
    end
  end
  protected :save

  def get(name)
    @dic[name]
  end

  def set(name, value)
    @dic[name] = value
    self.save
  end

  def delete(name)
    value = @dic.delete name
    self.save
    value
  end

  def values
    @dic.values
  end
end



class Second < TestCaseTemplate
  @description = 'Second'
  @requires = 'Path::To::First'
  @protocol = 'SecondProtocol'
  @author = 'SecondAuthor'

  def target_ports
    Port.all
  end

  def attack_on_port(port)
    @data_dir.mkpath
    @data_dir.join('result').write("#{@name} is successfully called. Port no = #{port.no}\n", mode: 'a')
  end
end

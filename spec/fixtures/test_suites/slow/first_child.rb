class FirstChild < TestCaseTemplate
  @description = 'FirstChild'
  @requires = 'Parent'
  @protocol = 'FirstChildProtocol'
  @author = 'FirstChildAuthor'

  def attack
    @data_dir.mkpath
    @data_dir.join('result').write("#{@name} is successfully called.\n", mode: 'a')
    sleep 1
  end
end

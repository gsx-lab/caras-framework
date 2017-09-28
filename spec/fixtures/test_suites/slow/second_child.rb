class SecondChild < TestCaseTemplate
  @description = 'Second Child'
  @requires = 'Parent'
  @protocol = 'SecondChildProtocol'
  @author = 'SecondChildAuthor'

  def attack
    @data_dir.mkpath
    @data_dir.join('result').write("#{@name} is successfully called.\n", mode: 'a')
    sleep 1
  end
end

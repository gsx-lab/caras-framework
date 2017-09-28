class SecondSibling < TestCaseTemplate
  @description = 'testcase for test'
  @requires = 'Path::To::First'
  @protocol = 'test'
  @author = 'test'

  def attack
    @data_dir.mkpath
    @data_dir.join('result').write("#{@name} is successfully called.\n", mode: 'a')
  end
end

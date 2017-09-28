class Parent < TestCaseTemplate
  @description = 'Parent'
  @requires = nil
  @protocol = 'ParentProtocol'
  @author = 'ParentAuthor'

  def attack
    @data_dir.mkpath
    @data_dir.join('result').write("#{@name} is successfully called.\n", mode: 'a')
    sleep 1
  end
end

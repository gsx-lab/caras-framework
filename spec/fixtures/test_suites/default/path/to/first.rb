class First < TestCaseTemplate
  @description = 'First'
  @requires = nil
  @protocol = 'FirstProtocol'
  @author = 'FirstAuthor'

  def attack
    @data_dir.mkpath
    @data_dir.join('result').write("#{@name} is successfully called.\n", mode: 'a')
  end
end

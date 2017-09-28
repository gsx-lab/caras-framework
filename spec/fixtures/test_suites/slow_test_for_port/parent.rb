class Parent < TestCaseTemplate
  @requires = nil

  def target_ports
    @host.ports
  end

  def attack_on_port(_)
    sleep 1
  end
end

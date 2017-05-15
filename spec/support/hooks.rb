
class TestAllHook < Gruf::Hooks::Base

  def before(_call_signature, _req, _call)
    true
  end

  def around(_call_signature, _req, _call, &block)
    yield
  end

  def after(_success, _response, _call_signature, _req, _call)
    true
  end
end

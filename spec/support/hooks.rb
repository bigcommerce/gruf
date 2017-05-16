# Base test hook
class TestHook < Gruf::Hooks::Base
  def self.verify
    true
  end
end
##########################################################################################
# EVERYTHING HOOKS
##########################################################################################
class TestAllHook1 < TestHook
  def before(_call_signature, _req, _call)
    self.class.verify
    true
  end

  def around(_call_signature, _req, _call, &block)
    self.class.verify
    yield
  end

  def after(_success, _response, _call_signature, _req, _call)
    self.class.verify
    true
  end
end

##########################################################################################
# BEFORE HOOKS
##########################################################################################
class BeforeHook1 < TestHook
  def before(_cs, _r, _c)
    self.class.verify
    true
  end
end
class BeforeHook2 < TestHook
  def before(_cs, _r, _c)
    self.class.verify
    true
  end
end
class BeforeHook3 < TestHook
  def before(_cs, _r, _c)
    self.class.verify
    true
  end
end

##########################################################################################
# AROUND HOOKS
##########################################################################################
class AroundHook1 < TestHook
  def around(_cs, _r, _c, &block)
    self.class.verify
    yield
  end
end
class AroundHook2 < TestHook
  def around(_cs, _r, _c, &block)
    self.class.verify
    yield
  end
end
class AroundHook3 < TestHook
  def around(_cs, _r, _c, &block)
    self.class.verify
    yield
  end
end

##########################################################################################
# AFTER HOOKS
##########################################################################################
class AfterHook1 < TestHook
  def after(_s, _rsp, _cs, _req, _c)
    self.class.verify
    true
  end
end
class AfterHook2 < TestHook
  def after(_s, _rsp, _cs, _req, _c)
    self.class.verify
    true
  end
end
class AfterHook3 < TestHook
  def after(_s, _rsp, _cs, _req, _c)
    self.class.verify
    true
  end
end

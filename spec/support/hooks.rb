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

  def around(_call_signature, _req, _call, &_)
    self.class.verify
    yield
  end

  def outer_around(_call_signature, _req, _call, &_)
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
class BeforeExceptionHook1 < TestHook
  def before(_cs, _r, _c)
    self.class.verify
    raise StandardError, 'Exception!'
  end
end

##########################################################################################
# AROUND HOOKS
##########################################################################################
class AroundHook1 < TestHook
  def around(_cs, _r, _c, &_)
    self.class.verify
    yield
  end
end
class AroundHook2 < TestHook
  def around(_cs, _r, _c, &_)
    self.class.verify
    yield
  end
end
class AroundHook3 < TestHook
  def around(_cs, _r, _c, &_)
    self.class.verify
    yield
  end
end
class AroundExceptionHook1 < TestHook
  def around(_cs, _r, _c, &_)
    self.class.verify
    raise StandardError, 'Exception!'
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
class AfterExceptionHook1 < TestHook
  def before(_s, _rsp, _cs, _req, _c)
    self.class.verify
    raise StandardError, 'Exception!'
  end
end

##########################################################################################
# OUTER AROUND HOOKS
##########################################################################################
class OuterAroundHook1 < TestHook
  def outer_around(_cs, _r, _c, &_)
    self.class.verify
    yield
  end
end
class OuterAroundHook2 < TestHook
  def outer_around(_cs, _r, _c, &_)
    self.class.verify
    yield
  end
end
class OuterAroundHook3 < TestHook
  def outer_around(_cs, _r, _c, &_)
    self.class.verify
    yield
  end
end
class OuterAroundExceptionHook1 < TestHook
  def around(_cs, _r, _c, &_)
    self.class.verify
    raise StandardError, 'Exception!'
  end
end

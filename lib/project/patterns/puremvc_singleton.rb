# The Singleton module implements the Singleton pattern.
#
# == Usage
#
# To use Singleton, include the module in your class.
#
#    class Klass
#       include Singleton
#       # ...
#    end
#
# This ensures that only one instance of Klass can be created.
#
#      a,b  = Klass.instance, Klass.instance
#
#      a == b
#      # => true
#
#      Klass.new
#      # => NoMethodError - new is private ...
#
# The instance is created at upon the first call of Klass.instance().
#
#      class OtherKlass
#        include Singleton
#        # ...
#      end
#
#      ObjectSpace.each_object(OtherKlass){}
#      # => 0
#
#      OtherKlass.instance
#      ObjectSpace.each_object(OtherKlass){}
#      # => 1
#
#
# This behavior is preserved under inheritance and cloning.
#
# == Implementation
#
# This above is achieved by:
#
# *  Making Klass.new and Klass.allocate private.
#
# *  Overriding Klass.inherited(sub_klass) and Klass.clone() to ensure that the
#    Singleton properties are kept when inherited and cloned.
#
# *  Providing the Klass.instance() method that returns the same object each
#    time it is called.
#
# *  Overriding Klass._load(str) to call Klass.instance().
#
# *  Overriding Klass#clone and Klass#dup to raise TypeErrors to prevent
#    cloning or duping.
#
# == Singleton and Marshal
#
# By default Singleton's #_dump(depth) returns the empty string. Marshalling by
# default will strip state information, e.g. instance variables and taint
# state, from the instance. Classes using Singleton can provide custom
# _load(str) and _dump(depth) methods to retain some of the previous state of
# the instance.
#
#    require 'singleton'
#
#    class Example
#      include Singleton
#      attr_accessor :keep, :strip
#      def _dump(depth)
#        # this strips the @strip information from the instance
#        Marshal.dump(@keep, depth)
#      end
#
#      def self._load(str)
#        instance.keep = Marshal.load(str)
#        instance
#      end
#    end
#
#    a = Example.instance
#    a.keep = "keep this"
#    a.strip = "get rid of this"
#    a.taint
#
#    stored_state = Marshal.dump(a)
#
#    a.keep = nil
#    a.strip = nil
#    b = Marshal.load(stored_state)
#    p a == b  #  => true
#    p a.keep  #  => "keep this"
#    p a.strip #  => nil
#
module PureMVCSingleton
  # Raises a TypeError to prevent cloning.
  def clone
    raise TypeError, "can't clone instance of singleton #{self.class}"
  end

  # Raises a TypeError to prevent duping.
  def dup
    raise TypeError, "can't dup instance of singleton #{self.class}"
  end

  # By default, do not retain any state when marshalling.
  def _dump(depth = -1)
    ''
  end

  module SingletonClassMethods # :nodoc:

    def clone # :nodoc:
      PureMVCSingleton.__init__(super)
    end

    # By default calls instance(). Override to retain singleton state.
    def _load(str)
      instance
    end

    private

    def inherited(sub_klass)
      super
      PureMVCSingleton.__init__(sub_klass)
    end
  end

  class << PureMVCSingleton # :nodoc:
    def __init__(klass) # :nodoc:
      klass.instance_eval {
        @singleton__instance__ = nil
      }
      def klass.instance # :nodoc:
        return @singleton__instance__ if @singleton__instance__
        mutex = PureMVCSingletonMutexes.mutex(self.name)
        mutex.synchronize do
          return @singleton__instance__ if @singleton__instance__
          @singleton__instance__ = new()
        end
        @singleton__instance__
      end
      klass
    end

    private

    def append_features(mod)
      #  help out people counting on transitive mixins
      unless mod.instance_of?(Class)
        raise TypeError, "Inclusion of the OO-Singleton module in module #{mod}"
      end
      super
    end

    def included(klass)
      super
      klass.private_class_method :new, :allocate
      klass.extend SingletonClassMethods
      PureMVCSingleton.__init__(klass)
    end
  end
end

class PureMVCSingletonMutexes
  MUTEX = nil
  Dispatch.once do
    MUTEX = Mutex.new
    @@mutexes = {}
  end

  def self.mutex(name)
    MUTEX.synchronize do
      return @@mutexes[name] unless @@mutexes[name].nil?
      @@mutexes[name] = Mutex.new
      return @@mutexes[name]
    end
  end
end

class Trebuchet::ActionControllerFilter

  def self.on_before(callback)
    return unless callback.is_a?(Proc)

    @on_before_callbacks ||= []
    @on_before_callbacks << callback
  end

  def self.before(controller)
    Trebuchet.initialize_logs

    if (
        defined?(Trebuchet::Backend::RedisCached) &&
        Trebuchet.backend.is_a?(Trebuchet::Backend::RedisCached) &&
        Trebuchet.backend.respond_to?(:clear_cached_strategies)
       )
      if Time.now > Trebuchet.backend.cache_cleared_at + 60.seconds
        Trebuchet.backend.clear_cached_strategies
      end
    end

    # Lazy local cache invalidation for RedisHammerspaced
    if (
        defined?(Trebuchet::Backend::RedisHammerspaced) &&
        Trebuchet.backend.is_a?(Trebuchet::Backend::RedisHammerspaced) &&
        Trebuchet.backend.respond_to?(:refresh)
       )
       Trebuchet.backend.refresh
    end

    (@on_before_callbacks || []).each do |callback|
      callback.call rescue nil
    end

    Trebuchet.current_block = Proc.new {
      Trebuchet.new(controller.send(:current_user), controller.request)
    }
  end

  def self.after(controller)
    Trebuchet.current_block = nil
    Trebuchet.reset_current! # very important
  end

end

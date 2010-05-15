class Bullhorn
  module Plugin
    class << self
      attr_accessor :options

      attr :ignored_exceptions
    end

    def self.ignored_exceptions
      [].tap do |ex|
        ex << ActiveRecord::RecordNotFound if defined? ActiveRecord
        if defined? ActionController
          ex << ActionController::UnknownController
          ex << ActionController::UnknownAction
          ex << ActionController::RoutingError if ActionController.const_defined?(:RoutingError)
        end
      end
    end

  protected
    def rescue_action_in_public(exception)
      notify_with_bullhorn!(exception)

      super
    end

    def notify_with_bullhorn!(exception)
      unless Bullhorn::Plugin.ignored_exceptions.include?(exception)
        bullhorn = Bullhorn.new(self, Bullhorn::Plugin.options)
        bullhorn.notify(exception, request.env)
      end
    end
  end
end
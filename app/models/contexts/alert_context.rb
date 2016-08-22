module Contexts
  class AlertContext
    def initialize alert
      @alert = alert
    end

    def process
      return if !@alert.enabled? || !@alert.has_recipients?

      message = MessageTemplate.instance.set_source!(@alert.message_template).interpolate(@alert.variables)
      sms = Sms::Message.new(@alert.recipients, message, @alert.type)

      SmsQueueJob.set(wait: ENV['DELAY_DELIVER_IN_MINUTES'].to_i).perform_later(sms.to_hash)
    end
  end
end

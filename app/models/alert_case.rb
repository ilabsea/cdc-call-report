class AlertCase
  def initialize(alert, report, week_year)
    @alert = alert
    @report = report
    @week_year = week_year
    @report_variable_cases = @report.report_variables.where(is_reached_threshold: true)
  end

  def run
    return if @alert.is_enable_sms_alert == false && @report_variable_cases.empty?
    messages = message_options
    if !messages.empty?
      SmsAlertJob.set(wait: ENV['DELAY_DELIVER_IN_MINUTES'].to_i).perform_later(messages)
    end
  end

  def message_options
    message_options = []
    message_body = translate_message
    recipients.each do |recipient|
      sms = recipient.phone
      if sms && sms != ""
        suggested_channel = Channel.suggested(Tel.new(sms))
        if suggested_channel
          options = { from: ENV['APP_NAME'],
                      to: "sms://#{sms}",
                      body: message_body,
                      suggested_channel: suggested_channel.name
                    }
          message_options << options
        end
      end
    end
    message_options
  end

  def recipients
    place = @report.user.place
    recipients = []
    @alert.recipient_type.each do |recipient|
      if recipient == "PHD"
        recipients = recipients + User.by_place(place.phd.id) if !place.phd.nil?
      end

      if recipient == "OD"
        recipients = recipients + User.by_place(place.od.id) if !place.od.nil?
      end

      if recipient == "HC"
        recipients = recipients + User.by_place(place.hc.id) if !place.hc.nil?
      end
    end
    recipients
  end

  def translate_message
    return "" unless @alert.message_template
    variable_ids = @report_variable_cases.pluck(:variable_id)
    variable_cases = Variable.where(id: variable_ids)
    translate_options = {
      week_year: @week_year,
      reported_cases: variable_cases.map(&:name).join(", ")
    }
    return MessageTemplate.instance.set_source(@alert.message_template).translate(translate_options)
  end
end

class SleepJob
  include SQS::Job
  include SQS::JobStatus

  def perform
    total = (self.options['length'] || 1000).to_i
    num = 0
    while num < total
      Rails.logger.debug "At #{num} of #{total}"
      sleep(1)
      num += 1
    end
  end

end

namespace :sqs do
  desc "works on a queue"
  task :work => :environment do
    SleepJob.queue.poll do |msg|
      Rails.logger.debug "got #{msg.body}"
      job = SleepJob.load(msg.body)
      job.perform
    end
  end
end

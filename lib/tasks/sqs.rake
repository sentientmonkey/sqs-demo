namespace :sqs do
  desc "works on a queue"
  task :work => :environment do
    SleepJob.queue.poll do |msg|
      Rails.logger.debug "got #{msg.id} #{msg.body}"
      job = SleepJob.load(msg.id, msg.body)
      job.perform
      job.complete
    end
  end
end

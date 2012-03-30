module SQS
  module Job
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sqs
        @sqs ||= AWS::SQS.new
      end

      def env_name
        @env_name ||= Rails.env
      end

      def app_name
        @app_name ||= Rails.application.class.parent_name
      end

      def class_name
        @class_nam ||= name.camelize
      end

      def queue_name
        @queue_name ||= [app_name, env_name, class_name].join("_")
      end

      def queue
        begin
          @queue ||= sqs.queues.named(queue_name)
        rescue AWS::SQS::Errors::NonExistentQueue => e
          Rails.logger.info(e)
        end
        @queue ||= sqs.queues.create(queue_name)
      end

      def setup
        queue
      end

      def encode(object)
        MultiJson.encode(object)
      end

      def decode(string)
        MultiJson.decode(string)
      end

      def create(*args)
        queue.send_message(encode(:klass => name.camelize, :args => args))
      end

      def load(id, msg)
        obj = decode(msg)
        Rails.logger.debug "obj is #{obj}"
        klass = Module.const_get(obj["klass"])
        klass.new(id, obj["args"])
      end
    end

    attr_accessor :id, :options

    def initialize(id, args)
      Rails.logger.debug "args #{args}"
      @id = id
      @options = args.first
    end

    def complete
    end
 
  end
end

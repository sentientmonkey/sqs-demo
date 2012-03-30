module SQS
  module JobStatus
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def dynamodb
        @dynamodb ||= AWS::DynamoDB.new
      end

      def env_name
        @env_name ||= Rails.env
      end

      def app_name
        @app_name ||= Rails.application.class.parent_name
      end

      def class_name
        @class_name ||= name.camelize
      end

      def table_name
        @table_name ||= [app_name, env_name, class_name].join("_")
      end

      def table
        begin
          @table ||= dynamodb.tables[table_name]
          @table.status
          @table.hash_key = [:id, :string]
        rescue AWS::DynamoDB::Errors::ResourceNotFoundException => e
          Rails.logger.debug e
          @table = (dynamodb.tables.create(table_name, 5, 5))
        end
        while @table.status == :creating do
          Rails.logger.info "waiting for table to create..."
          sleep 1
        end
        @table 
      end

      def setup
        queue
        table
      end

      def create(*args)
        obj = encode(:klass => name.camelize, :args => args)
        msg = queue.send_message(obj)
        table.items.create('id' => msg.id, 'obj' => obj, 'status' => 'queued')
        msg
      end

      def find(id)
        item = table.items[id]
        obj = decode(item.attributes['obj'])
        Rails.logger.debug "obj is #{obj}"
        klass = Module.const_get(obj["klass"])
        new_klass = klass.new(id, obj["args"])
        new_klass.status = item.attributes['status']
        new_klass
      end
    end

    attr_accessor :status, :item

    def complete
      item = self.class.table.items[id]
      item.attributes[:status] = 'complete'
    end
  end
end

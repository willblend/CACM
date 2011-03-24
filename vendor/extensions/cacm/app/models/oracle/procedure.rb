class Oracle
  module Procedure
    
    def self.included(base)
      base.class_eval do
        # make parse & exec available to both class and instance
        include ConnectionMethods
        extend ConnectionMethods
      end
    end

    module ConnectionMethods
      def exec(cursor, &block)
        Oracle.connection.reconnect! unless Oracle.connection.active?
        benchmark @plsql do
          cursor.exec
        end
        result = yield || false
        cursor.close
        @plsql = nil
        return result
      end

      def parse(plsql)
        @plsql = plsql
        Oracle.connection.reconnect! unless Oracle.connection.active?
        Oracle.connection.raw_connection.parse(@plsql)
      end

      def benchmark(query)
        if ActiveRecord::Base.logger && ActiveRecord::Base.logger.level == Logger::DEBUG
          result = nil
          seconds = Benchmark.realtime { result = yield }
          ActiveRecord::Base.logger.debug("  PLSQL (#{'%.5f' % seconds}) #{query}")
          result
        else
          yield
        end
      end
    end

  end
end
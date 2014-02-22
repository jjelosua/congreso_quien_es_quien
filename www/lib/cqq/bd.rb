module Cqq
  class Bd

    def initialize()
    end

    def diputados()
      @result = ActiveRecord::Base.connection.execute('SELECT * FROM diputados')

      return @result
    end

  end
end

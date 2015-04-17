module Xeroizer
  module Record
    class ScheduleModel < BaseModel
        
    end
    
    class Schedule < Base      
      decimal :period
      string  :unit
      date    :due_date
      string  :due_date_type
      date    :start_date
      date    :next_schedule_date
    end
    
  end
end
class User < ActiveRecord::Base
  WORK_HOURS_IN_A_DAY=8
  has_many :clocks
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :timeoutable ,#:ldap_authenticatable, #:registerable,
         :recoverable, #:rememberable,
         :trackable#, :validatable

  validates :password, { confirmation: true, length: { in: 6..20 }, allow_blank: true, allow_nil:  true  }

  def is_admin?
    role=="admin"
  end
  def is_camera?
    return true if is_admin?
    role=="camera"
  end


  def report(month)
    result={}
    result[:user] = username
    result[:area] = area
        (month.at_beginning_of_month..month.at_end_of_month).map do |day|
          worked_hours=0

          check_in=clocks.where(action: "check_in",date: day).first
          check_out=clocks.where(action: "check_out",date: day).first
          if check_in.nil? && check_out.nil?
            absence= 8
          else
            worked_hours=((check_out.time - check_in.time) / 1.hour).round(2)
            worked_hours=worked_hours - 1 if worked_hours > 6
          end
          case day.wday #(0-6, Sunday is zero).
            when 0
              delta=worked_hours
            when 6
              delta=worked_hours
            else
              delta=worked_hours-WORK_HOURS_IN_A_DAY
          end

          check_in = check_in.time.strftime("%H:%M") if check_in
          check_out = check_out.time.strftime("%H:%M") if check_out
          result[day.to_s] = {check_in: check_in, check_out: check_out,
                         worked_hours: worked_hours, delta: delta,
                         absence: absence, work_day: day.wday}
        end
    result
  end
end

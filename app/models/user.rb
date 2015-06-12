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
    result[:user_id] = id
    result[:area] = area
    result[:tot_absence] = 0
    result[:tot_hours] = 0
    result[:tot_by_tipo] = {}
    result[:tot_by_tipo]["Festivo"]=0
        (month.at_beginning_of_month..month.at_end_of_month).map do |day|
          worked_hours=0
          absence= 0
          check_in_id=false
          check_out_id=false

          check_in=clocks.where(action: "check_in",date: day).first
          check_out=clocks.where(action: "check_out",date: day).first
          tipo=check_in.tipo if check_in
          result[:tot_by_tipo][tipo] ||=0 if tipo

          if check_in
            check_in_id = check_in.id
            check_in = check_in.time.localtime
          end
          if check_out
            check_out_id = check_out.id
            check_out = check_out.time.localtime
          end

          if check_in.nil? && check_out.nil?
            absence= 8
            worked_hours=0
          else
            worked_hours=((check_out - check_in) / 1.hour) if (check_out && check_in)
            worked_hours=worked_hours - 1 if worked_hours > 6
          end

          case day.wday #(0-6, Sunday is zero).
            when 0
              absence= 0
              result[:tot_by_tipo]["Festivo"] += worked_hours
              delta=worked_hours
            when 6
              absence= 0
              result[:tot_by_tipo]["Festivo"] += worked_hours
              delta=worked_hours
            else
              delta=worked_hours-WORK_HOURS_IN_A_DAY
              result[:tot_by_tipo][tipo] += worked_hours if tipo
          end
          worked_hours=worked_hours.round(2)
          delta=delta.round(2)
          result[:tot_absence] += absence
          result[:tot_hours] += worked_hours

          check_in = check_in.strftime("%H:%M") if check_in
          check_out = check_out.strftime("%H:%M") if check_out

          result[day.to_s] = {check_in: check_in, check_out: check_out, check_in_id: check_in_id, check_out_id: check_out_id,
                         worked_hours: worked_hours, delta: delta,
                         absence: absence, work_day: day.wday}
        end
    result
  end
end
